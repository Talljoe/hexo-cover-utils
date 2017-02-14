require! {
  'prelude-ls': { Func, compact, map, flatten }
  path
}

module.exports = (hexo) ->
  _get = Func.memoize ->
    result = hexo.model \Data .findById \cover_profiles
    hexo.log.warn "No image profiles defined" unless result?data?
    result?data ? []

  getOutputsForProfile = (cover, profile) -->
    getRecord = (parentName, alt) -->
      covername = path.basename(cover, path.extname(cover))
      fullname = [covername, parentName, alt.name] |> compact |> (.join \_)
      return
        width: alt.width
        height: alt.height
        name: fullname
    profile.altSizes ? []
      |> map (getRecord profile.name)
      |> (++) [getRecord null profile]

  return do
    getProfiles: _get
    getOutputs: (cover) -> _get! |> map getOutputsForProfile cover |> flatten
