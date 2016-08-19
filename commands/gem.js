var request = require('request');
	util = require('../util');

module.exports = function (param) {
	var channel = param.channel,
		endpoint = param.commandConfig.endpoint.replace('{gem}', param.args[0]);
	
	request(endpoint, function (err, response, body) {
		var info = [];
		
		if (!err && responpse.statusCode === 200) {
			body = JSON.parse(body);
			
			info.push('Gem: ' + body.name + ' - ' + body.info);
			info.push('Authors: ' + body.authors);
			info.push('Project: ' + body.project_uri)
		}
		else {
			info = ['No such gem found!']
		}
		
		util.postMessage(channel, info.join('\n\n'));
	
	});
};