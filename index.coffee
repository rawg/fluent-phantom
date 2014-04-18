
# A fluent DSL for scraping web content using [PhantomJS](http://phantomjs.org/) 
# and the [PhantomJS bridge for Node](https://github.com/sgentle/phantomjs-node).
#

# We require EventEmitter to be inherited by Request
Emitter = require('events').EventEmitter

# A helper function to provide the current time
now = ->
    (new Date).getTime()


binder = (phantom) ->
    phantom = if typeof phantom == 'object' then phantom else require 'phantom'

    # A fluent builder
    class Builder

        constructor: ->
            super()
            @properties = 
                conditions: []
                actions: []
                errorHandlers: []
                timeout: null
                url: null

        # Currying keeps access consistent - otherwise you'd have to use 
        # something like timeout.after(val) instead of timeout().after(val)
        # and timeout(val)
        timeout: (val) -> 
            obj = @_chunk new Grammar.Timeout @
            obj._push val
        
        forever: -> @timeout(0)

        extract: (val) -> 
            obj = @_chunk new Grammar.Extract @
            obj._push val

        select: (val) -> @extract val

        when: (val) ->
            obj = @_chunk new Grammar.WaitFor @
            obj._push val

        wait: (val) -> @when val

        from: (val) ->
            obj = @_chunk new Grammar.From @
            obj._push val

        url: (val) -> @from val

        otherwise: (val) ->
            obj = @_chunk new Grammar.Otherwise @
            obj._push val

        evaluate: (val) ->
            obj = @_chunk new Grammar.Execute @
            obj._push val

        do: (val) -> @evaluate val

        # Conditional synonym: until(1000) should be interpreted as setting
        # the request timeout to 1s, but until('selector') and until(->) should
        # be understood as synonymous with when().
        until: (arg) ->
            if typeof arg is 'number' then @timeout(arg)
            else @when(arg)

        # Allow crossover to an immediately previous Extract clause for 
        # extract('selector').and(->).with(props)
        with: (args...) ->
            for idx in [@_chunks.length - 1 .. 0]
                if @_chunks[idx] instanceof Grammar.Extract
                    @_chunks[idx].with(args)
                    return @
            @

        # Build a request, applying all changes described in the grammar.
        build: ->
            # Extract information provided through all chunks
            @_mutate()
            req = new Request
            if @properties.timeout? and @properties.timeout >= 0 then req.timeout @properties.timeout
            if @properties.url then req.url @properties.url

            req.condition(condition) for condition in @properties.conditions
            for callback in @properties.errorHandlers
                req.on(events.TIMEOUT, callback)
                req.on(events.REQUEST_FAILURE, callback)
            req.action(action) for action in @properties.actions

            req

        # Build and immediately execute a request
        execute: (url) ->
            @from url
            req = @build()
            req.execute()
            req

        _terminated: ->
            # After the first chunk has been applied, expand to allow joining
            # chunks with `and()`
            #
            # Not so sure I like this...
            if typeof @and is 'undefined'
                @and = -> @


    # Events that may be emitted by a Request
    events =
        HALT: 'halted'
        PHANTOM_CREATE: 'phantom-created'
        PAGE_CREATE: 'page-created'
        PAGE_OPEN: 'page-opened'
        TIMEOUT: 'timeout'
        REQUEST_FAILURE: 'failed'
        READY: 'ready'
        FINISH: 'finished'
        CHECKING: 'checking'
        CONSOLE: 'console'
    
    
    # A request
    class Request
        # Private method to clean up open Phantom instances and notify listeners
        end = ->
            @emit events.FINISH
            clearInterval @_interval
            @_phantom.exit()

        log = (msg) ->
            console.log msg

        constructor: ->
            @_url = ''
            @_condition = null
            @_action = null
            @_interval = null
            @_phantom = null
            @_page = null
            @_timeout = 3000
            @_bindConsole = false
            @_debug = false

        # Add a callback that must return true before emitting ready
        condition: (callback, argument) ->
            if typeof callback isnt 'function' and typeof callback isnt 'object' then throw Error "Invalid condition"
            if typeof argument is 'undefined' then argument = null
            @_condition =
                callback: callback
                argument: argument
            this

        # Add an action to be performed whenc ontent is ready
        action: (callback) ->
            if typeof callback isnt 'function' then throw Error "Invalid action"
            @_action = callback
            this

        # Set or get the timeout value
        timeout: (value) ->
            if typeof value == 'number' && value >= 0
                @_timeout = value
                this
            else
                @_timeout

        # Toggle binding console.log to the PhantomJS instance's console.log.
        console: (bind) ->
            if typeof bind is 'boolean'
                @_bindConsole = bind
                if @_bindConsole
                    @addListener events.CONSOLE, log
                else
                    @removeListener events.CONSOLE, log
                @

            else
                @_bindConsole
            
        # Enable or disable debugging
        debug: (isOn) ->
            if typeof isOn is 'boolean'
                @_debug = isOn
                
                for key, event of events
                    do (event) ->
                        callback = -> console.log 'DEBUG: ' + event

                    if @_debug
                        @addListener event, callback
                    else
                        @removeListener event, callback
                @

            else
                @_debug

        # Set or get the URL
        url: (url) ->
            if typeof url == 'string'
                @_url = url
                this
            else
                @_url

        # Interrupt execution and end ASAP
        halt: ->
            @emit events.HALT
            end.call this

        # Execute the request
        execute: (url) ->
            @url url   # Set the URL if it was provided

            phantom.create (ph) =>
                @_phantom = ph
                @emit events.PHANTOM_CREATE
                
                ph.createPage (page) =>
                    @_page = page
                    page.set('onConsoleMessage', (msg) => @emit events.CONSOLE, msg)
                    @emit events.PAGE_CREATE

                    page.open @_url, (status) =>
                        if (status != 'success')        # Request failed
                            @emit events.REQUEST_FAILURE
                            end.call this

                        else if @_condition isnt null    # Request succeeded, but we have to verify the DOM
                            start = now()

                            # This function is called over and over until all conditions 
                            # have been satisfied or we run out of time.
                            tick = =>
                                @emit events.CHECKING

                                # Timeout
                                if @_timeout > 0 && now() - start > @_timeout
                                    @emit events.TIMEOUT
                                    end.call this

                                # Check sentry and perform action if ready
                                else
                                    handler = (result) =>
                                        if result
                                            @emit events.READY
                                            @_action(page)
                                            end.call this

                                    page.evaluate @_condition.callback, handler, @_condition.argument


                            @_interval = setInterval tick, 250

                        else                            # Request succeeded and no verifications necessary - proceed!
                            @emit events.READY
                            @_action(page)
                            end.call this

    # Ensure that Request can emit events
    Request.prototype.__proto__ = Emitter.prototype

    # Export bound classes
    exports =
        "Request": Request
        "Builder": Builder
        "events": events
        "create": -> new Builder
        

module.exports = binder()
module.exports.inject = binder
