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
  find: (name, fn) =>
    @current = null
    @list (err, usernames) =>
      if err
        return fn(err, usernames)
      if name in usernames
        @redis.hgetall @user_prefix(name), (err, obj) =>
          if err
            err =
              message: ''.concat("Error retrieving userinfo for `", name, "`.")
          return fn(err, obj)
      else return fn(null, {})

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current

    if typeof @current.name == "string"
      @current.name = @current.name.toLowerCase()
    target = @current

    @list (err, usernames) =>
      # Update the account
      if target.name in usernames
        @find target.name, (err, userinfo) =>
          userinfo = if userinfo then userinfo else {}
          target = merge.recursive(userinfo, target)
          return @save_user(target, fn)
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
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) the callback function
  ###
  # delete: (fn) =>
  #   fn(null, true)

module.exports = User
