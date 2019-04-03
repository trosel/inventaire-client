# dependencies: behaviorsPlugin, paginationPlugin

Masonry = require 'masonry-layout'
screen_ = require 'lib/screen'
# to keep in sync with _items_list.scss $itemCardBaseWidth variable
itemWidth = 230

module.exports = (containerSelector, itemSelector, minWidth = 500)->
  # MUST be called with the View it extends as context
  unless _.isView(@)
    throw new Error('should be called with a view as context')

  initMasonry = ->
    $itemsCascade = $('.itemsCascade')

    # It often happen that after triggering a masonry view
    # the user triggered an other view so that when images are ready
    # there is no more masonry to do, thus this check
    if $itemsCascade.length is 0 then return

    itemsPerLine = $itemsCascade.width() / itemWidth
    tooFewItems = @collection.length < itemsPerLine

    unless screen_.isSmall(minWidth) or tooFewItems
      positionBefore = window.scrollY
      container = document.querySelector containerSelector
      $(containerSelector).css 'opacity', 0
      new Masonry container,
        itemSelector: itemSelector
        isFitWidth: true
        isResizable: true
        isAnimated: true
        gutter: 5

      screen_.scrollHeight positionBefore, 0
      $(containerSelector).css 'opacity', 1

  refresh = ->
    require 'imagesloaded'
    # wait for images to be loaded
    $(containerSelector).imagesLoaded initMasonry.bind(@)

  @lazyMasonryRefresh = _.debounce refresh.bind(@), 200

  return
