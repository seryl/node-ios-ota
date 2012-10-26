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
  user_prefix: () =>
    ''.concat(@prefix(), 's', '::', @user)

  ###*
   * The user-specific application prefix for a given application.
   * @param {String} (application) The name of the application
  ###
  application_prefix: (application) =>
    [@user_prefix(), application].join('::')

  ###*
   * Returns the list of application names for a given user.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@application_prefix(), fn)

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
      if err
        return fn(err, applications)
      if name in applications
        # Get the branches for the application
        # Get the tags for the application
    # fn(null, [])

  ###*
   * Returns the list of branches for a particular application.
   * @param {String} (application) The name of the application to retrieve
  ###
  branches: (application) =>

  ###*
   * Returns the branch information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (branch) The name of the branch to retrieve
  ###
  branch_info: (application, branch) =>

  ###*
   * Returns the list of tags for a particular application.
   * @param {String} (application) The name of the application to retrieve
  ###
  tags: (application) =>

  ###*
   * Returns the tag information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (tag) The name of the tag to retrieve
  ###
  tag_info: (application, tag) =>

  ###*
   * Searches for the redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  # find_one: (query, fn) =>
  #   @current = null
  #   @find query, (err, obj) ->
  #     fn(err, obj)

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    target = @current
    console.log('target: ' + target)

    # @all { name: true }, (err, usernames) =>
    #   if target.name in usernames
    #     @current = target
    #     return fn(null, false)

    #   target.secret = generate_identity()
    #   stat_add = @redis.sadd(@application_prefix())
    #   stat_hm = @redis.hmset(@user_prefix(), target)
    #   @current = target

    #   status = if (stat_add and stat_hm) then null else
    #     message: "Error saving user"
    #   return fn(status, @current)

  ###*
   * Deletes a redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) the callback function
  ###
  # delete: (fn) =>
  #   fn(null, true)

module.exports = UserApp
