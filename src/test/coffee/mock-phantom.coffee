###
#phantom.create (ph) =>
                ph.createPage (page) =>
                    page.open @url, (status) =>
###


class MockPhantom
    createPage: (callback) ->
        if typeof callback != 'function' then throw Error "Invalid callback"
        callback(new MockPage)

    exit: () ->
        # pass

class MockPage
    open: (url, callback) ->
        if typeof callback != 'function' then throw Error "Invalid callback"
        callback('success')

    evaluate: (extract, handle) ->
        if typeof extract != 'function' then throw Error "Invalid extractor callback " + extract
        if typeof handle != 'function' then throw Error "Invalid handler callback" + handle
        handle(extract())

module.exports = 
    create: (callback) -> callback(new MockPhantom)
