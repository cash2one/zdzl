#coding=utf-8 
from bson.objectid import ObjectId
from luffy.extensions import db
import luffy.define as EXT
from .u import FilterPlayer
from flask import g
from luffy.count import Count
from .mygamebase import MongoFive
import time
from luffy.helps import time_to_hour

g_types = range(1, 13)

class BaseData(object):
    def __init__(self, start_time, end_time, time_format):
        self.time_format = time_format
        self.start_time = start_time
        self.end_time = end_time
        self.e_name, self.e_list = self.filter_name()

    def filter_name(self):
        return FilterPlayer.get_pids(), FilterPlayer.get_uids()

class BaseRetention(db.Document):
    t = db.FloatField(db_field='t')
    # 服务器
    s = db.StringField(db_field='s')
    # 留存率
    r = db.FloatField(db_field='r')

class RetentionCount2(BaseRetention):
    """ 次日留存率统计 """


class RetentionCount7(BaseRetention):
    """ 7日留存率统计 """


class RetentionCount15(BaseRetention):
    """ 15日留存率统计 """


class RetentionCountData(BaseData):
    def __init__(self, start_time, end_time, time_format):
        super(RetentionCountData, self).__init__(start_time, end_time, time_format)

    def get_r(self):
        mongo_user      = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
        mongo_log       = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
        mongo_player    = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
        user_querys  = {EXT.KEY_TNEW:{EXT.MONGO_GT:self.start_time, 
                EXT.MONGO_LT:self.start_time+EXT.NUM_UNIX_A_DAY-1}}
        user_ret    = mongo_user.distince_filter(EXT.KEY_MONGO_ID, user_querys)
        reg_user_count = len(user_ret)
        if reg_user_count == 0:
            return
            # start_time += EXT.NUM_UNIX_A_DAY
            # continue
        # PID对应UID
        pid_user_dict = {}
        for item in user_ret:
            pid_quers = {EXT.KEY_UID:item, EXT.KEY_LEVEL:{EXT.MONGO_GT:1}}
            # 查找uid对应的pid
            pid_ret = mongo_player.filter(dic=pid_quers)
            if pid_ret:
                for p in pid_ret:
                    pid_user_dict[p[EXT.KEY_MONGO_ID]] = item
            # 查询15天
        login_uid = {2:[], 3:[], 4:[], 5:[], 6:[], 7:[], 15:[]}
        for i in xrange(2, 16):
            rentention_start = self.start_time + EXT.NUM_UNIX_A_DAY * (i-1)
            log_querys = {EXT.KEY_CT:{EXT.MONGO_GT:rentention_start, EXT.MONGO_LT:rentention_start + EXT.NUM_UNIX_A_DAY},
                          EXT.MONGO_OR:[{EXT.KEY_T:1}, {EXT.KEY_T:2}]}
            p_ret = mongo_log.distince_filter(EXT.KEY_P, log_querys)
            for p in p_ret:
                if p not in pid_user_dict:
                    continue
                if i < 8:
                    if pid_user_dict[p] not in login_uid[i]:
                        login_uid[i].append(pid_user_dict[p])
                if 7 < i < 16:
                    if pid_user_dict[p] not in login_uid[15]:
                        login_uid[15].append(pid_user_dict[p])
        ret = {}
        # 15日留存率
        day7 = set(login_uid[2])|set(login_uid[3])|set(login_uid[4])|set(login_uid[5])|set(login_uid[6])|set(login_uid[7])
        if time.time() - self.start_time > EXT.NUM_UNIX_A_DAY * 15:
            ret[15] = round( float(len(day7 & set(login_uid[15])))/float(reg_user_count)*100, 2)
        if time.time() - self.start_time > EXT.NUM_UNIX_A_DAY * 7:
            ret[7] = round(float(len(day7))/float(reg_user_count)*100,2)
        ret[0] = reg_user_count
        for k in login_uid.keys():
            if k != 15 and k != 7:
                ret[k] = round(float(len(login_uid[k]))/float(reg_user_count)*100,2)
        return ret

def get_r(alist, time_format, searchCondition, t):
    for item in alist:
        today = time_to_hour(time.time(), EXT.UNIX_TIME_YMD_FORMAT)
        if t == 2 and item >= today-EXT.NUM_UNIX_A_DAY:
            continue
        if t == 7 and item >= today - EXT.NUM_UNIX_A_DAY*7:
            continue
        if t == 15 and item >= today - EXT.NUM_UNIX_A_DAY*15:
            continue
        r_data = RetentionCountData(item, item+EXT.NUM_UNIX_A_DAY, time_format)
        ret = r_data.get_r()
        if not ret:
            continue
        if t == 2:
            rentention = RetentionCount2()
        if t == 7:
            rentention = RetentionCount7()
        if t == 15:
            rentention = RetentionCount15()
        rentention.t = item
        rentention.s = g.GAME_BASEUSER
        if t == 2 and 2 in ret:
            rentention.r = ret[2]
        if t == 7 and 7 in ret:
            rentention.r = ret[7]
        if t == 15 and 15 in ret:
            rentention.r = ret[15]
        rentention.save()

def c2dict(r2, r7, r15):
    ret2 = {} 
    ret7 = {}
    ret15 = {}
    [ret2.update({item.t:item.r}) for item in r2]
    [ret7.update({item.t:item.r}) for item in r7]
    [ret15.update({item.t:item.r}) for item in r15]
    return ret2, ret7, ret15


class ComplexCount(db.Document):
    """ 综合统计 """
    # 时间
    t = db.FloatField(db_field='t')
    # 服务器
    s = db.StringField(db_field='s')
    # 创号人数
    create = db.IntField(db_field='c', allow_none=True, required=False)
    # 登录人数
    login = db.IntField(db_field='l', allow_none=True, required=False)
    # 最大在线
    max_online = db.IntField(db_field='m', allow_none=True, required=False)
    # 平均在线
    avg_online = db.IntField(db_field='a', allow_none=True, required=False)
    # 充值金额
    pay = db.IntField(db_field='p', allow_none=True, required=False)
    # 充值笔数
    paynums = db.IntField(db_field='n', allow_none=True, required=False)
    # 充值人数
    payusers = db.IntField(db_field='u', allow_none=True, required=False)
    # 新增充值人数
    newnums = db.IntField(db_field='w', allow_none=True, required=False)
    # 最大登录数pid
    max_login_pid = db.IntField(db_field='lp', allow_none=True, required=False)
    # 最大登录数uid
    max_login_uid = db.IntField(db_field='lu', allow_none=True, required=False)

class ComplexCountFromDatabase(BaseData):
    def __init__(self, start_time, end_time, time_format):
        super(ComplexCountFromDatabase, self).__init__(start_time, end_time, time_format)

    def get_create_user(self):
        """ 获取创号人数 """
        D_U = 'd.u'
        database        = (g.GAME_BASEUSER, EXT.BASEUSER_USER, g.mongo_host)
        user_count      = Count(self.start_time, self.end_time, database, origin=True)
        mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
        e_uids = mongo_player.distince_filter(EXT.KEY_UID, {EXT.KEY_NAME:{EXT.MONGO_IN:self.e_name}})
        querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:self.e_list}},
                            EXT.KEY_MONGO_ID:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
        tmp_user_ret    = user_count.getCount(EXT.KEY_TNEW, self.time_format,
                            querys_addition=querys_addition)
        user_ret = {}
        [user_ret.update({item[0]:item[1]}) for item in tmp_user_ret]

        # 登陆人数
        mongo_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
        e_list_uids = mongo_user.distince_filter(EXT.KEY_MONGO_ID,
                        {EXT.KEY_NAME:{EXT.MONGO_IN:self.e_list}})
        e_uids = list(set(e_uids)|set(e_list_uids))
        database        = (g.GAME_LOG, EXT.LOG_INFO, g.mongo_host)
        login_count     = Count(self.start_time, self.end_time, database)
        querys_addition = { EXT.MONGO_OR:[{EXT.KEY_T:1},{EXT.KEY_T:2}],
                D_U:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
        login_ret       = login_count.getLogin(EXT.KEY_CT, self.time_format, querys_addition)
        return user_ret, login_ret

    def get_maxlogin(self):
        """最高在线人数，平均在线人数"""
        from luffy.count import LoginCount
        login_count = LoginCount(self.start_time, self.end_time)
        pid_ret, uid_ret = login_count.get_ret()
        return pid_ret, uid_ret

    def get_max_avg(self, searchCondition):
        """最高在线人数，平均在线人数"""
        from luffy.count import OnlineCount
        database = (g.GAME_LOG, EXT.LOG_ONLINE, g.mongo_host)
        online_count = OnlineCount(self.start_time, self.end_time, database, searchCondition)
        ret = online_count.get_ret(EXT.KEY_CT, EXT.KEY_C)
        online_max = {}
        [online_max.update({item[0]:item[1][EXT.STRING_MAX]}) for item in ret]
        online_avg = {}
        [online_avg.update({item[0]:item[1]['avg']}) for item in ret]
        return online_max, online_avg

    def get_pay(self):
        """充值金额"""
        ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
        database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
        pay_count       = Count(self.start_time, self.end_time, database, origin=True)
        pay_ret         = pay_count.getAccumulateCount(EXT.KEY_CT, EXT.STRING_PRICE,
                                         self.time_format, querys_addition=ex_q)
        # 充值笔数
        all_deals = pay_count.count([self.start_time], EXT.KEY_CT, **ex_q)
        return pay_ret, all_deals
        
    def get_pay_nums(self):
        """充值人数"""
        ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
        database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
        pay_count       = Count(self.start_time, self.end_time, database)
        pay_nums        = pay_count.getPlayer(EXT.KEY_CT, [self.start_time], count_key=EXT.KEY_UID, q=ex_q)
        # 新增充值人数
        new_pay_nums    = pay_count.getNewPlayer(EXT.KEY_CT, [self.start_time], querys_addition=ex_q)
        return pay_nums, new_pay_nums

def NewComplexCountToday(time_format, searchCondition):
    today = time_to_hour(time.time(), EXT.UNIX_TIME_YMD_FORMAT)
    complex_count   = ComplexCount()
    from_database = ComplexCountFromDatabase(today, today+EXT.NUM_UNIX_A_DAY, time_format)
    # 创建用户数, 登录用户数
    create_users, login_ret    = from_database.get_create_user()
    # 最大在线，平均在线
    online_max, online_avg  = from_database.get_max_avg(searchCondition)
    # 最大登录数
    max_login_pid, max_login_uid = from_database.get_maxlogin()
    # 充值金额， 充值笔数
    pay_ret, all_deals      = from_database.get_pay()
    # 充值人数， 新增充值人数
    pay_nums, new_pay_nums  = from_database.get_pay_nums()
    try:
        create_users = create_users[today]
    except:
        create_users = 0
    try:
        login_ret = login_ret[today]
    except:
        login_ret = 0
    try:
        online_max = online_max[today]
    except:
        online_max = 0
    try:
        online_avg = online_avg[today]
    except:
        online_avg = 0
    try:
        pay_ret = pay_ret[today]
    except:
        pay_ret = 0
    try:
        all_deals = all_deals[today]
    except:
        all_deals = 0
    try:
        pay_nums = pay_nums[today]
    except:
        pay_nums = 0
    try:
        new_pay_nums = new_pay_nums[today]
    except:
        new_pay_nums = 0
    if max_login_pid == {}:
        max_login_pid = 0
    # if max_login_uid == {}:
    #     max_login_uid = 0
    return (today, create_users, login_ret, online_max, online_avg, max_login_pid, 
        pay_ret, all_deals, pay_nums, new_pay_nums)

def NewComplexCount(alist, time_format, searchCondition):
    """ 从列表内的时间内创建内容 """
    for item in alist:
        today = time_to_hour(time.time(), EXT.UNIX_TIME_YMD_FORMAT)
        if item >= today:
            continue
        complex_count   = ComplexCount()
        from_database = ComplexCountFromDatabase(item, item+EXT.NUM_UNIX_A_DAY, time_format)
        # 创建用户数, 登录用户数
        create_users, login_ret    = from_database.get_create_user()
        # 最大在线，平均在线
        online_max, online_avg  = from_database.get_max_avg(searchCondition)
        # 最大登录数
        max_login_pid, max_login_uid = from_database.get_maxlogin()
        # 充值金额， 充值笔数
        pay_ret, all_deals      = from_database.get_pay()
        # 充值人数， 新增充值人数
        pay_nums, new_pay_nums  = from_database.get_pay_nums()
        complex_count.t = item
        complex_count.s = g.GAME_BASEUSER
        if item in create_users:
            complex_count.create = int(create_users[item])
        if item in login_ret:
            complex_count.login = int(login_ret[item])
        if item in online_max:
            complex_count.max_online = int(online_max[item])
        if item in online_avg:
            complex_count.avg_online = int(online_avg[item])
        if item in pay_ret:
            complex_count.pay = int(pay_ret[item])
        if item in all_deals:
            complex_count.paynums = int(all_deals[item])
        if item in pay_nums:
            complex_count.payusers = int(pay_nums[item])
        if item in new_pay_nums:
            complex_count.newnums = int(new_pay_nums[item])
        complex_count.max_login_pid = max_login_pid
        # complex_count.max_login_uid = max_login_uid
        complex_count.save()


# =============== 分平台 ================
class CCount(db.Document):
    """ 综合统计 """
    # 时间
    t = db.FloatField(db_field='t')
    # 服务器
    s = db.StringField(db_field='s')
    # 创号人数
    create = db.IntField(db_field='c', allow_none=True, required=False)
    # 登录人数
    login = db.IntField(db_field='l', allow_none=True, required=False)
    # 最大在线
    max_online = db.IntField(db_field='m', allow_none=True, required=False)
    # 平均在线
    avg_online = db.IntField(db_field='a', allow_none=True, required=False)
    # 充值金额
    pay = db.IntField(db_field='p', allow_none=True, required=False)
    # 充值笔数
    paynums = db.IntField(db_field='n', allow_none=True, required=False)
    # 充值人数
    payusers = db.IntField(db_field='u', allow_none=True, required=False)
    # 新增充值人数
    newnums = db.IntField(db_field='w', allow_none=True, required=False)
    # 最大登录数pid
    max_login_pid = db.IntField(db_field='lp', allow_none=True, required=False)
    # 最大登录数uid
    max_login_uid = db.IntField(db_field='lu', allow_none=True, required=False)
    #平台
    platform = db.IntField(db_field='pf')

class Statistics(object):
    def __init__(self, start_time, end_time, database, origin=False):
        if origin:
            self.start_time = start_time
            self.end_time   = end_time
        else:
            self.start_time = time_to_hour(start_time)
            self.end_time   = time_to_hour(end_time)
        self.db, self.collection, self.host = database

    def hour_count(self, alist, query_key, time_format, return_type='list'):
        """ 对每小时进行统计 """
        ret = {}
        for item in alist:
            time_key = time_to_hour(item[query_key], time_format)
            if time_key in ret:
                if item['sns'] in ret[time_key]:
                    ret[time_key][item['sns']] += 1
                else:
                    ret[time_key][item['sns']] = 1
            else:
                ret[time_key] = {}
                ret[time_key][item['sns']] = 1
        if return_type == 'list':
            return sorted(ret.items(), key=lambda d:d[0])
        if return_type == 'dict':
            return ret

    def count(self, time_list, query_key, kw, types=None, st=None):
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            ret[item] = {}
            querys = {query_key: {EXT.MONGO_GTE: item,
                          EXT.MONGO_LT: item + EXT.NUM_UNIX_A_DAY - 1}}
            if kw:
                querys.update(kw)
            if st != -1:
                querys.update({EXT.KEY_T:st})
                ret[item][st] = mongo.count(dic=querys)
            else:
                for t in types:
                    querys.update({EXT.KEY_T:t})
                    ret[item][t] = mongo.count(dic=querys)
        return ret

    def getRetByQuerys(self, query_key, querys_addition=None):
        """ 条件查询 """
        mongo = MongoFive(self.db, self.collection, self.host)
        querys = {query_key:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LT:self.end_time}}

        if querys_addition:
            querys.update(querys_addition)
        return mongo.filter(dic=querys, sort=query_key)

    def getAccumulateCount(self, query_key, count_key, time_format,
                    querys_addition=None):
        """ 获取支付统计 """
        mongo_ret = self.getRetByQuerys(query_key, querys_addition)
        # return accumulate_count(mongo_ret, query_key, count_key, time_format)
        ret = {}
        for item in mongo_ret:
            time_key =  time_to_hour(item[query_key], time_format=time_format)
            if time_key in ret:
                if item['t'] in ret[time_key]:
                    ret[time_key][item['t']] += item[EXT.STRING_PRICE]
                else:
                    ret[time_key][item['t']] = item[EXT.STRING_PRICE]
                # ret[time_key] += item[EXT.STRING_PRICE]
            else:
                ret[time_key] = {}
                ret[time_key][item['t']] = item[EXT.STRING_PRICE]
                # ret[time_key] = item[EXT.STRING_PRICE]
        return ret

    def getCount(self, query_key, time_format, return_type='list',
                querys_addition=None):
        """ 获取统计总数 """
        mongo_ret = self.getRetByQuerys(query_key, querys_addition)
        return self.hour_count(mongo_ret, query_key, time_format, return_type)

    def getLogin(self, query_key, time_format, querys_addition=None,
                types=None, st=None):
        """ log_info登陆记录 """
        D_U = 'd.u'
        mongo_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
        mongo_log = MongoFive(self.db, self.collection, self.host)
        querys  = {query_key:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LTE:self.end_time}}
        if querys_addition:
            querys.update(querys_addition)
        # 获取登录角色
        uids = {}
        ret = {}
        players = mongo_log.filter(querys)
        for p in players:
            if EXT.KEY_D not in p:
                continue
            if EXT.KEY_U not in p[EXT.KEY_D]:
                continue
            day = time_to_hour(p[query_key], time_format)
            u = mongo_user.first({EXT.KEY_MONGO_ID:int(p[EXT.KEY_D][EXT.KEY_U])})
            if not u or 'sns' not in u:
                continue
            if day in uids and u['sns'] in uids[day] and u['_id'] in uids[day][u['sns']]:
                continue
            if day in ret:
                if u['sns'] in ret[day]:
                    ret[day][u['sns']] += 1
                else:
                    ret[day][u['sns']] = 1
            else:
                ret[day]= {u['sns']:1}
            if day in uids:
                if u['sns'] in uids[day]:
                    uids[day][u['sns']].append(u['_id'])
                else:
                    uids[day][u['sns']] = [u['_id']]
            else:
                uids[day] = {u['sns']:[u['_id']]}
        for k in uids.keys():
            for key in uids[k].keys():
                print k, key, uids[k][key]
        return ret

    def getPlayer(self, query_key, time_list, count_key=EXT.KEY_PID, q=None, 
            types=None, st=None):
        """ 获取充值角色数 """
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            ret[item] = {}
            paid_querys = {query_key:{EXT.MONGO_GTE:item, EXT.MONGO_LT:item+EXT.NUM_UNIX_A_DAY-1}}
            if q:
                paid_querys.update(q)
            if st != -1:
                paid_querys.update({EXT.KEY_T:st})
                paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)
                ret[item][st] = len(paid_ret)
            else:
                for t in types:
                    paid_querys.update({EXT.KEY_T:t})
                    paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)
                    ret[item][t] = len(paid_ret)
            # paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)
            # ret[item] = len(paid_ret)
        return ret

    def getNewPlayer(self, query_key, time_list, time_range=EXT.NUM_UNIX_A_DAY,
                        querys_addition=None, types=None, st=None):
        """ 获取新充值人数 """
        def get_before(mongo, paid_querys, ret, item, t):
            paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)
            if not paid_ret:
                ret[item][t] = 0
                return
            for p in paid_ret:
                paid_before = {query_key:{EXT.MONGO_LT:item}, EXT.KEY_PID:p}
                if querys_addition:
                    paid_before.update(querys_addition)
                paid_before_ret = mongo.first(dic=paid_before)
                if not paid_before_ret:
                    if item in ret:
                        if t in ret[item]:
                            ret[item][t] += 1
                        else:
                            ret[item][t] = 1
                    else:
                        ret[item][t] = 1
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            ret[item] = {}
            paid_querys = {query_key:{EXT.MONGO_GTE:item, EXT.MONGO_LT:item+time_range-1}}
            if querys_addition:
                paid_querys.update(querys_addition)
            if st != -1:
                paid_querys.update({EXT.KEY_T:st})
                get_before(mongo, paid_querys, ret, item, st)
            else:
                for t in types:
                    paid_querys.update({EXT.KEY_T:t})
                    get_before(mongo, paid_querys, ret, item, t)
        return ret

class CCountFromDatabase(BaseData):
    def __init__(self, start_time, end_time, time_format):
        super(CCountFromDatabase, self).__init__(start_time, end_time, time_format)

    def get_create_user(self):
        """ 获取创号人数 """
        D_U = 'd.u'
        database        = (g.GAME_BASEUSER, EXT.BASEUSER_USER, g.mongo_host)
        user_count      = Statistics(self.start_time, self.end_time, database, origin=True)
        mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
        e_uids = mongo_player.distince_filter(EXT.KEY_UID, {EXT.KEY_NAME:{EXT.MONGO_IN:self.e_name}})
        querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:self.e_list}},
                            EXT.KEY_MONGO_ID:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
        user_ret    = user_count.getCount(EXT.KEY_TNEW, self.time_format,
                            querys_addition=querys_addition, return_type='dict')

        # 登陆人数
        mongo_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
        e_list_uids = mongo_user.distince_filter(EXT.KEY_MONGO_ID,
                        {EXT.KEY_NAME:{EXT.MONGO_IN:self.e_list}})
        e_uids = list(set(e_uids)|set(e_list_uids))
        database        = (g.GAME_LOG, EXT.LOG_INFO, g.mongo_host)
        login_count     = Statistics(self.start_time, self.end_time, database)
        querys_addition = { EXT.MONGO_OR:[{EXT.KEY_T:1},{EXT.KEY_T:2}],
                D_U:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
        login_ret       = login_count.getLogin(EXT.KEY_CT, self.time_format, querys_addition)
        return user_ret, login_ret

    def get_maxlogin(self):
        """最高在线人数，平均在线人数"""
        from luffy.count import LoginCount
        login_count = LoginCount(self.start_time, self.end_time)
        pid_ret, uid_ret = login_count.get_ret()
        return pid_ret, uid_ret

    def get_max_avg(self, searchCondition):
        """最高在线人数，平均在线人数"""
        from luffy.count import OnlineCount
        database = (g.GAME_LOG, EXT.LOG_ONLINE, g.mongo_host)
        online_count = OnlineCount(self.start_time, self.end_time, database, searchCondition)
        ret = online_count.get_ret(EXT.KEY_CT, EXT.KEY_C)
        online_max = {}
        [online_max.update({item[0]:item[1][EXT.STRING_MAX]}) for item in ret]
        online_avg = {}
        [online_avg.update({item[0]:item[1]['avg']}) for item in ret]
        return online_max, online_avg

    def get_pay(self, types=None, st=-1):
        """充值金额"""
        ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
        database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
        pay_count       = Statistics(self.start_time, self.end_time, database, origin=True)
        pay_ret         = pay_count.getAccumulateCount(EXT.KEY_CT, EXT.STRING_PRICE,
                                         self.time_format, querys_addition=ex_q)
        # 充值笔数
        all_deals = pay_count.count([self.start_time], EXT.KEY_CT, ex_q, types, st)
        return pay_ret, all_deals
        
    def get_pay_nums(self, types=None, st=-1):
        """充值人数"""
        ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
        database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
        pay_count       = Statistics(self.start_time, self.end_time, database)
        pay_nums        = pay_count.getPlayer(EXT.KEY_CT, [self.start_time], 
            count_key=EXT.KEY_UID, q=ex_q, types=types, st=st)
        # 新增充值人数
        new_pay_nums    = pay_count.getNewPlayer(EXT.KEY_CT, [self.start_time], 
            querys_addition=ex_q, types=types, st=st)
        return pay_nums, new_pay_nums

def NewCCountToday(time_format, searchCondition, st):
    global g_types
    today = time_to_hour(time.time(), EXT.UNIX_TIME_YMD_FORMAT)
    complex_count   = CCount()
    from_database = CCountFromDatabase(today, today+EXT.NUM_UNIX_A_DAY, time_format)
    # 创建用户数, 登录用户数
    create_users, login_ret    = from_database.get_create_user()
    # 最大在线，平均在线
    online_max, online_avg  = from_database.get_max_avg(searchCondition)
    # 最大登录数
    max_login_pid, max_login_uid = from_database.get_maxlogin()
    # 充值金额， 充值笔数
    pay_ret, all_deals      = from_database.get_pay(types=g_types, st=st)
    # 充值人数， 新增充值人数
    pay_nums, new_pay_nums  = from_database.get_pay_nums(types=g_types, st=st)
    
    print "**pay_ret, all_deals **", pay_ret, all_deals 
    if create_users:
        if st != -1:
            if st in create_users[today]:
                create_users = create_users[today][st]
            else:
                create_users = 0
        else:
            total = 0
            for k in create_users[today].keys():
                total += create_users[today][k]
            create_users = total
    else:
        create_users = 0

    if login_ret:
        if st != -1:
            if st in login_ret[today]:
                login_ret = login_ret[today][st]
            else:
                login_ret = 0
        else:
            total = 0
            for k in login_ret[today].keys():
                total += login_ret[today][k]
            login_ret = total
    else:
        login_ret = 0


    try:
        online_max = online_max[today]
    except:
        online_max = 0
    try:
        online_avg = online_avg[today]
    except:
        online_avg = 0

    if pay_ret:
        if st != -1:
            if st in pay_ret[today]:
                pay_ret = pay_ret[today][st]
            else:
                pay_ret = 0
        else:
            total = 0
            for k in pay_ret[today].keys():
                total += pay_ret[today][k]
            pay_ret = total
    else:
        pay_ret = 0


    if all_deals:
        if st != -1:
            if st in all_deals[today]:
                all_deals = all_deals[today][st]
            else:
                all_deals = 0
        else:
            total = 0
            for k in all_deals[today].keys():
                total += all_deals[today][k]
            all_deals = total
    else:
        all_deals = 0

    if pay_nums:
        if st != -1:
            if st in pay_nums[today]:
                pay_nums = pay_nums[today][st]
            else:
                pay_nums = 0
        else:
            total = 0
            for k in pay_nums[today].keys():
                total += pay_nums[today][k]
            pay_nums = total
    else:
        pay_nums = 0

    if new_pay_nums:
        if st != -1:
            if st in new_pay_nums[today]:
                new_pay_nums = new_pay_nums[today][st]
            else:
                new_pay_nums = 0
        else:
            total = 0
            for k in new_pay_nums[today].keys():
                total += new_pay_nums[today][k]
            new_pay_nums = total
    else:
        new_pay_nums = 0


    if max_login_pid == {}:
        max_login_pid = 0
    # if max_login_uid == {}:
    #     max_login_uid = 0
    return (today, create_users, login_ret, online_max, online_avg, max_login_pid, 
        pay_ret, all_deals, pay_nums, new_pay_nums)

def NewCCount(alist, time_format, searchCondition):
    """ 从列表内的时间内创建内容 """
    global g_types
    for item in alist:
        today = time_to_hour(time.time(), EXT.UNIX_TIME_YMD_FORMAT)
        if item >= today:
            continue
        from_database = CCountFromDatabase(item, item+EXT.NUM_UNIX_A_DAY, time_format)
        # 创建用户数, 登录用户数
        create_users, login_ret    = from_database.get_create_user()
        # 最大在线，平均在线
        online_max, online_avg  = from_database.get_max_avg(searchCondition)
        # 充值金额， 充值笔数
        pay_ret, all_deals      = from_database.get_pay(g_types)
        # 充值人数， 新增充值人数
        pay_nums, new_pay_nums  = from_database.get_pay_nums(g_types)

        for i in g_types:
            complex_count   = CCount()
            complex_count.t = item
            complex_count.s = g.GAME_BASEUSER
            complex_count.platform = i

            if create_users and item in create_users:
                if i in create_users[item]:
                    complex_count.create = create_users[item][i]

            if login_ret and item in login_ret:
                if i in login_ret[item]:
                    complex_count.login = login_ret[item][i]

            complex_count.max_online = online_max[item]
            complex_count.avg_online = online_avg[item]

            if item in pay_ret and i in pay_ret[item]:
                complex_count.pay = pay_ret[item][i]
            else:
                complex_count.pay = 0

            if item in all_deals and i in all_deals[item]:
                complex_count.paynums = all_deals[item][i]
            else:
                complex_count.paynums = 0

            if item in pay_nums and i in pay_nums[item]:
                complex_count.payusers = pay_nums[item][i]
            else:
                complex_count.payusers = 0

            if item in new_pay_nums and i in new_pay_nums[item]:
                complex_count.newnums = new_pay_nums[item][i]
            else:
                complex_count.newnums = 0
            complex_count.save()


def ccount_all(alist):
    last_ret = []
    ret = {}
    for item in alist:
        if item.t in ret:
            deal_ccount(ret, item)
        else:
            ret[item.t] = {}
            deal_ccount(ret, item, True)
    for key in ret.keys():
        c = CCount()
        c.t = key
        if 'create' in ret[key]:
            c.create = ret[key]['create']
        if 'login' in ret[key]:
            c.login = ret[key]['login']
        if 'pay' in ret[key]:
            c.pay = ret[key]['pay']
        if 'paynums' in ret[key]:
            c.paynums = ret[key]['paynums']
        if 'payusers' in ret[key]:
            c.payusers = ret[key]['payusers']
        if 'newnums' in ret[key]:
            c.newnums = ret[key]['newnums']
        if 'max_online' in ret[key]:
            c.max_online = ret[key]['max_online']
        if 'avg_online' in ret[key]:
            c.avg_online = ret[key]['avg_online']
        last_ret.append(c)
    last_ret = sorted(last_ret, key=lambda d:d.t, reverse=True)
    return last_ret

def deal_ccount(ret, item, max_avg=False):
    attr_list = ['create', 'login', 'pay', 'paynums', 'payusers',
    'newnums']
    if max_avg:
        attr_list =attr_list + ['max_online', 'avg_online']
    for a in attr_list:
        if hasattr(item, a):
            if max_avg:
                ret[item.t][a] = getattr(item, a)
            else:
                if a in ret[item.t]:
                    ret[item.t][a] += getattr(item, a)
                else:
                    ret[item.t][a] = getattr(item, a)
