{ SafeString, escapeExpression } = Handlebars
icons_ = require './icons'
wdLang = require 'wikidata-lang'
commons_ = require 'lib/wikimedia/commons'
linkify_ = require './linkify'
platforms_ = require './platforms'
{ prop, entity, neutralizeDataObject, getValuesTemplates, labelString, claimString } = require './claims_helpers'

module.exports = API =
  prop: prop
  entity: entity
  claim: (args...)->
    # entityLink: set to true to link to the entity layout (work, author, etc),
    # the alternative being to link to a claim_layout
    [ claims, prop, entityLink, omitLabel, inline ] = neutralizeDataObject args
    if claims?[prop]?[0]?
      label = labelString prop, omitLabel
      values = getValuesTemplates claims[prop], entityLink, prop
      return claimString label, values, inline

  timeClaim: (args...)->
    [ claims, prop, format, omitLabel, inline ] = neutralizeDataObject args
    # default to 'year' and override handlebars data object when args.length is 3
    format or= 'year'
    if claims?[prop]?[0]?
      values = claims[prop]
        .map (unixTime)->
          time = new Date(unixTime)
          switch format
            when 'year' then return time.getUTCFullYear()
            else return
        .filter isntNaN
      label = labelString prop, omitLabel
      values = _.uniq(values).join(" #{_.i18n('or')} ")
      return claimString label, values, inline

  imageClaim: (claims, prop, omitLabel, inline, data)->
    if claims?[prop]?[0]?
      file = claims[prop][0]
      src = commons_.thumbnail file, 200
      propClass = prop.replace ':', '-'
      return new SafeString "<img class='image-claim #{propClass}' src='#{src}'>"

  stringClaim: (args...)->
    [ claims, prop, omitLabel, inline ] = neutralizeDataObject args
    if claims?[prop]?[0]?
      label = labelString prop, omitLabel
      values = escapeExpression claims[prop]?.join(', ')
      return claimString label, values, inline

  urlClaim: (args...)->
    [ claims, prop ] = neutralizeDataObject args
    firstUrl = claims?[prop]?[0]
    if firstUrl?
      label = icons_.icon 'link'
      cleanedUrl = removeTailingSlash dropProtocol(firstUrl)
      values = linkify_ cleanedUrl, firstUrl, 'link website'
      return claimString label, values

  platformClaim: (args...)->
    [ claims, prop ] = neutralizeDataObject args
    firstPlatformId = claims?[prop]?[0]
    if firstPlatformId?
      platform = platforms_[prop]
      icon = icons_.icon platform.icon
      escapedText = escapeExpression platform.text(firstPlatformId)
      text = icon + '<span>' + escapedText + '</span>'
      url = platform.url firstPlatformId
      values = linkify_ text, url, 'link social-network'
      return claimString '', values

  entityRemoteHref: (uri)->
    [ prefix, id ] = uri.split ':'
    switch prefix
      when 'wd' then "https://www.wikidata.org/entity/#{id}"
      else API.entityLocalHref uri

  entityLocalHref: (uri)-> "/entity/#{uri}"
  claimLocalHref: (propertyUri, entityUri)-> "/entity/#{propertyUri}-#{entityUri}"

  multiTypeValue: (value)->
    switch _.typeOf(value)
      when 'string'
        if _.isEntityUri value then entity value, true
        else escapeExpression value
      when 'array' then value.map(API.multiTypeValue).join('')
      when 'object' then escapeExpression JSON.stringify(value)

  entityFromLang: (lang)->
    langEntityId = wdLang.byCode[lang]?.wd
    if langEntityId? then new SafeString entity("wd:#{langEntityId}", false)
    else lang

dropProtocol = (url)-> url.replace /^(https?:)?\/\//, ''
removeTailingSlash = (url)-> url.replace /\/$/, ''
isntNaN = (value)-> not _.isNaN(value)
