Logger = require './logger'
Config = require './config'
restify = require 'restify'
{Identity, generate_identity} = require './identity'
RedisUtils = require './redisutils'

fs = require 'fs'
formidable = require 'formidable'

###*
 * The iOS-ota webserver command line interface class.
###
class WebServer
  constructor: (@port=8080, @pkg_info) ->
    @config = Config.get()
    @logger = Logger.get()
    @identity = Identity.get()
    @redis = RedisUtils.get()
    @app = restify.createServer()
    @setup_routing()
    @app.listen(@port)
    @logger.info "Webserver is up at: http://0.0.0.0:#{@port}"

  setup_routing: () =>
    @app.get '/', (req, res) =>
      res.json 200, 
        name: @pkg_info.name,
        version: @pkg_info.version

    @app.get '/users', (req, res) =>
      @redis.get_users (err, reply) ->
        if err
          return res.json 500,
            message: reply

        return res.json 200,
          users: if reply then reply else []

    @app.post '/users', (req, res) =>
      @logger.info req.params.user
      res.json 200,
        name: "ok"
      # @redis.authenticate()
      # @redis.add_or_update_user(req.params.user)
      # console.log(req)
      # res.json 200,
      #   name: "OK"
      # @logger.
      # @redis.add_user()

    # @app.get '/:user/:app/branches', (req, res) =>
    #   res.json 200,
    #     name: [req.params.user, req.params.app, 'branches'].join('/'),
    #     branches: fs.readdirSync([
    #       @config.get('repository'), req.params.user, req.params.app
    #     ].join('/'))

    # @app.post '/releases', (req, res) ->
    #   @logger.info req
    #   form = formidable.IncomingForm()
    #   form.parse req, (err, fields, files) ->
    #     res.json 200,
    #       message: "Recieved Upload",
    #       fields: fields,
    #       files: files

module.exports = WebServer
