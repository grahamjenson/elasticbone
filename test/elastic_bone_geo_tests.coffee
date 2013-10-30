chai = require 'chai'  
should = chai.should()
expect = chai.expect

sinon = require 'sinon'

Elasticbone = require('../elasticbone.coffee')
Backbone = Elasticbone.Backbone
$ = Elasticbone.$
_ = Elasticbone._

GeoQuery = Elasticbone.GeoQuery

es = 
  server: 'http://localhost:9250'
  index: 'elastic_bone_tests'

class Photo extends Elasticbone.ElasticModel
  server: es.server
  index: es.index
  @has 'location', Elasticbone.GeoShape

class Photos extends Elasticbone.ElasticCollection
  model: Photo

class GeoRegion extends Elasticbone.ElasticModel
  server: es.server
  index: es.index
  @has 'geo_shape', Elasticbone.GeoShape

class GeoRegions extends Elasticbone.ElasticCollection
  model: GeoRegion

#TODO need to put mappings 

#Box around new zealand
# gr = new GeoRegion({'geo_shape' : { "type": "Polygon", "coordinates": [ [ [ 166.0, -47.6 ],
# [166.0, -34.3 ], [179.1, -34.3], [179.1, -47.6] ] ] } }, {parse: true})

#p = new Photo(location: {lat: 10, lon : 20})
#$.when(p.get('location'))
#.then((loc) -> GeoQuery.find_intersecting(loc, GeoRegions, 'geo_shape'))
#.then((regions) -> regions.first.get('geo_shape'))
#.then((region_gs) -> GeoQuery.find_intersecting(region_gs, Photos, 'location'))
#.done((posts) -> console.log "Posts from same region", posts)


describe 'GeoQuery', ->

  describe 'query_from_cached', ->
    GeoQuery.query_from_cached("query_field", "shape_field_name", "id", "type", "index")

  describe 'query_from_geojson', ->
    GeoQuery.query_from_geojson("query_field", "geojson")

  describe 'find_intersecting', ->

    describe 'a non_indexed_geoshape', ->
      it 'find_intersecting should query elasticsearch', (done) ->
        json = {hits: {hits: [{name: 'ack', geo_shape: {} }] }}
        sinon.stub($, 'ajax', (req) -> 
          req.success(json, {}, {})
        )

        gr = new GeoRegion({name: 'wel', geo_shape: {}}, {parse: true})
        $.when(gr.get('geo_shape')).done((gs) ->
          GeoQuery.find_intersecting(gs, GeoRegions, 'geo_shape')
        )
        .done((regions) ->
          regions.should.be.an 'object'
          regions.should.be.instanceOf BasicFetchObject
          regions.size.should equal 1
          $.ajax.restore()
        )      
        .fail( -> 
          sinon.assert.fail()
          done()
        )
        .always( -> $.ajax.restore())
        
        
    describe 'indexed geo_shape', ->
      it 'find_intersecting should query elasticsearch', ->

#The ideal Situation
#p = new Photo(location: {lat: 10, lon : 20})
#$.when(p.get('location'))
#.then((loc) -> GeoQuery.find_intersecting(loc, GeoRegions, 'geo_shape'))
#.then((regions) -> regions.first.get('geo_shape'))
#.then((region_gs) -> GeoQuery.find_intersecting(region_gs, Photos, 'location'))
#.done((posts) -> console.log "Posts from same region", posts)
