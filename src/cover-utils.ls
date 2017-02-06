module.exports = (hexo) ->
  require! [ gm, path, stream, url ]
  require! {
    "node-fetch": fetch
    "hexo-fs": fs
    "smartcrop-gm": smartcrop
    bluebird: Promise
    "prelude-ls" : { map, fold, each, flatten, compact, find, Func }
  }

  getImageInfo = Func.memoize (id) ->
    applicationId = hexo.config.unsplash_appid
    unless applicationId?
      hexo.log.warn "No Unsplash app id configured."
      return null
    url = "https://api.unsplash.com/photos/#{id}?client_id=#{applicationId}"
    fetch url
      .then ->
        hexo.log.info "Image #{id} result: #{it.statusText}" unless it.ok
        it
      .then (.json!)

  getProfiles = Func.memoize ->
    result = hexo.model \Data .findById \cover_profiles
    hexo.log.warn "No image profiles defined" unless result?data?
    result?data

  getOutputName = (inputName, name) ->
    pathParts = path.parse inputName
    delete pathParts.base
    pathParts.name = name
    path.format pathParts

  generate = (source, out, data) -->
    passThrough = stream.passThrough
    gm(source)
      .crop(data.width, data.height, data.x, data.y)
      .resize(out.width, out.height)
      .autoOrient()
      .strip()
      .stream()

  getOutputsForProfile = (cover, profile) -->
    getRecord = (parentName, alt) -->
      covername = path.basename(cover, path.extname(cover))
      fullname = [covername, parentName, alt.name] |> compact |> (.join \_)
      return
        width: alt.width
        height: alt.height
        name: fullname
    profile.altSizes
      |> map (getRecord profile.name)
      |> (++) [getRecord null profile]

  local-crop = (asset, profile) -->
    getCropData = Func.memoize ->
      cropOptions =
        width: profile.width
        height: profile.height
        minScale: profile.minScale

      crop = smartcrop.crop(asset.source, cropOptions)
        .then (.topCrop)

    getOutputsForProfile asset.slug, profile
      |> map (out) ->
        path: getOutputName asset.path, out.name
        data:
          modified: asset.modified
          data: ->
            dataStream = stream.PassThrough!
            getCropData!
              .then generate asset.source, out
              .then (.pipe dataStream)
            return dataStream

  default_crop = \entropy
  parseUnsplash = ->
    | it.startsWith \unsplash: =>
      [,id,crop] = it.split(\:)
      return
        id: id
        crop: crop ? default_crop
    | it.startsWith \https://unsplash.com =>
      u = url.parse it, true
      return
        id: u.query.photo
        crop: (u.hash?substring 1) ? default_crop

  hexo.extend.filter.register \before_post_render, (post) ->
    unsplash = parseUnsplash post.cover
    return unless unsplash?
    { id, crop } = unsplash
    (image) <-! getImageInfo id .then
    return unless image?urls?raw?
    post.imageCreditUnsplash = id
    post.imageCreditName = image?user?name
    post.imageCreditUrl = image?user?links?html
    getProfiles!
      |> map getOutputsForProfile \cover
      |> flatten
      |> map ({ name, width, height }) ->
          post[name] = "#{image.urls.raw}?w=#{width}&h=#{height}&fit=crop&crop=#{crop}"
    post.cover = image.urls.full

  hexo.extend.filter.register \before_post_render, (post) !->
    return unless post.cover? and not post.cover.startsWith \unsplash:

    PostAsset = @model("PostAsset")
    asset = PostAsset.findOne do
      post: post._id
      slug: post.cover
    return unless asset?
    getProfiles!
      |> map getOutputsForProfile post.cover
      |> flatten
      |> map ({name}) -> post[name] = getOutputName post.cover, name

  hexo.extend.helper.register \cover_url, (post, ...profiles) ->
    profiles.unshift \cover
    profileName = profiles.join \_
    img = post[profileName]
    switch
      | not img? => ''
      | img.startsWith \# => img
      | url.parse img .protocol? => img
      | otherwise =>
        hexo.extend.helper.get \url_for .call hexo, post.path + img

  hexo.extend.generator.register \cover_resize, ->
    Post = @model("Post")
    PostAsset = @model("PostAsset")
    Promise.all(Post.toArray())
    .filter (.cover?)
    .then map (post) ->
      return [] unless post.cover?
      asset = PostAsset.findOne do
        post: post._id
        slug: post.cover

      return [] unless asset?
      getProfiles! |> map local-crop asset
    .then flatten
