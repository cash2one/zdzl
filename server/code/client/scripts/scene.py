#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import sleep

def test_scene(player):
    player.scene.enter_map(10)
    player.scene.move(100, 100)
    player.scene.enter_map(9)
    player.scene.move(10, 10)
    sleep(1)
