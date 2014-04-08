###
Grammatical chunks specific to our scraping DSL.

###

# Include our abstract grammar and expand it into the local namespace
{Sentence, Chunk} = require './grammar'

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
    # Allowable properties
    nodeProperties = ['attributes', 'baseURI', 'childElementCount', 'childNodes'
        ,'classList', 'className', 'dataset', 'dir', 'hidden', 'id', 'innerHTML'
        ,'innerText', 'lang', 'localName', 'namespaceURI', 'nodeName', 'nodeType'
        ,'nodeValue', 'outerHTML', 'outerText', 'prefix', 'style', 'tabIndex'
        ,'tagName', 'textContent', 'title', 'type', 'value', 'children'
    ]

    constructor: (@_sentence) ->
        super(@_sentence)
        @_numargs = 2

        # Properties to be preserved when extracting via a CSS selector
        @_props = ['children', 'tagName', 'innerText', 'innerHTML', 'id', 'attributes']

    _mutate: ->
        # Extract elements via a CSS selector
        if typeof @_arguments[0] is 'string'
            @_sentence.properties.conditions.push createCondition @_arguments[0]
            selector = @_arguments[0]
            handler = @_arguments[1]
            args =
                selector: selector
                preserve: @_props[..]

            @_sentence.properties.actions.push (page) ->
                extractor = (query) ->
                    # Function to recursively filter a list of HTML elements
                    filter = (elems) ->
                        results = []
                        for elem in elems
                            obj = {}
                            for key in query.preserve
                                if key is 'children' or key is 'childNodes'
                                    obj[key] = filter(elem[key])
                                else
                                    obj[key] = elem[key]

                            results.push obj

                        results

                    filter document.querySelectorAll(query.selector)


                page.evaluate extractor, handler, args

        # Extract via a function
        else
            extractor = @_arguments[0]
            handler = @_arguments[1]
            @_sentence.properties.actions.push (page) ->
                page.evaluate extractor, handler

    _validate: (argument) ->
        if @_arguments.length is 0 then typeof argument is 'string' or 'function'
        else typeof argument is 'function'

    and: (argument) -> @_push argument
    then: (argument) -> @_push argument
    process: (argument) -> @_push argument
    handle: (argument) -> @_push argument
    
    # select().properties(x, y, z).of('selector')
    of: (argument) ->
        if @_arguments.length > 0 then throw Error "Bad grammar: of() after extract()"
        else @_push argument
        @

    # extract ... and then do ...
    do: (argument) ->
        if @_arguments.length > 1 then @_push argument
        else throw Error "Bad grammar: do() before extract() or select()"

    # extract ... from(url) and then ...
    from: (argument) ->
        @_sentence.from(argument)
        @

    with: (props...) ->
        properties = props[0]
        if typeof properties isnt 'object' or properties not instanceof Array or properties.length <= 0
            throw Error "Invalid properties"
        for property in properties
            if nodeProperties.indexOf(property) < 0
                throw Error "Invalid property: " + property
        @_props = properties
        @

    properties: (properties...) -> @with(properties)

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
    
    url: (argument) -> @page(argument)


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



