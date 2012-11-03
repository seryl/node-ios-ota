User = require '../src/models/user'
Files = require '../src/models/files'

describe 'Files', ->
  user = new User({ name: "zoidberg" })
  app = null
  branch = null
  tag = null

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        app = user.applications().build('brainslugs')
        app.save (err, application) ->
          branch = app.branches().build('master')
          branch.save (err, reply) ->
            tag = app.tags().build('1.0')
            tag.save (err, reply) ->
              done()

  afterEach (done) ->
    user.delete_all ->
      app = null
      branch = null
      tag = null
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

  it "should be able
  to generate a prefix for the (branches) files hash", ->
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

  it "should be able to add a file to the files", (done) ->
    add_files = [
      { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
      { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
    ]
    files = branch.files()
    files.save add_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ['myapp.ipa', 'myapp.plist']
        done()

  it "should be able to remove a file from the files and hash", (done) ->
    add_files = [
      { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
      { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
    ]
    files = branch.files()
    files.save add_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ['myapp.ipa', 'myapp.plist']
        done()

  it "should be able to remove all files from the files", (done) ->
    add_files = [
      { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
      { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
    ]
    files = branch.files()
    files.save add_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ['myapp.ipa', 'myapp.plist']
        files.delete_all (err) =>
          assert.equal err, null
          files.list (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, []
            done()

  it "should be able to update the md5sum for a file", (done) ->
    add_files = [
      { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
      { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
    ]
    updated_file =
      name: "myapp.ipa"
      md5:  "33b42f456cd70aea284ef49d2c4a8652"

    files = branch.files()
    files.save add_files, (err, reply) =>
      files.list (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, ['myapp.ipa', 'myapp.plist']
        files.save updated_file, (err, reply) =>
          assert.equal err, null
          files.find 'myapp.ipa', (err, reply) =>
            assert.equal err, null
            assert.deepEqual reply, updated_file
            done()

  it "should be able to list all the md5sums for all files", (done) ->
    add_files = [
      { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
      { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
    ]
    files = branch.files()
    files.save add_files, (err, reply) =>
      files.all (err, reply) =>
        assert.equal err, null
        assert.deepEqual reply, add_files
        done()
