User = require '../src/models/user'
ApplicationBranch = require '../src/models/application_branch'

describe 'ApplicationBranch', ->
  it "should return prefixes for branches of an app" #, ->
    # user = new User({ name: "zoidberg" })
    # b_prefix = user.applications().get_app_build_prefix('blarph', 'branches')
    # tag_prefix = user.applications().get_app_build_prefix('blarph', 'tags')
    # zoidapp = "node-ios-ota::applications::zoidberg::blarph::"
    # b_prefix.should.equal "#{zoidapp}branches"
    # tag_prefix.should.equal "#{zoidapp}tags"

  it "should return the prefix for a single branch of an app" #, ->

  it "should return an empty list of branches when there are none" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('mooorrrooroo?').save (err, reply) ->
    #     user.applications().branches 'mooorrrooroo?', (err, reply) ->
    #       assert.equal err, null
    #       assert.isArray reply
    #       assert.equal reply.length, 0
    #       done()

  it "should be able to add a single branch to an app"

  it "should be able to remove a single branch from an app" #, (done) ->
    # user = new User({ name: "zoidberg" })
    # user.save (err, reply) ->
    #   user.applications().build('brainslug').save (err, reply) ->
    #     user.applications().branches 'slugbranch1', (err, reply) ->
    #       user.applications().branches 'slugbranch2', (err, reply) ->

  it "should be able to remove all branches from an app"
