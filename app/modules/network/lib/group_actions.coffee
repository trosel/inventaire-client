error_ = require 'lib/error'

module.exports =
  inviteUser: (user)->
    return @action 'invite', user.id
    .then @updateInvited.bind(@, user)
    # let views catch the error

  updateInvited: (user)->
    @push 'invited',
      user: user.id
      invitor: app.user.id
      timestamp: Date.now()
    @triggeredListChange()
    triggerUserChange user

  acceptInvitation: ->
    @moveMembership app.user, 'invited', 'members'

    return @action 'accept'
    .catch @revertMove.bind(@, app.user, 'invited', 'members')

  declineInvitation: ->
    @moveMembership app.user, 'invited', 'declined'

    return @action 'decline'
    .catch @revertMove.bind(@, app.user, 'invited', 'declined')

  requestToJoin: ->
    # create membership doc in the requested list
    @push 'requested',
      user: app.user.id
      timestamp: Date.now()

    @triggeredListChange()

    return @action 'request'
    .catch @revertMove.bind(@, app.user, null, 'requested')

  cancelRequest: ->
    @moveMembership app.user, 'requested', 'tmp'
    return @action 'cancel-request'
    .catch @revertMove.bind(@, app.user, 'requested', 'tmp')

  acceptRequest: (user)->
    @moveMembership user, 'requested', 'members'
    return @action 'accept-request', user.id
    .catch @revertMove.bind(@, user, 'requested', 'members')

  refuseRequest: (user)->
    @moveMembership user, 'requested', 'tmp'
    return @action 'refuse-request', user.id
    .catch @revertMove.bind(@, user, 'requested', 'tmp')

  makeAdmin: (user)->
    @moveMembership user, 'members', 'admins'
    triggerUserChange user
    return @action 'make-admin', user.id
    .catch @revertMove.bind(@, user, 'members', 'admins')

  kick: (user)->
    @moveMembership user, 'members', 'tmp'
    return @action 'kick', user.id
    .catch @revertMove.bind(@, user, 'members', 'tmp')

  leave: ->
    initialCategory = if @mainUserIsAdmin() then 'admins' else 'members'
    @moveMembership app.user, initialCategory, 'tmp'
    return @action 'leave'
    .catch @revertMove.bind(@, app.user, initialCategory, 'tmp')

  action: (action, userId)->
    return _.preq.put app.API.groups.base,
      action: action
      group: @id
      # requiered only for actions implying an other user
      user: userId
    .tap @_postActionHooks.bind(@, action)

  _postActionHooks: (action)->
    @trigger "action:#{action}"
    app.vent.trigger 'network:requests:update'

  revertMove: (user, previousCategory, newCategory, err)->
    @moveMembership user, newCategory, previousCategory
    triggerUserChange user
    throw err

  # moving membership object from previousCategory to newCategory
  moveMembership: (user, previousCategory, newCategory)->
    membership = @findMembership previousCategory, user
    unless membership? then throw error_.new 'membership not found', arguments

    @without previousCategory, membership
    # let the possibility to just destroy the doc
    # by letting newCategory undefined
    if newCategory? then @push newCategory, membership

    @triggeredListChange()

    # Trigger after the lists where updated
    # so that groups filtered collections can correctly re-filter
    if user.isMainUser then app.vent.trigger 'group:main:user:move'

  triggeredListChange: ->
    # avoid using an event name starting by "change:"
    # as Backbone FilteredCollection react on those
    @trigger 'list:change'
    @trigger 'list:change:after'

triggerUserChange = (user)->
  trigger = -> user.trigger 'group:user:change'
  # delay the event to let the time to the debounced recalculateAllLists to run
  setTimeout trigger, 100
