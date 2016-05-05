# -*- coding: utf-8 -*-  
'''
Created on 2012-10-20

@author: wangl
'''

import socket
from handledata import tDataManage

def connToServer ():
    #创建一个socket连接到127.0.0.1:5200，并发送内容
    connMain = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connMain.connect(("127.0.0.1", 5201))
    tCiphertext = tDataManage.textToCiphertext("get|test")
    connMain.send(tCiphertext)

    #等待主服务端返回子服务器的端口号，并去连接新的子服务器
    rev = connMain.recv(1024)
    print 'get server msg:' + str(rev)
    tText = tDataManage.ciphertextToText(rev)
    print 'get son-server tText:' + str(tText)
    ##连接子服务器
    connSon = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connSon.connect(("127.0.0.1", int(tText)))
    
    tMessageDict = {
                    "user":"wangl",
                    "content":"request-broadcast|Hello world!"
                    }
    #tCiphertext = tDataManage.textToCiphertext(tMessageDict)
    tSendData = "request-broadcast|Hello world!!!"
    tCiphertext = tDataManage.textToCiphertext(tSendData)
    connSon.send(tCiphertext)
    #connSon.send("request-broadcast|Hello world!!!")
    while True:
        rev = connSon.recv(1024)
        print 'get son-server msg:' + str(rev)
        if rev:
            tText = tDataManage.ciphertextToText(rev)
            print 'get son-server tText:' + str(tText)

print "test start!!!"
connToServer()
