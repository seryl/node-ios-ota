User = require '../src/models/user'
Application = require '../src/models/application'

describe 'Application', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  afterEach (done) ->
    new User().delete_all ->
      done()

  it "should have the object name `application`", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      app = user.applications()
      app.object_name.should.equal "application"
      done()

  it "should have a applist_prefix of `::applications::<name>`", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      app = user.applications()
      target_prefix = "node-ios-ota::applications::zoidberg"
      app.applist_prefix().should.equal target_prefix
      done()

  it "should have an app_prefix of `<applist_prefix>::<application>`", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) ->
      app = user.applications()
      u_prefix = app.applist_prefix()
      app.app_prefix("john").should.equal "#{u_prefix}::john"
      done()

  it "should return empty when a users application list is empty", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().list (err, reply) ->
        assert.equal err, null
        assert.isArray reply
        assert.equal reply.length, 0
        done()

  it "should be able to delete a single application for a user", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      apps = user.applications()
      apps.build('brainslugs').save (err, reply) =>
        apps.build('crushinator').save (err, reply) =>
          apps.list (err, reply) =>
            assert.equal err, null
            assert.isArray reply
            assert.equal reply.length, 2
            assert.equal ("brainslugs" in reply), true
            assert.equal ("crushinator" in reply), true
            apps.delete "brainslugs", (err, reply) =>
              apps.list (err, reply) =>
                assert.equal err, null
                assert.isArray reply
                assert.equal reply.length, 1
                assert.equal reply[0], "crushinator"
                done()

  it "should be able to delete all applications for a given user", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      apps = user.applications()
      apps.build('brainslugs').save (err, reply) =>
        apps.build('crushinator').save (err, reply) =>
          apps.list (err, reply) =>
            assert.equal err, null
            assert.isArray reply
            assert.equal reply.length, 2
            assert.equal ("brainslugs" in reply), true
            assert.equal ("crushinator" in reply), true
            apps.delete_all (err, reply) =>
              apps.list (err, reply) =>
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
