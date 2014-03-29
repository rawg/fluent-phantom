
assert = require('assert')
should = require('should')
Request = require('./lib/scraping-dsl').inject(require('./mock-phantom'))

delay = (ms, func) -> setTimeout func, ms


describe 'A request', ->
    it 'should have a settable URL', ->
        req = new Request
        req.url('#')
        should(req.url()).be.equal('#')

    it 'should have a settable timeout', ->
        req = new Request
        req.timeout(500)
        should(req.timeout()).be.equal(500)

    it 'should have have a fluent interface', ->
        req = new Request
        should(req.timeout(500)).be.equal(req)
        should(req.url('#')).be.equal(req)
        should(req.condition(() ->)).be.equal(req)

    it.skip 'should emit phantom events during execution'
    it.skip 'should invoke phantom.exit() when finished'


describe.skip 'Request builder', ->
    it 'should allow .extract().and().handle()', (done) ->
        Request.create()
        .extract -> 
            true
        .and()
        .handle (result) -> 
            should(result).be.true
            done()
        .open '#'

    it 'should allow .until(timeout)', ->
        req = Request.create()
        .until 500
        .build()

        should(req.timeout).be.equal(500)

    it 'should allow .when().until(timeout).then().otherwise(errorHandler)', (done) ->
        req = Request.create()
        .when -> false
        .until 500
        .otherwise ->
            should(true).be.true
            done()
        .open '#'

    it 'should allow .when().and().then()', ->
        func = -> true

        req = Request.create()
        .when func
        .and()
        .then func
        .build()

        should(req.listeners('ready')[0]).be.equal(func)

    it 'should allow .when().has(condition).then(callback).otherwise(handler)', ->
        func = -> true
        req = Request.create()
        .when().has(func).then(func).until(1000).otherwise(func)
        .build()

        should(req.listeners('ready')).have.length(1)
        should(req.listeners('timeout')).have.length(1)
        should(req.conditions).have.length(1)
        
        should(req.listeners('ready')[0]).be.equal(func)
        should(req.listeners('timeout')[0]).be.equal(func)
        should(req.timeout).be.equal(1000)
        
        should(req.conditions[0]).be.equal(func)

describe.skip 'Request', ->
    it 'should wait until an element is available', (done) ->
        sentry = false
       
        req = new Request.Request
        req.addCondition( -> sentry == true)
        req.on 'ready', ->
            should(sentry).be.true
            done()
        req.timeout = 2000
        req.open '#'
        
        delay 500, -> sentry = true
    
    it 'should time out if an element does not become available', (done) ->
        sentry = false

        req = Request.create()
        .when -> false
        .then -> should.fail('Request failed to wait for sentry')
        .until 500
        .then -> sentry = true
        .then -> 
            should(sentry).be.true
            done()
        .build()

        req.on('ready', -> console.log('> ready'))
        req.url = '#'
        req.begin()

    it 'should respond to halt()', (done) ->

        req = Request.create()
        .when -> false
        .forever()
        .otherwise ->
            should(true).be.ok
            done()
        .open '#'

        delay 500, req.halt()

    it 'should wait indefinitely (or at least 5s) if there is no timeout', (done) ->

        req = Request.create()
        .when -> false
        .then -> should.fail('Element never became available but request began processing')
        .forever()
        .otherwise -> 
            should(true).be.ok
            done()
        .open '#'
        
        delay 3000, req.halt()

    it.skip 'Should automativally invoke ph.exit() when finished', (done) ->


        req = Request.create()

