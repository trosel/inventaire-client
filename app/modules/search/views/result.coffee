module.exports = Marionette.ItemView.extend
  className: 'result'
  template: require './templates/result'
  behaviors:
    PreventDefault: {}

  events:
    'click a': 'showResultFromEvent'

  showResultFromEvent: (e)-> unless _.isOpenedOutside e then @showResult()
  showResult: ->
    command = @model.get 'showCommand'
    app.execute command, @model.id
    app.vent.trigger 'live:search:show:result'

  unhighlight: -> @$el.removeClass 'highlight'
  highlight: -> @$el.addClass 'highlight'