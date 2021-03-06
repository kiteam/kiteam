###
  issue
###
_entity = require '../entity'
_async = require 'async'
_common = require '../common'
_memberEntity = require '../entity/member'
_versionEntity = require '../entity/version'
_moment = require 'moment'
_path = require 'path'
_comment = require './comment'
_http = require('bijou').http
_notifier = require '../notification'
_issueNotifier = require '../notification/issue'
_logBiz = require './log'
_cache = require '../cache'
_ = require 'lodash'
_guard = require './guard'

#更新日志
writeUpdateLog = (member, data)->
  logContent = '更新'

  if data.owner
    logContent = "指派任务->#{_cache.member.get(data.owner)?.realname || data.owner}"
  else if data.plan_finish_time
    logContent = "指定任务完成时间->#{_moment(data.plan_finish_time).format('YYYY-MM-DD hh:mm')}"
  else if data.category_id
    logContent = "变更分类->#{data.category_id}"
  else if data.version_id
    logContent = "变更版本->#{data.version_id}"
  else if data.status
    logContent = "更改状态->#{_common.statusDescription data.status}"
  else if data.priority
    logContent = "更改优先级->#{data.priority}"

  exports.writeLog member.member_id, data.id, logContent

#更新issue后的通知消息
afterUpdateNotifier = (data, member_id)->
  #更改状态的通知
  if data.status
    _issueNotifier.changeStatus member_id, data.id
  #改了完成时间或者指定了任务
  else if data.plan_finish_time or data.owner
    _issueNotifier.takeTask member_id, data.id, data

#issue的操作日志
exports.writeLog = (member_id, issue_id, content)->
  _logBiz.writeLog member_id, 'issue', issue_id, content


#更新issue
exports.updateIssue = (client, cb)->
  project_id = client.params.project_id
  data = client.body
  _.extend data,
    project_id: client.params.project_id
    id: client.params.id

  queue = []
  #必需要是项目中的成员，才能修改
  queue.push(
    (done)->
      #wiki和运维类的，所有人都可以修改
      return done null if _guard.projectIsWiki(project_id) || _guard.projectIsService(project_id) || project_id is "all"
      _guard.projectPermission data.project_id, client.member, '*-g', (err)-> done err
  )

  #保存数据
  queue.push(
    (done)->
      #完成任务
      if data.status is 'done'
        _entity.issue.finishedIssue data.id, client.member.member_id, done
      else
        delete data.project_id if project_id is "all"
        _entity.issue.save data, done
  )

  _async.waterfall queue, (err)->
    return cb err if err
    cb err

    #没有错误才写入日志s
    writeUpdateLog(client.member, data) if not err

    #更新后，如果有需要，通知用户
    afterUpdateNotifier data, client.member.member_id


#重载save
exports.createIssue = (client, cb)->
  project_id = client.params.project_id

  data = client.body
#  console.log data.tag
  data.project_id = project_id
  data.creator = client.member.member_id
  data.timestamp = Number(new Date())
  data.priority = data.priority || 3
  data.status = _common.checkStatus data.status
  data.tag = _common.checkTag data.tag
  data.always_top = Boolean(data.always_top)
#  console.log data.tag

  queue = []

  #检查重复，不允许同一个人10分钟内创建同名的任务
  queue.push(
    (done)->
      cond =
        creator: data.creator
        title: data.title
        project_id: data.project_id
        status: data.status

      options =
        beforeQuery: (query)->
          beforeTenMin = _moment().subtract(10, 'minutes').valueOf()
          query.where 'timestamp', '>', beforeTenMin

      _entity.issue.findOne cond, options, (err, result)->
        return done err if err
        err = _http.notAcceptableError('请不要重复提交数据') if result
        done err
  )

  #权限检查
  queue.push(
    (done)->
      #wiki和运维类的，所有人都可以添加
      return done null if _guard.projectIsWiki(project_id) || _guard.projectIsService(project_id)
      #允许成员中的所有人，但不包括客人
      _guard.projectPermission project_id, client.member, '*-g', (err)-> done err
  )

  #新建的issue必需在某个版本下
  queue.push(
    (done)->
      return done null if data.version_id
      #获取活动的版本
      cond = project_id: project_id, status: 'active'
      _versionEntity.findOne cond, (err, result)->
        data.version_id = result.id if result
        done err
  )

  queue.push(
    (done)-> _entity.issue.save data, done
  )

#  queue.push(
#    (id, done)->
#      data =
#        issue_id: id
#        member_id: client.member.member_id
#      _entity.issue_follow.save data, (err, result)->
#        done err, id
#  )

  _async.waterfall queue, (err, id)->
    result = id: data.id || id
    cb err, result

    #处理提到某人
    filter = []
    #仅限管理员可以提到所有人
    filter.push 'all' if client.member.role isnt 'a'

    names = _common.extractMention filter, data.title, data.content
    _notifier.mention names, result.id, null

    #日志
    exports.writeLog client.member.member_id, result.id, '创建'


#查询issue
exports.getIssue = (client, cb)->
  id = client.params.id
  #根据id查询

  if id

    queue = []

    queue.push(
      (done)->
        _entity.issue.getSingleIssue id, client.member.member_id, (err, result)->
          done err, result
    )

    queue.push(
      (issue, done)->
        return done null, issue if issue.splited is 0
        _entity.issue_split.getSplitIssue id, (err, result)->
          issue.splitArr = result if !err
          done err, issue
    )

    _async.waterfall queue, (err, issue)->
      return cb err, issue

  else
    cond =
      tag: client.query.tag
      status: client.query.status
      hash: client.query.hash
      keyword: client.query.keyword
      myself: client.query.myself
      follow: client.query.follow
      member_id: client.member.member_id
      category_id: client.query.category_id
      version_id: client.query.version_id
      
    cond.project_id = client.params.project_id if client.params.project_id isnt "all"

    pagination = _entity.issue.pagination client.query.pageIndex, client.query.pageSize

    _entity.issue.fetch cond, pagination, cb


###
  获取项目的讨论
  1. tag为project
  2. 有comment的issue
###
exports.getDiscussion = (client, cb)->
  cond =
    project_id: client.params.project_id
    keyword: client.query.keyword

  pagination = _entity.issue.pagination client.query.pageIndex, client.query.pageSize
  _entity.issue.getDiscussion cond, pagination, cb

#统计测试任务
exports.statTestIssue = (client, cb)->
  project_id = client.params.project_id
  _entity.issue.statTestIssue project_id, cb

exports.toString = -> _path.basename __filename