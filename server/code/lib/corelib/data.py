#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
import array
import base64

from struct import unpack

import log
from common import make_lv_regions

#根据系统位数,选择合适的类型
sizeof_digit = sys.long_info.sizeof_digit
if sizeof_digit == 2:#32位系统
    UNIT = 'L'
elif sizeof_digit == 4:#64位系统
    UNIT = 'I'
else:
    raise ValueError('sys.long_info.sizeof_digit error:%s' % sizeof_digit)

class IntBiteMap(object):
    """
    说明：正整数biteMap
    """
    __slots__ = ('len', 'map')
    def __init__(self):
        self._init_map()

    def _init_map(self, data=None):
        if data:
            self.len = len(data) / 4
            self.map = array.array(UNIT, str(data))
        else:
            self.len = 0
            self.map = array.array(UNIT)
            #for i in xrange(151):
            #    self.insert(i)
            #log.debug('_init_map(data=%s):%s', data, self.map)

    def __getstate__(self):
        return self.len, self.map

    def __setstate__(self, data):
        self.len, self.map = data

    def _inc_map(self, len):
        #step = 0 #每次增加时，增加多1字节
        inc = len - self.len# + step
        self.len = len# + step
        self.map.extend((0L, ) * inc)

    @property
    def max_int(self):
        return self.len * 32

    def _value(self, insert, value):
        len = (value+1) / 32 + 1
        if len >= self.len:
            self._inc_map(len)
        index_Hash = value / 32 % self.len
        index_int = value % 32
        if insert:
            self.map[index_Hash] = (self.map[index_Hash] | (1<<index_int))
        else:
            self.map[index_Hash] = (self.map[index_Hash] & ~(1<<index_int))

    def clear(self):
        self._init_map()

    def insert(self, value):
        self._value(1, value)

    def delete(self, value):
        self._value(0, value)

    def trunate(self, value):
        """ 切去大于value的数据 """
        len = (value+1) / 32 + 1
        if len >= self.len:
            return
        index_Hash = value / 32 % self.len
        index_int = value % 32
        self.map = self.map[:index_Hash+1]
        for i in xrange(index_int+1, 32):
            self.map[index_Hash] = (self.map[index_Hash] & ~(1<<i))

    def __iter__(self):
        bi = 0
        for i in xrange(self.len):
            v = self.map[i]
            if not v:
                bi += 32
                continue

            for j in xrange(32):
                bi += 1
                if v & (1<<j):
                    yield bi



    def __contains__ (self, value):
        if  value >= self.len * 32:
            return False
        try:
            index_Hash = value / 32 % self.len
            index_int = value % 32
            if (self.map[index_Hash] & (1<<index_int)):
                return True
            else :
                return False
        except:
            log.log_except('map=%s, len=%s, ih=%s, ii=%s, value=%s',
                    self.map, self.len, index_Hash, index_int, value)

    def __str__(self):
        return self.to_string()

    def to_string(self):
        return str(self.map.tostring())

    def from_string(self, data):
        self._init_map(data=data)

    def to_base64(self):
        return base64.b64encode(str(self.map.tostring()))

    def from_base64(self, data):
        data = str(data)
        try:
            data = base64.b64decode(str(data))
            self.from_string(data)
        except TypeError:
            self.from_string(data)

    @classmethod
    def new(cls, data):
        m = cls()
        m.from_string(data)
        return m

    @classmethod
    def new_base64(cls, data):
        m = cls()
        m.from_base64(data)
        return m

def test_IntBiteMap():
    bm = IntBiteMap()
    #bm.from_base64('/v8PAA==')
    assert bm.len == 0
    #bm.insert(99)
    bm.insert(10)
    assert 10 in bm and bm.len == 1
    bm.insert(32)
    assert 32 in bm and bm.len == 2
    bm.insert(62)
    assert 62 in bm and bm.len == 2
    bm.insert(64)
    assert 64 in bm and bm.len == 3
    for i in xrange(330):
        bm.insert(i)
        assert i in bm
    print bm.map

    bm.trunate(100)
    for i in xrange(101, 330):
        assert i not in bm

    s = bm.to_string()
    bm1 = IntBiteMap.new(s)
    assert 64 in bm1 and 62 in bm1 and 32 in bm1 and 10 in bm1
    IntBiteMap.new('')

class IntRegionMap(object):
    """ 针对任务等级,定义的一种结构,
    解释: (1, 10): t1, (2, 15): t2, (5, 10):t3,
    {level:[t1, t2, t3]}
    """
    def __init__(self):
        self.get_func = None
        self.tmps = {}
        self.keys = None
        self.items = None

    def add(self, start, end, value):
        """ 左开右闭 """
        self.tmps[(int(start), int(end))] = value

    def init(self):
        keys = set()
        for start, end in self.tmps.iterkeys():
            keys.add(start)
            keys.add(end)
        keys = list(keys)
        keys.sort()
        self.keys = keys
        self.items = items = {}
        for (start, end), value in self.tmps.iteritems():
            for k in keys:
                values = items.setdefault(k, [])
                if not (start <= k < end):
                    continue
                values.append(value)
        self.get_func = make_lv_regions(items.items(), accept_low=0)

    def get(self, key):
        return self.get_func(key)

    def gets(self, start, end):
        """ [start, end] 获取这个范围段所有数据 """
        if not self.keys:
            return []
        rs = set()
        for k in self.keys:
            if start <= k <= end:
                rs.update(self.get_func(k))
        return rs

def test_IntRegionMap():
    m = IntRegionMap()
    m.add(2, 10, 1)
    m.add(5, 11, 2)
    m.add(5, 15, 3)
    m.init()
    l = m.get(5)
    l1 = m.get(10)
    l0 = m.get(1)


class TrieNode:
    def __init__(self, pnode):
        self.pnode = pnode
        self.value = None
        # children is of type {char, Node}
        self.children = {}
        self.end = 0 #是否叶子节点

    def get_value(self):
        if self.value is None:
            return ''
        return '%s%s' % (self.pnode.get_value(), self.value)

class Trie:
    def __init__(self):
        self.root = TrieNode(None)

    def insert(self, key):      # key is of type string
        # key should be a low-case string, this must be checked here!
        if not key:
            return None
        node = self.root
        for char in key:
            if char not in node.children:
                child = TrieNode(node)
                node.children[char] = child
                node = child
                child.value = char
            else:
                node = node.children[char]
        node.end = 1

    def search(self, key):
        node = self.root
        for char in key:
            if char not in node.children:
                break
            else:
                node = node.children[char]
        return node.end

    def searchs(self, s, full=1):
        """ 搜索句子,得到单词列表,
        full=0, 用于检查是否有单词在s中
        """
        pos = 0
        rs = None
        if full:
            rs = []
        while pos < len(s):
            node = self.root
            enode = None
            for char in s[pos:]:
                if char not in node.children:
                    break
                node = node.children[char]
                if node.end:
                    enode = node
            if enode:
                if full:
                    rs.append(enode.get_value())
                else:
                    return enode
            pos += 1
        return rs

    def display_node(self, node, log=None):
        def _log(n):
            if log is not None:
                log(n.get_value())
            else:
                print n.get_value()
        if node.end:
            _log(node)
        for key in node.children.iterkeys():
            self.display_node(node.children[key], log=log)
        return

    def display(self, log=None):
        self.display_node(self.root, log=log)

    @classmethod
    def test(cls):
        trie = cls()
        trie.insert('hello')
        trie.insert('nice')
        trie.insert('to')
        trie.insert('meet')
        trie.insert('you')
        trie.insert(u'中文')
        trie.insert(u'可以')
        trie.display()
        print 'search(hello):', trie.search('hello')
        print 'search(HELLO):', trie.search('HELLO')
        print(trie.searchs(u'中文是否可以ad找到to呢？' ))
        trie.benchmark()

    def benchmark(self, n=1000000):
        import timeit
        s = u'主席你好啊'
        def _ban():
            self.searchs(s, full=0)
        use = timeit.timeit(_ban, number=n)
        print 'used:%s per:%f' % (use, use / float(n))

    def replaces(self, s, ch):
        """ 将敏感词替换成ch """
        orig = s
        s = orig.lower()
        l = len(s)
        ch = unicode(ch)
        for i in xrange(0, l, 1):
            node = self.root
            e = 0
            for j in xrange(i, l, 1):
                k = s[j:j+1]
                if k not in node.children:
                    break
                node = node.children[k]
                if node.end:
                    e = j
            if not e:
                continue
            orig = orig[:i] + (e-i+1)*ch + orig[e+1:]
#            orig[i:e+1] = (e-i+1)*ch
#            orig = orig[:j] + ch + orig[j+1:]
        return orig


def encode(u):
    if not isinstance(u, unicode):
        u = u.decode('utf8')
    return u.encode('utf16')[2:]

def decode(s):
    return s.decode('utf16')

try:
    from _corelib import Trie
    print('install _corelib.Trie')
except ImportError:
    print('install _corelib.Trie fail!!!')

def main():
    #test_IntBiteMap()
    #test_IntRegionMap()
    Trie.test()

if __name__ == '__main__':
    main()
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


