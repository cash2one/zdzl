# -*- coding: utf-8 -*-  
'''
Created on 2012-10-17

@author: wangl
'''
import os, sys
if os.name!='nt':
    from twisted.internet import epollreactor
    epollreactor.install()    
else:
    from twisted.internet import iocpreactor
    iocpreactor.install()

from twisted.internet import reactor, protocol

from sockmana import sockMana
from handledata import tDataManage

import constant

class SonServer(protocol.Protocol):
    #有新用户连接至服务器
    def connectionMade(self):
        print 'New Client link sonserver port : %s' % str(tPort)
        #空则是该服务器与主服务器的连接，保留连接对象
        #否则是由玩家连接到该服务器，告知主服务器连接了新用户
        global oConnMain
        print "oConnMain==",oConnMain
        if oConnMain:
            sockMana.addClient(self)
            tSendData = tDataManage.textToCiphertext("add|"+ str(tPort))
            oConnMain.transport.write(tSendData)
        else:
            oConnMain = self
    
    #客户端断开连接
    def connectionLost(self, reason):
        sockMana.delClient(self)
        print 'Lost Client link sonserver port : %s' % str(tPort)
        #连接主服务器告知 有用户断开此端口
        global oConnMain
        tSendData = tDataManage.textToCiphertext("del|"+ str(tPort))
        oConnMain.transport.write(tSendData)
    
    #收到客户端发送数据
    def dataReceived(self, data):
        print 'Get data:' + str(data)
        #解析数据
        tText = tDataManage.ciphertextToText(data)
        
        #向该客户端发送数据
        #self.transport.write('your sockid is:'+ str(sockMana.getSockid(self)))
        
        tMsgList = tText.split('|')
        if tMsgList[0] == 'request-broadcast': #请求广播数据
            #将数据发送给主服务器，由主进程发送给子服务器进行全服广播
            global oConnMain
            oConnMain.transport.write(data) 
        elif tMsgList[0] =='mainServer-broadcast': #进行广播
            #广播给当下服务器所有连接的用户
            tClients = sockMana.getClients()
            print "(port , len)==(%d, %d)" % (tPort, len(tClients))
            tCiphertext = tDataManage.textToCiphertext(str(tMsgList[1]))
            for tClient in tClients:
                tClient.transport.write(tCiphertext)
            
class SonClientFactory(protocol.ClientFactory):
    protocol = SonServer
    
    def startedConnecting(self, connector):
        print 'Started to connect.'
    
    def buildProtocol(self, addr):
        print 'Connected.'
        return SonServer()
    
    def clientConnectionLost(self, connector, reason):
        print 'Lost connection.  Reason:', reason
    
    def clientConnectionFailed(self, connector, reason):
        print 'Connection failed. Reason:', reason


if __name__=='__main__':
    print 'sonserver started port...%s ' % sys.argv[1]
    #保存与主服务器的连接
    oConnMain = None
    #开启的端口号
    tSonFactory = SonClientFactory()
    #与主服务器保持连接
    reactor.connectTCP(constant.MAIN_SERVER_IP, constant.MAIN_SERVER_PORT, tSonFactory)
    
    #开启自服务器
    tPort = int(sys.argv[1])
    f = protocol.Factory()
    f.protocol = SonServer
    reactor.listenTCP(tPort,f)
    reactor.run()
    





