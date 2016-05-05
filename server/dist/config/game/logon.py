#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from os.path import join, abspath, dirname
import datetime

app = 'logon'

debug = True
auto_reload = False
use_cache = True
#是否使用gunicorn
use_gunicorn = 0
AES = 1

refresh_time = 10

websvr_port_for_http = 8008
base_server_ip = '127.0.0.1'
local_ip = '127.0.0.1'
inet_ip = 'td.f3322.org' #外网ip
#inet_ip = base_server_ip

#store
db_engine = 'mongodb://td:123456@%s/td_res' % base_server_ip
db_params =dict(max_pool_size=30,)

#sdk91
sdk91_app_id = '111'
sdk91_app_key = '************************************************'

#写入servers.json用
web_config_path = '/var/www/config'

