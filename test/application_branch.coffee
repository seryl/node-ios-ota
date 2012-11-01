User = require '../src/models/user'
ApplicationBranch = require '../src/models/application_branch'

describe 'ApplicationBranch', ->
  user = new User({ name: "zoidberg" })

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        done()

  afterEach (done) ->
      user.delete_all ->
      done()

  it "should have the object name `branches`", (done) ->
    user.save (err, reply) =>
      branches = user.applications().build('brainslugs').branches()
      branches.object_name.should.equal "branches"
      done()

  it "should be able to generate a prefix for the branch list", ->
    ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    ab.branchlist_prefix().should.equal b_prefix

  it "should be able to generate a prefix for a specific branch", ->
    ab = new ApplicationBranch("zoidberg", "brainslugs", "master")
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    ab.branch_prefix().should.equal "#{b_prefix}::master"

  it "should return an empty list of branches when there are none", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs')
      app.save (err, reply) =>
        assert.equal err, null
        branch = app.branches().build('master')
        branch.list (err, reply) =>
          assert.equal err, null
          assert.deepEqual reply, []
          done()

  it "should be able to add a single branch to an app", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs')
      app.save (err, reply) =>
        assert.equal err, null
        branch = app.branches().build('master')
        branch.save (err, reply) =>
          branch.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, ["master"]
            done()

  it "should be able to remove a single branch from an app", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs')
      app.save (err, reply) =>
        assert.equal err, null
        branch1 = app.branches().build('sillybranch')
        branch1.save (err, reply) =>
          assert.equal err, null
          branch2 = app.branches().build('swallow')
          branch2.save (err, reply) =>
            assert.equal err, null
            branch2.delete "swallow", (err, reply) =>
              branch2.list (err, reply) =>
                assert.equal err, null
                assert.deepEqual reply, ["sillybranch"]
                done()

  it "should be able to remove all branches from an app", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs')
      app.save (err, reply) =>
        assert.equal err, null
        branch1 = app.branches().build('sillybranch')
        branch1.save (err, reply) =>
          assert.equal err, null
          branch2 = app.branches().build('swallow')
          branch2.save (err, reply) =>
            assert.equal err, null
            branch2.delete_all (err, reply) =>
              branch2.list (err, reply) =>
                assert.equal err, null
                assert.deepEqual reply, []
                done()
