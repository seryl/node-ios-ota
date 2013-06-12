User = require '../src/models/user'
BranchArchive = require '../src/models/branch_archive'

describe 'BranchArchive', ->
  user = new User({ name: "zoidberg" })
  app = null
  branch = null
  dup_files = null
  b_cp = null

  add_files = [
    { name: "4101.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" },
    { name: "4101.plist", md5: "0a1b8472e01bc836acecd246347d4492" }
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
          fs.copy "#{pfix}/master.ipa", "#{b_cp}/master.ipa", (err) ->
            fs.copy "#{pfix}/master.plist", "#{b_cp}/master.plist", (err) ->
              branch = app.branches().build('master')
              branch.save (err, reply) =>
                done()

  after (done) ->
    user.delete_all ->
      app = null
      rimraf config.get('repository'), (err) ->
        rimraf config.get('client_repo'), (err) ->
          done()

  it "should have the object name `archives`", ->
    archives = branch.archives()
    archives.object_name.should.equal "archives"

  it "should be able to generate a prefix for the branch list", ->
    b_prefix = "node-ios-ota::applications::zoidberg::brainslugs::branches::master::archives"
    archives = branch.archives()
    b_prefix.should.equal archives.build(4101).archivelist_prefix()

  it "should return an empty list of archives when there are none", (done) ->
    branch.archives().build(4101).list (err, reply) =>
      assert.ifError err
      assert.deepEqual reply, []
      done()

  it "should be able to archive a branch", (done) ->
      arch = branch.archives().build(4101)
      arch.save (err, reply)  =>
        arch.list (err, reply) =>
          assert.ifError err
          assert.deepEqual reply, ["4101"]
          fs.exists [config.get('repository'),
          "zoidberg", "brainslugs", "branches", "master", "archives"].join('/')
          , (exists) ->
             exists.should.equal true
             done()

  it "should be able to show information for a single archive", (done) ->
    arch = branch.archives().build(4101)
    arch.save (err, reply) =>
      arch.find 4101, (err, reply) =>
        assert.ifError err
        reply.name.should.equal "4101"
        assert.deepEqual reply.files, []
        done()

  it "should be able to show added files for a single archive", (done) ->
    arch = branch.archives().build(4101)
    arch.save (err, reply) =>
      assert.ifError err
      files = arch.files()
      files.save dup_files, (err, reply) =>
        assert.ifError err
        arch.find '4101', (err, reply) =>
          assert.ifError err
          reply.name.should.equal "4101"
          assert.deepEqual reply.files, add_files
          done()

  it "should be able to show added files for all archives", (done) ->
    arch1 = branch.archives().build(4104)
    arch1.save (err, reply) =>
      assert.ifError err
      files1 = arch1.files()
      files1.save dup_files, (err, reply) =>
        assert.ifError err
        arch2 = branch.archives().build(4105)
        arch2.save (err, reply) =>
          assert.ifError err
          files2 = arch2.files()
          dup_files = [
            { location: path.join(b_cp, "master.ipa"),   name: "master.ipa" },
            { location: path.join(b_cp, "master.plist"), name: "master.plist" }
          ]
  
          pfix = "#{__dirname}/fixtures"
          fs.copy "#{pfix}/master.ipa", "#{b_cp}/master.ipa", (err) =>
            fs.copy "#{pfix}/master.plist", "#{b_cp}/master.plist", (err) =>
              files2.save dup_files, (err, reply) =>
                assert.ifError err
                arch2.all (err, reply) =>
                  assert.ifError err
                  ['4104', '4105'].should.include(
                    reply['archives'][0]['name'])
                  ['4104', '4105'].should.include(
                    reply['archives'][1]['name'])
                  done()

  it "should be able to remove a single archive from a branch", (done) ->
    branch.archives().build(4110).save (err, reply) =>
      assert.ifError err
      arch2 = branch.archives().build(4111)
      arch2.save (err, reply) =>
        assert.ifError err
        arch2.delete 4111, (err, reply) =>
          fs.exists [config.get('repository'),
          "zoidberg", "brainslugs", "branches", "master",
          "archives", "4111"].join('/'),
              (exists) ->
                exists.should.equal false
                arch2.list (err, reply) =>
                  assert.ifError err
                  assert.deepEqual reply, ["4110"]
                  done()

  it "should be able to remove all branches from an app", (done) ->
    branch.archives().build(4104).save (err, reply) =>
      assert.ifError err
      arch = branch.archives().build(4110)
      arch.save (err, reply) =>
        assert.ifError err
        arch.delete_all (err, reply) =>
          arch.list (err, reply) =>
            assert.ifError err
            assert.deepEqual reply, []
            done()
