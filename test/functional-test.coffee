
# Functional tests against a local web server (see test/resources/*)


{sleep, usleep} = require 'sleep'
assert = require 'assert'
should = require 'should'
request = require '../index.coffee'


# First, we define several helpers
# Simple content extractor 
extractor = (query) ->
    results = document.querySelectorAll query
    for index, result of results when result.id?
        innerText: result.innerText
        children: result.children
        id: result.id
        tagName: result.tagName
        innerHTML: result.innerHTML
        attributes: result.attributes

# Verify a list of headlines and exit
handler = (done) ->
    (results) ->
        results.length.should.be.above 5  # Actually 10...
        for index, result of results
            result.innerText.should.equal 'Headline ' + (parseInt(index) + 1)
        done()

# Error handler to force test failure
fail = (done) ->
    ->
        should.fail 'Timed out'
        done()

uri = 'http://localhost:3050/index.html'

describe 'A live request', ->
    before ->
        # Give the Express test harness a second to start up
        sleep 1
        
        # Recycle a phantom object to avoid wastefulness but, more importantly,
        # prevent the port binding / EADDRINUSE error.
        request.recycle true

    afterEach ->
        sleep 1

    it 'should scrape content using a bare function', (done) ->
        request.create()
            .url(uri)
            .run((page) -> page.evaluate extractor, handler(done), '#static li')
            .until(1000)
            .otherwise(fail(done))
            .execute()

    it 'should scrape using evaluate', (done) ->
        request.create()
            .from(uri)
            .evaluate(extractor, handler(done), '#static li')
            .timeout(1000)
            .otherwise(fail(done))
            .execute()

    it 'should scrape using separate functions', (done) ->
        request.create()
            .from(uri)
            .select(extractor, '#static li')
            .and().then().process(handler(done))
            .timeout(1000)
            .otherwise(fail(done))
            .execute()
    
    it 'should scrape using CSS selectors', (done) ->
        request.create()
            .from(uri)
            .select('#static li')
            .and().then().process(handler(done))
            .timeout(1000)
            .otherwise(fail(done))
            .execute()

    it 'should automatically wait when scraping with CSS selectors', (done) ->
        request.create()
            .from(uri)
            .select('#headlines li')  # headlines arrive after a short delay
            .and().then().process(handler(done))
            .timeout(5000)
            .otherwise(fail(done))
            .execute()

    it 'should filter node properties when scraping with CSS selectors', (done) ->
        verify = (results) ->
            for node in results
                should.exist node.innerText
                should.exist node.id
                should.exist node.nodeName
                should.not.exist node.innerHTML
                should.not.exist node.children
                should.not.exist node.attributes

            handler(done)(results)

        request.create()
            .from(uri)
            .select('#headlines li')  # headlines arrive after a short delay
            .and().then().process(verify)
            .with().properties('innerText', 'id', 'nodeName')
            .timeout(5000)
            .otherwise(fail(done))
            .execute()
    
    it 'should filter properties of child nodes when scraping with CSS selectors', (done) ->
        verify = (results) ->
            for result in results
                for node in result.children
                    should.exist node.innerText
                    should.exist node.id
                    should.exist node.nodeName
                    should.not.exist node.innerHTML
                    should.not.exist node.attributes

            done()

        request.create()
            .from(uri)
            .select('#nested div')  # nested divs have h3 and ul children
            .and().then().process(verify)
            .with().properties('innerText', 'id', 'nodeName', 'children')
            .timeout(5000)
            .otherwise(fail(done))
            .execute()

    it 'should wait on a function to return true', (done) ->
        request.create()
            .from(uri)
            .when(-> document.querySelectorAll('#headlines li').length >= 5)
            .select(extractor, '#headlines li')
            .and().then().process(handler(done))
            .timeout(5000)
            .otherwise(fail(done))
            .execute()

    it 'should wait on a CSS selector to be satisfied', (done) ->
        request.create()
            .from(uri)
            .when('#headlines li', 7)
            .select(extractor, '#headlines li')
            .and().then().process(handler(done))
            .timeout(5000)
            .otherwise(fail(done))
            .execute()

