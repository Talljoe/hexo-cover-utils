require! {
  url
  "node-fetch": fetch
  "prelude-ls" : { map, flatten, Func }
  "./profiles"
}

default_crop = \entropy
parseUnsplash = ->
  | it is /unsplash:.+/i =>
    [,id,crop] = it.split(\:)
    return
      id: id
      crop: crop ? default_crop
  | it is /https?:\/\/unsplash.com\//i =>
    u = url.parse it, true
    if u.query.photo? then
      id: u.query.photo
      crop: (u.hash?substring 1) ? default_crop

module.exports = (hexo) ->
  { getOutputsForProfile, getProfiles } = profiles hexo

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

module.exports._parseUnsplash = parseUnsplash
