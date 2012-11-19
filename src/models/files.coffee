path = require 'path'
fs = require 'fs'
async = require 'async'
mv = require 'mv'

RedisObject = require './redis_object'
filemd5 = require '../filemd5'

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
   * Returns the path to the file for reading.
  ###
  filepath: (filename) =>
    dirloc = [@user, @application, @dtype, @current].join('/')
    target_dir = [@config.get('repository'), dirloc].join('/')
    return path.normalize([target_dir, filename].join('/'))

  ###*
   * Adds a new files object, merging and saving the current if it exists.
   * @param {Object} (files) A single or list of filenames and md5s to add
   * @param {Function} (fn) The callback function
   *
   * @example
   *
   *   files = [
   *     { location: "/tmp/54e05c292ef585094a12b20818b3f952", name: "myapp.ipa" },
   *     { location: "/tmp/ab1e5d1ed4be9d7cb8376cbf12f85ca8", name: "myapp.plist" }
   *   ]
   *
  ###
  save: (files, fn) =>
    unless (files instanceof Array)
      files = Array(files)

    filemap = []
    filemap.push @files_prefix()

    flist = []

    async.map files, @setup_file, (err, reply) =>
      for f in reply
        filemap.push f.name
        filemap.push f.md5
        flist.push { name: f.name, md5: f.md5 }

      @redis.hmset.apply(@redis, filemap)
      fn(null, flist)

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
      @delete_files (err, reply) =>
        fn(null)

  ###*
   * Sets up the file in the proper directory.
   * @param {Object} (file) The file to add to the current leaf
   * @param {Function} (fn) The callback function
   *
   * @example
   *
   *  f =
   *     location: "/tmp/54e05c292ef585094a12b20818b3f952"
   *      name: "master.ipa"
   * 
   *  setup_file(f, (err, reply) -> console.log reply)
   *
  ###
  setup_file: (file, fn) =>
    fe = @file_extension(file.name)
    fname = "#{@current}.#{fe}"
    dirloc = [@user, @application, @dtype, @current].join('/')
    target_loc = [@config.get('repository'), dirloc, fname].join('/')

    mv file.location, target_loc, (err) =>
      filemd5 target_loc, (err, data) =>
        if err
          @logger.error "Error setting up files for `#{target_loc}`."
        fn(err, { name: fname, md5: data })

  ###*
   * Deletes the files for the current leaf.
   * @param {Function} (fn) The callback function
  ###
  delete_files: (fn) =>
    dirloc = [@user, @application, @dtype, @current].join('/')
    target_dir = [@config.get('repository'), dirloc].join('/')
    fs.readdir target_dir, (err, reply) =>
      async.parallel reply, fs.unlink, (err) =>
        if err
          @logger.error "Error removing directories for `#{dirloc}`."
        fn(null, true)

  ###*
   * Returns the file extension.
   * @param {String} (filename) The name of the file
   * @return {String} The filename extension
  ###
  file_extension: (filename) =>
    ext = path.basename(filename||'').split('.')
    ext.shift()
    return ext.join('.')

module.exports = Files
