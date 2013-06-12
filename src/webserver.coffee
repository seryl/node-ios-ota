fs = require 'fs.extra'
express = require 'express'
http = require 'http'
plist = require 'plist'
async = require 'async'
require('pkginfo')(module, 'name', 'version')

config = require 'nconf'
logger = require './logger'
{identity, generate_identity} = require './identity'
User = require './models/user'

errorHandler = (err, req, res, next) ->
  res.json(500, error: err)

###
The iOS-ota webserver class.
###
class WebServer
  constructor: ->
    @app = express()
    @app.configure

    @app.use express.bodyParser
      uploadDir: '/tmp',
      keepExtensions: false
    @app.use(errorHandler)
    @setup_routing()
    @srv = http.createServer(@app)
    @srv.listen(config.get('port'))
    logger.info "Webserver is up at: http://0.0.0.0:#{config.get('port')}"

  # Sets up the webserver routing.
  setup_routing: =>

    # Returns the base name and version of the app.
    @app.get '/', (req, res, next) =>
      res.json 200,
        name: exports.name,
        version: exports.version

    # List help.
    @app.get '/help', (req, res, next) =>
      res.json 200,
        message: "restdown docs coming soon."

    # Silence favicon requests.
    @app.get '/favicon.ico', (req, res, next) =>
      res.json 404, "No favicon exists."

    # Returns the current list of users.
    @app.get '/users', (req, res, next) =>
      user = new User
      user.list (err, userlist) =>
        if err
          res.json 500, "Error retrieving user list."
        res.json 200,
          users: userlist

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

        if user.username == "admin"
          res.json 403,
            code: 403,
            message: "Unable to modify the administrative user."

        if !reply.admin
          res.json 401,
            code: 401,
            message: "Only administrators are permitted to modify accounts."

        user = new User({ name: req.params.user })
        user.save (err, reply) =>
          res.json 200, reply
      
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

        if !user_resp
          res.json 404,
            code: 404
            location: location
            user: username
            message: "The user `#{username}` does not exist."

        user.applications().list (err, reply) =>
          if err
            res.json 500,
              code: 500
              location: location
              user: username
              message: "Error retrieving apps for user `#{username}`."

          res.json 200,
            user: username
            location: location
            applications: reply

    # Deletes a user.
    @app.del '/users/:user', (req, res, next) =>
      target = req.params.user
      if target in ["admin"]
        res.json 403,
          code: 403
          message: "Unable to modify internal services."

      user = new User()
      user.delete target, (err, reply) =>
        res.json 200,
          message: "Successfully deleted user `#{target}`."

    # Creates a new application for a user.
    @app.put '/:user/:app', (req, res, next) =>
      user = new User({ name: req.params.user })
      user.applications().build(req.params.app).save (err, reply) =>
        res.json 200,
          message: "Successfully updated application `#{req.params.app}`."

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

        res.json 200,
          user: req.params.user
          app: req.params.app
          location: loc
          branches: reply.branches
          tags: reply.tags

    # Lists all of the branches for a specified user/application.
    @app.get '/:user/:app/branches', (req, res, next) =>
      location = [req.params.user, req.params.app, 'branches']
      loc = location.join('/')
      location.unshift(config.get('repository'))
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branches = app.branches()
      branches.list (err, reply) =>
        res.json 200,
          name: loc
          branches: reply

    # Lists all of the tags for a specified user/application.
    @app.get '/:user/:app/tags', (req, res, next) =>
      location = [req.params.user, req.params.app, 'tags']
      loc = location.join('/')
      location.unshift(config.get('repository'))
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tags = app.tags()
      tags.list (err, reply) =>
        res.json 200,
          name: loc
          tags: reply

    # Creates or updates a new tag
    @app.post '/:user/:app/tags/:tag', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tag = app.tags().build(req.params.tag)
      tag.save (err, reply) =>
        if typeof req.files == undefined
          res.json 200, name: reply
        else
          mapto_flist = (file) =>
            return { location: file.path, name: file.name }

          flist = [req.files[k] for k in Object.keys(req.files)]
          f_normal = [mapto_flist(f) for f in flist[0]][0]
          files = tag.files()
          files.save f_normal, (err, reply) =>
            res.json 200, files: reply

    # Creates or updates a branch re-updating files if they are passed.
    @app.post '/:user/:app/branches/:branch', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      branch.save (err, reply) =>
        if typeof req.files == undefined
          res.json 200, name: reply
        else
          mapto_flist = (file) =>
            return { location: file.path, name: file.name }

          # TODO: Check whether or we need to update the files.
          unless req.files
            res.json 200, message: "ok"
          flist = [req.files[k] for k in Object.keys(req.files)]
          f_normal = [mapto_flist(f) for f in flist[0]][0]
          a_normal = [mapto_flist(f) for f in flist[0]][0]

          return_files = () =>
            files = branch.files()
            files.save f_normal, (err, reply) =>
              res.json 200, files: reply

          # Check for automatic branch archiving
          if config.get('archive')
            plist_file = (f_normal.filter (X) -> /\.plist/.test X['name']).pop()
            @plist_bundle_version plist_file['location']
            , (err, ref) =>
              copy_archive_file = (location_map, fn) =>
                loc = location_map['location']
                new_loc = "#{loc}_archive#{ref}"
                fs.copy loc, new_loc, (err) =>
                  location_map['location'] = new_loc

                  name_match = location_map['name'].match(/(\S+)\.(ipa|plist|dSYM\.tar\.gz)/)
                  new_name = "#{ref}.#{name_match[2]}"
                  location_map['name'] = new_name
                  fn(err, location_map)

              async.map a_normal, copy_archive_file, (err, results) =>
                nplist = (results.filter (X) -> /\.plist/.test X['name']).pop()
                @archive_plist_update nplist['location'], (err, data) =>
                  archive = branch.archives().build(ref)
                  archive.save (err, reply) =>
                    afiles = archive.files()
                    afiles.save results, (err, reply) =>
                      return_files()
          else
            return_files()

    # Creates or updates an archive re-updating files if they are passed.
    @app.post '/:user/:app/branches/:branch/archives/:ref', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      archive = branch.archives().build(req.params.ref)
      archive.save (err, reply) =>
        if typeof req.files == undefined
          res.json 200, name: reply
        else
          mapto_flist = (file) =>
            return { location: file.path, name: file.name }

          # TODO: Check whether or we need to update the files.
          unless req.files
            res.json 200, message: "ok"
          flist = [req.files[k] for k in Object.keys(req.files)]
          f_normal = [mapto_flist(f) for f in flist[0]][0]

          # Update plist to point to archives
          plist_file = (f_normal.filter (X) -> /\.plist/.test X['name']).pop()
          @archive_plist_update plist_file['location'], (err, data) =>
            archive.save (err, reply) =>
              files = archive.files()
              files.save f_normal, (err, reply) =>
                res.json 200, files: reply

    # Shows the tag info for a specified user/application/tag
    @app.get '/:user/:app/tags/:tag', (req, res, next) =>
      rel_url = "#{req.params.user}/#{req.params.app}/tags/#{req.params.tag}"
      if @is_ios_useragent(req)
        res.redirect(302, "#{rel_url}/download")

      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tag = app.tags().build(req.params.tag)
      tag.find req.params.tag, (err, reply) =>
        res.json 200, reply

    # Shows the branch info for a specified user/application/branch
    @app.get '/:user/:app/branches/:branch', (req, res, next) =>
      rel_url = "#{req.params.user}/#{req.params.app}/tags/#{req.params.tag}"
      if @is_ios_useragent(req)
        res.redirect(302, "#{rel_url}/download")

      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      branch.find req.params.branch, (err, reply) =>
        res.json 200, reply

    # List all of the archives for a specific branch.
    @app.get '/:user/:app/branches/:branch/archives', (req, res, next) =>
      location = [
        req.params.user, req.params.app, 'branches',
        req.params.branch, 'archives']
      loc = location.join('/')
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      archives = branch.archives()
      archives.list (err, reply) =>
        res.json 200,
          name: loc
          archives: reply

    # Deletes a tag
    @app.del '/:user/:app/tags/:tag', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      app.tags().delete req.params.tag, (err, reply) =>
        res.json 200, message: "successfully deleted `#{req.params.tag}`."

    # Deletes a branch
    @app.del '/:user/:app/branches/:branch', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      app.branches().delete req.params.branch, (err, reply) =>
        res.json 200, message: "successfully deleted `#{req.params.branch}`."

    # Deletes an archive
    @app.del '/:user/:app/branches/:branch/archives/:ref', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      archives = branch.archives().build(req.params.ref)
      archives.delete req.params.ref, (err, reply) =>
        res.json 200, message: "successfully deleted `#{req.params.ref}`."

    # Download plist files for a branch
    @app.get '/:user/:app/tags/:tag/download', (req, res, next) =>
      rel_url = "#{req.params.user}/#{req.params.app}/tags/#{req.params.tag}/download"
      tg = req.params.tag
      res.redirect(301, "#{rel_url}/#{tg}.plist")

    # Download plist files for a tag
    @app.get '/:user/:app/branches/:branch/download', (req, res, next) =>
      rel_url = "#{req.params.user}/#{req.params.app}/branches/#{req.params.branch}/download"
      br = req.params.branch
      res.redirect(301, "#{rel_url}/#{br}.plist")

    # Download plist files for an archive
    @app.get '/:user/:app/branches/:branch/archives/:ref/download', (req, res, next) =>
      rel_url = "#{req.params.user}/#{req.params.app}/branches/#{req.params.branch}/archives/#{req.params.ref}/download"
      ref = req.params.ref
      res.redirect(301, "#{rel_url}/#{ref}.plist")

    # Download specific file for a branch
    @app.get '/:user/:app/branches/:branch/download/:file', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branches = app.branches().build(req.params.branch)
      target = branches.files().filepath(req.params.file)
      if /plist$/.test req.params.file
        ct = 'text/xml'
      else
        ct = 'application/octet-stream'

      fs.stat target, (err, reply) =>
        res.writeHead(200, {
          'Content-Type': ct,
          'Content-Length': reply.size
        })
        readStream = fs.createReadStream(target
        , bufferSize: 4 * 1024).pipe(res)

    # Download specific file for a tag
    @app.get '/:user/:app/tags/:tag/download/:file', (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      tags = app.tags().build(reqs.params.tag)
      target = branches.files().filepath(req.params.file)
      if /plist$/.test req.params.file
        ct = 'text/xml'
      else
        ct = 'application/octet-stream'

      fs.stat target, (err, reply) =>
        res.writeHead(200, {
          'Content-Type': ct,
          'Content-Length': reply.size
        })
        readStream = fs.createReadStream(target
        , bufferSize: 4 * 1024).pipe(res)

    # Download specific file for an archive
    @app.get '/:user/:app/branches/:branch/archives/:ref/download/:file'
    , (req, res, next) =>
      user = new User({ name: req.params.user })
      app = user.applications().build(req.params.app)
      branch = app.branches().build(req.params.branch)
      archives = branch.archives().build(req.params.ref)
      target = archives.files().filepath(req.params.file)
      if /plist$/.test req.params.file
        ct = 'text/xml'
      else
        ct = 'application/octet-stream'

      fs.stat target, (err, reply) =>
        res.writeHead(200, {
          'Content-Type': ct,
          'Content-Length': reply.size
        })
        readStream = fs.createReadStream(target
        , bufferSize: 4 * 1024).pipe(res)

  ###
  Check what the user-agent is an iPhone or iPad.
  @params {Object} (req) The express request object
  @return {Boolean} Whether or not the user-agent is an iphone/ipad
  ###
  is_ios_useragent: (req) =>
    ua_regex = /[iI][pP](hone|ad)/
    if req.headers.hasOwnProperty('user-agent')
      return (req.headers['user-agent'].match(ua_regex) != null)
    else
      return null

  redirect_to_plist: (req, res, next) =>
    res.redirect(302, '/')

  ###
  Authenticates the user.
  @param {Object} (req) The express request object
  @param {Function} (fn) The callback function
  ###
  authenticate: (req, fn) =>
    err = false
    credentials =
      username: req.body.username
      secret: req.body.secret

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
      if credentials.secret != config.get('admin_secret')
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

  ###
  Authenticates the user, and if the user is managing themselves, elevate.
  @param {Object} (req) The express request object
  @param {Function} (fn) The callback function
  @param {String} (user) The user to test against for elevated privs
  ###
  authenticate_with_self_admin: (req, fn, user) =>
    credentials =
      username: req.body.username
      secret: req.body.secret

    @authenticate req, (err, reply) =>
      if credentials.username == user then reply.admin = true
      return fn(err, reply)

  ###
  Retrieve plist bundle-version.
  @param {String}   (location) The location of the plist
  @param {Function} (fn) The callback function
  ###
  plist_bundle_version: (location, fn) =>
    fs.readFile location, (err, data) =>
      pdata = plist.parseStringSync(data.toString())
      ref = pdata.items[0].metadata['bundle-version']
      fn(err, ref)

  ###
  Takes a given plist and forces the download url to point to archives.
  @param {String}   (location) The location of the plist to modify
  @param {Function} (fn) The callback function
  ###
  archive_plist_update: (location, fn) =>
    fs.readFile location, (err, data) =>
      pdata = plist.parseStringSync(data.toString())
      ref = pdata.items[0].metadata['bundle-version']
      url = pdata.items[0].assets[0].url
      ipa_match = url.match(/\/download\/(\S+)\.ipa/)

      pdata.items[0].assets[0]['url'] = url.replace(
        "/download/#{ipa_match[1]}.ipa", "/archives/#{ref}/download/#{ref}.ipa")

      updated_pdata = plist.build(pdata).toString()
      fs.writeFile location, updated_pdata, (err) =>
        fn(err, updated_pdata)

module.exports = WebServer
