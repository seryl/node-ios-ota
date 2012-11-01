async = require 'async'

RedisObject = require './redis_object'

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
   * Returns the prefix for a particular tag.
   * @return {String} The prefix for the given tag
  ###
  tag_prefix: =>
    return [@taglist_prefix(), @current].join('::')

  list: (fn) =>
    return @redis.smembers(@tag_prefix(), fn)

  ###*
   * Inserts a new tag into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    stat_add = @redis.sadd(@tag_prefix(), @current)
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
    fn(null, true)

  ###*
   * Deletes all of the tags for the current application.
   * @param {Function} The callback function
  ###
  delete_all: (fn) =>
    @list (err, taglist) =>
      async.forEach(taglist, @delete_tag, fn)

  ###*
   * Returns the tag information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (tag) The name of the tag to retrieve
  ###
  info: (application, tag) =>

module.exports = ApplicationTag
