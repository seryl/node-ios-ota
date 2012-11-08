filemd5 = require '../src/filemd5'

describe 'FileMd5', ->
  it "should be able get the md5 of a file", (done) ->
    filemd5 "#{__dirname}/fixtures/test_user.example_app.branch.master.ipa",
    (err, reply) ->
      assert.ifError err
      reply.should.equal "8b64ea08254c85e69d65ee7294431e0a"
      done()
