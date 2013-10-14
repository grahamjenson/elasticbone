chai = require 'chai'  
chai.should()

sinon = require 'sinon'

Elasticbone = require('../elasticbone')
Backbone = Elasticbone.Backbone
$ = Elasticbone.$
_ = Elasticbone._

es = 
  server: 'http://localhost:9225'
  index: 'elastic_bone_tests'

class BasicObject extends Backbone.Model

class TestObject extends Elasticbone.ElasticModel
  server: es.server
  index: es.index
  @has 'bo', BasicObject

describe 'Initialization of ElasticModel', ->  
  it 'should save properly', ->  
    to = new TestObject()
    to.server.should.equal es.server
    to.index.should.equal es.index
    to.type.should.equal "TestObject"

describe 'has relationship function,', ->
  describe 'with parse relationship', ->

    it 'should add a relationship', ->
      to = new TestObject()
      to.has_relationship('bo').should.equal true
      to.get_relationship('bo').should.be.an 'object'
      to.get_relationship_model('bo').should.equal BasicObject
      to.get_relationship_method('bo').should.equal 'parse'
    
    it 'should initialize the related object on creation', ->
       to = new TestObject({name: 'test', bo: {name: 'bo_test'}},{parse: true})
       to.get('name').should.equal 'test'
       to.get('bo').should.be.an 'object'
       to.get('bo').should.be.instanceOf BasicObject
       to.get('bo').get('name').should.equal 'bo_test'
  
    it 'should serialize toJSON including the internal models', ->
      to_json = {name: 'test', bo: {name: 'bo_test'}}
      to = new TestObject( to_json , {parse: true} )
      to.toJSON().should.eql to_json

    it 'should create model including all parse relationships'

    it 'should save model including all parse relationship', ->
      sinon.stub($, 'ajax', (req) -> req.success({ok: true, _id : 'new_id'}, {}, {}));
      to = new TestObject({name: 'test', bo: {name: 'bo_test'}},{parse: true})
      to.get('bo').should.be.instanceOf BasicObject
      to.save()
      $.ajax.restore()

  describe 'with fetch relationship', ->
    it 'should create relationship'
    it 'should not fetch on parse'
    it 'should fetch on get'
    it 'should parse the returned value'
    it 'toJSON should not include the model to be fetched'
    it 'should save each fetch related model async'
