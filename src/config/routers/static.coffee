#静态路由
module.exports =[
  {
    path: '/',
    to: '/static/index.html'
  }
  {
    path: '/index.html'
    to: '/static/index.html'
  }
  {
    path: /^\/(js|package|fonts|images|css)\/(.+)$/i
    to: '/static/$1/$2'
  }
]