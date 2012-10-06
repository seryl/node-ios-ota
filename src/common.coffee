crypto = require 'crypto'
log4js = require 'log4js'

class Logger
  constructor: () ->
    logger = log4js.getLogger()

module.exports =
  generate_identity: () ->
    crypto.randomBytes(8).toString('hex')

  logger: () =>
    return instances if instance?
    return new Logger
