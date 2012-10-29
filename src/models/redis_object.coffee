RedisSingleton = require './redis_singleton'
Config = require '../config'

###*
 * Acts as a base class for all Redis-based objects.
 * @param {Object} (obj) The object to 
###
class RedisObject
  constructor: (obj=null) ->
    @base_prefix = "node-ios-ota"
    @object_name = "redis-object"
    @redis = RedisSingleton.get()
    @config = Config.get()
    @current = obj

  ###*
   * Returns the redis prefix for the current object type.
   * @return {String} The redis object prefix for the current object
  ###
  prefix: => [@base_prefix, @object_name].join('::')

  ###*
   * Creates a new redis object.
   * @param {Function} (fn) The callback function
  ###
  build: (obj) =>
    @current = obj
    return @

  ###*
   * Returns all of the redis objects of the current object type.
   * @param {Object} (filter) The object keys you wish to return (null is all)
   * @param {Function} (fn) The callback function
  ###
  all: (filter=null, fn) =>
    if typeof filter == "function" then fn = filter
    @current = null
    fn(null, [])

  ###*
   * Searches for the redis objects that match the query.
   * @param {String} (name) The name of the object to find
   * @param {Function} (fn) The callback function
  ###
  find: (name, admin=false, fn) =>
    if typeof admin == "function" then fn = admin
    @current = null
    fn(null, [])

  ###*
   * Saves the current object if there is one.
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    fn(null, true)

  ###*
   * Deletes a redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) the callback function
  ###
  delete: (fn) =>
    fn(null, true)

module.exports = RedisObject
