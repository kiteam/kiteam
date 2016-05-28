_path = require("path")
_bijou = require("bijou")
_async = require 'async'
_fs = require 'fs-extra'
_ = require 'lodash'
_moment = require 'moment'

_common = require './common'
_entity = require './entity'
_memberBiz = require './biz/member'
_realtime = require './notification/realtime'
_cache = require './cache'
_staticRouter = require './config/routers/static'

getMemberWithToken = (token, cb)->
  _entity.token.findMemberId token, (err, member)->
    member =
      member_id: member?.id
      role: member?.role

    member.isLogin = member.member_id > 0
    cb member

#记住用户密码
getMemberWithRemember = (req, cb)->
  member = member_id: 0, isLogin: false
  member_id = req.cookies.member_id
  return cb member if not member_id

  #从数据库中查找
  _entity.member.findById member_id, (err, result)->
    return cb member if err or not result

    _memberBiz.setSession req, result
    member.member_id = result.id
    member.role = result.role
    member.isLogin = true
    cb member

#从session中获取member
getMemberWithSession = (req, cb)->
  #从session中读取token
  member_id = req.session.member_id || -1

  #如果用户没有登录，则判断是否有记住密码
  if not member_id
    return getMemberWithRemember req, cb if req.cookies.remember and req.cookies.member_id

  #直接从session获取
  member =
    role: req.session.role
    member_id: member_id
    isLogin: member_id > 0
    gitlab_token: req.session.gitlab_token

  cb member

#获取用户的基本信息
getMember = (req, cb)->
  #读取token
  token = req.headers['x-token']
  return getMemberWithToken token, cb if token

  getMemberWithSession req, cb


#初始化静太路由
initStaticRouter = (app, router)->
  app.get router.path, (req, res, next)->
    target = router.to.replace(/\$(\d+)/g, (all, index)->
      return req.params[parseInt(index) - 1]
    )

    target = _path.join __dirname, target
    res.sendfile target

#初始化静态路由列表
initStaticRouters = (app)->
  _staticRouter.forEach (router)-> initStaticRouter app, router

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
    routers: require './config/router'
    #处理之前
    onBeforeHandler: (client, req, cb)->
      getMember req, (member)->
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
    getMemberWithSession req, (member)->
      return if not member.isLogin
      _realtime.online member.member_id, req.socket

  app.io.route 'message', (req)->
    getMemberWithSession req, (member)->
      return if not member.isLogin
      _realtime.receiveMessage member.member_id, req.data

  #io = require('socket.io').listen(server, log: false)
#  app.io.on 'connection', (socket)->
#    #客户端已经准备好
#
#    socket.on 'disconnect', -> #console.log this

#默认的路由，转到首页
initDefaultRouter = (app)->
  target = _path.join __dirname, '../static/index.html'
  app.get '*', (req, res, next)-> res.sendfile target

module.exports = (app)->
  console.log "Staring..."
  initRealtime app
  initStaticRouters app
  initBijou app
  initDefaultRouter app