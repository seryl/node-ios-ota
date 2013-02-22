fs = require 'fs'
path = require 'path'
rest = require 'request'
http = require 'http'
mkdirp = require 'mkdirp'
FormData = require 'form-data'

Logger = require '../src/logger'
User = require '../src/models/user'
WebServer = require '../src/webserver'

describe 'WebServer', ->
  ws = null
  logger = Logger.get()

  url = "http://127.0.0.1:#{config.get('port')}"
  client = rest

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
    client.get url, json: true, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "ios-ota"
      assert.notEqual data.version, undefined
      done()

  it "should allow new user creation for the admin", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      assert.ifError err
      data.name.should.equal "test_user"
      data.secret.length.should.equal 16
      done()

  it "should be able to list users", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.post "#{url}/users/silly_user", json: true
      , form: admin_creds, (err, res, data) ->
        client.get "#{url}/users", json: true
        ,(err, res, data) ->
          assert.ifError err
          data.users.should.include 'silly_user'
          data.users.should.include 'test_user'
          done()

  it "should be able to get information for a user", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.get "#{url}/test_user", json: true
      , (err, res, data) ->
        assert.ifError err
        data.user.should.equal 'test_user'
        data.location.should.equal 'test_user'
        assert.deepEqual data.applications, []
        done()

  it "should be able to add an application for a user", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.put "#{url}/test_user/example_app", json: true
      , form: admin_creds, (err, res, data) ->
        assert.ifError err

        client.get "#{url}/test_user", json: true
        , (err, res, data) ->
          assert.ifError err
          data.user.should.equal 'test_user'
          data.location.should.equal 'test_user'
          assert.deepEqual data.applications, ['example_app']
          done()

  it "should list all the tags for an app", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.get "#{url}/test_user/example_app/tags", json: true
      , (err, res, data) ->
        assert.ifError err
        data.name.should.equal "test_user/example_app/tags"
        assert.deepEqual data.tags, []
        done()

  it "should list all the branches for an app", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.get "#{url}/test_user/example_app/branches", json: true
      , (err, res, data) ->
        assert.ifError err
        data.name.should.equal "test_user/example_app/branches"
        assert.deepEqual data.branches, []
        done()

  it "should show info for a tag", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.get "#{url}/test_user/example_app/tags/1.0", json: true
      , (err, res, data) ->
        assert.ifError err
        data.name.should.equal "1.0"
        assert.deepEqual data.files, []
        done()

  it "should show info for a branch", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      client.get "#{url}/test_user/example_app/branches/master", json: true
      , (err, res, data) ->
        assert.ifError err
        data.name.should.equal "master"
        assert.deepEqual data.files, []
        done()

  it "should be able to add/update a tag", (done) ->
    cmp_files = [
      { name: "1.0.plist", md5: "0a1b8472e01bc836acecd246347d4492" },
      { name: "1.0.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" }
    ]

    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      file_mapping = fix_files.map (fmapping) ->
        name: path.basename(fmapping.file)
        value: fs.createReadStream(fmapping.file)

      form = new FormData()
      form.append('username', admin_creds.username)
      form.append('secret',   admin_creds.secret)
      for f in file_mapping
        form.append(f.name, f.value)

      http_info = url.split('//')[1].split(':')
      http_host = http_info[0]
      http_port = http_info[1]

      req = http.request(
        method: 'post'
        host: http_host
        port: http_port
        path: "/test_user/example_app/tags/1.0"
        headers: form.getHeaders())

      form.pipe(req)

      req.on 'response', (res) =>
        res.on 'data', (data) =>
          response_data = JSON.parse(data.toString())
          ['1.0.plist', '1.0.ipa'].should.include response_data.files[0].name
          ['1.0.plist', '1.0.ipa'].should.include response_data.files[1].name
          done()

      req.on 'error', (error) =>
        throw new Error(error)
        done()

  it "should be able to add/update a branch", (done) ->
    cmp_files = [
      { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" },
      { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" }
    ]

    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      file_mapping = fix_files.map (fmapping) ->
        name: path.basename(fmapping.file)
        value: fs.createReadStream(fmapping.file)

      form = new FormData()
      form.append('username', admin_creds.username)
      form.append('secret',   admin_creds.secret)
      for f in file_mapping
        form.append(f.name, f.value)

      http_info = url.split('//')[1].split(':')
      http_host = http_info[0]
      http_port = http_info[1]

      req = http.request(
        method: 'post'
        host: http_host
        port: http_port
        path: "/test_user/example_app/branches/master"
        headers: form.getHeaders())

      form.pipe(req)

      req.on 'response', (res) =>
        res.on 'data', (data) =>
          response_data = JSON.parse(data.toString())
          ['master.plist', 'master.ipa'].should.include response_data.files[0].name
          ['master.plist', 'master.ipa'].should.include response_data.files[1].name
          done()

      req.on 'error', (error) =>
        throw new Error(error)
        done()

  it "should be able to add/update an archive", (done) ->
    cmp_files = [
      { name: "master.plist", md5: "0a1b8472e01bc836acecd246347d4492" },
      { name: "master.ipa",   md5: "8b64ea08254c85e69d65ee7294431e0a" }
    ]

    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) =>

      upload_appfiles = (archive, fn) =>
        file_mapping = fix_files.map (fmapping) =>
          name: path.basename(fmapping.file)
          value: fs.createReadStream(fmapping.file)

        form = new FormData()
        form.append('username', admin_creds.username)
        form.append('secret',   admin_creds.secret)
        for f in file_mapping
          form.append(f.name, f.value)

        http_info = url.split('//')[1].split(':')
        http_host = http_info[0]
        http_port = http_info[1]

        app_url = "/test_user/example_app/branches/master"
        if archive
          app_url = [app_url, "archives", "1"].join('/')

        req = http.request(
          method: 'post'
          host: http_host
          port: http_port
          path: app_url
          headers: form.getHeaders())

        form.pipe(req)

        req.on 'response', (res) =>
          res.on 'data', (data) =>
            response_data = JSON.parse(data.toString())
            fn(null, response_data)

        req.on 'error', (error) =>
          throw new Error(error)
          done()

      upload_appfiles false, (err, data) =>
        upload_appfiles true, (err, data) =>
          done()

  it "should be able to delete a tag", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      file_mapping = fix_files.map (fmapping) ->
        name: path.basename(fmapping.file)
        value: fs.createReadStream(fmapping.file)

      upload_appfiles = () =>
        form = new FormData()
        form.append('username', admin_creds.username)
        form.append('secret',   admin_creds.secret)
        for f in file_mapping
          form.append(f.name, f.value)

        http_info = url.split('//')[1].split(':')
        http_host = http_info[0]
        http_port = http_info[1]

        req = http.request(
          method: 'post'
          host: http_host
          port: http_port
          path: "/test_user/example_app/tags/1.0"
          headers: form.getHeaders())

        form.pipe(req)

        req.on 'response', (res) =>
          res.on 'data', (data) =>
            response_data = JSON.parse(data.toString())
            ['1.0.plist', '1.0.ipa'].should.include response_data.files[0].name
            ['1.0.plist', '1.0.ipa'].should.include response_data.files[1].name
            check_tags()

        req.on 'error', (error) =>
          throw new Error(error)
          done()

      check_tags = () =>
        client.get "#{url}/test_user/example_app/tags", json: true
        , (err, res, data) =>
            assert.ifError err
            data.tags[0].should.equal "1.0"
            test_delete()

      test_delete = () =>
        client.del "#{url}/test_user/example_app/tags/1.0", json: true
        , (err, res, data) =>
          client.get "#{url}/test_user/example_app/tags", json: true
          , (err, res, data) =>
            assert.ifError err
            data.tags.length.should.equal 0
            done()

      upload_appfiles()

  it "should be able to delete a branch", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) ->
      file_mapping = fix_files.map (fmapping) ->
        name: path.basename(fmapping.file)
        value: fs.createReadStream(fmapping.file)

      upload_appfiles = () =>
        form = new FormData()
        form.append('username', admin_creds.username)
        form.append('secret',   admin_creds.secret)
        for f in file_mapping
          form.append(f.name, f.value)

        http_info = url.split('//')[1].split(':')
        http_host = http_info[0]
        http_port = http_info[1]

        req = http.request(
          method: 'post'
          host: http_host
          port: http_port
          path: "/test_user/example_app/branches/master"
          headers: form.getHeaders())

        form.pipe(req)

        req.on 'response', (res) =>
          res.on 'data', (data) =>
            response_data = JSON.parse(data.toString())
            ['master.plist', 'master.ipa'].should.include response_data.files[0].name
            ['master.plist', 'master.ipa'].should.include response_data.files[1].name
            check_tags()

        req.on 'error', (error) =>
          throw new Error(error)
          done()

      check_tags = () =>
        client.get "#{url}/test_user/example_app/branches", json: true
        , (err, res, data) =>
            assert.ifError err
            data.branches[0].should.equal "master"
            test_delete()

      test_delete = () =>
        client.del "#{url}/test_user/example_app/branches/master", json: true
        , (err, res, data) =>
          client.get "#{url}/test_user/example_app/branches", json: true
          , (err, res, data) =>
            assert.ifError err
            data.branches.length.should.equal 0
            done()

      upload_appfiles()

  it "should allow deletion of a user for the admin", (done) ->
    client.post "#{url}/users/test_user", json: true
    , form: admin_creds, (err, res, data) =>
      client.post "#{url}/users/silly_user", json: true
      , form: admin_creds, (err, res, data) =>
        assert.ifError err
        data.name.should.equal "silly_user"
        data.secret.length.should.equal 16
        client.get "#{url}/users", json: true
        , (err, res, data) =>
          assert.ifError err
          data.users.should.include 'silly_user'
          data.users.should.include 'test_user'

          client.del "#{url}/users/test_user", json: true
          , (err, res, data) =>
            assert.ifError err
            client.get "#{url}/users", json: true
            , (err, res, data) =>
              assert.ifError err
              data.users.should.include 'silly_user'
              data.users.should.not.include 'test_user'
              client.del "#{url}/users/silly_user", json: true
              , (err, res, data) =>
                assert.ifError err
                client.get "#{url}/users", json: true
                , (err, res, data) =>
                  assert.ifError err
                  data.users.length.should.equal 0
                  done()
