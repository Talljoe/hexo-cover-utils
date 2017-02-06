require! {
  sinon
  "../src/index" : sut
  "chai"
}

{expect} = chai
chai.use require \chai-sinon

getHexo = -> new (require \hexo) __dirname

describe "index" -> specify "should load" -> sut(getHexo!)
