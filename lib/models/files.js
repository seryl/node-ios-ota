// Generated by CoffeeScript 1.4.0
(function() {
  var Files, RedisObject, async,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  async = require('async');

  RedisObject = require('./redis_object');

  /**
   * A helper for working with files for a branch or tag of an application.
  */


  Files = (function(_super) {

    __extends(Files, _super);

    function Files(user, application, dtype, name) {
      this.user = user;
      this.application = application;
      this.dtype = dtype;
      if (name == null) {
        name = null;
      }
      this.delete_all = __bind(this.delete_all, this);
      this["delete"] = __bind(this["delete"], this);
      this.save = __bind(this.save, this);
      this.find = __bind(this.find, this);
      this.all = __bind(this.all, this);
      this.list = __bind(this.list, this);
      this.files_prefix = __bind(this.files_prefix, this);
      Files.__super__.constructor.call(this, name);
      this.basename = "node-ios-ota::applications";
      this.object_name = 'files';
    }

    /**
     * Returns the prefix for the files hash.
     * @return {String} The prefix for the given files hash
    */


    Files.prototype.files_prefix = function() {
      return [this.basename, this.user, this.application, this.dtype, this.current, "files"].join('::');
    };

    /**
     * Returns the list of files for the current branch/tag.
     * @param {Function} (fn) The callback function
    */


    Files.prototype.list = function(fn) {
      var _this = this;
      return this.redis.hkeys(this.files_prefix(), function(err, reply) {
        return fn(err, reply);
      });
    };

    /**
     * Returns the full information hash all of the current files.
     * @param {Function} (fn) The callback function
    */


    Files.prototype.all = function(fn) {
      var _this = this;
      return this.redis.hgetall(this.files_prefix(), function(err, reply) {
        var key, new_reply, _i, _len, _ref;
        if (reply) {
          new_reply = [];
          _ref = Object.keys(reply);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            key = _ref[_i];
            new_reply.push({
              name: key,
              md5: reply[key]
            });
          }
        }
        return fn(err, new_reply);
      });
    };

    /**
     * Finds and returns the information hash for a particular file.
     * @param {String} (filename) The filename to find information about
     * @param {Function} (fn) The callback function
    */


    Files.prototype.find = function(filename, fn) {
      var _this = this;
      return this.redis.hget(this.files_prefix(), filename, function(err, reply) {
        if (reply) {
          reply = {
            name: filename,
            md5: reply
          };
        }
        return fn(err, reply);
      });
    };

    /**
     * Adds a new files object, merging and saving the current if it exists.
     * @param {Object} (files) A single or list of filenames and md5s to add
     * @param {Function} (fn) The callback function
     *
     * @example
     *
     *   files = [
     *     { name: "myapp.ipa",   md5: "54e05c292ef585094a12b20818b3f952" },
     *     { name: "myapp.plist", md5: "ab1e5d1ed4be9d7cb8376cbf12f85ca8" }
     *   ]
     *
    */


    Files.prototype.save = function(files, fn) {
      var f, filemap, _i, _len;
      if (!(files instanceof Array)) {
        files = Array(files);
      }
      filemap = [];
      filemap.push(this.files_prefix());
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        f = files[_i];
        filemap.push(f.name);
        filemap.push(f.md5);
      }
      this.redis.hmset.apply(this.redis, filemap);
      return fn(null, filemap);
    };

    /**
     * Deletes a single file from the files hashmap.
     * @param {String} (filename) The filename to delete
     * @param {Function} (fn) The callback function
    */


    Files.prototype["delete"] = function(filename, fn) {
      var _this = this;
      return this.redis.del(this.files_prefix(), filename(function(err, reply) {
        return fn(null);
      }));
    };

    /**
     * Deletes all of the associated files from the current tag/branch.
     * @param {Function} (fn) The callback function
    */


    Files.prototype.delete_all = function(fn) {
      var _this = this;
      return this.redis.hkeys(this.files_prefix(), function(err, reply) {
        if (reply.length !== 0) {
          reply.unshift(_this.files_prefix());
          _this.redis.hdel.apply(_this.redis, reply);
        }
        return fn(null);
      });
    };

    return Files;

  })(RedisObject);

  module.exports = Files;

}).call(this);