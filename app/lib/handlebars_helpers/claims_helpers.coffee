entityValue = require 'modules/general/views/behaviors/templates/entity_value'
propertyValue = require 'modules/general/views/behaviors/templates/property_value'
{ SafeString, escapeExpression } = Handlebars

prop = (id)->
  if /^wdt:P\d+$/.test id then propertyValue { id }
  else propertyValue { id: "wdt:P#{id}" }

entity = (id, linkify, alt)->
  if id?
    unless typeof alt is 'string' then alt = ''
    app.execute 'uriLabel:update'
    alt = escapeExpression alt
    return entityValue { id, linkify, alt, label: alt }

module.exports =
  prop: prop
  entity: entity
  # handlebars pass a sometime confusing {data:, hash: object} as last argument
  # this method is used to make helpers less error-prone by removing this object
  neutralizeDataObject: (args)->
    last = _.last args
    if last?.hash? and last.data? then args[0...-1]
    else args

  getValuesTemplates: (valueArray, linkify)->
    # prevent any null value to sneak in
    _.compact valueArray
    .map (id)-> entity(id, linkify).trim()
    .join ', '

  labelString: (pid, omitLabel)->
    if omitLabel then '' else prop pid

  claimString: (label, values, inline)->
    text = "#{label} #{values}"
    unless inline then text += ' <br>'
    return new SafeString text
