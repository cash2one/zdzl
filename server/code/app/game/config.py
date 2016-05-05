#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys
from os.path import join, abspath, dirname

debug = 1
monitor = 1
sys_encoding = os.environ['sys_encoding']
#逻辑服启动类型:
RT_SINGLE = 1 #单进程方式
RT_NORMAL = 2 #一般方式
run_type = RT_NORMAL


##路径设置
root_path = os.environ['ROOT_PATH']
res_base_dir = join(root_path, 'res')
locale_code = 'zh_CN'
#log_path = os.environ['LOG_PATH']
#配置文件所在目录,linux系统下用于存放配置、sock等文件
cfg_path = dirname(__file__)

#ip
base_server_ip = 'dev.zl.efun.com'
local_ip = '127.0.0.1'
inet_ip = local_ip #外网ip
#web
servers_json_url = (base_server_ip, 80, '/config/servers.json')
#logon url
logon_url = (base_server_ip, 8000, '/api')

#subgame address
base_port = 8001 #游戏服起始端口
max_subgame = 50 #最大逻辑子进程数

max_players = 4000 #单服最大在线数
logic_players = 200 #单逻辑进程达到这个数后开始新逻辑进程
logic_pool = 1 #逻辑进程保留数

#逻辑进程配置

#store
db_engine = 'mongodb://td:123456@%s/td' % base_server_ip
db_params =dict(max_pool_size=30,)
db_engine_res = 'mongodb://td:123456@%s/td_res' % base_server_ip
db_params_res =dict(max_pool_size=5, pool_set_size=5)
db_engine_log = 'mongodb://td:123456@%s/td_log' % base_server_ip
db_params_log =dict(max_pool_size=10,)
db_engine_pay = None
db_params_pay = None

#同场景人数上限
scene_cap = 50

#REPORT
report_times = 1 * 60 #报告时间

#战报访问的基础url
fight_report_base_url = 'http://%s/config/td/report' % base_server_ip
#战报保存路径
fight_report_base_dir = os.path.join(root_path, 'runtime', 'report')
#fight_report_base_dir = '/var/www/config/td/report'

#client
client_rpc_aes_key = '4fcc09d3ceb79129'

#是否强制启动支付回调处理功能
vip_pay_back = 0

##加载本地特有的配置
try:
    from local_config import *
except ImportError:
    pass


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


