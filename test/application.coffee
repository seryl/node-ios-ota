User = require '../src/models/user'
Application = require '../src/models/application'

describe 'Application', ->
  user = new User({ name: "zoidberg" })

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  afterEach (done) ->
    user.delete_all ->
      done()

  it "should have the object name `application`", (done) ->
    user.save (err, reply) ->
      app = user.applications()
      app.object_name.should.equal "application"
      done()

  it "should have a applist_prefix of `::applications::<name>`", (done) ->
    user.save (err, reply) ->
      app = user.applications()
      target_prefix = "node-ios-ota::applications::zoidberg"
      app.applist_prefix().should.equal target_prefix
      done()

  it "should have an app_prefix of `<applist_prefix>::<application>`", (done) ->
    user.save (err, reply) ->
      app = user.applications()
      u_prefix = app.applist_prefix()
      app.app_prefix("john").should.equal "#{u_prefix}::john"
      done()

  it "should return empty when a users application list is empty", (done) ->
    user.save (err, reply) =>
      user.applications().list (err, reply) ->
        assert.equal err, null
        assert.deepEqual reply, []
        done()

  it "should be able to delete a single application for a user", (done) ->
    user.save (err, reply) =>
      apps = user.applications()
      apps.build('brainslugs').save (err, reply) =>
        apps.build('crushinator').save (err, reply) =>
          apps.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, ["crushinator", "brainslugs"]
            apps.delete "brainslugs", (err, reply) =>
              apps.list (err, reply) =>
                assert.equal err, null
                assert.deepEqual reply, ["crushinator"]
                done()

  it "should be able to delete all applications for a given user", (done) ->
    user.save (err, reply) =>
      apps = user.applications()
      apps.build('brainslugs').save (err, reply) =>
        assert.equal err, null
        apps.build('crushinator').save (err, reply) =>
          assert.equal err, null
          apps.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, ['crushinator', 'brainslugs']
            apps.delete_all (err, reply) =>
              apps.list (err, reply) =>
                assert.equal err, null
                assert.deepEqual reply, []
                done()

  it "should return (null, false) when adding an unnamed app", (done) ->
    user.save (err, reply) ->
      user.applications().save (err, reply) ->
        assert.equal err, null
        assert.equal reply, false
        done()

  it "should be able to add new applications for a given user", (done) ->
    user.save (err, reply) ->
      user.applications().build('mooorrrooroo').save (err, reply) ->
        user.applications().list (err, reply) ->
          assert.equal err, null
          assert.deepEqual reply, ["mooorrrooroo"]
          done()

  it "should be able to list the applications for a given user", (done) ->
    user.save (err, reply) ->
      user.applications().build('silly_duck').save (err, reply) ->
        user.applications().build('silly_dog').save (err, reply) ->
          user.applications().list (err, reply) ->
            assert.equal err, null
            assert.deepEqual reply, ['silly_duck', 'silly_dog']
            done()
