###
High level grammatical concepts for a DSL that aren't bound to the screen 
scraping problem domain.

###


# Require EventEmitter to wire chunks to sentences
Emitter = require('events').EventEmitter


# A sentence, which is a container of chunks.
class Sentence
    constructor: ->
        @properties = {}
        @_chunks = []

    # Apply all chunks to the sentence
    _mutate: ->
        chunk._mutate() for chunk in @_chunks

    _chunk: (chunk) ->
        @_chunks.push chunk
        chunk

    # Invoked when a Chunk finds a terminator
    _terminated: ->


# A chunk or sentence part.
class Chunk
    constructor: (@_sentence) ->
        # As promised, invoke sentence._terminated when finished.
        @on 'terminated', => @_sentence._terminated()

        # The expectation is that arguments will be retrieved by an index, but
        # named keys may be more desirable in the future. Just revisit the
        # comparision between arguments.length and numargs in _push below.
        @_arguments = []

        @_numargs = 1

    # This method should operate on @_sentence.properties to push any 
    # information expressed in the use of the DSL.
    _mutate: ->

    # Validate an argument before storing it
    _validate: (argument) ->
       typeof argument isnt 'undefined'


    # This method allows any part of a chunk to potentially accept an argument.
    # For instance, extract(arg).and().then(arg2) or extract(arg).and(arg2) or
    # extract(arg).and().then().do(arg2)
    _push: (argument) ->
        if typeof argument isnt 'undefined'
            if @_validate argument
                @_arguments.push argument
                if @_arguments.length is @_numargs
                    return @_terminate()
            else
                throw new Error "Invalid argument"
        @

    # Signal the end of a chunk, usually meaning that we've satisfied all
    # arguments. Returns the sentence so that chunks can be seamlessly strung
    # together.
    _terminate: ->
        @emit 'terminated'
        @_sentence

# Chunks are emitters.
Chunk.prototype.__proto__ = Emitter.prototype

# Export public classes
module.exports = 
    Sentence: Sentence
    Chunk: Chunk


