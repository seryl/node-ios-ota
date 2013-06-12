path = require 'path'

global.fs = require 'fs.extra'
global.os = require 'os'
global.rimraf = require 'rimraf'

global.chai = require 'chai'
global.assert = chai.assert

chai.should()

global.config = require 'nconf'
CLI = require '../../src/cli'

global.cli = new CLI()

config.overrides({
  'port': 8080,
  'repository': path.normalize(path.join(__dirname, "..", "tmp"))
})
