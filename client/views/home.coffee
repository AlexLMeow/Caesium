###
/client/views/home.coffee
###


#########################################################

Template.tasksHome.onRendered () ->

	# initialise limit and sort options
	Session.set "home-tasks-limit", 5
	Session.set "home-tasks-sort", ["danger"]


	# init prio select for addtask form
	$("#newTask-home-prio").select2 
		minimumResultsForSearch: 5


	# initialise addtask modal datetimepicker
	$(".datetimepicker").datetimepicker
		inline: true
		sideBySide: true
		showTodayButton: true

	# init tag select2 for addtask form
	@autorun (c) ->
		if Meteor.user()?
			$("#newTask-home-tags").select2
				tags: _.map Meteor.user().tags, (e) -> {id: e, text: e}
				tokenSeparators: [',',' ']
				placeholder: "Add tags here"
				closeOnSelect: false

	# init summernote editors
	$(".summernote").summernote
		height: 250


	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"


	# reset modal forms after modal close
	$(".modal").on "hidden.bs.modal", (e) ->
		modal = $(@)
		modal.find("form")?[0].reset();

		dtp = modal.find(".datetimepicker")
		if dtp.length > 0 then dtp.data("DateTimePicker").date new Date()

		sn = modal.find(".summernote")
		sn?.destroy()
		sn?.text ""		
		sn?.summernote
			height: 250


	# setup addprogress modal to extract id
	$("#addProgFromHome").on "show.bs.modal", (e) ->
		now = new Date
		# initialise date limit for add progress modal
		dtp = $(@).find("#newProg-home-date").data("DateTimePicker")
		dtp.maxDate now
		dtp.date now

		source = $(e.relatedTarget)
		taskId = source.data "id"
		taskName = source.data "name"

		modal = $(@)
		# alter modal's title based on source task
		modal.find(".modal-title").text "Log progress for: #{taskName}"
		# store task id in hidden field
		modal.find("#addProgFromHomeTaskID").val taskId


Template.tasksHome.helpers
	
	# returns cursor of tasks sorted by mod and limited by lim
	homeTasks: () ->
		a = Session.get "home-tasks-sort"
		if !a? then return ["session not loaded"]

		mod = a[0]
		dir = a[1]
		lim = Session.get "home-tasks-limit"

		switch mod
			when "due"
				sort = [["due_date","asc"],["danger","asc"]]
			when "prio"
				sort = [["priority","desc"],["danger","asc"]]
			when "percent"
				sort = [["percent_complete",dir],["danger","asc"]]
			when "danger"
				sort = [["danger","asc"],["due_date","asc"]]
			# custom alpha sort for capitals
			when "name"
				compare = (a,b) ->
					x = if dir is "asc" then 1 else -1
					a = a.name.toLowerCase()
					b = b.name.toLowerCase()
					if a < b then return -x
					if a > b then return x
					return 0
				return Tasks.find({
					active: true
					percent_complete:
						$lt: 100
				},{
					limit: lim
				}).fetch().sort compare
					
			else throw "Session key 'home-tasks-sort' illegal value"

		Tasks.find {
			active: true
			percent_complete:
				$lt: 100
			},{
				limit: lim
				sort: sort
			}

	# styles correct task limit button as active
	btnLimitClass: (n) ->
		if Session.get("home-tasks-limit") is n
			"active"

	# creates button for sort dropdown
	btnSort: () ->
		s = Session.get "home-tasks-sort"
		if !s? then return "session unloaded"

		switch s[0]
			when "due" 
				t = "Due date"
				g = "time"
			when "prio" 
				t = "Priority"
				g = "star-empty"
			when "danger" 
				t = "Remaining safe time"
				g = "hourglass"
			when "name"
				if s[1] is "asc" 
					t = "Name (A-Z)"
					g = "sort-by-alphabet"
				if s[1] is "desc" 
					t = "Name (Z-A)"
					g = "sort-by-alphabet-alt"
			when "percent"
				if s[1] is "asc" 
					t = "Least Progress"
					g = "sort-by-attributes"
				if s[1] is "desc" 
					t = "Most Progress"
					g = "sort-by-attributes-alt"

		# re-call jquery tooltip for updated dom 
		Tracker.afterFlush ()->
			$("#home-sort-btn").tooltip 
				container: "body"
				trigger: "hover"

		'<button 
			type="button" 
			id = "home-sort-btn"
			class="btn btn-glyph btn-default dropdown-toggle" 
			data-toggle="dropdown" 
			data-hover="tooltip" 
			data-placement="top" 
			title="' + t + '"
		 ><span class="glyphicon glyphicon-' + g + '"></span>
		 </button>'


Template.tasksHome.events

	# add task modal submit
	"click #addTask-home": (e,tp) ->
		e.preventDefault()
		# create addTask args object for debugging
		tagstr = tp.find("#newTask-home-tags").value
		tagstr = if tagstr is "" then [] else tagstr.split(',')
		x = 
			tags: tagstr
			name: tp.find("#newTask-home-name").value
			due: new Date tp.find("#newTask-home-due").value
			notes: tp.$("#newTask-home-notes").code()
			dur: parseInt(tp.find("#newTask-home-dur-h").value) * 3600000 + parseInt(tp.find("#newTask-home-dur-m").value) * 60000
			prio: parseInt tp.find("#newTask-home-prio").value

		if x.name is "" or x.dur <= 0		
			throw "cannot add task with empty name or 0 duration"

		Meteor.call "addTask", x.name, x.due, x.dur, x.prio, x.tags, x.notes

	# add progress modal submit
	"click #addProg-home": (e,tp) ->
		e.preventDefault()
		x =
			id: tp.$("#addProgFromHomeTaskID").val()
			dur: parseInt(tp.$("#newProg-home-dur-h").val()) * 3600000 + parseInt(tp.$("#newProg-home-dur-m").val()) * 60000
			date: new Date tp.$("#newProg-home-date").val()
			notes: ""

		if x.dur <= 0 or x.date > new Date() 
			throw "cannot log progress in the future or with 0 time"

		Meteor.call "addProgress", x.id, x.dur, x.date, x.notes

	# toggle limit of tasks shown
	"click .home-limit": (e,tp) ->
		e.preventDefault()
		Session.set "home-tasks-limit", parseInt e.target.textContent

	# toggle current sort modifiers
	"click .sort-select": (e,tp) ->
		e.preventDefault()
		a = [e.target.type]
		if e.target.type in ["percent","name"]
			a.push e.target.rel
		Session.set "home-tasks-sort", a

	# add event
	"click #addEvent-home": (e,tp) ->
		e.preventDefault()
		s = Session.get "newEventData"
		evt =
			id: Meteor.call "genEvtId", Schedules.findOne()._id
			start: s[0]
			end: s[1]
			title: tp.find("#home-new-evt-title").value
		$("#calendar").fullCalendar "renderEvent", evt, true

	# update event
	"click #editEvent-home": (e,tp) ->
		e.preventDefault()
		evt = Caesium.evt
		evt.title = tp.find("#home-edit-evt-title").value
		$("#calendar").fullCalendar "updateEvent", evt

	# del event
	"click #delEvent-home": (e,tp) ->
		e.preventDefault()
		$("#calendar").fullCalendar "removeEvents", tp.$("#editEventFromHome").data "id"

#########################################################

Template.taskHome.onRendered () ->

	# style task area scrollbar
	$(".nicescroll").niceScroll()

	# load tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"


Template.taskHome.helpers

	# text for due_date
	due: (d) ->
		moment(d).format "hh:mma dddd [<br>] Do MMMM YYYY"

	# text for last progress made date
	lastprog: (lp) ->
		if !lp? then return "<span class='text-danger'>None yet</span>"
		lp = moment(lp)
		diff = moment().diff lp # time difference now vs last_progress

		if diff < 604800000 then s = "success"
		else s = "info"
		
		"<span class='text-#{s}'>#{lp.fromNow()}</span>"

	# text for priority
	prio: (p) ->
		switch p
			when 0 then return "<strong class='text-success'>Low</strong>"
			when 1 then return "<strong class='text-info'>Normal</strong>"
			when 2 then return "<strong class='text-warning'>High</strong>"
			when 3 then return "<strong class='text-danger'>Critical</strong>"
			else return "ERROR: INVALID PRIORITY"

	# hours and minutes format, ignore seconds and ms
	workLeft: (dur,spent) ->
		t = dur - spent
		t = moment.duration t
		h = Math.floor t.asHours()
		m = t.minutes()
		d = moment.duration dur
		dh = Math.floor d.asHours()
		dm = d.minutes()
		"<span style='color:#000C98;'>#{h}<small class='text-muted'> h</small> #{m}<small class='text-muted'> min</small></span> <small class='text-muted'>left, out of</small> #{dh}<small class='text-muted'> h</small> #{dm}<small class='text-muted'> min</small>"

	# styling for progress bar
	progStyle: (p) ->
		switch 
			when p < 25 then "danger"
			when p < 50 then "warning"
			when p < 75 then "info"
			else "success"

	# fuzzy timer in task panel header
	dTimerSmall: (d) ->
		# retrigger every second, btn styilng
		if (c = d - Session.get "timer-1s") < 0
			s = "danger"
		else if c < 258200000 # 3 days
			s = "warning"
		else if c < 604800000 # 1 week
			s = "info"
		else s = "success"
		'<button class="btn btn-' + s + 
		' btn-sm btn-inactive">' + 
			moment.duration(c).humanize(true) + 
	  '</button>'

	# main timer in task panel body
	dTimerHMS: (d,due) ->
		# retrigger every sec
		now = Session.get "timer-1s"
		if !now? then return ""
		t = moment.duration d - now
		if due? and due.getTime() < Date.now()
			return "<strong 
			class='h3' 
			style='color:#F30000;'>
			OVERDUE
			</strong>"
		if t.asMilliseconds() < 0
			return "<span class='h3' style='color:#F3CE00;'>
			UNSAFE
			</span><br>
			<small class='text-muted'>
			Not enough time left to complete task
			</small>"
		h = if t.hours()<10 then "0"+t.hours() else t.hours()
		m = if t.minutes()<10 then "0"+t.minutes() else t.minutes()
		s = if t.seconds()<10 then "0"+t.seconds() else t.seconds()
		"<span class='h3'>
		#{h}<small class='text-muted'>h </small>
		#{m}<small class='text-muted'>m </small>
		#{s}<small class='text-muted'>s</small>
		</span>"

	# main timer extension
	dTimerDMY: (d) ->
		t = moment.duration d - Session.get "timer-1s"
		if t.asMilliseconds() < 0 then return
		str = ""
		if (d = t.days()) is 0 then return str
		str += "<hr><span class='h3' style='margin-bottom:0;'>" + d + "</span><br><small class='text-muted'>days</small>"
		if (m = t.months()) is 0 then return str
		str += "<hr><span class='h3' style='margin-bottom:0;'>" + m + "</span><br><small class='text-muted'>months</small>"
		if (y = t.years()) is 0 then return str
		str += "<hr><span class='h3' style='margin-bottom:0;'>" + y + "</span><br><small class='text-muted'>years</small>"
		return str


Template.taskHome.events

	"click .home-edit-task": (e,tp) ->
		e.preventDefault()
		Router.go "/t/" + tp.data._id

##########################################################

Template.calView.onRendered () ->

	@autorun (c)->
		if schedsubs.ready()
			# init calendar
			$("#calendar").fullCalendar
				height: "80vh"
				header:
					left: "title"
					center: "agendaDay,agendaWeek,month"
					right: "today prev,next"
				defaultView: "agendaWeek"
				slotEventOverlap: false
				eventOverlap: false
				selectable: true
				unselectCancel: "#addEventHomeBtn"
				selectOverlap: false
				allDayDefault: false
				editable: true
				eventStartEditable: true
				eventDurationEditable: true
				nextDayThreshold: "05:00:00"

				events: Schedules.findOne({owner_id: Meteor.userId()},{reactive:false}).events_list

				select: (start, end, evt, view) ->
					Session.set "newEventData", [start.format(),end.format()]

				eventClick: (evt, jsev, view) ->
					$("#editEventFromHome").modal "show"
					$("#home-edit-evt-title").val evt.title
					$("#editEventFromHome").data "id", evt._id
					Caesium.evt = evt


			c.stop()


Template.calView.events 
	
	# save events
	"click #save-events": (e,tp) ->
		e.preventDefault()
		evts = tp.$("#calendar").fullCalendar "clientEvents"
		evts = _.map evts, (x) -> {
			title: x.title
			start: x.start.format()
			end: x.end.format()
		}
		Meteor.call "saveEvents", Schedules.findOne()._id, evts
