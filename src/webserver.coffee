common = require './common'
restify = require 'restify'
formidable = require 'formidable'
app = restify.createServer()

module.exports =
  start_server: () ->
    this.setup_routes()
    app.listen('3000')
    console.log "Webserver is up at: http://0.0.0.0:%s", 3000

  setup_routes: () ->
    app.get '/', (req, res) ->
      res.json(200, 
        name: app_info.name,
        version: app_info.version)

    app.post '/test', (req, res) ->
      console.log(req)
      form = formidable.IncomingForm()
      form.parse req, (err, fields, files) ->
        res.json 200,
          message: "Recieved Upload",
          fields: fields,
          files: files

    return
