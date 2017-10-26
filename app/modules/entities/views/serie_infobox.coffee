AuthorsPreviewList = require 'modules/entities/views/authors_preview_list'

module.exports = Marionette.LayoutView.extend
  template: require './templates/serie_infobox'
  behaviors:
    EntitiesCommons: {}

  regions:
    authors: '.authors'

  initialize: ->
    @waitForAuthors = @model.getAuthorsModels()
    @model.getWikipediaExtract()

  modelEvents:
    # The description might be overriden by a Wikipedia extract arrive later
    'change:description': 'render'

  serializeData: -> _.extend @model.toJSON(), { standalone: @options.standalone }

  onRender: ->
    @waitForAuthors.then @showAuthorsPreviewList.bind(@)

  showAuthorsPreviewList: (authors)->
    if authors.length is 0 then return

    collection = new Backbone.Collection authors
    @authors.show new AuthorsPreviewList { collection }
