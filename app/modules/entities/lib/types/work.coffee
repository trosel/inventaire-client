wd_ = require 'lib/wikimedia/wikidata'

module.exports = ->
  # Main property by which sub-entities are linked to this one
  @childrenClaimProperty = 'wdt:P629'
  @fetchSubEntities 'editions', @refresh

  setPublicationYear.call @
  @waitForSubentities.then setImage.bind(@)

  _.extend @, workMethods

setPublicationYear = ->
  publicationDate = @get 'claims.wdt:P577.0'
  if publicationDate?
    @publicationYear = publicationDate.split('-')[0]

setImage = ->
  images =_.compact @editions.map(getEditionImageData)
  images.sort BestImage(app.user.lang)
  @set 'image', images[0]?.image

getEditionImageData = (model)->
  image = model.get 'image'
  unless image?.url? then return
  return {
    image: image
    lang: model.get 'lang'
    publicationDate: model.get 'publicationTime'
  }

# Sorting function on probation
BestImage = (userLang)-> (a, b)->
  if a.lang is b.lang then latestPublication a, b
  else if a.lang is userLang then -1
  else if b.lang is userLang then 1
  else latestPublication a, b

latestPublication = (a, b)-> b.publicationTime - a.publicationTime

workMethods =
  getAuthorsString: ->
    P50 = @get 'claims.wdt:P50'
    unless P50?.length > 0 then return _.preq.resolve ''
    return wd_.getLabel P50, app.user.lang

  buildWorkTitle: ->
    title = @get 'label'
    P31 = @get 'claims.wdt:P31.0'
    type = _.I18n(typesString[P31] or 'book')
    return "#{title} - #{type}"

typesString =
  'wd:Q571': 'book'
  'wd:Q1004': 'comic book'
  'wd:Q8274': 'manga'
  'wd:Q49084': 'short story'