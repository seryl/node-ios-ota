async = require 'async'

RedisObject = require './redis_object'
Files = require './files'

###*
 * A helper for working with tags for an application/user combo.
###
class ApplicationTag extends RedisObject
  constructor: (@user, @application, tag=null) ->
    super tag
    @basename = "node-ios-ota::applications"
    @object_name = 'tags'

  ###*
   * Returns the the prefix for the taglist.
   * @return {String} The taglist prefix for the current application
  ###
  taglist_prefix: =>
    return [@basename, @user, @application, @object_name].join('::')

  ###*
   * Returns the list of tags for the given user/application.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@taglist_prefix(), fn)

  ###*
   * Inserts a new tag into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    stat_add = @redis.sadd(@taglist_prefix(), @current)
    status = if (stat_add) then null else
      message: "Error saving tag: `#{@user}/#{@application}/#{@current}`."
    fn(status, @current)

  ###*
   * Deletes a single tag for the given application.
   * @param {String} (tag) The name of the target tag
   * @param {Function} The callback function
  ###
  delete: (tag, fn) =>
    @current = tag
    @redis.srem(@taglist_prefix(), tag)
    @files().delete_all (err, reply) =>
      fn(null)

  ###*
   * Deletes all of the tags for the current application.
   * @param {Function} The callback function
  ###
  delete_all: (fn) =>
    @list (err, taglist) =>
      async.forEach(taglist, @delete, fn)

  ###*
   * Returns the list of files for the current tag.
   * @return {Object} The Files object for the current application
  ###
  files: =>
    return new Files(@user, @application, @object_name, @current)

module.exports = ApplicationTag
