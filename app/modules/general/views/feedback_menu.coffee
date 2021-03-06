behaviorsPlugin = require 'modules/general/plugins/behaviors'
{ contact } = require 'lib/urls'

module.exports = Marionette.ItemView.extend
  template: require './templates/feedback_menu'
  className: ->
    standalone = if @options.standalone then 'standalone' else ''
    return "feedback-menu #{standalone}"

  behaviors:
    Loading: {}
    SuccessCheck: {}
    ElasticTextarea: {}
    General: {}
    PreventDefault: {}

  initialize: ->
    _.extend @, behaviorsPlugin
    { @standalone } = @options

  serializeData: ->
    loggedIn: app.user.loggedIn
    user: app.user.toJSON()
    contact: contact
    subject: @options.subject
    standalone: @standalone

  ui:
    unknownUser: '.unknownUser'
    subject: '#subject'
    message: '#message'
    sendFeedback: '#sendFeedback'
    confirmation: '#confirmation'

  events:
    'click a#sendFeedback': 'sendFeedback'

  onShow: -> unless @standalone then app.execute 'modal:open'

  sendFeedback: ->
    @startLoading '#sendFeedback'

    @postFeedback()
    .then @confirm.bind(@)
    .catch @postFailed.bind(@)

  postFeedback: ->
    app.request 'post:feedback',
      subject: @ui.subject.val()
      uris: @options.uris
      message: @ui.message.val()
      unknownUser: @ui.unknownUser.val()

  confirm: ->
    @stopLoading '#sendFeedback'
    @ui.subject.val null
    @ui.message.val null
    @ui.confirmation.slideDown()

    if @standalone
      # simply hide the confirmation so that the user can still send a new feedback
      # and get a new confirmation for it
      @setTimeout @hideConfirmation.bind(@), 5000
    else
      @setTimeout app.Execute('modal:close'), 2000

  postFailed: ->
    @stopLoading '#sendFeedback'
    @fail 'feedback err'

  hideConfirmation: -> unless @isDestroyed then @ui.confirmation.slideUp()
