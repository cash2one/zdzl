#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys

if __name__ == '__main__':
    sys.path.insert(0, '..')

import gevent
from gevent import coros, queue, GreenletExit, getcurrent
import socket
import random
import struct
#from StringIO import StringIO
from cStringIO import StringIO
from zlib import compress, decompress


import corelib
from corelib import log, is_ujson, json

ZLIB_LEVEL = 1
DEBUG_PACK = 0

PRE_MSG = 'RPCMSG'
PRE_MSG_LEN = len(PRE_MSG)
BUFFER_SIZE = 1024

#heartbeat
hb_fmt = '!I'
hb_packet_size = struct.calcsize(hb_fmt)
hb_pkt = struct.pack(hb_fmt, hb_packet_size)

class BasePacker(object):
    @classmethod
    def aes_init(cls, key):
        from corelib.aes import new_aes_encrypt
        cls.aes_encrypt = staticmethod(new_aes_encrypt(key))
        cls.AES = 1

    def pack(self, msg):
        pass
    def raw_pack(self, data):
        """ SafeClientRpc:返回一个没有包长度的二进制包 """
        pass
    def safe_pack_raw(self, raw_data, token, adler_value):
        """ SafeClientRpc: """
    def safe_pack(self, data, token, adler_value):
        """ SafeClientRpc: """

class BaseUnPacker(object):
    aes_decrypt = 0
    def aes_init(self, key):
        from corelib.aes import new_aes_decrypt
        self.aes_decrypt = new_aes_decrypt(key)

    def raw_unpack(self, tag, data):
        """ 解一个没有长度的包数据 """
    def unpack(self, data):
        pass
    def set_token(self, token):
        """ SafeClientRpc: """


class BufferUnPacker(BaseUnPacker):
    _head_fmt = '!H'
    _head_size = struct.calcsize(_head_fmt)
    def __init__(self):
        self._buffer = StringIO()
        if not hasattr(self, '_head_next_size'):
            self._head_next_size = self._head_size - hb_packet_size

    def _buffer_size(self):
        cur_pos = self._buffer.tell()
        self._buffer.seek(0, 2)
        size = self._buffer.tell()
        self._buffer.seek(cur_pos)
        return size - cur_pos

    def unpack(self, data):
        #往最后添加数据
        #log.debug('unpack:%s', repr(data))
        global hb_packet_size, hb_pkt
        cur_pos = self._buffer.tell()
        self._buffer.seek(0, 2)
        self._buffer.write(data)
        #定位回当前位置
        self._buffer.seek(cur_pos)
        packages = []
        size = self._buffer_size()
        while size > self._head_size:
            #heartbeat
            data = self._buffer.read(hb_packet_size)
            if data == hb_pkt:
                size -= hb_packet_size
                continue
            if self._head_next_size:
                data = '%s%s' % (data, self._buffer.read(self._head_next_size))
            tag, need =struct.unpack(self._head_fmt, data)
            #need = struct.unpack(self._head_fmt, self._buffer.read(self._head_size))[0]
            if need == 0:#心跳
                #log.debug(u'收到心跳包')
                size -= self._head_size
                continue

            size -= (need + self._head_size)
            if size < 0:
                #定位回头,用于下次读取
                self._buffer.seek(-self._head_size, 1)
                break

            data = self._buffer.read(need)
            t = self.raw_unpack(tag, data)
            if t is not None:
                packages.append(t)

        if not size and self._buffer.tell() > 0:
            self._buffer.truncate(0)
        return packages

JSON_HEAD_FMT = '!2sL'
class JsonPacker(BasePacker):
    _head_fmt = JSON_HEAD_FMT
    ZIP = 1
    AES = 0
    @staticmethod
    def _json_default(o):
        return o.__dict__

    def pack(self, msg):
        if DEBUG_PACK: log.debug('pack:%s', msg)
        tag = msg.pop('_tag')
        if is_ujson:
            #ujson支持object对象,并且直接输出最短结构
            data = json.dumps(msg, ensure_ascii=False)
        else:
            data = json.dumps(msg, ensure_ascii=False,
                    default=self._json_default,
                    separators=(',', ':'))
            #ensure_ascii=False时,json输出unicode, ujson输出utf8str
            if isinstance(data, unicode):
                data = data.encode('utf-8')
        if self.ZIP:
            data = compress(data, ZLIB_LEVEL)
        if self.AES:
            data = self.aes_encrypt(data)
        l = len(data)
        return struct.pack('%s%ds' % (self._head_fmt, l), tag, l, data)

class JsonUnPacker(BufferUnPacker):
    _head_fmt = JSON_HEAD_FMT
    _head_size = struct.calcsize(_head_fmt)
    UNZIP = 1
    AES = 0
    def raw_unpack(self, tag, data):
        """ 解一个没有长度的包数据 """
        if self.aes_decrypt:
            data = self.aes_decrypt(data)
        if self.UNZIP:
            #log.debug('raw_unpack:%s', repr(data))
            try:
                data = decompress(data)
            except:
                log.error('decompress:%s', repr(data[:50]))
                raise
        adict = json.loads(data)
        adict['_tag'] = tag
        return adict


class AbsExport(object):
    _rpc_attr_pre = 'rc_'
    def on_close(self, rpcobj):
        pass

def get_cur_rpc():
    gl = getcurrent()
    return getattr(gl, '_game_client_rpc_', None)

class NormalClientRpc(object):
    #处理函数名缓存
    _names_ = {}
    _rpc_attr_pre = AbsExport._rpc_attr_pre
    timeout = socket.getdefaulttimeout()
    if not timeout:
        timeout = 60
    timeout = 60 * 30 #TODO: 暂时将超时设长，方便前端调试
    delay_time = 60 #超时的延迟时间
    #改成类属性，所有对象共用一个
    _packer = BasePacker()
    _unpacker_cls = BaseUnPacker
    _aes_key = None

    @classmethod
    def aes_encrypt(cls, data):
        return cls._packer.aes_encrypt(data)

    @classmethod
    def aes_init(cls, key, pack=0, unpack=0):
        if pack:
            cls._packer.aes_init(key)
        if unpack:
            NormalClientRpc._aes_key = key
        else:
            NormalClientRpc._aes_key = 0

    def __init__(self, sock, addr, export = None):
        self._sock = sock
        self.addr = addr
        self._unpacker = self._unpacker_cls()
        if self._aes_key:
            self._unpacker.aes_init(self._aes_key)
        self._loop_task = None
        self._send_queue = queue.Queue()
        self._slock = coros.Semaphore()
        self._is_server = True
        self.set_export(export)
        #是否让call_func关联rpc
        self.call_link_rpc = False

    def set_export(self, export):
        self._rpc_attr_pre = getattr(export, '_rpc_attr_pre', '')
        self._names_ = NormalClientRpc._names_.setdefault(self._rpc_attr_pre, {})
        self._export = export
        self._export_funcs = {}

    def set_timeout(self, timeout):
        self.timeout = timeout

    def heartbeat(self):
        """ 心跳 """
        fmt = hb_fmt
        packet_size = hb_packet_size
        pkt = hb_pkt
        htime = int(self.timeout / 2)
        while True:
            gevent.sleep(htime)
            try:
                with self._slock:
                    if self.stoped:
                        break
                    self._sock.sendall(pkt)
            except GreenletExit:
                break
            except:
                log.log_except()
                break

        log.info('[client_rpc]heartbeat stop:%s' % (self.addr, ))
        corelib.spawn(self.stop)

    def _send_let(self):
        """ 处理发送消息队列 """
        while not self.stoped:
            msg = self._send_queue.get()
            if self.stoped:
                break
            if not self.send_imme(msg):
                break

    def _loop(self):
        readfunc = self._sock.recv
        try:
            while 1:
                data = readfunc(BUFFER_SIZE)
                if not data:
                    break
                self._process(data)
        except socket.error, e:
            log.error('[ClientRpc]socket error:%s' % e)
        except gevent.GreenletExit:
            pass
        except:
            log.log_except()
        log.info('[ClientRpc]loop stop:%s' % (self.addr, ))
        corelib.spawn(self.stop)

    def _process(self, data):
        raise NotImplementedError

    def _get_handle(self, msg_name):
        """ 获取远程函数对象 """
        try:
            func_name = self._names_[msg_name]
        except KeyError:
            func_name = self._rpc_attr_pre + msg_name.replace('.', '_')
            self._names_[msg_name] = func_name

        try:
            return self._export_funcs[func_name]
        except KeyError:
            func = getattr(self._export, func_name, None)
            if func is None:
                log.error(u'对象(%s)中，远程调用本地函数(%s)未找到' % (self._export, msg_name))
            self._export_funcs[func_name] = func
            return func

    def _before_call(self):
        if not self.call_link_rpc:
            return
        gl = getcurrent()
        gl._game_client_rpc_ = self

    def _after_call(self):
        if not self.call_link_rpc:
            return
        gl = getcurrent()
        gl._game_client_rpc_ = None

    def _call_func(self, func, msg):
        rs = None
        self._before_call()
        try:
            rs = func(msg)
            if rs is not None:
                self.send(rs)
        except StandardError:
            log.log_except('func(%s), rs(%s)', func, rs)
        finally:
            self._after_call()


    def start(self):
        if not self.stoped:
            return
        self._sock.settimeout(self.timeout + self.delay_time)
        self._loop_task = corelib.spawn(self._loop)
        self._heartbeat_task = corelib.spawn(self.heartbeat)
        self._send_task = corelib.spawn(self._send_let)


    @property
    def stoped(self):
        return self._loop_task is None

    def stop(self):
        if self.stoped:
            return
        self._loop_task.kill(block=False)
        self._loop_task = None
        self._heartbeat_task.kill(block=False)
        self._heartbeat_task = None
        self._send_task.kill(block=False)
        self._send_task = None
        if self._sock is not None:
            self._sock.close()
            self._sock = None
        on_close = getattr(self._export, 'on_close', None)
        if on_close:
            corelib.spawn(on_close, self)

    @classmethod
    def prepare_send(cls, msg):
        if isinstance(msg, str):
            if msg.startswith(PRE_MSG):
                return msg
            else:
                raise ValueError, 'can not send str type:%s' % repr(msg)
        else:
            data = cls._packer.pack(msg)
            return PRE_MSG + data

    def send(self, msg):
        """ 用消息队列发送消息 """
        data = self.prepare_send(msg)
        self._send_queue.put(data)

    def send_imme(self, msg):
        """ 立即发送
        msg:必须为字符串或者protobuf对象,
        在外部将protobuf对象序列化后，直接发送字符串，能优化速度
        """
        if isinstance(msg, str):
            if msg.startswith(PRE_MSG):
                data = msg[PRE_MSG_LEN:]
            else:
                raise ValueError, 'can not send str type:%s' % repr(msg)
        else:
            data = self._packer.pack(msg)
##        length = len(data)
        #log.debug('[rpc]send:%s-%s' % (self.addr, msg.DESCRIPTOR.full_name))
        try:
            with self._slock:
#                self._sock.sendall(hb_pkt+data) #TODO: 测试
                self._sock.sendall(data)
            return True
        except socket.error, e:
            log.error('[clientRpc]error:(%s)%s' % (id(self), e))
            corelib.spawn(self.stop)
            return False

    def after_rpc_client(self):
        self._is_server = False

    @classmethod
    def rpc_client(cls, host, port, export):
        sock = socket.socket()
        sock.connect((host, port))
        rpc = cls(sock, (host, port), export)
        rpc.after_rpc_client()
        return rpc

    @staticmethod
    def pack_msg(msg_name, status, data=None, err=None):
        """ 打包协议 """
        raise NotImplementedError

#import absolute32
class SafeClientRpc(NormalClientRpc):
    """ 安全的链接 """
    #改成类属性，所有对象共用一个
    _packer = BasePacker()
    _unpacker_cls = BaseUnPacker

    def __init__(self, *args, **kw):
        NormalClientRpc.__init__(self, *args, **kw)
        self.adler_value = 1

    def _init(self):
        self._unpacker.set_token(self._r_token)

    def handshake_svr(self):
        """ 握手 """
        sock = self._sock
        try:
            #2
            seq = struct.unpack('!i', sock.recv(4))[0]
            token = absolute32.hash(corelib.uuid())
            token_md5 = corelib.get_md5(token, digest=True)
            seq_seed = token ^ seq
            sock.sendall(struct.pack('!i', seq_seed))

            #4
            c_token_md5 = sock.recv(16)
            if token_md5 != c_token_md5:
                self.stop()
                return
            #w_token = absolute32.add(token, 4) ^ token
            #sock.sendall(struct.pack('ii', w_token, 1))
            w_token = token
            sock.sendall(struct.pack('!i', 1))
            self._w_token = w_token
            self._r_token = token
            self._init()
        except:
            sock.close()
            raise

    def handshake_client(self):
        """ 握手 """
        sock = self._sock
        try:
            #1
            seq = random.randint(-99999, 99999)
            sock.sendall(struct.pack('!i', seq))

            #3
            seq_seed = struct.unpack('!i', sock.recv(4))[0]
            token = seq_seed ^ seq
            token_md5 = corelib.get_md5(token, digest=True)
            sock.sendall(token_md5)

            #5
            #r_token, rs = struct.unpack('ii', sock.recv(8))
            rs = struct.unpack('!i', sock.recv(4))[0]
            if rs != 1:
                self.stop()
                return
            #self._r_token = r_token
            self._r_token = token
            self._w_token = token
            self._init()
        except:
            sock.close()
            raise

    def start(self):
        if not self.stoped:
            return
        self._sock.settimeout(self.timeout + self.delay_time)
        if self._is_server:
            self.handshake_svr()
        super(SafeClientRpc, self).start()

    def heartbeat(self):
        """ 心跳 """
        fmt = hb_fmt
        packet_size = hb_packet_size
        pkt = hb_pkt
        htime = int(self.timeout / 2)
        while True:
            gevent.sleep(htime)
            try:
                if self.stoped:
                    break
                with self._slock:
                    #log.debug(u'发心跳包')
                    self._sock.sendall(pkt)
            except GreenletExit:
                break
            except:
                log.log_except()
                break

        log.info('[client_rpc]heartbeat stop:%s' % (self.addr, ))
        corelib.spawn(self.stop)

    def after_rpc_client(self):
        self.handshake_client()
        NormalClientRpc.after_rpc_client(self)

    @classmethod
    def prepare_send(cls, msg):
        if isinstance(msg, str):
            if msg.startswith(PRE_MSG):
                return msg
            else:
                raise ValueError, 'can not send str type:%s' % repr(msg)
        else:
            data = cls._packer.raw_pack(msg)
            return PRE_MSG + data

    def send_imme(self, msg):
        """ 立即发送
        msg:必须为字符串或者protobuf对象,
        在外部将protobuf对象序列化后，直接发送字符串，能优化速度
        """
        if isinstance(msg, str):
            if msg.startswith(PRE_MSG):
                data = msg[PRE_MSG_LEN:]
                data, self._w_token, self.adler_value = \
                    self._packer.safe_pack_raw(data, self._w_token, self.adler_value)
            else:
                raise ValueError, 'can not send str type:%s' % repr(msg)
        else:
            data, self._w_token, self.adler_value = \
                self._packer.safe_pack(msg, self._w_token, self.adler_value)
        try:
            with self._slock:
                self._sock.sendall(data)
            return True
        except socket.error, e:
            log.error('[clientRpc]error:%s' % e)
            corelib.spawn(self.stop)
            return False

class JsonClientRpc(NormalClientRpc):
    #改成类属性，所有对象共用一个
    _packer = JsonPacker()
    _unpacker_cls = JsonUnPacker
    def _process(self, data):
        msgs = self._unpacker.unpack(data)
        if DEBUG_PACK: log.debug('read data:%s, msgs=%s', len(data), msgs)
        for m in msgs:
            tag = m.pop('_tag')
            full_name = m['f']
            func = self._get_handle(full_name)
            if func:
                corelib.spawn(self._call_func, func, tag, m)
            else:
                self.send(self.pack_msg(full_name, 0, err=1, tag=tag))


    @staticmethod
    def pack_msg(msg_name, status, data=None, err=None, tag=None):
        if tag is None:
            tag = '\xff\xbc'
        rs = {'_tag':tag, 'f':msg_name, 's':1 if bool(status) else 0}
        if data is not None:
            rs['d'] = data
        if err:
            rs['m'] = err
        return rs

    def raw_call_func(self):
        """ 模拟端用来获取详细call信息 """
        if self._raw_call_func == self._call_func:
            return
        self._call_func_old = self._call_func
        self._call_func = self._raw_call_func

    def un_raw_call_func(self):
        if not hasattr(self, '_call_func_old'):
            return
        self._call_func = self._call_func_old

    def _raw_call_func(self, func, tag, m):
        status, msg, err = m.get('s', 1), m.get('d'), m.get('m')
        rs = None
        self._before_call()
        try:
            rs = func(msg, _status=status, _err=err)
            if rs is not None:
                if isinstance(rs, dict) and '_tag' in rs:
                    #hack无奈做法,给pack_msg用
                    rs['_tag'] = tag
                self.send(rs)
        except StandardError:
            log.log_except('func(%s), rs(%s)', func, rs)
        finally:
            self._after_call()


    def _call_func(self, func, tag, m):
        status, msg, err = m.get('s', 1), m.get('d'), m.get('m')
        rs = None
        self._before_call()
        try:
            rs = func(**msg) if msg else func()
            if rs is not None:
                if isinstance(rs, dict) and '_tag' in rs:
                    #hack无奈做法,给pack_msg用
                    rs['_tag'] = tag
                self.send(rs)
        except StandardError:
            log.log_except('func(%s)(%s), rs(%s)', func, msg, rs)
        finally:
            self._after_call()



if 0:
    from corelib.pb2.protocol import Pb2Unpacker, Pb2Packer, SafePb2Unpacker, SafePb2Packer
    class Pb2ClientRpc(NormalClientRpc):
        _packer = Pb2Packer()
        _unpacker_cls = Pb2Unpacker
        def _process(self, data):
            msgs = self._unpacker.unpack(data)
            #log.debug('read data:%s, msgs=%s', len(data), msgs)
            for m in msgs:
                full_name = m.DESCRIPTOR.full_name
                if full_name.startswith('com.shendian.protobuf.'):
                    func_name = full_name.replace('com.shendian.protobuf.', '')
                func = self._get_handle(full_name)
                if func:
                    corelib.spawn(self._call_func, func, m)
    class Pb2SafeClientRpc(Pb2ClientRpc):
        _packer = Pb2Packer()
        _unpacker_cls = SafePb2Unpacker


def test_pb2():
    from corelib.pb2 import etc
    from protobuf import rpc_pb2
    log.console_config(log.DEBUG)
    etc.init('../protobuf', '../full_name_map_msg_id/full_name_map_msg_id.xml')
    testobj = rpc_pb2.RpcTest()
    testobj.id = 1
    testobj.name = 'client'
    return Pb2SafeClientRpc, testobj

def test_json():
    return JsonClientRpc, {'f':'rpc_RpcTest', 'd':{'name':'client'}}

def main():
    log.console_config()
    #rpc_cls, testobj = test_pb2()
    rpc_cls, testobj = test_json()

    class _Export(AbsExport):
        def __init__(self, name):
            self.name = name
        def _rc_rpc_RpcTest(self, msg):
            name = getattr(msg, 'name', None)
            if not name:
                name = msg['name']
            print '[%s] get %s' % (self.name, name)
            gevent.sleep(0.5)
            return testobj

        def _rc_raise_except(self, msg):
            raise ValueError, str(msg)

    def _on_accept(sock, addr):
        svr_obj = _Export('server')
        proxy = rpc_cls(sock, addr, svr_obj)
        proxy.start()
        while not proxy.stoped:
            corelib.sleep(1)

    from gevent.server import StreamServer
    svr = StreamServer(('localhost', 32346), _on_accept)
    svr.start()

    cproxy = rpc_cls.rpc_client('localhost', 32346, _Export('client'))
    cproxy.start()
    cproxy.send(testobj)
    gevent.sleep(10)
    cproxy.stop()

if __name__ == '__main__':
    main()


