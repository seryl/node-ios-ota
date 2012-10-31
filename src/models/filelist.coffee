async = require 'async'

RedisObject = require './redis_object'

###*
 * A helper for working with filelists for a branch or tag of an application.
###
class Filelist extends RedisObject
  constructor: (@user, @application, @dtype) ->
    super tag
    @basename = "node-ios-ota::applications"
    @object_name = 'filelist'

module.exports = Filelist
