path = require 'path'
os = require 'os'

global.fs = require 'fs'
global.rimraf = require 'rimraf'

global.chai = require 'chai'
global.assert = chai.assert

chai.should()

Config = require '../../src/config'
CLI = require '../../src/cli'

global.cli = new CLI()
global.config = Config.get()

config.overrides({
  'port': 8080,
  'repository': path.normalize("#{os.tmpDir()}/tmp/node-ios-ota")
})
