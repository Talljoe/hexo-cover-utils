require! chai

describe \filter ->
  require! './filter/registration'
  require! './filter/should-not-modify-post'
  require! './filter/get-image-info'
  require! './filter/image-credit'
