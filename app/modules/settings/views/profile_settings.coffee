username_ = require 'modules/user/lib/username_tests'
email_ = require 'modules/user/lib/email_tests'
password_ = require 'modules/user/lib/password_tests'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'
behaviorsPlugin = require 'modules/general/plugins/behaviors'
{ languages: activeLanguages } = require 'lib/active_languages'
error_ = require 'lib/error'

module.exports = Marionette.ItemView.extend
  template: require './templates/profile_settings'
  className: 'profileSettings'
  behaviors:
    AlertBox: {}
    SuccessCheck: {}
    Loading: {}
    TogglePassword: {}

  ui:
    username: '#usernameField'
    email: '#emailField'
    currentPassword: '#currentPassword'
    newPassword: '#newPassword'
    passwords: '.password'
    passwordUpdater: '#passwordUpdater'
    languagePicker: '#languagePicker'
    bioTextarea: '#bio'

  initialize: ->
    _.extend @, behaviorsPlugin
    @listenTo @model, 'change:picture', @render
    @listenTo @model, 'change:position', @render

  serializeData: ->
    attrs = @model.toJSON()
    return _.extend attrs,
      usernamePicker: @usernamePickerData()
      emailPicker: @emailPickerData()
      languages: @languagesData()
      changePicture:
        classes: 'max-large-profilePic'
      hasPosition: @model.hasPosition()
      position: @model.getCoords()

  usernamePickerData: -> pickerData @model, 'username'
  emailPickerData: -> pickerData @model, 'email'

  languagesData: ->
    languages = _.deepClone activeLanguages
    currentLanguage = _.shortLang @model.get('language')
    languages[currentLanguage]?.selected = true
    return languages

  events:
    'click a#changePicture': 'changePicture'
    'click a#usernameButton': 'updateUsername'
    'click a#emailButton': 'updateEmail'
    'click a#emailConfirmationRequest': 'emailConfirmationRequest'
    'change select#languagePicker': 'changeLanguage'
    'click #saveBio': 'saveBio'
    'click a#updatePassword': 'updatePassword'
    'click #forgotPassword': -> app.execute 'show:forgot:password'
    'click #deleteAccount': 'askDeleteAccountConfirmation'
    'click #showPositionPicker': -> app.execute 'show:position:picker:main:user'

  # USERNAME
  updateUsername: ->
    username = @ui.username.val()
    Promise.try @testUsername.bind(@, username)
    .then =>
      # if the username update is just a change in case
      # it should be rejected because the username is already taken
      # which it will be given usernames concurrency is case insensitive
      if @usernameCaseChange username then return
      else return username_.verifyUsername username, '#usernameField'
    .then => @confirmUsernameChange username
    .catch forms_.catchAlert.bind(null, @)

  usernameCaseChange: (username)->
    username.toLowerCase() is @model.get('username').toLowerCase()

  testUsername: (username)->
    testAttribute 'username', username, username_

  confirmUsernameChange: (username)->
    action = @updateUserUsername.bind @, username
    @askConfirmation action,
      requestedUsername: username
      currentUsername: app.user.get 'username'
      usernameCaseChange: @usernameCaseChange username
      model: @model

  askConfirmation: (action, args)->
    { usernameCaseChange } = args
    app.execute 'ask:confirmation',
      confirmationText: _.i18n('username_change_confirmation', args)
      # no need to show the warning if it's just a case change
      warningText: _.i18n('username_change_warning')  unless usernameCaseChange
      action: action
      selector: '#usernameGroup'

  updateUserUsername: (username)->
    app.request 'user:update',
      attribute: 'username'
      value: username
      selector: '#usernameButton'

  # EMAIL

  updateEmail: ->
    email = @ui.email.val()
    Promise.try @testEmail.bind(@, email)
    .then @startLoading.bind(@, '#emailButton')
    .then email_.verifyAvailability.bind(null, email, '#emailField')
    .then @sendEmailRequest.bind(@, email)
    .then @showConfirmationEmailSuccessMessage.bind(@)
    .catch forms_.catchAlert.bind(null, @)
    .finally @hardStopLoading.bind(@)

  testEmail: (email)->
    testAttribute 'email', email, email_

  sendEmailRequest: (email)->
    _.preq.get app.API.auth.emailAvailability(email)
    .get 'email'
    .then @sendEmailChangeRequest

  sendEmailChangeRequest: (email)->
    app.request 'user:update',
      attribute: 'email'
      value: email
      selector: '#emailField'

  hardStopLoading: ->
    # triggering stopLoading wasnt working
    # temporary solution
    @$el.find('.loading').empty()

  # EMAIL CONFIRMATION
  emailConfirmationRequest: ->
    $('#notValidEmail').fadeOut()
    app.request 'email:confirmation:request'
    .then @showConfirmationEmailSuccessMessage

  showConfirmationEmailSuccessMessage: ->
    $('#confirmationEmailSent').fadeIn()
    $('#emailButton').once 'click', @hideConfirmationEmailSent

  hideConfirmationEmailSent: ->
    $('#confirmationEmailSent').fadeOut()

  # PASSWORD

  updatePassword: ->
    currentPassword = @ui.currentPassword.val()
    newPassword = @ui.newPassword.val()

    Promise.try -> password_.pass currentPassword, '#currentPasswordAlert'
    .then -> password_.pass newPassword, '#newPasswordAlert'
    .then @startLoading.bind(@, '#updatePassword')
    .then @confirmCurrentPassword.bind(@, currentPassword)
    .then @updateUserPassword.bind(@, currentPassword, newPassword)
    .then @ifViewIsIntact('passwordSuccessCheck')
    .catch @ifViewIsIntact('passwordFail')
    .catch forms_.catchAlert.bind(null, @)
    .finally @stopLoading.bind(@)

  confirmCurrentPassword: (currentPassword)->
    app.request 'password:confirmation', currentPassword
    .catch (err)->
      if err.statusCode is 401
        err = error_.new 'wrong password', 400
        err.selector = '#currentPasswordAlert'
        throw err
      else throw err

  updateUserPassword: (currentPassword, newPassword)->
    app.request 'password:update', currentPassword, newPassword

  passwordSuccessCheck: ->
    @ui.passwords.val('')
    @ui.passwordUpdater.trigger('check')

  passwordFail: (err)->
    @ui.passwordUpdater.trigger('fail')
    throw err

  # BIO
  saveBio: ->
    bio = @ui.bioTextarea.val()

    Promise.try validateBio.bind(null, bio)
    .then updateUserBio.bind(null, bio)
    .catch error_.Complete('#bio')
    .catch forms_.catchAlert.bind(null, @)

  # LANGUAGE
  changeLanguage: (e)->
    app.request 'user:update',
      attribute:'language'
      value: e.target.value
      selector: '#languagePicker'

  # PICTURE
  changePicture: require 'modules/user/lib/change_user_picture'

  # DELETE ACCOUNT
  askDeleteAccountConfirmation: ->
    args = { username: @model.get('username') }
    app.execute 'ask:confirmation',
      confirmationText: _.i18n('delete_account_confirmation', args)
      warningText: _.i18n 'cant_undo_warning'
      action: @model.deleteAccount.bind(@model)
      selector: '#usernameGroup'
      formAction: sendDeletionFeedback
      formLabel: "that would really help us if you could say a few words about why you're leaving:"
      formPlaceholder: "our love wasn't possible because"
      yes: 'delete your account'
      no: 'cancel'

validateBio = (bio)->
  if bio.length > 1000
    throw error_.new "the bio can't be longer than 1000 characters", { length: bio.length }

updateUserBio = (bio)->
  app.request 'user:update',
    attribute: 'bio'
    value: bio
    selector: '#bio'

sendDeletionFeedback = (message)->
  _.preq.post app.API.feedback,
    subject: '[account deletion]'
    message: message

testAttribute = (attribute, value, validator_)->
  selector = "##{attribute}Field"
  if value is app.user.get attribute
    # Non-standard convention: 499 = client user error
    err = error_.new "that's already your #{attribute}", 499
    err.selector = selector
    throw err
  else
    validator_.pass value, selector
    return value

pickerData = (model, attribute)->
  nameBase: attribute
  special: true
  field:
    value: model.get attribute
  button:
    text: _.i18n "change #{attribute}"
    classes: 'grey postfix'
