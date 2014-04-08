
{sleep, usleep} = require 'sleep'
assert = require 'assert'
should = require 'should'
request = require('../lib/fluent-phantom')

handler = (done) ->
    (results) ->
        results.length.should.be.above 5  # Actually 10...
        results[0].innerText.should.equal 'Headline 1'
        done()

fail = (done) ->
    ->
        should.fail 'Timed out'
        done()

uri = 'http://localhost:3050/index.html'

describe 'A live request', ->
    before ->
        sleep 1

    afterEach ->
        # This crappy 1s delay prevents an EADDRINUSE error that's bubbling up
        # from grunt-express or PhantomJS.
        sleep 1

    # This test works... sometimes. WTH?
    it.skip 'should extract results using functions', (done) ->
        req = request.create()
            .when(-> 
                document.querySelectorAll('#headlines li').length >= 5
            )
            .extract(-> 
                elems = document.querySelectorAll('#headlines li')
                return elems
            )
            .from(uri)
            .and().then(handler(done))
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()


    # Another test that passes... sometimes.
    it.skip 'should extract results using page.evaluate', (done) ->
        req = request.create()
            .url(uri)
            .when(-> 
                document.querySelectorAll('#headlines li').length >= 5
            )
            .evaluate((page) ->
                extractor = ->
                    document.querySelectorAll('#headlines li')

                handle = (results) ->
                    results.length.should.be.above 5
                    done()

                page.evaluate extractor, handle
            
            ).until(5000)
            .otherwise(fail(done))
            .build()
        
        req.execute()
    

    it 'should wait for and scrape elements by selectors', (done) ->
        req = request.create()
            .extract('#headlines li')
            .from(uri)
            .and().then(handler(done))
            .until(5000)
            .otherwise(fail(done))
            .build()

        req.execute()


    it 'should extract a subset of properties', (done) ->
        req = request.create()
            .extract('#headlines li')
            .from(uri)
            .and().then((results) ->
                results[0].should.have.property 'id'
                results[1].should.have.property 'innerHTML'
                results[2].should.have.property 'innerText'
                done()
            )
            .with('id', 'children', 'innerHTML', 'innerText')
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()


    it 'should allow select().properties(x, y, z).of(selector)...', (done) ->
        req = request.create()
            .select()
            .properties('id', 'children', 'innerHTML', 'innerText')
            .of('#headlines li')
            .from(uri)
            .and().then((results) ->
                results[0].should.have.property 'id'
                results[1].should.have.property 'innerHTML'
                results[2].should.have.property 'innerText'
                done()
            )
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()

    it 'should filter children as well as the parent when using select().properties()', (done) ->
        req = request.create()
            .select()
            .properties('id', 'children', 'innerHTML')
            .of('#nested div')
            .from(uri)
            .and().then((results) ->
                # Test a sample of properties of top level elements
                results[0].should.have.property 'id'
                results[1].should.have.property 'innerHTML'
                results[2].should.have.property 'children'
                results[0].should.not.have.property 'innerText'

                for result in results
                    for child in result.children
                        child.should.have.property 'id'
                        child.should.have.property 'innerHTML'
                        child.should.not.have.property 'innerText'

                done()
            )
            .until(10000)
            .otherwise(fail(done))
            .build()

        req.execute()

