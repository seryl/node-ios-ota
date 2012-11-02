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
 * A helper for working with filelists for a branch or tag of an application.
###
class Filelist extends RedisObject
  constructor: (@user, @application, @dtype, name=null) ->
    super name
    @basename = "node-ios-ota::applications"
    @object_name = 'filelist'

  ###*
   * Returns the the prefix for the filelist.
   * @return {String} The filelist prefix for the application tag/branch
  ###
  filelist_prefix: =>
    return [@basename, @user, @application,
            @dtype, @current, @object_name].join('::')

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
    return @redis.smembers(@filelist_prefix(), fn)

  add_file: (file, fn) =>
    console.log file
    fn(null, true)

  ###*
   * Adds a new filelist object, merging and saving the current if it exists.
   * @param {Object} (files) Files object 
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
    # async.forEach files, update_obj, (err) =>
    #   @redis.hmset @filelist_prefix(), 'files', JSON.stringify(file_obj)
    #   @redis.hgetall @filelist_prefix(), (err, reply) ->
    #     console.log err
    #     console.log reply
    #   fn(null, true)
    # file_obj
    # filemap = (f.name for f in files)
    # filemap.unshift(@filelist_prefix())
    filemap = flatten(f.name for f in files)
    console.log filemap

    # @redis.hmset @filelist_prefix(), 'files', filemap
    fn(null, true)

    # filemap.unshift(@filelist_prefix())

    # @redis.hmset.apply(this, filemap)

    # @redis.hgetall(@filelist_prefix(), (err, reply) =>
    #   console.log err
    #   console.log reply)
    # console.log filemap
    # fn(null, true)
    # @redis.hmset()
    # @redis.hmset()
    # async.forEach files, @add_file, (err) =>
    #   fn(null, true)
    # return fn(null, false) unless @current
    # target = @current

  # ###*
  #  * Saves the given files hash.
  #  * @param {Object} (files) The files object to save
  #  * @param {Boolean} (replace) whether or not to replace the current hash
  #  * @param {Function} The callback function
  # ###
  # save_files: (files, replace=false, fn) =>
  #   if typeof replace == "function"
  #     fn = replace
  #     replace = false

  #   unless replace
  #     null
  #     # Merge the filelist

  #   # Update the current filelist

  #   # Add the file and it's md5 to the file hash

  #   # return the result.

  #   # for each of the files get their md5, 
  #   stat_add = @redis.sadd(@userlist_prefix(), @current)
  #   stat_hm = @redis.hmset(@user_prefix(obj.name), obj)

  #   status = if (stat_add and stat_hm) then null else
  #       message: "Error saving filelist for #{@application}/: `#{@current}`."
  #   @current = obj
  #   return fn(status, @current)

  delete: =>

  delete_all: =>


module.exports = Filelist
