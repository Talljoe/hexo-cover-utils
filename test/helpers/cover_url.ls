require! {
  sinon
  chai
  '../../src/helpers' : helpers
}

expect = chai.expect
chai.use require \chai-sinon

getHexo = -> new (require \hexo) __dirname

describe \cover_url ->
  hexo = getHexo!
  helpers hexo
  sut = -> hexo.extend.helper.get \cover_url .apply hexo, arguments

  specify "it should register helper" ->
    expect sut .to .be .defined

  context "when profile does not exist" ->
    post = {}
    result = sut post, \foo

    specify "it should return an empty string" ->
      expect result .to .be .empty

  context "when profile starts with #" ->
    expected-value = \#value
    post = cover_foo: expected-value
    result = sut post, \foo

    specify "it should return the value verbatim" ->
      expect result .to .equal expected-value

  context "when profile contains an absolute url" ->
    expected-value = "https://example.com/myimage.jpg"
    post = cover_foo: expected-value
    result = sut post, \foo

    specify "it should return the value verbatim" ->
      expect result .to .equal expected-value

  context "when profile parts are specified" ->
    expected-value = \#foo
    post =
      cover_foo: \#nope
      cover_foobar: \#notmeeither
      coverFooBar: \#notcamelcase
      cover_foo_bar: expected-value

    result = sut post, \foo, \bar

    specify "it should return the value corresponding to profile parts separated by underscores" ->
      expect result .to .equal expected-value

  context "when profile contains a relative url" ->
    expected-value = "http://example.com/url_for.jpg"

    stub = sinon.stub!
    stub.returns expected-value

    original-helper = hexo.extend.helper.get \url_for
    hexo.extend.helper.register \url_for, stub

    post =
      cover_foo: \here/there
      path: \post/

    result = sut post, \foo

    hexo.extend.helper.register \url_for, original-helper if original-helper?

    specify "it should return the result of the call to url_for" ->
      expect result .to .equal expected-value

    specify "it should call url_for with the correct parameters" ->
      expect stub .to .have .been .calledWithExactly "post/here/there"

    specify "it should call url_for on hexo" ->
      expect stub .to .have .been .calledOn hexo

