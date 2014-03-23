
assert = require('assert')
should = require('should')
Request = require('../index').inject(require('./mock-phantom'))

delay = (ms, func) -> setTimeout func, ms

describe 'Request Builder', ->
    it 'Should allow .extract().and().handle()', (done) ->
        Request.create()
        .extract -> 
            true
        .and()
        .handle (result) -> 
            should(result).be.true
            done()
        .open '#'

    it 'Should allow .until(timeout)', ->
        req = Request.create()
        .until 500
        .build()

        should(req.timeout).be.equal(500)

    it 'Should allow .when().until(timeout).then().otherwise(errorHandler)', (done) ->
        req = Request.create()
        .when -> false
        .until 500
        .otherwise ->
            should(true).be.true
            done()
        .open '#'

    it 'Should allow .when().and().then()', ->
        func = -> true

        req = Request.create()
        .when func
        .and()
        .then func
        .build()

        should(req.actions[0]).be.equal(func)

    it 'Should allow .when().has(condition).then(callback).otherwise(handler)', ->
        func = -> true
        req = Request.create()
        .when().has(func).then(func).until(1000).otherwise(func)
        .build()

        should(req.actions).have.length(1)
        should(req.errorHandlers).have.length(1)
        should(req.conditions).have.length(1)
        should(req.actions[0]).be.equal(func)
        should(req.errorHandlers[0]).be.equal(func)
        should(req.timeout).be.equal(1000)
        should(req.conditions[0]).be.equal(func)

describe 'Request', ->
    it 'Should wait until an element is available', (done) ->
        sentry = false

        delay 500, -> sentry = true
        
        req = Request.create()
        .when -> sentry == true
        .then ->
            should(sentry).be.true
            done()
        .until 2000
        .open '#'
    
    it 'Should time out if an element does not become available', (done) ->
        sentry = false

        Request.create()
        .when -> false
        .then -> should.fail('Request failed to wait for sentry')
        .until 500
        .then -> sentry = true
        .then -> 
            should(sentry).be.true
            done()
        .open '#'

    it 'Should respond to halt()', (done) ->

        req = Request.create()
        .when -> false
        .forever()
        .otherwise ->
            should(true).be.ok
            done()
        .open '#'

        delay 500, req.halt()

    it 'Should wait indefinitely (or at least 5s) if there is no timeout', (done) ->

        req = Request.create()
        .when -> false
        .then -> should.fail('Element never became available but request began processing')
        .forever()
        .otherwise -> 
            should(true).be.ok
            done()
        .open '#'
        
        delay 3000, req.halt()
