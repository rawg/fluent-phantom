(function() {
  var Request, assert, delay, should;

  assert = require('assert');

  should = require('should');

  Request = require('../index').inject(require('./mock-phantom'));

  delay = function(ms, func) {
    return setTimeout(func, ms);
  };

  describe('Request Builder', function() {
    it('Should allow .extract().and().handle()', function(done) {
      return Request.create().extract(function() {
        return true;
      }).and().handle(function(result) {
        should(result).be["true"];
        return done();
      }).open('#');
    });
    it('Should allow .until(timeout)', function() {
      var req;
      req = Request.create().until(500).build();
      return should(req.timeout).be.equal(500);
    });
    it('Should allow .when().until(timeout).then().otherwise(errorHandler)', function(done) {
      var req;
      return req = Request.create().when(function() {
        return false;
      }).until(500).otherwise(function() {
        should(true).be["true"];
        return done();
      }).open('#');
    });
    it('Should allow .when().and().then()', function() {
      var func, req;
      func = function() {
        return true;
      };
      req = Request.create().when(func).and().then(func).build();
      return should(req.actions[0]).be.equal(func);
    });
    return it('Should allow .when().has(condition).then(callback).otherwise(handler)', function() {
      var func, req;
      func = function() {
        return true;
      };
      req = Request.create().when().has(func).then(func).until(1000).otherwise(func).build();
      should(req.actions).have.length(1);
      should(req.errorHandlers).have.length(1);
      should(req.conditions).have.length(1);
      should(req.actions[0]).be.equal(func);
      should(req.errorHandlers[0]).be.equal(func);
      should(req.timeout).be.equal(1000);
      return should(req.conditions[0]).be.equal(func);
    });
  });

  describe('Request', function() {
    it('Should wait until an element is available', function(done) {
      var req, sentry;
      sentry = false;
      delay(500, function() {
        return sentry = true;
      });
      return req = Request.create().when(function() {
        return sentry === true;
      }).then(function() {
        should(sentry).be["true"];
        return done();
      }).until(2000).open('#');
    });
    it('Should time out if an element does not become available', function(done) {
      var sentry;
      sentry = false;
      return Request.create().when(function() {
        return false;
      }).then(function() {
        return should.fail('Request failed to wait for sentry');
      }).until(500).then(function() {
        return sentry = true;
      }).then(function() {
        should(sentry).be["true"];
        return done();
      }).open('#');
    });
    it('Should respond to halt()', function(done) {
      var req;
      req = Request.create().when(function() {
        return false;
      }).forever().otherwise(function() {
        should(true).be.ok;
        return done();
      }).open('#');
      return delay(500, req.halt());
    });
    return it('Should wait indefinitely (or at least 5s) if there is no timeout', function(done) {
      var req;
      req = Request.create().when(function() {
        return false;
      }).then(function() {
        return should.fail('Element never became available but request began processing');
      }).forever().otherwise(function() {
        should(true).be.ok;
        return done();
      }).open('#');
      return delay(3000, req.halt());
    });
  });

}).call(this);
