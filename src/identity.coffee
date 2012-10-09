Singleton = require './singleton'
crypto = require 'crypto'

# Generates a new identity
generate_identity = (length=8) ->
  crypto.randomBytes(length).toString('hex')

###*
 * A singleton for generating an identity
###
class Identity extends Singleton
  constructor: () ->
    @id = generate_identity()
    return @id

module.exports =
  generate_identity: generate_identity
  Identity: Identity
