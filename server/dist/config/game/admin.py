#!/usr/bin/env python
# -*- coding:utf-8 -*-

app = 'admin'
SERVER_VER_CONFIG	= 'admin'
SERVER_HOST_PORT	= 8000 

dmin_path = join(os.environ['ROOT_PATH'], 'serveradmin')

CONFIG_DATA_VER             = '/var/www/config/ver/'
MONGO_BACKUP_PATH           = '/home/game/backup/'
RESOUCE_ROOT		    = '/var/www/'

class BaseConfig(object):
    """ Flask配置文件 """
    CSRF_ENABLED                = False
    SECRET_KEY                  = '0\xda\xb3!xAj\x88\x98\x00\x02\xcaR\x9d\xb5QD\x0c\x1aX"\x89{s'
    SITE_NAME                   = u'efun游戏管理'
    ADMINS                      = ('wukehong86@gmail.com')
    DEBUG                       = True
    MONGOALCHEMY_DATABASE       = 'efun'
    MONGOALCHEMY_SERVER         = '127.0.0.1'
    MONGOALCHEMY_PORT           = '27017'
    MONGOALCHEMY_USER           = None
    MONGOALCHEMY_PASSWORD       = None
    
    MONGODB_SETTINGS = {'DB': MONGOALCHEMY_DATABASE, 'USERNAME': '',
                        'PASSWORD': '', 'HOST': MONGOALCHEMY_SERVER,
                        'PORT': int(MONGOALCHEMY_PORT)}
