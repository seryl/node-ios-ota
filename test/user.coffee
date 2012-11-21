User = require '../src/models/user'

describe 'User', ->
  user = new User()

  beforeEach (done) ->
    user = new User()
    user.delete_all ->
      done()

  after (done) ->
    user.delete_all ->
      done()

  it "should have the object name `user`", ->
    user.object_name.should.equal "user"

  it "should have a userlist_prefix of `node-ios-ota::users`", ->
    user.userlist_prefix().should.equal "node-ios-ota::users"

  it "should have a user_prefix of `node-ios-ota::user::<name>`", ->
    user.user_prefix("fry").should.equal "node-ios-ota::user::fry"

  it "should be able to delete a non-existing user", (done) ->
    user.delete "blargmat", (err, reply) ->
      assert.equal err, null
      reply.should.equal true
      done()

  it "should be able to delete all users", (done) ->
    user.delete_all (err, reply) ->
      assert.equal err, null
      assert.equal reply, undefined
      done()

  it "should return an empty list of users when there are none", (done) ->
    user.list (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should return (null, false) when adding an empty user", (done) ->
    user.save (err, reply) ->
      assert.ifError err
      reply.should.equal false
      done()

  it "should be able to add a user", (done) ->
    user.build({ name: "bender" }).save (err, reply) ->
      assert.ifError err
      reply.name.should.equal "bender"
      fs.exists [
        config.get('repository'), "bender"].join('/'), (exists) ->
          exists.should.equal true
          done()

  it "should be able to remove a user from a set of users", (done) ->
    user.build({ name: "farnsworth" }).save (err, reply) ->
      assert.ifError err
      assert.equal reply.name, "farnsworth"
      user.build({ name: "zapp" }).save (err, reply) ->
        assert.ifError err
        assert.equal reply.name, "zapp"
        user.delete "farnsworth", (err, reply) ->
          assert.ifError err
          assert.equal reply, true
          fs.exists [
            config.get('repository'), "farnsworth"].join('/'), (exists) ->
              exists.should.equal false
              user.list (err, usernames) ->
                assert.ifError err
                assert.deepEqual usernames, ["zapp"]
                done()

  it "should be able to check whether a user exists", (done) ->
    credentials = { username: "boxy", password: "uhmmuhum" }
    user.check_login credentials, (err, reply) ->
      assert.isNotNull(err)
      err.code.should.equal "UserDoesNotExist"
      done()

  it "should be able to check whether a login is incorrect", (done) ->
    user.build({ name: "kroker" }).save (err, reply) ->
      assert.ifError err
      reply.name.should.equal "kroker"
      credentials = { username: "kroker", password: "blghur" }
      user.check_login credentials, (err, reply) ->
        err.code.should.equal "InvalidPassword"
        done()

  it "should be able to check whether a login was successful", (done) ->
    user.build({ name: "nibbler" }).save (err, reply) ->
      assert.ifError err
      reply.name.should.equal "nibbler"
      credentials = { username: "nibbler", secret: reply.secret }
      user.check_login credentials, (err, reply) ->
        assert.ifError err
        done()

  it "should be able to return the list of user applications", (done) ->
    user.build({ name: "Calculon" }).applications().list (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()
