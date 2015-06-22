Entity = require './entity'

module.exports = Entity.extend
  prefix: 'isbn'
  initialize: ->
    @initLazySave()
    @findAPicture()

    # already normalized as arriving from google books data
    @id = @uri = @get 'id'
    pathname = "/entity/#{@id}"

    if title = @get 'title'
      pathname += "/" + _.softEncodeURI(title)

    @set
      pathname: pathname
      domain: 'isbn'

  findAPicture: ->
    pictures = @get 'pictures'
    unless _.isEmpty pictures
      @set 'pictures', pictures.map(app.lib.books.uncurl)
