fs = require 'fs'
merge = require 'merge-recursive'

RedisObject = require './redis_object'
{generate_identity} = require '../identity'
UserApp = require './user_application'

###*
 * Acts as a base class for all Redis-based objects.
###
class User extends RedisObject
  constructor: ->
    super
    @object_name = 'user'
    # @applications = new UserApp(@current)

  ###*
   * The user list prefix.
   * @return {String} The prefix for the list of users.
  ###
  userlist_prefix: =>
    ''.concat(@prefix(), 's')

  ###*
   * The user-specific data prefix.
   * @param {String} The name of the user you want the prefix for
   * @return {String} The prefix for the user-specific data
  ###
  user_prefix: (name) =>
    [@prefix(), name].join('::')

  ###*
   * Returns the list of user names.
   * @param {Function} (fn) The callback function
  ###
  list: (fn) =>
    return @redis.smembers(@userlist_prefix(), fn)

  ###*
   * Returns all of the user objects with the given filter.
   * @param {Object} (filter) The object keys you wish to return (null is all)
   * @param {Function} (fn) The callback function
  ###
  all: (filter=null, fn) =>
    @current = null
    filter = {} unless filter
    @list (err, usernames) =>
      if (filter.name and Object.keys(filter).length is 1) or err
        return fn(err, usernames)

  ###*
   * Searches for the redis objects that match the query.
   * @param {String} (name) The name of the user to find
   * @param {Function} (fn) The callback function
  ###
  find: (name, fn, admin=false) =>
    @current = null
    @list (err, usernames) =>
      if err
        return fn(err, usernames)
      if name in usernames
        @redis.hgetall @user_prefix(name), (err, obj) =>
          if err
            err =
              code: "RedisLookupFailed"
              message: ''.concat("Error retrieving userinfo for `", name, "`.")
          unless admin then delete obj['secret']
          return fn(err, obj)
      else return fn(null, {})

  ###*
   * Adds a new user object, merging and saving the current if it exists.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn, update_secret=false) =>
    return fn(null, false) unless @current

    if typeof @current.name == "string"
      @current.name = @current.name.toLowerCase()
    target = @current

    @list (err, usernames) =>
      handle_save = (err, userinfo) =>
        userinfo = if userinfo then userinfo else {}
        secret = target.secret
        target = merge.recursive(userinfo, target)
        if update_secret then target.secret = secret
        return @save_user(target, fn)

      if target.name in usernames
        @find(target.name, handle_save, true)
      else return @save_user(target, fn)

  ###*
   * Saves the given user object.
   * @param {Object} (obj) The user object to save
   * @return {Object} The status of the object save
  ###
  save_user: (obj, fn) =>
    obj.secret or= generate_identity()
    stat_add = @redis.sadd(@userlist_prefix(), obj.name)
    stat_hm = @redis.hmset(@user_prefix(obj.name), obj)

    status = if (stat_add and stat_hm) then null else
        message: ''.concat("Error saving user: `", obj.name, "`.")
    @current = obj
    return fn(status, @current)

  ###*
   * Deletes a redis object that matches the query.
   * @param {String} (username) The username to delete
   * @param {Function} (fn) the callback function
  ###
  delete: (username, fn) =>
    @current = { name: username.toLowerCase() }
    @redis.del(@userlist_prefix())
    @redis.del(@user_prefix())
    fn(null, true)

  ###*
   * Checks the login for a given user
  ###
  check_login: (user, fn) =>
    @find(user.username, (err, reply) =>
      if typeof(reply) == "undefined"
        err =
          code: "ErrorConnectingToRedis"
          message: "Error connecting to redis database."
        return fn(err, reply)

      if Object.keys(reply).length == 0
        err =
          code: "UserDoesNotExist"
          message: ''.concat("User `", user.username, "` does not exist.")

      if err
        return fn(err, reply)
      unless user.secret == reply.secret then err =
        code: "InvalidPassword"
      fn(err, reply)
    true)

  ###*
   * Creates the directories for a user application.
   * @param {Object} (user) The username to create directories for
   * @param {Function} (fn) The callback function
  ###
  setup_directories: (user, fn) =>
    # fs.mkdir [@config.get('repository'), user.username].join('/'), () =>


module.exports = User
