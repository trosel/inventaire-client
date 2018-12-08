{ langs:activeLangs } = require 'lib/active_languages'

module.exports = (userLanguage)->
  # querystring parameters > other settings sources
  qsLang = app.request 'querystring:get', 'lang'
  lang = qsLang or userLanguage or _.getCookie('lang') or browserLocale()
  lang = _.shortLang lang
  if lang? and lang in activeLangs then return lang
  else return 'en'

# Adapted from: https://github.com/maxogden/browser-locale/blob/master/index.js
getBrowserLocalLang = ->
  # Latest versions of Chrome and Firefox set this correctly
  if  navigator.languages and navigator.languages.length then return navigator.languages[0]
  # IE only
  if navigator.userLanguage then return navigator.userLanguage
  # Latest versions of Chrome, Firefox, and Safari set this correctly
  return navigator.language
