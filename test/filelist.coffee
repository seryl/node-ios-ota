User = require '../src/models/user'
Filelist = require '../src/models/filelist'

describe 'Filelist', ->
  beforeEach (done) ->
    new User().delete_all ->
      user = new User({ name: "zoidberg" })
      user.save (err, username) ->
        done()

  afterEach (done) ->
    new User().delete_all ->
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

  it "should be able to add a file to the filelist"

  it "should be able to add md5sums for a file"

  it "should be able to have multiple md5sums in the files hash"

  it "should be able to remove a file from the filelist"

  it "should be able to remove a file from the filelist and hash"

  it "should be able to remove all files from the filelist"

  it "should be able to update the md5sum for a file"
