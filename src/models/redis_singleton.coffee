redis = require 'redis'

Singleton = require '../singleton'
Config = require '../config'
Logger = require '../logger'

###*
 * Redis utility wrapper that acts as a singleton.
###
class RedisSingleton extends Singleton
  constructor: ->
    @config = Config.get()
    @logger = Logger.get()
    @redis = new redis.createClient(
      @config.get("redis_port"),@config.get("redis_host") )

    @redis.on "error", (err) =>
      @logger.error ''.concat("Error connecting to redis://"
        @config.get('redis_host'), ':', @config.get('redis_port'))
      @logger.error "Retrying connection..."

    return @redis

module.exports = RedisSingleton