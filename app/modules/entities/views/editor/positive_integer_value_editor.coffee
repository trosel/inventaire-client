EditorCommons = require './editor_commons'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'
inputSelector = '.positive-integer-picker'

module.exports = EditorCommons.extend
  mainClassName: 'positive-integer-value-editor'
  template: require './templates/positive_integer_value_editor'

  behaviors:
    AlertBox: {}

  ui:
    input: inputSelector

  initialize: ->
    @lazyRender = _.LazyRender @
    @initEditModeState()
    @focusTarget = 'input'

  onRender: ->
    @focusOnRender()

  events:
    'click .edit, .displayModeData': 'showEditMode'
    'click .cancel': 'hideEditMode'
    'click .save': 'save'
    'click .delete': 'delete'
    # Not setting a particular selector so that any keyup event on the element triggers the event
    'keyup': 'onKeyup'

  save: ->
    inputVal = @ui.input.val()

    unless _.isPositiveIntegerString inputVal
      err = error_.new 'invalid number', inputVal
      err.selector = inputSelector
      return forms_.alert @, err

    val = parseInt inputVal

    # Ignore if we got the same value
    if val is @model.get('value') then return @hideEditMode()

    unless 1 <= val <= 100000
      err = error_.new "number can't be higher than 100000", val
      err.selector = inputSelector
      return forms_.alert @, err

    @_save val
