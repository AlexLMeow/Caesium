###
/server/accounts.coffee

Additional accounts control
###

Accounts.onCreateUser (opt, usr) ->

	if opt.profile?
		usr.profile = opt.profile

	defsched = 
		name: "default"
		owner_id: usr._id
		created_at: new Date
		last_modified: new Date
		notes: ""
		events_list: []
		next_event_id: 0

	usr.task_id_list = []
	usr.schedule_id_list = [
		Schedules.insert defsched, {removeEmptyStrings: false}
	]

	# default tags
	usr.tags = [
		"School"
		"Work"
		"Errand"
		"Learn"
		"Leisure"
		"Hobby"
	]

	return usr
