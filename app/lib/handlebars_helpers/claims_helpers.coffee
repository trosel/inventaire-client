entityValue = require 'modules/general/views/behaviors/templates/entity_value'
propertyValue = require 'modules/general/views/behaviors/templates/property_value'
{ SafeString, escapeExpression } = Handlebars
wdk = require 'lib/wikidata-sdk'
error_ = require 'lib/error'

prop = (id)->
  # Be more restrictive on the input to be able to use it in SafeStrings
  if /^wdt:P\d+$/.test id then propertyValue { id }
  else if wdk.isWikidataPropertyId(id) then propertyValue { id: "wdt:P#{id}" }

entity = (id, entityLink, alt, property)->
  # Be restricting on the input to be able to use it in SafeStrings
  unless wdk.isWikidataItemId(id) or _.isEntityUri(id)
    throw error_.new 'invalid entity id', 500, { id }

  unless typeof alt is 'string' then alt = ''
  app.execute 'uriLabel:update'
  alt = escapeExpression alt
  return entityValue { id, entityLink, property, alt, label: alt }

module.exports =
  prop: prop
  entity: entity
  # handlebars pass a sometime confusing {data:, hash: object} as last argument
  # this method is used to make helpers less error-prone by removing this object
  neutralizeDataObject: (args)->
    last = _.last args
    if last?.hash? and last.data? then args[0...-1]
    else args

  getValuesTemplates: (valueArray, entityLink, property)->
    # prevent any null value to sneak in
    _.compact valueArray
    .map (id)-> entity(id, entityLink, null, property).trim()
    .join ', '

  labelString: (pid, omitLabel)->
    if omitLabel then '' else prop pid

  claimString: (label, values, inline)->
    text = "#{label} #{values}"
    unless inline then text += ' <br>'
    return new SafeString text
