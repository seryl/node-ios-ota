{exec} = require 'child_process'
task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'watch', 'Starts a watcher for the src/*.coffee files', ->
  exec 'coffee -w src/ -o lib/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

REPORTER = "spec"

task "test", "run tests", ->
  exec "clear; NODE_ENV=test 
    ./node_modules/.bin/mocha 
    --compilers coffee:coffee-script
    --reporter #{REPORTER}
    --require coffee-script 
    --require test/lib/test_helper.coffee
    --colors
  ", (err, output) ->
    throw err if err
    console.log output
