###*
 * Class that acts as a singleton.
###
class Singleton
  @_instance: null
  @get: (args) ->
    @_instance or= new @ args...

module.exports = Singleton
