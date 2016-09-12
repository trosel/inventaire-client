fs = require 'fs'
Promise = require '../lib/bluebird'
writeFile = Promise.promisify fs.writeFile
{ grey, red, green } = require 'chalk'

module.exports = (path, content)->
  console.log grey('writting sitemap'), path
  writeFile path, content, (err, res)->
    if err? then console.log red('err'), err
    else console.log green('done!')
