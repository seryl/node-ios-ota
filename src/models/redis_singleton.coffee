redis = require 'redis'

config = require 'nconf'
logger = require '../logger'

###*
 * Redis utility wrapper that acts as a singleton.
###
class RedisSingleton
  constructor: ->
    @redis = new redis.createClient(
      config.get("redis_port"),config.get("redis_host") )

    @redis.on "error", (err) =>
      logger.error ''.concat("Error connecting to redis://"
        config.get('redis_host'), ':', config.get('redis_port'))
      logger.error "Retrying connection..."

    return @redis

module.exports = new RedisSingleton()
