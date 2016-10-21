sitelinks_ = require 'lib/wikimedia/sitelinks'
wikipedia_ = require 'lib/wikimedia/wikipedia'
getBestLangValue = require '../get_best_lang_value'

module.exports = ->
  { lang } = app.user
  setWikiLinks.call @, lang
  setAttributes.call @, lang

  waitForExtract = setWikipediaExtract.call @
  @_dataPromises.push waitForExtract

setWikiLinks = (lang)->
  wdId = @get('claims.invp:P1.0')
  updates =
    wikidata:
      url: "https://www.wikidata.org/entity/#{wdId}"
      wiki: "https://www.wikidata.org/wiki/#{wdId}"

  # Editions happen on Wikidata for now
  updates.editable = updates.wikidata

  sitelinks = @get 'sitelinks'
  if sitelinks?
    # required to fetch images from the English Wikipedia
    @enWpTitle = sitelinks.enwiki
    updates.wikipedia = sitelinks_.wikipedia sitelinks, lang, @originalLang
    updates.wikisource = sitelinks_.wikisource sitelinks, lang, @originalLang

  @set updates

setWikipediaExtract = ->
  lang = @get 'wikipedia.lang'
  title = @get 'wikipedia.title'
  unless lang? and title? then return _.preq.resolved

  wikipedia_.extract lang, title
  .then _setWikipediaExtractAndDescription.bind(@)
  .catch _.Error('setWikipediaExtract err')

_setWikipediaExtractAndDescription = (extract)->
  if extract?
    @set 'extract', extract
    description = @get('description') or ''
    if extract.length > description.length
      @set 'description', extract

setAttributes = (lang)->
  label = @get 'label'
  wikipediaTitle = @get 'wikipedia.title'
  if wikipediaTitle? and not label?
    # If no label was found, try to use the wikipedia page title
    # remove the escaped spaces: %20
    label = decodeURIComponent wikipediaTitle
      # Remove the eventual desambiguation part between parenthesis
      .replace /\s\(\w+\)/, ''

    @set 'label', label

  description = getBestLangValue lang, @originalLang, @get('descriptions')
  if description? then @set 'description', description