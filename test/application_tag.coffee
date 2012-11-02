User = require '../src/models/user'
ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  user = new User({ name: "zoidberg" })

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        done()

  afterEach (done) ->
    user.delete_all ->
      done()

  it "should have the object name `tags`", (done) ->
    user.save (err, reply) =>
      tags = user.applications().build('brainslugs').tags()
      assert.equal tags.object_name, "tags"
      done()

  it "should be able to generate a prefix for the tag list", ->
    at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
    tlist_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    at.taglist_prefix().should.equal tlist_prefix

  it "should return an empty list of tags when there are none", (done) ->
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
        at.list (err, reply) =>
          assert.equal err, null
          assert.deepEqual reply, []
          done()

  it "should be able to add a single tag to an app", (done) ->
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
        at.save (err, reply) =>
          at.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, ["1.0"]
            done()

  it "should be able to remove a single tag from an app", (done) ->
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
                assert.deepEqual reply, ["sillytag"]
                done()

  it "should be able to remove all tags from an app", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs')
      app.save (err, reply) =>
        assert.equal err, null
        branch1 = app.branches().build('sillytag')
        branch1.save (err, reply) =>
          assert.equal err, null
          branch2 = app.branches().build('thefunk')
          branch2.save (err, reply) =>
            assert.equal err, null
            branch2.delete_all (err, reply) =>
              branch2.list (err, reply) =>
                assert.equal err, null
                assert.deepEqual reply, []
                done()
