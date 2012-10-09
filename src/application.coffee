Logger = require './logger'
CLI = require './cli'
Config = require './config'
{Identity, generate_identity} = require './identity'
WebServer = require './webserver'

###*
 * The base application class.
###
class Application
  constructor: (@pkg_info) ->
    @config = Config.get()
    @logger = Logger.get()
    @cli = new CLI(@pkg_info, @logger)
    @identity = Identity.get()
    @ws = new WebServer(@config.get('port'), @pkg_info)

  abort: (str) =>
    @logger.info('aborting...')
    process.exit(1)

module.exports = Application
