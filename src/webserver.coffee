restify = require 'restify'
formidable = require 'formidable'
require('pkginfo')(module, 'name', 'version')

Config = require './config'
Logger = require './logger'
{Identity, generate_identity} = require './identity'
User = require './models/user'

###*
 * The iOS-ota webserver command line interface class.
###
class WebServer
  constructor: (@port=8080) ->
    @config = Config.get()
    @logger = Logger.get()
    @identity = Identity.get()
    @app = restify.createServer( name: exports.name )
    @app.use(restify.authorizationParser());
    @app.use(restify.bodyParser({ mapParams: true }))
    @setup_routing()
    @app.listen(@port)
    @logger.info "Webserver is up at: http://0.0.0.0:#{@port}"

  # Sets up the webserver routing.
  setup_routing: () =>

    # Returns the base name and version of the app.
    @app.get '/', (req, res, next) =>
      res.json 200, 
        name: exports.name,
        version: exports.version

    # List help.
    @app.get '/help', (req, res, next) =>
      res.json 200
        message: "restdown docs coming soon."
      next()

    # Silence favicon requests.
    @app.get '/favicon.ico', (req, res, next) =>
      next new restify.codeToHttpError(404, "No favicon exists.")

    # Returns the current list of users.
    @app.get '/users', (req, res, next) =>
      user = new User
      user.list (err, userlist) =>
        if err
          next new restify.codeToHttpError(500, "Error retrieving user list.")
          return next()
        res.json 200,
          users: userlist
        return next()

    # Creates or updates a user. (Requires Auth)
    @app.post '/users/:user', (req, res, next) =>
      user = req.params.user
      handle_auth_response = (err, reply) =>
        if err
          if err.code == "UserDoesNotExist"
            res.json 401,
              code: 401
              message: err.message
          if err.code == "InvalidPassword"
            res.json 401,
              code: 401
              message: "Unauthorized: Invalid authentication secret."
          else
            res.json 500,
              code: 500,
              message: reply.message
          return next()

        if user.username == "admin"
          res.json 403,
            code: 403,
            message: "Unable to modify the administrative user."
          return next()

        if !reply.admin
          res.json 401,
            code: 401,
            message: "Only administrators are permitted to modify accounts."
          return next()

        user = new User({ name: req.params.user })
        user.save (err, reply) =>
          console.log(reply)

        res.json 200
          message: reply
        return next()

      @authenticate_with_self_admin(req, handle_auth_response, user)

    # Returns the user-specific info.
    @app.get '/:user', (req, res, next) =>
      location = [req.params.user]
      loc = location.join('/')
      location.unshift(@config.get('repository'))
      @redis.get_user req.params.user, (err, user) =>
        if err
          return res.json 500,
            code: 500
            user: req.params.user
            message: ''.concat(
              "Error retrieving info for user `", req.params.user, "`.")
        if !user
          return res.json 404,
            code: 404
            user: req.params.user
            message: ''.concat(
              "The user `", req.params.user, "` does not exist.")

        @redis.get_applications req.params.user, (err, apps) =>
          if err
            return res.json 500,
              code: 500
              message: ''.concat(
                "Error retrieving apps for user `", loc, "`.")
          return res.json 200,
            user: req.params.user
            location: loc
            apps: if apps then apps else []

    # Deletes a user. (Requires Auth)
    # 
    # NOTE: Currently this does not use authentication at all.
    #       Restify doesn't parse body parameters with delete requests yet.
    #
    #       https://github.com/mcavage/node-restify/issues/180
    @app.del '/users/:user', (req, res, next) =>
      target = req.params.user
      if target in ["admin"]
        res.json 403,
          code: 403
          message: "Unable to modify internal services."
        return next()

      user = new User()
      user.delete(target, (err, reply) =>
        res.json 200,
          message: ''.concat(
            "Successfully deleted user `" + target + "`.")
        return next())

    # Returns the list of applications for a specific user.
    @app.get '/:user/:app', (req, res, next) =>
      location = [req.params.user, req.params.app]
      loc = location.join('/')
      location.unshift(@config.get('repository'))
      fs.readdir location.join('/'),
        (err, reply) =>
          if err
            return res.json 404,
              code: 404
              user: req.params.user
              app: req.params.app
              message: ''.concat(
                "The application `", req.params.app, "` does not exist.")

    # Lists all of the branches for a specified user/application.
    @app.get '/:user/:app/branches', (req, res, next) =>
      location = [req.params.user, req.params.app, 'branches']
      loc = location.join('/')
      location.unshift(@config.get('repository'))
      fs.readdir location.join('/'),
        (err, reply) =>
          console.log(err)
          console.log(reply)
          return res.json 200,
            message: "branches"

    # Lists all of the tags for a specified user/application.
    @app.get '/:user/:app/tags', (req, res) =>
      location = [req.params.user, req.params.app, 'tags']
      res.json 200,
        name: [req.params.user, req.params.app, 'tags'].join('/'),
        tags: []

    # Posts new files to a specified user/application.
    @app.post '/:user/:app/branches', (req, res) ->
      location = [req.params.user, req.params.app, 'branches']
      form = formidable.IncomingForm()
      form.parse req, (err, fields, files) ->
        res.json 200,
          message: "Recieved Upload",
          fields: fields,
          files: files

    # Posts new tags to a specified user/application.
    @app.post '/:user/:app/tags', (req, res) ->
      location = [req.params.user, req.params.app, 'tags']
      form = formidable.IncomingForm()
      form.parse req, (err, fields, files) ->
        res.json 200,
          message: "Recieved Upload",
          fields: fields,
          files: files

  ###*
   * Authenticates the user.
   * @param {Object} (req) The restify request object
   * @param {Function} (fn) The callback function
  ###
  authenticate: (req, fn) =>
    err = false
    credentials =
      username: req.params.username
      secret: req.params.secret

    if !credentials.username
      err = true
      reply =
        code: 401,
        message: "Unauthorized: No username parameter was provided."

    if !credentials.secret
      err = true
      reply =
        code: 401,
        message: "Unauthorized: No secret parameter was provided."

    if credentials.username == "admin"
      if credentials.secret != @config.get('admin_secret')
        err = true
        reply =
          code: 401,
          message: "Unauthorized: Invalid authentication secret."
      else
        reply =
          admin: true
      return fn(err, reply)
    else
      user = new User()
      user.check_login credentials, (err, authenticated) =>
        if authenticated
          reply =
            admin: false
        else if err.code == "ErrorConnectingToRedis"
          err = true
          reply =
            code: 500
            message: "Error connecting to redis."
        else
          err = true
          reply =
            code: 401,
            message: "Unauthorized: Invalid authentication secret."
        return fn(err, reply)

  ###*
   * Authenticates the user, and if the user is managing themselves, elevate.
   * @param {Object} (req) The restify request object
   * @param {Function} (fn) The callback function
   * @param {String} (user) The user to test against for elevated privs
  ###
  authenticate_with_self_admin: (req, fn, user) =>
    credentials =
      username: req.params.username
      secret: req.params.secret

    @authenticate req, (err, reply) =>
      if credentials.username == user
        reply.admin = true
      return fn(err, reply)

module.exports = WebServer
