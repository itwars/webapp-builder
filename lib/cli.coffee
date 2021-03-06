{ AppMonitor } = require './AppMonitor'
ArgumentParser = require('argparse').ArgumentParser
Reporter = require './Reporter'
path = require 'path'
fs = require 'fs'

get_version = ->
  package_json = path.join __dirname, "../package.json"
  package_info = JSON.parse fs.readFileSync package_json, "utf-8"
  package_info.version

parser = new ArgumentParser
  version: get_version()
  addHelp: yes
  description: 'Command-line frontend to bootstrap making web applications.'

common_args = (parser) ->
  parser.addArgument [ '-f', '--file' ],
    help: "File to use as a build script."

  parser.addArgument [ '-v', '--verbose' ],
    action: 'count'
    help: "Increase amount of logging."

  parser.addArgument [ '-j', '--jobs' ],
    help: 'Number of builds to perform simultaneously. Default is number of ' +
          'CPUs.'
    defaultValue: null
    dest: 'concurrency'
    metavar: 'N'
    type: 'int'

subparsers = parser.addSubparsers
  title: 'Valid commands'
  dest: 'command'

server_parser = subparsers.addParser 'serve',
  addHelp: yes
  help: 'Run an auto-building web server.'
  description: "Create a web server that serves from the source directory. Any
    files requested will automatically be built and served in real time."

common_args server_parser

server_parser.addArgument [ '-p', '--port' ],
  help: 'Port to listen on. Defaults to the PORT environment variable or 8000.'
  defaultValue: process.env.PORT ? 0
  type: 'int'

server_parser.addArgument [ '--no-watch' ],
  help: 'Disable watching the file system for changes and auto-refresh.'
  action: 'storeFalse'
  dest: 'watchFileSystem'
  defaultValue: true

server_parser.addArgument [ '--no-browser' ],
  help: 'Do not automatically open the browser to the server\'s address.'
  action: 'storeFalse'
  dest: 'openBrowser'
  defaultValue: true

build_parser = subparsers.addParser "build",
  addHelp: yes
  help: 'Build all defined assets.'

common_args build_parser

build_parser.addArgument [ 'targets' ],
  help: 'Targets to build'
  nargs: '*'
  metavar: 'target'

monitor_parser = subparsers.addParser 'monitor',
  addHelp: yes
  help: 'Run a node program and with refreshing support.'
  description: "Run the given program. If any of the files included by the
    program is modified, automatically restart the program."

monitor_parser.addArgument [ 'program' ],
  help: 'Program to run, with arguments.'
  nargs: '+'

args = parser.parseArgs()

commands =
  serve: ->
    # Set up monitoring if necessary
    if AppMonitor.IS_CHILD
      server = require './server'
      server.standalone args
    else
      m = new AppMonitor process.argv.slice 1
      m.start()
  monitor: ->
    m = new AppMonitor args.program
    m.start()
  build: ->
    BuildManager = require './BuildManager'
    args.verbose += Reporter.INFO
    m = new BuildManager args
    m.make args.targets, (results) ->
      m.saveCache()
      code = 0
      code = 1 for err in results when err?

      process.exit code

commands[args.command]()
