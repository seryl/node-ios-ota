winston = require 'winston'
MixlibLog = require('winston-mixlib-log').MixlibLog

logger = new winston.Logger
  transports: [
    new MixlibLog
      timestamp: true
  ]

logger.log = ->
  winston.Logger.prototype.log.apply(@, arguments)

module.exports = logger
