evaluate = (code) ->
  newIframe = document.getElementById('homework-iframe') || document.createElement('iframe')
  code = code.replace(/(<\/head>)/, "<base target=\"_parent\" />$1")
  newIframe.frameBorder = 0
  newIframe.width = '100%'
  newIframe.height = '300'
  newIframe.allowfullscreen = 'true'
  newIframe.webkitallowfullscreen = 'true'
  newIframe.name = 'homework-result-iframe'
  newIframe.id = 'homework-iframe'
  newIframe.srcdoc = code #srcdoc does not have problem with content origin policy
  #newIframe.src = 'data:text/html;charset=utf-8,' + encodeURI(code)
  homeworkResult = document.getElementById('homework-result')
  if homeworkResult.childNodes[0]
    homeworkResult.removeChild homeworkResult.childNodes[0]
  homeworkResult.appendChild(newIframe)

Template.studyGroupHomework.helpers
  editorConfig: ->
    hw = Template.instance().data.homework
    studentHomework = Template.instance().data.studentHomework
    return (editor) ->
      editor.setTheme('ace/theme/monokai')
      editor.getSession().setMode('ace/mode/html')
      editor.setShowPrintMargin(false)
      editor.getSession().setUseWrapMode(false)
      editor.getSession().setTabSize(2);

      if studentHomework
        editor.setValue studentHomework.code
      else
        editor.setValue """
          <!DOCTYPE html>
          <html>
            <head>
              <title>#{hw.title}</title>
            </head>
            <body>
              Do your homework here
            </body>
          </html>
        """
      editor.selection.clearSelection()
  isCurrent: ->
    Router.current().params.homeworkId is @_id
  showSaveAndSubmitButtons: ->
    return false unless Meteor.user()
    !@studentHomework?.success and Router.current().params.username == Meteor.user()?.username
  isCurrentUserInGroup: ->
    @studyGroup?.userIds?.indexOf(Meteor.userId()) != -1
  isHomeworkUser: ->
    @studentHomework?.userId == Meteor.userId()
  isReadComment: ->
    studentHw = StudentHomework.findOne @studentHomeworkId
    return @isReadBy.indexOf(studentHw.userId) != -1
  makeReadComment: ->
    if @isReadBy.indexOf(Meteor.userId()) is -1
      Meteor.call 'makeReadStudentHomeworkComments', @studentHomeworkId
  isCorrect: ->
    StudentHomework.findOne({ homeworkId: @_id })?.success
  canMarkAsCorrect: ->
    (@studentHomework and Meteor.user()?.username is 'elfoslav') or
      (@studentHomework and Meteor.userId() != @studentHomework.userId)
  showSaveHomeworkAlert: ->
    Meteor.userId() and @studyGroup?.userIds?.indexOf(Meteor.userId()) != -1 and
      !localStorage.hideSaveHomeworkAlert and
      Router.current().params.username == Meteor.user()?.username

Template.studyGroupHomework.events
  'click .mark-as-correct': (evt, tpl) ->
    evt.preventDefault()
    data =
      homeworkId: tpl.data.homework?._id
      username: Router.current().params.username
    Meteor.call 'markHomeworkAsCorrect', data, (err, result) ->
      if err
        bootbox.alert err.reason
        console.log err
  'click .mark-as-incorrect': (evt, tpl) ->
    evt.preventDefault()
    data =
      homeworkId: tpl.data.homework?._id
      username: Router.current().params.username
    Meteor.call 'markHomeworkAsIncorrect', data, (err, result) ->
      if err
        bootbox.alert err.reason
        console.log err
  'click .save-and-run': (evt, tpl) ->
    evt.preventDefault()
    data =
      studyGroupId: tpl.data.studyGroup?._id
      homeworkId: tpl.data.homework?._id
      code: ace.edit('html-editor').getValue()
    evaluate(data.code)
    Meteor.call 'saveStudentHomework', data, (err, result) ->
      if err
        bootbox.alert err.reason
        console.log err
      else
        Alerts.set('Successfuly saved', 'success')
        setTimeout ->
          App.initTextEditor('#homework-comments-textarea')
        , 100
  'click .submit-to-teacher': (evt, tpl) ->
    evt.preventDefault()
    data =
      studyGroupId: tpl.data.studyGroup?._id
      homeworkId: tpl.data.homework?._id
      code: ace.edit('html-editor').getValue()
    evaluate(data.code)
    Meteor.call 'submitStudentHomework', data, (err, result) ->
      if err
        bootbox.alert err.reason
        console.log err
      else
        bootbox.alert('Successfuly submitted. Your teacher will review your homework soon.')
        setTimeout ->
          App.initTextEditor('#homework-comments-textarea')
        , 100
  'click .run-the-code': (evt, tpl) ->
    evt.preventDefault()
    evaluate(ace.edit('html-editor').getValue())
  'submit .comment-form': (evt, tpl) ->
    evt.preventDefault()
    form = evt.target
    editor = tinyMCE.get()[0]
    comment = editor.getContent()
    editor.setContent('')
    form.reset()
    tpl.$('#comment-preview').html('')
    data =
      message: comment
      studentHomeworkId: tpl.data.studentHomework?._id
    if form.sendEmail
      data.sendEmail = form.sendEmail.checked
    Meteor.call 'saveStudentHomeworkComment', data, (err) ->
      if err
        bootbox.alert err.reason
        console.log err
        editor.setContent(comment)
  'click .enter-fullscreen-btn': (evt, tpl) ->
    evt.preventDefault()
    fullscreenHw = document.getElementById('fullscreen-homework')
    isEditorEnlarged = false
    if BigScreen.enabled
      BigScreen.toggle fullscreenHw, ->
        console.log('fulllscreen enabled')
        $(fullscreenHw).addClass('fullscreen-enabled')
        if $(fullscreenHw).hasClass('enlarged-editor')
          $(fullscreenHw).removeClass('enlarged-editor')
          isEditorEnlarged = true
        tpl.$('.col-editor').addClass('hidden')
        tpl.$('.col-result').removeClass('col-sm-4')
        tpl.$('.col-result .glyphicon-fullscreen')
          .removeClass('glyphicon-fullscreen')
          .addClass('glyphicon-resize-small')
        tpl.$('.enter-fullscreen-btn').attr('title','Exit fullscreen')
      , ->
        console.log('leaving fullscreen')
        $(fullscreenHw).removeClass('fullscreen-enabled')
        if isEditorEnlarged
          $(fullscreenHw).addClass('enlarged-editor')
        tpl.$('.col-editor').removeClass('hidden')
        tpl.$('.col-result').addClass('col-sm-4')
        tpl.$('.col-result .glyphicon-resize-small')
          .removeClass('glyphicon-resize-small')
          .addClass('glyphicon-fullscreen')
        tpl.$('.enter-fullscreen-btn').attr('title','Enter fullscreen')
  'click .toggle-editor': (evt, tpl) ->
    evt.preventDefault()
    $colEditor = tpl.$('#fullscreen-homework .col-editor')
    if $colEditor.hasClass('col-sm-5')
      #enlarge editor
      tpl.$('.assignment').addClass('hidden')
      $colEditor.removeClass('col-sm-5').addClass('col-sm-8')
      tpl.$('#fullscreen-homework').addClass('enlarged-editor')
      ace.edit('html-editor').resize()
      $('.toggle-editor .glyphicon').removeClass('glyphicon-resize-full')
        .addClass('glyphicon-resize-small')
    else
      #diminish editor
      tpl.$('.assignment').removeClass('hidden')
      $colEditor.removeClass('col-sm-8').addClass('col-sm-5')
      tpl.$('#fullscreen-homework').removeClass('enlarged-editor')
      ace.edit('html-editor').resize()
      $('.toggle-editor .glyphicon').removeClass('glyphicon-resize-small')
        .addClass('glyphicon-resize-full')
  'click .save-homework-alert .btn': (evt, tpl) ->
    localStorage.hideSaveHomeworkAlert = true
  'click .preview-comment': (evt, tpl) ->
    previewContent = tpl.$('#comment-preview').html()
    tpl.$('#comment-preview').html(tinyMCE.get()[0]?.getContent())
    unless previewContent
      $('html, body').animate({
        scrollTop: tpl.$("#preview-comment-scroll-here").offset().top
      }, 300)
