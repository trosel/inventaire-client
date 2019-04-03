# A behavior that passes a suggestion model to its view through
# onAutoCompleteSelect and onAutoCompleteUnselect hooks

# Forked from: https://github.com/KyleNeedham/autocomplete/blob/master/src/autocomplete.behavior.coffee

getSources = require 'modules/entities/lib/sources/sources'
getActionKey = require 'lib/get_action_key'
rateLimit = 200
Suggestions = require '../collections/suggestions'
SuggestionsList = require '../views/behaviors/suggestions'

module.exports = Marionette.Behavior.extend
  events:
    'keyup @ui.autocomplete': 'onKeyUp'
    'keydown @ui.autocomplete': 'onKeyDown'
    'click .close': 'hideDropdown'

  initialize: ->
    @visible = no
    prop = @view.options.model.get('property')
    source = getSources prop
    # TODO: init @suggestions only if needed
    @suggestions = Suggestions source
    @lazyUpdateQuery = _.debounce @updateQuery, rateLimit

    @_startListening()

  _startListening: ->
    @listenTo @suggestions, 'selected:value', @completeQuery.bind(@)
    @listenTo @suggestions, 'highlight', @fillQuery.bind(@)
    @listenTo @suggestions, 'error', @showAlertBox.bind(@)

  onRender: ->
    @_setInputAttributes()
    @_buildElement()

  # Wrap the input element inside the container template
  # and then append collectionView
  _buildElement: ->
    @container = $ '<div class="ac-container"></div>'
    @collectionView = new SuggestionsList { collection: @suggestions }

    @ui.autocomplete.replaceWith @container

    @container
    .append @ui.autocomplete
    .append @collectionView.render().el

  _setInputAttributes: ->
    @ui.autocomplete.attr
      autocomplete: off
      spellcheck: off
      dir: 'auto'

  onKeyDown: (e)->
    key = getActionKey e
    # only addressing 'tab' as it isn't caught by the keyup event
    if key is 'tab'
      # In the case the dropdown was shown and a value was selected
      # @fillQuery will have been triggered, the input filled
      # and the selected suggestion kept at end: we can let the event
      # propagate to move to the next input
      @hideDropdown()

  onKeyUp: (e)->
    e.preventDefault()
    e.stopPropagation()

    value = @ui.autocomplete.val()
    if value.length is 0
      @hideDropdown()
    else
      actionKey = getActionKey e

      if actionKey?
        @keyAction actionKey, e
      else
        @showDropdown()
        @lazyUpdateQuery value

  keyAction: (actionKey, e)->
    # actions happening in any case
    switch actionKey
      when 'esc' then return @hideDropdown()

    # actions conditional to suggestions state
    unless @suggestions.isEmpty()
      switch actionKey
        when 'enter' then @suggestions.trigger 'select:from:key'
        when 'down' then @suggestions.trigger 'highlight:next'
        when 'up' then @suggestions.trigger 'highlight:previous'
        # when 'home' then @suggestions.trigger 'highlight:first'
        # when 'end' then @suggestions.trigger 'highlight:last'

  showDropdown: ->
    @visible = true
    @ui.autocomplete.parent().find('.ac-suggestions').show()

  hideDropdown: ->
    @visible = false
    @ui.autocomplete.parent().find('.ac-suggestions').hide()
    @ui.autocomplete.focus()

  # Update suggestions list, never directly call this use @lazyUpdateQuery
  # which is a debounced alias.
  updateQuery: (query)->
    # remove the value passed to the view as the input changed
    @removeCurrentViewValue()
    @suggestions.trigger 'find', query

  # Complete the query using the highlighted or the clicked suggestion.
  fillQuery: (suggestion)->
    @ui.autocomplete
    .val suggestion.get('label')

    @view.onAutoCompleteSelect?(suggestion)
    @_suggestionSelected = true

  # Complete the query using the selected suggestion.
  completeQuery: (suggestion)->
    @fillQuery suggestion
    @hideDropdown()

  removeCurrentViewValue: ->
    @view.onAutoCompleteUnselect?()
    @_suggestionSelected = false

  showAlertBox: (err)->
    @view.$el.trigger 'alert', { message: err.message }

  # Clean up
  onDestroy: -> @collectionView.destroy()

# Check to see if the cursor is at the end of the query string.
isSelectionEnd = (e)->
  { value, selectionEnd } = e.target
  return value.length is selectionEnd
