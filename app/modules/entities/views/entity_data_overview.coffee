module.exports = Marionette.ItemView.extend
  template: require './templates/entity_data_overview'
  className: 'entityDataOverview'
  initialize: (options)->
    @lazyRender = _.LazyRender @
    @listenTo @model, 'change', @lazyRender

    @hidePicture = options.hidePicture
    unless @hidePicture
      @listenTo @model, 'add:pictures', @lazyRender

  serializeData: ->
    attrs = @model.toJSON()
    attrs = @setDescriptionAttributes(attrs)
    attrs.standalone = @options.standalone
    attrs.hidePicture = @hidePicture
    return attrs

  ui:
    description: '.description'
    togglers: '.toggler i'

  behaviors:
    PreventDefault: {}

  onRender: ->
    app.execute 'uriLabel:update'

  events:
    'click .toggler': 'toggleDescLength'

  toggleDescLength: ->
    @ui.description.toggleClass 'clamped'
    @ui.togglers.toggleClass 'hidden'

  setDescriptionAttributes: (attrs)->
    if attrs.extract? then attrs.description = attrs.extract
    if attrs.description?
      attrs.descOverflow = attrs.description.length > 600

    return attrs
