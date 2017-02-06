module.exports = (hexo) ->
  require! [ gm, path, stream ]
  require! {
    "smartcrop-gm": smartcrop
    bluebird: Promise
    "prelude-ls" : { map, flatten, find, Func }
    "./profiles"
  }

  { getOutputsForProfile, getProfiles } = profiles hexo

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
