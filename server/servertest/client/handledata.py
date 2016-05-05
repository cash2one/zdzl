# -*- coding: utf-8 -*-  
'''
Created on 2012-10-25

@author: wangl
'''

'''
            处理数据
    textToCiphertext() 对python数据进行转json、加密、压缩
    ciphertextToText() 对json数据进行解压、解密、转python数据
'''

from Crypto.Cipher import AES    
from Crypto import Random
import json, zlib

key = b'Sixteen byte key'   
mode = AES.MODE_CBC
ADD_CHAR = "="

class HandleData():
    def __init__(self):
        #self.iv = Random.new().read(AES.block_size)
        self.iv = "1"*16
    
    #将数据转为json并加密压缩返回
    def textToCiphertext(self, aDataDict):
        #将字典数据转为json格式的数据
        tEncodedjson = json.dumps(aDataDict, skipkeys=True)
        #进行数据加密（加密内容要保证是16的倍数）
        tEncryptor = AES.new(key, mode, self.iv)
        #保证数据时16的倍数
        tAddNum = AES.block_size - len(tEncodedjson) % AES.block_size
        if tAddNum != AES.block_size:
            tEncodedjson = tEncodedjson + tAddNum * ADD_CHAR
        tChipherData = tEncryptor.encrypt(tEncodedjson)
        #压缩数据返回给客户端（数据格式包括：iv+真实数据）
        return zlib.compress(self.iv+tChipherData)
    
    #将接收到的客户端数据解压解密解json返回python数据
    #aClientdata = iv+data
    def ciphertextToText(self, aClientdata):
        #解压
        tChipherData = zlib.decompress(aClientdata)
        #获取iv
        tClientIv = tChipherData[:AES.block_size]
        if tClientIv!=self.iv:
            return None
        tChipherData = tChipherData[AES.block_size:]
        #解密
        tDecryptor = AES.new(key, mode, self.iv)
        tEncodedjson = tDecryptor.decrypt(tChipherData)
        ##由json数据转为python数据
        tAddNum = tEncodedjson[-15:].count(ADD_CHAR)
        if tAddNum:
            tEncodedjson = tEncodedjson[:tAddNum*-1]
        if tEncodedjson:
            return json.loads(tEncodedjson)
        else:
            return None
#初始化数据处理管理器
tDataManage = HandleData()
