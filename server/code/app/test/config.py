#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys
import random
import locale
sys_encoding = locale.getdefaultlocale()[1]
if sys_encoding is None:
	sys_encoding = 'UTF-8'

from os.path import join
import socket

debug = 1

##路径设置
app_path = os.path.abspath(os.path.dirname(__file__)).decode(sys_encoding)
root_path = os.environ['ROOT_PATH'] if 'ROOT_PATH' in os.environ else app_path
log_path = join(app_path, 'log')
pid_file = join(app_path, 'pidfile')
res_dir = join(root_path, 'res')

##protobuf相关配置
protobuf_src_path = join(app_path, '..', 'protobuf')
full_name_map_msg_id_path = join(app_path, '..', 'full_name_map_msg_id', 'full_name_map_msg_id.xml')

base_server_ip = 'dev.zl.efun.com'
local_ip = socket.gethostbyname(socket.gethostname())


#store
db_engine = 'mongodb://td:123456@%s/td' % base_server_ip
db_params =dict(max_pool_size=30,)
db_engine_res = 'mongodb://td:123456@%s/td_res' % base_server_ip
db_params_res =dict(max_pool_size=5, pool_set_size=5)
db_engine_log = 'mongodb://td:123456@%s/td_log' % base_server_ip
db_params_log =dict(max_pool_size=10,)



##加载本地特有的配置
try:
	from local_config import *
except ImportError:
	pass



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



