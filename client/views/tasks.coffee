###
/client/views/tasks.coffee
###

Template.tasks_layout.onRendered () ->

	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"

	# init nicescroll
	$(".nicescroll").niceScroll()

	# nicescroll for whole page
	$("html").niceScroll()

	# reset modal forms after modal close
	$(".modal").on "hidden.bs.modal", (e) ->
		modal = $(@)
		modal.find("form")[0].reset();

		dtp = modal.find(".datetimepicker")
		dtp.data("DateTimePicker").date new Date()

		sn = modal.find(".summernote")
		sn.destroy()
		sn.text ""		
		sn.summernote
			height: 250

	# init add progress modal dtp
	$(".datetimepicker").datetimepicker
		inline: true
		sideBySide: true
		showTodayButton: true

	# setup addprogress modal to extract id
	$("#addProg").on "show.bs.modal", (e) ->
		now = new Date
		# initialise date limit for add progress modal
		dtp = $(@).find("#newProg-date").data("DateTimePicker")
		dtp.maxDate now
		dtp.date now

		source = $(e.relatedTarget)
		taskId = source.data "id"
		taskName = source.data "name"

		modal = $(@)
		# alter modal's title based on source task
		modal.find(".modal-title").text "Log progress for: #{taskName}"
		# store task id in hidden field
		modal.find("#addProgTaskID").val taskId


Template.tasks_layout.helpers


Template.tasks_layout.events

	"click #logProg": (e,tp) ->
		e.preventDefault()
		x =
			id: tp.$("#addProgTaskID").val()
			dur: parseInt(tp.$("#newProg-dur-h").val()) * 3600000 + parseInt(tp.$("#newProg-dur-m").val()) * 60000
			date: new Date tp.$("#newProg-date").val()
			notes: ""

		if x.dur <= 0 or x.date > new Date() 
			throw "cannot log progress in the future or with 0 time"

		Meteor.call "addProgress", x.id, x.dur, x.date, x.notes


#######################################################################################

Template.tasksView.onRendered () ->

	# init sort by danger time
	Session.set "tasks-sort", ["danger","asc"]

	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"

	# init nicescroll
	$(".nicescroll").niceScroll()



Template.tasksView.helpers
	
	# html for button showing current sort state
	currentSort: () ->
		s = Session.get "tasks-sort"
		if !s? then return "session unloaded"

		if s[1] is "asc" then dir = "top"
		if s[1] is "desc" then dir = "bottom"

		switch s[0]
			when "due_date" 
				t = "Due date"
				g = "time"
			when "priority" 
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
			when "percent_complete"
				if s[1] is "asc" 
					t = "Progress"
					g = "sort-by-attributes"
				if s[1] is "desc" 
					t = "Progress"
					g = "sort-by-attributes-alt"

		Tracker.afterFlush () ->
			$("#current-sort-btn").tooltip
				container: "body"
				trigger: "hover"

		return "<button 
		id='current-sort-btn'
		class='btn btn-sm btn-primary btn-inactive'
		data-hover='tooltip'
		data-placement='top'
		title='#{t} (#{s[1]})'>
		<span class='glyphicon glyphicon-#{g}'></span>
		<span class='glyphicon glyphicon-triangle-#{dir}'></span>
		</button>"

	# highlights active sort button
	activeSortBtn: (x) ->
		if Session.get("tasks-sort")?[0] is x
			return "active"
	# highlights active sort dir button
	activeSortDirBtn: (x,d) ->
		s = Session.get "tasks-sort"
		if s? and s[0] is x and s[1] is d
			return "active"
			
	# sorted and filtered task cursors
	tasksCursor: (mod) ->
		sort = Session.get "tasks-sort"
		if !sort? then return ["wait"]
		switch mod
			when "inactive"
				sObj = 
					active: false
			when "overdue"
				sObj = 
					active: true
					due_date:
						$lte: new Date()
			else sObj = 
				active: true
				due_date:
					$gt: new Date()

		Tasks.find sObj, {
			sort: [[sort[0],sort[1]]]
		}

Template.tasksView.events

	"click .btn-sort": (e,tp) ->
		e.preventDefault()
		source = e.target.dataset
		Session.set "tasks-sort", [source.sorts, source.dir]

	"click #newTaskBtn": (e,tp) ->
		e.preventDefault()
		Router.go "/t/index"

##########################################################################

Template.tasksViewTask.onRendered () ->

	# style task area scrollbar
	$(".nicescroll").niceScroll()

	# load tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"


Template.tasksViewTask.helpers

	# text for due_date
	due: (d) ->
		moment(d).format "hh:mma dddd [<br>] Do MMM YYYY"

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
		' btn-sm btn-inactive btn-block">' + 
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



Template.tasksViewTask.events

	"click .home-edit-task": (e,tp) ->
		e.preventDefault()
		Router.go "/t/" + tp.data._id

#######################################################################################

Template.task.onRendered () ->

	# set initial progress sort direction
	Session.set "sort-prog-dir", -1

	# init nicescroll
	$(".nicescroll").niceScroll()

	# init tooltips
	$('[data-hover="tooltip"]').tooltip
		container: "body"
		trigger: "hover"

	# init tablesorter
	#$("table").tablesorter()


Template.task.helpers

	# quick boolean comparator
	equals: (a,b) -> a is b

	# switch to show add task in side pane
	isIndex: () ->
		b = Router.current().params.taskID is "index"
		# queue jquery plugin inits after DOM updated
		if b then Tracker.afterFlush () ->
			# initialise addtask modal datetimepicker
			$(".datetimepicker").datetimepicker
				inline: true
				sideBySide: true
				showTodayButton: true
			# init tags select2 for addtask form
			if Meteor.user()? then $("#newTask-tags").select2
				tags: _.map Meteor.user().tags, (e) -> {id: e, text: e}
				tokenSeparators: [',',' ']
				placeholder: "Add tags here"
				closeOnSelect: false
			# init prio select for addtask form
			$("#newTask-prio").select2 
				minimumResultsForSearch: 5
			# init summernote editor
			$(".summernote").summernote
				height: 350

		return b

	# session check for editing task name
	editingName: () -> Session.get "editTaskName"

	# switch to run code when active field is changed
	# (reinit tooltip for new button)
	isActive: (b) ->
		Tracker.afterFlush () ->
			$(".task-active-toggle").tooltip
				container: "body"
				trigger: "hover"
		return b

	# session check for editing priority
	editingPrio: () -> Session.get "editTaskPrio"

	# priority text
	prioText: (p) ->
		switch p
			when 0 
				style = "success"
				text = "Low"
			when 1 
				style = "info"
				text = "Normal"
			when 2 
				style = "warning"
				text = "High"
			when 3 
				style = "danger"
				text = "Critical"
			else throw "invalid task priority"

		"<span class='lead text-#{style}'> #{text}</span>"

	# parses a priority number and returns the styled button dropdown
	prioBtnDrop: (p) ->
		switch p
			when 0 
				style = "success"
				text = "Low"
			when 1 
				style = "info"
				text = "Normal"
			when 2 
				style = "warning"
				text = "High"
			when 3 
				style = "danger"
				text = "Critical"
			else throw "invalid task priority"

		li = [
			"<li><a href='#' class='task-prio-save' data-val='0'>Low</a></li>"
			"<li><a href='#' class='task-prio-save' data-val='1'>Normal</a></li>"
			"<li><a href='#' class='task-prio-save' data-val='2'>High</a></li>"
			"<li><a href='#' class='task-prio-save' data-val='3'>Critical</a></li>"
		]

		# remove current priority from dropdown
		li.splice p, 1

		"<div class='btn-group' style='margin-left:5px;'>
		<button class='btn unpad-y dropdown-toggle btn-#{style}' data-toggle='dropdown'>
			#{text} <span class='caret'></span>
		</button>
		<ul class='dropdown-menu priodropdown'>
			#{li[0]}
			#{li[1]}
			#{li[2]}
		</ul>
		</div>"

	# session check for editing tags + init tags select2
	editingTags: (t) -> 
		b = Session.get "editTaskTags"
		if b and Meteor.user()? then Tracker.afterFlush () ->
			input = $ "#task-set-tags"
			input.select2
				tags: _.map Meteor.user().tags, (e) -> {id: e, text: e}
				tokenSeparators: [',',' ']
				closeOnSelect: false
			# initialise select values to current tags
			input.select2 "val", t
		return b

	# generates all individual tag btns
	tagBtns: (t) ->
		if t.length is 0 then return "No tags attached"
		html = ""
		_.each t, (e) ->
			html += "<div class='btn btn-default btn-inactive tagbtn' type='button' 
				style='margin-left:2px;white-space:normal;padding:3px 5px;'>" +
				e +
			"<span style='white-space:pre;'> </span>
			<button class='close' type='button' data-tagstr='"+e+"'>
			&times;
			</button>
			</div>"
		return html

	# task completion check
	isComplete: (p) -> p >= 100

	# remaining work
	workLeft: (d,ts) ->
		m = moment.duration d - ts
		str = ""
		if (x = m.asHours()) > 0 then str += "<span class='text-info lead'>#{Math.floor(x)}</span><small class='text-muted'> hours</small>"
		if (x = m.minutes()) > 0 then str += "<span class='text-info lead'>#{x}</span><small class='text-muted'> minutes</small>"
		return str

	# timer to d
	timerYMDHMS: (d) ->
		now = Session.get "timer-1s"
		if !now? then return ""
		if Match.test(d, Date) then d = d.getTime()
		t = moment.duration d - now
		str = ""
		if t.asMilliseconds() < 0 then return "<strong class='text-danger lead'>OVERDUE</strong>"

		if (x = t.years()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> years</small> "
		if (x = t.months()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> months</small> "
		if (x = t.days()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> days</small> "
		if (x = t.hours()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> hours</small> "
		if (x = t.minutes()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> min</small> "
		if (x = t.seconds()) > 0 then str += " <span class='text-info lead'>#{x}</span><small class='text-muted'> sec</small> "

		return str

	# session check for editing due date + init datepicker
	editingDue: () -> 
		b = Session.get "editTaskDue"
		if b then Tracker.afterFlush () ->
			$("#task-new-due").datetimepicker
				showTodayButton: true
				sideBySide: false
				inline: true
		return b

	# text for due_date and progress date
	dueText: (d, isProgress) ->
		if isProgress
			moment(d).format "hh:mma ddd[<br>]DD MMM 'YY"
		else
			moment(d).format "[<mark>]hh:mma, dddd[</mark> <span class='text-muted'>the</span> <mark>]Do, MMMM YYYY</mark>"

	# session check for editing duration
	editingDur: () -> Session.get "editTaskDur"

	# extract hours and minutes from dur/timespent
	parseDur: (d, mod) ->
		if mod is "h" then return "" + Math.floor moment.duration(d).asHours() 
		if mod is "m" then return "" + moment.duration(d).minutes()

	# session check editing notes
	editingNotes: () -> Session.get "editTaskNotes"

	# styling for progress bar
	progStyle: (p) ->
		switch 
			when p < 25 then "danger"
			when p < 50 then "warning"
			when p < 75 then "info"
			else "success"

	# moment dur humanising; d will be wrapped as duration, b is passed to humanize()
	mDurHumanize: (d,b) -> 
		if d? then "<span class='text-info'>"+moment.duration(d).humanize(b)+"</span>"
		else "<span class='text-warning'>None yet</span>"

	# sorting helper for progress list
	sortProg: (lst) ->
		# dir is 1 if asc and -1 if desc
		compF = (a,b,field,dir) ->
			a = a[field]
			b = b[field]
			if a > b then return dir
			if a < b then return -dir
			return 0

		if Session.get "sort-prog-by-dur"
			return lst.sort (a,b) -> compF a, b, "duration", Session.get "sort-prog-dir"
		else
			return lst.sort (a,b) -> compF a, b, "progress_date", Session.get "sort-prog-dir"


Template.task.events

	# generic cancel edit
	"click .task-edit-cancel": (e,tp) ->
		e.preventDefault()
		Session.set e.target.dataset.session, false

	# add task submit
	"submit form": (e,tp) ->
		e.preventDefault()
		tagstr = e.target.tags.value
		tagstr = if tagstr is "" then [] else tagstr.split(',')
		# create addTask args object for debugging
		x = 
			tags: tagstr
			name: e.target.name.value
			due: new Date e.target.due.value
			notes: tp.$("#newTask-notes").code()
			dur: parseInt(e.target.dur_h.value) * 3600000 + parseInt(e.target.dur_m.value) * 60000
			prio: parseInt e.target.prio.value

		if x.name is "" or x.dur <= 0		
			throw "cannot add task with empty name or 0 duration"

		Meteor.call "addTask", x.name, x.due, x.dur, x.prio, x.tags, x.notes, (e,r) -> Router.go("/t/"+r)

	# change active
	"click .task-active-toggle": (e,tp) ->
		e.preventDefault()
		# prevent tooltip clog up
		tp.$(".task-active-toggle").tooltip "destroy"
		Meteor.call "updateTask", tp.data._id, "active", !tp.data.active

	# start editing name
	"click #task-name-edit": (e,tp) ->
		e.preventDefault()
		Session.set "editTaskName", true

	# save edited name
	"click #task-name-save": (e,tp) ->
		e.preventDefault()
		Meteor.call "updateTask", tp.data._id, "name", tp.find("#task-new-name").value, ()->
			Session.set "editTaskName", false
	
	# start editing priority
	"click #task-prio-edit": (e,tp) ->
		e.preventDefault()
		Session.set "editTaskPrio", true
		
	# save new priority
	"click .task-prio-save": (e,tp) ->
		e.preventDefault()
		Meteor.call "updateTask", tp.data._id, "priority", parseInt e.target.dataset.val, ()->
			Session.set "editTaskPrio", false

	# delete individual tag via close btn
	"click .tagbtn > .close": (e,tp) ->
		e.preventDefault()
		tags = [e.target.dataset.tagstr]
		Meteor.call "updateTags", tp.data._id, tags, "remove"

	# start editing tags
	"click #task-tags-edit": (e,tp) ->
		e.preventDefault()
		Session.set "editTaskTags", true

	# save new set of tags
	"click #task-tags-save": (e,tp) ->
		e.preventDefault()
		tagstr = tp.find("#task-set-tags").value
		tagstr = if tagstr is "" then [] else tagstr.split(',')
		Meteor.call "updateTags", tp.data._id, tagstr, "set", ()->
			Session.set "editTaskTags", false

	# start editing due
	"click #task-due-edit": (e,tp) ->
		e.preventDefault()
		Session.set "editTaskDue", true

	# save new due
	"click #task-due-save": (e,tp) ->
		e.preventDefault()
		Meteor.call "updateTask", tp.data._id, "due_date", new Date(tp.find("#task-new-due").value), ()->
			Session.set "editTaskDue", false

	# start editing dur
	"click #task-dur-edit": (e,tp) ->
		e.preventDefault()
		Session.set "editTaskDur", true

	# save new dur
	"click #task-dur-save": (e,tp) ->
		e.preventDefault()
		dur = parseInt(tp.find("#task-new-dur-h").value) * 3600000 + parseInt(tp.find("#task-new-dur-m").value) * 60000
		Meteor.call "updateTask", tp.data._id, "duration", dur, ()->
			Session.set "editTaskDur", false

	# start editing notes
	"click #task-notes-edit": (e,tp) ->
		e.preventDefault()
		tp.$("#task-notes-div").summernote
			focus: true
		Session.set "editTaskNotes", true

	# cancel editing notes
	"click #task-notes-cancel": (e,tp) ->
		e.preventDefault()
		tp.$("#task-notes-div").destroy()

	# save new notes
	"click #task-notes-save": (e,tp) ->
		e.preventDefault()
		Meteor.call "updateTask", tp.data._id, "notes", tp.$("#task-notes-div").code(), ()->
			$("#task-notes-div").destroy()
			Session.set "editTaskNotes", false

	# delete a progress
	"click .del-prog": (e,tp) ->
		e.preventDefault()
		console.log parseInt e.target.dataset.progid
		Meteor.call "removeProgress", tp.data._id, parseInt(e.target.dataset.progid)

	# delete task
	"click #taskDel": (e,tp) ->
		e.preventDefault()
		Meteor.call "removeTask", e.target.dataset.taskid, ()->
			Router.go "/t/index"