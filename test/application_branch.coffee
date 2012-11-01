User = require '../src/models/user'
ApplicationBranch = require '../src/models/application_branch'

describe 'ApplicationBranch', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  afterEach (done) ->
    new User().delete_all ->
      done()

  it "should have the object name `branches`", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      branches = user.applications().build('brainslugs').branches()
      assert.equal branches.object_name, "branches"
      done()

  it "should be able to generate a prefix for the branch list", ->
    ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    assert.equal ab.branchlist_prefix(), b_prefix

  it "should be able to generate a prefix for a specific branch", ->
    ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    assert.equal ab.branch_prefix(), "#{b_prefix}::master"

  it "should return an empty list of branches when there are none", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
        ab.list (err, reply) =>
          assert.equal err, null
          assert.isArray reply
          assert.equal reply.length, 0
          done()

  it "should be able to add a single branch to an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
        ab.save (err, reply) =>
          ab.list (err, reply) =>
            assert.equal err, null
            assert.isArray reply
            assert.equal reply.length, 1
            assert.equal reply[0], "master"
            done()

  it "should be able to remove a single branch from an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        ab = new ApplicationBranch("zoidberg", "brainslugs", "sillybranch")
        ab.save (err, reply) =>
          assert.equal err, null
          ab2 = new ApplicationBranch("zoidberg", "brainslugs", "swallow")
          ab2.save (err, reply) =>
            assert.equal err, null
            ab2.delete "swallow", (err, reply) =>
              ab2.list (err, reply) =>
                assert.equal err, null
                assert.isArray reply
                assert.equal reply.length, 1
                assert.equal reply[0], "sillybranch"
                done()

  it "should be able to remove all branches from an app", (done) ->
    user = new User({ name: "zoidberg" })
    user.save (err, reply) =>
      user.applications().build('brainslugs').save (err, reply) =>
        assert.equal err, null
        ab = new ApplicationBranch("zoidberg", "brainslugs", "sillybranch")
        ab.save (err, reply) =>
          assert.equal err, null
          ab2 = new ApplicationBranch("zoidberg", "brainslugs", "swallow")
          ab2.save (err, reply) =>
            assert.equal err, null
            ab2.delete_all (err, reply) =>
              ab2.list (err, reply) =>
                assert.equal err, null
                assert.isArray reply
                assert.equal reply.length, 0
                done()
