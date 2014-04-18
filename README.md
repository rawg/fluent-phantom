# Fluent Phantom 
A fluent interface for scraping web content in Node with the PhantomJS headless browser.  Its most notable feature is that, similar to waitFor.js, you can wait until the availability of content on a page, which comes in handy when scraping content generated by AJAX requests.

## Installation
Install via npm with:
```
npm install fluent-phantom
```

Note that this package depends on the [PhantomJS bridge for Node](https://github.com/sgentle/phantomjs-node), which assumes that you have already installed [PhantomJS](http://phantomjs.org/).


## Builder

### select(selector: string)
Retrieves elements that match a CSS selector using `querySelectorAll()`. Automatically waits for content to be ready using `when()`. Optionally restricts element properties to those specified in `properties()`.

### select(selector: function, [argument: any])


### when(selector: string, [count: number])

### when(condition: function, [argument: any])

### properties(properties: array) or properties(property, [property2], [...])
synonyms: `members()`


### from(url: string)
synonyms: `url()`

### evaluate(scraper: function, handler: function. [argument: any])

### for(milliseconds: number)
synonyms: `until()`, `timeout()`

### forever()

### immediately()

### otherwise(handler: function)



