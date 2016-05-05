# -*- coding: utf-8 -*-  
'''
Created on 2012-10-22

@author: wangl
'''

#保存客户端与服务端的对应关系
class SockMana:
    def __init__ (self):
        self.sockNum = 0 #记录当前的在线总数
        self.sockIndex = 1 #累加sockid
        self.client2id = {} #保存client->sockid字典
        self.id2client = {} #保存sockid->client字典

    def addClient(self, client):
        #增加一个客户端
        print '** add client **'
        self.sockNum = self.sockNum + 1
        self.client2id[client] = self.sockIndex
        self.id2client[self.sockIndex] = client
        self.sockIndex = self.sockIndex + 1

    def delClient(self,client):
        #删除一个客户端
        print '** del client **'
        if client in self.client2id:
            self.sockNum = self.sockNum - 1
            _sockid = self.client2id[client]
            del self.client2id[client]
            del self.id2client[_sockid]

    def getSockid(self,client):
        #通过client获取sockid
        if client in self.client2id:
            return self.client2id[client]
        else:
            return None
        
    def getClient(self,sockid):
        #通过sockid获取client
        if sockid in self.id2client:
            return self.id2client[sockid]
        else:
            return None    
    
    def getClients(self):
        return self.client2id.keys()

#初始化连接管理器
sockMana = SockMana()

