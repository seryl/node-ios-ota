nconf = require 'nconf'

Singleton = require './singleton'

###*
 * Config class that acts as a singleton.
###
class Config extends Singleton
  constructor: ->
    return nconf

module.exports = Config
