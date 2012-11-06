User = require '../src/models/user'
ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  user = new User({ name: "zoidberg" })
  app = null

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        app = user.applications().build('brainslugs')
        app.save (err, reply) ->
          done()

  afterEach (done) ->
    user.delete_all ->
      app = null
      done()

  it "should have the object name `tags`", ->
    app.tags().object_name.should.equal "tags"

  it "should be able to generate a prefix for the tag list", ->
    tlist_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    app.tags().build('1.0').taglist_prefix().should.equal tlist_prefix

  it "should return an empty list of tags when there are none", (done) ->
    app.tags().build('1.0').list (err, reply) =>
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should be able to add a single tag to an app", (done) ->
    tags = app.tags().build('1.0')
    tags.save (err, reply) =>
      tags.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ["1.0"]
        done()

  it "should be able to remove a single tag from an app", (done) ->
    tags1 = app.tags().build('sillytag')
    tags1.save (err, reply) =>
      assert.equal err, null
      tags2 = app.tags().build('thefunk')
      tags2.save (err, reply) =>
        assert.equal err, null
        tags2.delete "thefunk", (err, reply) =>
          tags2.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, ["sillytag"]
            done()

  it "should be able to remove all tags from an app", (done) ->
    tags1 = app.tags().build('sillytag')
    tags1.save (err, reply) =>
      assert.equal err, null
      tags2 = app.branches().build('thefunk')
      tags2.save (err, reply) =>
        assert.equal err, null
        tags2.delete_all (err, reply) =>
          tags2.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, []
            done()
