RedisObject = require '../src/models/redis_object'

ro = new RedisObject()

describe "RedisObject", ->
  beforeEach () =>
    ro = new RedisObject()

  it "should have a base prefix of `node-ios-ota`", =>
    ro.base_prefix.should.equal "node-ios-ota"

  it "should have the object name of `redis-object`", ->
    ro.object_name.should.equal "redis-object"

  it "should have a prefix of `node-ios-ota::redis-object`", ->
    ro.prefix().should.equal "node-ios-ota::redis-object"

  it "should return (null, false) when saving without an object", ->
    assert.equal ro.current, null
    ro.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, false

  it "should return (null, true) when saving with an object", ->
    ro.current = { name: "test_save_object" }
    ro.save (err, reply) ->
      assert.equal err, null
      assert.equal reply, true

  it "should return (null, true) when calling delete", ->
    ro.delete (err, reply) ->
      assert.equal err, null
      assert.equal reply, true
