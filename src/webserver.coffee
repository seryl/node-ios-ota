restify = require 'restify'
fs = require 'fs'
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
      res.json 200, services: [
        {url: '/', method: 'GET', description: 'version info'},
        {url: '/help', method: 'GET', description: 'help information'},
        {url: '/users', method: 'GET', description: 'returns the list of users'},

        {url: '/:user', method: 'GET', description: 'returns the user info'},
        {url: '/:user', method: 'POST', description: 'adds or updates a user'},
        {url: '/:user', method: 'DELETE', description: 'deletes a user'},

        {url: '/:user/:app', method: 'GET', description: 'returns the app info'},
        {url: '/:user/:app', method: 'POST', description: 'adds or creates an app'},
        {url: '/:user/:app', method: 'DELETE', description: 'deletes an app'},

        {url: '/:/user/:app/branches', method: 'GET', description: 'returns the list of branches for a given app'},
        {url: '/:/user/:app/branches/:branch', method: 'GET', description: 'returns the branch info for the app'},
        {url: '/:/user/:app/branches/:branch', method: 'POST', description: 'add or updates the branch info for the app'},
        {url: '/:/user/:app/branches/:branch', method: 'DELETE', description: 'deletes a branch for the app'},

        {url: '/:/user/:app/tags', method: 'GET', description: 'returns the list of branches for a given app'},
        {url: '/:/user/:app/branches/:branch', method: 'GET', description: 'returns the branch info for the app'},
        {url: '/:/user/:app/branches/:branch', method: 'POST', description: 'add or updates the branch info for the app'},
        {url: '/:/user/:app/branches/:branch', method: 'DELETE', description: 'deletes a branch for the app'},
      ]

    # Silence favicon requests.
    @app.get '/favicon.ico', (req, res, next) =>
      return next(new restify.codeToHttpError(404, "No favicon exists."))

    # Returns the current list of users.
    @app.get '/users', (req, res, next) =>
      new User({ name: "bobby" }).save (err, user) =>
        res.json 200,
          user: user
      # new User().all { name: true }, (err, users) =>
      #   res.json 200,
      #     users: users
      # @redis.get_users (err, reply) ->
      #   if err
      #     return res.json 500,
      #       code: 500
      #       message: reply
      #   return res.json 200,
      #     users: if reply then reply else []

    # Creates or updates a user. (Requires Auth)
    @app.post '/users', (req, res, next) =>
      @authenticate req, (err, reply) =>
        if err
          return res.json reply.code,
            code: reply.code
            message: reply.message

        user = req.params.user
        if user.username == "admin"
          return res.json 403,
            code: 403,
            message: "Unable to modify the administrative user."

        if user.username in ["help", "users"]
          return res.json 403,
            code: 403
            message: "Unable to modify internal users."

        if !reply.admin
          return res.json 401,
            code: 401,
            message: "Only administrators are allowed to modify accounts."

        fs.mkdir [@config.get('repository'), user.username].join('/'),
          () =>
            bcrypt.genSalt 10, (err, salt) =>
              if err
                return res.json 500,
                  code: 500,
                  message: "Error creating bcrypt salt."

              bcrypt.hash user.secret, salt, (error, hash) =>
                if error
                  return res.json 500,
                    code: 500,
                    message: "Error creating bcrypt hash."
                user.secret = hash
                @redis.add_or_update_user user, (err, reply) =>
                  if err
                    return res.json 500,
                      code: 500,
                      message: "Error updating user: " + user.username
                  return res.json 200
                    message: "Successfully updated: " + user.username

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
    @app.del '/:user', (req, res, next) =>
      if req.params.user in ["help", "users"]
        return res.json 403,
          code: 403
          message: "Unable to modify internal services."

      @redis.remove_user req.params.user, (err, reply) =>
        if err
          return res.json 500,
            code: 500,
            message: ''.concat("Error deleting user `", req.params.user, "`.")
        res.json 200,
          message: ''.concat(
            "Successfully deleted the user `", req.params.user, "`.")

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
      @redis.check_login credentials, (err, authenticated) =>
        if authenticated
          reply =
            admin: false
        else
          err = true
          reply =
            code: 401,
            message: "Unauthorized: Invalid authentication secret."
        return fn(err, reply)

module.exports = WebServer
