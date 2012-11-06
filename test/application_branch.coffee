User = require '../src/models/user'
ApplicationBranch = require '../src/models/application_branch'

describe 'ApplicationBranch', ->
  user = new User({ name: "zoidberg" })
  app = null

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        app = user.applications().build('brainslugs')
        app.save (err, reply) ->
          done()

  afterEach (done) ->
    user.delete_all ->
      app = null
      done()

  it "should have the object name `branches`", ->
    app.branches().object_name.should.equal "branches"

  it "should be able to generate a prefix for the branch list", ->
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    app.branches().build('master').branchlist_prefix().should.equal b_prefix

  it "should return an empty list of branches when there are none", (done) ->
    app.branches().build('master').list (err, reply) =>
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should be able to add a single branch to an app", (done) ->
    branch = app.branches().build('master')
    branch.save (err, reply) =>
      branch.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ["master"]
        done()

  it "should be able to remove a single branch from an app", (done) ->
    app.branches().build('sillybranch').save (err, reply) =>
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
    app.branches().build('sillybranch').save (err, reply) =>
      assert.equal err, null
      branch = app.branches().build('swallow')
      branch.save (err, reply) =>
        assert.equal err, null
        branch.delete_all (err, reply) =>
          branch.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, []
            done()
