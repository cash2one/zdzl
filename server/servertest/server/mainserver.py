# -*- coding: utf-8 -*-  
'''
Created on 2012-10-17

@author: wangl
'''
import os
if os.name!='nt':
    from twisted.internet import epollreactor
    epollreactor.install()    
else:
    from twisted.internet import iocpreactor
    iocpreactor.install()

from twisted.internet.protocol import Factory,Protocol
from twisted.internet import reactor

from sockmana import sockMana
from handledata import tDataManage

import openserver
import constant

class MainServer(Protocol):
    #有新用户连接至服务器
    def connectionMade(self):
        sockMana.addClient(self)
        print 'New Client link MainServer!'
    
    #客户端断开连接
    def connectionLost(self, reason):
        sockMana.delClient(self)
        print 'MainServer Lost Client!'
    
    #收到客户端发送数据
    def dataReceived(self, data):
        print '===========Mainserver-Get data=========:' + str(data)
        tText = tDataManage.ciphertextToText(data)
        print '===========Mainserver-Get tText=========:' + str(tText)
        tMsgList = tText.split('|')
        if tMsgList[0] == 'get': #获取连接（由子客户端传来）
            #将按连接数进行由小到大排序
            tMin = sorted(openserver.PORTNUM.items(), key=lambda d:d[1])
            print "(tMinPort, tMinNum) = (%s, %s)",(tMin[0][0], tMin[0][1])
            #所有进程最小连接数与设的上限相比较，达到开启新进程
            if tMin[0][1]>=constant.SON_CONN_MAX_NUM:
                #开启新进程（子服务器）
                openserver.openSonServer()
                tPort = openserver.NOWPORT-1
            else:
                #返回人数最少进程的端口
                tPort = tMin[0][0]
            tCiphertext = tDataManage.textToCiphertext(str(tPort))
            self.transport.write(tCiphertext)
            self.transport.loseConnection()
        elif tMsgList[0]=='add': #连接成功（由子进程传来）
            openserver.PORTNUM[int(tMsgList[1])] +=1
        elif tMsgList[0]=='del': #断开连接（由子进程传来）
            openserver.PORTNUM[int(tMsgList[1])] -=1
        elif tMsgList[0]=='request-broadcast': #广播数据
            tSonServers = sockMana.getClients()
            if len(tSonServers):
                print "tMsgList[1]=", tMsgList[1]
                print "tMsgList[1]type=", type(tMsgList[1])
                tCiphertext = tDataManage.textToCiphertext("mainServer-broadcast|" + tMsgList[1])
                for tSonServer in tSonServers:
                    tSonServer.transport.write(tCiphertext)
            

if __name__=='__main__':
    #初始化开启子服务器
    for i in range(constant.START_SON_SERVER_NUM):
        openserver.openSonServer()
    print 'mainserver started...'
    f = Factory()
    f.protocol = MainServer
    reactor.listenTCP(constant.MAIN_SERVER_PORT, f)
    reactor.run()



