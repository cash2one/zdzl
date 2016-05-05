# -*- coding: utf-8 -*-  
'''
Created on 2012-10-17

@author: wangl
'''
from handledata import tDataManage
import socket,stackless
sockIndex = 1

def connToServer ():
    global sockIndex
    #创建一个socket连接到127.0.0.1:5200，并发送内容
    connMain = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connMain.connect(("127.0.0.1", 5201))
    tCiphertext = tDataManage.textToCiphertext("get|"+ str(sockIndex))
    connMain.send(tCiphertext)
    print sockIndex
    sockIndex = sockIndex + 1

    while True:
        #等待主服务端返回子服务器的端口号，并去连接新的子服务器
        tMainRev = connMain.recv(1024)
        ##连接子服务器
        if tMainRev:
            print 'get main-server ciphertext:' + str(tMainRev)
            tText = tDataManage.ciphertextToText(tMainRev)
            print 'get main-server tText:' + str(tText)
            connSon = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            connSon.connect(("127.0.0.1", int(tText)))
#            while True:
#                tSonRev = connSon.recv(1024)
#                if tSonRev:
#                    print 'get son-server msg:' + str(tSonRev)
#                stackless.schedule()

        stackless.schedule()

#先来500个并发试试
for i in range(0,13):
    #创建微进程并将其添加到调度器
    stackless.tasklet(connToServer)()

stackless.run()
