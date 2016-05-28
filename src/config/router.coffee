_path = require("path")
_entity = require '../entity'
_staticRouter = require './routers/static'
_common = require '../common'
_ = require 'lodash'

#获取静态文件的路径
getStaticFile = (file)->
  _path.join _path.dirname(require.main.filename), '../', file

#初始化静态路由
initStaticRouter = (app, router)->
  app.get router.path, (req, res, next)->
    target = router.to.replace(/\$(\d+)/g, (all, index)->
      return req.params[parseInt(index) - 1]
    )

    res.sendfile getStaticFile(target)

#根据token获取用户
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
getMemberWithSession = exports.getMemberWithSession = (req, cb)->
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

#获取所有的API路由列表
exports.all = [].concat(
  require('./routers/member'),
  require('./routers/issue'),
  require('./routers/project'),
  require('./routers/report'),
  require('./routers/other')
)

#默认的路由，转到首页
exports.initOtherwise = (app)->
  target = _path.join __dirname, '../../', 'static/index.html'
  console.log(target)
  app.get '*', (req, res, next)-> res.sendfile target

#初始化静态路由列表
exports.initStatic = (app)->
  _staticRouter.forEach (router)-> initStaticRouter app, router


#获取用户的基本信息
exports.getMember = (req, cb)->
  #读取token， 优先使用token
  token = req.headers['x-token']
  return getMemberWithToken token, cb if token
  getMemberWithSession req, cb

#路由级权限许可，仅请求访问权限， 不包含具体的数据权限，数据权限由程序自己处理
exports.requestPermission = (client, router, action)->
#允许匿名的路由或者用户已经登录，则允许访问
  return true if client.member.isLogin or _.indexOf(router.anonymity || [], action) >= 0
  #如果开启了访客模式，并且路由在许诺的列表内，允许用户访问
  return true if _common.config.guestModel and _.indexOf(router.allowGuest || [], action) >= 0
  return false