ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  it "should be able to generate a prefix for the tag list", ->
   at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
   tlist_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
   assert.equal at.taglist_prefix(), tlist_prefix

  it "should be able to generate a prefix for a specific tag", ->
    at = new ApplicationTag("zoidberg", "brainslugs", "1.0")
    t_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    assert.equal at.tag_prefix(), "#{t_prefix}::1.0"

  it "should return the prefix for the taglist of an app" #, ->
    # user = new User({ name: "zoidberg" })
    # b_prefix = user.applications().get_app_build_prefix('blarph', 'branches')
    # tag_prefix = user.applications().get_app_build_prefix('blarph', 'tags')
    # zoidapp = "node-ios-ota::applications::zoidberg::blarph::"
    # b_prefix.should.equal "#{zoidapp}branches"
    # tag_prefix.should.equal "#{zoidapp}tags"

  it "should return the prefix for a single tag of an app" #, ->

  it "should return an empty list of tags when there are none" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('mooorrrooroo!').save (err, reply) ->
    #     user.applications().tags 'mooorrrooroo!', (err, reply) ->
    #       assert.equal err, null
    #       assert.isArray reply
    #       assert.equal reply.length, 0
    #       done()

  it "should be able to add a single tag to an app" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('brainslugs').save (err, reply) ->
    #     user.applications().add_branch 'brainslugs', 'slugtest', (err, reply) ->
    #       user.applications().branches 'brainslugs', (err, reply) ->
    #         console.log err
    #         console.log reply
    #         done()

  it "should be able to remove a single tag from an app" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('brainspawn').save (err, reply) ->
    #     user.applications().tags('bspawn1').save (err, reply) ->
    #       user.applications().tags('bspawn2').save (err, reply) ->

  it "should be able to remove all tags from an app"
