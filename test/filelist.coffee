User = require '../src/models/user'
Filelist = require '../src/models/filelist'

describe 'Filelist', ->
  user = new User({ name: "zoidberg" })

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        done()

  afterEach (done) ->
    user.delete_all ->
      done()

  it "should have the object name `filelist`", ->
    fl = new Filelist("zoidberg", "brainslugs", "branches")
    fl.object_name.should.equal "filelist"

  it "should be able to generate a prefix for the (branches) file list", ->
    fl = new Filelist("zoidberg", "brainslugs", "branches", "master")
    app_suffix = "zoidberg::brainslugs::branches::master::filelist"
    fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    fl.filelist_prefix().should.equal fl_prefix

  it "should be able to generate a prefix for the (tags) file list", ->
    fl = new Filelist("zoidberg", "brainslugs", "tags", "master")
    app_suffix = "zoidberg::brainslugs::tags::master::filelist"
    fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    fl.filelist_prefix().should.equal fl_prefix

  it "should be able to generate a prefix for the (branches) files hash", ->
    fl = new Filelist("zoidberg", "brainslugs", "branches", "example")
    app_suffix = "zoidberg::brainslugs::branches::example::files"
    files_prefix = fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    fl.files_prefix().should.equal files_prefix

  it "should be able to generate a prefix for the (tags) files hash", ->
    fl = new Filelist("zoidberg", "brainslugs", "tags", "example")
    app_suffix = "zoidberg::brainslugs::tags::example::files"
    files_prefix = fl_prefix = "node-ios-ota::applications::#{app_suffix}"
    fl.files_prefix().should.equal files_prefix

  it "should return an empty list for a filelist that is empty", (done) ->
    user.save (err, reply) =>
      app = user.applications().build('brainslugs');
      app.save (err, reply) =>
        assert.equal err, null
        branch = app.branches().build('master')
        branch.save (err, reply) ->
          assert.equal err, null
          files = branch.files()
          files.list (err, reply) ->
            assert.equal err, null
            assert.deepEqual reply, []
            done()

  # it "should be able to add a file to the filelist", (done) ->
  #   add_files = [
  #     { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
  #     { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
  #   ]
  #   user = new User({ name: "zoidberg" })
  #   user.save (err, reply) =>
  #     app = user.applications().build('brainslugs')
  #     app.save (err, reply) =>
  #       assert.equal err, null
  #       branch = app.branches().build('master')
  #       branch.save (err, reply) =>
  #         assert.equal err, null
  #         files = branch.files()
  #         files.save add_files, (err, reply) =>
  #           console.log "Adding files..."
  #           console.log err
  #           console.log reply
  #           done()

  it "should be able to add md5sums for a file"

  it "should be able to have multiple md5sums in the files hash"

  it "should be able to remove a file from the filelist"

  it "should be able to remove a file from the filelist and hash"

  it "should be able to remove all files from the filelist"

  it "should be able to update the md5sum for a file"
