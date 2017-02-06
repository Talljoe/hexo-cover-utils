require! {
  'prelude-ls': { map, each }
}

module.exports = (hexo) ->
  <[ ./local-resize ./helpers ./unsplash ]> |> map require |> each -> it(hexo)
