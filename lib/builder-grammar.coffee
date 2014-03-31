
Grammar = require './grammar'
Chunk = Grammar.Chunk
Sentence = Grammar.Sentence

# Create a condition that will cause execution to wait until a CSS selector can 
# be satisfied.
createCondition = (selector) ->
    [selector, (query) -> document.querySelectorAll(query).length > 0]


# Set a timeout duration
class Timeout extends Chunk
    _mutate: ->
        @_sentence.properties.timeout = @_arguments[0]

    _validate: (argument) ->
        typeof argument is 'number' and argument >= 0

    after: (argument) -> @_push argument


# Extract a CSS selector or callback and process it
# extract 'css selector' and then (result) -> {}
class Extract extends Chunk
    constructor: (@_sentence) ->
        super(@_sentence)
        @_numargs = 2

    _mutate: ->
        if typeof @_arguments[0] is 'string'
            @_sentence.properties.conditions.push createCondition @_arguments[0]
            selector = @_arguments[0]
            callback = @_arguments[1]
            @_sentence.properties.actions.push ->
                extractor = (query) -> JSON.stringify document.querySelectorAll query
                handler = (result) -> callback JSON.parse result
                page.evaluate extractor, handler, selector

        else
            extractor = @_arguments[0]
            handler = @_arguments[1]
            @_sentence.properties.actions.push ->
                page.evaluate extractor, handler

    _validate: (argument) ->
        if @_arguments.length is 0 then typeof argument is 'string' or 'function'
        else typeof argument is 'function'

    and: (argument) -> @_push argument
    then: (argument) -> @_push argument
    process: (argument) -> @_push argument
    handle: (argument) -> @_push argument

    # extract ... and then do ...
    do: (argument) ->
        if @_arguments.length > 1 then @_push argument
        else throw Error "Bad grammar: do() before extract() or select()"

    # extract ... from(url) and then ...
    from: (argument) ->
        @_sentence.from(argument)
        @


# Wait for a CSS selector to be satisfied or for a function to return true
# when page has 'selector'
# when is -> bool
class WaitFor extends Chunk
    _mutate: ->
        if typeof @_arguments[0] is 'string'
            condition = createCondition @_arguments[0]
        else
            condition = [null, @_arguments[0]]

        @_sentence.properties.conditions.push condition

    _validate: (argument) ->
        typeof argument is 'string' or 'function'

    has: (argument) -> @_push argument
    is: (argument) -> @_push argument
    ready: (argument) -> @_push argument
    for: (argument) -> @_push argument

    # when page(url) has ...
    page: (argument) -> 
        @_sentence.from(argument)
        @
    url: @page


# Execute code against a page object
# execute (page) -> page.evaluate extractor, handler, args
# todo execute( extractor, handler [, args])
class Execute extends Chunk
    _validate: (argument) ->
        typeof argument is 'function'

    _mutate: ->
        @_sentence.properties.actions.push @_arguments[0]
    

class Otherwise extends Chunk
    _validate: (argument) ->
        typeof argument is 'function'

    _mutate: ->
        @_sentence.properties.timeoutHandlers.push @_arguments[0]


class From extends Chunk
    _validate: (argument) ->
        typeof argument is 'string'

    _mutate: ->
        @_sentence.properties.url = @_arguments[0]


module.exports =
    Sentence: Sentence
    Chunk: Chunk
    Timeout: Timeout
    WaitFor: WaitFor
    Execute: Execute
    Otherwise: Otherwise
    From: From
    Extract: Extract



