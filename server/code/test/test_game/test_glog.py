#!/usr/bin/env python
# -*- coding:utf-8 -*-

from test.common import attr
from game.glog.logger import GameLogger


@attr(p_game=1, log=1)
def test():
    gl = GameLogger()
    gl.log(1, '中文')
    gl.item(1, 2, u'物品', 1)


