###
/lib/router.coffee
###

Router.configure
	
	layoutTemplate: "layout"
	#loadingTemplate: ?
	#notFoundTemplate: ?

# login/signup route
Router.route '/auth', (() -> 
	@render "auth"
	), {
	name: 'auth'
	layoutTemplate: "auth-layout"
}

# home/main route
Router.route '/', (() -> 
	@render "home"
	), {
	name: 'home'
}

# tasks view
Router.route '/t/:taskID', (() ->

	_id = @params.taskID
	if _id is "index" 
		@render "task", {}
	else 
		if tasksubs.ready()
			task = Tasks.findOne @params.taskID
			if task?
				@render "task", {
					data: () -> task 				# set template data context to task doc
				}
			else
				@redirect "/t/index"
		
	),{
	name: 'tasks'
	layoutTemplate: 'tasks_layout'
}

# tasks view redirect
Router.route '/t', () -> @redirect '/t/index'

# schedule view
#Router.route '/schedule', (() -> ), {name: 'schedule'}




# if user is not logged in redirect to auth for register/login
Router.onBeforeAction (() ->	

	# reset editing sessions
	Session.set "editTaskName", false
	Session.set "editTaskPrio", false
	Session.set "editTaskTags", false
	Session.set "editTaskDue", false
	Session.set "editTaskDur", false
	Session.set "editTaskNotes", false

	if !Meteor.user()? and !Meteor.loggingIn()
		Router.go "/auth"
	else
		@next()
	), {except: 'auth'}