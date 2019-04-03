module.exports = Marionette.ItemView.extend
  tagName: 'li'
  className: 'item-row'
  template: require './templates/item_row'

  initialize: ->
    @listenTo @model, 'change', @render.bind(@)

  serializeData: ->
    _.extend @model.serializeData(),
      checked: @getCheckedStatus()

  events:
    'click .showItem': 'showItem'

  showItem: ->
    app.execute 'show:item', @model

  getCheckedStatus: -> @model.id in @options.getSelectedIds?()
