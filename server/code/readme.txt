服务程序帮助：

运行环境：
	python2.7
	virtualenv
	virtualenvwrapper
	pip
	fabric

依赖包：
	greenlet>=0.3
	gevent>=0.13.x
	grpc
	python-daemon>=1.6
	pymongo
	absolute32
	psutil
	urllib3,
	msgpack-python
	
	#psyco,
	M2Crypto,
	python-crypto,

启动命令：
	python main.py <app> run
	守护进程方式启动和停止：
	python main.py <app> start
	python main.py <app> stop
	监控当前运行的log信息
	python main.py <app> log


	<app>为对应的子项目，具体有：
	logon: 游戏登陆程序
	game: 游戏程序
	test: 运行测试框架
	client: 模拟客户端

目录说明：
	game：游戏逻辑
	app：游戏进程目录，里面每一个目录就是一个独立的<app>进程
	client：模拟端
	test：单元、功能测试
	lib：游戏库
	tools：工具目录
	res：资源目录，如：本地化资源等
	
  






