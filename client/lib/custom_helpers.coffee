###
/client/lib/custom_helpers.coffee

custom helper functions 
client/lib/custom-helpers.coffee
###

@Caesium =

	# check if adding a new event with these start and end times clashes with other events
	# true if no clash, false otherwise
	eventClashSafe: (id, start, end) ->

		#sanitise
		check id, String
		check start, Date
		check end, Match.Where (x) ->
			check end, Date
			return end > start

		# retrieve schedule
		sched = Schedule.findOne id

		if !sched? 
			throw "Caesium.eventClashSafe: id does not match any schedule"

		# fold to find if there is no clash
		return _.reduce sched.events_list, ((m, v) -> 
			return m and (v.start>end or v.end<start)
			), true

	test: () -> 
		console.log "fired"
		"TESTEST"

