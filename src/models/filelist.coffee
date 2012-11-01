async = require 'async'

RedisObject = require './redis_object'

###*
 * A helper for working with filelists for a branch or tag of an application.
###
class Filelist extends RedisObject
  constructor: (@user, @application, @dtype, name=null) ->
    super name
    @basename = "node-ios-ota::applications"
    @object_name = 'filelist'

  ###*
   * Returns the the prefix for the filelist.
   * @return {String} The filelist prefix for the application tag/branch
  ###
  filelist_prefix: =>
    return [@basename, @user, @application,
            @dtype, @current, @object_name].join('::')

  ###*
   * Returns the prefix for the files hash.
   * @return {String} The prefix for the given files hash
  ###
  files_prefix: =>
    return [@basename, @user, @application,
        @dtype, @current, "files"].join('::')

  

module.exports = Filelist
