require! {
  sinon
  chai
  bluebird: Promise
  'prelude-ls': { keys, any, filter }
  '../../../src/unsplash' : unsplash
}

{expect} = chai

getHexo = -> new (require \hexo) __dirname

context "it should not modify post" ->
  var getImageInfoStub
  var sut

  beforeEach ->
    sut := unsplash getHexo!
    getImageInfoStub := sinon.stub sut, \getImageInfo

  afterEach ->
    getImageInfoStub.restore!

  cases =
    "when there is no cover": -> {}
    "when there is a cover and no image": -> { cover: void }
    "when there is a cover and local image": -> { cover: \cover.jpg }
    "when there is an unsplash cover and can't get image data": ->
      getImageInfoStub.returns Promise.resolve void
      { cover: "unsplash:abc" }
    "when there is an unsplash cover and image data is missing urls": ->
      getImageInfoStub.returns Promise.resolve {}
      { cover: "unsplash:abc" }
    "when there is an unsplash cover and image data is missing raw url": ->
      getImageInfoStub.returns Promise.resolve { url: { raw: "raw.jpg" } }
      { cover: "unsplash:abc" }
    "when there is an unsplash cover and image data is missing full url": ->
      getImageInfoStub.returns Promise.resolve { url: { full: "full.jpg" } }
      { cover: "unsplash:abc" }

  for let name, setup of cases
    specify name, ->
      expected = setup!

      Promise.resolve (sut._main ^^expected)
        .then -> expect it .to .deep .equal expected
