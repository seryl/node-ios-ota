crypto = require 'crypto'

Singleton = require './singleton'

###*
 * Generates a new identity.
 * @param {Integer} (length) The length of the identity bytestring
 * @return {String} The randombyte hex string
###
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
