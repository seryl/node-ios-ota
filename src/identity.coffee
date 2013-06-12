crypto = require 'crypto'

###
Generates a new identity.
@param {Integer} (length) The length of the identity bytestring
@return {String} The randombyte hex string
###
generate_identity = (length=8) ->
  crypto.randomBytes(length).toString('hex')

module.exports =
  generate_identity: generate_identity
  identity: generate_identity()
