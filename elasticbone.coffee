Elasticbone = {}

$ = require 'jquery'
_ = require 'backbone/node_modules/underscore'
Backbone = require 'backbone'
Backbone.$ = $

#####Pass these mmodules through to client

Elasticbone.Backbone = Backbone
Elasticbone.$ = $
Elasticbone._ = _

$.wait = (time) ->
  return $.Deferred((dfd) ->
    setTimeout(dfd.resolve, time);
  )

#This auto adds the relational thing

#example of search http://localhost:9225/geojson_feature_collection/_search?pretty=true&q=%22nz-region%22&df=_geojson_dataset
#example of individual model http://localhost:9225/geojson_feature_collection/geojson_feature/IlR0IZ_iQRGTySIa8qzWGw
#MODEL TEST

#############ABSTRACTIONS

class Elasticbone.ElasticModel extends Backbone.Model
  urlRoot: -> "#{@server}/#{@index}/#{@type}"
  
  constructor: ->
    @type = @constructor.name
    super

  @has: (name, model, options = {}) ->
    options = _.defaults(options, 
      method: 'parse'
      model: model
      name: name
    )
    @prototype._has ||= {}
    @prototype._has[name] = options

  has_relationship: (attr, options) ->
    @get_relationship(attr, options) and true

  get_relationship: (attr, options = {}) ->
    has_rel = @_has  and @_has[attr] and true
    if options.method
      has_rel = has_rel and options.method == @_has[attr].method
    if not has_rel
      return undefined
    @_has[attr]

  get_relationship_model: (attr) ->
    @get_relationship(attr).model

  get_relationship_method: (attr) ->
    @get_relationship(attr).method

  get_relationship_reverse: (attr) ->
    @_has[attr].reverse

  has_relationship_reverse: (attr) ->
    !! @_has[attr].reverse

  get_relationships: (options ={}) ->
    if not @_has
      return []
    rels = []
    for key, val of @_has
      if  (rel = @get_relationship(key, options))
        rels.push(rel)
    rels

  set_model_values: (m, attr) ->
    m.set(@get_relationship_reverse(attr), @)
    m._parent = @
    m._field_name = attr

  #Semantic change, get reutrns a promise for the data
  get: (attr, options) ->
    data = super(attr,options)
    #if it is there return it as a promise
    if data 
      return $.when(data)
    
    if @has_relationship(attr, method: 'fetch')
      #IF it is a single object, it will be a search for the item
      #TODO have fetch query called on the single item
      model_class = @get_relationship_model(attr)
      m = new model_class()
      @set_model_values(m, attr)
      @set(attr, m)
      return $.when(m.fetch(options)).then( (res) -> return m)
    $.when(undefined)

  #(elasticsearch document) -> (Backbone model)
  parse: (data, options) ->
    data = super(data, options)

    #The returned object
    parsed = {}

    if data._id
      parsed.id = data._id
    if data.id
      parsed.id = id
    #Possible Data
    # 1) on a save to elasticsearch the responce will work
    #model is created without ids but needs to be parsed

    if data.ok
      return parsed
    
    # 2) elasticsearch returns model inside a _source key
    if data._source
      parsed = _.extend(parsed, data._source)
    else
      parsed = _.extend(parsed, data)

    for val in @get_relationships()
        if parsed[val.name]
          m = new val.model(parsed[val.name], parse: true)
          @set_model_values(m, val.name)
          parsed[val.name] = m

    parsed

  #(Backbone model) -> (elasticsearch document) 
  toJSON: (options) ->
    json = super
    #remove id as in elastic it is outside the object
    delete json.id

    #delete all relationships
    for rel in @get_relationships()
      delete json[rel.name]

    for rel in @get_relationships(method: 'parse')
      #ASSUMPTION: ALL PARSE RELATIONSHIPS WILL BE RESOLVED GET
      @get(rel.name).done( (x) ->
        json[rel.name] = x.toJSON(options) if x
      )
    json

class Elasticbone.ElasticCollection extends Backbone.Collection
  fetch_query: -> {"query":{"match_all": {}}}

  url: -> 
    u = "#{@server}"
    if @index
      u +="/#{@index}"
      if @type
        u += "/#{@type}"
    u += "/_search?size=100"
    u

  model: Elasticbone.ElasticsearchObject
  server: 'http://localhost:9200'

  parse: (data) ->
    console.log 'parse col', data
    @total = data.hits.total
    @took = data.took
    return data.hits.hits

  fetch: (options) ->
    console.log 'fetch col', options, @fetch_query()
    super _.defaults(options, {
      type: 'POST'
      data:  JSON.stringify(@fetch_query())
    })

  set_reverse: (attr,model) ->
    @[attr] = model
    

###############Geo Helper Methods

class Elasticbone.GeoQuery

  #takes a geoshape instance, an ElasticCollection and a field, and finds all of the collections models.field that intersect the geoshape and returns them
  #initially, will only support query with geoshape, later can support query of an already indexed shape
  @find_intersecting: (geoshape, elasticbone_collection, field) ->
    ebc = new elasticbone_collection()
    
    if !!(geoshape._field_name && geoshape._parent.id && geoshape._parent.type && geoshape._parent.index)
      geo_shape_query = 
        "query": 
          "filtered":
            "query":
              "match_all": {}
            "filter":
              "geo_shape": 
                field:
                  "indexed_shape": 
                    "shape_field_name": geoshape._field_name,
                    "id": geoshape._parent.id,
                    "type": geoshape._parent.type,
                    "index": geoshape._parent.index
    else
      geo_shape_query =
        "query": 
          "filtered":
            "query":
              "match_all": {}
            "filter":
              "geo_shape": 
                field: 
                  "shape": 
                    geoshape.toJSON()

    return $.when( ebc.fetch( data:  JSON.stringify(geo_shape_query) ) )


class Elasticbone.GeoShape

#AMD
if (typeof define != 'undefined' && define.amd)
  define([], -> return Elasticbone)
#Node
else if (typeof module != 'undefined' && module.exports)
    module.exports = Elasticbone;

