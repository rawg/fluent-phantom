
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'
request = require('../index.coffee').inject(new mock.Phantom)

delay = (ms, func) -> setTimeout func, ms


describe 'A request builder', ->
    it 'should set timeouts using timeout()', ->
        req = request.create().timeout(500).build()
        req._timeout.should.equal(500)

    it 'should set timeouts using until()', ->
        req = request.create().until(500).build()
        req._timeout.should.equal(500)

    it 'should set indefinite timeouts using forever()', ->
        req = request.create().forever().build()
        req._timeout.should.equal(0)

    it 'should set urls using url()', ->
        req = request.create().url('#').build()
        req._url.should.equal('#')

    it 'should set urls using from()', ->
        req = request.create().from('#').build()
        req._url.should.equal('#')


