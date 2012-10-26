User = require '../src/models/user'

describe 'User', ->
  it "should have the object name `user`", ->
    user = new User()
    user.object_name.should.equal "user"

  # it "should have a prefix "
