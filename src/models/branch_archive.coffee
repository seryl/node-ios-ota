fs = require 'fs'
async = require 'async'

RedisObject = require './redis_object'
Files = require './files'

###*
 * A helper for working with archives for a branch.
###
class BranchArchive extends RedisObject
  constructor: (@user, @application, @branch, ref=null) ->
    super ref
    @basename = "node-ios-ota::applications"
    @object_name = 'archives'

  ###*
   * Returns the the prefix for the branchlist.
   * @return {String} The archivelist prefix for the branch
  ###
  archivelist_prefix: =>
    return [@basename, @user, @application, "branches", @branch, @object_name].join('::')

  ###*
   * Returns the list of archives for the current branch.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@archivelist_prefix(), fn)

  ###*
   * Returns the information for the current branch archive.
   * @param {String} (name) The name of the ref to retrieve
   * @param {Function} (fn) The callback function
  ###
  find: (name, fn) =>
    original = String(@current)
    @current = String(name)
    @files().all (err, reply) =>
      @current = original
      fn(err, {name: String(name), files: reply} )

  ###*
   * Returns the information for all the current branch archives.
   * @param {Function} (fn) The callback function
  ###
  all: (fn) =>
    @list (err, archives) =>
      async.map archives, @find, (err, results) =>
        fn(err, {archives: results})

  ###*
   * Inserts a new archive into the given application.
   * @param {String} (archive) The name of the archive to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    stat_add = @redis.sadd(@archivelist_prefix(), String(@current))
    status = if (stat_add) then null else
      message: "Error saving archive: `#{@user}/#{@application}/branches/#{@branch}/archives/#{@current}`."
    @setup_directories @current, (err, reply) =>
      fn(status, @current)

  ###*
   * Deletes a single archive for the given branch.
   * @param {String} (ref) The archive reference tag
   * @param {Function} (fn) The callback function
  ###
  delete: (ref, fn) =>
    @current = ref
    @redis.srem(@archivelist_prefix(), String(ref))
    @files().delete_all (err, reply) =>
      @delete_directories ref, (err, reply) =>
        fn(null, true)

  ###*
   * Deletes the branch archives for a given application.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, archivelist) =>
      async.each(archivelist, @delete, fn)

  ###*
   * Returns the list of files for the current branch.
   * @return {Object} The Files object for the current branch
  ###
  files: =>
    return new Files(@user, @application, "branches.#{@branch}.#{@object_name}", String(@current))

  ###*
   * Creates the directories for the archive ref.
   * @param {Object} (ref) The archive ref to create directories for
   * @param {Function} (fn) The callback function
  ###
  setup_directories: (ref, fn) =>
    dirloc = [@user, @application, "branches", @branch, @object_name, ref].join('/')
    target = [@config.get('repository'), dirloc].join('/')
    fs.exists target, (exists) =>
      unless exists
        fs.mkdir target, (err, made) =>
          if err
            @logger.error "Error setting up directories for `#{dirloc}`."
          fn(err, made)
      else
        fn(null, false)

  ###*
   * Deletes the directories for the archive ref.
   * @param {Object} (ref) The archive ref to create directories for
   * @param {Function} (fn) The callback function
  ###
  delete_directories: (ref, fn) =>
    dirloc = [@user, @application, "branches", @branch, @object_name, ref].join('/')
    fs.rmdir [@config.get('repository'), dirloc].join('/'), (err) =>
      if err
        @logger.error "Error removing directories for `#{dirloc}`."
      fn(null, true)

module.exports = BranchArchive
