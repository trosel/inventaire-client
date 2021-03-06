{ defaultZoom } = require './config'
getCurrentPosition = require './navigator_position'
smartPreventDefault = require 'modules/general/lib/smart_prevent_default'
leafletLite = require './leaflet_lite'
{ buildPath } = require 'lib/location'

module.exports = map_ =
  draw: require './draw'
  getCurrentPosition: getCurrentPosition

  updateRoute: (root, lat, lng, zoom = defaultZoom)->
    # Keep only defined parameters in the route
    # Allow to pass a custom root to let it be used in multiple modules
    route = buildPath root, { lat, lng, zoom }
    app.navigate route, { preventScrollTop: true }

  updateRouteFromEvent: (root, e)->
    { lat, lng } = e.target.getCenter()
    { _zoom } = e.target
    map_.updateRoute root, lat, lng, _zoom

  updateMarker: (marker, coords)->
    unless coords?.lat? then return marker.remove()
    { lat, lng } = coords
    marker.setLatLng [ lat, lng ]

  showUsersOnMap: (map, users)->
    for user in _.forceArray users
      map_.showUserOnMap map, user

  showGroupsOnMap: (map, groups)->
    for group in _.forceArray groups
      showGroupOnMap map, group

  BoundFilter: (map)->
    bounds = map.getBounds()
    return filter = (model)->
      unless model.hasPosition() then return false
      point = model.getLatLng()
      return bounds.contains point

  # a, b MUST be { lat, lng } coords objects
  distanceBetween: (a, b)->
    _.types arguments, 'objects...'
    # return the distance in kilometers
    return leafletLite.distance(a, b) / 1000

  getBbox: (map)->
    { _southWest, _northEast } = map.getBounds()
    return [ _southWest.lng, _southWest.lat, _northEast.lng, _northEast.lat ]

  showUserOnMap: (map, user)->
    # Substitude the main user model to the one created from user document
    # so that updates on the main user model are correctly displayed,
    # and to avoid to display duplicates
    if user.id is app.user.id then user = app.user

    if user.hasPosition()
      marker = map.addMarker
        objectId: user.cid
        model: user
        markerType: 'user'

      # map.addMarker will return undefined if the marker was already added
      # which allows here to not re-add the event listerner
      if marker?
        # Expose the main user marker to make it easier to update
        # on user position change
        if user is app.user then map.mainUserMarker = marker

showGroupOnMap = (map, group)->
  if group.hasPosition()
    map.addMarker
      objectId: group.cid
      model: group
      markerType: 'group'
