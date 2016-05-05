#!/usr/bin/env python
# -*- coding:utf-8 -*-

from copy import copy

from corelib import log

from collections import defaultdict as dd
from collections import Hashable

__all__ = [
        'Broker',
        'sub',
        'unsub',
        'pub',
        'declare',
        'retract',
        'get_declarations',
        'has_declaration',
        ]


class Broker(object):
    def __init__(self):
        self._router = dd(list)
#        self._board = {}

    def clear(self):
        self._router.clear()

    def sub(self, topic, func, data=None, front = False):
        assert isinstance(topic, Hashable)
        assert callable(func) or hasattr(func, '__call__')
        if (func, data) in self._router[topic]:
            return
        if front:
            self._router[topic].insert(0, (func, data))
        else:
            self._router[topic].append((func, data))
#        if topic in self._board:
#            a, kw = self._board[topic]
#            func(*a, **kw)

    def unsub(self, topic, func, data=None):
        assert isinstance(topic, Hashable)
        assert callable(func) or hasattr(func, '__call__')
        if topic not in self._router:
            return
        try:
            self._router[topic].remove((func, data))
        except ValueError:
            if len(self._router[topic]) > 100:
                log.warn('Broker.unsub(%s, %s) may remove error!!!', self, topic)
            pass

    def pub(self, topic, *a, **kw):
        assert isinstance(topic, Hashable)
        if topic not in self._router:
            return
        key_data = '_data'
        removed = []
        for func, data in copy(self._router[topic]):
            if func:
                if data:
                    kw[key_data] = data
                    try:
                        func(*a, **kw)
                    finally:
                        kw.pop(key_data)
                else:
                    func(*a, **kw)
            else:
                removed.append((func, data))
        for i in removed:
            try:
                self._router[topic].remove(i)
            except ValueError:
                pass

#    def declare(self, topic, *a, **kw):
#        assert isinstance(topic, Hashable)
#        self._board[topic] = (a, kw)
#        return pub(topic, *a, **kw)

#    def retract(self, topic):
#        assert isinstance(topic, Hashable)
#        try:
#            self._board.pop(topic)
#        except KeyError:
#            pass

#    def get_declarations(self):
#        return self._board.keys()

#    def has_declaration(self, topic):
#        assert isinstance(topic, Hashable)
#        return topic in self._board


def observable(cls):
    t = cls.__init__
    def __init__(self, *a, **kw):
#        print 'decorate __init__'
        self._message_broker = Broker()
        t(self, *a, **kw)
        #assert not hasattr(self, '_message_broker')

    def clear(self):
        self._message_broker.clear()

    def sub(self, *a, **kw):
        self._message_broker.sub(*a, **kw)

    def rpc_sub(self, func, topic, *a, **kw):
        kw.pop('_proxy', None)
        self._message_broker.sub(topic, func, *a, **kw)

    def rpc_unsub(self, func, topic, data=None, _proxy=True):
        self._message_broker.unsub(topic, func, data=data)

    def unsub(self, *a, **kw):
        self._message_broker.unsub(*a, **kw)

    def pub(self, *a, **kw):
        self._message_broker.pub(*a, **kw)

    def safe_pub(self, *a, **kw):
        try:
            self._message_broker.pub(*a, **kw)
        except StandardError:
            log.log_except()

#    def declare(self, *a, **kw):
#        self._message_broker.declare(*a, **kw)
#
#    def retract(self, *a, **kw):
#        self._message_broker.retract(*a, **kw)
#
#    def get_declarations(self, *a, **kw):
#        self._message_broker.get_declarations(*a, **kw)
#
#    def has_declaration(self, *a, **kw):
#        self._message_broker.has_declaration(*a, **kw)

    setattr(cls, '__init__', __init__)

    for k, v in dict(
            message_clear = clear,
            sub = sub,
            rpc_sub=rpc_sub,
            rpc_unsub=rpc_unsub,
            unsub = unsub,
            pub = pub,
            safe_pub = safe_pub,
#            declare = declare,
#            retract = retract,
#            get_declarations = get_declarations,
#            has_declaration = has_declaration,
            ).iteritems():
        assert not hasattr(cls, k)
        setattr(cls, k, v)
    return cls


_broker = Broker()
sub = _broker.sub
unsub = _broker.unsub
pub = _broker.pub
#declare = _broker.declare
#retract = _broker.retract
#get_declarations = _broker.get_declarations
#has_declaration = _broker.has_declaration

if __name__ == '__main__':
    def greet(name):
        print 'hello, %s.'%name

    sub('greet', greet)
    pub('greet', 'lai')
    pub('greet', 'smallfish')
    pub('greet', 'guido')
    unsub('greet', greet)
    unsub('not existed', greet)
    pub('greet', 'world')
    print '*' * 30
    sub('greet', greet)
#    declare('greet', 'world')
#    assert get_declarations()

    def greet2(name):
        print 'hello, %s. greet2'%name

    sub('greet', greet2)

    pub('greet', 'spring')

#    retract('greet')

    def greet3(name):
        print 'hello, %s. greet3'%name

    sub('greet', greet3)

    print '*' * 30
    def greet4(name):
        print 'hello, %s. greet4'%name
        unsub('greet', greet4)
    sub('greet', greet4, front = True)
    pub('greet', 'lv')
    pub('greet', 'ma')

    print '*' * 30
    class Foo(object):
        def foo(self, ctx, name):
            print 'Foo.foo, hello %s.'%name

    foo = Foo()
    sub('lai', foo.foo)
    pub('lai', 'lai')

