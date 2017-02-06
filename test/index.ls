require! {
  "../src/index" : sut
}

describe "index" ->
  hexo = new (require \hexo) __dirname
  specify "should load" -> sut(hexo)
