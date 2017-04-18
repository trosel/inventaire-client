{ reportError } = requireProxy 'lib/reports'

# allow to pass a csle object so that we can pass whatever we want in tests
module.exports = (_, csle)->
  csle or= window.console

  log = (obj, label, stack)->
    # customizing console.log
    # unfortunatly, it makes the console loose the trace
    # of the real line and file the _.log function was called from
    # the trade-off might not be worthing it...
    if _.isString obj
      if label? then csle.log "[#{label}] #{obj}"
      else csle.log obj
    else
      # logging arguments as arrays for readability
      if _.isArguments obj then obj = _.toArray obj
      csle.log "===== #{label} =====" if label?
      csle.log obj
      csle.log "-----" if label?

    # Log a stack trace if stack option is true.
    # Testing console.trace? as not all browsers have this function
    if stack then console.trace?()

    return obj

  error = (err, label)->
    unless err instanceof Error
      err = new Error('invalid error object')
      err.context = err
      # Non-standard convention: 599 = client implementation error
      err.statusCode = 599
      reportError err
      throw err

    if err.hasBeenLogged then return
    err.hasBeenLogged = true

    originalErr = err

    userError = false
    serverError = false
    if err.statusCode?
      if /^4\d+$/.test err.statusCode then userError = true
      if /^5\d+$/.test err.statusCode then serverError = true

    # No need to report user errors to the server
    # This statusCode can be set from the client for this purpose
    # of not reporting the error to the server
    if userError
      return csle.warn "[#{err.statusCode}][#{label}] #{err.message}]"

    stackLines = err.stack.split('\n')
    report = [err.message, stackLines]

    if err.context? then report.push err.context

    report.push label

    # No need to report server error back to the server
    unless serverError then reportError err

    csle.error err, err.context

  # providing a custom warn as it might be used
  # by methods shared with the server
  warn = (args...)->
    csle.warn '/!\\'
    loggers.log.apply null, args
    return

  # inspection utils to log a label once a function is called
  spy = (res, label)->
    console.log label
    return res

  PartialLogger = (logger)-> (label)-> (obj)-> logger obj, label

  partialLoggers =
    Log: PartialLogger log
    Error: PartialLogger error
    Warn: PartialLogger warn
    Spy: PartialLogger spy
    ErrorRethrow: (label)->
      return fn = (err)->
        error err, label
        throw err

  loggers =
    log: log
    error: error
    warn: warn
    spy: spy

    logAllEvents: (obj, prefix='logAllEvents')->
      obj.on 'all', (event)->
        csle.log "[#{prefix}:#{event}]"
        csle.log arguments
        csle.log '---'

    logArgs: (args)->
      csle.log "[arguments]"
      csle.log args
      csle.log '---'

    logServer: (obj, label)->
      $.post app.API.tests, { obj, label }
      return obj

  proxied =
    trace: csle.trace.bind csle
    time: csle.time.bind csle
    timeEnd: csle.timeEnd.bind csle

  return _.extend loggers, partialLoggers, proxied
