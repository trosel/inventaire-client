embeddedScanner = require 'modules/inventory/lib/scanner/embedded'

module.exports = Marionette.ItemView.extend
  template: require './templates/embedded_scanner'
  className: 'embedded'
  events:
    'click .close': 'close'

  onShow: ->
    app.execute 'last:add:mode:set', 'scan:embedded'
    @scanner = embeddedScanner()

  close: ->
    # come back to the previous view
    # which should trigger @destroy as the previous view is expected to be shown
    # in app.layout.main too
    window.history.back()

  onDestroy: ->
    # Cancelling the promise to let the opportunity to Quagga to stop properly
    # and avoid having a promise unfulfilled.
    # Has no effect if the promise is already fulfilled
    @scanner.cancel()