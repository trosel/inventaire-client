{ data:transactionsData } = require 'modules/inventory/lib/transactions_data'

module.exports = Marionette.CompositeView.extend
  template: require './templates/items_preview_list'
  childViewContainer: '.items-preview'
  childView: require './item_preview'
  className: 'itemsPreviewList'

  initialize: ->
    { @transaction } = @options

  childViewOptions: ->
    showDetails: @options.showDetails

  serializeData: ->
    transaction: @transaction
    icon: transactionsData[@transaction].icon
    showDetails: @options.showDetails
