fs = require 'fs'
crypto = require 'crypto'

###*
 * Generates an md5sum for a given file.
 * @param {Integer} (filepath) The path to the file you want an md5sum of
 * @return {String} The md5sum of the file
###
filemd5 = (filepath, cb) ->
  fs.readFile filepath, 'binary', (err, data) ->
    cb(err, crypto.createHash('md5').update(data).digest('hex'))

module.exports = filemd5
