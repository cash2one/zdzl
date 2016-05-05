# -*- coding: utf-8 -*-  
'''
Created on 2012-10-17

@author: wangl
'''
import os
import subprocess

from server.config import constant

#｛端口号:连接数...｝
PORTNUM = {}
# 预开启端口号 
NOWPORT = constant.SON_SERVER_PORT_START

#开启一个新的端口 进程
def openSonServer():
    global NOWPORT, PORTNUM
    PORTNUM[NOWPORT] = 0
    print "start-NOWPORT::",NOWPORT
    subprocess.Popen('python '+os.getcwd()+'/openserver/sonserver.py ' + str(NOWPORT)+ '', shell=False)
    NOWPORT+=1
    
#openSonServer()




