Singleton = require './singleton'
winston = require 'winston'
MixlibLog = require('winston-mixlib-log').MixlibLog

###*
 * Logging class that acts as a singleton.
###
class Logger extends Singleton
  ###*
   * At some point we're going to want to allow appenders here.
  ###
  constructor: ->
    @logger = new winston.Logger
      transports: [
        new MixlibLog
          timestamp: true
      ]
    @logger.log = () ->
      args = arguments
      winston.Logger.prototype.log.apply(this, args)
    return @logger

module.exports = Logger
