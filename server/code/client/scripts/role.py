#!/usr/bin/env python
# -*- coding:utf-8 -*-


def wear_takeoff_eq(player, eid, rid):
    """ 穿脱装备 """
    if not _exist_item(player, eid, 'equip'):
        return
    if not _exist_role(player, rid):
        return
    #穿装备(装备id, 配将id)
    tRs = player.role.role_wear_eq(eid,rid)
    print 'role_wear_eq = ', tRs
    #脱装备(装备id, 配将id)
    tRs = player.role.role_tackoff_eq(eid,rid)
    print 'role_tackoff_eq = ', tRs
    return True


def wear_takeoff_fate(player, fid, rid, place):
    """ 穿脱命格 命格一键合成 """
    if not _exist_item(player, fid, 'fate'):
        return
    if not _exist_role(player, rid):
        return
    #穿命格(命格d, 配将id)
    tRs = player.role.role_wear_fate(fid, rid, place)
    print 'role_wear_fate = ', tRs
    #脱命格(命格id, 配将id)
    tRs = player.role.role_tackoff_fate(fid, rid, place)
    print 'role_tackoff_fate = ', tRs
    #一键合成
    tRs = player.role.role_merge_all_fate()
    print 'role_merge_all_fate = ', tRs
    tFates = player.bag.bag_get_ilist()['fate']
    if len(tFates) < 2:
        return
    #命格合并(命格id1, 命格id2)
    print 'merge_fate = (%d, %d)' % (tFates[0]['id'], tFates[1]['id'])
    tRs = player.role.role_merge_fate(tFates[0]['id'], tFates[1]['id'])
    print 'role_merge_fate = ', tRs
    return True



def _exist_item(player, aId, aType):
    """ 判断物品是否存在 """
    playIDicts = player.bag.bag_get_ilist()
    tDicts = playIDicts[aType]
    for tDict in tDicts:
        if tDict['id'] == aId:
            return True
    return False

def _exist_role(player, aRid):
    """ 判断配将是否存在 """
    tRoles = player.role.role_roles()
    for tRole in tRoles:
        if tRole['id'] == aRid:
            return True
    return False

ADD_FATEID_HP = 1
ADD_FATEID_STK = 3
ADD_FATEID_DEF = 4

def merge_fate_test(player, type):
    """ 命格合成测试
    type=0 背包内的合并
    type=1 都在身上的合并
    type=2 将身上的命格放到背包某命格合并
    type=3 将背包里的某命格放到身上某命格合并
    """
    if 0:
        from client.player import Player
        player = Player()
    #清理数据
    player.game_master.clear_player()
    player.game_master.add_role(3)
    roles = player.role.role_roles()
    tRole = roles[0]
    print "tRole = ", tRole
    tIlsit = player.bag.bag_get_ilist()
    if not tIlsit['fate']:
        player.game_master.add_fate(ADD_FATEID_HP)
        player.game_master.add_fate(ADD_FATEID_STK)
        #player.game_master.add_fate(ADD_FATEID_DEF)
        tIlsit = player.bag.bag_get_ilist()
    tFates = tIlsit['fate']
    print "bag merge_fate : [%s, %s]" % (tFates[0], tFates[1])
    if type == 1:
        #都在身上的合并
        player.role.role_wear_fate(tFates[0]['id'], tRole['id'], 1)
        player.role.role_wear_fate(tFates[1]['id'], tRole['id'], 2)

    elif type == 2:
        # 将身上的命格放到背包某命格合并
        player.role.role_wear_fate(tFates[0]['id'], tRole['id'], 1)
    elif type ==3:
        #将背包里的某命格放到身上某命格合并
        player.role.role_wear_fate(tFates[1]['id'], tRole['id'], 1)
    if type:
        re = player.role.role_merge_fate(tFates[0]['id'], tFates[1]['id'], tRole['id'])
    else:
        re = player.role.role_merge_fate(tFates[0]['id'], tFates[1]['id'])
    #显示结果
    print "re = ",re
    tIlsit = player.bag.bag_get_ilist()
    print 'res-fate = ', tIlsit['fate']
    roles = player.role.role_roles()
    tRole = roles[0]
    print "res-tRole = ", tRole


