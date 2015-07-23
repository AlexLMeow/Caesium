###
/server/publications.coffee

server reactive publications
###

####################################################################
# Publish additional user fields
Meteor.publish "userData", () ->
	if @userId?
		return Meteor.users.find @userId, {
			fields: {task_id_list:1, schedule_id_list:1, tags:1}
		}
	else
		@ready()

####################################################################
# Publish user's schedules
Meteor.publish "userSchedules", () ->
	if @userId?
		return Schedules.find { owner_id: @userId }
	else
		@ready()

####################################################################
# Publish user's tasks
Meteor.publish "userTasks", () ->
	if @userId?
		return Tasks.find { owner_id: @userId }
	else
		@ready()