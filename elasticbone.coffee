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
      m.set(@get_relationship_reverse(attr), @) if @has_relationship_reverse(attr)
      @set(attr, m)
      return m.fetch(options)
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
          parsed[val.name] = new val.model(parsed[val.name], parse: true)

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
    


class Elasticbone.ElasticsearchType extends Backbone.Model




###############EXTRA Helper Models

class Elasticbone.GeoShape extends Elasticbone.ElasticsearchType
  query_inside: (server, index, type, es) ->
    ne = new Elasticbone.ElasticsearchObjects()
    console.log @
    ne.elastic(@parent._es)

    ne.fetch_query = 
      "query": 
        "filtered":
          "query":
            "field": {"_geojson_dataset":"\"nz-area-units\""}
          "filter":
            "geo_shape": 
              "geometry": 
                "indexed_shape": 
                  "shape_field_name": @._es.attribute,
                  "id": @._es.parent.id,
                  "type": @._es.type,
                  "index": @._es.index

    console.log ne.url()
    console.log es.get('properties')
    ne.fetch(
      success: (collection, response, options) ->
        console.log 'success'
        # console.log reg.models.length
        console.log 'model', ne.total,  ne.took
        for model in ne.models
          console.log 'model', ne.total,  ne.took, model.get('properties')
      error: (collection, response, options) -> 
        console.log 'error', response
        #console.log 'error x', collection, response, options
    )
    

#AMD
if (typeof define != 'undefined' && define.amd)
  define([], -> return Elasticbone)
#Node
else if (typeof module != 'undefined' && module.exports)
    module.exports = Elasticbone;

