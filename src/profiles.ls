require! {
  'prelude-ls': { Func, compact, map }
  path
}

module.exports = (hexo) ->
  getProfiles: Func.memoize ->
    result = hexo.model \Data .findById \cover_profiles
    hexo.log.warn "No image profiles defined" unless result?data?
    result?data ? []

  getOutputsForProfile: (cover, profile) -->
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
