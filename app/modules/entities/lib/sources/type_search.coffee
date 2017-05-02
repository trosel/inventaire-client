SearchResult = require 'modules/entities/models/search_result'
elasticSearch = require './elastic_search'
wikidataSearch = require './wikidata_search'
languageSearch = require './language_search'
{ getEntityUri, prepareSearchResult } = require './entities_uris_results'

module.exports = (type)->
  collection = new Backbone.Collection [], { model: SearchResult }
  remote = getRemoteFn type, getSearchTypeFn(type), collection, []
  return API = { collection, remote }

getSearchTypeFn = (type)->
  # the searchType function should take a input string
  # and return an array of results
  switch type
    when 'humans', 'genres', 'movements', 'publishers', 'series' then elasticSearch type
    when 'topics' then wikidataSearch
    when 'languages' then languageSearch
    else throw new Error("unknown type: #{type}")

getRemoteFn = (type, searchType, collection, searches)-> (input)->
  _.log input, 'input'
  if input in searches
    _.log input, 'already queried'
    # keep a consistant interface by returning only promises
    return _.preq.resolved

  searches.push input

  entityUri = getEntityUri input
  if entityUri?
    app.request 'get:entity:model', entityUri
    .then (model)->
      pluarlizedType = model.type + 's'
      if pluarlizedType is type
        collection.add prepareSearchResult(model)

  else
    searchType input
    .then collection.add.bind(collection)
    .catch _.Error("search #{type}")
