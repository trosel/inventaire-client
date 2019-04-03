Items = require 'modules/inventory/collections/items'
ItemsCascade = require 'modules/inventory/views/items_cascade'

module.exports = (params)->
  { region, allowMore, showDistance } = params
  params.collection = collection = new Items

  # Use an object to store the flag so that it can be modified
  # by functions the object is passed to
  params.moreData = moreData = { status: true }
  hasMore = -> moreData.status
  fetchMore = FetchMore params

  fetchMore()
  .then ->
    region.show new ItemsCascade
      collection: collection
      # if not allowMore, let ItemsList set the default values
      fetchMore: if allowMore then fetchMore
      hasMore: if allowMore then hasMore
      showDistance: showDistance

FetchMore = (params)->
  { request, collection, moreData, fallback } = params
  # Avoiding fetching more items several times at a time
  # as it will just return the same items, given that it will pass
  # the same arguments.
  # Known case: when the view is locked on the infiniteScroll trigger
  busy = false
  fetchMore = ->
    done = moreData.total? and collection.length >= moreData.total
    if busy or done then return Promise.resolve()

    busy = true
    params.offset = collection.length
    app.request request, params
    .then (res)->
      moreData.total = res.total
      moreData.continue = res.continue
      # Display the inventory welcome screen when appropriate
      if res.total is 0 and fallback? then fallback()
    .catch catch404(fallback)
    .finally -> busy = false

  catch404 = (fallback)-> (err)->
    if err.statusCode is 404
      moreData.status = false
      _.warn 'no more items to show'
      if fallback? then fallback()
    else
      throw err

  return fetchMore
