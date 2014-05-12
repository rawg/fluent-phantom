
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'
whenjs = require 'when'

phantom = new mock.Phantom
request = require('../index.coffee').inject(phantom)
strategy = request.ConnectionStrategy

delay = (ms, func) -> setTimeout func, ms

# Note: New and Recycled strategies are implicitly tested elsewhere

describe 'A round robin phantom pooling strategy', ->
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

    it 'should loop back to zero', ->

        bounds =
            requests: 10
            connections: 4

        counters =
            requests: 0
            connections: 0

        strat = new strategy.RoundRobin bounds.connections
        phantom.on 'create', -> counters.connections++
        
        wait = []
        for i in [0...bounds.requests]
            strat.open (ph, done) -> 
                counters.requests++
                done()
        
        counters.requests.should.be.exactly(bounds.requests)
        counters.connections.should.be.exactly(bounds.connections)

    it 'should use unique ports', ->
        ports = {}
        size = 30
        strat = new strategy.RoundRobin size
        phantom.on 'create', (options) ->
            if not options.port?
                should.fail "Expected port not provided"

            if ports[options.port]?
                should.fail "Reused port #{options.port}"
            
            ports[options.port] = true

        for i in [0...size]
            strat.open (ph) ->


describe 'A random phantom pooling strategy', ->
    afterEach ->
        # no listeners were harmed in the making of this suite...
        #phantom.removeAllListeners()

    it 'should invoke a callback with a connection when open() is called', (done) ->
        strat = new strategy.Random(5)
        strat.open (ph) ->
            ph.should.be.instanceof mock.Phantom
            done()

    it 'should create requests as needed and not in advance', ->
        bounds =
            size: 10
            create: 4
        found =
            initialized: 0
            created: 0

        strat = new strategy.Random bounds.size

        for i in [0...bounds.create]
            strat.open (ph, done) -> 
                found.created++
                done()

        for i, conn of strat.pool
            if typeof conn is 'object' then found.initialized++

        found.initialized.should.be.within 1, bounds.create
        found.created.should.be.exactly bounds.create
    
    it 'should fill completely when fill() is invoked', ->
        size = 20
        strat = new strategy.Random 20

        countConns = (pool) ->
            # Wish there was a native reduce() here
            count = 0
            count++ for i in [0...size] when typeof pool[i] is 'object'
            count

        countConns(strat.pool).should.be.exactly 0
        strat.fill()
        countConns(strat.pool).should.be.exactly size


    it 'should use unique ports', ->
        ports = {}
        size = 30
        strat = new strategy.Random size

        phantom.on 'create', (options) ->
            if not options.port?
                should.fail "Expected port not provided"

            if ports[options.port]?
                should.fail "Reused port #{options.port}"
            
            ports[options.port] = true

        for i in [0...size]
            strat.open (ph) ->

