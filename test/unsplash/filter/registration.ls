require! {
  sinon
  chai
  'prelude-ls': { filter }
  '../../../src/unsplash' : unsplash
}

chai.use require \chai-asserttype
chai.use require \chai-sinon
{expect} = chai

describe "when registering" ->
  hexo = new (require \hexo) __dirname
  spy = sinon.spy(hexo.extend.filter, \register)
  unsplash hexo

  after -> spy.restore!

  specify "it should register a 'before_post_render' filter" ->
    expect spy .to .have .been .calledWith \before_post_render

  specify "it should register a function" ->
    expect spy.args[0][1] .to .be .function()
