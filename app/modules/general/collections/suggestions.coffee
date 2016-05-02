# Forked from: https://github.com/KyleNeedham/autocomplete/blob/master/src/autocomplete.collection.coffee

module.exports = (options)->
  { collection, remote } = options.source()
  # FilteredCollection don't have an extend method
  # and do weird things when `call`ed with Backbone.Collection.extend
  # so here is a custom extension
  suggestions = new FilteredCollection collection
  _.extend suggestions, suggestionMethods
  suggestions.init collection, remote
  return suggestions

# module.exports = Backbone.Collection.extend
suggestionMethods =
  init: (collection, remote)->
    @index = -1
    @remote = remote
    @on 'find', @fetchNewSuggestions
    @on 'highlight:next', @highlightNext
    @on 'highlight:previous', @highlightPrevious
    @on 'highlight:first', @highlightFirst
    @on 'highlight:last', @highlightLast
    @on 'select', @select

    # Model events are passed to their collection but not to their
    # filtered collection, thus the need to add a listner
    @listenTo collection, 'select', @select

  # Get suggestions based on the current input. Either query
  # the api or filter the dataset.
  fetchNewSuggestions: (query)->
    query = query.trim().replace /\s{2,}/g, ' '
    @index = -1
    @filterByText query
    @remote query

  # Select first suggestion unless the suggestion list
  # has been navigated then select at the current index.
  select: ->
    index = if @isStarted() then @index else 0
    @trigger 'selected:value', @at(index)

  highlightPrevious: -> unless @isFirst() then @highlightAt @index - 1
  highlightNext: -> unless @isLast() then @highlightAt @index + 1
  highlightFirst: -> @highlightAt 0
  highlightLast: -> @highlightAt @length - 1
  highlightAt: (index)->
    if @index is index then return

    if @isStarted() then @removeHighlight @index
    @index = index
    @highlight index

  isFirst: -> @index is 0
  isLast: -> @index is @length - 1

  # Check to see if we have navigated through the
  # suggestions list yet.
  isStarted: -> @index isnt -1

  highlight: (index)-> @highlightEvent 'highlight', index
  removeHighlight: (index)-> @highlightEvent 'highlight:remove', index
  highlightEvent: (eventName, index)->
    model = @at index
    model.trigger eventName, model
