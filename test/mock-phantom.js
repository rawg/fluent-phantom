
/*
 *phantom.create (ph) =>
                ph.createPage (page) =>
                    page.open @url, (status) =>
 */

(function() {
  var MockPage, MockPhantom;

  MockPhantom = (function() {
    function MockPhantom() {}

    MockPhantom.prototype.createPage = function(callback) {
      if (typeof callback !== 'function') {
        throw Error("Invalid callback");
      }
      return callback(new MockPage);
    };

    MockPhantom.prototype.exit = function() {};

    return MockPhantom;

  })();

  MockPage = (function() {
    function MockPage() {}

    MockPage.prototype.open = function(url, callback) {
      if (typeof callback !== 'function') {
        throw Error("Invalid callback");
      }
      return callback('success');
    };

    MockPage.prototype.evaluate = function(extract, handle) {
      if (typeof extract !== 'function') {
        throw Error("Invalid extractor callback " + extract);
      }
      if (typeof handle !== 'function') {
        throw Error("Invalid handler callback" + handle);
      }
      return handle(extract());
    };

    return MockPage;

  })();

  module.exports = {
    create: function(callback) {
      return callback(new MockPhantom);
    }
  };

}).call(this);
