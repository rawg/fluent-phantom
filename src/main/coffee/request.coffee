

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
                        page.evaluate extract, handler
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
            req.conditions = @conditions
            req.actions = @successes

            if @failures.length > 0
                req.errorHandlers = @failures
            else
                req.errorHandlers.push -> console.error "Request timed out"

            req.timeout = @timeout
            req

        open: (url) ->
            req = @build url
            req.begin()
            req

    class Request
        errors = 
            TIMEOUT: 'timeout'
            HALT: 'halt'
            RESPONSE: 'response'

        callAllAndQuit = (interval, functions, ph, page, args) ->
            clearInterval(interval)
            funcs = functions[..]
            funcs.push -> ph.exit()
            func.call(this, ph, page) for func in functions

        constructor: (@url) ->
            @conditions = []
            @actions = []
            @errorHandlers = []
            @timeout = 3000
            @interval

        doSuccess: (ph, page) ->
            callAllAndQuit(@interval, @actions, ph, page)

        doFailure: (reason, ph, page) ->
            callAllAndQuit(@interval, @errorHandlers, ph, page, reason)

        halt: () ->
            clearInterval(@interval)
            @doFailure()

        begin: () ->
            phantom.create (ph) =>
                ph.createPage (page) =>
                    page.open @url, (status) =>
                        if (status != 'success')
                            @doFailure(ph, page)
                        else if @conditions.length
                            start = now()

                            tick = =>
                                # Timeout (if applicable)
                                if @timeout > 0 && now() - start > @timeout
                                    @doFailure(ph, page)

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
                                                    @doSuccess(ph, page)

                                    # Start checking the conditions
                                    check tests.pop()

                            @interval = setInterval(tick, 250)

                        else
                            @doSuccess(ph, page)

    exports =
        "RequestBuilder": RequestBuilder
        "Request": Request
        "create": -> new RequestBuilder


module.exports = binder()
module.exports.inject = binder
