
assert = require 'assert'
should = require 'should'
mock = require './mock-phantom'
request = require('../lib/fluent-phantom').inject(new mock.Phantom)

delay = (ms, func) -> setTimeout func, ms

verify = (builder) ->
    req = builder.build
    match = true
    match = match & req.listeners('ready') == @builder.properties.actions
    match = match & req.listeners('timeout') == @builder.properties.
    match = match & req._conditions == @conditions
    match &= req._timeout == @builder.properties.timeout
    match

describe 'A request builder', ->
    it 'should set the 
    it 'should interpret extract(callback).and.do(callback)', ->
        builder = request.create()
            .extract(-> false).and().then(-> true).when('more stuff')
        #    .extract(-> 
    it.skip 'should interpret when(callback).then.do.(callback)'
