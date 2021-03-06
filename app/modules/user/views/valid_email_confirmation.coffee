{ Check } = require 'modules/general/plugins/behaviors'

module.exports = Marionette.ItemView.extend
  className: 'validEmailConfirmation'
  template: require './templates/valid_email_confirmation'
  behaviors:
    Loading: {}
    General: {}
    SuccessCheck: {}

  events:
    'click .showHome, .showLoginRedirectSettings': -> app.execute 'modal:close'
    'click .showLoginRedirectSettings': 'showLoginRedirectSettings'
    'click #emailConfirmationRequest': 'emailConfirmationRequest'

  onShow: ->  app.execute 'modal:open'

  serializeData: ->
    validEmail: @options.validEmail
    loggedIn: app.user.loggedIn

  emailConfirmationRequest: ->
    @$el.trigger 'loading'
    app.request 'email:confirmation:request'
    .then Check.call(@, 'emailConfirmationRequest', app.Execute('modal:close'))
    .catch emailFail.bind(@)

  showLoginRedirectSettings: ->
    app.request 'show:login:redirect', 'settings/profile'

emailFail = -> @$el.trigger 'somethingWentWrong'
