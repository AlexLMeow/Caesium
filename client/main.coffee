###
/client/main.coffee

subscriptions and others
###

@usrsubs = Meteor.subscribe "userData" 			# subscribe to user's other fields
@schedsubs = Meteor.subscribe "userSchedules" 	
@tasksubs = Meteor.subscribe "userTasks"



Meteor.startup () ->

	Session.set "timer-1s", Date.now()
	# run 1 second timer
	Meteor.setInterval (() -> Session.set "timer-1s", Date.now()), 1000

	# set underscore template settings
	# interpolate: {{{ verbatim }}}
	# escape: {{ to be HTML-esc }}
	# evaluate: {{\ executable code }}
	_.templateSettings =
		interpolate: /\{\{\{(.+?)\}\}\}/g
		escape: /\{\{(.+?)\}\}/g
		evaluate: /\{\{=(.+?)\}\}/g
