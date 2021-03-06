module.exports = Backbone.Collection.extend
  model: require '../models/search'
  # deduplicating searches
  addNonExisting: (data)->
    { query, uri } = data
    model = if query then @where({ query })[0] else @where({ uri })[0]

    # create the model if not existing
    if model? then model.updateTimestamp()
    else model = @add data

    return model

  comparator: (model)-> -model.get('timestamp')

  initialize: ->
    data = localStorageProxy.getItem 'searches'
    if data?
      @add JSON.parse(data)

    # set a high debounce to give priority to everything else
    # as writing to the local storage is blocking the thread
    # and those aren't critical data
    @lazySave = _.debounce @save.bind(@), 3000
    # Models 'change' events are propagated to the collection by Backbone
    # see http://stackoverflow.com/a/9951424/3324977
    @on 'add remove change reset', @lazySave.bind(@)

  save: ->
    # Remove duplicates
    searches = _.uniq @toJSON(), (search)-> search.uri or search.query.trim().toLowerCase()
    # keep only track of the 10 last searches
    data = JSON.stringify searches[0..10]
    localStorageProxy.setItem 'searches', data

  findLastSearch: ->
    @sort()
    return @models[0]
