app = 'game'

#ip
base_server_ip = '127.0.0.1'
local_ip = '127.0.0.1'
inet_ip = 'dev.zl.efun.com' #外网ip
#inet_ip = '172.16.8.10' #外网ip
#web
servers_json_url = (base_server_ip, 80, '/config/servers.json')
#logon url
logon_url = (base_server_ip, 8008, '/api')

#subgame address
base_port = 8001 #游戏服起始端口
max_subgame = 7 #最大逻辑子进程数

max_players = 2000 #单服最大在线数
logic_players = 100 #单逻辑进程达到这个数后开始新逻辑进程

#逻辑进程配置

#store
db_engine = 'mongodb://td:123456@%s/td' % base_server_ip
db_params =dict(max_pool_size=30,)
db_engine_res = 'mongodb://td:123456@%s/td_res' % base_server_ip
db_params_res =dict(max_pool_size=5, pool_set_size=5)
db_engine_log = 'mongodb://td:123456@%s/td_log' % base_server_ip
db_params_log =dict(max_pool_size=10,)

#战报访问的基础url
fight_report_base_url = 'http://%s:801/config/report/td' % inet_ip
#战报保存路径
fight_report_base_dir = '/var/www/config/report/td'

#是否强制启动支付回调处理功能
vip_pay_back = 1

