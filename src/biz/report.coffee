###
  报表
###
_entity = require '../entity'
_common = require '../common'
_ = require 'lodash'
_async = require 'async'
_http = require('bijou').http
_notifier = require '../notification'
_moment = require 'moment'
_converter = require './report_converter'


#指定时间段，所有项目的issue完成量的统计
exports.projectIssueFinishStat = (client, cb)->
  startTime = client.query.startTime
  endTime = client.query.endTime
  _entity.report.projectIssue startTime, endTime, cb

exports.memberIssueFinishStat = (client, cb)->
  startTime = client.query.startTime
  endTime = client.query.endTime
  _entity.report.memberIssue startTime, endTime, cb

exports.teamIssueFinishStat = (client, cb)->
  team_id = client.params.team_id
  startTime = client.query.startTime
  endTime = client.query.endTime
  _entity.report.teamIssue team_id, startTime, endTime, cb


#根据团队Id获取团队周报
exports.weeklyOfTeam = (client, cb)->
  #查询报表的条件
  cond =
    member_id: client.member.member_id
    start_time: Number(client.query.start_time)
    end_time: Number(client.query.end_time)

  cond.start_time = _moment().startOf('week').valueOf() if isNaN(cond.start_time)
  cond.end_time = _moment().endOf('week').valueOf() if isNaN(cond.end_time)
  cond.team_id = client.params.team_id if client.params.team_id
  cond.project_id = client.query.project_id if client.query.project_id
  cond.all = true if client.query.project_id

  projects = 
    items: [
      {
        report: {}  
      }
    ]

  queue = []
  queue.push(
    (done)->
      _entity.issue.report cond, (err, result)->
        projects.items[0].report = result
        done err
  )

  queue.push(
    (done)->
       _entity.report.find {time: cond.start_time}, (err, result)->
        done err, result
  )


  _async.waterfall queue, (err, result)->
    cb err, new _converter(projects.items, result)


exports.save = (client, cb)->
  cond = client.body
  cond.member_id = client.member.member_id
  _entity.report.save cond, (err, result)->
    cb err,result


exports.get = (client, cb)->
  cond = 
    member_id: client.member.member_id
    time: client.query.time
  _entity.report.findOne cond, (err,result)->
    cb err,result

exports.toString = -> 'biz.report'