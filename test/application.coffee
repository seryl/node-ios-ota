User = require '../src/models/user'
Application = require '../src/models/application'

describe 'Application', ->
  user = new User({ name: "zoidberg" })
  apps = null

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        apps = user.applications()
        done()

  afterEach (done) ->
    user.delete_all ->
      apps = null
      done()

  it "should have the object name `application`", ->
    apps.object_name.should.equal "application"

  it "should have a applist_prefix of `::applications::<name>`", ->
    target_prefix = "node-ios-ota::applications::zoidberg"
    apps.applist_prefix().should.equal target_prefix

  it "should have an app_prefix of `<applist_prefix>::<application>`", ->
    app = user.applications()
    u_prefix = app.applist_prefix()
    apps.app_prefix("john").should.equal "#{u_prefix}::john"

  it "should return empty when a users application list is empty", (done) ->
    apps.list (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should be able to delete a single application for a user", (done) ->
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
      apps.save (err, reply) ->
        assert.equal err, null
        assert.equal reply, false
        done()

  it "should be able to add new applications for a given user", (done) ->
      apps.build('mooorrrooroo').save (err, reply) ->
        apps.list (err, reply) ->
          assert.equal err, null
          assert.deepEqual reply, ["mooorrrooroo"]
          done()

  it "should be able to list the applications for a given user", (done) ->
    apps.build('silly_duck').save (err, reply) ->
      apps.build('silly_dog').save (err, reply) ->
        apps.list (err, reply) ->
          assert.equal err, null
          assert.equal reply.length, 2
          assert.equal ('silly_dog' in reply), true
          assert.equal ('silly_duck' in reply), true
          done()
