

###
# TODO: switch to event emitters in request
# TODO: send ph and page objects as args to events
# TODO: document that conditions must be synchronous and return a bool
# TODO: combine conditions by wrapping in (finish: Function) => Unit or something similar
# TODO: add easy CSS selection
###

Emitter = require('events').EventEmitter

now = ->
    (new Date).getTime()


# Exports are defined in a closure to make phantom injectable
binder = (phantom) ->
    phantom = if typeof phantom == 'object' then phantom else require 'phantom'

    class RequestBuilder
        states =
            'UNTIL': 0
            'WHEN': 1
            'EXEC': 2
            'EXTRACT': 3
            'BEGIN': 4
            'HANDLER': 5

        states.keyOf = (key) -> 
               (v for k, v of states when k == key)

        
        state = states.BEGIN

        transitions = {}
        transitions[states.BEGIN] = [states.UNTIL, states.WHEN, states.EXEC, states.EXTRACT]
        transitions[states.UNTIL] = [states.WHEN, states.EXEC, states.EXTRACT]
        transitions[states.WHEN] = [states.UNTIL, states.EXEC, states.EXTRACT]
        transitions[states.EXEC] = [states.UNTIL, states.WHEN, states.EXTRACT]
        transitions[states.EXTRACT] = [states.HANDLER]
        transitions[states.HANDLER] = [states.EXEC, states.EXTRACT, states.UNTIL, states.WHEN]

        constructor: () ->
            @conditions = []
            @successes = []
            @failures = []
            @timeout = 2000
            @extractor = null

        transitionTo: (newState) ->
            if transitions[state].indexOf newState >= 0
                state = newState
            else
                throw Error "Invalid state transition: " + states.keyOf(state) + " => " + states.keyOf(newState) 

        append: (callback) ->
            if typeof callback != 'function' then throw Error "Invalid callback"
            switch state
                when states.WHEN then @conditions.push callback
                when states.UNTIL then @failures.push callback 
                when states.EXEC then @successes.push callback 
                when states.EXTRACT then @extractor = callback
                when states.HANDLER
                    extract = @extractor
                    handler = callback
                    @successes.push (ph, page) ->
                        page.evaluate extract, (results) -> handler(results)

                    @extractor = null

                    @transitionTo states.EXEC
            this

        when: (callback) ->
            @transitionTo states.WHEN
            if typeof callback == 'function'
                @append(callback)
            else
                this

        execute: (callback) ->
            @transitionTo states.EXEC
            @append(callback)

        evaluate: (extractor, handler) ->
            @transitionTo states.EXEC
            @append((ph, page) -> page.evaluate extractor, handler)

        extract: (callback) ->
            @transitionTo states.EXTRACT
            @append(callback)

        handle: (callback) ->
            @transitionTo states.HANDLER
            @append callback

        then: (callback) ->
            if typeof callback == 'function'
                # when ... then ... without wrecking until ... then
                if state == states.WHEN then @transitionTo states.EXEC
                @append(callback)

            else
                this

        until: (callbackOrTimeout) ->
            @transitionTo states.UNTIL
            if typeof callbackOrTimeout == 'number'
                @timeout = callbackOrTimeout
            else if typeof callbackOrTimeout == 'function'
                @append(callbackOrTimeout)
            this

        # Synonyms
        orElse: (callback) ->
            @until callback

        otherwise: (callback) ->
            @until callback

        waitFor: (callback) ->
            @when callback

        has: (callback) ->
            @when callback

        process: (callback) ->
            @handle callback

        forever: ->
            @until 0

        # and ... or and(func)
        and: (callback) ->
            if typeof callback == 'function'
                @append(callback)
            this

        # Just a grammatical place holder
        page: -> this

        build: (url) ->
            req = new Request url

            req.on('ready', callback) for callback in @successes
            req.on('timeout', callback) for callback in @failures
            req.conditions = @conditions
            req.timeout = @timeout
            req

        open: (url) ->
            req = @build url
            req.begin()
            req

    class Request
        events = 
            TIMEOUT: 'timeout'
            HALT: 'halt'
            FAILURE: 'failure'
            READY: 'ready'
            FINISH: 'finish'
            PH_CREATE: 'create-phantom'
            PAGE_CREATE: 'create-page'
            PAGE_OPEN: 'open-page'

        constructor: (@url) ->
            @conditions = []
            @timeout = 3000
            @interval = null
            @phantom = null
            @page = null

            exit = (ph, page) -> ph.exit()
            @on(events.FAILURE, exit)
            @on(events.TIMEOUT, exit)
            @on(events.FINISH, exit)

        addCondition: (callback) ->
            @conditions.push callback

        halt: ->
            clearInterval(@interval)
            @phantom.exit()
            @emit(events.HALT)

        begin: ->
            phantom.create (ph) =>
                @phantom = ph
                @emit events.PH_CREATE, ph

                ph.createPage (page) =>
                    @page = page
                    @emit events.PAGE_CREATE, page

                    page.open @url, (status) =>
                        if (status != 'success')
                            @emit events.FAILURE, ph, page

                        else if @conditions.length
                            start = now()

                            tick = =>
                                # Timeout (if applicable)
                                if @timeout > 0 && now() - start > @timeout
                                    @emit(events.TIMEOUT, ph, page)

                                # Keep ticking
                                else
                                    isReady = true
                                    tests = @conditions[..]

                                    check = (condition) =>
                                        page.evaluate condition, (result) =>
                                            isReady = isReady & result
                                            if isReady              # else, keep ticking
                                                if tests.length
                                                    check tests.pop()
                                                else
                                                    @emit(events.READY, ph, page)
                                                    @emit(events.FINISH, ph, page)

                                    # Start checking the conditions
                                    check tests.pop()

                            @interval = setInterval(tick, 250)

                        else
                            @emit(events.READY, ph, page)
                            @emit(events.FINISH, ph, page)

        Request.prototype.__proto__ = Emitter.prototype

    exports =
        "RequestBuilder": RequestBuilder
        "Request": Request
        "create": -> new RequestBuilder


module.exports = binder()
module.exports.inject = binder
