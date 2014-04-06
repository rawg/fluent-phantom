
assert = require 'assert'
should = require 'should'
request = require('../lib/fluent-phantom')

handler = (done) ->
    (results) ->
        console.log 'finito'
        results.length.should.be.above 5
        results[0].innerText.should.equal 'Headline 1'
        done()

fail = (done) ->
    ->
        should.fail 'Timed out'
        done()

uri = 'http://localhost:3030/index.html'

describe 'A live request', ->
    it 'should extract results using functions', (done) ->
        req = request.create()
            .when(-> document.querySelectorAll('#headlines li').length > 5)
            .extract(-> document.querySelectorAll('#headlines li'))
            .from(uri)
            .and().then(handler(done))
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()


    it 'should extract results using page.evaluate', (done) ->
        req = request.create()
            .url(uri)
            .when(-> document.querySelectorAll('#headlines li').length > 5)
            .evaluate((page) ->
                extractor = -> document.querySelectorAll('#headlines li')
                handle = (results) ->
                    results.length.should.be.above 5
                    done()
                page.evaluate extractor, handle
            ).until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()
    

    it 'should wait for and scrape elements by selectors', (done) ->
        req = request.create()
            .extract('#headlines li')
            .from(uri)
            .and().then(handler(done))
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()


    it 'should extract a subset of properties', (done) ->
        req = request.create()
            .extract('#nested')
            .from(uri)
            .and().then(handler(done))
            .with('id', 'children', 'innerHTML', 'innerText')
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()


    

