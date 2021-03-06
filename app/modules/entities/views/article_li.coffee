module.exports = Marionette.ItemView.extend
  template: require './templates/article_li'
  className: 'articleLi'
  serializeData: ->
    attrs = @model.toJSON()
    _.extend attrs,
      href: @getHref()
      hasDate: @hasDate()
      hideRefreshButton: true

  getHref: ->
    DOI = @model.get('claims.wdt:P356.0')
    if DOI? then "https://dx.doi.org/#{DOI}"

  hasDate: -> @model.get('claims.wdt:P577.0')?
