clampedExtract = require '../lib/clamped_extract'

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
    clampedExtract.setAttributes attrs
    attrs.standalone = @options.standalone
    attrs.hidePicture = @hidePicture
    return attrs

  behaviors:
    PreventDefault: {}
    ClampedExtract: {}

  onRender: ->
    app.execute 'uriLabel:update'
