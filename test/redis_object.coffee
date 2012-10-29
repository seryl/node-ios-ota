RedisObject = require '../src/models/redis_object'

describe "RedisObject", ->
  it "should have a base prefix of `node-ios-ota`", ->
    ro = new RedisObject()
    ro.base_prefix.should.equal "node-ios-ota"

  it "should have the object name of `redis-object`", ->
    ro = new RedisObject()
    ro.object_name.should.equal "redis-object"

  it "should have a prefix of `node-ios-ota::redis-object`", ->
    ro = new RedisObject()
    ro.prefix().should.equal "node-ios-ota::redis-object"

  it "should be able to build an object and return itself", ->
    ro = new RedisObject()
    resp = ro.build({ name: "build_object" })
    ro.current.name.should.equal "build_object"
    resp.should.equal ro

  it "should be able to return a list of all redis objects", (done) ->
    ro = new RedisObject()
    ro.all (err, reply) ->
      assert.equal err, null
      assert.isArray reply
      assert.equal reply.length, 0
      done()

  it "should be able to find an object of with the given name", (done) ->
    ro = new RedisObject()
    ro.find "empty_name", (err, reply) ->
      assert.equal err, null
      assert.isArray reply
      assert.equal reply.length, 0
      done()

  it "should return (null, false) when saving without an object", (done) ->
    ro = new RedisObject()
    assert.equal ro.current, null
    ro.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, false
      done()

  it "should return (null, true) when saving with an object", (done) ->
    ro = new RedisObject()
    ro.current = { name: "test_save_object" }
    ro.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, true
      done()

  it "should return (null, true) when calling delete", (done) ->
    ro = new RedisObject()
    ro.delete (err, reply) ->
      assert.equal err, null
      assert.equal reply, true
      done()
