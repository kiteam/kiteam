_log = require './log'
_notification = require './notification'
_email = require './email'
_error = require './error'
_shared = require '../shared'

module.exports =
	log: _log
	email: _email
	error: _error
	shared: _shared
	http:
		incorrectParamter: '参数非法'
		incorrectFormat: '数据格式不正确'