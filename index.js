(function() {
  var Emitter, binder, now,
    __slice = [].slice;

  Emitter = require('events').EventEmitter;

  now = function() {
    return (new Date).getTime();
  };

  binder = function(phantom) {
    var Builder, Request, builders, events, exports, nodeProperties, shared;
    phantom = typeof phantom === 'object' ? phantom : require('phantom');
    shared = {
      phantom: null,
      recycle: false
    };
    events = {
      HALT: 'halted',
      PHANTOM_CREATE: 'phantom-created',
      PAGE_CREATE: 'page-created',
      PAGE_OPEN: 'page-opened',
      TIMEOUT: 'timeout',
      REQUEST_FAILURE: 'failed',
      READY: 'ready',
      FINISH: 'finished',
      CHECKING: 'checking',
      CONSOLE: 'console'
    };
    builders = {
      when: {
        css: 'when-css',
        "function": 'when-func',
        none: 'when-none'
      },
      action: {
        css: 'action-css',
        parts: 'action-parts',
        evaluate: 'action-evaluate',
        "function": 'action-function'
      }
    };
    nodeProperties = ['attributes', 'baseURI', 'childElementCount', 'childNodes', 'classList', 'className', 'dataset', 'dir', 'hidden', 'id', 'innerHTML', 'innerText', 'lang', 'localName', 'namespaceURI', 'nodeName', 'nodeType', 'nodeValue', 'outerHTML', 'outerText', 'prefix', 'style', 'tabIndex', 'tagName', 'textContent', 'title', 'type', 'value', 'children', 'href', 'src'];
    Builder = (function() {
      function Builder() {
        this._build = {
          when: builders.when.none,
          action: builders.action["function"]
        };
        this._props = {
          condition: {
            callback: null,
            argument: null
          },
          action: function() {
            return console.log("No default action provided");
          },
          scraper: {
            extractor: null,
            handler: null,
            argument: null,
            properties: ['children', 'tagName', 'innerText', 'innerHTML', 'id', 'attributes', 'href', 'src', 'className'],
            query: null
          },
          timeout: {
            duration: 3000,
            handler: function() {
              return console.error("Timeout");
            }
          },
          url: null
        };
      }

      Builder.prototype.until = function(timeout) {
        return this["for"](timeout);
      };

      Builder.prototype.timeout = function(timeout) {
        return this["for"](timeout);
      };

      Builder.prototype["for"] = function(timeout) {
        if (typeof timeout !== 'number') {
          throw Error("Expected timeout to be a number");
        }
        this._props.timeout.duration = timeout;
        return this;
      };

      Builder.prototype.forever = function() {
        return this["for"](0);
      };

      Builder.prototype.immediately = function() {
        return this["for"](100);
      };

      Builder.prototype.otherwise = function(callback) {
        if (typeof callback !== 'function') {
          throw Error("Expected timeout handler to be a function");
        }
        this._props.timeout.handler = callback;
        return this;
      };

      Builder.prototype.url = function(url) {
        return this.from(url);
      };

      Builder.prototype.from = function(url) {
        if (typeof url !== 'string') {
          throw Error("Expected URL to be a string");
        }
        this._props.url = url;
        return this;
      };

      Builder.prototype.evaluate = function(scraper, handler, argument) {
        if (typeof scraper !== 'function') {
          throw Error("Expected scraping function");
        }
        if (typeof handler !== 'function') {
          throw Error("Expected handler function");
        }
        this._build.action = builders.action.evaluate;
        this._props.action = function(page) {
          return page.evaluate(scraper, handler, argument);
        };
        return this;
      };

      Builder.prototype.invoke = function(callback) {
        return this.run(callback);
      };

      Builder.prototype.run = function(callback) {
        if (typeof callback !== 'function') {
          throw Error("Expected action to be a function");
        }
        this._build.action = builders.action["function"];
        this._props.action = callback;
        return this;
      };

      Builder.prototype.when = function(condition, argument) {
        var minimum;
        if (typeof condition === 'string') {
          this._build.when = builders.when.css;
          minimum = typeof argument === 'number' ? argument : 1;
          this._props.condition = {
            callback: function(args) {
              return document.querySelectorAll(args.query).length >= args.minimum;
            },
            argument: {
              minimum: minimum,
              query: condition
            }
          };
        } else if (typeof condition === 'function') {
          this._build.when = builders.when["function"];
          this._props.condition = {
            callback: condition
          };
          if (typeof argument !== 'undefined') {
            this._props.condition.argument = argument;
          }
        } else {
          throw Error("Invalid condition");
        }
        return this;
      };

      Builder.prototype.extract = function(selector, argument) {
        return this.select(selector, argument);
      };

      Builder.prototype.select = function(selector, argument) {
        if (typeof selector === 'string') {
          this._build.action = builders.action.css;
          this._props.scraper.query = selector;
          this.when(selector, argument);
        } else if (typeof selector === 'function') {
          this._build.action = builders.action.parts;
          this._props.scraper.extractor = selector;
        } else {
          throw Error("Invalid selector");
        }
        if (typeof argument !== 'undefined') {
          this._props.scraper.argument = argument;
        }
        return this;
      };

      Builder.prototype.process = function(handler) {
        return this.handle(handler);
      };

      Builder.prototype.receive = function(handler) {
        return this.handle(handler);
      };

      Builder.prototype.handle = function(handler) {
        this._props.scraper.handler = handler;
        return this;
      };

      Builder.prototype.properties = function() {
        var props;
        props = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this.members(props);
      };

      Builder.prototype.members = function() {
        var properties, traverse;
        properties = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this._props.scraper.properties = [];
        traverse = (function(_this) {
          return function(props) {
            var prop, _i, _len, _results;
            if (typeof props === 'object' && props instanceof Array && props.length > 0) {
              _results = [];
              for (_i = 0, _len = props.length; _i < _len; _i++) {
                prop = props[_i];
                if (typeof prop === 'string') {
                  if (nodeProperties.indexOf(prop) < 0) {
                    throw Error("Invalid property: " + prop);
                  }
                  _results.push(_this._props.scraper.properties.push(prop));
                } else if (typeof prop === 'object') {
                  _results.push(traverse(prop));
                } else {
                  _results.push(void 0);
                }
              }
              return _results;
            }
          };
        })(this);
        traverse(properties);
        return this;
      };

      Builder.prototype.and = function() {
        return this;
      };

      Builder.prototype.then = function() {
        return this;
      };

      Builder.prototype.of = function() {
        return this;
      };

      Builder.prototype["with"] = function() {
        return this;
      };

      Builder.prototype.build = function() {
        var args, argument, extractor, handler, req;
        req = new Request;
        if (typeof this._props.url === 'string') {
          req.url(this._props.url);
        }
        if ((this._props.timeout.duration != null) && this._props.timeout.duration >= 0) {
          req.timeout(this._props.timeout.duration);
        }
        req.on(events.TIMEOUT, this._props.timeout.handler);
        req.on(events.REQUEST_FAILURE, this._props.timeout.handler);
        switch (this._build.when) {
          case builders.when["function"]:
          case builders.when.css:
            req.condition(this._props.condition.callback, this._props.condition.argument);
        }
        switch (this._build.action) {
          case builders.action["function"]:
          case builders.action.evaluate:
            req.action(this._props.action);
            break;
          case builders.action.parts:
            extractor = this._props.scraper.extractor;
            handler = this._props.scraper.handler;
            argument = this._props.scraper.argument;
            if (typeof argument === 'undefined') {
              argument = '';
            }
            req.action(function(page) {
              return page.evaluate(extractor, handler, argument);
            });
            break;
          case builders.action.css:
            args = {
              query: this._props.scraper.query,
              preserve: this._props.scraper.properties
            };
            handler = this._props.scraper.handler;
            extractor = function(args) {
              var filter;
              filter = function(elems) {
                var elem, key, obj, results, _i, _j, _len, _len1, _ref;
                results = [];
                for (_i = 0, _len = elems.length; _i < _len; _i++) {
                  elem = elems[_i];
                  if (!(elem.id != null)) {
                    continue;
                  }
                  obj = {};
                  _ref = args.preserve;
                  for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                    key = _ref[_j];
                    if (key === 'children' || key === 'childNodes') {
                      obj[key] = filter(elem[key]);
                    } else {
                      obj[key] = elem[key];
                    }
                  }
                  results.push(obj);
                }
                return results;
              };
              return filter(document.querySelectorAll(args.query));
            };
            req.action(function(page) {
              return page.evaluate(extractor, handler, args);
            });
        }
        return req;
      };

      Builder.prototype.execute = function(url) {
        var req;
        if (typeof url !== 'undefined') {
          this.from(url);
        }
        req = this.build();
        req.execute();
        return req;
      };

      return Builder;

    })();
    Request = (function() {
      var end, log;

      end = function() {
        this.emit(events.FINISH);
        clearInterval(this._interval);
        if (this._closeWhenFinished && shared.recycle !== true) {
          return this._phantom.exit();
        }
      };

      log = function(msg) {
        return console.log(msg);
      };

      function Request() {
        this._url = '';
        this._condition = null;
        this._action = null;
        this._interval = null;
        this._phantom = null;
        this._page = null;
        this._timeout = 3000;
        this._bindConsole = false;
        this._debug = false;
        this._closeWhenFinished = true;
      }

      Request.prototype.condition = function(callback, argument) {
        if (typeof callback !== 'function' && typeof callback !== 'object') {
          throw Error("Invalid condition");
        }
        if (typeof argument === 'undefined') {
          argument = null;
        }
        this._condition = {
          callback: callback,
          argument: argument
        };
        return this;
      };

      Request.prototype.action = function(callback) {
        if (typeof callback !== 'function') {
          throw Error("Invalid action");
        }
        this._action = callback;
        return this;
      };

      Request.prototype.timeout = function(value) {
        if (typeof value === 'number') {
          this._timeout = value;
          return this;
        } else {
          return this._timeout;
        }
      };

      Request.prototype.closeWhenFinished = function(close) {
        if (typeof close === 'boolean') {
          return this._closeWhenFinished = close;
        } else {
          return this._closeWhenFinished;
        }
      };

      Request.prototype.console = function(bind) {
        if (typeof bind === 'boolean') {
          this._bindConsole = bind;
          if (this._bindConsole) {
            this.addListener(events.CONSOLE, log);
          } else {
            this.removeListener(events.CONSOLE, log);
          }
          return this;
        } else {
          return this._bindConsole;
        }
      };

      Request.prototype.debug = function(isOn) {
        var event, key, _fn;
        if (typeof isOn === 'boolean') {
          this._debug = isOn;
          _fn = function(event) {
            var callback;
            return callback = function() {
              return console.log('DEBUG: ' + event);
            };
          };
          for (key in events) {
            event = events[key];
            _fn(event);
            if (this._debug) {
              this.addListener(event, callback);
            } else {
              this.removeListener(event, callback);
            }
          }
          return this;
        } else {
          return this._debug;
        }
      };

      Request.prototype.url = function(url) {
        if (typeof url === 'string') {
          this._url = url;
          return this;
        } else {
          return this._url;
        }
      };

      Request.prototype.halt = function() {
        this.emit(events.HALT);
        return end.call(this);
      };

      Request.prototype.execute = function(url) {
        var exec;
        this.url(url);
        exec = (function(_this) {
          return function(ph) {
            _this._phantom = ph;
            _this.emit(events.PHANTOM_CREATE);
            return ph.createPage(function(page) {
              _this._page = page;
              page.set('onConsoleMessage', function(msg) {
                return _this.emit(events.CONSOLE, msg);
              });
              _this.emit(events.PAGE_CREATE);
              return page.open(_this._url, function(status) {
                var start, tick;
                if (status !== 'success') {
                  _this.emit(events.REQUEST_FAILURE);
                  return end.call(_this);
                } else if (_this._condition !== null) {
                  start = now();
                  tick = function() {
                    var handler;
                    _this.emit(events.CHECKING);
                    if (_this._timeout > 0 && now() - start > _this._timeout) {
                      _this.emit(events.TIMEOUT);
                      return end.call(_this);
                    } else {
                      handler = function(result) {
                        if (result) {
                          _this.emit(events.READY);
                          _this._action(page);
                          return end.call(_this);
                        }
                      };
                      return page.evaluate(_this._condition.callback, handler, _this._condition.argument);
                    }
                  };
                  if (_this._timeout >= 0) {
                    _this._interval = setInterval(tick, 250);
                  }
                  return tick();
                } else {
                  _this.emit(events.READY);
                  _this._action(page);
                  return end.call(_this);
                }
              });
            });
          };
        })(this);
        if (shared.recycle === false || shared.phantom === null) {
          return phantom.create(function(ph) {
            shared.phantom = ph;
            return exec(ph);
          });
        } else {
          return exec(shared.phantom);
        }
      };

      return Request;

    })();
    Request.prototype.__proto__ = Emitter.prototype;
    return exports = {
      "Request": Request,
      "Builder": Builder,
      "events": events,
      "recycle": function(val) {
        if (typeof val === 'boolean') {
          return shared.recycle = val;
        }
      },
      "create": function() {
        return new Builder;
      }
    };
  };

  module.exports = binder();

  module.exports.inject = binder;

}).call(this);
