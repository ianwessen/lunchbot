Botkit = require './lib/Botkit.js'
os = require 'os'
_ = require 'underscore'
moment = require 'moment'

# Utilities
formatUptime = (uptime) ->
	unit = 'second'
	if uptime > 60
		uptime = uptime / 60
		unit = 'minute'
	if uptime > 60
		uptime = uptime / 60
		unit = 'hour'
	if uptime != 1
		unit = unit + 's'
	uptime = uptime + ' ' + unit
	uptime

# Error handling
if !process.env.SLACK_API_KEY
	console.log 'Error: Specify token in environment'
	process.exit 1

# Useful vars
controller = Botkit.slackbot(debug: true, logLevel: 0)
bot = controller.spawn(
	token: process.env.SLACK_API_KEY
)

start_rtm = ->
	bot.startRTM( (err,bot,payload) ->
		if (err)
			console.log('Failed to start RTM')
			return setTimeout(start_rtm, 60000)
		console.log("RTM started!")
	)
	
controller.on 'rtm_close', (bot, err) ->
	start_rtm()

start_rtm()

# Hears & Says
controller.hears [
		"hello"
		"hi"
		"hey"
		"sup"
		"yo"
		"hola"
		"howdy"
		"what's up"
		"how are you"
		"aloha"
		"what's good"
		"how's it going"
		"what's crackin"
	], 'direct_message,direct_mention,mention', (bot, message) ->

		bot.api.reactions.add {
			timestamp: message.ts
			channel: message.channel
			name: 'robot_face'
		}, (err, res) ->
			if err then bot.botkit.log 'Failed to add emoji reaction :(', err

		controller.storage.users.get message.user, (err, user) ->
			greeting = _.sample [
				"Greetings"
				"Hello"
				"Hi"
				"Hiya"
				"Howdy"
			]
			if user and user.name
				bot.reply message, greeting + ' ' + user.name + '!!'
			else
				bot.reply message, greeting + '!'

controller.hears [
	'call me (.*)'
	'my name is (.*)'
	], 'direct_message,direct_mention,mention', (bot, message) ->
		name = message.match[1]
		controller.storage.users.get message.user, (err, user) ->
			if !user
				user = id: message.user
			user.name = name
			controller.storage.users.save user, (err, id) ->
				bot.reply message, 'Got it. I will call you ' + user.name + ' from now on.'

controller.hears [
	'what is my name'
	'who am i'
	], 'direct_message,direct_mention,mention', (bot, message) ->
		controller.storage.users.get message.user, (err, user) ->
			if user and user.name
				bot.reply message, 'Your name is ' + user.name
			else
				bot.startConversation message, (err, convo) ->
					if !err
						convo.say 'I don\'t know your name yet!'
						convo.ask 'What should I call you?', ((response, convo) ->
							console.log "THE RESPONSE: ", response
							console.log "THE CONVO: ", convo
							convo.ask 'You want me to call you `' + response.text + '`?',
							[{
								pattern: 'yes'
								callback: (response, convo) ->
									# since no further messages are queued after this,
									# the conversation will end naturally with status == 'completed'
									convo.next()
							}
							{
								pattern: 'no'
								callback: (response, convo) ->
									# stop the conversation. this will cause it to end with status == 'stopped'
									convo.stop()
							}
							{
								default: true
								callback: (response, convo) ->
									convo.repeat()
									convo.next()
							}]
							convo.next()
						), 'key': 'nickname'
						# store the results in a field called nickname
						
						convo.on 'end', (convo) ->
							if convo.status == 'completed'
								bot.reply message, 'OK! I will update my dossier...'
								controller.storage.users.get message.user, (err, user) ->
									if !user
										user = id: message.user
									user.name = convo.extractResponse('nickname')
									controller.storage.users.save user, (err, id) ->
										bot.reply message, 'Got it. I will call you ' + user.name + ' from now on.'
							else
								# this happens if the conversation ended prematurely for some reason
								bot.reply message, 'OK, nevermind!'

controller.hears [
	'shutdown'
	], 'direct_message,direct_mention,mention', (bot, message) ->
	bot.startConversation message, (err, convo) ->
		convo.ask 'Are you sure you want me to shutdown?', [
			{
				pattern: bot.utterances.yes
				default: true
				callback: (response, convo) ->
					convo.say "`I'm sorry Dave, I'm afraid I can't do that.`"
					convo.say ":hal9000:"
					convo.next()
			}
			{
				pattern: bot.utterances.no
				default: true
				callback: (response, convo) ->
					convo.say '*Phew!*'
					convo.next()
			}
		]

controller.hears [
	'uptime'
	'identify yourself'
	'who are you'
	'what is your name'
	], 'direct_message,direct_mention,mention', (bot, message) ->
		hostname = os.hostname()
		uptime = formatUptime(process.uptime())
		bot.reply message, ':robot_face: I am a bot named <@' + bot.identity.name + '>.
		I have been running for ' + uptime + ' on ' + hostname + '.'

controller.hears [
	'lunch today'
	'what\'s for lunch'
	'what\'s for lunch?'
	'what\'s for lunch today'
	'what\'s for lunch today?'
	'what\'s the lunch today'
	'what\'s the lunch today?'
	], 'direct_message,direct_mention,mention', (bot, message) ->
		lunchWeek = ((moment().format('W') + 3) % 4) + 1
		bot.reply message, "Check out the lunch schedule: https://goo.gl/u9c5U6. It's currently week " + lunchWeek + "."
