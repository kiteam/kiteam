_path = require("path")
_bijou = require("bijou")
_async = require 'async'
_fs = require 'fs-extra'
_ = require 'lodash'
_moment = require 'moment'

_common = require './common'
_memberBiz = require './biz/member'
_realtime = require './notification/realtime'
_cache = require './cache'
_routers = require './config/router'


#初始化bijou
initBijou = (app)->
  #console.log _moment
  _moment.locale('zh-cn')
  options =
    log: process.env.DEBUG
    root: '/api/'
    #指定数据库链接
    database: _common.config.database
    #指定业务逻辑的文件夹
    biz: './biz'
    #指定路由的配置文件
    routers: _routers.all
    #处理之前
    onBeforeHandler: (client, req, cb)->
      _routers.getMember req, (member)->
        client.member = member
        cb null, client
    #请求访问许可
    requestPermission: (client, router, action, cb)->
      allow =  _common.config.guestModel || #访客模式
        _.indexOf(router.anonymity || [], action) >= 0 ||   #允许匿名访问
        client.member.isLogin #用户已经登录
      cb null, allow

  _bijou.initalize(app, options)

  queue = []
  queue.push(
    (done)->
      #扫描schema，并初始化数据库
      schema = _path.join __dirname, './schema'
      _bijou.scanSchema schema, done
  )

  #加载缓存
  queue.push(
    (done)->
      #_authority.init ->
      _cache.init (err)-> done err
  )

  _async.waterfall queue, (err)->
    console.log err if err
    console.log 'Kiteam is running now!'

#初始化实时讨论
initRealtime = (app)->
  #获取用户的基本信息，如果用户不存在，则将用户加入到房间
#  app.get '*', (req, res, next)->
#    res.socket
#    next()
  _realtime.init app

  app.io.route 'ready', (req)->
    _routers.getMemberWithSession req, (member)->
      return if not member.isLogin
      _realtime.online member.member_id, req.socket

  app.io.route 'message', (req)->
    _routers.getMemberWithSession req, (member)->
      return if not member.isLogin
      _realtime.receiveMessage member.member_id, req.data

  #io = require('socket.io').listen(server, log: false)
#  app.io.on 'connection', (socket)->
#    #客户端已经准备好
#
#    socket.on 'disconnect', -> #console.log this


module.exports = (app)->
  console.log "Staring..."
  initRealtime app
  _routers.initStatic app
  initBijou app
  _routers.initOtherwise app