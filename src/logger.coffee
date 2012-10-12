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
    @logger = new winston.Logger
      transports: [
        new winston.transports.Console
          timestamp: () ->
            cdate = new Date
            ("").concat("[",
              "#{cdate.getUTCFullYear()}-",
              "#{cdate.getUTCMonth()+1}-",
              "#{cdate.getUTCDate()}T",
              "#{cdate.getUTCHours()}:",
              "#{cdate.getUTCMinutes()}:",
              "#{cdate.getUTCSeconds()}Z",
              "]")
      ]
    @logger.log = () ->
      args = arguments
      winston.Logger.prototype.log.apply(this, args)
    return @logger

module.exports = Logger
