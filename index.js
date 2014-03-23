(function() {
  var binder, now;

  now = function() {
    return (new Date).getTime();
  };

  binder = function(phantom) {
    var Request, RequestBuilder, exports;
    phantom = typeof phantom === 'object' ? phantom : require('phantom');
    RequestBuilder = (function() {
      var state, states, transitions;

      states = {
        'UNTIL': 0,
        'WHEN': 1,
        'EXEC': 2,
        'EXTRACT': 3,
        'BEGIN': 4,
        'HANDLER': 5
      };

      states.keyOf = function(key) {
        var k, v, _results;
        _results = [];
        for (k in states) {
          v = states[k];
          if (k === key) {
            _results.push(v);
          }
        }
        return _results;
      };

      state = states.BEGIN;

      transitions = {};

      transitions[states.BEGIN] = [states.UNTIL, states.WHEN, states.EXEC, states.EXTRACT];

      transitions[states.UNTIL] = [states.WHEN, states.EXEC, states.EXTRACT];

      transitions[states.WHEN] = [states.UNTIL, states.EXEC, states.EXTRACT];

      transitions[states.EXEC] = [states.UNTIL, states.WHEN, states.EXTRACT];

      transitions[states.EXTRACT] = [states.HANDLER];

      transitions[states.HANDLER] = [states.EXEC, states.EXTRACT, states.UNTIL, states.WHEN];

      function RequestBuilder() {
        this.conditions = [];
        this.successes = [];
        this.failures = [];
        this.timeout = 2000;
        this.extractor = null;
      }

      RequestBuilder.prototype.transitionTo = function(newState) {
        if (transitions[state].indexOf(newState >= 0)) {
          return state = newState;
        } else {
          throw Error("Invalid state transition: " + states.keyOf(state) + " => " + states.keyOf(newState));
        }
      };

      RequestBuilder.prototype.append = function(callback) {
        var extract, handler;
        if (typeof callback !== 'function') {
          throw Error("Invalid callback");
        }
        switch (state) {
          case states.WHEN:
            this.conditions.push(callback);
            break;
          case states.UNTIL:
            this.failures.push(callback);
            break;
          case states.EXEC:
            this.successes.push(callback);
            break;
          case states.EXTRACT:
            this.extractor = callback;
            break;
          case states.HANDLER:
            extract = this.extractor;
            handler = callback;
            this.successes.push(function(ph, page) {
              return page.evaluate(extract, handler);
            });
            this.extractor = null;
            this.transitionTo(states.EXEC);
        }
        return this;
      };

      RequestBuilder.prototype.when = function(callback) {
        this.transitionTo(states.WHEN);
        if (typeof callback === 'function') {
          return this.append(callback);
        } else {
          return this;
        }
      };

      RequestBuilder.prototype.execute = function(callback) {
        this.transitionTo(states.EXEC);
        return this.append(callback);
      };

      RequestBuilder.prototype.evaluate = function(extractor, handler) {
        this.transitionTo(states.EXEC);
        return this.append(function(ph, page) {
          return page.evaluate(extractor, handler);
        });
      };

      RequestBuilder.prototype.extract = function(callback) {
        this.transitionTo(states.EXTRACT);
        return this.append(callback);
      };

      RequestBuilder.prototype.handle = function(callback) {
        this.transitionTo(states.HANDLER);
        return this.append(callback);
      };

      RequestBuilder.prototype.then = function(callback) {
        if (typeof callback === 'function') {
          if (state === states.WHEN) {
            this.transitionTo(states.EXEC);
          }
          return this.append(callback);
        } else {
          return this;
        }
      };

      RequestBuilder.prototype.until = function(callbackOrTimeout) {
        this.transitionTo(states.UNTIL);
        if (typeof callbackOrTimeout === 'number') {
          this.timeout = callbackOrTimeout;
        } else if (typeof callbackOrTimeout === 'function') {
          this.append(callbackOrTimeout);
        }
        return this;
      };

      RequestBuilder.prototype.orElse = function(callback) {
        return this.until(callback);
      };

      RequestBuilder.prototype.otherwise = function(callback) {
        return this.until(callback);
      };

      RequestBuilder.prototype.waitFor = function(callback) {
        return this.when(callback);
      };

      RequestBuilder.prototype.has = function(callback) {
        return this.when(callback);
      };

      RequestBuilder.prototype.process = function(callback) {
        return this.handle(callback);
      };

      RequestBuilder.prototype.forever = function() {
        return this.until(0);
      };

      RequestBuilder.prototype.and = function(callback) {
        if (typeof callback === 'function') {
          this.append(callback);
        }
        return this;
      };

      RequestBuilder.prototype.page = function() {
        return this;
      };

      RequestBuilder.prototype.build = function(url) {
        var req;
        req = new Request(url);
        req.conditions = this.conditions;
        req.actions = this.successes;
        if (this.failures.length > 0) {
          req.errorHandlers = this.failures;
        } else {
          req.errorHandlers.push(function() {
            return console.error("Request timed out");
          });
        }
        req.timeout = this.timeout;
        return req;
      };

      RequestBuilder.prototype.open = function(url) {
        var req;
        req = this.build(url);
        req.begin();
        return req;
      };

      return RequestBuilder;

    })();
    Request = (function() {
      var callAllAndQuit, errors;

      errors = {
        TIMEOUT: 'timeout',
        HALT: 'halt',
        RESPONSE: 'response'
      };

      callAllAndQuit = function(interval, functions, ph, page, args) {
        var func, funcs, _i, _len, _results;
        clearInterval(interval);
        funcs = functions.slice(0);
        funcs.push(function() {
          return ph.exit();
        });
        _results = [];
        for (_i = 0, _len = functions.length; _i < _len; _i++) {
          func = functions[_i];
          _results.push(func.call(this, ph, page));
        }
        return _results;
      };

      function Request(url) {
        this.url = url;
        this.conditions = [];
        this.actions = [];
        this.errorHandlers = [];
        this.timeout = 3000;
        this.interval;
      }

      Request.prototype.doSuccess = function(ph, page) {
        return callAllAndQuit(this.interval, this.actions, ph, page);
      };

      Request.prototype.doFailure = function(reason, ph, page) {
        return callAllAndQuit(this.interval, this.errorHandlers, ph, page, reason);
      };

      Request.prototype.halt = function() {
        clearInterval(this.interval);
        return this.doFailure();
      };

      Request.prototype.begin = function() {
        return phantom.create((function(_this) {
          return function(ph) {
            return ph.createPage(function(page) {
              return page.open(_this.url, function(status) {
                var start, tick;
                if (status !== 'success') {
                  return _this.doFailure(ph, page);
                } else if (_this.conditions.length) {
                  start = now();
                  tick = function() {
                    var check, isReady, tests;
                    if (_this.timeout > 0 && now() - start > _this.timeout) {
                      return _this.doFailure(ph, page);
                    } else {
                      isReady = true;
                      tests = _this.conditions.slice(0);
                      check = function(condition) {
                        return page.evaluate(condition, function(result) {
                          isReady = isReady & result;
                          if (isReady) {
                            if (tests.length) {
                              return check(tests.pop());
                            } else {
                              return _this.doSuccess(ph, page);
                            }
                          }
                        });
                      };
                      return check(tests.pop());
                    }
                  };
                  return _this.interval = setInterval(tick, 250);
                } else {
                  return _this.doSuccess(ph, page);
                }
              });
            });
          };
        })(this));
      };

      return Request;

    })();
    return exports = {
      "RequestBuilder": RequestBuilder,
      "Request": Request,
      "create": function() {
        return new RequestBuilder;
      }
    };
  };

  module.exports = binder();

  module.exports.inject = binder;

}).call(this);

//# sourceMappingURL=index.js.map
