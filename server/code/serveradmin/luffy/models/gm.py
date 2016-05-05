#coding=utf-8
from flask import g, request
from luffy.helps import grpc_get_proxy
from .u import UserLog
from .mygamebase import MongoFive
from luffy.models import Servers
import time
import json
import luffy.define as EXT
from luffy.forms.cp import MailForm
from corelib import log
from webapi.notify import NotifyServer
from luffy.views import FiveMethods


class Gm(object):
    def __init__(self, t, pid):
        self.t = t
        self.pid = pid
        self.proxy = grpc_get_proxy(g.user.server)

    @property
    def tbox_reset(self):
        num = int(request.args.get('num'))
        cmd = """p=get_by_pid(%d);p.add_re(%d)""" % (self.pid, num)
        return 1, cmd

    @property
    def tbox_change(self):
        chapter = int(request.args.get('chapter'))
        tbids = request.args.get('tbids')
        cmd = """p=get_by_pid(%d);p.tbox_change_data(%d, '%s')""" % (self.pid, chapter, tbids)
        return 1, cmd

    @property
    def awar_kill_monster(self):
        cmd = """p=get_by_pid(%d);p.awar_kill_monster()""" % self.pid
        return 1, cmd

    @property
    def p_attr_copy(self):
        spid = int(request.args.get('spid'))
        cmd = """p=get_by_pid(%d);p.copy(%d)""" % (self.pid, spid)
        return 1, cmd

    @property
    def add_money(self):
        coin1 = request.args.get('coin1')
        coin2 = request.args.get('coin2')
        coin3 = request.args.get('coin3')
        if coin1 == '':coin1 = 0
        if coin2 == '':coin2 = 0
        if coin3 == '':coin3 = 0
        cmd = """add_money(%d,%d,%d,%d)""" % (self.pid, int(coin1), int(coin2), int(coin3))
        return 1, cmd

    @property
    def add_exp(self):
        exp = int(request.args.get('exp'))
        cmd = """p=get_by_pid(%d);p.add_exp(%d)""" % (self.pid, exp)
        return 1, cmd

    @property
    def add_train(self):
        train = int(request.args.get('train'))
        cmd = """p=get_by_pid(%d);p.add_train(%d)""" % (self.pid, train)
        return 1, cmd

    @property
    def add_gem(self):
        gid  = int(request.args.get('gid'))
        level = int(request.args.get('level'))
        is_trade = int(request.args.get('trade'))
        cmd = """p=get_by_pid(%d);p.add_gem(%d, %d, %d)""" % (self.pid, gid, level, is_trade)
        return 1, cmd

    @property
    def reset_shop(self):
        cmd = """p=get_by_pid(%d);p.reset_shop()""" % self.pid
        return 1, cmd

    @property
    def set_sign_day(self):
        day = int(request.args.get('day'))
        cmd = """p=get_by_pid(%d);p.set_sign_day(%d)""" % (self.pid, day)
        return 1, cmd

    @property
    def next_sign(self):
        cmd = """p=get_by_pid(%d);p.next_sign()""" % self.pid
        return 1, cmd

    @property
    def add_fate(self):
        fid = int(request.args.get('fid'))
        level = int(request.args.get('level'))
        cantrade = int(request.args.get('cantrade'))
        cmd = """p=get_by_pid(%d);p.add_fate(%d,%d, can_trade=%d)""" % (self.pid, fid, level, cantrade)
        return 1, cmd

    @property
    def clear_tbox_news(self):
        cmd = """p=get_by_pid(%d);p.del_tbox_news()""" % self.pid
        return 1, cmd

    @property
    def del_deep(self):
        cmd = """p=get_by_pid(%d);p.del_deep()""" % self.pid
        return 1, cmd

    @property
    def deep_jump(self):
        level = int(request.args.get('level'))
        cmd = """p=get_by_pid(%d);p.deep_jump(%d)""" % (self.pid, level)
        return 1, cmd

    @property
    def deep_buff(self):
        count = int(request.args.get('count'))
        cmd = """p=get_by_pid(%d);p.deep_buff(%d)""" % (self.pid, count)
        return 1, cmd

    @property
    def clear_bag(self):
        cmd = """p=get_by_pid(%d);p.clear_bag()""" % self.pid
        return 1, cmd

    @property
    def del_role(self):
        rid = int(request.args.get('rid'))
        cmd = """p=get_by_pid(%d);p.del_role(%d)""" % (self.pid, rid)
        return 1, cmd

    @property
    def add_item(self):
        iid = int(request.args.get('iid'))
        count = int(request.args.get('count'))
        cmd = """p=get_by_pid(%d);p.add_item(%d, %d)""" % (self.pid, iid, count)
        return 1, cmd

    @property
    def add_roleup(self):
        num = int(request.args.get('num'))
        cmd = """p=get_by_pid(%d);p.roleup_add_num(%d)"""% (self.pid, num)
        return 1, cmd

    @property
    def add_task(self):
        tid = int(request.args.get('tid'))
        cmd = """p=get_by_pid(%d);p.add_task(%d)""" % (self.pid, tid)
        return 1, cmd

    @property
    def turn_task(self):
        tid = int(request.args.get('tid'))
        auto = int(request.args.get('auto'))
        cmd = """p=get_by_pid(%d);p.turn_task(%d, %d)""" % (self.pid, tid, auto)
        return 1, cmd

    @property
    def task_complete(self):
        tid = request.args.get('tid')
        cmd = """p=get_by_pid(%d);p.task_complete(%s)""" % (self.pid, tid)
        return 1, cmd

    @property
    def task_clear(self):
        ids = str(request.args.get('ids'))
        request.form.get('ids')
        cmd = """p=get_by_pid(%d);p.task_clear_ids(%s)""" % (self.pid, ids)
        return 1, cmd

    @property
    def kick(self):
        cmd = """p=get_by_pid(%d);p.kick()""" % self.pid
        return 1, cmd

    @property
    def vip_level(self):
        level = int(request.args.get('level'))
        cmd = """p=get_by_pid(%d);p.vip_level(%d)""" % (self.pid, level)
        return 1, cmd

    @property
    def add_fete_num(self):
        num = int(request.args.get('num'))
        t = int(request.args.get('t'))
        cmd = """p=get_by_pid(%d);p.add_fete_num(%d, %d)""" % (self.pid, num, t)
        return 1, cmd

    @property
    def add_fate_num(self):
        num = int(request.args.get('num'))
        t = int(request.args.get('t'))
        cmd = """p=get_by_pid(%d);p.add_fate_num(%d,%d)""" % (self.pid, num, t)
        return 1, cmd

    @property
    def add_arena_count(self):
        num = int(request.args.get('num'))
        cmd = """p=get_by_pid(%d);p.add_arena_count(%d)""" % (self.pid, num)
        return 1, cmd

    @property
    def change_arena_rank(self):
        rank = int(request.args.get('arena_rank'))
        cmd = """p=get_by_pid(%d);p.change_arena_rank(%d)""" % (self.pid, rank)
        return 1, cmd

    @property
    def forbid_chat(self):
        atime = int(request.args.get('time'))
        cmd = """forbid_chat(%d, %d)""" % (self.pid, atime)
        return 1, cmd

    @property
    def gm_start_bot(self):
        cmd = """start_bot()"""
        return 1, cmd

    @property
    def gm_stop_bot(self):
        cmd = """stop_bot()"""
        return 1, cmd

    @property
    def unforbid_chat(self):
        cmd = """unforbid_chat(%d)""" % self.pid
        return 1, cmd

    @property
    def player_pay_back(self):
        pid = int(request.args.get('pid'))
        rid = int(request.args.get('rid'))
        cmd = """player_pay_back(%d, %d)""" % (self.pid, rid)
        return 1, cmd

    @property
    def forbid_login(self):
        atime = int(request.args.get('time'))
        cmd = """forbid_login(%d,%d)""" % (self.pid, atime)
        return 1, cmd

    @property
    def clean_cbe(self):
        rank = int(request.args.get('rank'))
        attr_ret = g.mongo_drive.last(g.GAME_BASEUSER, EXT.BASEUSER_P_ATTR,sort="CBE",
                     limit=100)
        pids = [item['pid'] for item in attr_ret]
        pids = pids[:rank]
        for pid in pids:
            update_querys = {EXT.KEY_PID:pid}
            update_insert = {'CBE':0}
            g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_ATTR, update_querys,
                    update_insert, upsert=False)
        return 0, u'清除5级以前的战斗力成功'

    @property
    def unforbid_login(self):
        cmd = """unforbid_login(%d)""" % self.pid
        return 1, cmd

    @property
    def horn_msgs(self):
        msgs = request.args.get('msgs')
        times = request.args.get('times', '1')
        interval = request.args.get('interval', '1')
        if times == '':
            times='1'
        if interval == '':
            interval='1'
        msgs = u'%s' % msgs
        cmd = """horn_msgs('%s', %d, %d)""" % (msgs, int(times), int(interval))
        return 1, cmd

    @property
    def horn_stop(self):
        cmd = """horn_stop()"""
        return 1, cmd

    @property
    def start_wboss(self):
        t = int(request.args.get('t'))
        if request.args.get('notice'):
            notice = int(request.args.get('notice'))
            cmd = """worldboss_start(%d, %d)""" % (t, notice)
        else:
            cmd = """worldboss_start(%d)""" % t
        return 1, cmd

    @property
    def start_awar(self):
        type = int(request.args.get('type'))
        if request.args.get('notice'):
            notice = int(request.args.get('notice'))
            cmd = """start_awar(%d, %d)""" % (type, notice)
        else:
            cmd = """start_awar(%d)""" % type
        return 1, cmd

    @property
    def worldboss_level(self):
        t = int(request.args.get('t'))
        level = int(request.args.get('level'))
        cmd = """worldboss_level(%d, %d)""" % (level, t)
        return 1, cmd

    @property
    def gm_mail_hide(self):
        pid = int(request.args.get('pid'))
        cmd = """hide_mail(%d) """ % pid
        return 1, cmd

    @property
    def gm_mail_view(self):
        pid = int(request.args.get('pid'))
        cmd = """view_mail(%d) """ % pid
        return 1, cmd

    @property
    def set_debug_data(self):
        ips = request.args.get('debug_ips')
        status = int(request.args.get('debug_status'))
        if status and not ips:
            return 0, u'设置失败,测试状态开启但禁止了所有ip,即所有玩家无法登陆'
        if isinstance(ips, (str, unicode)):
            ips = ips.split(',')
        print "ips:%s, type_ips:%s, status:%s, type_status:%s"%(ips, type(ips), status, type(status))
        cmd = """set_debug_data(%s, %s)""" % (ips, status)
        return 1, cmd

    @property
    def set_allyboss_start(self):
        if not request.args.get('notice'):
            cmd = """p=get_by_pid(%d);p.set_allyboss_start()""" % self.pid
        else:
            notice = int(request.args.get('notice'))
            cmd = """p=get_by_pid(%d);p.set_allyboss_start(%d)""" % (self.pid, notice)
        return 1, cmd

    @property
    def set_level(self):
        level = int(request.args.get('level'))
        cmd = """set_level(%d, %d)""" % (self.pid, level)
        return 1, cmd

    @property
    def add_equip(self):
        eid = int(request.args.get('eid'))
        level = int(request.args.get('level'))
        cantrade = int(request.args.get('cantrade'))
        cmd = """p=get_by_pid(%d);p.add_equip(%d, %d, %d)""" % (self.pid, eid, level, cantrade)
        return 1, cmd

    @property
    def del_offline_player(self):
        cmd = """del_player(%d)""" % self.pid
        return 1, cmd

    @property
    def scene_enter(self):
        mapId = int(request.args.get('mapId'))
        cmd = """scene_enter(%d, %d)""" % (self.pid, mapId)
        return 1, cmd

    @property
    def unlock(self):
        gindex = int(request.args.get('gindex'))
        cmd = """player_func(%d, %d)""" % (self.pid, gindex)
        return 1, cmd

    @property
    def search_pid(self):
        name = request.args.get('name')
        cmd = """get_pid_by_name('%s')"""  % name
        return 1, cmd

    @property
    def rest_daylucky(self):
        nums = int(request.args.get('nums'))
        role = int(request.args.get('role'))
        cmd = """p=get_by_pid(%d);p.rest_daylucky(%d, %d)""" % (self.pid, nums, role)
        return 1, cmd

    @property
    def change_uid(self):
        uid = int(request.args.get('uid'))
        cmd = """change_uid(%d, %d)""" % (self.pid, uid)
        return 1, cmd

    @property
    def arena_start(self):
        cmd = """arena_start()"""
        return 1, cmd

    @property
    def arena_stop(self):
        cmd = """arena_stop()"""
        return 1, cmd

    @property
    def add_bf_boxes(self):
        num = int(request.args.get('num'))
        cmd = """p=get_by_pid(%d);p.add_bf_boxes(%d)""" % (self.pid, num)
        return 1, cmd

    @property
    def set_player_attr(self):
        attr = request.args.get('attr')
        val = request.args.get('val')
        cmd = """p=get_by_pid(%d);p.set_player_attr('%s', %s)""" % (self.pid, attr, val)
        return 1, cmd

    @property
    def set_CBE(self):
        val = int(request.args.get('val'))
        cmd = """change_CBE(%d, %d)""" % (self.pid, val)
        return 1, cmd

    @property
    def fihgt_allyboss_clear(self):
        cmd = """p=get_by_pid(%d);p.fihgt_allyboss_clear()""" % self.pid
        return 1, cmd

    @property
    def clear_ally_tbox_team(self):
        cmd = """p=get_by_pid(%d);p.clear_ally_tbox_team()""" % self.pid
        return 1, cmd

    @property
    def add_achieve(self):
        pids = request.args.get('pids')

        pids = pids.rstrip()
        pids = pids.lstrip()
        if pids == '':
            return 0, cmd
        else:
            if pids[-1] == ',':
                pids = pids[0:-1]
            if int(pids.partition(',')[0]) == -1:
                mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_ACHI, host=g.mongo_host)
                show_attr = {'pid': 1, '_id': 0}
                all_pids = mongo_player.all(isShow=show_attr)
                pids = [c['pid'] for c in all_pids]
            else:
                pids = '[' + pids + ']'
            aid = request.args.get('aid')
            time_dur = int(request.args.get('type'))
            time_dur_str = "day" if time_dur else "ever"
            cmd = """finish_achi('%s', %s, %s)""" % (time_dur_str, aid, str(pids))
        return 1, cmd

    @property
    def add_car(self):
        arg = int(request.args.get('cid'))
        if arg:
            cmd = """p=get_by_pid(%d);p.%s(%d)""" % (self.pid, gtype, arg)
            return 1, cmd
        else:
            cmd = ''
            return 0, u'请输入参数'

    @property
    def kill_boss(self):
        stype = int(request.args.get('type'))
        cmd = """p=get_by_pid(%d);p.kill_boss(%d)""" % (self.pid, stype)
        return 1, cmd

    @property
    def get_reward(self):
        rid = int(request.args.get('rid'))
        cmd = """p=get_by_pid(%d);p.reward(%d)""" % (self.pid, rid)
        return 1, cmd

    @property
    def add_ally_members(self):
        name = request.args.get('name', '')
        p_name = request.args.get('p_name', '')
        nums = request.args.get('nums', 1)
        nums = nums if nums else 1
        name = u'%s' % name
        if p_name:
            p_name = u'%s'%p_name
        cmd = """add_ally_members('%s', "%s", %d)""" % (name, p_name, int(nums))
        return 1, cmd

    @property
    def clear_ally_members(self):
        name = request.args.get('name')
        name = u'%s' % name
        cmd = """clear_ally_except_main('%s')""" % name
        return 1, cmd

    @property
    def change_ally_member_duty(self):
        pid = request.args.get('pid')
        duty = request.args.get('duty')
        name = request.args.get('name')
        name = u'%s' % name
        cmd = """change_ally_duty('%s', '%s', '%s')"""%(pid, duty, name)
        return 1, cmd

    @property 
    def reset_gem_mine(self):
        """ 重置珠宝开采 """
        cmd = """p=get_by_pid(%d);p.reset_gem_mine()""" % self.pid
        return 1, cmd

    @property
    def get_ally_members(self):
        name = request.args.get('ally_name')
        name = u'%s' % name
        cmd = """get_ally_members('%s')""" % name
        return 1, cmd

    @property
    def send_mail(self):
        qf = MailForm()
        mtype = int(request.args.get('type'))
        title = request.args.get('title')
        content = request.args.get('content')
        items = request.args.get('items')
        sns = int(request.args.get(qf.platform.id))

        pids = request.args.get('pids')
        pids = pids.split(',')
        pids = [int(item) for item in pids]
        cmd = 'send_mail(%d, %s, %s, %s)' % (mtype, title, content, items)
        if items:
            try:
                items = json.loads(items)
            except:
                return 0, u"发送的邮件奖励物品列表格式可能不正确请检查"
        else:
            items = None

        if not sns == 0:
            p_querys = {'_id': {'$in': pids}}
            player_ret = g.mongo_drive.filter(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER,  querys=p_querys, show={EXT.KEY_UID: 1})
            user_coll = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
            snspids = []
            for p in player_ret:
                u = user_coll.find_one({'_id': p[EXT.KEY_UID]})
                if u:
                    u.get('sns', 0) == sns and snspids.append(p['_id'])
            pids = snspids
        ret = self.proxy.send_mail(pids, mtype, title, content, items)
        tmp_p = len(pids)
        return 0, "".join([cmd, ",", ret, "total(", str(tmp_p), ")"])

    @property
    def send_mail_date(self):
        qf = MailForm()
        mtype = int(request.args.get('type'))
        title = request.args.get('title')
        content = request.args.get('content')
        items = request.args.get('items')
        sns = int(request.args.get(qf.platform.id))

        cmd = 'send_mail(%d, %s, %s, %s)' % (mtype,title,content,items)
        start_time_str = request.args.get('start_time')
        start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
            "", beforeDay=EXT.NUMBER_SEVEN, searchCondition="day")
        p_querys = {EXT.KEY_TNEW:{EXT.MONGO_LT:start_time}}
        tpids = g.mongo_drive.distinct(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, EXT.KEY_MONGO_ID, p_querys)
        if items:
            try:
                items = json.loads(items)
            except:
                return 0, u"发送的邮件奖励物品列表格式可能不正确请检查"
        else:
            items = None

        if not sns == 0:
            p_querys = {'_id': {'$in': tpids}}
            player_ret = g.mongo_drive.filter(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER,  querys=p_querys, show={EXT.KEY_UID: 1})
            user_coll = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
            snspids = []
            for p in player_ret:
                u = user_coll.find_one({'_id': p[EXT.KEY_UID]})
                if u:
                    u.get('sns', 0) == sns and snspids.append(p['_id'])

            tpids = snspids
        i = 0
        for x in xrange(len(tpids)/100+1):
            tmp_p = tpids[i:100+i]
            ret = self.proxy.send_mail(tmp_p, mtype, title, content, items)
            i += 100
            if len(tmp_p)<100:
                break
        return 0, "".join([cmd, ",", ret, "total(", str(len(tpids)), ")"])

    @property
    def arena_init(self):
        ret = self.proxy.arena_init()
        cmd = 'arena_init()'
        return 0, "".join([cmd, ret])

    @property
    def restart(self):
        try:
            mins = int(request.args.get('mins'))
            ret = self.proxy.restart(mins)
        except:
            ret = u'重启失败'
        cmd = 'restart()'
        return 0, "".join([cmd, ret])

    @property
    def stop(self):
        try:
            mins = int(request.args.get('mins'))
            ret = self.proxy.restart_stop(mins)
        except:
            ret = u'停止失败'
        cmd = 'restart stop()'
        return 0, "".join([cmd, ret])

    @property
    def reload_ban_words(self):
        try:
            ret = self.proxy.reload_ban_words()
        except:
            ret = u'加载失败'
        cmd = 'reload_ban_words'
        return 0, "".join([cmd, ret])

    @property
    def notify_players(self):
        global g_token_server
        msgs = request.args.get('msgs')
        if isinstance(msgs, unicode):
            msgs = msgs.encode('utf-8')
        is_all = int(request.args.get('all', False))
        str_pids = request.args.get('pids')
        init_token_server()
        return g_token_server.send_msgs(str_pids, msgs, is_all)


    def execute(self):
        ret = cmd = ''
        user_log = UserLog()

        if not self.proxy:
            return u'无法连接游戏服务器'
        is_ok, cmd = getattr(self, self.t)
        if is_ok == 1:
            ret = self.proxy.gm(self.pid, cmd)
        if is_ok == 0:
            ret = cmd
        user_log.u  = g.user.username
        user_log.ty = 2
        user_log.i  = cmd
        user_log.t  = time.time()
        user_log.save()
        return ret

num_per_page = 1000

class MyNotifyServer(NotifyServer):

    def start(self):
        NOTIFY_APNS = 'notify_apns'
        _coll_config = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
        shows = {'value':1}
        t_apns = _coll_config.filter({"key":NOTIFY_APNS}, shows)
        if t_apns is not None:
            t_apns = t_apns[0]['value']
            if isinstance(t_apns, (str, unicode)):
                t_apns = eval(t_apns)
            sanbox, pem = t_apns
            import config
            self.start_apns(pem, config.cfg_path, sanbox)
            log.info('*****[notify]APNS service start!')

    def _pids_tokens(self, str_pids):
        """
        通知一部分玩家
        """
        data_base = g.current_server.db_user
        _player = MongoFive(data_base, EXT.BASEUSER_PLAYER, host=g.mongo_host)
        _user = MongoFive(data_base, EXT.BASEUSER_USER, host=g.mongo_host)

        dt_shows = {EXT.KEY_MONGO_ID:1, EXT.KEY_DT:1}
        pids = [int(pid) for pid in str_pids.split(",")]
        querys = {EXT.KEY_MONGO_ID:{EXT.MONGO_IN:pids}}
        shows = {EXT.KEY_UID:1}
        uids = _player.find(querys, shows)
        uids = [d.pop(EXT.KEY_UID) for d in uids]

        querys = {EXT.KEY_MONGO_ID:{EXT.MONGO_IN:uids}}
        db_users = _user.filter(querys, dt_shows)
        return db_users

    def _all_tokens(self):
        """
        通知所有玩家
        """
        dbs = Servers.query.all()
        db_res = g.current_server.db_res
        log.info("++++++the db_res is:%s", db_res)
        notify_dbs = []
        all_db_users = []
        dt_shows = {EXT.KEY_MONGO_ID:1, EXT.KEY_DT:1}
        for db in dbs:
            if db.db_res == db_res:
                _user = MongoFive(db.db_user, EXT.BASEUSER_USER, host=g.mongo_host)
                pages = _user.count()/num_per_page + 1
                for page in xrange(pages):
                    dt = _user.paginate(page+1, num_per_page)
                    all_db_users.extend(dt)
        return all_db_users

    def filter_repeat(self, users):
        """
        过滤重复的tokens
        """
        tokens = {}
        for user_dic in users:
            if not user_dic.has_key(EXT.KEY_DT):
                continue
            uid, token = user_dic[EXT.KEY_MONGO_ID], user_dic[EXT.KEY_DT]
            if not token:
                continue
            tokens[token] = uid
        return tokens

    def get_tokens(self, is_all, str_pids):
        users = self._all_tokens() if is_all else self._pids_tokens(str_pids)
        return self.filter_repeat(users)

    def send_msgs(self, str_pids, msg, is_all=False,**kw):
        """ 向某玩家推送消息 """
        if isinstance(msg, unicode):
            msg = msg.encode('utf-8')
        tokens = self.get_tokens(is_all, str_pids)
        if not tokens:
            return 0, u"数据得到空请确定pid正确或者数据库不为空"
        from datetime import datetime
        _start = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log.info("%s token_send_start,msg:%s", _start, msg)
        kw['identifier'] = 0
        for token, uid in tokens.iteritems():
            if not token:
                continue
            kw['identifier'] += 1
            self.send_msg_by_token(uid, token, msg, **kw)
        _end = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log.info("%s token_send_end, num:%s", _end, kw['identifier'])
        return 0, u'token发送完成'

    def send_msg_by_token(self, uid, token, msg, **kw):
        if self.apns_started:
            try:
                log.info("identifier:%s,uid:%s,token:%s", kw['identifier'], uid, token)
                self.send_apns_msg(token, msg, **kw)
            except Exception, e:
                log.log_except()
                #log.error('[apns]send_msg_by_token error:(%s, %s) %s', uid, token, e)

g_token_server = None
if 0:
    g_token_server = MyNotifyServer()

def init_token_server():
    global g_token_server
    if g_token_server:
        return
    g_token_server = MyNotifyServer()
    g_token_server.start()


