###
Grammatical chunks specific to our scraping DSL.

###

# Include our abstract grammar and expand it into the local namespace
Grammar = require './grammar'
Chunk = Grammar.Chunk
Sentence = Grammar.Sentence


# Helper method to reate a condition that will cause execution to wait until a 
# CSS selector can be satisfied.
createCondition = (selector) ->
    [selector, (query) -> document.querySelectorAll(query).length > 0]


# Set the timeout duration of a Request
class Timeout extends Chunk
    _mutate: ->
        @_sentence.properties.timeout = @_arguments[0]

    _validate: (argument) ->
        typeof argument is 'number' and argument >= 0

    after: (argument) -> @_push argument


# Extract a CSS selector or a callback that runs in the context of a page
# and process it's results. Use as 
# `extract('selector').and().then((result) -> do stuff)`
class Extract extends Chunk
    constructor: (@_sentence) ->
        super(@_sentence)
        @_numargs = 2

    _mutate: ->
        if typeof @_arguments[0] is 'string'
            @_sentence.properties.conditions.push createCondition @_arguments[0]
            selector = @_arguments[0]
            handler = @_arguments[1]
            @_sentence.properties.actions.push (page) ->
                extractor = (query) ->
                    results = []
                    preserve = ['attributes', 'baseURI', 'childElementCount', 'childNodes', 'children'
                        ,'classList', 'className', 'dataset', 'dir', 'hidden', 'id', 'innerHTML'
                        ,'innerText', 'lang', 'localName', 'namespaceURI', 'nodeName', 'nodeType'
                        ,'nodeValue', 'outerHTML', 'outerText', 'prefix', 'style', 'tabIndex'
                        ,'tagName', 'textContent', 'title', 'type', 'value'
                    ]
                    
                    for elem in document.querySelectorAll(query)
                        obj = {}
                        for key in preserve
                            obj[key] = elem[key]

                        results.push obj

                    results

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
# Use as `when().page().has(-> document.querySelectorAll('stuff').length > 5)`
# or `when().is('selector')`
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

    # Allow crossover to sentence.from() for just one invokation, to permit
    # syntax like `when().page('index.html').has('h2.headline')`
    page: (argument) -> 
        @_sentence.from(argument)
        @
    url: @page


# Execute code against a page object directly. The callback is provided with a
# page object whose `evaluate` method you may invoke yourself.
# `execute((page) -> page.evaluate extractor, handler, args)
# TODO accept three arguments in the form of extractor, handler [,args] to skip
# the page.evaluate call.
class Execute extends Chunk
    _validate: (argument) ->
        typeof argument is 'function'

    _mutate: ->
        @_sentence.properties.actions.push @_arguments[0]


# Assign a timeout handler.
class Otherwise extends Chunk
    _validate: (argument) ->
        typeof argument is 'function'

    _mutate: ->
        @_sentence.properties.errorHandlers.push @_arguments[0]


# Set the request URL
class From extends Chunk
    _validate: (argument) ->
        typeof argument is 'string'

    _mutate: ->
        @_sentence.properties.url = @_arguments[0]


# Export Grammar classes as well as our new Chunks
module.exports =
    Sentence: Sentence
    Chunk: Chunk
    Timeout: Timeout
    WaitFor: WaitFor
    Execute: Execute
    Otherwise: Otherwise
    From: From
    Extract: Extract



