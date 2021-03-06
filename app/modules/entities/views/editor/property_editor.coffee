isLoggedIn = require './lib/is_logged_in'
creationParials = require './lib/creation_partials'

editors =
  entity: require './entity_value_editor'
  'fixed-entity': require './fixed_entity_value'
  string: require './string_value_editor'
  'fixed-string': require './fixed_string_value'
  'simple-day': require './simple_day_value_editor'
  'positive-integer': require './positive_integer_value_editor'
  'positive-integer-string': require './positive_integer_string_value_editor'
  'image': require './image_value_editor'

module.exports = Marionette.CompositeView.extend
  className: ->
    specificClass = 'property-editor-' + @model.get('editorType')
    return "property-editor #{specificClass}"

  template: require './templates/property_editor'
  getChildView: -> editors[@model.get('editorType')]
  childViewContainer: '.values'

  behaviors:
    # May be required by customAdd creation partials
    AlertBox: {}
    PreventDefault: {}

  initialize: ->
    @collection = @model.values

    fixedValue = @model.get('editorType').split('-')[0] is 'fixed'
    noValue = @collection.length is 0
    if fixedValue and noValue
      @shouldBeHidden = true
      return

    unless @model.get 'multivalue'
      @listenTo @collection, 'add remove', @updateAddValueButton.bind(@)

    @property = @model.get 'property'
    @customAdd = creationParials[@property]

  serializeData: ->
    if @shouldBeHidden then return
    attrs = @model.toJSON()
    if @customAdd
      attrs.customAdd = true
      attrs.creationPartial = 'entities:editor:' + @customAdd.partial
      attrs.creationPartialData = @customAdd.partialData @model.entity
    else
      attrs.canAddValues = @canAddValues()
    return attrs

  onShow: ->
    if @shouldBeHidden then @$el.hide()

  canAddValues: -> @model.get('multivalue') or @collection.length is 0

  events:
    'click .addValue': 'addValue'
    'click .creationPartial a': 'dispatchCreationPartialClickEvents'

  ui:
    addValueButton: '.addValue'

  addValue: (e)->
    if isLoggedIn() then @collection.addEmptyValue()
    # Prevent parent views including the same 'click .addValue': 'addValue'
    # event listener to be triggered
    e.stopPropagation()

  updateAddValueButton: ->
    if @collection.length is 0 then @ui.addValueButton.show()
    else @ui.addValueButton.hide()

  dispatchCreationPartialClickEvents: (e)->
    { id } = e.currentTarget
    @customAdd.clickEvents[id]?({ view: @, work: @model.entity, e })
