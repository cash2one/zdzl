#coding=utf-8
import hashlib
from flask import render_template, current_app,url_for, redirect
import traceback, os
from grpc import RpcClient, get_proxy_by_addr, get_rpc_by_addr
from corelib import log
import time, datetime
from define import MONGO_GT, MONGO_LT, MONGO_GTE, MONGO_LTE, UNIX_TIME_YMD_FORMAT,\
    UNIX_TIME_Y_FORMAT, UNIX_TIME_YM_FORMAT, UNIX_TIME_YMDH_FORMAT, \
    DATE_HOUR,DATE_YEAR,DATE_MONTH, DATE_DAY

def print_traceback():
    import traceback
    print traceback.format_exc()
    
def format_date(date,s='%Y-%m-%d %H:%M'):
    """ 针对timestamp转换日期格式 """
    from datetime import datetime
    try:
        date = datetime.fromtimestamp(date)
        return date.strftime(s)
    except:
        return ''

def get_format(searchCondition):
    """ 根据条件返回时间转换的格式 """
    if searchCondition == DATE_HOUR:
        return UNIX_TIME_YMDH_FORMAT
    if searchCondition == DATE_DAY:
        return UNIX_TIME_YMD_FORMAT
    if searchCondition == DATE_MONTH:
        return UNIX_TIME_YM_FORMAT
    if searchCondition == DATE_YEAR:
        return UNIX_TIME_Y_FORMAT

def allowed_file(filename):
    """ 允许上传的文件格式 """
    return '.' in filename and filename.rsplit('.', 1)[1] in ['xls', 'xlsx']

def pop_id(alist):
    """ 更发列表里的字符"_id"为"id" """
    tmp = []
    for item in alist:
        item['id'] = item.pop('_id')
        tmp.append(item)
    return tmp
        
def xlsupload(xlsfile, admin, xls2mongo=None, mongo=None, 
    coll=None, save_mongo=True, database_addr=None):
    """ xls上传至mongodb """
    from werkzeug import secure_filename
    xlsPath = os.path.dirname(admin.root_path)+'/static/xlsdatabase/'
    if xlsfile and allowed_file(xlsfile.filename):
        filename = secure_filename(xlsfile.filename)
        xlsfile.save(os.path.join(xlsPath, filename))
        last_path = ''.join([xlsPath ,filename])
        if not save_mongo:
            # from luffy.models import mac2count
            # mac2count(last_path, database_addr)
            # os.remove(last_path)
            return last_path
        try:
            xls2mongo(last_path, mongo, coll)
        except:
            print_traceback()
            return False
        finally:
            os.remove(last_path)
        return True

def build_url(app,action,filename,_external = False):
    """ 生成图片或者JS等静态文件路径 """
    return url_for(action,filename = filename,_external = _external)

def md5(value):
    """ 转换字符为MD5码 """
    return hashlib.md5(value).hexdigest()

def range_list(start, end, step):
    """ 给定开始与结束，根据step生成list """
    ret = []
    while start <= end:
        ret.append(start)
        start += step
    return ret

def check_dict_item(adict, item, default=0):
    """ 测试字典内是否存在item这个key，没有则返回default """
    if item in adict:
        return adict[item]
    else:
        return default

def time_range(val):
    """ Unix时间截转换时长 """
    val = int(val)
    hour = 0
    min = 0
    sec = 0
    tmp = val / 3600
    if tmp >= 1:
        hour = tmp
    tmp = val % 3600
    if tmp != 0:
        tmp_min = tmp/60
        if tmp_min >=1:
            min = tmp_min
        sec = tmp%60
    return u''.join([str(hour), u'时', str(min), u'分', str(sec), u'秒'])

def strptime(time_str, time_format=UNIX_TIME_YMD_FORMAT):
    """ 2013-02-25格式转为时间截 """
    return  time.mktime(time.strptime(time_str, time_format))

def time_to_hour(atime, time_format=UNIX_TIME_YMDH_FORMAT):
    """ 时间截转为至小时，日期，年份的时间截 """
    date = datetime.datetime.fromtimestamp(atime)
    return strptime(date.strftime(time_format), time_format=time_format)

def grpc_get_proxy(serverid):
    """ 获取服务器端gprc """
    from luffy.define import LOCAL_HOST_IP
    from luffy.models import Servers
    from grpc import get_proxy_by_addr
    GRPC_PORT = '8001'
    GRPC_CLIENT = 'rpc_client'
    log.info('grpc_get_proxy(%s)', serverid)
    mongo_host = Servers.query.get(serverid)
    if mongo_host:
        gport = mongo_host.gport
    else:
        ip = LOCAL_HOST_IP
        gport = ':'.join([LOCAL_HOST_IP, GRPC_PORT])
#            gport = '127.0.0.1:8001'
    log.info('grpc_get_proxy:gport:%s', gport)
    grpc_server = GRPC_CLIENT
    gport = gport.split(':')
    addr = (gport[0], int(gport[1]))
    return get_proxy_by_addr(addr, grpc_server)
