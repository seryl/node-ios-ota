Singleton = require './singleton'
winston = require 'winston'

###*
 * Logging class that acts as a singleton.
###
class Logger extends Singleton
  ###*
   * At some point we're going to want to allow appenders here.
  ###
  constructor: ->
    return new winston.Logger
      transports: [
        new winston.transports.Console
          timestamp: true
      ]

module.exports = Logger
