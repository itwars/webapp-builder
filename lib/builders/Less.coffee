{ Builder } = require '../Builder'
fs = require 'fs'
path = require 'path'
less = require 'less'

Builder.registerBuilder class Less extends Builder
  @targetSuffix: '.css'

  constructor: (target, sources, options) ->
    super target, sources, options

    @config = {}

  validateSources: ->
    if @sources.length != 1
      throw new Error "#{@} requires exactly one source."

  getData: (next) ->
    parser = new less.Parser @config
    fs.readFile @sources[0].getPath(), 'utf-8', (err, data) ->
      return next err if err?

      parser.parse data, (err, tree) ->
        return next err if err?

        next null, tree.toCSS()
