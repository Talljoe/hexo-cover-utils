require! {
  sinon
  chai
  'prelude-ls': { filter }
  '../../../src/unsplash' : unsplash
}

chai.use require \chai-asserttype
chai.use require \chai-sinon
{expect} = chai

describe "registration" ->
  hexo = new (require \hexo) __dirname
  spy = sinon.spy(hexo.extend.filter, \register)
  unsplash hexo

  after -> spy.restore!

  specify "should register a 'before_post_render' filter" ->
    expect spy .to .have .been .calledWith \before_post_render

  specify "should register a function" ->
    expect spy.args[0][1] .to .be .function()
