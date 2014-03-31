

Emitter = require('events').EventEmitter


class Sentence
    constructor: ->
        @properties = {}

    _terminated: ->


class Chunk
    constructor: (@_sentence) ->
        @on 'terminated', => @_sentence._terminated()
        @_arguments = []
        @_numargs = 1

    _mutate: ->

    _validate: (argument) ->
       typeof argument isnt 'undefined'

    _push: (argument) ->
        if typeof argument isnt 'undefined'
            if @_validate argument
                @_arguments.push argument
                if @_arguments.length is @_numargs
                    return @_terminate()
            else
                throw new Error "Invalid argument"
        @

    _terminate: ->
        @_mutate()
        @_arguments = []
        @emit 'terminated'
        @_sentence

Chunk.prototype.__proto__ = Emitter.prototype

module.exports = 
    Sentence: Sentence
    Chunk: Chunk

###
sen = new Builder

console.log sen.timeout()
console.log sen.timeout().after(500)
console.log sen.timeout(1000)
###


