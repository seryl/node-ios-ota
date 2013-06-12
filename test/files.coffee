User = require '../src/models/user'
Files = require '../src/models/files'

describe 'Files', ->
  user = new User({ name: "zoidberg" })
  app = null
  branch = null
  tag = null
  dup_files = []

  add_files = [
    { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" },
    { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" }
  ]

  before (done) ->
    fs.exists config.get('repository'), (exists) ->
      if exists
        done()
      else
        fs.mkdir config.get('repository'), (err) ->
          done()

  beforeEach (done) ->
    b_cp = config.get('repository')
    user = new User({ name: "zoidberg" })
    user.delete_all =>
      user.save (err, username) =>
        app = user.applications().build('brainslugs')
        app.save (err, application) =>
          branch = app.branches().build('master')
          branch.save (err, reply) =>
            tag = app.tags().build('1.0')
            tag.save (err, reply) =>
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
      branch = null
      tag = null
      rimraf config.get('repository'), (err) ->
        done()

  it "should have the object name `files`", ->
    tag.files().object_name.should.equal "files"
    branch.files().object_name.should.equal "files"

  it "should be able to generate a prefix for the (branches) file list", ->
    app_suffix = "zoidberg::brainslugs::branches::master::files"
    fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    branch.files().files_prefix().should.equal fl_prefix

  it "should be able to generate a prefix for the (tags) file list", ->
    app_suffix = "zoidberg::brainslugs::tags::1.0::files"
    fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    tag.files().files_prefix().should.equal fl_prefix

  it "should be able to generate a prefix for the (branches) files hash", ->
    app_suffix = "zoidberg::brainslugs::branches::master::files"
    files_prefix = fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    branch.files().files_prefix().should.equal files_prefix

  it "should be able to generate a prefix for the (tags) files hash", ->
    app_suffix = "zoidberg::brainslugs::tags::1.0::files"
    files_prefix = fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    tag.files().files_prefix().should.equal files_prefix

  it "should return an empty list for a files that is empty", (done) ->
    branch.files().list (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should be able to cleanup the file extension for a file", (done) ->
    files = branch.files()
    test_dsym = 'awesome.cool.awesome.dSYM.tar.gz'
    test_plist = 'profile-2.0-0.plist'
    test_ipa = 'myawesom-cool.nextone-0.ipa'

    files.file_extension(test_dsym).should.equal "dSYM.tar.gz"
    files.file_extension(test_plist).should.equal "plist"
    files.file_extension(test_ipa).should.equal "ipa"
    done()

  it "should be able to add a file to the files", (done) ->
    files = branch.files()
    files.save dup_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, (f.name for f in add_files)
        done()

  it "should be able to remove a file from the files and hash", (done) ->
    files = branch.files()
    files.save dup_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, (f.name for f in add_files)
        done()

  it "should be able to remove all files from the files", (done) ->
    files = branch.files()
    files.save dup_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, (f.name for f in add_files)
        files.delete_all (err) =>
          assert.equal err, null
          files.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, []
            done()

  it "should be able to list all the md5sums for all files", (done) ->
    files = branch.files()
    files.save dup_files, (err, reply) =>
      files.all (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, add_files
        done()
