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
  server: 'http://localhost:9225'
  index: 'elastic_bone_tests'

class Photo extends Elasticbone.ElasticModel
  server: es.server
  index: es.index

class Photos extends Elasticbone.ElasticCollection
  model: Photo
  @has 'location', GeoShape

class GeoRegion extends Elasticbone.ElasticModel
  server: es.server
  index: es.index
  type: 'geo_region'
  @has 'geo_shape', GeoShape

class GeoRegions extends Elasticbone.ElasticCollection
  model: GeoRegion

#The ideal Situation
#p = new Photo(location: {lat: 10, lon : 20})
#$.when(p.get('location'))
#.then((loc) -> GeoQuery.find_intersecting(loc, GeoRegions, 'geo_shape'))
#.then((regions) -> regions.first.get('geo_shape'))
#.then((region_gs) -> GeoQuery.find_intersecting(region_gs, Photos, 'location'))
#.done((posts) -> console.log "Posts from same region", posts)
