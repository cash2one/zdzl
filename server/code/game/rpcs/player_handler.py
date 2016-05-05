#!/usr/bin/env python
# -*- coding:utf-8 -*-
from functools import wraps

from game import ClientRpc, AbsExport, prepare_send, pack_msg, client_monitor_export
from corelib import log, sleep, RLock
from game.base import errcode
from game.glog.common import PL_FUNCSUPDATE
from game.base.msg_define import MSG_ROLE_INVITE, MSG_FETE_NUM
from game.store import TN_PLAYER
from game.store.define import FN_P_ATTR_CBE, FN_P_ATTR_CBES
from webapi import SNSClient

import config


def _wrap_nolock(func):
    func._nolock_ = 1
    return func


class BasePlayerRpcHander(AbsExport):
    def __init__(self):
        if 0:
            from game.player import player as player_md
            self.player = player_md.Player()
            self.rpc = ClientRpc()
        raise NotImplementedError


class PlayerRpcHandler(BasePlayerRpcHander):
    def __init__(self, player):
        if 0:
            from game.player import player as player_md
            self.player = player_md.Player()
            self.rpc = ClientRpc()
        self.player = player
        self.active = True
        self.rpc = None
        self._lock = RLock()

    def uninit(self):
        self.player = None
        self.rpc = None
        if 0:
            from game.player import player as player_md
            self.player = player_md.Player()
            self.rpc = ClientRpc()

    def on_close(self, rpcobj):
        """ 断线处理 """
        sleep(0.05)#等待其它接口完成
        self.player.on_close()

    _close_i = 0.05
    _close_time = 10 #等待时间
    _close_count = int(_close_time/_close_i)
    def close_handler(self):
        """ player主动调用，先关闭接口,再处理别的,注意不调用会内存泄漏 """
        global _locks
        try:
            self.active = False
            for i in xrange(self._close_count):
                if not _locks[self]:
                    break
                sleep(self._close_i)
        except:
            log.log_except()
        finally:
            _locks.pop(self, None)

    def init(self, sock, addr):
        self._sock = sock
        self.rpc = ClientRpc(sock, addr, self)
        self.rpc.start()
        _locks[self] = {}

    def init_by_rpc(self, rpc):
        self.rpc = rpc
        if rpc:
            rpc.set_export(self)
        _locks[self] = {}

    def stop(self):
        if self.rpc is not None:
            self.rpc.stop()
            self.rpc = None

    def _pack_items(self, items, equips, fates):
        return dict(
            coin1=self.player.data.coin1,
            coin2=self.player.data.coin2,
            coin3=self.player.data.coin3,
            exp=self.player.data.exp,
            train=self.player.data.train,
            items=[i.to_dict() for i in items],
            equips=[i.to_dict() for i in equips],
            fates=[i.to_dict() for i in fates],
        )

    def rc_gm(self, cmd):
        """ 执行gm命令 """
        resp_f = 'gm'
        gm = self.player.gm
        if gm is None:
            return pack_msg(resp_f, 0, err=u'gm auth error!')
        msg = gm.execute(cmd)
        return pack_msg(resp_f, 1, data=dict(msg=msg))

    def rc_isGm(self):
        """ 判断玩家是否gm """
        resp_f = 'isGm'
        gm = self.player.gm is not None
        return pack_msg(resp_f, 1, data=dict(gm=int(gm)))

    def rc_clear_player_data(self, all=True, dels=tuple()):
        """ 清空玩家数据,压力测试用,正常游戏不需要调用这个接口 """
        resp_f = 'clear_player_data'
        #log.warn(u'(%s) rc_clear_player_data', self.player.data.id)
        try:
            self.player.clear(all=all, dels=dels)
            return pack_msg(resp_f, 1)
        except Exception as e:
            return pack_msg(resp_f, 0, err=str(e))

    def rc_valid_gm(self):
        """ 启动gm模块,压力测试用 """
        resp_f = 'valid_gm'
        if not self.player._game.rpc_player_mgr.is_overload():
            return pack_msg(resp_f, 0, err='overload close')
        self.player._gm = self.player._game.gm_mgr.get_gm(self.player, forced=True)
        return pack_msg(resp_f, 1)

    def rc_init(self):
        """ 获取初始化信息 """
        resp_f = 'init'
        return self.player.get_init_msg()

    def rc_bindSNS(self, t, sid, session):
        """ 账号绑定 """
        resp_f = 'bindSNS'
        rs, data = self.player._game.rpc_player_mgr.bindSNS(self.player.data.uid,
                t, sid, session)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1)

    def rc_logout(self):
        """ 退出 """
        return self.player.user.rc_logout()

    @_wrap_nolock
    def rc_leave(self):
        """ 退出player """
        resp_f = 'leave'
        self.player.leave()
        return pack_msg(resp_f, 1)

    def rc_lookPlayer(self, pid=None, name=None):
        """ 查看其它玩家信息 """
        resp_f = 'lookPlayer'
        if name:
            querys = dict(name=name)
            dics = self.player._game.rpc_store.query_loads(TN_PLAYER, querys=querys)
            if not dics:
                return pack_msg(resp_f, 0, err=errcode.EC_PLAYER_EMPTY)
            pid = dics[0]['id']
        rs, data = self.player._game.player_mgr.look(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_player(self):
        """ 请求玩家信息 """
        resp_f = 'player'
        return pack_msg(resp_f, 1, data=self.player.to_dict())

    def rc_funcsUpdate(self, funcs):
        """ 更新前端用的开启功能按钮列表 """
        resp_f = 'funcsUpdate'
        self.player.data.funcs = funcs
        if config.debug:
            self.player.log_normal(PL_FUNCSUPDATE, d=funcs,
                tid=self.player.task.current_tid)
        return pack_msg(resp_f, 1)

    def rc_CBEUpdate(self, CBE, cbes):
        """ 更新战斗力信息 """
        if self.player.is_guide:
            return
        #CBE改用服务器计算的
        #self.player.play_attr.set(FN_P_ATTR_CBE, CBE)
        #self.player.play_attr.set(FN_P_ATTR_CBES, cbes)


    def rc_roles(self, pid=None):
        """ 请求配将信息 """
        resp_f = 'roles'
        if pid is None:
            return pack_msg(resp_f, 1, data=self.player.roles.to_dict())
        #TODO 获取其它玩家配将信息

    def rc_ilist(self, pid = None):
        """ 请求玩家物品信息 """
        log.debug(u'===rc_ilist===')
        resp_f = 'ilist'
        if pid is None:
            return pack_msg(resp_f, 1, data=self.player.bag.to_dict())

    def rc_iwait(self):
        """ 请求待收取物品列表 """
        resp_f = 'iwait'
        return pack_msg(resp_f, 1, data=self.player.wait_bag.to_dict())

    def rc_waitFetch(self, type, id=None):
        """ 收取物品 """
        resp_f = 'waitFetch'
        rs, data = self.player.wait_bag.fetch(type, id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        else:
            return pack_msg(resp_f, 0, err=data)

    def rc_useItem(self, id):
        """ 使用物品,获取东西 """
        resp_f = 'useItem'
        rs, data = self.player.use_item(id)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_cliAttr(self, key):
        """ 获取前端属性 """
        resp_f = 'cliAttr'
        value = self.player.play_attr.client_get(key)
        return pack_msg(resp_f, 1, data=value if value is not None else '')
        #return pack_msg(resp_f, 1, data=self.player.play_attr.client_to_dict())

    def rc_cliAttrSet(self, key, value):
        """ 设置前端属性 """
        #log.debug('rc_cliAttrSet(%s, %s)', key, value)
        resp_f = 'cliAttrSet'
        if not key:
            return pack_msg(resp_f, 0)
        self.player.play_attr.client_set(key, value)
        return pack_msg(resp_f, 1)

    def rc_pAttr(self, key):
        """ 获取属性 """
        resp_f = 'pAttr'
        value = self.player.play_attr.get(key)
        return pack_msg(resp_f, 1, data=value if value is not None else '')
        #return pack_msg(resp_f, 1, data=self.player.play_attr.client_to_dict())

    def rc_pAttrSet(self, key, value):
        """ 设置属性 """
        resp_f = 'pAttrSet'
        if not key:
            return pack_msg(resp_f, 0)
        self.player.play_attr.set(key, value)
        return pack_msg(resp_f, 1)

    def rc_task(self, pid = None):
        """ 获取玩家的任务 """
        resp_f = 'task'
        if pid is None:
            return pack_msg(resp_f, 1, data=self.player.task.to_dict())

    def rc_taskUpdate(self, id, step):
        """ 更新玩家任务状态"""
        resp_f = 'taskUpdate'
        return pack_msg(resp_f, 1, data=self.player.task.task_update(id, step))

    def rc_taskActive(self, id):
        """ 激活某任务,无返回 """
        resp_f = 'taskActive'
        task = self.player.task.get_task(id)
        if not task:
            return
        self.player.task.task_active(task)

    def rc_taskComplete(self, id):
        """ 完成任务获取奖励 """
        resp_f = 'taskComplete'
        rs, bag_items = self.player.task.task_complete(id)
        if rs:
            if bag_items:
                data = bag_items.pack_msg(rwitems=True)
            else:
                data = None
            return pack_msg(resp_f, 1, data=data)
        else:
            return pack_msg(resp_f, 0, err=bag_items)

    def rc_chapterComplete(self):
        """ 完成章节 """
        resp_f = 'chapterComplete'
        if self.player.task.chapter_complete():
            return pack_msg(resp_f, 1)
        else:
            return pack_msg(resp_f, 0)

    def rc_bfTaskEnter(self):
        """ 进入兵符任务 """
        resp_f = 'bfTaskEnter'
        rs, data = self.player._game.bftask_mgr.bf_task_enter(self.player)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bfTaskRe(self, type):
        """ 兵符任务刷新 """
        resp_f = 'bfTaskRe'
        rs, data = self.player._game.bftask_mgr.bf_task_re(self.player, type)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bfTaskBox(self):
        """ 打开兵符宝箱 """
        resp_f = 'bfTaskBox'
        rs, data = self.player._game.bftask_mgr.bf_task_box(self.player)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bfTaskGet(self, index):
        """ 接兵符任务 """
        resp_f = 'bfTaskGet'
        rs, data = self.player._game.bftask_mgr.bf_task_get(self.player, index)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bfTaskFinish(self):
        """ 立即完成的兵符任务 """
        resp_f = 'bfTaskFinish'
        rs, data = self.player._game.bftask_mgr.bf_finish(self.player)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_carExchange(self, cid):
        """ 坐骑兑换 """
        resp_f = 'carExchange'
        rs, data = self.player.car_exchange(cid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_carDo(self, cid):
        """ 坐骑的操作 """
        resp_f = 'carDo'
        rs, data = self.player.car_do(cid)
        if rs:
            return pack_msg(resp_f, 1)
        return pack_msg(resp_f, 0, err=data)

    def rc_mergeItem(self, desId, count, srcId):
        """ 物品合成 """
        res_f = 'mergeItem'
        rs, data = self.player.merge_item(desId, count, srcId)
        if rs:
            return pack_msg(res_f, 1, data=data)
        return pack_msg(res_f, 0, err=data)

    def rc_wearEq(self, id, rid):
        """ 穿装备
        id: 装备玩家表id
        rid:角色玩家表id
        """
        resp_f = 'wearEq'
        role = self.player.roles.get_role(rid)
        equip, res_equip = self.player.bag.get_equip_ex(id)
        if res_equip is None:
            return pack_msg(resp_f, 0, err=errcode.EC_ITEM_NOFOUND)

        res_eq_set = self.player._game.item_mgr.get_res_eq_set(res_equip.sid)
        if res_eq_set.cond and res_eq_set.lv > self.player.data.level:
            return pack_msg(resp_f, 0, err=errcode.EC_NOLEVEL)
        if not (role and equip):
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        if equip.data.used:
            return pack_msg(resp_f, 0, err=errcode.EC_ROLE_WEARED)
        rs, data = role.wear_equip(self.player, equip, res_equip)
        if rs:
            off_equip, msg = data
            return msg
        return pack_msg(resp_f, 0, err=data)

    def rc_tackOffEq(self, id, rid):
        """ 脱装备 """
        resp_f = 'tackOffEq'
        role = self.player.roles.get_role(rid)
        equip, res_equip = self.player.bag.get_equip_ex(id)
        if not (equip and role):
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        rs, data = role.take_off_equip(self.player, res_equip.part)
        if rs:
            return pack_msg(resp_f, 1, data=dict(uid=id))
        return pack_msg(resp_f, 0, err=data)

    def rc_armUpgrade(self, rid):
        """ 武器升级 """
        resp_f = 'armUpgrade'
        if not rid:
            return pack_msg(resp_f, 0)
        tRole = self.player.roles.roles.get(rid)
        rs, data = self.player.arm_upgrade(tRole)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_armSkill(self, rid, sid):
        """ 激活技能 """
        resp_f = 'armSkill'
        if not rid or not sid:
            return pack_msg(resp_f, 0)
        tRole = self.player.roles.roles.get(rid)
        rs, data = self.player.arm_skill(tRole, sid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_skillBack(self, rid, type):
        """ 取回技能点 """
        resp_f = 'skillBack'
        if not rid or not type:
            return pack_msg(resp_f, 0)
        tRole = self.player.roles.roles.get(rid)
        rs, data = self.player.skill_back(tRole, type)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_eqStr(self, eid):
        """ 装备强化升级 """
        resp_f = 'eqStr'
        if not eid:
            return pack_msg(resp_f, 0)
        rs, data = self.player.equip_strong(eid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_eqMove(self, rid, eid1, eid2):
        """ 装备强化转移 """
        resp_f = 'eqMove'
        if not eid1 or not eid2:
            return pack_msg(resp_f, 0)
        tRole = self.player.roles.roles.get(rid)
        rs, data = self.player.equip_move_level(tRole, eid1, eid2)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_chatSend(self, t, m, id=None, name=None):
        """ 玩家发聊天信息 """
        resp_f = 'chatSend'
        rs, data = self.player._game.chat_mgr.chat_send(self.player, t, m, pid=id, name=name)
        if rs:
            return pack_msg(resp_f, 1)
        return pack_msg(resp_f, 0, err=data)

    def rc_wearFt(self, id, rid, place):
        """ 穿命格 """
        resp_f = 'wearFt'
        role = self.player.roles.get_role(rid)
        fate, res_fate = self.player.bag.get_fate_ex(id)
        if not (place and fate and role):
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        rs, data = role.wear_fate(self.player, fate, res_fate, place)
        if rs:
            return  pack_msg(resp_f, 1, data=dict(id=id, rid=rid))
        return pack_msg(resp_f, 0, err=data)

    def rc_tackOffFt(self, id, rid, place):
        """ 脱命格 """
        resp_f = 'tackOffFt'
        role = self.player.roles.get_role(rid)
        fate = self.player.bag.get_fate(id)
        if not(role and fate):
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        rs, data = role.take_off_fate(self.player, fate, place)
        if rs:
            return pack_msg(resp_f, 1, data=dict(uid=id))
        return pack_msg(resp_f, 0, err=data)

    def rc_mergeFt(self, id1, id2, rid=0):
        """ 命格合并 """
        resp_f = 'mergeFt'
        if not id1 or not id2:
            return pack_msg(resp_f, 0)
        rs, data = self.player.roles.merge_fate(id1, id2, rid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_mergeAllFt(self):
        """ 命格一键合成"""
        resp_f = 'mergeAllFt'
        rs, data = self.player.roles.merge_all_fate()
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_sellAll(self, equip=None, item=None, fate=None, gem=None):
        """ 批量卖出 """
        resp_f = 'sellAll'
        rs, data = self.player.bag.sell_all(equip, item, fate, gem)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_invite(self, rid):
        """ 招募配将 """
        resp_f = 'invite'
        role, data = self.player.roles.invite(rid)
        if role == False:
            return pack_msg(resp_f, 0, err=data)
        d = role.data
        data['id'] = d.id
        data['rid'] = d.rid
        data['role'] = [role.to_dict()]

        #self.player.pub(MSG_ROLE_INVITE, d.rid, self.player)

        return pack_msg(resp_f, 1, data=data)

    def rc_roleLeave(self, rid):
        """ 离队 """
        resp_f = 'roleLeave'
        role = self.player.roles.get_role(rid)
        if role is None or role.is_main:
            return pack_msg(resp_f, 0, err=errcode.EC_ROLE_NOFOUND)
        role.leave()
        return pack_msg(resp_f, 1, data=dict(rid=role.data.id))

    def rc_roleReturn(self, rid):
        """ 归队 """
        resp_f = 'roleReturn'
        role = self.player.roles.get_role(rid)
        if role is None:
            return pack_msg(resp_f, 0, err=errcode.EC_ROLE_NOFOUND)
        if not self.player.roles.can_come_back():
            return pack_msg(resp_f, 0, err=errcode.EC_NO_RIGHT)
        role.come_back()
        return pack_msg(resp_f, 1, data=dict(rid=role.data.id))

    def rc_inviteState(self, rid):
        """ 获取招募条件状态 """
        #TODO: 获取招募条件状态

    def rc_enterHitFate(self):
        """ 进入猎命获取初始数据 """
        resp_f = 'enterHitFate'
        rs, data = self.player._game.hfate_mgr.enter_hit_fate(self.player)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0)

    def rc_hitFate(self, type, isBatch=0):
        """ 进行猎命 """
        resp_f = 'hitFate'
        rs, data = self.player._game.hfate_mgr.hit_fate(self.player, type, isBatch)
        if rs:
            return pack_msg(resp_f, 1, data =data)
        return pack_msg(resp_f, 0, err=data)

    def rc_enterFete(self):
        """ 进入祭天获取初始化数据 """
        resp_f = 'enterFete'
        data = self.player._game.fete_mgr.enter_fete(self.player)
        if data:
            return data

    def rc_fete(self, type):
        """ 进行祭天 """
        resp_f = 'fete'
        rs, data = self.player._game.fete_mgr.fete_ing(self.player, type)
        if rs:
            self.player.pub(MSG_FETE_NUM)
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_position(self):
        """ 获取阵型信息 """
        resp_f = 'position'
        return pack_msg(resp_f, 1, data=self.player.positions.to_dict())

    def rc_posStudy(self, pid):
        """ 学习阵型 """
        resp_f = 'posStudy'
        p = self.player.positions.study(pid)
        if p:
            return pack_msg(resp_f, 1, data=dict(pid=p.data.id, coin1=self.player.data.coin1))
        else:
            return pack_msg(resp_f, 0)

    def rc_posUpgrade(self, pid):
        """ 升级阵型 """
        resp_f = 'posUpgrade'
        rs, err = self.player.positions.upgrade(pid)
        if rs:
            return pack_msg(resp_f, 1, data=dict(coin1=self.player.data.coin1))
        else:
            return pack_msg(resp_f, 0, err=err)

    def rc_posActive(self, pid):
        """ 激活阵型 """
        resp_f = 'posActive'
        rs = self.player.positions.active(pid)
        if rs:
            return pack_msg(resp_f, 1)
        else:
            return pack_msg(resp_f, 0)

    def rc_posSet(self, **kw):
        """ 设置阵型 """
        resp_f = 'posSet'
        id = kw['id']
        rs = self.player.positions.set(id, kw)
        if rs:
            return pack_msg(resp_f, 1)
        else:
            return pack_msg(resp_f, 0)

    def rc_startSit(self):
        """ 开始打坐 """
        resp_f = 'startSit'
        rs, data = self.player.sit.start_sit()
        if rs:
            return pack_msg(resp_f, 1)
        return pack_msg(resp_f, 0, err=data)

    def rc_stopSit(self):
        """ 停止打坐 """
        resp_f = 'stopSit'
        rs, data = self.player.sit.stop_sit()
        if rs:
            return pack_msg(resp_f, 1)
        return pack_msg(resp_f, 0, err=data)

    def rc_onlineSitExp(self):
        """ 上线获取打坐信息 """
        resp_f = 'onlineSitExp'
        rs, data = self.player.sit.online_sit()
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_mail(self):
        """ 获取邮件列表 """
        resp_f = 'mail'
        return pack_msg(resp_f, 1, data=self.player.mail.to_dict())

    def rc_mailReceive(self, id):
        """ 收取删除邮件 """
        resp_f = 'mailReceive'
        rs, msg = self.player.mail.receive(id)
        if rs:
            return pack_msg(resp_f, 1, data=msg)
        else:
            return pack_msg(resp_f, 0, err=msg)

    def rc_fishEnter(self):
        """ 进入钓鱼操作获取所有的鱼饵 """
        resp_f = 'fishEnter'
        rs, data = self.player._game.fish_mgr.fish_enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_fishUp(self, iid, num, qt = 1):
        """ 一次(批量)起杆获得奖励 """
        resp_f = 'fishUp'
        rs, data = self.player._game.fish_mgr.fish_up(self.player, iid, num, qt)
        if rs:
            return pack_msg(resp_f, 1, data = data)
        return pack_msg(resp_f, 0, err = data)

    #def rc_fishGiveup(self, iid, t):
    #    """ 放弃钓鱼 """
    #    resp_f = "fishGiveup"
    #    rs, data = self.player._game.fish_mgr.fish_give_up(self.player, iid, t)
    #    if not rs:
    #        return pack_msg(resp_f, 0, err = data)
    #    return pack_msg(resp_f, 1, data = data)

    def rc_foodEnter(self):
        resp_f = 'foodEnter'
        return pack_msg(resp_f, 1, data=dict(bTime=self.player.buffs.delay_times))

    def rc_foodEat(self, id, t):
        """ 进食 """
        resp_f = 'foodEat'
        rs, err = self.player.buffs.eat(id, t)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1, data=err)

    def rc_buffDel(self, id):
        """ buff过期，删除buff """
        resp_f = 'buffDel'
        buff = self.player.buffs.get_buff(id)
        if not buff:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        rs, err = self.player.buffs.del_buff(buff)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_mineEnter(self):
        resp_f = "mineEnter"
        rs, data = self.player._game.mining_mgr.enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_mine(self, type, hit, isbatch, hit3 = 0, hit5 = 0):
        """ 请求采矿 """
        resp_f = "mine"
        hit = dict(hit2 = hit, hit3 = hit3, hit5 = hit5)
        rs, data = self.player._game.mining_mgr.mining(self.player, type, hit, isbatch)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_deepEnter(self, type):
        """ 进入深渊 """
        resp_f = 'deepEnter'
        rs, data = self.player._game.deep_mgr.enter(self.player, type)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_deepBox(self):
        resp_f = 'deepBox'
        rs, data = self.player._game.deep_mgr.open_box(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_deepFight(self, type):
        resp_f = 'deepFight'
        rs, data = self.player._game.deep_mgr.fight(self.player, type)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_deepAuto(self):
        """ 自动挂机 """
        resp_f = 'deepAuto'
        rs, data = self.player._game.deep_mgr.auto(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        wasteTimes = int(data)
        data = self.player.pack_msg_data(coin=True)
        return pack_msg(resp_f, 1, data=dict(data=data, wasteTimes=wasteTimes))

    def rc_shop(self, t=2):
        """ 神秘商店 """
        resp_f = 'shop'
        rs, data = self.player._game.shop_mgr.enter(self.player, t)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f,1, data=data)

    def rc_shopBuy(self, t=2, sid=0):
        """ 神秘商店购买物品 """
        resp_f = 'shopBuy'
        rs, data = self.player._game.shop_mgr.buy(self.player, t, sid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_dshopBuy(self, id=0, c=0):
        """可购买物品"""
        resp_f = 'dshopBuy'
        rs, data = self.player._game.shop_mgr.dshopBuy(self.player, id, c)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemShop(self):
        """珠宝商店"""
        resp_f = 'gemShop'
        rs, data = self.player._game.shop_mgr.gem_enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f,1, data=data)

    def rc_resetShop(self):
        """ 重置神秘商店 """
        resp_f = "resetShop"
        rs, data = self.player._game.shop_mgr.resetShop(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)


    def rc_allyEnter(self):
        """ 玩家进入游戏的发送 """
        resp_f = "allyEnter"
        rs, data = self.player._game.rpc_ally_mgr.enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)


    def rc_fightReport(self, id):
        """ 获取战报 """
        resp_f = 'fightReport'
        rs, data = self.player._game.rpc_report_mgr.get_url(id)
        if rs:
            return pack_msg(resp_f, 1, data=dict(url=data))
        return pack_msg(resp_f, 0, err=data)

    def rc_rankEnter(self, t, p):
        """ 排行榜 """
        resp_f = 'rankEnter'
        pid = self.player.data.id
        level = self.player.data.level
        if hasattr(self.player.play_attr, 'CBE'):
            p_cbe = self.player.play_attr.CBE
        else:
            p_cbe = 0
        p_data = {'id':pid, 'level':level, 'CBE':p_cbe}
        rs, data = self.player._game.rpc_rank_mgr.enter(p_data, t, p)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_speedUp(self, mul):
        """vip战斗加速mul战斗的倍数"""
        resp_f = 'speedUp'
        rs, data = self.player.vip_attr.speed_up(mul)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_rewardTime(self):
        """ 领取登录时长的奖励 """
        resp_f = 'rewardTime'
        rs, data = self.player._game.reward_mgr2.reward_time(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        #return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 1)

    def rc_rewardActiveEnter(self):
        """ 活动奖励面板打开 """
        resp_f = 'rewardActiveEnter'
        rs, data = self.player._game.reward_mgr2.active_enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        #return pack_msg(resp_f, 1, data = data)
        return pack_msg(resp_f, 1)

    def rc_rewardActive(self, t, lv):
        """
        活动奖励的领取 t = 1 充值 2 = 武器升阶 3 = 招募 4 = 激活码奖励
        t=1对lv参数忽略
        """
        resp_f = 'rewardActive'
        rs, data = self.player._game.reward_mgr2.active_fetch(self.player, t, lv)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        #return pack_msg(resp_f, 1, data = data)
        return pack_msg(resp_f, 1)

    def rc_rewardCode(self, code):
        """ 兑换码领取 """
        resp_f = 'rewardCode'
        rs, data = self.player._game.reward_mgr2.reward_code(self.player, code)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_goodsList(self):
        """ 获取商品列表 """
        resp_f = 'goodsList'
        rs = self.player._game.rpc_vip_mgr.get_goods(self.player.user.sns_type)
        return pack_msg(resp_f, 1, data=rs)

    def rc_goodsBuy(self, t, gid):
        """ 购买商品 """
        log.debug('[rc_goodsBuy](%s)(%s, %s)', self.player.data.id, t, gid)
        resp_f = 'goodsBuy'
        rs, data = self.player._game.rpc_vip_mgr.buy_goods(t, gid,
                self.player.data.uid, self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        gorder, price, good_id = data
        return pack_msg(resp_f, 1, data=dict(gorder=gorder, price=price, gid=good_id))

    def rc_goodsPay(self, gorder, pid):
        """ 支付成功检查 """
        resp_f = 'goodsPay'
        #log.info('[rc_goodsPay](%s)(%s, %s)', self.player.data.id, gorder, pid)
        rs, data = SNSClient.pay(gorder, pid)#, self.player._game.rpc_res_store)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

#    def rc_goodsPay1(self, t, gid, torder):
#        resp_f = 'goodsPay1'
#        log.info('[rc_goodsPay1](%s, %s)', t, torder)
#        rs, data = self.player._game.rpc_vip_mgr.buy_goods(t, gid,
#            self.player.data.uid, self.player.data.id)
#        if not rs:
#            return pack_msg(resp_f, 0, err=data)
#        pre_pay, gorder, price, good_id = data
#        SNSClient.pay1(t, torder, pre_pay, self.player._game.rpc_res_store)
#        return pack_msg(resp_f, 1, data=data)

    def rc_TeamFight(self, tid):
        """组队战斗"""
        resp_f = 'TeamFight'
        if tid == 1000001 or tid == 1000002:
            data = self.test_rc_TeamFight(tid)
        else:
            data = self.player._game.rpc_team_mgr.get_fight_info(tid)
        if data is None:
            return pack_msg(resp_f, 0, err=errcode.EC_TEAM_NOT_FIND)
        return pack_msg(resp_f, 1, data=data)

    def test_rc_TeamFight(self, tid):
        if tid == 1000001:
            pid1, rid1_1, rid1_2 = 526, 1, 21
            pid2, rid2_1 = 700, 6
            pid3, rid3_1 = self.player.data.id, self.player.data.rid

            p1, p2 = self.player.load_player(pid1), self.player.load_player(pid2)
            info1, info2, eid1, eid2 = [], [], [], []
            if p1:
                info1 = p1.team_look([rid1_1, rid1_2])
                _, eid1 = p1.get_main_role_eid()
            if p2:
                info2 = p2.team_look([rid2_1])
                _, eid2 = p2.get_main_role_eid()

            info3 = self.player.team_look([self.player.data.rid])
            _, eid3 = self.player.get_main_role_eid()

            pos = {1:{'pid': pid1, 'rid':rid1_1, 'eid':eid1},
                   2:{'pid': pid1, 'rid':rid1_2},
                   4:{'pid': pid2, 'rid':rid2_1, 'eid':eid2},
                   7:{'pid': pid3, 'rid':rid3_1, 'eid':eid3},
                    } #阵型信息 {index : {pid:0, rid:0} }
            return dict(players = [info1, info2, info3], mb = pos, lid = self.player.data.id)

        if tid == 1000002:
            pid1, rid1_1, rid1_2 = 2905, 1, 26
            pid2, rid2_1, rid2_2 = 3024, 1, 33
            pid3, rid3_1, rid3_2 = 2908, 1, 22

            p1, p2, p3 = self.player.load_player(pid1), self.player.load_player(pid2), self.player.load_player(pid3)
            info1, info2, info3, eid1, eid2, eid3 = [], [], [], [], [], []
            if p1:
                info1 = p1.team_look([rid1_1, rid1_2])
                _, eid1 = p1.get_main_role_eid()
            if p2:
                info2 = p2.team_look([rid2_1, rid2_2])
                _, eid2 = p2.get_main_role_eid()
            if p3:
                info3 = p3.team_look([rid3_1, rid3_2])
                _, eid3 = p3.get_main_role_eid()

            pos = {1:{'pid': pid1, 'rid':rid1_1, 'eid':eid1},
                   2:{'pid': pid1, 'rid':rid1_2},
                   4:{'pid': pid2, 'rid':rid2_1, 'eid':eid2},
                   5:{'pid': pid2, 'rid':rid2_2},
                   7:{'pid': pid3, 'rid':rid3_1, 'eid':eid3},
                   8:{'pid': pid3, 'rid':rid3_2},
                   } #阵型信息 {index : {pid:0, rid:0} }
            return dict(players = [info1, info2, info3], mb = pos, lid = self.player.data.id)

    def rc_TeamDisband(self, tid):
        """解散队伍"""
        resp_f = 'TeamDisband'
        rs, err = self.player._game.rpc_team_mgr.disband(tid)
        if not rs:
            return pack_msg(resp_f, 0, err=err)

    def rc_fightWin(self, fid):
        """主线战斗胜利"""
        resp_f = 'fightWin'
        data = self.player.fight_win(fid)
        if data:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=errcode.EC_FIGHT_WIN)

    def rc_achiEnter(self):
        """进入成就系统"""
        resp_f = 'achiEnter'
        data = self.player.achievement.to_dict()
        return pack_msg(resp_f, 1, data=data)

    def rc_achiUpdate(self):
        """更新成就"""
        resp_f = 'achiUpdate'
        data = self.player.achievement

    def rc_achiReward(self, id, t):
        """领取成就奖励"""
        resp_f = 'achiReward'
        rs, data = self.player.achievement.get_reward(id, t)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemInlay(self, eid, gid, index):
        """珠宝镶嵌"""
        resp_f = 'gemInlay'
        rs, data = self.player._game.gem_mgr.inlay(self.player, eid, gid, index)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemRemove(self, eid, index):
        """珠宝移除"""
        resp_f = 'gemRemove'
        rs, data = self.player._game.gem_mgr.remove(self.player, eid, index)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemTransform(self, feid, teid):
        """珠宝转移"""
        resp_f = 'gemTransform'
        rs, data = self.player._game.gem_mgr.transform(self.player, feid, teid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemMineEnter(self):
        """进入珠宝开采"""
        resp_f = 'gemMineEnter'
        data = self.player._game.gem_mgr.enter_mine(self.player)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemMine(self, t, n):
        """珠宝开采"""
        resp_f = 'gemMine'
        rs, data = self.player._game.gem_mgr.mine(self.player, t, n)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemSanding(self, stuff):
        """珠宝打磨"""
        resp_f = 'gemSanding'
        rs, data = self.player._game.gem_mgr.sanding(self.player, stuff)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemCalc(self, gid, stuff):
        """珠宝升级概率"""
        resp_f = 'gemCalc'
        rs, data = self.player._game.gem_mgr.calculate(self.player, gid, stuff)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=dict(succ=data))

    def rc_gemShop(self):
        """读取珠宝商店信息"""
        resp_f = 'gemShop'
        rs, data = self.player._game.shop_mgr.gem_enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemUpgrade(self, gid, stuff):
        """珠宝升级"""
        resp_f = 'gemUpgrade'
        rs, data = self.player._game.gem_mgr.upgrade(self.player, gid, stuff)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemShopBuy(self, sid):
        """珠宝商店购买"""
        resp_f = 'gemShopBuy'
        rs, data = self.player._game.shop_mgr.gem_buy(self.player, sid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemShopAdd(self):
        """珠宝商店窗口增加"""
        resp_f = 'gemShopAdd'
        rs, data = self.player._game.shop_mgr.gem_add(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_gemShopReset(self):
        """珠宝商店重置"""
        resp_f = 'gemShopReset'
        rs, data = self.player._game.shop_mgr.gem_reset(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_ctreeEnter(self):
        """
        点击进入摇钱树，返回剩余次数
        """
        resp_f = 'ctreeEnter'
        ctree_mgr = self.player._game.ctree_mgr
        rs, data = ctree_mgr.enter(self.player)
        # import logging
        # LG = logging.getLogger()
        # LG.info(str(rs) + ' ---peng--- ' + str(data))
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_ctreeExchange(self):
        """
        处理兑换过程，要用真无宝
        """
        resp_f = 'ctreeExchange'
        ctree_mgr = self.player._game.ctree_mgr
        rs, data = ctree_mgr.exchange(self.player)
        # import logging
        # LG = logging.getLogger()
        # LG.info(str(rs) + ' ---peng--- ' + str(data))
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_roleUpEnter(self):
        """ 进入武将升段 """
        resp_f = 'roleUpEnter'
        rs, data = self.player.roles.role_up_enter()
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_roleUpDo(self, rid):
        """ 武将升段 """
        resp_f = 'roleUpDo'
        role = self.player.roles.rid2roles.get(rid)
        if not role:
            return False, errcode.EC_ROLE_NOFOUND
        rs, data = role.role_up_do()
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_roleUpTrain(self, rid, type):
        """ 武将培养 """
        resp_f = 'roleUpTrain'
        rs, data = self.player.roles.role_train_do(rid, type)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_roleUpTrainOk(self, rid):
        """ 武将培养保存 """
        resp_f = 'roleUpTrainOk'
        rs, data = self.player.roles.role_train_ok(rid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_changeName(self, n=None):
        """
        玩家改名
        """
        resp_f = 'changeName'
        name = n.strip()
        querys = dict(name=name)
        if not name:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        _game = self.player._game
        if _game.rpc_player_mgr.get_id_by_name(name):
            return pack_msg(resp_f, 0, err=errcode.EC_NAME_REPEAT)
        if _game.rpc_store.query_loads(TN_PLAYER, querys=querys):
            return pack_msg(resp_f, 0, err=errcode.EC_NAME_REPEAT)
        #敏感词
        if _game.rpc_ban_word_mgr.check_ban_word(name):
        #if _game.setting_mgr.check_ban_word(name):
            return pack_msg(resp_f, 0, err=errcode.EC_FORBID_STRING)
        name = name[:50]
        log.info(u'pid(%s)原名(%s)改为(%s)', self.player.data.id, self.player.data.name, name)
        self.player.data.name = name
        self.player.save(full=False)
        rs, data = _game.rpc_player_mgr.change_name(self.player.data.id, name, self.player.data.rid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1)

_locks = {}

def _wrap_rpc_lock(func):
    global _locks
    if getattr(func, '_nolock_', None):
        return func

    func_name = func.__name__
    @wraps(func)
    def _func(self, *args, **kw):
        #key = (self, func_name)
        if not self.active:
            return
        if func_name in _locks[self]:#不允许重复
            return pack_msg(func_name[3:], 0, err=errcode.EC_HANDLED)
        _locks[self][func_name] = 1
        try:
            return func(self, *args, **kw)
        finally:
            _locks[self].pop(func_name)
    return _func

#def _wrap_rpc_lock1(func):
#    func_name = func.__name__
#    @wraps(func)
#    def _func(self, *args, **kw):
#        key = (self, func_name)
#        if key in _locks:#不允许重复
#            return pack_msg(func_name[3:], 0, err=errcode.EC_HANDLED)
#        _locks[key] = 1
#        try:
#            return func(self, *args, **kw)
#        finally:
#            _locks.pop(key)
#    return _func

def init_rpc_lock(export_cls):
    """ 保证同一玩家同一时间不能同时调用同一接口 """
    #monitor
    client_monitor_export(export_cls)
    #rpc lock
    attr_pre = export_cls._rpc_attr_pre
    for n in dir(export_cls):
        if not n.startswith(attr_pre):
            continue
        func = getattr(export_cls, n)
        setattr(export_cls, n, _wrap_rpc_lock(func))

init_rpc_lock(PlayerRpcHandler)
_handlers = []
def reg_player_handler(handler_cls):
    """ 注册协议处理类 """
    if handler_cls in _handlers:
        return False
    _handlers.append(handler_cls)
    init_rpc_lock(handler_cls)
    PlayerRpcHandler.__bases__ = tuple(_handlers)
    return True



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
