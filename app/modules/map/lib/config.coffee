module.exports =
  # Init once Leaflet was fetched
  init: ->
    L.Icon.Default.imagePath = '/public/images/map'
  tileUrl: 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}'
  settings:
    attribution: """
      Map data &copy; <a href='http://openstreetmap.org'>OpenStreetMap</a> contributors,
      <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>,
      Imagery © <a href="http://mapbox.com">Mapbox</a>"""
    minZoom: 2
    maxZoom: 18
    id: 'maxlatha.gd5jof9d'
    accessToken: 'pk.eyJ1IjoibWF4bGF0aGEiLCJhIjoiY2lldm9xdjFrMDBkMnN6a3NmY211MzQxcyJ9.a7_CBy6Xao-yF6f1cjsBNA'
    noWrap: true
  defaultZoom: 13
