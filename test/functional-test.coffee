
assert = require 'assert'
should = require 'should'
request = require('../lib/fluent-phantom')

describe 'A live request', ->
    it 'should scrape elements by selectors', (done) ->
        handler = (results) ->
            console.log 'results', results
            done()

        fail = ->
            should.fail 'Timed out'
            done()

        req = request.create()
            .extract('#headlines li')
            .from('http://localhost:3030/index.html')
            .and().then(handler)
            .until(10000)
            .otherwise(fail)
            .build()

        events =
            HALT: 'halted'
            PHANTOM_CREATE: 'phantom-created'
            PAGE_CREATE: 'page-created'
            PAGE_OPEN: 'page-opened'
            TIMEOUT: 'timeout'
            REQUEST_FAILURE: 'failed'
            READY: 'ready'
            FINISH: 'finished'
            CHECKING: 'checking'

        for key, event of events
            do (event) ->
                #req.on event, -> console.log event

        req.execute()



