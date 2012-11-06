restify = require 'restify'

Logger = require '../src/logger'
CLI = require '../src/cli'
WebServer = require '../src/webserver'

describe 'WebServer', ->
  ws = null
  cli = new CLI()
  logger = Logger.get()

  client = restify.createJsonClient
    url: 'http://127.0.0.1:8080'
    version: '*'

  admin_creds =
    username: "admin"
    secret: "admin"

  add_files = [
    { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
    { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
  ]

  beforeEach (done) ->
    logger.clear()
    ws = new WebServer(8080)
    done()

  afterEach (done) ->
    ws.app.close()
    done()

  it "should show the version info", (done) ->
    client.get '/', (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "ios-ota"
      assert.notEqual data.version, undefined
      done()

  it "should allow new user creation for the admin", (done) ->
    client.post '/users/test_user', admin_creds, (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      done()

  it "should be able to list users", (done) ->
    client.post '/users/silly_user', admin_creds, (err, req, res, data) ->
      assert.ifError err
      client.get '/users', (err, req, res, data) ->
        assert.ifError err
        assert.deepEqual data, { users: ['silly_user', 'test_user'] }
        done()

  it "should be able to get information for a user", (done) ->
    client.get '/test_user', (err, req, res, data) ->
      assert.ifError err
      data.user.should.equal 'test_user'
      data.location.should.equal 'test_user'
      assert.deepEqual data.applications, []
      done()

  it "should be able to add an application for a user", (done) ->
    client.put '/test_user/example_app', {}, (err, req, res, data) ->
      assert.ifError err

      client.get '/test_user', (err, req, res, data) ->
        assert.ifError err
        data.user.should.equal 'test_user'
        data.location.should.equal 'test_user'
        assert.deepEqual data.applications, ['example_app']
        done()

  it "should list all the tags for an app", (done) ->
    client.get '/test_user/example_app/tags', (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user/example_app/tags"
      assert.deepEqual data.tags, []
      done()

  it "should list all the branches for an app", (done) ->
    client.get '/test_user/example_app/branches', (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user/example_app/branches"
      assert.deepEqual data.branches, []
      done()

  it "should be able to add/update a tag", (done) ->
    client.post '/test_user/example_app/tags/1.0',
    {files: add_files}, (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "1.0"
      done()

  it "should be able to add/update a branch", (done) ->
    client.post '/test_user/example_app/branches/master',
    {files: add_files}, (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "master"
      done()

  it "should show info for a tag", (done) ->
    client.get '/test_user/example_app/tags/1.0',
    (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "1.0"
      assert.deepEqual data.files, []
      done()

  it "should show info for a branch", (done) ->
    client.get '/test_user/example_app/branches/master',
    (err, req, res, data) ->
      assert.ifError err
      data.name.should.equal "master"
      assert.deepEqual data.files, []
      done()

  it "should be able to update the tag list"

  it "should be able to update the branch list"

  it "should be able to delete a tag"

  it "should be able to delete a branch"

  it "should be able to synchronize files for a tag"

  it "should be able to synchronize files for a branch"

  it "should allow deletion of a user for the admin", (done) ->
    client.get '/users', (err, req, res, data) ->
      assert.ifError err
      assert.deepEqual data, { users: ['silly_user', 'test_user'] }

      client.del '/users/test_user', (err, req, res, data) ->
        assert.ifError err
        client.get '/users', (err, req, res, data) ->
          assert.ifError err
          assert.deepEqual data, { users: ['silly_user'] }

          client.del '/users/silly_user', (err, req, res, data) ->
            assert.ifError err
            client.get '/users', (err, req, res, data) ->
              assert.ifError err
              assert.deepEqual data, { users: [] }
              done()
