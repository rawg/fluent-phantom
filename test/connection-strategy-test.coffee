
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'
whenjs = require 'when'

phantom = new mock.Phantom
request = require('../index.coffee').inject(phantom)
strategy = request.ConnectionStrategy

delay = (ms, func) -> setTimeout func, ms

# Note: New and Recycled strategies are implicitly tested elsewhere

describe 'A round robin strategy', ->
    afterEach ->
        phantom.removeAllListeners()

    it 'should invoke a callback with a connection when open() is called', (done) ->
        strat = new strategy.RoundRobin(5)
        strat.open (ph) ->
            ph.should.be.instanceof mock.Phantom
            done()

    it 'should fill itself to the minimum', ->
        strat = new strategy.RoundRobin(4, 2)
        strat.pool[0].should.be.instanceof mock.Phantom
        strat.pool[1].should.be.instanceof mock.Phantom
        should(strat.pool[2]).be.empty

    it 'should fill itself completely when fill() is invoked', ->
        strat = new strategy.RoundRobin(4, 2)
        strat.fill()

        for i in [0...4]
            strat.pool[i].should.be.instanceof mock.Phantom

        strat.pool.should.have.lengthOf 4

    it 'should create new connections as needed', (done) ->
        strat = new strategy.RoundRobin(4, 2)
        
        wait = []
        for i in [0...4]
            wait.push whenjs.promise (resolve) ->
                strat.open (ph) ->
                    ph.should.be.instanceof mock.Phantom
                    resolve()
        
        whenjs.all(wait).then -> done()

    it 'should loop back to zero after using all connections', ->

        bounds =
            requests: 10
            connections: 4

        counters =
            requests: 0
            connections: 0

        strat = new strategy.RoundRobin bounds.connections
        console.log strat
        phantom.on 'create', -> counters.connections++
        
        wait = []
        for i in [0...bounds.requests]
            strat.open (ph) -> counters.requests++
        
        counters.requests.should.be.exactly(bounds.requests)
        counters.connections.should.be.exactly(bounds.connections)

describe.skip 'A random strategy', ->
    afterEach ->
        phantom.removeAllListeners()

    it 'should invoke a callback with a connection when open() is called', (done) ->
        strat = new strategy.Random(5)
        strat.open (ph) ->
            ph.should.be.instanceof mock.Phantom
            done()

