module.exports = Backbone.Collection.extend
  model: require '../models/property_value'
  initialize: (models, options)->
    { @entity, @property, @allowEntityCreation } = options

  addClaimsValues: (claims)->
    # accept both an array of claims values or a single claim value
    claims = _.forceArray claims
    for value in claims
      @addByValue value
    return

  addEmptyValue: ->
    @addByValue null

  addByValue: (value)->
    model = @add
      value: value
      property: @property
      allowEntityCreation: @allowEntityCreation
    model.entity = @entity
    return model
