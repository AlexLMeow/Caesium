###
/client/views/navbar.coffee
###

Template.navbar.onRendered ()->

	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"

	# set timers to trigger recalculations for navbar task info
	@autorun (c)->

		# add timeout trigger dependancy
		Session.get "navbarTrigger"

		# trigger function for observeChanges callbacks
		triggerFunc = (id, fs) ->
			switch
				# if danger time has passed but not overdue yet
				# set a trigger to fire upon overdue
				when fs.danger < Date.now()
					setTimeout (() -> 
						Session.set "navbarTrigger", Date.now()
						), fs.due_date.getTime() - Date.now()
				# if danger time is < 3 days away
				# set a trigger to fire upon danger threshold
				when fs.danger < Date.now() + 259200000
					setTimeout (() -> 
						Session.set "navbarTrigger", Date.now()
						), fs.danger - Date.now()
				# all remaining tasks more than 3 days away from danger
				# set a trigger to fire upon 3 days from danger
				else
					setTimeout (() ->
						Session.set "navbarTrigger", Date.now()
						), fs.danger - 259200000 - Date.now()

		# setup observeChanges
		Tasks.find({
				active: true 				# only consider active tasks
				due_date:						# only those who are not yet overdue
					$gt: new Date()
				percent_complete: 	# not yet complete
					$lt: 100
			},{
				fields:							# reg dependancies on these fields only
					danger: 1
					due_date: 1
				}).observeChanges 
					added: triggerFunc
					changed: triggerFunc

	# style scrollbar for dropdown-menus				
	$(".dropdown-menu").niceScroll()

Template.navbar.helpers
	
	# identity string to display at navbar top right
	userIdentity: () -> 
		u = Meteor.user()
		if u?
			u.emails[0].address
		else
			"...loading user"

	# active highlighting for navbar tab links
	home_bt: () -> "active" if Router.current().route.getName() is "home"
	tasks_bt: () -> "active" if Router.current().route.getName() is "tasks"
	scheds_bt: () -> "active" if Router.current().route.getName() is "schedule"

	############################################################
	# for all navbar task counts, reduce dependancies to relevant fields
	# for all navbar cursors, retrieve all fields
	############################################################

	# count of active tasks
	active_count: () -> 
		Tasks.find({
			active: true
			percent_complete:
				$lt: 100
			},{
				fields: 	# register dependency on these fields for count
					active: 1
				}).count()

	# count of completed tasks regardless of active
	completed_count: () ->
		Tasks.find({
			percent_complete:
				$gte: 100
			},{
				fields:
					percent_complete: 1
				}).count()

	# count of active tasks becoming incompleteable in 3 days
	urgent_count: () -> 
		# register dependency on this session var for trigger
		Session.get "navbarTrigger"
		Tasks.find({
			active: true
			percent_complete:
				$lt: 100
			danger:  	# danger time between today and 3 days later
				$lt: Date.now()+259200000
				$gt: Date.now()
			},{
				fields:		# register dependency on these fields for count
					active: 1
					danger: 1
				}).count()

	# cursor to list urgent tasks
	urgent_cursor: () -> 
		Session.get "navbarTrigger"
		Tasks.find {
			active: true
			percent_complete:
				$lt: 100
			danger: 
				$lt: Date.now()+259200000
				$gt: Date.now()
			},{
				sort: [["danger, asc"]]
			}

	# count of active but incompleteable tasks
	danger_count: () -> 
		Session.get "navbarTrigger"
		Tasks.find({
			active: true
			percent_complete:
				$lt: 100
			danger: 
				$lt: Date.now()
			due_date:
				$gt: new Date()
			},{
				fields: 
					active: 1
					danger: 1
					due_date: 1
				}).count()

	# cursor to list incompleteable
	danger_cursor: () ->
		Session.get "navbarTrigger"
		Tasks.find {
			active: true
			percent_complete:
				$lt: 100
			danger: 
				$lt: Date.now()
			due_date:
				$gt: new Date()
			}, {
				sort: [["due_date","asc"]]
			}
	
	# count of active but overdue tasks
	overdue_count: () ->
		Session.get "navbarTrigger"
		Tasks.find({
			active: true
			percent_complete:
				$lt: 100
			due_date: 
				$lt: new Date() # task's due_date < now
			},{
				fields: 
					active: 1
					due_date: 1
				}).count()

	overdue_cursor: () ->
		Session.get "navbarTrigger"
		Tasks.find {
			active: true
			percent_complete:
				$lt: 100
			due_date: 
				$lt: new Date()
			},{
				sort: [["priority","desc"]]
			}
	
	
		
Template.navbar.events

	"click .logout-link": (e, tp) ->
		e.preventDefault()
		Meteor.logout()

###################################################################################

Template.navbarTask.events

	"click .deact-task-home": (e, tp) ->
		e.preventDefault()
		d = tp.data
		Meteor.call "updateTask", d._id, "active", false
		

Template.navbarTask.helpers

	# task unit styling
	panelStyle: (p) ->
		check p, Match.Where (x) -> check x, Match.Integer; 0<=x<=3
		switch p
			when 0 then "success"
			when 1 then "info"
			when 2 then "warning"
			else "danger"
 
	dayDateString: (d) ->
		check d, Date
		moment(d).format "ddd Do MMM YY"
		
	timeString: (d) ->
		check d, Date
		moment(d).format "hh:mma"

	# hours and minutes format, ignore seconds and ms
	workLeft: (dur,spent) ->
		check dur, Number
		check spent, Number
		t = dur-spent
		ms = t % 1000
		t = (t-ms)/1000
		s = t % 60
		t = (t-s)/60
		m = t % 60
		h = (t - m)/60
		"#{h} h #{m} min"

	progPercent: (dur,spent) -> "" + 100*spent//dur

	# prog bar styling
	progStyle: (p) ->
		switch
			when p < 25 then "danger"
			when p < 50 then "warning"
			when p < 75 then "info"
			else "success"

Template.navbarTask.onRendered () ->
	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"

	$(".dropdown-menu").niceScroll()