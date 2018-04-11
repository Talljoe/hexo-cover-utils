require! {
  chai: {expect}
  '../../src/unsplash' : { parseUnsplash }
}

describe \parseUnsplash ->
  sut = parseUnsplash
  const default_crop = \entropy

  specify "it should return undefined for a local file" ->
    expect(sut "foo.jpg").to.be.undefined

  describe "when using short form specification" ->
    specify "it should return undefined for missing id" ->
      expect(sut "unsplash:").to.be.undefined

    specify "it should match upper case" ->
      expect(sut "UNSPLASH:test").to.not.be.undefined

    context "without a specified crop" ->
      const expected_id = \1234
      result = sut "unsplash:#{expected_id}"

      specify "it should return id" -> expect(result.id).to.equal expected_id
      specify "it should return default crop" ->
       expect(result.crop).to.equal default_crop

    context "with a specified crop" ->
      const expected_id = \abcd
      const expected_crop = \face
      result = sut "unsplash:#{expected_id}:#{expected_crop}"

      specify "it should return id" -> expect(result.id).to.equal expected_id
      specify "it should return expected crop" ->
        expect(result.crop).to.equal expected_crop

  describe "when using long form specification" ->
    specify "it should return undefined for a different site" ->
      expect(sut "http://example.com/").to.be.undefined

    specify "it should return undefined for missing id" ->
      expect(sut "https://unsplash.com/").to.be.undefined

    specify "it should match upper case url" ->
      expect(sut "HTTPS://UNSPLASH.COM/?photo=37121").to.not.be.undefined

    specify "it should match upper case photos url" ->
      expect(sut "HTTPS://UNSPLASH.COM/PHOTOS/37121").to.not.be.undefined

    specify "it should not match upper case query string" ->
      expect(sut "https://unsplash.com/?PHOTO=37121").to.be.undefined

    specify "it should match http" ->
      expect(sut "http://unsplash.com/?photo=37121").to.not.be.undefined

    context "without a specified crop" ->
      const expected_id = \0987
      result = sut "https://unsplash.com/?photo=#{expected_id}"

      specify "it should return id" -> expect(result.id).to.equal expected_id
      specify "it should return default crop" ->
       expect(result.crop).to.equal default_crop

    context "with a specified crop" ->
      const expected_id = \1a2b3c4d
      const expected_crop = \face
      result = sut "https://unsplash.com/?photo=#{expected_id}##{expected_crop}"

      specify "it should return id" -> expect(result.id).to.equal expected_id
      specify "it should return expected crop" ->
       expect(result.crop).to.equal expected_crop

    context "from a collection page" ->
      const expected_id = \1234
      result = sut "https://unsplash.com/collections/87821/write-read-note?photo=" + expected_id

      specify "it should return id" -> expect(result.id).to.equal expected_id

    context "from a following page" ->
      const expected_id = \65kl03
      result = sut "https://unsplash.com/following?photo=" + expected_id

      specify "it should return id" -> expect(result.id).to.equal expected_id

    context "from a photo page" ->
      const expected_id = \65kl03
      result = sut "https://unsplash.com/photos/" + expected_id

      specify "it should return id" -> expect(result.id).to.equal expected_id

    context "from a photo page with trailing path" ->
      const expected_id = \65kl03
      result = sut "https://unsplash.com/photos/#{expected_id}/foo"

      specify "it should return id" -> expect(result.id).to.equal expected_id
