logger = require './logger'
CLI = require './cli'
config = require 'nconf'
{identity, generate_identity} = require './identity'
WebServer = require './webserver'

###
The base application class.
###
class Application
  constructor: ->
    @cli = new CLI()
    @ws = new WebServer()

  ###
  Aborts the application with a message.
  @param {String} (msg) The message to abort the application with
  ###
  abort: (msg) =>
    logger.info(''.concat('Aborting Application: ', str, '...'))
    process.exit(1)

module.exports = Application
