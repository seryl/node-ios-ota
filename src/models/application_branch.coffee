fs = require 'fs'
async = require 'async'

RedisObject = require './redis_object'
BranchArchive = require './branch_archive'
Files = require './files'

###*
 * A helper for working with branches for an application/user combo.
###
class ApplicationBranch extends RedisObject
  constructor: (@user, @application, branch=null) ->
    super branch
    @basename = "node-ios-ota::applications"
    @object_name = 'branches'

  ###*
   * Returns the the prefix for the branchlist.
   * @return {String} The branchlist prefix for the current application
  ###
  branchlist_prefix: =>
    return [@basename, @user, @application, @object_name].join('::')

  ###*
   * Returns the list of branches for the given user/application.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@branchlist_prefix(), fn)

  ###*
   * Returns the information for the current application branch.
   * @param {String} (name) The name of the branch to retrieve
   * @param {Function} (fn) The callback function
  ###
  find: (name, fn) =>
    original = @current
    @current = name
    @files().all (err, reply) =>
      @current = original
      fn(err, {name: name, files: reply} )

  ###*
   * Returns the information for all the current application branches.
   * @param {Function} (fn) The callback function
  ###
  all: (fn) =>
    @list (err, branches) =>
      async.map branches, @find, (err, results) =>
        fn(err, {branches: results})

  ###*
   * Inserts a new branch into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    stat_add = @redis.sadd(@branchlist_prefix(), @current)
    status = if (stat_add) then null else
      message: "Error saving branch: `#{@user}/#{@application}/branches/#{@current}`."
    @setup_directories @current, (err, reply) =>
      fn(status, @current)

  ###*
   * Deletes a single branch for the given application.
   * @param {String} (branch) The name of the target branch
   * @param {Function} (fn) The callback function
  ###
  delete: (branch, fn) =>
    @current = branch
    @redis.srem(@branchlist_prefix(), branch)
    @archives().delete_all (err, reply) =>
    @files().delete_all (err, reply) =>
      @delete_directories branch, (err, reply) =>
        fn(null, true)

  ###*
   * Deletes the branches for a given application.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, branchlist) =>
      async.forEach(branchlist, @delete, fn)

  ###*
   * Returns the list of files for the current branch.
   * @return {Object} The Files object for the current branch
  ###
  files: =>
    return new Files(@user, @application, @object_name, @current)

  ###*
   * Creates the directories for the branch.
   * @param {Object} (branch) The branch to create directories for
   * @param {Function} (fn) The callback function
  ###
  setup_directories: (branch, fn) =>
    dirloc = [@user, @application, @object_name, branch].join('/')
    target = [@config.get('repository'), dirloc].join('/')

    fs.exists target, (exists) =>
      unless exists
        fs.mkdir target, (err, made) =>
          if err
            @logger.error "Error setting up directories for `#{dirloc}`."
          fs.mkdir [target, "archives"].join('/'), (err, made) =>
            if err
              @logger.error "Error setting up directories for `#{dirloc}/archives`"
            fn(err, made)
      else
        fn(null, false)

  ###*
   * Returns the list of archives for the current branch.
   * @return {Object} The BranchArchive object for the current branch
  ###
  archives: =>
    return new BranchArchive(@user, @application, @current)

  ###*
   * Deletes the directories for the branch.
   * @param {Object} (branch) The branch to create directories for
   * @param {Function} (fn) The callback function
  ###
  delete_directories: (branch, fn) =>
    dirloc = [@user, @application, @object_name, branch].join('/')
    fulldir = [@config.get('repository'), dirloc].join('/')
    msg = "Error removing directories for"

    fs.rmdir fulldir, (err) =>
      if err
        @logger.error "#{msg} `#{dirloc}`."
      fs.rmdir [fulldir, "archives"].join('/'), (err) =>
        if err
          @logger.error "#{msg} `#{dirloc}/archives`."
          fn(null, true)

module.exports = ApplicationBranch
