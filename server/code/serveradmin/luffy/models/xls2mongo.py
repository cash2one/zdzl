#coding=utf-8
import xlrd
import os
from luffy.models import MongoFive
from luffy.helps import time_range, format_date
from luffy import define as EXT
import pyExcelerator
from flask import g

def xls2mongo(source, database, coll=None):
    change_type = { 'str':str, 'int':int, 'float':float}
    xl = xlrd.open_workbook(source)
    for s in xrange(len(xl.sheets())):
        lastRet = {}
        sheet = xl.sheet_by_index(s)
        type_tmp = []
        key_tmp = []

        for row in xrange(sheet.nrows):
            tmp = []
            ret = {}
            get_tmp(sheet, row, tmp, type_tmp, key_tmp)
            if row >4:
                write_ret(tmp, key_tmp, type_tmp, change_type, ret)
                check_plus(coll, lastRet, ret)
                if ret.has_key('id'):
                    args = {}
                    id = ret.pop('id')
                    args['condition'] = { '_id':id }
                    args['data'] = { '$set':ret }
                    database.update(args,upsert=True)
                else:
                    database.insert(ret)

def get_tmp(sheet, row, tmp, type_tmp, key_tmp):
    """ 获取类型，key，内容 """
    for col in xrange(sheet.ncols):
        if col != 0:
            value = sheet.cell_value(row, col)
            try:
                value = sheet.cell_value(row, col).encode('utf-8')
            except Exception:
                pass
            if row == 3:
                type_tmp.append(value)
            if row == 4:
                key_tmp.append(value)
            elif row >4:
                tmp.append(value)

def write_ret(tmp, key_tmp, type_tmp, change_type, ret):
    #记录类型
    type_tmp = [item for item in type_tmp if item != '']
    #存入数据库中的key
    key_tmp = [item for item in key_tmp if item != '']
    if len(type_tmp) == len(key_tmp):
        for i in xrange(len(key_tmp)):
            if type_tmp[i] != 'str':
                if tmp[i] == '':tmp[i]='0'
            if type_tmp[i] == 'intstr':
                try:
                    ret[key_tmp[i]] = int(tmp[i])
                except:
                    ret[key_tmp[i]] = str(tmp[i])
            else:
                ret[key_tmp[i]] = change_type[type_tmp[i]](tmp[i])

def check_plus(coll, lastRet, ret):
    if coll == 'roleup':
        check_plus_roleup(lastRet, ret)
        return
    if coll is not None:
        dontCheck = ['id', 'aid', 'level', 'fid','_id', 'gid','exp']
        collKey = { 'arm_level':'aid', 'fate_level':'fid', 'gem_level':'gid' }
        if coll == 'arm_level':
            flevel = 0
        else:
            flevel = 1
        lastRet[(ret[collKey[coll]],ret['level'])] = ret
        # dontCheck = ['id', 'aid', 'level', 'fid','_id','exp', 'gid']
        if ret['level'] != flevel:
            for k in ret.keys():
                if k not in dontCheck:
                    lastRet[(ret[collKey[coll]],ret['level'])][k] = lastRet[(ret[collKey[coll]],ret['level']-1)][k] + ret[k]
                    ret[k] = lastRet[(ret[collKey[coll]],ret['level'])][k]

def check_plus_roleup(lastRet, ret):
    """ 武将升段统计 """
    type = ret['type']
    n_attr = str2dict(ret['attr'])
    o_attr = lastRet.get('attr')
    if o_attr and type == lastRet['type']:
        for attr, value in o_attr.iteritems():
            if attr in n_attr:
                n_attr[attr] += o_attr[attr]
            else:
                n_attr[attr] = value
    lastRet['attr'] = n_attr
    lastRet['type'] = type
    ret['attr'] = n_attr


def str2dict(s, ktype=str, vtype=int):
    """ k:v|k1:v|...
    返回: {k:v, k1:v, ... }
    """
    s = s.strip()
    if not s:
        return
    rs = dict(map(lambda kv: (ktype(kv[0]), vtype(kv[1])),
        map(lambda i: i.strip().split(':'), s.split('|'))))
    return rs

#=======================================================
#兑换码写入数据库
#=======================================================
def code2mongo(source, database, coll=None):
    """ 兑换码写入数据库 """
    xl = xlrd.open_workbook(source)
    for s in xrange(len(xl.sheets())):
        sheet = xl.sheet_by_index(s)
        for row in xrange(sheet.nrows):
            code2mongo_insert(sheet, row, database)

def code2mongo_insert(sheet, row, database):
    if row>0:
        name = sheet.cell_value(row, 0)
        code = sheet.cell_value(row, 1)
        one = sheet.cell_value(row, 2)
        et = sheet.cell_value(row, 3)
        rid = sheet.cell_value(row, 4)
        ct = sheet.cell_value(row, 5)
        num = sheet.cell_value(row, 6)
        try:
            name = sheet.cell_value(row, 0).encode('utf-8')
            code = sheet.cell_value(row, 1).encode('utf-8')
            one = sheet.cell_value(row, 2).encode('utf-8')
            et = sheet.cell_value(row, 3).encode('utf-8')
            rid = sheet.cell_value(row, 4).encode('utf-8')
            ct = sheet.cell_value(row, 5).encode('utf-8')
            num = sheet.cell_value(row, 6).encode('utf-8')
        except Exception:
           import traceback
           print traceback.format_exc()
        ret = {'name':str(name), 'code':str(code), 'one':int(float(one)),
               'et':int(float(et)), 'rid':int(float(rid)), 'ct':int(float(ct)),
               'num':int(float(num))}
        database.insert(ret)
#=======================================================
#兑换码写入数据库-结束
#=======================================================

#=======================================================
#以下为运营用MAC地址统计
#=======================================================
def mac2count(file_path, database_addr):
    """ mac地址统计 """
    xl = xlrd.open_workbook(file_path)
    mac_list = []
    for s in xrange(len(xl.sheets())):
        sheet = xl.sheet_by_index(s)
        mac_list, start_time, end_time = get_sheet(sheet)
    # 用户表
    mongo_user      = MongoFive(database_addr[0], EXT.BASEUSER_USER, host=database_addr[1])
    user_querys     = {EXT.KEY_MAC:{EXT.MONGO_IN:mac_list}}
    user_list       = mongo_user.distince_filter(EXT.KEY_MONGO_ID, user_querys)
    # 需要写入的excel表
    file_path = '/'.join(file_path.split("/")[:-1])
    file_path = ''.join([file_path,"/mac"])
    if not os.path.isdir(file_path):
        os.mkdir(file_path)
    w=pyExcelerator.Workbook()
    ws = w.add_sheet("sheet1")
    ws.write(0, 0, u'uid')
    ws.write(0, 1, u'角色id')
    ws.write(0, 2, u'角色名')
    ws.write(0, 3, u'等级')
    ws.write(0, 4, u'VIP')
    ws.write(0, 5, u'登录次数')
    ws.write(0, 6, u'登录详细')
    # 通用uid查找出player信息
    player_info(user_list, database_addr, start_time, end_time, ws, w, file_path)


def player_info(user_list, database_addr, start_time, end_time, ws, w, file_path):
    """ MAC统计角色详细信息 """
    i = 1
    for u in user_list:
        mongo_player    = MongoFive(database_addr[0], EXT.BASEUSER_PLAYER, host=database_addr[1])
        player_querys   = {EXT.KEY_UID:u}
        player_list     = mongo_player.find(player_querys)
        # player_info(player_list, database_addr, u, start_time, end_time, ws)
        for item in player_list:
            #print 'item[EXT.KEY_NAME]', item[EXT.KEY_NAME], type(item[EXT.KEY_NAME])
            # UID
            name = item[EXT.KEY_NAME].encode("gbk", errors='ignore').decode("gbk")
            ws.write(i, 0, u)
            # 角色ID
            ws.write(i, 1, item[EXT.KEY_MONGO_ID])
            # 角色名
            ws.write(i, 2, name)#.encode("utf8", errors='ignore'))
            # 等级
            ws.write(i, 3, item[EXT.KEY_LEVEL])
            # VIP
            ws.write(i, 4, item[EXT.KEY_VIP])
            # 登录详细
            mongo_log = MongoFive(database_addr[2], EXT.LOG_INFO, host=database_addr[1])
            logins = login_times(mongo_log, item[EXT.KEY_MONGO_ID], start_time, end_time)
            ws.write(i, 5, len(logins))
            ws.write(i, 6, list2text(logins))
            i += 1
    file_name = ''.join([start_time, '~', end_time, '.xls'])
    w.save("/".join([file_path, file_name]))



def list2text(alist):
    """ list合并为text,加换行 """
    STRING_LOGIN, STRING_LOGOUT, STRING_RANGE = 'login', 'logout', 'range'
    ret = []
    for item in alist:
        if STRING_LOGIN in item:
            ret.append("%s:%s"%(STRING_LOGIN,item[STRING_LOGIN]))
        if STRING_LOGOUT in item:
            ret.append("%s:%s"%(STRING_LOGOUT,item[STRING_LOGOUT]))
        if STRING_RANGE in item:
            ret.append("%s:%s"%(STRING_RANGE,item[STRING_RANGE]))
    return '\n'.join(ret)

def login_times(mongo, pid, start_time_str, end_time_str):
    """ 登录时长 """
    from luffy.views import FiveMethods
    ret = []
    TIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    STRING_LOGIN, STRING_LOGOUT, STRING_TID, STRING_RANGE = 'login', 'logout', 'tid', 'range'
    start_time_str, end_time_str, start_time, end_time = FiveMethods.dealTime(
    start_time_str, end_time_str, searchCondition=EXT.DATE_DAY)
    # 查询数据库
    log_querys = {EXT.KEY_P:pid, EXT.KEY_T:{EXT.MONGO_IN:[1,2]},
                    EXT.KEY_CT:{EXT.MONGO_GTE:start_time, EXT.MONGO_LT:end_time}}
    log_ret = mongo.filter(dic=log_querys, sort=EXT.KEY_CT)
    tmp = {}
    while len(log_ret) >= 2:
        login = log_ret.pop(0)
        tmp[STRING_LOGIN] = login[EXT.KEY_CT]
        logout = log_ret.pop(0)
        tmp[STRING_LOGOUT] = logout[EXT.KEY_CT]
        if STRING_LOGIN in tmp and STRING_LOGOUT in tmp:
            ret.append({
                STRING_LOGIN:format_date(tmp[STRING_LOGIN], TIME_FORMAT),
                STRING_LOGOUT:format_date(tmp[STRING_LOGOUT], TIME_FORMAT),
                STRING_RANGE:time_range(tmp[STRING_LOGOUT]-tmp[STRING_LOGIN])
                })
            tmp = {}
    return ret

def get_sheet(sheet):
    """ 从sheet中取出数据 """
    ret = []
    start_time = None
    end_time = None
    for row in xrange(sheet.nrows):
        if row == 0:
            start_time = sheet.cell_value(row, 0)
            end_time = sheet.cell_value(row, 1)
        elif row == 1:
            continue
        else:
            value = sheet.cell_value(row, 0)
            ret.append(value)
    return ret, start_time.split(":")[1], end_time.split(":")[1]

def create_ws(*args):
    w = pyExcelerator.Workbook()
    ws = w.add_sheet("sheet1")
    for i in xrange(len(args)):
        ws.write(0, i, args[i])
    return w, ws

def get_pay_log(path, start_time, end_time, q=None):
    """ 充值纪录 """
    from webapi import SNS_MAP
    TIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    titles = [u'充值日期', u'订单编号', u'服务器', u'订单RMB', u'订单元宝', u'游戏角色ID',
                u'游戏角色名', u'游戏等级', u'交易序列号', u'渠道标示', u'渠道类型', u'是否成功']
    servers = {1:u'',2:u'', 3:u'', 4:u'', 5:''}
    querys = {EXT.KEY_CT:{EXT.MONGO_GT:start_time, EXT.MONGO_LT:end_time}}
    if q:
        querys.update(q)
    pays = g.mongo_drive.all(g.GAMEBASE, EXT.COLL_PAY_LOG, querys=querys)
    w, ws = create_ws(*titles)
    j = 1
    for p in pays:
        ws.write(j, 0, format_date(p[EXT.KEY_CT], TIME_FORMAT))
        ws.write(j, 1, p[EXT.PAY_PORDER])
        ws.write(j, 2, p[EXT.PAY_SID])
        ws.write(j, 3, p[EXT.STRING_PRICE])
        if EXT.STRING_COIN in p:
            ws.write(j, 4, p[EXT.STRING_COIN])
        ws.write(j, 5, p[EXT.KEY_PID])
        player = get_player_by_pid(p[EXT.KEY_PID])
        if player:
            ws.write(j, 6, player[EXT.KEY_NAME].encode("gbk", errors='ignore').decode("gbk"))
            ws.write(j, 7, player[EXT.KEY_LEVEL])
        if EXT.PAY_TORDER in p:
            ws.write(j, 8, p[EXT.PAY_TORDER])
        if EXT.STRING_DATA in p:
            ws.write(j, 9, str(p[EXT.STRING_DATA]))
        if p[EXT.KEY_T] in SNS_MAP:
            t = SNS_MAP[p[EXT.KEY_T]]
        else:
            t = p[EXT.KEY_T]
        ws.write(j, 10, t)
        if 'status' in p:
            ws.write(j, 11, p['status'])
        j += 1
    w.save(path)

def get_player_by_pid(pid):
    querys = {EXT.KEY_MONGO_ID:pid}
    player = g.mongo_drive.find_one(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, querys)
    return player

