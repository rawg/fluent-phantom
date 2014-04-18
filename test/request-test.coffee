
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'

phantom = new mock.Phantom
request = require('../index.coffee').inject(phantom)

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
            .action(-> done())
            .execute()

        delay 500, -> sentry = true

    it 'should accept arguments to be passed to Phantom for conditions', (done) ->
        sentry = 2

        condition = (arg) -> sentry + arg >= 10

        req = new request.Request
        req.condition(condition, 5)
            .action(-> done())
            .execute()

        delay 500, -> sentry = 5

    it 'should timeout if conditions are not satisfied in time', (done) ->

        req = new request.Request
        req.timeout(500)
            .url('#')
            .condition(-> false)
            .on('timeout', -> done())
            .action(-> should.fail 'timeout', 'ready', 'Expected timeout but received ready instead')
            .execute()

    it 'should invoke phantom methods during execution', (done) ->
        phEvents = ['createPage', 'open', 'exit']
        emitted = []

        req = new request.Request
        req.url('#').timeout(1500).action(-> )

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
        req.action(-> ).execute()

    it 'should invoke phantom.exit() after timing out', (done) ->
        phantom.once 'exit', -> done()
        
        req = new request.Request
        req.timeout(500)
        req.condition -> false
        req.action(->)
        req.execute()

    it 'should invoke phantom.exit() after satisfying a condition', (done) ->
        phantom.once 'exit', -> done()
        
        sentry = false
        req = new request.Request
        req.condition -> sentry
        req.action ->
        req.timeout 2000

        delay 500, ->
            sentry = true

        req.execute()

