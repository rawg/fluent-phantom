###
#phantom.create (ph) =>
                ph.createPage (page) =>
                    page.open @url, (status) =>
###

Emitter = require('events').EventEmitter


class MockPhantom
    create: (callback) ->
        callback this

    createPage: (callback) ->
        if typeof callback != 'function' then throw Error "Invalid callback"
        @emit 'createPage'
        page = new MockPage
        page.on 'open', (url) => 
            @emit 'open', url
        page.on 'evaluate', => 
            @emit 'evaluate'
        callback page

    exit: ->
        @emit 'exit'

class MockPage
    open: (url, callback) ->
        if typeof callback != 'function' then throw Error "Invalid callback"
        @emit 'open', url
        callback 'success'

    evaluate: (extract, handle, argument) ->
        if typeof extract != 'function' then throw Error "Invalid extractor callback " + extract
        if typeof handle != 'function' then throw Error "Invalid handler callback" + handle
        @emit 'evaluate'
        handle extract(argument)


MockPage.prototype.__proto__ = Emitter.prototype
MockPhantom.prototype.__proto__ = Emitter.prototype

module.exports = 
    create: (callback) -> callback(new MockPhantom)
    Phantom: MockPhantom
    Page: MockPage

