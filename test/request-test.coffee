
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'
phantom = new mock.Phantom
request = require('../lib/fluent-phantom').inject(phantom)

delay = (ms, func) -> setTimeout func, ms


describe 'A request', ->
    afterEach ->
        phantom.removeAllListeners()

    it 'should have a settable URL', ->
        req = new request.Request
        req.url('#')
        should(req.url()).be.equal('#')

    it 'should have a settable timeout', ->
        req = new request.Request
        req.timeout(500)
        should(req.timeout()).be.equal(500)

    it 'should have have a fluent interface (setters should return this)', ->
        req = new request.Request
        should(req.timeout(500)).be.equal(req)
        should(req.url('#')).be.equal(req)
        should(req.condition(() ->)).be.equal(req)

    it 'should wait for conditions to be satisfied before emitting ready', (done) ->
        sentry = false

        req = new request.Request
        req.timeout(2000)
            .url('#')
            .condition(-> sentry)
            .on('ready', -> done())
            .execute()

        delay 500, -> sentry = true

    it 'should timeout if conditions are not satisfied in time', (done) ->

        req = new request.Request
        req.timeout(500)
            .url('#')
            .condition(-> false)
            .on('timeout', -> done())
            .on('ready', -> should.fail 'timeout', 'ready', 'Expected timeout but received ready instead')
            .execute()



    it 'should invoke phantom methods during execution', (done) ->
        phEvents = ['createPage', 'open', 'exit']
        emitted = []

        delay 1500, -> 
            keys = (key for key of emitted)
            should.fail(keys, phEvents, 'Not all events were emitted. Only received ' + keys.join ', ')

        req = new request.Request
        req.url('#').timeout(1500)

        for event in phEvents
            do (event) ->
                phantom.once event, ->
                    emitted[event] = true
                    if emitted.createPage and emitted.open and emitted.exit
                        done()
        
        req.execute()

    it 'should invoke phantom.exit() when finished without a condition', (done) ->
        phantom.once 'exit', -> done()

        req = new request.Request
        req.execute()

    it 'should invoke phantom.exit() after timing out', (done) ->
        phantom.once 'exit', -> done()
        
        req = new request.Request
        req.timeout(500)
        req.condition -> false
        req.execute()

    it 'should invoke phantom.exit() after satisfying a condition', (done) ->
        phantom.once 'exit', -> done()
        
        sentry = false
        req = new request.Request
        req.condition -> sentry
        req.timeout 2000

        delay 500, ->
            sentry = true

        req.execute()

