behaviorsPlugin = require 'modules/general/plugins/behaviors'
{ apiDoc } = require 'lib/urls'
{ host, protocol } = window.location

module.exports = Marionette.ItemView.extend
  template: require './templates/labs_settings'
  className: 'labsSettings'
  behaviors:
    AlertBox: {}
    SuccessCheck: {}
    Loading: {}

  initialize: -> _.extend @, behaviorsPlugin

  serializeData: ->
    username = app.user.get 'username'
    return {
      apiDoc: apiDoc
      inventoryEndpoint: "/api/items?action=by-users&users=#{app.user.id}&limit=100000"
      userEndpoint: '/api/user'
      curlBase: "$ curl #{protocol}//#{username}:yourpassword@#{host}"
    }
