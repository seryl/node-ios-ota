RedisSingleton = require './redis_singleton'

###*
 * Acts as a base class for all Redis-based objects.
 * @param {Object} (obj) The object to 
###
class RedisObject
  constructor: (obj=null) ->
    @base_prefix = "node-ios-ota"
    @object_name = "redis-object"
    @redis = RedisSingleton.get()
    @current = obj

  ###*
   * Returns the redis prefix for the current object type.
   * @return {String} The redis object prefix for the current object
  ###
  prefix: => [@base_prefix, @object_name].join('-')

  ###*
   * Returns all of the redis objects of the current object type.
   * @param {Object} (filter) The object keys you wish to return (null is all)
   * @param {Function} (fn) The callback function
  ###
  all: (filter=null, fn) =>
    @current = null
    filter = {} unless filter
    fn(null, [])

  ###*
   * Searches for the redis objects that match the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  find: (query, fn) =>
    @current = null
    fn(null, [])

  ###*
   * Searches for the redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  find_one: (query, fn) =>
    @current = null
    @find query, (err, obj) ->
      fn(err, obj)

  ###*
   * Saves the current object if there is one.
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    return fn(null, false) unless @current
    fn(null, true)

  ###*
   * Updates a redis object with the given parameters.
   * @param {Object} (obj) The object to merge with updates
   * @param {Function} (fn) The callback function
  ###
  update: (obj, fn) =>
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
