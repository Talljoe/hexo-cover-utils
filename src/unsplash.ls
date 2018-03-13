require! {
  url : { URL }
  bluebird: Promise
  "node-fetch": fetch
  "prelude-ls" : { each, flatten, Func }
  "./profiles"
}

module.exports = class UnsplashFilter
  (@hexo) ~>
    @hexo.extend.filter.register \before_post_render @_main
    { @getOutputs } = profiles @hexo
    @getImageInfo = Func.memoize @_getImageInfo


  default_crop = \entropy

  @parseUnsplash = ->
    | it is /unsplash:.+/i =>
      [,id,crop] = it.split(\:)
      return
        id: id
        crop: crop ? default_crop
    | it is /https?:\/\/unsplash.com\//i =>
      u = new URL it
      crop = if (u.hash?length < 2) then default_crop else (u.hash?substring 1)
      switch
        | u.searchParams.has \photo =>
          id: u.searchParams.get \photo
          crop: crop
        | /photos\/([^/]+)/i .exec u.pathname =>
          id: that.1
          crop: crop

  _main: (post) ~>
    unsplash = @@parseUnsplash post.cover
    return post unless unsplash?
    { id, crop } = unsplash

    (image) <~! Promise.resolve @getImageInfo id .then
    return post unless image? and image.urls?raw? and image.urls?full?

    post.imageCreditUnsplash = id
    post.imageCreditName? = image.user?name
    post.imageCreditUrl? = image.user?links?html

    @getOutputs \cover
      |> each ({ name, width, height }) ~>
          imgUrl = new URL image.urls.raw
          imgUrl.searchParams
            ..append(\w, width)
            ..append(\h, height)
            ..append(\fit, \crop)
            ..append(\crop, crop)
          post[name] = imgUrl.toString!
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
