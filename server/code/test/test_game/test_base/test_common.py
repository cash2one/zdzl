#!/usr/bin/env python
# -*- coding:utf-8 -*-

from test.common import attr
from game.base import common


@attr(base=1)
def test_RandomRegion():
    regions = dict(a=3)
    assert 'a' == common.RandomRegion(regions).random()

    regions = dict(a=3, b=9, c=12, d=8)
    rrans = dict(a=3.0/32, b=9.0/32, c=12.0/32, d=8.0/32)
    rr = common.RandomRegion(regions)
    rs = dict(a=0, b=0, c=0, d=0)
    count = 50000
    for i in xrange(count):
        k = rr.random()
        rs[k] += 1
    rans = [(k, v/ float(count)) for k,v in rs.iteritems()]
    print(rans)