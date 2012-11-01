User = require '../src/models/user'
ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  after (done) ->
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
    at = new ApplicationTag("zoidberg", "brainslugs", "emptytag")
    at.list (err, reply) ->
      assert.equal err, null
      # assert.isArray reply
      # assert.equal reply.length, 0
      done()

  it "should be able to add a single tag to an app", (done) ->
    at = new ApplicationTag("zoidberg", "brainslugs", "newtag")
    at.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, "newtag"
      done()

  it "should be able to remove a single tag from an app" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('brainspawn').save (err, reply) ->
    #     user.applications().tags('bspawn1').save (err, reply) ->
    #       user.applications().tags('bspawn2').save (err, reply) ->

  it "should be able to remove all tags from an app"
