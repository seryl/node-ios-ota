async = require 'async'

RedisObject = require './redis_object'

###*
 * A helper for working with files for a branch or tag of an application.
###
class Files extends RedisObject
  constructor: (@user, @application, @dtype, name=null) ->
    super name
    @basename = "node-ios-ota::applications"
    @object_name = 'files'

  ###*
   * Returns the prefix for the files hash.
   * @return {String} The prefix for the given files hash
  ###
  files_prefix: =>
    return [@basename, @user, @application,
        @dtype, @current, "files"].join('::')

  ###*
   * Returns the list of files for the current branch/tag.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    @redis.hkeys @files_prefix(), (err, reply) =>
      fn(err, reply)

  ###*
   * Returns the full information hash all of the current files.
   * @param {Function} (fn) The callback function
  ###
  all: (fn) =>
    @redis.hgetall @files_prefix(), (err, reply) =>
      if reply
        new_reply = []
        for key in Object.keys(reply)
          new_reply.push { name: key, md5: reply[key] }
      else
        new_reply = []
      fn(err, new_reply)

  ###*
   * Finds and returns the information hash for a particular file.
   * @param {String} (filename) The filename to find information about
   * @param {Function} (fn) The callback function
  ###
  find: (filename, fn) =>
    @redis.hget @files_prefix(), filename, (err, reply) =>
      if reply
        reply = { name: filename, md5: reply }
      fn(err, reply)

  ###*
   * Adds a new files object, merging and saving the current if it exists.
   * @param {Object} (files) A single or list of filenames and md5s to add
   * @param {Function} (fn) The callback function
   *
   * @example
   *
   *   files = [
   *     { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
   *     { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
   *   ]
   *
  ###
  save: (files, fn) =>
    unless (files instanceof Array)
      files = Array(files)
    filemap = []
    filemap.push @files_prefix()
    for f in files
      filemap.push f.name
      filemap.push f.md5

    @redis.hmset.apply(@redis, filemap)
    fn(null, filemap)

  ###*
   * Deletes a single file from the files hashmap.
   * @param {String} (filename) The filename to delete
   * @param {Function} (fn) The callback function
  ###
  delete: (filename, fn) =>
    @redis.del @files_prefix(), filename (err, reply) =>
      fn(null)

  ###*
   * Deletes all of the associated files from the current tag/branch.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @redis.hkeys @files_prefix(), (err, reply) =>
      unless reply.length == 0
        reply.unshift @files_prefix()
        @redis.hdel.apply(@redis, reply)
      fn(null)

  # ###*
  #  * Sets up the files in the proper directory.
  #  * @param {Object} (tag) The tag to create directories for
  #  * @param {Function} (fn) The callback function
  # ###
  # setup_files: (name, fn) =>
    # dirloc = [@user, @application, @dtype, name].join('/')
  #   fs.mkdir [@config.get('repository'), dirloc].join('/'), (err, made) =>
  #     if err
  #       @logger.error "Error setting up directories for `#{dirloc}`."
  #     fn(err, made)

  # ###*
  #  * Deletes the directories for the application.
  #  * @param {Object} (tag) The tag to create directories for
  #  * @param {Function} (fn) The callback function
  # ###
  # delete_files: (tag, fn) =>
  #   dirloc = [@user, @application, @dtype, name].join('/')
  #   fs.rmdir [@config.get('repository'), dirloc].join('/'), (err) =>
  #     if err
  #       @logger.error "Error removing directories for `#{dirloc}`."
  #     fn(null, true)

module.exports = Files
