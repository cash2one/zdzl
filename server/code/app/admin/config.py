#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from os.path import join


SERVER_VER_CONFIG   = 'admin'
SERVER_HOST_PORT    = 8000

admin_path = join(os.environ['ROOT_PATH'], 'serveradmin')

CONFIG_DATA_VER             = '/Users/kainwu/Documents/wukehong/hahahaha/'

RESOUCE_ROOT 				= '/Users/kainwu/pic/'
MONGO_BACKUP_PATH           = '/home/game/backup/'

WEBAPI_PORT = 5005
WEBAPI_HOST = 'web1.zl.52yh.com'
WEBAPI_URL = '/api/info'

class BaseConfig(object):
    """ Flask配置文件 """
    CSRF_ENABLED                = False
    SECRET_KEY                  = '0\xda\xb3+xAj\x88\x98\x00\x02\xcaR\x9d\xb5QD\x0c\x1aX"\x89{S'
    SITE_NAME                   = u'efun游戏管理'
    ADMINS                      = ('wukehong86@gmail.com')
    DEBUG                       = True
    MONGOALCHEMY_DATABASE       = 'efun'
    MONGOALCHEMY_SERVER         = 'dev.zl.efun.com'
    MONGOALCHEMY_PORT           = '27017'
    MONGOALCHEMY_USER           = 'td'
    MONGOALCHEMY_PASSWORD       = '123456'

    # mongoengine
    MONGODB_SETTINGS = {'DB': MONGOALCHEMY_DATABASE, 'USERNAME': '',
                        'PASSWORD': '', 'HOST': MONGOALCHEMY_SERVER,
                        'PORT': int(MONGOALCHEMY_PORT)}

try:
    from local_config import *
except ImportError:
    pass
