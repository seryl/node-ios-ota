User = require '../src/models/user'

describe 'User', ->
  beforeEach (done) ->
    user = new User()
    user.delete_all ->
      done()

  after (done) ->
    user = new User()
    user.delete_all ->
      done()

  it "should have the object name `user`", ->
    user = new User()
    user.object_name.should.equal "user"

  it "should have a userlist_prefix of `node-ios-ota::users`", ->
    user = new User()
    user.userlist_prefix().should.equal "node-ios-ota::users"

  it "should have a user_prefix of `node-ios-ota::user::<name>`", ->
    user = new User()
    user.user_prefix("fry").should.equal "node-ios-ota::user::fry"

  it "should be able to delete a non-existing user", (done) ->
    user = new User()
    user.delete "blargmat", (err, reply) ->
      assert.equal err, null
      assert.equal reply, true
      done()

  it "should be able to delete all users", (done) ->
    user = new User()
    user.delete_all (err, reply) ->
      assert.equal err, null
      assert.equal reply, undefined
      done()

  it "should return an empty list of users when there are none", (done) ->
    user = new User()
    user.list (err, reply) ->
      assert.equal err, null
      assert.isArray reply
      assert.equal reply.length, 0
      done()

  it "should return (null, false) when adding an empty user", (done) ->
    user = new User()
    user.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, false
      done()

  it "should be able to add a user", (done) ->
    user = new User()
    user.build({ name: "bender" }).save (err, reply) ->
      assert.equal err, null
      assert.equal reply.name, "bender"
      done()

  it "should be able to remove a user from a set of users", (done) ->
    user = new User()
    user.build({ name: "farnsworth" }).save (err, reply) ->
      assert.equal err, null
      assert.equal reply.name, "farnsworth"
      user.build({ name: "zapp" }).save (err, reply) ->
        assert.equal err, null
        assert.equal reply.name, "zapp"
        user.delete "farnsworth", (err, reply) ->
          assert.equal err, null
          assert.equal reply, true
          user.list (err, usernames) ->
            assert.equal err, null
            assert.equal usernames[0], "zapp"
            done()

  it "should be able to check whether a user exists", (done) ->
    user = new User()
    credentials = { username: "boxy", password: "uhmmuhum" }
    user.check_login credentials, (err, reply) ->
      assert.isNotNull(err)
      err.code.should.equal "UserDoesNotExist"
      done()

  it "should be able to check whether a login is incorrect", (done) ->
    user = new User({ name: "kroker" })
    user.save (err, reply) ->
      assert.equal err, null
      assert.equal reply.name, "kroker"
      credentials = { username: "kroker", password: "blghur" }
      user.check_login credentials, (err, reply) ->
        err.code.should.equal "InvalidPassword"
        done()

  it "should be able to check whether a login was successful", (done) ->
    user = new User({ name: "nibbler" })
    user.save (err, reply) ->
      assert.equal err, null
      assert.equal reply.name, "nibbler"
      credentials = { username: "nibbler", secret: reply.secret }
      user.check_login credentials, (err, reply) ->
        assert.equal err, null
        done()

  it "should be able to return the list of user applications", (done) ->
    user = new User({ name: "Calculon" })
    user.applications().list (err, reply) ->
      assert.equal err, null
      assert.isArray reply
      assert.equal reply.length, 0
      done()
