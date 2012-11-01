async = require 'async'

RedisObject = require './redis_object'

###*
 * A helper for working with branches for an application/user combo.
###
class ApplicationBranch extends RedisObject
  constructor: (@user, @application, branch=null) ->
    super branch
    @basename = "node-ios-ota::applications"
    @object_name = 'branches'

  ###*
   * Returns the the prefix for the branchlist.
   * @return {String} The branchlist prefix for the current application
  ###
  branchlist_prefix: =>
    return [@basename, @user, @application, @object_name].join('::')

  ###*
   * Returns the prefix for a particular branch.
   * @return {String} The prefix for the given branch
  ###
  branch_prefix: =>
    return [@branchlist_prefix(), @current].join('::')

  list: (fn) =>
    return @redis.smembers(@branchlist_prefix(), fn)

  ###*
   * Inserts a new branch into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    stat_add = @redis.sadd(@branchlist_prefix(), @current)
    status = if (stat_add) then null else
      message: "Error saving branch: `#{@user}/#{@application}/#{@current}`."
    fn(status, @current)

  ###*
   * Deletes a single branch for the given application.
   * @param {String} (branch) The name of the target branch
   * @param {Function} (fn) The callback function
  ###
  delete: (branch, fn) =>
    @current = branch
    @redis.srem(@branchlist_prefix(), branch)
    fn(null, true)

  ###*
   * Deletes the branches for a given application.
   * @param {Function} (fn) The callback function
  ###
  delete_all: (fn) =>
    @list (err, branchlist) =>
      async.forEach(branchlist, @delete, fn)

  ###*
   * Returns the branch information and file hashes for the given app/branch.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (branch) The name of the branch to retrieve
  ###
  info: (application, branch) =>

module.exports = ApplicationBranch
