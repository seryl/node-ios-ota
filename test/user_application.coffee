User = require '../src/models/user'
UserApplication = require '../src/models/user_application'

describe 'UserApplication', ->
  beforeEach (done) ->
    user = new User
    user.delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  it "should have the object name `application`", ->
    userapp = new UserApplication("zoidberg")
    userapp.object_name.should.equal "application"

  # it "should have a userlist_prefix of `node-ios-ota::users`", ->
  #   user = new User()
  #   user.userlist_prefix().should.equal "node-ios-ota::users"

  # it "should have a user_prefix of `node-ios-ota::user::<name>`", ->
  #   user = new User()
  #   user.user_prefix("fry").should.equal "node-ios-ota::user::fry"
