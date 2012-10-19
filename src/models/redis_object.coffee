RedisSingleton = require '../redis'

###*
 * Acts as a base class for all Redis-based objects.
###
class RedisObject
  constructor: ->
    @base_prefix = "node-ios-ota"
    @object_prefix = "redis-object"
    @redis = RedisSingleton.get()

  ###*
   * Returns the redis prefix for the current object type.
   * @return {String} The redis object prefix for the current object
  ###
  prefix: => [@base_prefix, @object_prefix].join('-')

  ###*
   * Returns all of the redis objects of the current object type.
   * @param {Function} (fn) The callback function
  ###
  all: (fn) =>
    fn(null, [])

  ###*
   * Searches for the redis objects that match the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  find: (query, fn) =>
    fn(null, [])

  ###*
   * Searches for the redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) The callback function
  ###
  find_one: (query, fn) =>
    @find query, (err, obj) ->
      fn(err, obj)

  ###*
   * Adds a new redis object of the current type to the database.
   * @param {Object} (obj) The object to add
   * @param {Function} (fn) The callback function
  ###
  add: (obj, fn) =>
    fn(null, obj)

  ###*
   * Updates a redis object with the given parameters.
   * @param {Object} (obj) The object to merge with updates
   * @param {Function} (fn) The callback function
  ###
  update: (obj, fn) =>
    fn(null, obj)

  ###*
   * Deletes a redis object that matches the query.
   * @param {Object} (query) The query object to search
   * @param {Function} (fn) the callback function
  ###
  delete: (query, fn) =>
    fn(null, true)
