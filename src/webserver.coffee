fs = require 'fs'
restify = require 'restify'
util = require 'util'
require('pkginfo')(module, 'name', 'version')

Config = require './config'
Logger = require './logger'
{Identity, generate_identity} = require './identity'
User = require './models/user'

###*
 * The iOS-ota webserver class.
###
class WebServer
  constructor: ->
    @config = Config.get()
    @logger = Logger.get()
    @identity = Identity.get()
    @app = restify.createServer( name: exports.name )
    @app.use(restify.authorizationParser());
    @app.use(restify.bodyParser({ mapParams: true, maxBodySize: 0 }))
    @setup_routing()
    @app.listen(@config.get('port'))
    @logger.info "Webserver is up at: http://0.0.0.0:#{@config.get('port')}"

  # Sets up the webserver routing.
  setup_routing: =>

    # Returns the base name and version of the app.
    @app.get '/', (req, res, next) =>
      res.json 200, 
        name: exports.name,
        version: exports.version

    # List help.
    @app.get '/help', (req, res, next) =>
      res.json 200
        message: "restdown docs coming soon."
      return next()

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
          res.json 200, reply
          return next()

      @authenticate_with_self_admin(req, handle_auth_response, user)

    # Returns the user-specific info.
    @app.get '/:user', (req, res, next) =>
      username = req.params.user
      location = username
      user = new User({ name: username })
      user.exists username, (err, user_resp) =>
        if err
          res.json 500,
            code: 500
            location: location
            user: username
            message: "Error retrieving info for user `#{username}`."
          return next()

        if !user_resp
          res.json 404,
            code: 404
            location: location
            user: username
            message: "The user `#{username}` does not exist."
          return next()

        user.applications().list (err, reply) =>
          if err
            res.json 500,
              code: 500
              location: location
              user: username
              message: "Error retrieving apps for user `#{username}`."
            return next()

          res.json 200
            user: username
            location: location
            applications: reply
          return next()

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
          message: "Successfully deleted user `#{target}`."
        return next())

    # Creates a new application for a user.
    @app.put '/:user/:app', (req, res, next) =>
      user = new User({ name: req.params.user })
      user.applications().build(req.params.app).save (err, reply) =>
        res.json 200
          message: "Successfully updated application `#{req.params.app}`."
        return next()

    # Returns the list of branches/tags for a specific app.
    @app.get '/:user/:app', (req, res, next) =>
      location = [req.params.user, req.params.app]
      loc = location.join('/')

      user = new User({ name: req.params.user })
      app = user.applications()
      app.build(req.params.app).find req.params.app, (err, reply) =>
        if err
          res.json 404,
            code: 404
            user: req.params.user
            app: req.params.app
            location: loc
            message: "The application `#{req.params.app}` does not exist."
          return next()

        res.json 200,
          user: req.params.user
          app: req.params.app
          location: loc
          branches: reply.branches
          tags: reply.tags
        return next()

    # Lists all of the branches for a specified user/application.
    @app.get '/:user/:app/branches', (req, res, next) =>
      location = [req.params.user, req.params.app, 'branches']
      loc = location.join('/')
      location.unshift(@config.get('repository'))
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branches = app.branches()
      branches.list (err, reply) =>
        res.json 200,
          name: loc
          branches: reply
        return next()

    # Lists all of the tags for a specified user/application.
    @app.get '/:user/:app/tags', (req, res, next) =>
      location = [req.params.user, req.params.app, 'tags']
      loc = location.join('/')
      location.unshift(@config.get('repository'))
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tags = app.tags()
      tags.list (err, reply) =>
        res.json 200,
          name: loc
          tags: reply
        return next()

    # Creates or  a new tag
    @app.post '/:user/:app/tags/:tag', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tag = app.tags().build(req.params.tag)
      tag.save (err, reply) =>
        if typeof req.params.files == undefined
          res.json 200, name: reply
          return next()
        else
          mapto_flist = (file) =>
            return { location: file.path, name: file.name }

          # TODO: Check whether or we need to update the files.
          flist = [req.params.files[k] for k in Object.keys(req.params.files)]
          f_normal = [mapto_flist(f) for f in flist[0]][0]
          res.json 200, message: f_normal
          return next()

    # Creates or updates a branch re-updating files if they are passed.
    @app.post '/:user/:app/branches/:branch', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      branch.save (err, reply) =>
        if typeof req.params.files == undefined
          res.json 200, name: reply
          return next()
        else
          mapto_flist = (file) =>
            return { location: file.path, name: file.name }

          # TODO: Check whether or we need to update the files.
          flist = [req.params.files[k] for k in Object.keys(req.params.files)]
          f_normal = [mapto_flist(f) for f in flist[0]][0]
          files = branch.files()
          files.save f_normal, (err, reply) =>
            res.json 200, files: reply
            return next()

    # Shows the tag info for a specified user/application/tag
    @app.get '/:user/:app/tags/:tag', (req, res, next) =>
      if @is_ios_useragent(req)
        res.header('Location', "./#{req.params.tag}/download")
        res.send(302)
        return next()

      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tag = app.tags().build(req.params.tag)
      tag.find req.params.tag, (err, reply) =>
        res.json 200, reply
        return next()

    # Shows the branch info for a specified user/application/branch
    @app.get '/:user/:app/branches/:branch', (req, res, next) =>
      if @is_ios_useragent(req)
        res.header('Location', "./#{req.params.branch}/download")
        res.send(301)
        return next()

      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      branch.find req.params.branch, (err, reply) =>
        res.json 200, reply
        return next()

    # Deletes a tag
    @app.del '/:user/:app/tags/:tag', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      app.tags().delete req.params.tag, (err, reply) =>
        res.json 200, message: "successfully deleted `#{req.params.tag}`."
        return next()

    # Deletes a branch
    @app.del '/:user/:app/branches/:branch', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      app.branches().delete 'master', (err, reply) =>
        res.json 200, message: "successfully deleted `#{req.params.branch}`."
      return next()

    # Download plist files for a branch
    @app.get '/:user/:app/tags/:tag/download', (req, res, next) =>
      tg = req.params.tag
      res.header('Location', "./download/#{tg}.plist")
      res.send(301)
      return next()

    # Download plist files for a tag
    @app.get '/:user/:app/branches/:branch/download', (req, res, next) =>
      br = req.params.branch
      res.header('Location', "./download/#{br}.plist")
      res.send(301)
      return next()

    # Download specific file for a branch
    @app.get '/:user/:app/branches/:branch/download/:file', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branches = app.branches().build(req.params.branch)
      target = branches.files().filepath(req.params.file)

      fs.stat target, (err, reply) =>
        res.writeHead(200, {
          'Content-Type': 'application/octet-stream',
          'Content-Length': reply.size
        })
        readStream = fs.createReadStream(target)
        util.pump(readStream, res)
        return next()

    # Download specific file for a tag
    @app.get '/:user/:app/tags/:tag/download/:file', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tags = app.tags().build(reqs.params.tag)
      target = branches.files().filepath(req.params.file)

      fs.stat target, (err, reply) =>
        res.writeHead(200, {
          'Content-Type': 'application/octet-stream',
          'Content-Length': reply.size
        })
        readStream = fs.createReadStream(target)
        util.pump(readStream, res)
        return next()

  ###*
   * Check what the user-agent is an iPhone or iPad.
   * @params {Object} (req) The restify request object
   * @return {Boolean} Whether or not the user-agent is an iphone/ipad
  ###
  is_ios_useragent: (req) =>
    ua_regex = /[iI][pP](hone|ad)/
    return (req.headers['user-agent'].match(ua_regex) != null)

  redirect_to_plist: (req, res, next) =>
    res.header('Location', '/')
    res.send(302);
    return next(false);

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
      else reply = { admin: true }
      return fn(err, reply)
    else
      user = new User()
      user.check_login credentials, (err, authenticated) =>
        if authenticated then reply = { admin: false }
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
      if credentials.username == user then reply.admin = true
      return fn(err, reply)

module.exports = WebServer
