module.exports = {
  "database": {
    "client": "mysql",
    "connection": {
      "host": "localhost",
      "user": "root",
      "password": "123456",
      "database": "bhf"
    }
  },
  "redis": {
    "server": "localhost",
    "port": 6379,
    "database": 0,
    "unique": "bhf-kiteam"
  },
  "gitlab": {
    "hooks": "http://xxxxx",
    "url": "http://git.xxxx.com",
    "token": "xxxxxx",
    "api": "http://git.xxx.com/api/v3",
    "database": {
      "host": "localhost",
      "user": "gitlab",
      "password": "gitlab",
      "database": "gitlabhq"
    }
  },
  "storage": {
    "base": "./storage",
    "avatar": "avatar",
    "assets": "assets",
    "uploads": "uploads",
    "uploadTemporary": "uploadTemporary"
  },
  "notification": {
    "email": true,
    "weixin": true,
    "client": true,
    "webhook": true
  },
  "rootAPI": "/api/",
  "port": 8001,
  "allowRegister": true,
  "thumbnail": {
    "width": 100,
    "height": 80
  },
  "host": "http://bhf.hunantv.com/"
}