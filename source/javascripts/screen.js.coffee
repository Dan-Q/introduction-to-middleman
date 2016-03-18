$ ->
  current_slide_number = $('body').data 'slide-number'

  firebase = if ($('body').data('firebase-url') || '') != '' then new Firebase($('body').data('firebase-url')) else false

  window.onpopstate = (e)->
    # user pressed back button, for example
    $('.slide').addClass 'hidden'
    current_slide_number = e.state.current_slide_number
    show_slide e.state.current_slide_number, false

  show_slide = (n, push_to_history = true)->
    $(".slide[data-slide-id=#{n}]").removeClass 'hidden'
    document.title = "Introduction To Middleman | #{$(".slide[data-slide-id=#{n}] .slide-contents").data('title')}"
    if push_to_history
      history.pushState { current_slide_number: n},
                        document.title
                        "slide-#{n}.html"
    # update Firebase, if used
    if firebase && $('body').data('view') == 'slide' then firebase.child('slide').set(n)

  show_current_slide = ->
    $('.slide').addClass 'hidden'
    if $(".slide[data-slide-id=#{current_slide_number}]").length > 0
      # new slide already loaded
      show_slide(current_slide_number)
    else
      # load new slide
      $('body').append "<div class=\"hidden slide\" data-slide-id=\"#{current_slide_number}\"></div>"
      $(".slide[data-slide-id=#{current_slide_number}]").load "slide-#{current_slide_number}.html .slide-contents", (responseText, textStatus, jqXHR)->
        if textStatus == 'success'
          # slide loaded: show it
          show_slide(current_slide_number)
        else
          # 404: revert to first slide (because we've probably reached the end)
          $(".slide[data-slide-id=#{current_slide_number}]").remove()
          current_slide_number = 1
          show_current_slide()

  next_slide = ->
    # next slide
    current_slide_number++
    show_current_slide()

  prev_slide = ->
    # previous slide
    if(current_slide_number > 1)
      current_slide_number--
      show_current_slide()

  if firebase
    if $('body').data('view') == 'slide'
      # Push initial state to Firebase
      firebase.child('slide').set(current_slide_number)

      # Firebase control
      firebase.child('cmd').on 'value', (data)->
        cmd = data.val()
        if cmd == 'next_slide' then next_slide()
        if cmd == 'prev_slide' then prev_slide()
        firebase.child('cmd').remove()

    # Control mode
    if $('body').data('view') == 'control'
      $('#control a').on 'click', ->
        firebase.child('cmd').set($(this).attr('href'))
        false

    # Follow mode
    if $('body').data('view') == 'follow'
      firebase.child('slide').on 'value', (data)->
        $('#follow > *').removeClass('current').filter(".slide-#{data.val()}").addClass('current')

  $('body').on 'keydown', (e)->
    if e.keyCode == 13 || e.keyCode == 32 || e.keyCode == 39 # 13 = enter, 32 = space, 37 = right arrow
      next_slide()
    else if e.keyCode == 37 # 37 = left arrow
      prev_slide()

  next_slide() if current_slide_number == 0
