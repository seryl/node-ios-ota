User = require '../src/models/user'
ApplicationBranch = require '../src/models/application_branch'

describe 'ApplicationBranch', ->
  user = new User({ name: "zoidberg" })
  app = null
  dup_files = null
  b_cp = null

  add_files = [
    { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" },
    { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" }
  ]

  before (done) ->
    fs.exists config.get('repository'), (exists) ->
      if exists
        fs.exists config.get('client_repo'), (exists) ->
          if exists then done()
          else
            fs.mkdir config.get('client_repo'), (exists) ->
              done()
      else
        fs.mkdir config.get('repository'), (err) ->
          fs.exists config.get('client_repo'), (exists) ->
          if exists then done()
          else
            fs.mkdir config.get('client_repo'), (exists) ->
              done()

  beforeEach (done) ->
    b_cp = config.get('client_repo')
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        app = user.applications().build('brainslugs')
        app.save (err, reply) ->
          dup_files = [
            { location: path.join(b_cp, "master.ipa"), name: "master.ipa" },
            { location: path.join(b_cp, "master.plist"), name: "master.plist" }
          ]

          pfix = "#{__dirname}/fixtures"
          fs.copy "#{pfix}/master.ipa", "#{b_cp}/master.ipa", (err) =>
            fs.copy "#{pfix}/master.plist", "#{b_cp}/master.plist", (err) =>
              done()

  after (done) ->
    user.delete_all ->
      app = null
      rimraf config.get('repository'), (err) ->
        rimraf config.get('client_repo'), (err) ->
          done()

  it "should have the object name `branches`", ->
    app.branches().object_name.should.equal "branches"

  it "should be able to generate a prefix for the branch list", ->
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches"
    app.branches().build('master').branchlist_prefix().should.equal b_prefix

  it "should return an empty list of branches when there are none", (done) ->
    app.branches().build('master').list (err, reply) =>
      assert.ifError err
      assert.deepEqual reply, []
      done()

  it "should be able to add a single branch to an app", (done) ->
    branch = app.branches().build('master')
    branch.save (err, reply) =>
      branch.list (err, reply) =>
        assert.ifError err
        assert.deepEqual reply, ["master"]
        fs.exists [config.get('repository'),
        "zoidberg", "brainslugs", "branches", "master"].join('/'),
            (exists) ->
              exists.should.equal true
              done()

  it "should be able to show information for a single branch", (done) ->
    branch = app.branches().build('master')
    branch.save (err, reply) =>
      branch.find 'master', (err, reply) =>
        assert.ifError err
        reply.name.should.equal "master"
        assert.deepEqual reply.files, []
        done()

  it "should be able to show added files for a single branch", (done) ->
    branch = app.branches().build('master')
    branch.save (err, reply) =>
      assert.ifError err
      files = branch.files()
      files.save dup_files, (err, reply) =>
        assert.ifError err
        branch.find 'master', (err, reply) =>
          assert.ifError err
          reply.name.should.equal "master"
          assert.deepEqual reply.files, add_files
          done()

  it "should be able to show added files for all branches", (done) ->
    branch1 = app.branches().build('master')
    branch1.save (err, reply) =>
      assert.ifError err
      files1 = branch1.files()
      files1.save dup_files, (err, reply) =>
        assert.ifError err
        branch2 = app.branches().build('development')
        branch2.save (err, reply) =>
          assert.ifError err
          files2 = branch2.files()
          dup_files = [
            { location: path.join(b_cp, "master.ipa"),   name: "master.ipa" },
            { location: path.join(b_cp, "master.plist"), name: "master.plist" }
          ]

          pfix = "#{__dirname}/fixtures"
          fs.copy "#{pfix}/master.ipa", "#{b_cp}/master.ipa", (err) =>
            fs.copy "#{pfix}/master.plist", "#{b_cp}/master.plist", (err) =>
              files2.save dup_files, (err, reply) =>
                assert.ifError err
                branch2.all (err, reply) =>
                  assert.ifError err
                  ['master', 'development'].should.include(
                    reply['branches'][0]['name'])
                  ['master', 'development'].should.include(
                    reply['branches'][1]['name'])
                  done()

  it "should be able to remove a single branch from an app", (done) ->
    app.branches().build('sillybranch').save (err, reply) =>
      assert.ifError err
      branch2 = app.branches().build('swallow')
      branch2.save (err, reply) =>
        assert.ifError err
        branch2.delete "swallow", (err, reply) =>
          fs.exists [config.get('repository'),
          "zoidberg", "brainslugs", "branches", "master"].join('/'),
              (exists) ->
                exists.should.equal false
                branch2.list (err, reply) =>
                  assert.ifError err
                  assert.deepEqual reply, ["sillybranch"]
                  done()

  it "should be able to remove all branches from an app", (done) ->
    app.branches().build('sillybranch').save (err, reply) =>
      assert.ifError err
      branch = app.branches().build('swallow')
      branch.save (err, reply) =>
        assert.ifError err
        branch.delete_all (err, reply) =>
          branch.list (err, reply) =>
            assert.ifError err
            assert.deepEqual reply, []
            done()
