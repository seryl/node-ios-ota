Singleton = require './singleton'
Config = require './config'
Logger = require './logger'
redis = require 'redis'

###*
 * Redis utility wrapper for the iOS-ota service.
###
class RedisUtility
  constructor: (port, host, options, @prefix="ios-ota-") ->
    @redis = redis.createClient(port, host, options)
    @modify_redis()
    return @redis

  modify_redis: () =>
    @redis.prefix = (k) =>
      ''.concat(@prefix, k)

    @redis.get_users = (fn) =>
      @redis.get(@redis.prefix('users'), fn)

    @redis.get_user = (username, fn) =>
      @redis.hgetall(''.concat(@redis.prefix('user'), '-', username), fn)

    @redis.get_user_secret = (username, fn) =>
      @redis.hget(''.concat(@redis.prefix('user'), '-', username), 'secret', fn)

    @redis.add_or_update_user = (user, fn) =>
      console.log(user)
      # @redis.hset(
      #   ''.concat(@redis.prefix('user'), '-', user.username), 'secret', fn)

###*
 * Redis utility wrapper that acts as a singleton.
###
class RedisUtils extends Singleton
  constructor: ->
    @config = Config.get()
    @logger = Logger.get()
    @redis = new RedisUtility(
      @config.get("redis_port"),@config.get("redis_host") )

    @redis.on "error", (err) =>
      @logger.error ''.concat("Error connecting to redis://"
        @config.get('redis_host'), ':', @config.get('redis_port'))
      process.exit(1)

    return @redis

module.exports = RedisUtils
