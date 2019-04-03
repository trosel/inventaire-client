module.exports = Marionette.ItemView.extend
  tagName: 'li'
  className: 'item-row'
  template: require './templates/item_row'

  serializeData: -> @model.serializeData()

  events:
    'click .showItem': 'showItem'

  showItem: ->
    app.execute 'show:item', @model
