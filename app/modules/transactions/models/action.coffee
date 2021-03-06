module.exports = Backbone.Model.extend
  initialize: ->
    @action = @get('action')
    @userReady = false

  serializeData: ->
    _.extend @toJSON(),
      icon: @icon()
      context: @context(true)
      userReady: @userReady

  icon: ->
    switch @action
      when 'requested' then 'envelope'
      when 'accepted' then 'check'
      when 'confirmed' then 'sign-in'
      when 'declined', 'cancelled' then 'times'
      when 'returned' then 'check'
      else _.warn @, 'unknown action', true

  context: (withLink)-> @userAction @findUser(), withLink
  findUser: ->
    if @action in actorCanBeBoth then return @findCancelActor()
    if @transaction?.owner?
      if @transaction.mainUserIsOwner
        if @action in ownerActions then 'main' else 'other'
      else
        if @action in ownerActions then 'other' else 'main'

  findCancelActor: ->
    actorIsOwner = @get('actor') is 'owner'
    { mainUserIsOwner } = @transaction
    if mainUserIsOwner
      if actorIsOwner then 'main' else 'other'
    else
      if actorIsOwner then 'other' else 'main'

  userAction: (user, withLink)->
    if user?
      @userReady = true
      _.i18n "#{user}_user_#{@action}", { username: @otherUsername(withLink) }

  otherUsername: (withLink)->
    otherUser = @transaction?.otherUser()
    # injecting an html anchor instead of just a username string
    if otherUser?
      [ username, pathname ] = otherUser.gets 'username', 'pathname'
      if withLink then "<a href='#{pathname}' class='username'>#{username}</a>"
      else username

actorCanBeBoth = ['cancelled']

ownerActions = [
  'accepted'
  'declined'
  'returned'
]
