winston = require 'winston'
MixlibLog = require('winston-mixlib-log').MixlibLog

Singleton = require './singleton'

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
      winston.Logger.prototype.log.apply(@, arguments)
    return @logger

module.exports = Logger
