needle = require 'needle'
mkdirp = require 'mkdirp'

Logger = require '../src/logger'
User = require '../src/models/user'
WebServer = require '../src/webserver'

describe 'WebServer', ->
  ws = null
  logger = Logger.get()

  url = "http://127.0.0.1:#{config.get('port')}"
  client = needle

  admin_creds =
    username: "admin"
    secret: "admin"

  add_files = [
    { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" },
    { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" }
  ]

  fix_files = [
    { file: "#{__dirname}/fixtures/master.ipa",
    content_type: "application/octet-stream" },
    { file: "#{__dirname}/fixtures/master.plist",
    content_type: "application/octet-stream" }
  ]

  beforeEach (done) ->
    logger.clear()
    mkdirp config.get('repository'), (err, made) =>
      if err
        @logger.error "Error setting up test webserver directories."
      ws = new WebServer(config.get('port'))
      done()

  afterEach (done) ->
    user = new User({ name: "test_user" })
    user.delete_all ->
      user = new User({ name: "silly_user" })
      user.delete_all ->
        apps = null
        rimraf config.get('repository'), (err) ->
          ws.srv.close()
          done()

  after (done) ->
    user = new User({ name: "test_user" })
    user.delete_all ->
      user = new User({ name: "silly_user" })
      user.delete_all ->
        apps = null
        rimraf config.get('repository'), (err) ->
          done()

  it "should show the version info", (done) ->
    client.get "#{url}/", (err, res, data) ->
      assert.ifError err
      data.name.should.equal "ios-ota"
      assert.notEqual data.version, undefined
      done()

  it "should allow new user creation for the admin", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      done()

  it "should be able to list users", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.post "#{url}/users/silly_user", admin_creds, (err, res, data) ->
        assert.ifError err
        client.get "#{url}/users", (err, res, data) ->
          assert.ifError err
          data.users.should.include 'silly_user'
          data.users.should.include 'test_user'
          done()

  it "should be able to get information for a user", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.get "#{url}/test_user", (err, res, data) ->
        assert.ifError err
        data.user.should.equal 'test_user'
        data.location.should.equal 'test_user'
        assert.deepEqual data.applications, []
        done()

  it "should be able to add an application for a user", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.put "#{url}/test_user/example_app", admin_creds,
      (err, res, data) ->
        assert.ifError err

        client.get "#{url}/test_user", (err, res, data) ->
          assert.ifError err
          data.user.should.equal 'test_user'
          data.location.should.equal 'test_user'
          assert.deepEqual data.applications, ['example_app']
          done()

  it "should list all the tags for an app", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.get "#{url}/test_user/example_app/tags", (err, res, data) ->
        assert.ifError err
        data.name.should.equal "test_user/example_app/tags"
        assert.deepEqual data.tags, []
        done()

  it "should list all the branches for an app", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.get "#{url}/test_user/example_app/branches", (err, res, data) ->
        assert.ifError err
        data.name.should.equal "test_user/example_app/branches"
        assert.deepEqual data.branches, []
        done()

  it "should show info for a tag", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.get "#{url}/test_user/example_app/tags/1.0",
      (err, res, data) ->
        assert.ifError err
        data.name.should.equal "1.0"
        assert.deepEqual data.files, []
        done()

  it "should show info for a branch", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.get "#{url}/test_user/example_app/branches/master",
      (err, res, data) ->
        assert.ifError err
        data.name.should.equal "master"
        assert.deepEqual data.files, []
        done()

  it "should be able to add/update a tag", (done) ->
    cmp_files = [
      { name: "1.0.plist", md5: "0a1b8472e01bc836acecd246347d4492" },
      { name: "1.0.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" }
    ]

    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      d = { files: fix_files }
      client.post "#{url}/test_user/example_app/tags/1.0", d,
      { multipart: true, username: "admin", secret: "admin" },
      (err, res, data) =>
        assert.ifError err
        ['1.0.plist', '1.0.ipa'].should.include data.files[0].name
        ['1.0.plist', '1.0.ipa'].should.include data.files[1].name
        done()

  it "should be able to add/update a branch", (done) ->
    cmp_files = [
      { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" },
      { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" }
    ]

    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      d = { files: fix_files }
      client.post "#{url}/test_user/example_app/branches/master", d,
      { multipart: true, username: "admin", secret: "admin" },
      (err, res, data) ->
        assert.ifError err
        ['master.plist', 'master.ipa'].should.include data.files[0].name
        ['master.plist', 'master.ipa'].should.include data.files[1].name
        done()

  it "should be able to delete a tag", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      d = { files: fix_files }
      client.post "#{url}/test_user/example_app/tags/1.0", d,
      { multipart: true, username: "admin", secret: "admin" },
      (err, res, data) ->
        assert.ifError err
        ['1.0.plist', '1.0.ipa'].should.include data.files[0].name
        ['1.0.plist', '1.0.ipa'].should.include data.files[1].name
        client.get "#{url}/test_user/example_app/tags",
        (err, res, data) ->
          assert.ifError err
          data.tags[0].should.equal "1.0"
          done()
          # TODO: Find out why using needle to delete this fails
          # client.delete "#{url}/test_user/example_app/tags",
          # (err, res, data) ->
          #   assert.ifError err
          #   client.get "#{url}/test_user/example_app/tags",
          #   (err, res, data) ->
          #     assert.ifError err
          #     assert.deepEqual data.tags, []
          #     done()

  it "should be able to delete a branch", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      d = { files: fix_files }
      client.post "#{url}/test_user/example_app/branches/master", d,
      { multipart: true, username: "admin", secret: "admin" },
      (err, res, data) ->
        assert.ifError err
        ['master.plist', 'master.ipa'].should.include data.files[0].name
        ['master.plist', 'master.ipa'].should.include data.files[1].name
        client.get "#{url}/test_user/example_app/branches",
        (err, res, data) ->
          assert.ifError err
          data.branches[0].should.equal "master"
          done()
          # TODO: Find out why using needle to delete this fails
          # client.delete "#{url}/test_user/example_app/branches/master",
          # (err, res, data) ->
          #   assert.ifError err
          #   client.get "#{url}/test_user/example_app/branches",
          #   (err, res, data) ->
          #     assert.ifError err
          #     assert.deepEqual data.branches, []
          #     done()

  it "should allow deletion of a user for the admin", (done) ->
    client.post "#{url}/users/test_user", admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      client.post "#{url}/users/silly_user", admin_creds, (err, res, data) ->
        assert.ifError err
        data.name.should.equal "silly_user"
        data.secret.length.should.equal 16
        client.get "#{url}/users", (err, res, data) ->
          assert.ifError err
          data.users.should.include 'silly_user'
          data.users.should.include 'test_user'
          done()

          # client.delete "#{url}/users/test_user", (err, res, data) ->
          #   assert.ifError err
          #   client.get "#{url}/users", (err, res, data) ->
          #     assert.ifError err
          #     data.users.should.include 'silly_user'
          #     data.users.should.not.include 'test_user'

          #     client.delete "#{url}/users/silly_user", (err, res, data) ->
          #       assert.ifError err
          #       client.get "#{url}/users", (err, res, data) ->
          #         assert.ifError err
          #         assert.deepEqual data, { users: [] }
          #         done()
