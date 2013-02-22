fs = require 'fs'
merge = require 'merge-recursive'
async = require 'async'
mkdirp = require 'mkdirp'

RedisObject = require './redis_object'
Application = require './application'
{generate_identity} = require '../identity'

###*
 * A helper for representing a particular user and their applications.
###
class User extends RedisObject
  constructor: ->
    super
    @object_name = 'user'

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
  all: (filter={}, fn) =>
    if typeof filter == "function" then fn = filter
    @current = null
    @list (err, usernames) =>
      if (filter.name and Object.keys(filter).length is 1) or err
        return fn(err, usernames)

  ###*
   * Searches for the redis objects that match the query.
   * @param {String} (name) The name of the user to find
   * @param {Function} (fn) The callback function
  ###
  find: (name, admin=false, fn) =>
    if typeof admin == "function" then fn = admin
    @current = null
    @list (err, usernames) =>
      if err then return fn(err, usernames)
      if name in usernames
        @redis.hgetall @user_prefix(name), (err, obj) =>
          if err
            err =
              code: "RedisLookupFailed"
              message: "Error retrieving userinfo for `#{name}`."
          unless admin then delete obj['secret']
          return fn(err, obj)
      else return fn(null, {})

  ###*
   * Adds a new user object, merging and saving the current if it exists.
   * @param {Function} (fn) The callback function
  ###
  save: (update_secret=false, fn) =>
    if typeof update_secret == "function" and (
      typeof fn == "undefined" or typeof fn == "null")
      fn = update_secret
      update_secret = false
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
   * @param {Function} The callback function
  ###
  save_user: (obj, fn) =>
    obj.secret or= generate_identity()
    stat_add = @redis.sadd(@userlist_prefix(), obj.name)
    stat_hm = @redis.hmset(@user_prefix(obj.name), obj)

    status = if (stat_add and stat_hm) then null else
        message: "Error saving user: `#{obj.name}`."
    @setup_directories obj.name, (err, made) =>
      @current = obj
      return fn(status, @current)

  ###*
   * Deletes a redis object that matches the query.
   * @param {String} (username) The username to delete
   * @param {Function} (fn) the callback function
  ###
  delete: (username, fn) =>
    @current = { name: username.toLowerCase() }
    @redis.srem(@userlist_prefix(), username)
    @redis.del(@user_prefix(username))
    @applications().delete_all (err, reply) =>
      @delete_directories username, (err, succ) =>
        if err then fn(true, false) else fn(null, true)

  ###*
   * Deletes every user that currently exists.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, usernames) =>
      if usernames.length
        async.each(usernames, @delete, fn)
      else
        fn(err)

  ###*
   * Checks whether or not the given user exists.
   * @param {String} (username) The username to check the existance of
   * @param {Function} (fn) The callback function
  ###
  exists: (username, fn) =>
    @redis.sismember(@userlist_prefix(), username, fn)

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
          message: "User `#{user.username}` does not exist."

      if err then return fn(err, reply)
      unless user.secret == reply.secret then err =
        code: "InvalidPassword"
      fn(err, reply)
    true)

  ###*
   * Creates the directories for a user.
   * @param {Object} (username) The username to create directories for
   * @param {Function} (fn) The callback function
  ###
  setup_directories: (username, fn) =>
    mkdirp [@config.get('repository'), username].join('/'), (err, made) =>
      if err
        @logger.error "Error setting up directories for `#{username}`."
      fn(err, made)

  ###*
   * Deletes the directories for a user.
   * @param {Object} (username) The username to delete directories of
   * @param {Function} (fn) The callback function
  ###
  delete_directories: (username, fn) =>
    fs.rmdir [@config.get('repository'), username].join('/'), (err) =>
      if err
        @logger.error "Error removing directories for `#{username}`."
      fn(null, true)

  ###*
   * Returns the applications object for the current user.
   * @return {Object} The Application object for the current user
  ###
  applications: =>
    return new Application(@current.name)

module.exports = User
