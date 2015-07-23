###
/lib/schemas/task.schema.coffee

Holds schema(s) definition for docs in Tasks collection
###

#####################################################################
# subschema for task progress updates data

Schemas.progress = new SimpleSchema

	_id:
		type: Number
	
	# date of progress 
	progress_date:
		type: Date

	# time in milliseconds to count to task completion
	duration:
		type: Number
		min: 0

	# html str for notes
	notes:
		type: String


#####################################################################
#####################################################################
# main schema for tasks

Schemas.task = new SimpleSchema 

	last_modified:
		type: Date

	owner_id:
		type: String

	created_at:
		type: Date

######## update these ########################

	last_progress:
		type: Date
		optional: true

	# numeric (getTime) format of the date it will become incompleteable
	# ensure recalculate on all updates
	danger:
		type: Number

	# ensure recalculate, use for completion check (>=100)
	percent_complete:
		type: Number
		min: 0

	# time spent on task in milliseconds
	time_spent:
		type: Number
		min: 0

	# array of progress objects (see above) to record all progress updates
	progress_list:
		type: [Schemas.progress]

	# tracks id for new progress objects
	next_progress_id:
		type: Number

############## user editable ############

	active:
		type: Boolean

	# 0 is lowest priority, highest 3, 4 levels
	priority:
		type: Number
		min: 0
		max: 3

	# expected duration for this task in milliseconds
	duration:
		type: Number
		minCount: 0

	due_date:
		type: Date

	name:
		type: String
		max: 25

	# string array of tags
	tags:
		type: [String]

	# users notes for this task, html str
	notes:
		type: String


####################################################################	



Tasks.attachSchema Schemas.task