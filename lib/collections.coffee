#lessonId
#lessonCode
#userId
#teacherId
#message
#comments: NeedHelpComments
#timestamp
#solved
@NeedHelp = new Mongo.Collection 'needHelp',
  transform: (doc) ->
    if Meteor.isClient
      doc.lesson = JSLessonsList._collection.findOne { id: doc.lessonId }

    doc.comments = NeedHelpComments.find({ needHelpId: doc._id }, { sort: { timestamp: 1 } })
    doc.user = Meteor.users.findOne doc.userId
    return doc

#needHelpId: String
#text: String
#userId: String
#username: String
#timestamp: Date.now()
#lang: String
#isRead: Boolean
@NeedHelpComments = new Mongo.Collection 'needHelpComments'

#senderId
#senderUsername
#receiverId
#receiverUsername
#text
#timestamp
#isRead
@Messages = new Mongo.Collection('messages')

#READ ONLY - senders list for messages
@SendersList = new Mongo.Collection('sendersList')

# Meteor.users
# ============:
# lastLesson: Object
# points: Number
# profile: Object
# roles: Object
# status: Object
# username: String
# lessons {
#  lessonId: {
#    id: String
#    changedBy: String (userId)
#    code: String
#    success: Boolean
#    pointsAdded: Boolean
#    points: Number
#    timestamp: Number
#    exercises:
#      exerciseId: {
#        id: String
#        changedBy: String (userId)
#        code: String
#        success: Boolean
#        pointsAdded: Boolean
#        points: Number
#        timestamp: Number
#      }
#    }
#  }
# settings: {
#  emailNotifications: {
#   sendStudyGroupsActivity: 'turn-off'|'daily'|'weekly'|'monthly'
#  }
# }
#}

#{
#  id: String
#  userId: String
#  changedBy: String (userId)
#  code: String
#  success: Boolean
#  pointsAdded: Boolean
#  points: Number
#  timestamp: Number
#  exercises: {
#    id: String
#    changedBy: String (userId)
#    code: String
#    success: Boolean
#    pointsAdded: Boolean
#    points: Number
#    timestamp: Number
#  }
#}
@UserHTMLLessons = new Mongo.Collection 'userHTMLLessons'
#UserCSSLessons may differ from UserHTMLLessons in the future
@UserCSSLessons = new Mongo.Collection 'userCSSLessons'
@UserProgrammingChallengeLessons = new Mongo.Collection 'userProgrammingChallengeLessons'

#title: String
#description: String
#type: String - HTML|CSS|JavaScrit|Web|whatever...
#timestamp: Number
#updatedAt: Number (timestamp)
#updatedBy: String (userId)
@Homework = new Mongo.Collection 'homework'

#studyGroupId: String
#homeworkId: String
#userId: String
#title: String - store homework title so we don't need to make joins
#code: String
#success: Optional Boolean
#timestamp: Number
#updatedAt: Optional Number
#comments: [
#  {
#    userId: String
#    message: String
#    timestamp: Number
#  }
#]
@StudentHomework = new Mongo.Collection 'studentHomework'

#{
#  title: String
#  topics: String
#  studentsCount: Number
#  description: String
#  isPublic: Boolean
#  userId: String
#  userIds: [ String ]
#  curriculumId: String
#  homeworkIds: [ String ]
#}
@StudyGroups = new Mongo.Collection 'studyGroups'

StudyGroups.helpers
  isAMember: (userId) ->
    @userIds?.indexOf(userId) != -1
  messages: ->
    StudyGroupMessages.find({ studyGroupId: @_id }, { sort: { timestamp: 1 } })
  homework: ->
    homeworkArr = []
    if @homeworkIds
      #homeworks sorted according to position in homeworkIds
      @homeworkIds.forEach (homeworkId) ->
        homeworkArr.push Homework.findOne({ _id: homeworkId })
    return homeworkArr

#studyGroupId: String
#text: String
#userId: String
#timestamp: Number
#isReadBy: [ { userId: String} ]
@StudyGroupMessages = new Mongo.Collection 'studyGroupMessages',
  transform: (doc) ->
    doc.user = Meteor.users.findOne doc.userId
    return doc

#title: String
#text: String
#createdBy: String (userId)
#timestamp: Number
@StudyGroupCurriculums = new Mongo.Collection 'studyGroupCurriculums'

@Slides = new Mongo.Collection('slides')

# {
#  type: String (html,js)
#  code: String
#}
@Code = new Mongo.Collection('code')
