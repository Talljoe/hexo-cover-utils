require! {
  url
  bluebird: Promise
  "node-fetch": fetch
  "prelude-ls" : { map, flatten, Func }
  "./profiles"
}

module.exports = class UnsplashFilter
  (@hexo) ~>
    @hexo.extend.filter.register \before_post_render @_main
    { @getOutputsForProfile, @getProfiles } = profiles @hexo
    @getImageInfo = Func.memoize @_getImageInfo


  default_crop = \entropy

  @parseUnsplash = ->
    | it is /unsplash:.+/i =>
      [,id,crop] = it.split(\:)
      return
        id: id
        crop: crop ? default_crop
    | it is /https?:\/\/unsplash.com\//i =>
      u = url.parse it, true
      crop = (u.hash?substring 1) ? default_crop
      switch
        | u.query.photo? =>
          id: that
          crop: crop
        | /photos\/([^/]+)/i .exec u.path =>
          id: that.1
          crop: crop

  _main: (post) ~>
    unsplash = @@parseUnsplash post.cover
    return post unless unsplash?
    { id, crop } = unsplash

    (image) <~! Promise.resolve @getImageInfo id .then
    return post unless image?urls?raw? and image?urls?full?

    post.imageCreditUnsplash = id
    post.imageCreditName? = image?user?name
    post.imageCreditUrl? = image?user?links?html

    @getProfiles!
      |> map @getOutputsForProfile \cover
      |> flatten
      |> map ({ name, width, height }) ~>
          post[name] = "#{image.urls.raw}?w=#{width}&h=#{height}&fit=crop&crop=#{crop}"
    post.cover = image.urls.full
    return post

  _getImageInfo: (id) ~>
    applicationId = @hexo.config.unsplash_appid
    unless applicationId?
      @hexo.log.warn "No Unsplash app id configured."
      return Promise.resolve null
    url = "https://api.unsplash.com/photos/#{id}?client_id=#{applicationId}"
    fetch url
      .then ~>
        if it.ok then it.json!
        else
          @hexo.log.info "Image #{id} result: #{it.statusText}"
          null
