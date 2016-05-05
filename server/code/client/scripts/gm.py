#!/usr/bin/env python
# -*- coding:utf-8 -*-

def test_gm(player):
    if 0:
        from client.player import Player
        player = Player()
    print player.game_master.reward(42)
    print player.game_master.add_item(38, 1, can_trade=1)
    print player.game_master.use_item_ex(38)
    player.game_master.status_inc('bfBestCount')
    print player.game_master.status_get('bfBestCount')
    player.game_master.status_inc('bfBestCount', -1)
    print player.game_master.status_get('bfBestCount')
    print player.game_master.status_set('bfBestCount', 1, 1)
    player.game_master.attr_set('test_json', dict(a=1, b=2, c=[1,2,3]))
    print player.game_master.attr_get('test_json')

def test_show(player):
    print player.client.call_actiInfo()
    print player.game_master.show_bag()
    print player.game_master.show_wait_bag()
    print player.game_master.show_roles()
    print player.game_master.show_tasks()


