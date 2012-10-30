User = require '../src/models/user'
UserApplication = require '../src/models/user_application'

describe 'UserApplication', ->
  beforeEach (done) ->
    user = new User()
    user.delete_all ->
      user = new User({ name: "zoidberg" })
      user.applications().delete_all ->
        user.save (err, username) ->
          done()

  after (done) ->
    user = new User()
    user.delete_all ->
      user = new User({ name: "zoidberg" })
      user.applications().delete_all ->
        done()

  it "should have the object name `application`", ->
    userapp = new UserApplication("zoidberg")
    userapp.object_name.should.equal "application"

  it "should have a applist_prefix of `node-ios-ota::applications::<name>`", ->
    userapp = new UserApplication("zoidberg")
    target_prefix = "node-ios-ota::applications::zoidberg"
    userapp.applist_prefix().should.equal target_prefix

  it "should have an app_prefix of `<applist_prefix>::<application>`", ->
    userapp = new UserApplication("zoidberg")
    u_prefix = userapp.applist_prefix()
    userapp.app_prefix("john").should.equal "#{u_prefix}::john"

  it "should return empty when a users application list is empty", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      userapp = new UserApplication(reply.username)
      userapp.list (err, reply) ->
        assert.equal err, null
        assert.isArray reply
        assert.equal reply.length, 0
        done()

  it "should return (null, false) when adding an unnamed app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().save (err, reply) ->
        assert.equal err, null
        assert.equal reply, false
        done()

  it "should return prefixes for branches or tags of an app", ->
    user = new User({ name: "zoidberg" })
    b_prefix = user.applications().get_app_build_prefix('blarph', 'branches')
    tag_prefix = user.applications().get_app_build_prefix('blarph', 'tags')
    zoidapp = "node-ios-ota::applications::zoidberg::blarph::"
    b_prefix.should.equal "#{zoidapp}branches"
    tag_prefix.should.equal "#{zoidapp}tags"

  it "should be able to add new applications for a given user", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().build('mooorrrooroo').save (err, reply) ->
        user.applications().list (err, reply) ->
          assert.equal err, null
          assert.equal reply[0], 'mooorrrooroo'
          done()

  it "should return an empty list of tags when there are none", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().build('mooorrrooroo!').save (err, reply) ->
        user.applications().tags 'mooorrrooroo!', (err, reply) ->
          assert.equal err, null
          assert.isArray reply
          assert.equal reply.length, 0
          done()

  it "should return an empty list of branches when there are none", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().build('mooorrrooroo?').save (err, reply) ->
        user.applications().branches 'mooorrrooroo?', (err, reply) ->
          assert.equal err, null
          assert.isArray reply
          assert.equal reply.length, 0
          done()

  it "should be able to list the applications for a given user", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().build('silly_duck').save (err, reply) ->
        user.applications().build('silly_dog').save (err, reply) ->
          user.applications().list (err, reply) ->
            assert.equal err, null
            assert.isArray reply
            assert.equal reply.length, 2
            assert.equal reply[0], 'silly_dog'
            assert.equal reply[1], 'silly_duck'
            done()
