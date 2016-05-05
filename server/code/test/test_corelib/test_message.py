#!/usr/bin/env python
# -*- coding:utf-8 -*-

from test.common import attr
from corelib import message

class T1(object):
    def __hash__(self):
        return 1

    def __call__(self, *args, **kwargs):
        pass

@attr(corelib=1, message=1)
def test_hash():
    b = message.Broker()
    t1 = T1()
    t2 = T1()
    b.sub('abc', t1)
    b.unsub('abc', t2)
    assert (t1, None) not in b._router['abc']


