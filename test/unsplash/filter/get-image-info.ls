require! {
  sinon
  chai
  proxyquire
  bluebird: Promise
  'node-fetch' : { Response }
  'prelude-ls': { filter }
}

chai.use require \chai-sinon
{expect} = chai

getHexo = -> new (require \hexo) __dirname

getSut = (hexo, { appid = null, response = null, status = null, stub = null }) ->
  hexo.config.unsplash_appid = appid
  sinon.stub hexo.log

  fetchStub = stub ? sinon.stub!
  if response?
    fetch-response =
      new Response JSON.stringify response
      |> Promise.resolve
    fetchStub.returns fetch-response, { status }

  hexo |> proxyquire '../../../src/unsplash' do
    'node-fetch': fetchStub


describe 'get image info' ->
  describe 'missing app id' ->
    hexo = getHexo!
    fetchStub = sinon.stub!
    sut = getSut hexo, stub: fetchStub

    result = sut._getImageInfo \id

    specify 'it should log a warning' ->
      expect hexo.log.warn .to .be .called

    specify 'it should not fetch' ->
      expect fetchStub .to .not .be .called

    specify 'it should return null promise' ->
      result.then -> expect it .to .be .null

  describe 'photo not found' ->
    expected-result = null

    sut = getSut getHexo!, status: 404, response: "404 NOT FOUND"
    result = sut._getImageInfo \id

    specify 'it should return null promise' ->
      result.then -> expect it .to .be .null

  describe 'photo is found' ->
    expected-result = hello: 'there'
    expected-appid = 'myappid'
    photo-id = '123'

    hexo = getHexo!
    fetchStub = sinon.stub!
    sut = getSut hexo, do
      appid: expected-appid
      response: expected-result
      status: 200
      stub: fetchStub
    result = sut._getImageInfo photo-id

    specify 'it should return expected result' ->
      result.then -> expect it .to .deep .equal expected-result

    specify 'it should pass expected url' ->
      expect fetchStub .to .have .been .called-with do
        "https://api.unsplash.com/photos/#{photo-id}?client_id=#{expected-appid}"

    specify 'it should not log an error' ->
      expect hexo.log.error .to .not .be .called

    specify 'it should not log a warning' ->
      expect hexo.log.warn .to .not .be .called
