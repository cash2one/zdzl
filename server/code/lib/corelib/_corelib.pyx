### distutils11111: language = c++
#from struct import unpack
from cython.operator cimport (
    dereference as deref,
)

def test(s):
    if not isinstance(s, unicode):
        u = s.decode('utf-8')
    else:
        u = s
    s = u.encode('utf-16')
    cdef int l = len(s)
    cdef char *p = s
    for i in range(l):
        print p[i]
    return p[:l]

#cython
from libc cimport string
#from libcpp cimport map

def encode(u):
    if not isinstance(u, unicode):
        u = u.decode('utf8')
    return u.encode('utf16')[2:]
def decode(s):
    return s.decode('utf16')

cdef inline int utf16_to_int(char *c):
    cdef unsigned short *i
    #return unpack('H', <bytes>c[:2])[0]
    #string.memcpy(&i, c, 2)
    i = <unsigned short *>c
    return <int>deref(i)

cdef class TrieNode:
    cdef char[2] value
    cdef TrieNode pnode
    cdef int end
    cdef object children
    #cdef map.map[char[2], object] childrens
    def __cinit__(self):
        self.value[0] = '\x00'
        self.end = 0

    def __init__(self):
        self.children = {}

    cpdef get_value(self):
        if self.value[0] == '\x00':
            return ''
        return u'%s%s' % (self.pnode.get_value(), decode(self.value[:2]))

cdef class Trie:
    cpdef TrieNode root
    def __cinit__(self):
        self.root = TrieNode()

    def insert(self, key):
        key = encode(key)
        cdef char *c = key
        cdef int l = len(key)
        cdef TrieNode n
        n = self.root
        for i in range(0, l, 2):
            n = self.new_node(n, c)
            c += 2
        n.end = 1

    def inserts(self, keys):
        for key in keys:
            self.insert(key)

    def search(self, key):
        key = encode(key)
        cdef TrieNode n = self.root
        cdef int l = len(key)
        cdef char *c = key
        cdef int i
        for i in range(0, l, 2):
            s = utf16_to_int(c + i)
            if s not in n.children:
                break
            n = n.children[s]
        return n.end

    def searchs(self, s, int full=1):
        """ 搜索敏感词 """
        s = encode(s)
        cdef int pos = 0
        rs = None
        if full:
            rs = []
        cdef int i, j, l
        cdef TrieNode node, enode
        cdef char *c = s

        l = len(s)
        for i in range(0, l, 2):
            node = self.root
            enode = None
            for j in range(i, l, 2):
                k = utf16_to_int(c + j)
                if k not in node.children:
                    break
                node = node.children[k]
                if node.end:
                    enode = node
            if enode:
                if full:
                    rs.append(enode.get_value())
                else:
                    return enode
        return rs

    cdef new_node(self, TrieNode p, char *c):
        """ 新建节点 """
        s = <bytes>c[:2]
        key = utf16_to_int(c)
        if key in p.children:
            return p.children[key]
        cdef TrieNode n = TrieNode()
        n.pnode = p
        p.children[key] = n
        string.strncpy(n.value, c, 2)
        return n

    cdef display_node(self, TrieNode node):
        if node.end == 1:
            print node.get_value()
        for key in node.children.iterkeys():
            self.display_node(node.children[key])

    def display(self):
        self.display_node(self.root)

    def benchmark(self, n=1000000):
        import timeit
        s = u'主席你好啊'
        self.insert(u'主席')
        def _ban():
            assert self.searchs(s, full=0) is not None
        use = timeit.timeit(_ban, number=n)
        print 'used:%s per:%f' % (use, use / float(n))

    def replaces(self, s, ch):
        """ 将敏感词替换成c """
        orig = s
        s = s.lower()
        orig = encode(orig)
        s = encode(s)
        cdef int pos = 0
        cdef int i, j, e, l
        cdef TrieNode node
        cdef char *c = s
        cdef char *oc = orig
#        cdef char buf[20] #最大长度
#        string.strncpy(buf, ch, 20)
#        print 'buf:', buf

        l = len(s)
        for i in range(0, l, 2):
            node = self.root
            e = 0
            for j in range(i, l, 2):
                k = utf16_to_int(c + j)
                if k not in node.children:
                    break
                node = node.children[k]
                if node.end:
                    e = j
            if not e:
                continue
#            string.strncpy(oc+i, buf, 2*(e-i+1))
            for j in range(i, e+2, 2):
                string.strncpy(oc+j, ch, 2)
        return decode(orig)





#---------------------
#---------------------
#---------------------
#---------------------


