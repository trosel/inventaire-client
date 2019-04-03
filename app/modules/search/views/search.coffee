ResultsList = require './results_list'
Entities = require 'modules/entities/collections/entities'
isbn_ = require 'lib/isbn'
behaviorsPlugin = require 'modules/general/plugins/behaviors'
{ startLoading } = require 'modules/general/plugins/behaviors'

# An object to cache search results from one search to the next
cache = {}

module.exports = Marionette.LayoutView.extend
  id: 'searchLayout'
  template: require './templates/search'
  behaviors:
    AlertBox: {}
    PreventDefault: {}
    Loading: {}

  regions:
    authors: '#authors'
    series: '#series'
    works: '#works'
    editions: '#editions'

  ui:
    showFindByIsbnButton: '#showFindByIsbn'
    findByIsbnForm: '#findByIsbnForm'

  initialize: (params)->
    _.extend @, behaviorsPlugin
    @query = params.query.trim()
    @queryIsIsbn = isbn_.looksLikeAnIsbn @query
    @model = app.request 'search:history:add', { @query }

  serializeData: ->
    queryIsIsbn: @queryIsIsbn
    findByIsbn:
      nameBase: 'findIsbn'
      field:
        name: 'isbn'
        placeholder: _.i18n('ex:') + ' 978-2-07-036822-8'
        dotdotdot: ''
      button:
        icon: 'search'
        classes: 'secondary postfix'

  events:
    'click #showFindByIsbn a': 'showFindByIsbn'
    'click .scanner': -> app.execute 'show:scan'
    'click #findIsbnButton': 'searchByIsbn'
    'click #createEntity': 'createEntity'

  onShow: ->
    @searchEntities()

  sameAsPreviousQuery: ->
    # Verifying that the query is not the same as the last one
    # and using the previous results if so
    if cache.search is @query and cache.length > 0
      @displayResults()
      @authors.$el.hide().fadeIn 200
      return true

  searchEntities: ->
    search = @query
    if @sameAsPreviousQuery() then return

    # Reset cache
    cache = { search }

    _.preq.get app.API.entities.search(search, @options.refresh)
    .then @ifViewIsIntact('showResults')
    .catch @_catchErr.bind(@)

    @startLoading '#authors', { timeout: 120 }
    @setTimeout @_pleaseBePatient.bind(@), 6000

  _pleaseBePatient: ->
    unless cache.returned
      @_appendToAuthorEl _.i18n('slow_search_message')
      @setTimeout @_pleaseBeVeryPatient.bind(@), 10000

  _pleaseBeVeryPatient: ->
    unless cache.returned
      text2 = _.I18n "while you're there,"
      text3 = _.i18n 'while_you_are_there_1'
      innerText = "#{text2} #{text3}"
      @_appendToAuthorEl innerText

  _appendToAuthorEl: (text)->
    # The page might have change since the timeout was triggered
    if @isDestroyed then return

    $("<p class='please-be-patient hidden'>#{text}</p>")
    .appendTo @authors.$el
    .slideDown()

  showResults: (res)->
    @_parseResponse res
    @displayResults()

  _parseResponse: (res)->
    cache.returned = true
    # hiding the loader and .please-be-patient messages
    @authors.$el.empty()
    if res? then spreadResults res

  _catchErr: (err)->
    switch err.statusCode
      when 404 then @alert 'no item found'
      # Known case: invalid ISBN
      when 400 then @alert err.message
      else
        _.error err, 'searchEntities err'
        @alert err.message

    @_emptyAllRegions()
    cache.returned = true

  _emptyAllRegions: ->
    Object.keys @regions
    .forEach (regionName)=> @[regionName].empty()

  displayResults: ->
    { humans, series, works, editions } = cache

    _.log cache, 'cache'

    authorsUris = humans?.models.map(getUri) or []
    seriesUris = series?.models.map(getUri) or []
    deduplicateSubEntities authorsUris, series, 'wdt:P50'
    deduplicateSubEntities authorsUris, works, 'wdt:P50'
    deduplicateSubEntities seriesUris, works, 'wdt:P179'

    # Eventually, add a filter to display humans with occupation writter only
    @_displayTypeResults humans, 'authors'
    @_displayTypeResults series, 'series'
    @_displayTypeResults works, 'works'
    @_displayTypeResults editions, 'editions'

  _displayTypeResults: (collection, type)->
    if collection?.length > 0
      list = new ResultsList { collection, type }
      @[type].show list

      @saveSearchPictures collection

  showFindByIsbn: ->
    @ui.showFindByIsbnButton.slideUp()
    @ui.findByIsbnForm.slideDown()

  saveSearchPictures: (collection)->
    # keep only every entity first picture to avoid passing
    # several possibily identical pictures for a single entity
    pictures = collection.map (model)-> model.get('image.url')
    @model.savePictures pictures

  searchByIsbn: ->
    query = $('input#findIsbnField').val()
    _.log query, 'isbn query'
    app.execute 'search:global', query

  createEntity: (e)->
    unless _.isOpenedOutside e
      app.execute 'show:entity:create', { type: 'work', label: @query }

spreadResults = (res)->
  { humans, series, works, editions } = res
  cache.humans = new Entities humans
  cache.series = new Entities series
  cache.works = new Entities works
  cache.editions = new Entities editions
  cache.length = humans.length + series.length + works.length + editions.length
  return

# Remove works and series that have an author in the authors list or works that are
# part of a found serie as they will fetched and displayed in the author's or serie's
# subentities list
deduplicateSubEntities = (authorsUris, subentities, subentitiesProperty)->
  unless subentities? then return

  toRemove = []
  subentities.forEach (subentity)->
    if _.haveAMatch subentity.get("claims.#{subentitiesProperty}"), authorsUris
      # Not removing directly as it would conflict with the forEach loop
      toRemove.push subentity

  subentities.remove toRemove

getUri = (model)-> model.get 'uri'
