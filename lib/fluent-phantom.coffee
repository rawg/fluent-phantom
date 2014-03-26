


Emitter = require('events').EventEmitter

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
            if typeof callback != 'function' then throw Error "Invalid condition"
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
                @emit PHANTOM_CREATE, ph

                ph.createPage (page) =>
                    @_page = page
                    @emit PAGE_CREATE, page

                    page.open @_url, (status) =>
                        if (status != 'success')
                            @emit events.FAILURE
                            end.call this

                        else if @_conditions.length
                            start = now()

                            tick = =>
                                # Timeout
                                if @_timeout > 0 && now() - start > @_timeout
                                    @emit events.TIMEOUT, page
                                    end.call this

                                # Check all conditions
                                else
                                    isReady = true
                                    tests = @_conditions[..]

                                    check = (condition) => 
                                        page.evaluate condition, (result) =>
                                            isReady = isReady & result
                                            if isReady
                                                if tests.length
                                                    check tests.pop()
                                                else
                                                    @emit events.READY, page
                                                    end.call this
                                    
                                    check tests.pop()

                            @_interval = setInterval tick, 250

                        else
                            @emit events.READY, page



    Request.prototype.__proto__ = Emitter.prototype

    exports =
        "Request": Request
        

module.exports = binder()
module.exports.inject = binder
