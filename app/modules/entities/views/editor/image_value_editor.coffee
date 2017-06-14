EditorCommons = require './editor_commons'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'
files_ = require 'lib/files'
images_ = require 'lib/images'
{ startLoading, stopLoading } = require 'modules/general/plugins/behaviors'

urlInputSelector = '.imageUrl'
imagePreviewSelector = '.image-preview'

module.exports = EditorCommons.extend
  mainClassName: 'image-value-editor'
  template: require './templates/image_value_editor'

  behaviors:
    AlertBox: {}
    Loading: {}

  ui:
    urlInput: urlInputSelector
    uploadConfirmation: '.upload-confirmation'
    imagePreview: imagePreviewSelector

  initialize: ->
    @lazyRender = _.LazyRender @
    @initEditModeState()
    @focusTarget = 'urlInput'

  onRender: ->
    @focusOnRender()

  events:
    'click .edit, .displayModeData': 'showEditMode'
    'click .cancel': 'hideEditMode'
    'click .save': 'saveFromUrl'
    'click .delete': 'delete'
    # Not setting a particular selector so that any keyup event on taezaehe element triggers the event
    'keyup': 'onKeyup'
    'change input[type=file]': 'getImageUrl'
    'click .validate-upload': 'uploadFileAndSave'

  getImageUrl: (e)->
    files_.parseFileEventAsDataURL e
    .then _.first
    .then @showUploadConfirmation.bind(@)

  showUploadConfirmation: (dataUrl)->
    @ui.imagePreview.html "<img src=\"#{dataUrl}\">"
    @ui.uploadConfirmation.show()

  saveFromUrl: ->
    startLoading.call @, '.save'
    url = @ui.urlInput.val()

    if url is @model.get('value') then return @hideEditMode()

    unless _.isUrl url
      err = error_.new 'invalid URL', url
      err.selector = urlInputSelector
      return forms_.alert @, err

    _.preq.post app.API.images.convertUrl, { url }
    .get 'url'
    .then @_save.bind(@)
    .catch error_.Complete(urlInputSelector, false)
    .catch forms_.catchAlert.bind(null, @)
    .finally stopLoading.bind(@)

  uploadFileAndSave: ->
    dataUrl = @ui.imagePreview.find('img')[0]?.src

    startLoading.call @, '.validate-upload'

    images_.getIpfsPathFromDataUrl dataUrl
    .then @_save.bind(@)
    .catch error_.Complete(imagePreviewSelector, false)
    .catch forms_.catchAlert.bind(null, @)
    .finally stopLoading.bind(@)