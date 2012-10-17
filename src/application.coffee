Logger = require './logger'
CLI = require './cli'
Config = require './config'
{Identity, generate_identity} = require './identity'
WebServer = require './webserver'

###*
 * The base application class.
###
class Application
  constructor: () ->
    @config = Config.get()
    @logger = Logger.get()
    @cli = new CLI()
    @identity = Identity.get()
    @ws = new WebServer(@config.get('port'))

  abort: (str) =>
    @logger.info('aborting...')
    process.exit(1)

module.exports = Application
