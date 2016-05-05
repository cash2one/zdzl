#!/usr/bin/env python
# -*- coding:utf-8 -*-

#低品质装备的eid(要求同部位)
EQUIP_QUALITY_SMALL_EID = 1
#高品质装备的eid(要求同部位)
EQUIP_QUALITY_BIG_EID = 7

#装备属性
EQ_ATTR = 'eq%d'

def equip_move_test(player):
    """ 装备等级转移测试 """
    if 0:
        from client.player import Player
        player = Player()
    tRole = _handle_data(player)
    tIlsit = player.bag.bag_get_ilist()
    for tEq in tIlsit['equip']:
        if tEq['eid'] == EQUIP_QUALITY_SMALL_EID:
            tWearEqId = tEq['id']
            player.role.role_wear_eq(tWearEqId, tRole['id'])
        else:
            tBagEqId = tEq['id']
    print "change (%s, %s)" % (tWearEqId, tBagEqId)
    player.bag.bag_eq_move(tRole['id'], tWearEqId, tBagEqId)
    tIlsit = player.bag.bag_get_ilist()
    print "tIlsit.equip = ", tIlsit['equip']
    roles = player.role.role_roles()
    for role in roles:
        if role['id'] == tRole['id']:
            print "tRole =", role
            break

def _handle_data(player):
    """ 处理数据 """
    #脱掉角色身上的装备
    tRoles = player.role.role_roles()
    if not tRoles:
        player.game_master.add_role(1)
        tRoles = player.role.role_roles()
    tRole = tRoles[0]
    print "tRole = ", tRole
    _takeoff_eq(player, tRole)
    #卖出所有装备
    tIlsit = player.bag.bag_get_ilist()
    tEqIds = []
    for tEq in tIlsit['equip']:
        tEqIds.append(tEq['id'])
    player.bag.bag_sellAll(tEqIds, [],[])
    #同等级不同品质的转移(要求同部位)
    #添加装备
    player.game_master.add_equip(EQUIP_QUALITY_SMALL_EID)
    player.game_master.add_equip(EQUIP_QUALITY_BIG_EID)
    return tRole

def _takeoff_eq(player, aRole):
    """ 将角色身上的装备全部脱掉 """
    def iter_equips(aRole):
        for i in xrange(1, 7):
            key = EQ_ATTR % i
            yield key, aRole[key]
    for tEqPlace, tWearEqId in iter_equips(aRole):
        if not tWearEqId:
            continue
        player.role.role_tackoff_eq(tWearEqId, aRole['id'])


