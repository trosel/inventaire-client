forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'

module.exports =

  createGroup: (data)->
    { name, description, searchable, position } = data
    { groups } = app

    _.preq.post app.API.groups.base,
      action: 'create'
      name: name
      description: description
      searchable: searchable
      position: position
    .then groups.add.bind(groups)
    .then _.Log('group')
    .catch error_.Complete('#createGroup')

  validateName: (name, selector)->
    forms_.pass
      value: name
      tests: groupNameTests
      selector: selector
    return

  validateDescription: (description, selector)->
    forms_.pass
      value: description
      tests: groupDescriptionTests
      selector: selector
    return

groupNameTests =
  "group name can't be longer than 60 characters": (name)->
    name.length > 60

groupDescriptionTests =
  "group description can't be longer than 5000 characters": (description)->
    description.length > 5000
