


Emitter = require('events').EventEmitter
Grammar = require('./builder-grammar')

now = ->
    (new Date).getTime()


binder = (phantom) ->
    phantom = if typeof phantom == 'object' then phantom else require 'phantom'


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
    
    
    class Builder extends Grammar.Sentence

        constructor: ->
            @properties = 
                conditions: []
                actions: []
                timeoutHandlers: []
                timeout: null
                url: null

        # Currying keeps access consistent - otherwise you'd have to use 
        # something like timeout.after(val) instead of timeout().after(val)
        # and timeout(val)
        timeout: (val) -> 
            obj = new Grammar.Timeout @
            obj._push val
        
        forever: -> @timeout 0

        extract: (val) -> 
            obj = new Grammar.Extract @
            obj._push val

        select: @extract

        when: (val) ->
            obj = new Grammar.WaitFor @
            obj._push val

        wait: @when

        from: (val) ->
            obj = new Grammar.From @
            obj._push val

        url: @from

        execute: (val) ->
            obj = new Grammar.Execute @
            obj._push val

        do: @execute
        evaluate: @execute

        # Conditional synonym
        until: (arg) ->
            if typeof arg is 'number' then @timeout
            else @when

        # Build a request
        build: ->
            req = new Request
            if @properties.timeout then req.timeout @properties.timeout
            if @properties.url then req.url @properties.url

            req.condition(condition) for condition in @properties.conditions
            req.on(events.TIMEOUT, callback) for callback in @properties.timeoutHandlers
            req.on(events.READY, callback) for callback in @properties.actions

            req

        # Build and execute a request
        execute: (url) ->
            @from url
            req = @build()
            req.execute()
            req

        _terminated: ->
            # Not so sure I like this...
            if typeof @and is 'undefined'
                @and = -> @


    class Request
        end = ->
            @emit events.FINISH
            clearInterval @_interval
            @_phantom.exit()

        constructor: ->
            @_url = ''
            @_conditions = []
            @_interval = null
            @_phantom = null
            @_page = null
            @_timeout = 3000

        condition: (callback) ->
            if typeof callback isnt 'function' and typeof callback isnt 'object' then throw Error "Invalid condition"
            @_conditions.push callback
            this

        timeout: (value) ->
            if typeof value == 'number' && value >= 0
                @_timeout = value
                this
            else
                @_timeout

        url: (url) ->
            if typeof url == 'string'
                @_url = url
                this
            else
                @_url

        halt: ->
            @emit events.HALT
            end.call this

        execute: (url) ->
            @url url   # Set the URL if it was provided

            phantom.create (ph) =>
                @_phantom = ph
                @emit events.PHANTOM_CREATE
                
                ph.createPage (page) =>
                    @_page = page
                    @emit events.PAGE_CREATE

                    page.open @_url, (status) =>
                        if (status != 'success')
                            @emit events.FAILURE
                            end.call this

                        else if @_conditions.length
                            start = now()

                            tick = =>
                                @emit events.CHECKING

                                # Timeout
                                if @_timeout > 0 && now() - start > @_timeout
                                    @emit events.TIMEOUT, page
                                    end.call this

                                # Check all conditions
                                else
                                    isReady = true
                                    tests = @_conditions[..]

                                    check = (condition) =>
                                        if typeof condition is 'function'
                                            test = condition
                                            args = null

                                        else if typeof condition is 'object'
                                            [args, test] = condition

                                        handler = (result) =>
                                            isReady = isReady & result
                                            if isReady
                                                if tests.length
                                                    check tests.pop()
                                                else
                                                    @emit events.READY, page
                                                    end.call this
                                        
                                        page.evaluate test, handler, args

                                    check tests.pop()

                            @_interval = setInterval tick, 250

                        else
                            @emit events.READY, page
                            end.call this



    Request.prototype.__proto__ = Emitter.prototype

    exports =
        "Request": Request
        "Builder": Builder
        "create": -> new Builder
        

module.exports = binder()
module.exports.inject = binder
