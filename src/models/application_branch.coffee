async = require 'async'

RedisObject = require './redis_object'
Application = require './application'

###*
 * A helper for working with branches for an application/user combo.
###
class ApplicationBranch extends RedisObject
  constructor: (@user, @application, branch=null) ->
    super branch
    @object_name = 'branches'

  ###*
   * Returns the the prefix for the branchlist.
   * @return {String} The branchlist prefix for the current application
  ###
  branchlist_prefix: () =>
    app = new Application(@user)
    return [app.applist_prefix(), @application, @object_name].join('::')

  ###*
   * Returns the prefix for a particular branch.
   * @return {String} The prefix for the given branch
  ###
  branch_prefix: (branch) =>
    return [@branchlist_prefix, branch].join('::')

  list: () =>
    branch_prefix = @get_app_build_prefix application, "branches"
    return @redis.smembers(branch_prefix)

  ###*
   * Inserts a new branch into the given application.
   * @param {String} (branch) The name of the branch to add
   * @param {Function} (fn) The callback function
  ###
  save: (fn) =>
    branch_prefix = @get_app_build_prefix application, "branches"
    @redis.sadd(branch_prefix, branch)
    fn(null, true)

  ###*
   * Deletes a single branch for the given application.
   * @param {String} (branch) The name of the target branch
   * @param {Function} (fn) The callback function
  ###
  delete: (branch, fn) =>

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

  ###*
   * Returns the application build info for either a branch or tag.
   * @param {String} (application) The name of the application to retrieve
   * @param {String} (dtype) The data type to get `branches` or `tags`
  ###
  get_app_build_prefix: (application, dtype) =>
    return [@applist_prefix(), application, dtype].join('::')
