Logger = require '../src/logger'
WebServer = require '../src/webserver'
restify = require 'restify'

describe 'Webserver', ->
  ws = null
  client = restify.createJsonClient
    url: 'http://127.0.0.1:8080'
    version: '*'
  logger = Logger.get()

  beforeEach (done) ->
    logger.clear()
    ws = new WebServer(8080)
    done()

  afterEach (done) ->
    ws.app.close()
    done()

  it "should show the version information at /", (done) ->
    client.get '/', (err, req, res, data) ->
      assert.equal err, null
      data.name.should.equal "ios-ota"
      assert.notEqual data.version, undefined
      done()
