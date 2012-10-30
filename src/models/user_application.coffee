RedisObject = require './redis_object'
{generate_identity} = require '../identity'

###*
 * Acts as a base class for all Redis-based objects.
###
class UserApp extends RedisObject
  constructor: (@user, obj=null) ->
    super obj
    @object_name = 'application'

  ###*
   * The applications prefix for the specified user.
  ###
  applist_prefix: () =>
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
        return fn(err, applications)

  ###*
   * Searches for the redis objects that match the query.
   * @param {Object} (name) The name of the application to search for
   * @param {Function} (fn) The callback function
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
   * Returns the application build info for either a branch or tag.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (dtype) The data type to get `branches` or `tags`
  ###
  get_app_build_prefix: (application, dtype) =>
    return [@applist_prefix(), application, dtype].join('::')

  ###*
   * Returns the list of branches for a particular application.
   * @param {String} (application) The name of the application to retrieve
   * @param {Function} (fn) The callback function
  ###
  branches: (application, fn) =>
    branch_prefix = @get_app_build_prefix application, "branches"
    return @redis.smembers(branch_prefix, fn)

  ###*
   * Returns the branch information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (branch) The name of the branch to retrieve
  ###
  branch_info: (application, branch) =>

  ###*
   * Returns the list of tags for a particular application.
   * @param {String} (application) The name of the application to retrieve
   * @param {Function} (fn) The callback function
  ###
  tags: (application, fn) =>
    tags_prefix = @get_app_build_prefix application, "tags"
    return @redis.smembers(tags_prefix, fn)

  ###*
   * Returns the tag information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (tag) The name of the tag to retrieve
  ###
  tag_info: (application, tag) =>

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    target = @current
    @all { name: true }, (err, applications) =>
      stat_add = @redis.sadd(@applist_prefix(), target)
      # tags_add = @redis.app_prefix
      # stat_
      return fn(null, true)

    # @all { name: true }, (err, usernames) =>
    #   if target.name in usernames
    #     @current = target
    #     return fn(null, false)

    #   target.secret = generate_identity()
    #   stat_add = @redis.sadd(@app_prefix())
    #   stat_hm = @redis.hmset(@user_prefix(), target)
    #   @current = target

    #   status = if (stat_add and stat_hm) then null else
    #     message: "Error saving user"
    #   return fn(status, @current)

  ###*
   * Saves the given application object for the current user
  ###
  save_app: (obj, fn) =>
    obj.secret or= generate_identity()
    stat_add = @redis.sadd(@userlist_prefix(), obj.name)
    stat_hm = @redis.hmset(@user_prefix(obj.name), obj)

    status = if (stat_add and stat_hm) then null else
        message: "Error saving user: `#{obj.name}`."
    @current = obj
    return fn(status, @current)

  ###*
   * Deletes a redis object that matches the query.
   * @param {String} (application) The name of the application to delete
   * @param {Function} (fn) the callback function
  ###
  delete: (application, fn) =>
    @current = { name: application.toLowerCase() }

    tag_prefix = @get_app_build_prefix application, "tags"
    branch_prefix = @get_app_build_prefix application, "branches"
    @delete_tags application, (err, reply) =>
      @delete_branches application, (err, reply) =>
        @redis.srem(@applist_prefix(), application)
        fn(null, true)

  ###*
   * Deletes the tags for a given application matching the given name.
  ###
  delete_tags: (application, tags='*', fn) =>
    if typeof tags == "function" then fn = tags
    fn(null, true)
    # if typeof tags == "string"
    #   if tags == "*"
    #     @tags application, (err, reply) =>

  ###*
   * Deletes the branches for a given application matching the given name.
   * @param {String}
  ###
  delete_branches: (application, branches='*', fn) =>
    if typeof branches == "function" then fn = branches
    fn(null, true)
    # if typeof branches == "String"
    #   if branches == "*"
    #     @branches application, (err, reply) =>

  ###*
   * Deletes every application for the user that currently exists.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, applications) =>
      console.log err
      console.log applications
      async.forEach(applications, @delete, fn)

module.exports = UserApp
