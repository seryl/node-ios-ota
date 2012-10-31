User = require '../src/models/user'
Application = require '../src/models/application'

describe 'Application', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  after (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.applications().delete_all ->
        done()

  it "should have the object name `application`", ->
    app = new Application("zoidberg")
    app.object_name.should.equal "application"

  it "should have a applist_prefix of `node-ios-ota::applications::<name>`", ->
    app = new Application("zoidberg")
    target_prefix = "node-ios-ota::applications::zoidberg"
    app.applist_prefix().should.equal target_prefix

  it "should have an app_prefix of `<applist_prefix>::<application>`", ->
    app = new Application("zoidberg")
    u_prefix = app.applist_prefix()
    app.app_prefix("john").should.equal "#{u_prefix}::john"

  it "should return empty when a users application list is empty", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      app = new Application(reply.username)
      app.list (err, reply) ->
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

  it "should be able to add new applications for a given user", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      user.applications().build('mooorrrooroo').save (err, reply) ->
        user.applications().list (err, reply) ->
          assert.equal err, null
          assert.equal reply[0], 'mooorrrooroo'
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
            assert.equal ('silly_dog' in reply), true
            assert.equal ('silly_duck' in reply), true
            done()
