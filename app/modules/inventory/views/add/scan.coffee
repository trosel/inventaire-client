zxing = require 'modules/inventory/lib/scanner/zxing'
embedded_ = require 'modules/inventory/lib/scanner/embedded'
zxingLocalSetting = window.localStorageBoolApi 'use-zxing-scanner'
files_ = require 'lib/files'

module.exports = Marionette.ItemView.extend
  className: 'scan'
  template: require './templates/scan'
  initialize: -> prepareEmbeddedScanner()
  serializeData: ->
    hasVideoInput: window.hasVideoInput
    doesntSupportEnumerateDevices: window.doesntSupportEnumerateDevices
    zxing: zxing
    useZxing:
      id: 'toggleZxing'
      label: 'use_zxing_application'
      checked: zxingLocalSetting.get()
      inverted: false

  events:
    'click #embeddedScanner': 'startEmbeddedScanner'
    # should open the href url
    'click #zxingScanner': 'setAddModeScanZxing'
    'change .toggler-input': 'toggleZxing'
    'change #staticImageScanner': 'scanStaticImage'

  setAddModeScanZxing: -> app.execute 'last:add:mode:set', 'scan:zxing'
  startEmbeddedScanner: -> app.execute 'show:scanner:embedded'

  toggleZxing: (e)->
    { checked } = e.currentTarget

    # in case zxing was selected when the view was initalized
    # thus preventing to fire embedded_.prepare
    unless checked then prepareEmbeddedScanner false

    zxingLocalSetting.set checked
    # wait for the end of the toggle animation
    # keep in sync with app/modules/general/scss/_toggler.scss
    setTimeout @render.bind(@), 400

  scanStaticImage: (e)->
    files_.parseFileEventAsDataURL e
    .then _.Log('filesDataUrl')
    .then (dataUrlsArray)-> embedded_.staticScan dataUrlsArray[0]
    .then (results)=> @$el.find('.inner').append "<p>#{JSON.stringify(results)}<p>"
    .catch (err)=> @$el.find('.inner').append "<p>#{err.message}<p>"

prepareEmbeddedScanner = (useZxing)->
  useZxing ?= zxingLocalSetting.get()
  if window.hasVideoInput and not useZxing
    embedded_.prepare()
