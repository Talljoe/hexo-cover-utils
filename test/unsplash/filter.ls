require! {
  sinon
  chai
  bluebird: Promise
  'prelude-ls': { keys, any, filter }
  '../../src/unsplash' : unsplash
}

chai.use require \chai-asserttype
chai.use require \chai-sinon
{expect} = chai

getHexo = -> new (require \hexo) __dirname

describe "registration" ->
  hexo = getHexo!
  spy = sinon.spy(hexo.extend.filter, \register)
  unsplash hexo

  after -> spy.restore!

  specify "should register a 'before_post_render' filter" ->
    expect spy .to .have .been .calledWith \before_post_render

  specify "should register a function" ->
    expect spy.args[0][1] .to .be .function()


context "should not modify post" ->
  var getImageInfoStub
  var sut

  beforeEach ->
    sut := unsplash getHexo!
    getImageInfoStub := sinon.stub sut, \getImageInfo

  afterEach ->
    getImageInfoStub.restore!

  cases =
    "when no cover": -> {}
    "when cover and no image": -> { cover: void }
    "when cover and local image": -> { cover: \cover.jpg }
    "when unsplash cover and can't get image data": ->
      getImageInfoStub.returns Promise.resolve void
      { cover: "unsplash:abc" }
    "when unsplash cover and image data is missing urls": ->
      getImageInfoStub.returns Promise.resolve {}
      { cover: "unsplash:abc" }
    "when unsplash cover and image data is missing raw url": ->
      getImageInfoStub.returns Promise.resolve { url: { raw: "raw.jpg" } }
      { cover: "unsplash:abc" }
    "when unsplash cover and image data is missing full url": ->
      getImageInfoStub.returns Promise.resolve { url: { full: "full.jpg" } }
      { cover: "unsplash:abc" }

  for let name, setup of cases
    specify name, ->
      expected = setup!

      Promise.resolve (sut._main ^^expected)
        .then -> expect it .to .deep .equal expected
