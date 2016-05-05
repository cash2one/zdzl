#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from os.path import join, abspath, dirname
import datetime
debug = True
auto_reload = False
use_cache = True
#是否使用gunicorn
use_gunicorn = True
AES = 1

app_path = dirname(abspath(dirname(__file__)))
root_path = os.environ['ROOT_PATH']
templates_path = join(app_path, 'templates')
static_path = join(app_path, 'static')

refresh_time = 10 #每10秒更新数据

websvr_port_for_http = 8080
#admin_port = websvr_port_for_http - 1
#写入servers.json用
web_config_path = '/var/www/config'
base_server_ip = 'dev.zl.efun.com'
local_ip = '127.0.0.1'
inet_ip = base_server_ip #外网ip

#store
db_engine = 'mongodb://td:123456@%s/td_res' % base_server_ip
db_params =dict(max_pool_size=30,)

#webapp
api_url = '/api'

##sdk91
#sdk91_app_id = '100010'
#sdk91_app_key = 'C28454605B9312157C2F76F27A9BCA2349434E546A6E9C75'
#sdk91_urls = ('service.sj.91.com', 80, '/usercenter/AP.aspx')
#测试
#sdk91_urls = ('mobileusercenter.sj.91.com', 80, '/usercenter1/Default.aspx')

try:
    from local_config import *
except ImportError:
    pass
