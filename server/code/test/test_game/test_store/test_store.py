#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game import Game

from corelib import log
from test.common import attr


def setup():
    log.info('store setup')


def tearDown():
    log.info('store tearDown')


@attr(store=1, p_game=1)
def test_insert():
    store = Game.rpc_store
    tname = 'player'
    values = dict(uname='abc', level=1, forbid=True)
    key = store.insert(tname, values)
    player = store.load(tname, key)
    player['level'] = 23
    store.save(tname, player)
    players = store.query_loads(tname, None)
    keys = []
    for p in players:
        print p
        keys.append(p['id'])
        #store.deletes(tname, keys)



#------------------------\#------------------------\
#------------------------\#------------------------\
#------------------------\#------------------------\

