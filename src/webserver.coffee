Logger = require './logger'
restify = require 'restify'
formidable = require 'formidable'
{Identity, generate_identity} = require './identity'

class WebServer
  constructor: (@port=8080, @pkg_info) ->
    @logger = Logger.get()
    @identity = Identity.get()
    @app = restify.createServer()
    @setup_routes()
    @app.listen(@port)
    @logger.info "Webserver is up at: http://0.0.0.0:#{@port}"

  setup_routes: () =>
    @app.get '/', (req, res) =>
      res.json 200, 
        name: @pkg_info.name,
        version: @pkg_info.version

    @app.get '/:user/releases', (req, res) =>
      res.json 200,
        name: "/:user/releases",
        releases: []

    @app.post '/:user/releases', (req, res) ->
      @logger.info req
      form = formidable.IncomingForm()
      form.parse req, (err, fields, files) ->
        res.json 200,
          message: "Recieved Upload",
          fields: fields,
          files: files

  setup_

module.exports = WebServer
