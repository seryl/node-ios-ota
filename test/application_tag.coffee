User = require '../src/models/user'
ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  afterEach (done) ->
    new User().delete_all ->
      done()

  it "should have the object name `tags`", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      tags = user.applications().build('brainslugs').tags()
      assert.equal tags.object_name, "tags"
      done()

  it "should be able to generate a prefix for the tag list", ->
    at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
    tlist_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    assert.equal at.taglist_prefix(), tlist_prefix

  it "should be able to generate a prefix for a specific tag", ->
    at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
    t_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    assert.equal at.tag_prefix(), "#{t_prefix}::1.0"

  it "should return an empty list of tags when there are none", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
        at.list (err, reply) =>
          assert.equal err, null
          assert.isArray reply
          assert.equal reply.length, 0
          done()

  it "should be able to add a single tag to an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
        at.save (err, reply) =>
          at.list (err, reply) =>
            assert.equal err, null
            assert.isArray reply
            assert.equal reply.length, 1
            assert.equal reply[0], "1.0"
            done()

  it "should be able to remove a single tag from an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "sillytag")
        at.save (err, reply) =>
          assert.equal err, null
          at2 = new ApplicationTag("zoidberg", "brainslugs", "thefunk")
          at2.save (err, reply) =>
            assert.equal err, null
            at2.delete "thefunk", (err, reply) =>
              at2.list (err, reply) =>
                assert.equal err, null
                assert.isArray reply
                assert.equal reply.length, 1
                assert.equal reply[0], "sillytag"
                done()

  it "should be able to remove all tags from an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "sillytag")
        at.save (err, reply) =>
          assert.equal err, null
          at2 = new ApplicationTag("zoidberg", "brainslugs", "thefunk")
          at2.save (err, reply) =>
            assert.equal err, null
            at2.delete_all (err, reply) =>
              at2.list (err, reply) =>
                assert.equal err, null
                assert.isArray reply
                assert.equal reply.length, 0
                done()
