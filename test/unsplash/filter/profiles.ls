require! {
  sinon
  proxyquire
  url
  chai
  'prelude-ls': { keys, map, filter, count }
}

{ expect } = chai
chai.use require 'chai-arrays'

getHexo = -> new (require \hexo) __dirname

describe "profiles" ->
  rawUrl = "/img.raw"
  fullUrl = "/img.full"

  var result

  setup = (outputs, cover = "unsplash:someId") ->
    var getImageInfoStub

    before ->
      post = cover: cover

      sut = getHexo! |> proxyquire '../../../src/unsplash', do
        './profiles': ->
          getOutputs: -> outputs

      getImageInfoStub := sinon.stub sut, \getImageInfo
        ..returns do
          urls:
            raw: rawUrl
            full: fullUrl

      sut._main post .then -> result := it

    after -> getImageInfoStub.restore!

  describe "when there are no profiles" ->
    setup []

    specify "it should set the cover to the full url" ->
      expect result.cover .to .equal fullUrl

    specify "it should not set any other profiles" ->
      result |> keys |> filter (.startsWith \cover_) |> -> expect it .to .be .empty

  describe "when crop is supplied" ->
    const expected-crop = \face

    setup [{name: \cover_foo}], "unsplash:bar:#{expected-crop}"

    specify "it should set the crop" ->
      result.cover_foo |> url.parse _, true |> -> expect it.query.crop .to .equal expected-crop

  describe "when crop is not supplied" ->
    const default-crop = \entropy

    setup [{name: \cover_foo}], "unsplash:bar"

    specify "it should set the crop" ->
      result.cover_foo |> url.parse _, true |> -> expect it.query.crop .to .equal default-crop

  describe "when there is a profile" ->
    const expected-name = \foo
    const expected-width = 1111
    const expected-height = 222

    profile =
      name: "cover_#{expected-name}"
      width: expected-width
      height: expected-height

    setup [profile]

    specify "it should set the cover to the full url" ->
      expect result.cover .to .equal fullUrl

    specify "it should set the profile" ->
      expect result.cover_foo .to .not .be .undefined

    specify "it should set the path" ->
      result.cover_foo |> url.parse |> -> expect it.pathname .to .equal rawUrl

    specify "it should set the height" ->
      result.cover_foo |> url.parse _, true |> -> expect it.query.h .to .equal "#{expected-height}"

    specify "it should set the width" ->
      result.cover_foo |> url.parse _, true |> -> expect it.query.w .to .equal "#{expected-width}"

  describe "when there are multiple profiles" ->
    profiles =
      * name: \cover_1
        width: 0
        height: 0
      * name: \cover_2
        width: 0
        height: 0

    setup profiles

    specify "it should set each profile" ->
      result |> keys |> -> expect it .to .be .containingAllOf (profiles |> map (.name))

