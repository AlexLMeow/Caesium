###
/client/views/auth.coffee
###

Template.auth.onRendered () ->

	$("html").niceScroll()

Template.auth.helpers
	
	registering: () ->
		Session.get "register-acc"

	# boolean, if there was a login error
	loginErr: () ->
		Session.get "login-err"

	# boolean, if there was a signup error
	signupErr: () ->
		Session.get "signup-err"

Template.auth.events
	
	# toggle form to signup
	"click .login-switchregister": (e, tp) ->
		e.preventDefault()
		Session.set "register-acc", true
		Session.set "login-err", false

	# toggle form to login
	"click .login-switchlogin": (e, tp) ->
		e.preventDefault()
		Session.set "register-acc", false
		Session.set "signup-err", false

	# log user in
	"submit form.form-signin": (e, tp) ->
		e.preventDefault()
		console.log e.target
		email = e.target.email.value
		pass = e.target.password.value

		# treat form submit as register
		if Session.get "register-acc"

			Accounts.createUser { 
					email: email
					password: pass
				}, (err)-> 
				if err? 
					Session.set "signup-err", true
				else
					Meteor.loginWithPassword {email: email}, pass, (err) ->
						if err?
							Session.set "login-err", true
						else Router.go "home"

		# treat form submit as login
		else
			Meteor.loginWithPassword {email: email}, pass, (err) ->
				if err?
					Session.set "login-err", true
				else Router.go "home"


	#remove login error label
	"click #login-err": (e, tp) ->
		e.preventDefault()
		Session.set "login-err", false
	# remove signup erro label
	"click #signup-err": (e, tp) ->
		e.preventDefault()
		Session.set "signup-err", false
