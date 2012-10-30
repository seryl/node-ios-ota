async = require 'async'

RedisObject = require './redis_object'
Application = require './application'

###*
 * A helper for working with tags for an application/user combo.
###
class ApplicationTag extends RedisObject
  constructor: (@user, @application, tag=null) ->
    super tag
    @object_name = 'tags'

  ###*
   * Returns the the prefix for the taglist.
   * @return {String} The taglist prefix for the current application
  ###
  taglist_prefix: =>
    app = new Application(@user)
    return [app.applist_prefix(), @application, @object_name].join('::')

  ###*
   * Returns the prefix for a particular tag.
   * @return {String} The prefix for the given tag
  ###
  tag_prefix: (tag) =>
    return [@taglist_prefix(), tag].join('::')

  list: =>
    tags_prefix = @get_app_build_prefix application, "tags"
    return @redis.smembers(tags_prefix, fn)

  ###*
   * Inserts a new tag into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    tags_prefix = @get_app_build_prefix application, "tags"
    resp = @redis.sadd(tags_prefix, tag)
    fn(null, resp)

  ###*
   * Deletes a single tag for the given application.
   * @param {String} (tag) The name of the target tag
   * @param {Function} The callback function
  ###
  delete: (tag, fn) =>

  ###*
   * Deletes all of the tags for the current application.
   * @param {Function} The callback function
  ###
  delete_all: (fn) =>
    @tags application, (err, taglist) =>
      async.forEach(taglist, @delete_tag, fn)

  ###*
   * Returns the tag information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (tag) The name of the tag to retrieve
  ###
  info: (application, tag) =>

  ###*
   * Returns the application build info for either a branch or tag.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (dtype) The data type to get `branches` or `tags`
  ###
  get_app_build_prefix: (application, dtype) =>
    return [@applist_prefix(), application, dtype].join('::')
