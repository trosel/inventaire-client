Groups = require './collections/groups'
NetworkLayout = require './views/network_layout'
GroupBoard =  require './views/group_board'
initGroupHelpers = require './lib/group_helpers'
{ tabsData } = require './lib/network_tabs'
{ getDefaultTab, defaultToSearch } = require './lib/network_tabs'
fetchData = require 'lib/data/fetch'
{ parseQuery, buildPath } = require 'lib/location'

module.exports =
  define: (Redirect, app, Backbone, Marionette, $, _)->
    Router = Marionette.AppRouter.extend
      appRoutes:
        'network(/users)(/)': 'showFirstUsersLayout'
        'network(/users)(/search)(/)': 'showSearchUsers'
        'network/users/friends(/)': 'showFriends'
        'network/users/invite(/)': 'showInvite'
        'network/users/nearby(/)': 'showNearbyUsers'

        'network/groups(/)': 'showFirstGroupLayout'
        'network/groups/search(/)': 'showSearchGroups'
        'network/groups/user(/)': 'showUserGroups'
        'network/groups/create(/)': 'showCreateGroup'
        'network/groups/nearby(/)': 'showNearbyGroups'

        'network/groups/settings/:id(/)': 'showGroupBoard'
        # Redirect to 'network/groups/user'
        'network/groups/settings(/)': 'showUserGroups'

        # legacy redirections
        'network/friends(/)': 'showFriends'

        'g(roups)/:id(/)': 'showGroupInventory'
        # aliases
        'g(roups)(/)': 'showSearchGroups'
        'network/groups/:id(/)': 'showGroupInventory'

    app.addInitializer -> new Router { controller: API }

  initialize: ->
    app.commands.setHandlers
      'show:network': API.showNetworkLayout
      'show:group:board': showGroupBoardFromModel
      'show:group:user': API.showUserGroups
      'show:group:create': API.showCreateGroup
      'show:users:search': API.showSearchUsers
      'show:users:nearby': API.showNearbyUsers

    app.reqres.setHandlers
      'get:network:counters': networkCounters

    fetchData
      name: 'groups'
      Collection: Groups
      condition: app.user.loggedIn

    app.request 'wait:for', 'user'
    .then initGroupHelpers
    .then initRequestsCollectionsEvent.bind(@)

initRequestsCollectionsEvent = ->
  if app.user.loggedIn
    app.request 'waitForNetwork'
    .then -> app.vent.trigger 'network:requests:update'

API =
  showFirstUsersLayout: ->
    app.request 'wait:for', 'relations'
    .then ->
      if defaultToSearch.users() then API.showSearchUsers()
      else API.showFriends()

  # qs stands for query string
  showSearchUsers: (qs)-> API.showNetworkLayout 'searchUsers', qs
  showFriends: -> API.showNetworkLayout 'friends'
  showInvite: -> API.showNetworkLayout 'invite'
  showNearbyUsers: (qs)-> API.showNetworkLayout 'nearbyUsers', qs

  showFirstGroupLayout: ->
    app.request 'wait:for', 'groups'
    .then ->
      if defaultToSearch.groups() then API.showSearchGroups()
      else API.showUserGroups()

  showSearchGroups: (qs)-> API.showNetworkLayout 'searchGroups', qs
  showUserGroups: -> API.showNetworkLayout 'userGroups'
  showCreateGroup: -> API.showNetworkLayout 'createGroup'
  showNearbyGroups: (qs)-> API.showNetworkLayout 'nearbyGroups', qs

  showNetworkLayout: (tab, qs)->
    tab or= getDefaultTab.general()
    { path } = tabsData.all[tab]

    if _.isNonEmptyString(qs) then query = parseQuery qs
    # Allow to directly pass a query object instead of a query string
    else if _.isPlainObject(qs) then query = qs
    else query = {}

    if app.request 'require:loggedIn', buildPath(path, query)
      app.layout.main.show new NetworkLayout { tab, query }

  showGroupBoard: (slug)->
    app.request 'get:group:model', slug
    .then showGroupBoardFromModel
    .catch (err)->
      _.error err, 'get:group:model err'
      app.execute 'show:error:missing'

  showGroupSearch: (name)-> API.showSearchGroups "q=#{name}"
  showGroupInventory: (id)-> app.execute 'show:inventory:group:byId', id

showGroupBoardFromModel = (model)->
  if model.mainUserIsMember()
    model.beforeShow()
    app.layout.main.show new GroupBoard { model, standalone: true }
    app.navigateFromModel model, 'boardPathname'
  else
    # if the user isnt a member, redirect to the group inventory
    app.execute 'show:inventory:group', model

networkCounters = ->
  # TODO: introduce a 'read' flag on the relation document to stop counting
  # requests that were already seen.
  friendsRequestsCount = app.relations.otherRequested.length
  groupsRequestsCount = getGroupsRequestsCount()
  return counters =
    friendsRequestsCount: counterUnlessZero friendsRequestsCount
    groupsRequestsCount: counterUnlessZero groupsRequestsCount
    total: counterUnlessZero(friendsRequestsCount + groupsRequestsCount)

getGroupsRequestsCount = ->
  { groups } = app
  mainUserInvitationsCount = groups?.mainUserInvited.length or 0
  otherUsersRequestsCount = groups?.otherUsersRequestsCount() or 0
  return mainUserInvitationsCount + otherUsersRequestsCount

counterUnlessZero = (count)->
  if count is 0 then return
  else return count
