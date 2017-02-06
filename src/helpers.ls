module.exports = (hexo) ->
  require! url

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
