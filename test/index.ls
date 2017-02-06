require! {
  sinon
  "../src/cover-utils.ls" : sut
  "chai"
}

{expect} = chai
chai.use require \chai-sinon

describe "tests" ->
  specify "should be written"
