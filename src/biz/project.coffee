###
  项目
###
_ = require 'lodash'
_async = require 'async'
_path = require 'path'
_http = require('bijou').http

_entity = require '../entity'
_common = require '../common'
_notifier = require '../notification'
_cache = require '../cache'
_realtime = require '../notification/realtime'
_guard = require './guard'
_config = require('../common').config


#获取项目详情
getProjectDetails = (client, cb) ->
  project = {}
  project_id = client.params.id
  queue = []

  #找到项目
  queue.push(
    (done)->
      _entity.project.findById project_id, (err, result)->
        return done _http.notFoundError() if not result
        project = result
        done err
  )

  #判断是否需要返回成员
  queue.push(
    (done)->
      return done null if client.query.get_member isnt 'true'

      _entity.project_member.projectMembers project_id, (err, members)->
        project.members = members
        done err
  )

  #判断是否需要返回gits
  queue.push(
    (done)->
      return done null if client.query.get_git isnt 'true'

      _entity.git_map.findProjectGits project_id, (err, result)->
        project.gits = result
        done err
  )

  #获取当前用户在项目中的角色
  queue.push(
    (done)->
      # return done null if client.query.get_role isnt 'true'

      role = _cache.projectMember.getRole project_id, client.member.member_id
      project.role = role
      #特殊项目中，给用户设置默认角色
      project.role = (project.role || 't') if project.flag is 1
      done null
  )

  _async.waterfall queue, (err)-> cb err, project

#保存数据
exports.save = (client, cb)->
  data = client.body
  data.id = client.params.id
  isUpdate = Boolean(data.id)
  #更新，则检查leader的权限
  queue = []
  queue.push(
    (done)->
      return done null if not isUpdate
      #修改项目仅leader可以
      _guard.projectPermission data.id, client.member, (err)-> done err
  )

  #project不存在，创建project
  queue.push(
    (done)->
      data.creator = client.member.member_id if not isUpdate
      _entity.project.unionSave data, client.member, (err, result)->
        done err, result
  )

  _async.waterfall queue, (err, result)->
    #更新缓存
    _cache.gitMap.load()
    #更新成员的缓存
    _cache.projectMember.load result.id, client.member.member_id


    cb err

#查找数据
exports.get = (client, cb)->
  id = client.params.id
  member_id = client.member.member_id
  return getProjectDetails(client, cb) if id

  pagination = _entity.project.pagination client.query.pageIndex, client.query.pageSize

  cond =
    #查看自己的项目
    member_id: member_id
    #允许查看指定权限的项目
    role: client.query.role
    #查询关键字
    keyword: client.query.keyword

  cond.myself = true if client.query.myself

  #admin允许全部项目
  cond.member_id = null if client.member.role is 'a'
  #是否包括特殊项目
  cond.special = Boolean(client.query.special)
  _entity.project.fetch cond, pagination, cb


#移除成员
exports.removeMember = (client, cb)->
  cond =
    project_id: client.params.project_id
    member_id: client.params.id

  queue = []
  queue.push(
    (done)-> 
      # 允许自己退出
      return done null if parseInt(client.params.id) is parseInt(client.member.member_id) 

      _guard.projectPermission cond.project_id, client.member, (err)-> done err
  )

  #执行任务，并要求权限
  queue.push(
    (done)->
      _entity.project_member.remove cond, (err)-> done err
  )

  _async.waterfall queue, (err)->
    cb err

    #将用户踢出项目的房间
    _realtime.leaveProject cond.project, cond.member_id
    #更新成员的缓存
    _cache.projectMember.load cond.project_id, cond.member_id


#添加项目成员，如果存在，则修改
exports.addMember = (client, cb)->
  data =
    project_id: client.params.project_id
    member_id: client.params.id
    role: _common.projectRoleValidator client.body.role

  #用于post一个id
  data.member_id = data.member_id || client.body.member_id

  return cb _http.notAcceptableError '数据格式不正确' if not data.member_id or not data.role

  queue = []
  queue.push(
    (done)-> _guard.projectPermission data.project_id, client.member, (err)-> done err
  )

  queue.push(
    (done)->
      _entity.project_member.saveOrUpdate data, (err, id)->
        data.id = id
        done err
  )

  _async.waterfall queue, (err)->
    #先返回，不用等
    cb err, id: data.id

    #通知与实时推送
    _realtime.joinProject data.project_id, data.member_id
    _notifier.joinProject data.project_id, data.member_id, client.member.member_id
    #更新成员的缓存
    _cache.projectMember.load data.project_id, data.member_id


#获取项目成员
exports.getMembers = (client, cb)->
  project_id = client.params.project_id
  _entity.project_member.projectMembers project_id, cb

exports.toString = -> _path.basename __filename