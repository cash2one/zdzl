#!/usr/bin/env python
#coding=utf-8
__author__ = 'kainwu'

from models import MongoFive, FilterPlayer
import define as EXT
import time, datetime
from helps import get_format, range_list, strptime, time_to_hour
from flask import g


def hour_count(alist, query_key, time_format, return_type='list'):
    """ 对每小时进行统计 """
    ret = {}
    for item in alist:
        time_key = time_to_hour(item[query_key], time_format)
        if time_key in ret:
            ret[time_key] += 1
        else:
            ret[time_key] = 1
    if return_type == 'list':
        return sorted(ret.items(), key=lambda d:d[0])
    if return_type == 'dict':
        return ret

def accumulate_count(alist, query_key, count_key, time_format):
    """ 累加 """
    ret = {}
    for item in alist:
        time_key =  time_to_hour(item[query_key], time_format=time_format)
        if time_key in ret:
            ret[time_key] += item[EXT.STRING_PRICE]
        else:
            ret[time_key] = item[EXT.STRING_PRICE]
    return ret

class Count(object):
    """ 统计类 """
    def __init__(self, start_time, end_time, database, origin=False):
        if origin:
            self.start_time = start_time
            self.end_time   = end_time
        else:
            self.start_time = time_to_hour(start_time)
            self.end_time   = time_to_hour(end_time)
        self.db, self.collection, self.host = database

    def getRetByQuerys(self, query_key, querys_addition=None):
        """ 条件查询 """
        mongo = MongoFive(self.db, self.collection, self.host)
        querys = {query_key:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LT:self.end_time}}

        if querys_addition:
            querys.update(querys_addition)
        return mongo.filter(dic=querys, sort=query_key)

    def count(self, time_list, query_key, **kw):
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            querys = {query_key: {EXT.MONGO_GTE: item,
                      EXT.MONGO_LT: item + EXT.NUM_UNIX_A_DAY - 1}}
            if kw:
                querys.update(kw)
            ret[item] = mongo.count(dic=querys)
        return ret


    def getCount(self, query_key, time_format, return_type='list',
                querys_addition=None):
        """ 获取统计总数 """
        mongo_ret = self.getRetByQuerys(query_key, querys_addition)
        return hour_count(mongo_ret, query_key, time_format, return_type)

    def getAccumulateCount(self, query_key, count_key, time_format,
                    querys_addition=None):
        """ 获取支付统计 """
        mongo_ret = self.getRetByQuerys(query_key, querys_addition)
        return accumulate_count(mongo_ret, query_key, count_key, time_format)

    def getPlayer(self, query_key, time_list, count_key=EXT.KEY_PID, q=None):
        """ 获取充值角色数 """
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            paid_querys = {query_key:{EXT.MONGO_GTE:item, EXT.MONGO_LT:item+EXT.NUM_UNIX_A_DAY-1}}
            if q:
                paid_querys.update(q)
            paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)
            ret[item] = len(paid_ret)
        return ret

    def getNewPlayer(self, query_key, time_list, time_range=EXT.NUM_UNIX_A_DAY,
                        querys_addition=None):
        """ 获取新充值人数 """
        ret = {}
        mongo = MongoFive(self.db, self.collection, self.host)
        for item in time_list:
            paid_querys = {query_key:{EXT.MONGO_GTE:item, EXT.MONGO_LT:item+time_range-1}}
            if querys_addition:
                paid_querys.update(querys_addition)
            paid_ret = mongo.distince_filter(key=EXT.KEY_PID, querys=paid_querys)

            if not paid_ret:
                ret[item] = 0
                continue
            for p in paid_ret:
                paid_before = {query_key:{EXT.MONGO_LT:item}, EXT.KEY_PID:p}
                if querys_addition:
                    paid_before.update(querys_addition)
                paid_before_ret = mongo.first(dic=paid_before)
                if not paid_before_ret:
                    if item in ret:
                        ret[item] += 1
                    else:
                        ret[item] = 1
        return ret

    def getLogin(self, query_key, time_format, querys_addition=None):
        """ log_info登陆记录 """
        D_U = 'd.u'
        e_name = FilterPlayer.get_pids()
        e_list = FilterPlayer.get_uids()
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
            if day in uids and p[EXT.KEY_D][EXT.KEY_U] in uids[day]:
                continue
            if day in ret:
                ret[day] += 1
            else:
                ret[day] = 1
            if day in uids:
                uids[day].append(p[EXT.KEY_D][EXT.KEY_U])
            else:
                uids[day] = [p[EXT.KEY_D][EXT.KEY_U]]
        return ret

    def getLogin_player(self, query_key, time_format, querys_addition=None):
        """ log_info登陆记录 """
        D_U = 'd.u'
        e_name = FilterPlayer.get_pids()
        e_list = FilterPlayer.get_uids()
        mongo_log = MongoFive(self.db, self.collection, self.host)
        querys  = {query_key:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LTE:self.end_time}}
        if querys_addition:
            querys.update(querys_addition)
        # 获取登录角色
        uids = {}
        ret = {}
        players = mongo_log.filter(querys)
        for p in players:
            day = time_to_hour(p[query_key], time_format)
            if day in ret:
                ret[day] += 1
            else:
                ret[day] = 1
        return ret

class CoinCount(object):
    """ 玩家资金统计 """
    def __init__(self, coin, start_time, end_time, querys_addition=None):
        self.start_time         = start_time
        self.end_time           = end_time
        self.coin               = coin
        self.querys_addition    = querys_addition

    def getRet(self, p_count=True, time_format=EXT.UNIX_TIME_YMD_FORMAT):
        ret = {}
        STR_C1, STR_C2, STR_C3, STR_P = 'c1', 'c2', 'c3', 'p'
        querys = {EXT.KEY_CT:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LTE:self.end_time}}
        if self.querys_addition:
            querys.update(self.querys_addition)
        mongo_ret = self.coin.filter(dic=querys, sort=EXT.KEY_CT)
        i = 0
        tmp_pid = {}
        for item in mongo_ret:
            time_key =  time_to_hour(item[EXT.KEY_CT], time_format=time_format)
            if time_key in ret:
                if STR_C1 in item:
                    ret[time_key][STR_C1] += item[STR_C1]
                if STR_C2 in item:
                    ret[time_key][STR_C2] += item[STR_C2]
                if STR_C3 in item:
                    ret[time_key][STR_C3] += item[STR_C3]
            else:
                tmp_c1=0
                tmp_c2=0
                tmp_c3=0
                if STR_C1 in item:
                    tmp_c1 = item[STR_C1]
                if STR_C2 in item:
                    tmp_c2 = item[STR_C2]
                if STR_C3 in item:
                    tmp_c3 = item[STR_C3]

                ret[time_key] = {STR_C1:tmp_c1, STR_C2:tmp_c2,
                            STR_C3:tmp_c3,STR_P:0}
        if p_count:
            for k,v in ret.iteritems():
                condition = {EXT.KEY_CT:{EXT.MONGO_GTE:k,EXT.MONGO_LT:k+EXT.NUM_UNIX_A_DAY-1}}
                ret[k][STR_P] = len(self.coin.distince_filter(EXT.KEY_P, condition))
        return sorted(ret.items(), key=lambda d:d[0])

class OnlineCount(object):
    """ 登录统计 """
    def __init__(self, start_time, end_time, database, searchCondition):
        super(OnlineCount, self).__init__()
        self.start_time = time_to_hour(start_time)
        self.end_time   = time_to_hour(end_time)
        self.mongo = MongoFive(database[0], database[1], database[2])
        self.searchCondition = searchCondition

    def query(self, query_key, querys_addition=None):
        querys = {query_key:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LT:self.end_time}}
        if querys_addition:
            querys.update(querys_addition)
        return self.mongo.filter(dic=querys, sort=query_key)

    def hour_max_min(self, query_key, count_key, querys_addition=None):
        s_ret = self.query(query_key, querys_addition)
        time_format = get_format("hour")
        ret = {}
        avg = {}
        for item in s_ret:
            hour = time_to_hour(item[query_key], time_format=time_format)
            if hour in ret:
                if ret[hour][EXT.STRING_MAX] < item[count_key]:
                    ret[hour][EXT.STRING_MAX] = item[count_key]
                if ret[hour][EXT.STRING_MIN] > item[count_key]:
                    ret[hour][EXT.STRING_MIN] = item[count_key]
            else:
                ret[hour] = {}
                ret[hour][EXT.STRING_MAX] = ret[hour][EXT.STRING_MIN] = item[count_key]
            if hour in avg:
                avg[hour].append(item[count_key])
            else:
                avg[hour] = [item[count_key]]
        for k in ret.keys():
            tmp = 0
            i = 0
            for a in avg[k]:
                tmp += a
                i += 1
            ret[k].update({"avg":tmp/i})
        return ret

    def analysis(self, adict, time_format, nums):
        STRING_AVG = 'avg'
        ret = {}
        avg = {}
        for k in adict.keys():
            day = time_to_hour(k, time_format=time_format)
            if day in ret:
                if ret[day][EXT.STRING_MAX] < adict[k][EXT.STRING_MAX]:
                    ret[day][EXT.STRING_MAX] = adict[k][EXT.STRING_MAX]
                if ret[day][EXT.STRING_MIN] > adict[k][EXT.STRING_MIN]:
                    ret[day][EXT.STRING_MIN] = adict[k][EXT.STRING_MIN]
            else:
                ret[day] = {}
                if k in adict:
                    ret[day][EXT.STRING_MAX] = adict[k][EXT.STRING_MAX]
                else:
                    ret[day][EXT.STRING_MAX] = 0
                if k in adict:
                    ret[day][EXT.STRING_MIN] = adict[k][EXT.STRING_MIN]
                else:
                    ret[day][EXT.STRING_MIN] = 0
            if day in avg:
                avg[day].append(adict[k][EXT.STRING_MAX])
            else:
                if k in adict:
                    avg[day] = [adict[k][EXT.STRING_MAX]]
                else:
                    avg[day] = [0]
        for k in ret.keys():
            tmp = 0
            i = 0
            for a in avg[k]:
                tmp += a
                i += 1
            ret[k].update({"avg":tmp/i})
        return ret


    def day(self, query_key, count_key, querys_addition=None):
        STRING_AVG = 'avg'
        time_format = get_format("day")
        hour_ret = self.hour_max_min(query_key, count_key, querys_addition)
        ret = self.analysis(hour_ret, time_format, 24)
        return ret

    def month(self, query_key, count_key, querys_addition=None):
        time_format = get_format("month")
        month_ret = self.day(query_key, count_key, querys_addition)
        ret = self.analysis(month_ret, time_format, 30)
        return ret

    def year(self, query_key, count_key, querys_addition=None):
        time_format = get_format("year")
        year_ret = self.month(query_key, count_key, querys_addition)
        ret = self.analysis(year_ret, time_format, 12)
        return ret

    def get_ret(self, query_key, count_key, querys_addition=None):
        # return self.hour_max_min(query_key, count_key, querys_addition)
        if self.searchCondition == 'year':
            ret = self.year(query_key, count_key, querys_addition)
        if self.searchCondition == 'month':
            ret = self.month(query_key, count_key, querys_addition)
        if self.searchCondition == 'day':
            ret = self.day(query_key, count_key, querys_addition)
        if self.searchCondition == 'hour':
            ret = self.hour_max_min(query_key, count_key, querys_addition)
        return sorted(ret.items(), key=lambda d:d[0])

class LoginCount(object):
    """ 登录统计 """
    def __init__(self, start_time, end_time):
        self.start_time = start_time
        self.end_time   = end_time
        self.mongo = MongoFive(g.GAME_LOG, EXT.LOG_INFO, g.mongo_host)

    def get_ret(self):
        D_U = 'd.u'
        query = {EXT.KEY_CT:{EXT.MONGO_GTE:self.start_time, EXT.MONGO_LTE:self.end_time},
                    EXT.KEY_T:{EXT.MONGO_IN:[1,2]}}
        pid_ret = self.mongo.distince_filter(EXT.KEY_P, query)
        uid_ret = self.mongo.distince_filter(D_U, query)
        max_pid_ret = len(pid_ret)
        max_uid_ret = len(uid_ret)
        return max_pid_ret, max_uid_ret

def count_coin(r, alist):
    """ 通过mongo group统计出的资金sumc1, sumc2, sumc3总计 """
    if EXT.COIN_SUMC1 in alist:
        alist[EXT.COIN_SUMC1] += int(r[EXT.COIN_SUMC1])
    else:
        alist[EXT.COIN_SUMC1] = int(r[EXT.COIN_SUMC1])
    if EXT.COIN_SUMC2 in alist:
        alist[EXT.COIN_SUMC2] += int(r[EXT.COIN_SUMC2])
    else:
        alist[EXT.COIN_SUMC2] = int(r[EXT.COIN_SUMC2])
    if EXT.COIN_SUMC3 in alist:
        alist[EXT.COIN_SUMC3] += int(r[EXT.COIN_SUMC3])
    else:
        alist[EXT.COIN_SUMC3] = int(r[EXT.COIN_SUMC3])

def mongo_group(mongo, key, condition):
    """ mongo group统计 """
    from bson.code import Code
    key = {key: True}
    initial = {"countstar": 0}
    red = Code("function(obj,prev){prev.countstar++;}")
    return mongo.group(key, condition, initial, red)

def group2dict(group, key=None):
    """ group出来的结果list转为dict """
    STR_LEVEL, STR_COUNTSTAR = 'level', 'countstar'
    ret = {}
    if key == 'level':
        for g in group:
            if int(g[STR_LEVEL]) > 17:
                if 18 in ret:
                    ret[18] += int(g[STR_COUNTSTAR])
                else:
                    ret[18] = int(g[STR_COUNTSTAR])
            else:
                ret[int(g[STR_LEVEL])] = int(g[STR_COUNTSTAR])
    else:
        [ret.update({int(item[key]):int(item[STR_COUNTSTAR])}) for item in group]
    return ret