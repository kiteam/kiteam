###
  读取API文件，将接口列表返回到客户端
###

_http = require('bijou').http
_router = require '../config/router'

#获取api列表
exports.apis = (client, cb)->
  result = []
  for item in _router
    #暂时忽略正则部分
    continue if item.path instanceof RegExp
    methods = {}
    for key, value of item.methods
      methods[key] = Boolean(value) if not value

    result.push
      url: item.path
      methods: methods

  cb null, result

#获取客户端的i18n数据
exports.i18n = (client, cb)->
  callback = client.query.callback

  #这里需要根据语言获取
#  content = JSON.stringify(_i18n);

  content = "#{callback}(#{content})" if callback
  cb null, content