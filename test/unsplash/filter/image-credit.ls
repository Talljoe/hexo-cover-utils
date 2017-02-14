require! {
  sinon
  chai
  bluebird: Promise
  proxyquire
  'prelude-ls': { keys, any, filter }
  '../../../src/unsplash' : unsplash
}

{expect} = chai

getHexo = -> new (require \hexo) __dirname

context "image credits" ->
  context "when image has with full information" ->
    build-case do
      expected-id: "id"
      expected-name: "My Name"
      expected-url: "http://example.com/"

  context "when image has no name" ->
    build-case do
      expected-id: "id"
      expected-name: null
      expected-url: "http://example.com/"

  context "when image has no url" ->
    build-case do
      expected-id: "id"
      expected-name: "A Name"
      expected-url: null

  context "when image has no user" ->
    build-case do
      expected-id: "id"
      expected-name: null
      expected-url: null
      makeUser: -> undefined

  context "when image has no links" ->
    build-case do
      expected-id: "id"
      expected-name: "Foo"
      expected-url: null
      makeUser: ->
        name: "Foo"
        links: null

!function build-case ({ expected-id, expected-name, expected-url, makeUser })
  var getImageInfoStub
  var result

  post = cover: "unsplash:#{expected-id}"

  before ->
    sut = getHexo! |> proxyquire '../../../src/unsplash', do
      './profiles': ->
        getOutputs: -> []
    getImageInfoStub := sinon.stub sut, \getImageInfo
    getImageInfoStub.returns do
      urls: raw: "/img", full: "/img"
      user: if makeUser? then makeUser! else
        name: expected-name
        links: html: expected-url

    sut._main post .then -> result := it

  after -> getImageInfoStub.restore!

  build-verify "unsplash id", (.imageCreditUnsplash), expected-id
  build-verify "name", (.imageCreditName), expected-name
  build-verify "url", (.imageCreditUrl), expected-url

  !function build-verify (message, getProperty, expected)
    if expected? then
      specify "it should set #{message}" ->
        expect (getProperty post) .to .equal expected
    else
      specify "it should not set #{message}" ->
        expect (getProperty post) .to .be .undefined
