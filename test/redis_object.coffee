RedisObject = require '../src/models/redis_object'

describe "RedisObject", ->
  ro = new RedisObject()

  beforeEach ->
    ro = new RedisObject()    

  it "should have a base prefix of `node-ios-ota`", ->
    ro.base_prefix.should.equal "node-ios-ota"

  it "should have the object name of `redis-object`", ->
    ro.object_name.should.equal "redis-object"

  it "should have a prefix of `node-ios-ota::redis-object`", ->
    ro.prefix().should.equal "node-ios-ota::redis-object"

  it "should be able to build an object and return itself", ->
    resp = ro.build({ name: "build_object" })
    ro.current.name.should.equal "build_object"
    resp.should.equal ro

  it "should be able to return a list of all redis objects", (done) ->
    ro.all (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should be able to find an object of with the given name", (done) ->
    ro.find "empty_name", (err, reply) ->
      assert.equal err, null
      assert.deepEqual reply, []
      done()

  it "should return (null, false) when saving without an object", (done) ->
    assert.equal ro.current, null
    ro.save (err, reply) ->
      assert.equal err, null
      reply.should.equal false
      done()

  it "should return (null, true) when saving with an object", (done) ->
    ro.build({ name: "test_save_object" }).save (err, reply) ->
      assert.equal err, null
      reply.should.equal true
      done()

  it "should return (null, true) when calling delete", (done) ->
    ro.delete (err, reply) ->
      assert.equal err, null
      reply.should.equal true
      done()
