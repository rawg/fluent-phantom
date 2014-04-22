###
###

Emitter = require('events').EventEmitter


class MockPhantom
    create: (options, callback) ->
        @emit 'create'
        if typeof options is 'function' and not callback?
            callback = options
        callback @

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

    set: ->
        # pass

MockPage.prototype.__proto__ = Emitter.prototype
MockPhantom.prototype.__proto__ = Emitter.prototype

module.exports = 
    create: (options, callback) -> 
        if typeof options is 'function' and not callback?
            callback = options
        callback(new MockPhantom)

    Phantom: MockPhantom
    Page: MockPage

