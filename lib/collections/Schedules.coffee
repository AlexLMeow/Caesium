###
/lib/collections/Schedules.coffee

Holds code for Schedules collections
Schema at /lib/schemas/schedule.schema.coffee
###

@Schedules = new Mongo.Collection 'schedules'

Schedules.allow({
	update: ()->true
	# update: (userId, doc, fieldNames, mod) ->
	# 	if userId isnt doc.owner_id then return false
	# 	_.reduce field, ((m,v)-> m and v in ["last_modified","events_list"]), true 
	})

Schedules.deny({})

#####################################################################
Meteor.methods
	
	###################################################################
	# Inserts new schedule
	# name: String
	# start: Date
	# end: Date
	# notes: String
	# RETURNS NEW _ID
	addSchedule: (name, start, end, notes) ->

		check notes, String
		check name, String
		check start, Date
		check start, Date

		sched = 
			name: name
			owner_id: @userId
			created_at: new Date
			schedule_start: start
			schedule_end: end
			notes: notes
			events_list: []
			last_modified: new Date
			next_event_id: 0

		# insert sched
		id = Schedules.insert sched, {
			removeEmptyStrings: false		# notes can be empty
			}, ()->

		# update user's sched list
		Meteor.users.update @userId, {
			$addToSet: 
				schedule_id_list: id
			}, {}, ()->
		
		return id

	###################################################################
	# Removes schedule if user authorised
	# id: String (id of doc to remove)
	removeSchedule: (id) ->

		check id, String

		sched = Schedule.findOne id, {
			fields: 
				owner_id: 1
			}

		if !sched?
			throw new Meteor.Error "schedule-id-not-found", "no schedule with this id"
		if @userId isnt sched.owner_id
			throw new Meteor.Error "removeSchedule-userId-mismatch", "user id does not match schedule's owner"

		Schedules.remove id, ()->

		Meteor.users.update @userId, {
			$pull: 
				schedule_id_list: id
			}, {}, ()->

	###################################################################
	# Modify standard schedule fields
	# id: String (task _id)
	# field: String 
	# val: VALIDATION DONE VIA SCHEMAS
	updateSchedule: (id, field, val) ->

		check id, String

		# pull sched doc for simulation
		sched = Schedules.findOne id

		# check if schedule with this id exists
		if !sched?
			throw new Meteor.Error "schedule-id-not-found", "no schedule with this id"
		# auth user
		if @userId isnt sched.owner_id
			throw new Meteor.Error "modifySchedule-userId-mismatch", "user id does not match schedule's owner"

		# make sure requested field is safe to modify and exists
		check field, Match.Where (x) ->
			check field, String
			return field in [
				"name"
				"schedule_start"
				"schedule_end"
				"notes"
				]

		# $set object to update field in schedule
		sObj = 
			last_modified: new Date

		fieldObj[field] = val

		Schedules.update id, {
			$set: fieldObj
			}, {
				removeEmptyStrings:false # notes can be empty
				}, ()->

	###################################################################
	# Add a new event object to the schedule
	# id: String (schedule _id)
	# start: Date
	# end: Date
	# name: String
	# notes: String
	# task: String (associated task's _id) OPTIONAL
	# fixed: Boolean (is this event fixed to it's time)
	###
	addEvent: (id, name, start, end, notes, fixed, task) ->

		check name, String
		check id, String
		check notes, String
		check(task, String) if task? 
		check start, Date
		check end, Date

		if !Caesium.eventClashSafe id, start, end
			throw new Meteor.Error "addEvent-clash", "clash with existing event(s)"

		# pull relevant fields of schedule
		sched = Schedules.findOne id, {
			fields: 
				next_event_id: 1
				owner_id: 1
			}

		if !sched?
			throw new Meteor.Error "schedule-id-not-found", "no schedule with this id"
		if @userId isnt sched.owner_id
			throw new Meteor.Error "addEvent-userId-mismatch", "user id does not match schedule's owner"

		evt = 
			_id: sched.next_event_id
			fixed: fixed
			name: name
			start: start
			end: end
			notes: notes

		(evt.task_id = task) if task?

		Schedules.update id, {
			$addToSet: 
				events_list: evt
			$inc: 
				next_event_id: 1
			$set: 
				last_modified: new Date
			}, {
				removeEmptyStrings:false
				}, ()->
	###

	###################################################################
	# Remove an event from schedule
	# id: String (sched _id)
	# evt: String (event _id)
	###
	removeEvent: (id, evt) ->

		check id, String
		check evt, String

		sched = Schedules.findOne id, {
			fields: 
				owner_id: 1
			}

		if !sched?
			throw new Meteor.Error "schedule-id-not-found", "no schedule with this id"
		if @userId isnt sched.owner_id
			throw new Meteor.Error "removeEvent-userId-mismatch", "user id does not match schedule's owner"

		Schedules.update id, {
			$pull: 
				events_list: 
					_id: evt
			$set: 
				last_modified: new Date
		}, {}, ()->
	###

	###################################################################
	# Modifies existing event's specified field --> val
	# id: String (sched _id)
	# evt: String (event _id)
	# field: String 
	# val: VALIDATION DONE VIA SCHEMAS
	###
	modifyEvent: (id, evt, field, val) ->

		check id, String
		check evt, String

		# safe fields
		check field, Match.Where (x) ->
			check field, String
			return !(field in [
				"_id"
			]) and task.hasOwnProperty field

		# pull relevant doc fields
		sched = Schedules.findOne id, {
			fields: 
				owner_id: 1
				events_list: 1
			}

		if !sched?
			throw new Meteor.Error "schedule-id-not-found", "no schedule with this id"
		if @userId isnt sched.owner_id
			throw new Meteor.Error "removeEvent-userId-mismatch", "user id does not match schedule's owner"

		# object to pass as $set option for updating schedule doc
		sObj = 
			last_modified: new Date

		if i = _.findIndex(sched.events_list, (x) -> x._id is evt) is -1
			throw new Meteor.Error "event-not-found", "no event with this id"

		fieldObj["events_list."+i+"."+field] = val

		# simulate change in sched
		sched.events_list[i][field] = val

		# switch for catching illegal changes
		switch
			# if event is fixed can only toggle fixed or change notes
			when sched.events_list[i].fixed
				if !(field in ['fixed', 'notes']) 
					throw new Meteor.Error "event-fixed-$set-lock", "cannot change field:#{field} if event is fixed"

			# cannot set start date > end date
			when sched.events_list[i].start > sched.events_list[i].end
				throw new Meteor.Error "event-start-after-end", "event cannot have start date > end date"

		# updating event
		ev = sched.events_list[i]

		# array without modified event for clash comparison
		others = sched.events_list.splice i, 1

		# check if event clashes after change
		if !(_.reduce others, ((m, v) -> 
			return m and (v.start>ev.end or v.end<ev.start)
			), true)
			throw new Meteor.Error "modEvent-clash", "clash with existing event(s)"

		# update
		Schedules.update id, {
			$set: fieldObj	
		}, {
			removeEmptyStrings:false
			}, ()->
	###

	saveEvents: (id, evts) ->
		check id, String
		check evts, [Object]
		if !(s = Schedules.findOne id)?
			throw new Meteor.Error "saveEvents: sched id mismatch"

		if @userId isnt Schedules.findOne(id).owner_id
			throw new Meteor.Error  "saveEvents: sched owner mismatch"

		Schedules.update id, {
			$set:
				events_list: evts
				last_modified: new Date
		}

	genEvtId: (id) ->
		check id, String

		if !(s = Schedules.findOne id)?
			throw new Meteor.Error "genEvtId: sched id mismatch"

		if @userId isnt Schedules.findOne(id).owner_id
			throw new Meteor.Error  "genEvtId: sched owner mismatch"

		s = s.next_event_id
		Schedules.update id, {
			$inc:
				next_event_id: 1
		}
		return s
