module.exports = [
  {
    path: 'project/:project_id(\\d+)/member'
    biz: 'project'
    methods: delete: 'removeMember', put: 'addMember', post: 'addMember', get: 'getMembers'
    allowGuest: ['get']
  },
#  {
#  #查看某个项目下的所有commit
#  #提交commit，用于git或svn提交commit时，自动获取commit并分析，需要指定project_id
#    path: 'project/:project_id(\\d+)/git/commit'
#    biz: 'commit'
#    methods: post: 'postCommit', get: 0, delete: 0, patch: 0, put: 0
#  },
#  {
#    #更改issue的所有者及计划
#    path: 'project/:project_id(\\d+)/issue/:issue_id(\\d+)/plan'
#    biz: 'issue'
#    suffix: false,
#    methods: put: 'changeOwnerOrSchedule', get: 0, delete: 0, patch: 0, post: 0
#  },
  #0 #doing @功能 增加改变owner和计划完成时间的接口

  {
  #获取一个项目的所有素材
    path: 'project/:project_id(\\d+)/assets'
    biz: 'asset'
    methods: post: '{uploadFile}', delete: 'remove', patch: 0, put: 0
    allowGuest: ['get']
  },

  {
  #获取一个项目的所有素材
    path: 'project/:project_id(\\d+)/webhook'
    biz: 'webhook'
  },

  {
  #获取素材的缩略图
    path: 'project/:project_id(\\d+)/asset/:asset_id/thumbnail'
    biz: 'asset'
    methods: get: '{thumbnail}', delete: 0, patch: 0, put: 0, post: 0
  },
  {
  #获取素材的文件
    path: 'project/:project_id(\\d+)/asset/:asset_id/read'
    biz: 'asset'
    methods: get: '{readAsset}', delete: 0, patch: 0, put: 0, post: 0
  },
  {
  ##展开zip的素材
    path: 'project/:project_id(\\d+)/assets/:asset_id/unwind'
    biz: 'asset'
    suffix: false
    methods: get: 'unwind', post: 0, delete: 0, patch: 0, put: 0
  },
  {
  #issue相关
    path: 'project/:project_id(\\d+)/member/invite'
    biz: 'invite'
  },
  {
  #获取项目的统计情况
    path: 'project/:project_id(\\d+)/stat'
    biz: 'issue'
    methods: get: 'statistic', post: 0, delete: 0, patch: 0, put: 0
  },
  {
    path: 'project/:project_id(\\d+)/discussion'
    biz: 'issue'
    methods: put: 0, post: 0, delete: 0, patch: 0, get: 'getDiscussion'
    allowGuest: ['get']
  }
  {
  #项目分类
    path: 'project/:project_id/category'
    biz: 'issue_category'
    allowGuest: ['get']
  },
  {
  #项目版本
    path: 'project/:project_id/version'
    biz: 'version'
    allowGuest: ['get']
  }
  {
  #上传文件，用于评论中的附件
    path: 'project/:project_id/attachment/(:filename)?'
    biz: 'attachment'
    suffix: false,
    methods: post: '{uploadFile}', get: '{readFile}'
  },
  {
  #路由地址
    path: 'project'
    allowGuest: ['get']
  },
  {
    #收藏项目
    path: 'project/:project_id/favorite'
    biz: 'favorite'
    suffix: false
    methods: get: 0, patch: 0, put: 0
  }
  {
    path: 'project/git-map'
    biz: 'git_map'
    data: type: 'project'
    methods: post: 0, put: 0, delete: 0
  }
  {
    ###
      Author: ec.huyinghuan@gmail.com
      Date: 2015.07.06
      Describe: 项目中gitlab的增删查
    ###
    path: 'project/:project_id/gitlab'
    biz: 'git_map'
    data: type: 'project'
    methods: get: 'getAllGitsInProject', put: 'addGitToProject', post: 'createGitForProject', delete: 'delOne'
    allowGuest: ['get']
  }
  {
    #fork项目
    path: 'project/:project_id/gitlab/:gitlab_id/fork'
    biz: 'git_map'
    data: type: 'project'
    methods: get: 'fork', put: 0, delete: 0
  }
  {
    #获取项目中所有自己的git仓库地址
    path: 'project/:project_id/owned-gits'
    biz: 'git_map'
    data: type: 'project'
    methods: get: 'getProjectOwnedGitsList', post: 0, put: 0, delete: 0
  }

]