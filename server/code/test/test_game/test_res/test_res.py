#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.res import res_mgr
from test.common import attr


if 0:
    _mgr = res_mgr.ResMgr()
def setup():
    global _mgr
    from game.store import new_game_store
    store, res_store = new_game_store()
    _mgr = res_mgr.ResMgr(res_store)

def tearDown():
    global _mgr
    del _mgr


@attr(res_role=1)
def test_load():
    _mgr.load()
