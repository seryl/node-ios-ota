User = require '../src/models/user'
ApplicationTag = require '../src/models/application_tag'

describe 'ApplicationTag', ->
  user = new User({ name: "zoidberg" })
  app = null

  add_files = [
    { name: "test_user.example_app.branch.master.ipa",
    md5: "8b64ea08254c85e69d65ee7294431e0a" },
    { name: "test_user.example_app.branch.master.plist",
    md5: "f1a8c3b91286aa1971a18b61e68b9ea8" }
  ]

  beforeEach (done) ->
    user = new User({ name: "zoidberg" })
    user.delete_all ->
      user.save (err, username) ->
        app = user.applications().build('brainslugs')
        app.save (err, reply) ->
          done()

  after (done) ->
    user.delete_all ->
      app = null
      done()

  it "should have the object name `tags`", ->
    app.tags().object_name.should.equal "tags"

  it "should be able to generate a prefix for the tag list", ->
    tlist_prefix = "node-ios-ota::applications::zoidberg::brainslugs::tags"
    app.tags().build('1.0').taglist_prefix().should.equal tlist_prefix

  it "should return an empty list of tags when there are none", (done) ->
    app.tags().build('1.0').list (err, reply) =>
      assert.ifError err
      assert.deepEqual reply, []
      done()

  it "should be able to add a single tag to an app", (done) ->
    tags = app.tags().build('1.0')
    tags.save (err, reply) =>
      tags.list (err, reply) =>
        assert.ifError err
        assert.deepEqual reply, ["1.0"]
        fs.exists [config.get('repository'),
        "zoidberg", "brainslugs", "tags", "1.0"].join('/'),
            (exists) ->
              exists.should.equal true
              done()

  it "should be able to show information for a single tag", (done) ->
    tag = app.tags().build('1.0')
    tag.save (err, reply) =>
      tag.find '1.0', (err, reply) =>
        assert.ifError err
        reply.name.should.equal "1.0"
        assert.deepEqual reply.files, []
        done()

  it "should be able to show added files for a single tag", (done) ->
    tag = app.tags().build('1.0')
    tag.save (err, reply) =>
      assert.ifError err
      files = tag.files()
      files.save add_files, (err, reply) =>
        assert.ifError err
        tag.find '1.0', (err, reply) =>
          assert.ifError err
          reply.name.should.equal "1.0"
          assert.deepEqual reply.files, add_files
          done()

  it "should be able to show added files for all tags", (done) ->
    tag1 = app.tags().build('1.0')
    tag1.save (err, reply) =>
      assert.ifError err
      files1 = tag1.files()
      files1.save add_files, (err, reply) =>
        assert.ifError err
        tag2 = app.tags().build('1.1')
        tag2.save (err, reply) =>
          assert.ifError err
          files2 = tag2.files()
          files2.save add_files, (err, reply) =>
            assert.ifError err
            tag2.all (err, reply) =>
              assert.ifError err
              ['1.0', '1.1'].should.include(reply['tags'][0]['name'])
              ['1.0', '1.1'].should.include(reply['tags'][1]['name'])
              done()

  it "should be able to remove a single tag from an app", (done) ->
    tags1 = app.tags().build('sillytag')
    tags1.save (err, reply) =>
      assert.ifError err
      tags2 = app.tags().build('thefunk')
      tags2.save (err, reply) =>
        assert.ifError err
        tags2.delete "thefunk", (err, reply) =>
          fs.exists [config.get('repository'),
          "zoidberg", "brainslugs", "tags", "thefunk"].join('/'),
            (exists) ->
              exists.should.equal false
              tags2.list (err, reply) =>
                assert.ifError err
                assert.deepEqual reply, ["sillytag"]
                done()

  it "should be able to remove all tags from an app", (done) ->
    tags1 = app.tags().build('sillytag')
    tags1.save (err, reply) =>
      assert.ifError err
      tags2 = app.tags().build('thefunk')
      tags2.save (err, reply) =>
        assert.ifError err
        tags2.delete_all (err, reply) =>
          tags2.list (err, reply) =>
            assert.ifError err
            assert.deepEqual reply, []
            done()
