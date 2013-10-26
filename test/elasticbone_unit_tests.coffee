chai = require 'chai'  
should = chai.should()
expect = chai.expect

sinon = require 'sinon'

Elasticbone = require('../elasticbone.coffee')
Backbone = Elasticbone.Backbone
$ = Elasticbone.$
_ = Elasticbone._

es = 
  server: 'http://localhost:9250'
  index: 'elastic_bone_tests'

class BasicFetchObject extends Elasticbone.ElasticModel
  server: es.server
  index: es.index

class BasicObject extends Backbone.Model

class TestObject extends Elasticbone.ElasticModel
  server: es.server
  index: es.index
  @has 'bo', BasicObject
  @has 'bfo', BasicFetchObject, method: 'fetch'

class TestCollection extends Elasticbone.ElasticCollection
  server: es.server
  index: es.index
  model: TestObject

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
    
    it 'should initialize the related object on creation', (done) ->
      to = new TestObject({name: 'test', bo: {name: 'bo_test'}},{parse: true})
      $.when(to.get('name'), to.get('bo')).done( (name, bo) ->
        name.should.equal 'test'
        bo.should.be.an 'object'
        bo.should.be.instanceOf BasicObject
        bo.get('name').should.equal 'bo_test'
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )
  
    it 'should serialize toJSON including the internal models', ->
      to_json = {name: 'test', bo: {name: 'bo_test'}}
      to = new TestObject( to_json , {parse: true} )
      to.toJSON().should.eql to_json

    it 'should create a model without a parse relationship', (done) ->
      to = new TestObject( {name: 'test'} , {parse: true} )
      $.when(to.get('name'), to.get('bo')).done( (name, bo) ->
        name.should.equal 'test'
        expect(bo).to.be.undefined
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )

    it 'should save model including all parse relationship', (done) ->
      to_json = {name: 'test', bo: {name: 'bo_test'}}
      sinon.stub($, 'ajax', (req) -> 
        req.data.should.equal JSON.stringify(to_json)
        req.success({ok: true, _id : 'new_id'}, {}, {})
      )
      
      to = new TestObject(to_json,{parse: true})
      $.when(to.save()).done( (bo) ->
        to.id.should.equal 'new_id'
        sinon.assert.calledOnce($.ajax);
        $.ajax.restore()
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )

  describe 'with fetch relationship', ->
    it 'should add the relationship', ->
      to = new TestObject()
      to.has_relationship('bfo').should.equal true
      to.get_relationship('bfo').should.be.an 'object'
      to.get_relationship_model('bfo').should.equal BasicFetchObject
      to.get_relationship_method('bfo').should.equal 'fetch'


    it 'should initialize the object relationship', (done) ->
      to = new TestObject({name: 'test', bfo: {name: 'bfo_test'}},{parse: true})
      $.when(to.get('name'), to.get('bfo'))
      .then((name, bfo) ->
        name.should.equal 'test'
        bfo.should.be.an 'object'
        bfo.should.be.instanceOf BasicFetchObject
        return bfo.get('name')
      )
      .done( (bfo_name) ->
        bfo_name.should.equal 'bfo_test'
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )

    it 'should not be included in toJSON', ->
      to = new TestObject({name: 'test', bfo: {name: 'bfo_test'}},{parse: true})
      to.toJSON().should.eql {name: 'test'}

    it 'should not save the sub relationship', (done) ->
      #as it is another documnet
      to_json = {name: 'test', bfo: {name: 'bfo_test'}}
      sinon.stub($, 'ajax', (req) -> 
        req.data.should.equal JSON.stringify({name: 'test'})
        req.success({ok: true, _id : 'new_id'}, {}, {})
      )

      to = new TestObject(to_json,{parse: true})
      $.when(to.save()).done( (bo) ->
        to.id.should.equal 'new_id'
        sinon.assert.calledOnce($.ajax);
        $.ajax.restore()
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )

    it 'should fetch on get', (done) ->
      sinon.stub($, 'ajax', (req) -> 
        req.url.should.equal 'http://localhost:9250/elastic_bone_tests/BasicFetchObject'
        req.success({_id : 'new_id', _source: { name: 'bfo_test' } }, {}, {})
      )

      to = new TestObject({name: 'test'},{parse: true})
      $.when(to.get('bfo')).then( (bfo) ->
        bfo.id.should.equal 'new_id'
        return bfo.get('name')
      )
      .done( (name) ->
        name.should.equal 'bfo_test'
        sinon.assert.calledOnce($.ajax);
        $.ajax.restore()
        done()
      )
      .fail( -> 
        sinon.assert.fail()
        done()
      )
