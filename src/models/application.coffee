async = require 'async'

RedisObject = require './redis_object'
ApplicationBranch = require './application_branch'
ApplicationTag = require './application_tag'

###*
 * A helper for working with applications of a particular user.
###
class Application extends RedisObject
  constructor: (@user, application=null) ->
    super application
    @object_name = 'application'

  ###*
   * The applications prefix for the specified user.
  ###
  applist_prefix: =>
    ''.concat(@prefix(), 's', '::', @user)

  ###*
   * The user-specific application prefix for a given application.
   * @param {String} (application) The name of the application
  ###
  app_prefix: (application) =>
    [@applist_prefix(), application].join('::')

  ###*
   * Returns the list of application names for a given user.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@applist_prefix(), fn)

  ###*
   * Returns all of the user objects with the given filter.
   * @param {Object} (filter) The object keys you wish to return (null is all)
   * @param {Function} (fn) The callback function
  ###
  all: (filter={}, fn) =>
    if typeof filter == "function" then fn = filter
    @current = null
    @list (err, applications) =>
      if (filter.name and Object.keys(filter).length is 1) or err
        fn(err, applications)

  ###*
   * Searches for the redis objects that match the query.
   * @param {Object} (name) The name of the application to search for
   * @param {Function} (fn) The callback function
   TODO: Finish this function
  ###
  find: (name, admin=false, fn) =>
    if typeof admin == "function" then fn = admin
    @current = null
    @list (err, applications) =>
      if err then return fn(err, applications)
      # if name in applications
        # Get the branches for the application
        # Get the tags for the application
    # fn(null, [])

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    target = @current
    @all { name: true }, (err, applications) =>
      if target in applications then return fn(null, @current) else
        stat_add = @redis.sadd(@applist_prefix(), target)
        status = if (stat_add) then null else
          message: "Error saving application: `#{target}`."
        @current = target
        fn(status, target)

  ###*
   * Deletes a redis object that matches the query.
   * @param {String} (application) The name of the application to delete
   * @param {Function} (fn) the callback function
  ###
  delete: (application, fn) =>
    @current = application
    @redis.srem(@applist_prefix(), application)
    @branches().delete_all (err, reply) =>
      @tags().delete_all (err, reply) =>
        fn(null)
  ###*
   * Deletes every application for the user that currently exists.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, applications) =>
      async.forEach(applications, @delete, fn)

  ###*
   * Returns the list of branches for the current application.
   * @return {Object} The ApplicationBranch object for the current application
  ###
  branches: =>
    return new ApplicationBranch(@user, @current)

  ###*
   * Returns the list of tags for the current application.
   * @return {Object} The ApplicationTag object for the current application
  ###
  tags: =>
    return new ApplicationTag(@user, @current)

module.exports = Application
