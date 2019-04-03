forms_ = require 'modules/general/lib/forms'
relationsActions = require 'modules/users/plugins/relations_actions'
{ buildPath } = require 'lib/location'

module.exports = Marionette.ItemView.extend
  template: require './templates/user_profile'
  events:
    'click #editBio': 'editBio'
    'click #saveBio': 'saveBio'
    'click #cancelBio': 'cancelBio'
    'click a#changePicture': 'changePicture'
    'click a.showGroup': 'showGroup'
    'click #showPositionPicker': -> app.execute 'show:position:picker:main:user'
    'click .showUserOnMap': 'showUserOnMap'

  behaviors:
    AlertBox: {}
    SuccessCheck: {}
    Loading: {}
    ElasticTextarea: {}
    PreventDefault: {}
    Unselect: {}

  ui:
    bio: '.bio'
    bioText: 'textarea.bio'

  initialize: ->
    { @isMainUser } = @model
    @listenTo @model, 'change', @render.bind(@)
    @initPlugin()

  initPlugin: ->
    relationsActions.call @

  serializeData: ->
    # Show private items in items counts if available
    nonPrivate = false
    _.extend @model.serializeData(nonPrivate),
      onUserProfile: true
      loggedIn: app.user.loggedIn
      commonGroups: @commonGroupsData()
      visitedGroups: @visitedGroupsData()
      distance: @model.distanceFromMainUser
      rss: @model.getRss()
      positionUrl: @getPositionUrl()

  onShow: ->
    @makeRoom()

    # take care of destroying this view even on events out of this
    # view scope (ex: clicking the home button)
    @listenTo app.vent, 'inventory:change', @destroyOnInventoryChange

  destroyOnInventoryChange: (username)->
    unless username is @model.get('username')
      @$el.slideUp 500, @destroy.bind(@)

  onDestroy: ->
    @giveRoomBack()

  makeRoom: -> $('#one').addClass 'notEmpty'
  giveRoomBack: -> $('#one').removeClass 'notEmpty'

  editBio: -> @ui.bio.toggle()
  cancelBio: -> @ui.bio.toggle()
  saveBio: ->
    bio = @ui.bioText.val()

    Promise.try @testBio.bind(null, bio)
    .then @updateUserBio.bind(null, bio)
    .then @ui.bio.toggle.bind(@ui.bio)
    .catch forms_.catchAlert.bind(null, @)

  testBio: (bio)->
    if bio.length > 1000
      formatErr new Error("the bio can't be longer than 1000 characters")

  updateUserBio: (bio)->
    app.request 'user:update',
      attribute: 'bio'
      value: bio
      selector: '#usernameButton'
    .catch formatErr

  changePicture: require 'modules/user/lib/change_user_picture'

  commonGroupsData: -> @_requestGroupData 'get:groups:common'
  visitedGroupsData: -> @_requestGroupData 'get:groups:others:visited'

  _requestGroupData: (request)->
    if @isMainUser then return
    groups = app.request(request, @model).map parseGroupData
    if groups.length > 0 then return groups else return null

  showGroup: (e)->
    unless _.isOpenedOutside e
      groupId = e.currentTarget.attributes['data-id'].value
      app.execute 'show:inventory:group:byId', groupId

  getPositionUrl: ->
    unless @model.distanceFromMainUser? then return
    [ lat, lng ] = @model.get 'position'
    return buildPath '/network/users/nearby', { lat, lng }

  showUserOnMap: (e)->
    if _.isOpenedOutside(e) then return
    unless @model.distanceFromMainUser? then return
    [ lat, lng ] = @model.get 'position'
    app.execute 'show:users:nearby', { lat, lng }

parseGroupData = (group)->
  id: group.id
  name: group.get('name')
  pathname: group.get('pathname')

formatErr = (err)->
  err.selector = 'textarea.bio'
  throw err
