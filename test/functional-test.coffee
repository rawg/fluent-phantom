
assert = require 'assert'
should = require 'should'
request = require('../lib/fluent-phantom')

handler = (done) ->
    (results) ->
        results.length.should.be.above 5
        results[0].innerText.should.equal 'Headline 1'
        done()

fail = (done) ->
    -> 
        should.fail 'Timed out'
        done()

describe 'A live request', ->
    it 'should wait for and scrape elements by selectors', (done) ->

        req = request.create()
            .extract('#headlines li')
            .from('http://localhost:3030/index.html')
            .and().then(handler(done))
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()

    it 'should extract results using functions', (done) ->
        req = request.create()
            .when(-> document.querySelectorAll('#headlines li').length > 5)
            .extract(-> document.querySelectorAll('#headlines li'))
            .from('http://localhost:3030/index.html')
            .and().then(handler(done))
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()

    it 'should extract results using page.evaluate', (done) ->
        req = request.create()
            .when().page()
            .url('http://localhost:3030/index.html')
            .has(-> document.querySelectorAll('#headlines li').length > 5)
            .execute((page) ->
                extractor = -> document.querySelectorAll('#headlines li')
                
                page.evaluate extractor, handler(done)
            ).until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()
            


