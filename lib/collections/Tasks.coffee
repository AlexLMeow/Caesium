###
/lib/collections/Tasks.coffee

Holds code for Tasks collections
Schema at /lib/schemas/task.schema.coffee
###

@Tasks = new Mongo.Collection "tasks"

Tasks.allow
	insert: () -> true
	update: () -> true
	remove: ()-> true


Tasks.deny({})

###################################################################
Meteor.methods
	
	###################################################################
	# Inserts new task
	# name: String
	# due: Date
	# dur: Integer (milliseconds)
	# prio: Number [0,3]
	# tags: [String]
	# notes: String
	# RETURNS NEW _ID
	addTask: (name, due, dur, prio, tags, notes) ->

		check dur, Match.Where (x) -> 
			check x, Match.Integer
			x > 0

		check prio, Match.Where (x) -> 
			check x, Match.Integer
			0 <= x <= 3

		check name, Match.Where (x) ->
			check x, String
			0 < x.length <= 25

		check tags, [String]
		check notes, String
		check due, Date

		task = 
			name: name
			active: true
			owner_id: @userId
			created_at: new Date
			due_date: due
			duration: dur
			time_spent: 0
			priority: prio
			tags: tags
			notes: notes
			progress_list: []
			next_progress_id: 0
			last_modified: new Date
			danger: due.getTime() - dur
			percent_complete: 0

		# insert task, update user's task list
		id = Tasks.insert task, {
			removeEmptyStrings: false
			}, ()->

		Meteor.users.update @userId, {
			$addToSet: 
				task_id_list: id
				tags: 
					$each: tags
			}, {}, ()->
		
		return id

	###################################################################
	# Removes task if user is owner
	# id: String (id of doc to remove)
	removeTask: (id) ->

		check id, String

		task = Tasks.findOne id, {
			fields: 
				owner_id: 1
			}

		if !task?
			throw new Meteor.Error "task-id-not-found", "no task with this id"
		if @userId isnt task.owner_id
			throw new Meteor.Error "removeTask-userId-mismatch", "user id does not match task's owner"

		Tasks.remove id, ()->

		Meteor.users.update @userId, {
			$pullAll: 
				task_id_list: [id]
			}, () ->

	###################################################################
	# add task progress object if user is owner
	# id: String (task id)
	# dur: Integer (milliseconds of time spent)
	# date: Date (date of progress)
	# notes: String
	addProgress: (id, dur, date, notes) ->

		check dur, Match.Where (x) ->
			check x, Match.Integer
			return x>0

		check id, String
		check notes, String

		# no logging future progress
		check date, Match.Where (x) ->
			check x, Date
			x < new Date

		# pull relevant task data and check owner
		task = Tasks.findOne id, {}

		if !task?
			throw new Meteor.Error "task-id-not-found", "no task with this id"
		if @userId isnt task.owner_id
			throw new Meteor.Error "addProgress-userId-mismatch", "user id does not match task's owner"

		prog = 
			_id: task.next_progress_id
			progress_date: date
			duration: dur
			notes: notes

		percent = 100 * (task.time_spent+dur) // task.duration

		# object fo $set
		setObj =
			percent_complete: percent
			last_modified: new Date

		# update last progress date if needed
		if !task.last_progress? or date > task.last_progress
			setObj.last_progress = date

		# add the progress Object
		Tasks.update id, {
				$addToSet: 
					progress_list: prog 
				$inc: 
					time_spent: dur
					next_progress_id: 1
					danger: dur 					# increment danger date
				$set: setObj		
			}, {
				removeEmptyStrings: false
				}, () ->

	###################################################################
	# Removes a progress object 
	# id: String (task _id)
	# prog: Number (prog _id)
	removeProgress: (id, prog) ->

		check id, String
		check prog, Number

		# check owner
		task = Tasks.findOne id, {}

		if !task?
			throw new Meteor.Error "task-id-not-found", "no task with this id"
		if @userId isnt task.owner_id
			throw new Meteor.Error "removeProgress-userId-mismatch", "user id does not match task's owner"

		# find index of offending progress object
		if (i = _.findIndex(task.progress_list, (x) -> 
			x._id is prog 
			)) is -1
			throw new Meteor.Error "removeProgress-progId-mismatch", "no progress with this id"

		progID = prog
		prog = task.progress_list[i]
		# extract duration of progress object
		dur = prog.duration

		percent = 100 * (task.time_spent-dur) // task.duration

		# update obj
		uObj = 
			$pull: 
				progress_list: 
					_id: progID
			$inc: 
				time_spent: -dur
				danger: -dur
			$set: 
				percent_complete: percent
				last_modified: new Date

		# remove offending progress from list
		task.progress_list.splice i, 1

		# if no progress remaining, remove last_progress
		if task.progress_list.length is 0
			uObj.$unset = {last_progress: ""}

		# else adjust last progress time if needed
		else if task.last_progress.getTime() is prog.progress_date.getTime()
			uObj.$set.last_progress = _.max(task.progress_list, (p) -> p.progress_date.getTime()).progress_date

		console.log uObj
		# remove the progress object matching prog and update time spent
		Tasks.update id, uObj

	###################################################################
	# Modifies task's tag list
	# id: String (task _id)
	# tags: [String] (tags to add/remove) or array of str
	# mod: String ("add" or "remove" or "set")
	updateTags: (id, tags, mod) ->

		check id, String
		check tags, [String]
		check mod, Match.OneOf "add", "remove", "set"

		# pull relevant task info and validate user
		task = Tasks.findOne(id, {fields: {owner_id: 1, tags: 1}})
		if !task?
			throw new Meteor.Error "task-id-not-found", "no task with this id"
		if @userId isnt task.owner_id
			throw new Meteor.Error "modifyTags-userId-mismatch", "user id does not match task's owner"

		# add or remove tag, rely on collection2 clean to ignore empty string tags
		if mod is "add"
			Meteor.users.update @userId, {
			$addToSet: 
				tags: 
					$each: tags
			}, {}, ()->
			Tasks.update id, {
				$addToSet: 
					$each:
						tags: tags
				$set: 
					last_modified: new Date
			}, {}, ()->
		else if mod is "remove"
			Tasks.update id, {
				$pullAll: 
					tags: tags
				$set: 
					last_modified: new Date
			}, {}, ()->
		else
			Meteor.users.update @userId, {
			$addToSet: 
				tags: 
					$each: tags
			}, {}, ()->
			Tasks.update id, {
				$set:
					last_modified: new Date
					tags: tags
			}, {}, ()->

	###################################################################
	# Modifies task field --> val
	# id: String (task _id)
	# field: String 
	# val: VALIDATION DONE VIA SCHEMAS
	updateTask: (id, field, val) ->

		check id, String

		# retrieve entire task doc for simulation
		task = Tasks.findOne id

		if !task?
			throw new Meteor.Error "task-id-not-found", "no task with this id"

		# make sure requested field is safe to modify and exists
		check field, Match.Where (x) ->
			check field, String
			return field in [
				"active"
				"name"
				"due_date"
				"duration"
				"priority"
				"notes"
				]

		# auth user
		if @userId isnt task.owner_id
			throw new Meteor.Error "modifyTask-userId-mismatch", "user id does not match task's owner"
		# deny empty name
		if field is "name" and val is ""
			throw new Meteor.Error "modifyTask-name-empty", "task name cannot be empty string"

		# simulate change in task doc here
		task[field] = val

		# calculate new danger field
		newDanger = task.due_date.getTime() - task.duration + task.time_spent

		# calculate new percent
		newPercent = 100 * task.time_spent // task.duration

		# $set object to update field in task
		sObj = 
			last_modified: new Date
			danger: newDanger
			percent_complete: newPercent

		# add updating field to sObj
		sObj[field] = val

		Tasks.update id, {
			$set: sObj
			}, {
				removeEmptyStrings:false  # notes can be empty
				}, ()->
