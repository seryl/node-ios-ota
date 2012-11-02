async = require 'async'

RedisObject = require './redis_object'

###*
 * Flattens an array into a single dimension.
 * @param {Array} (a) The array to flatten
 * @return {Array} The flattened array
###
flatten = (a) ->
  if a.length is 0 then return []
  a.reduce (lhs, rhs) -> lhs.concat rhs

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
   * @param {Function} The callback function
  ###
  delete: (filename, fn) =>
    @redis.del @files_prefix(), filename (err, reply) =>
      fn(null)

  ###*
   * Deletes all of the associated files from the
  ###
  delete_all: (fn) =>
    @redis.hkeys @files_prefix(), (err, reply) =>
      unless reply.length == 0
        reply.unshift @files_prefix()
        @redis.hdel.apply(@redis, reply)
      fn(null)


module.exports = Files
