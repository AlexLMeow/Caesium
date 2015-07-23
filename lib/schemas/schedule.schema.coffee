###
/lib/schemas/schedule.schema.coffee

Holds schema(s) definition for docs in Schedules collection
###

#####################################################################
# subschema for scheduled events

# Schemas.events = new SimpleSchema 
	
# 	fixed:
# 		type: Boolean
		
# 	name:
# 		type: String

# 	# start date for this scheduled event
# 	start:
# 		type: Date

# 	# end date for this scheduled event
# 	end:
# 		type: Date

# 	# holds _id of associated task if (any)
# 	task_id:
# 		type: String
# 		optional: true

# 	# user defined event notes, html str
# 	notes:
# 		type: String

# 	_id:
# 		type: Number


####################################################################
####################################################################
# main schema for schedule

Schemas.schedule = new SimpleSchema 

	name:
		type: String

	owner_id:
		type: String

	created_at:
		type: Date

	last_modified:
		type: Date


	# user notes for this schedule, html str
	notes:
		type: String

	# Array of all events on calender (see above for events object)
	events_list:
		type: [Object]
		blackbox: true

	# tracks id for new event bjects
	next_event_id:
		type: Number

####################################################################



Schedules.attachSchema Schemas.schedule