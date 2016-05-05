#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
import locale
sys_encoding = locale.getdefaultlocale()[1]
if sys_encoding is None:
	sys_encoding = 'UTF-8'

debug = 1

##路径设置
app_path = os.path.abspath(os.path.dirname(__file__)).decode(sys_encoding)


#client
client_rpc_aes_key = '4fcc09d3ceb79129'

#登陆压力测试
#web端口
over_login_web_addr = ('0.0.0.0', 8113)
#服务器的ip
over_login_ip = 'dev.zl.efun.com'
#服务器端口
over_login_port = 8002
#登陆的玩家最大数目
over_login_player_nums = 1000

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



