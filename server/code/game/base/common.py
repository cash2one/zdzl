#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
import random
import bisect
import math
import json
import cPickle as pickle
import time, datetime
import copy
now = datetime.datetime.now

from corelib.common import (iter_id, iter_cls_base, uuid, CustomObject, log,
    SoltObject, StateObject, PersistObject,
    RandomRegion, make_lv_regions,
    )

from .constant import ONE_DAY_TIME, ONE_DAY_DELTA

def ran_bool(rate):
    """
    爆击率等倍率开关有关的地方使用
    rate: 10%时， rate = 10, 例子：if ran_bool(10): xxx
    如：
        暴击率80%,就是百分之80的机会暴击
    """
    if rate >= 100:
        return True
    elif rate <= 0:
        return False
    ran = random.uniform(0, 100)
    return ran <= rate

def ran_region(regions, max_rate=100):
    """ 获取随机区间(列表结构),保留两位小数,从0开始 """
    if len(regions) == 0:
        return -1
    cur_num, index = 0, (len(regions) - 1)
    index = index if regions[index] > regions[0] else 0
    num = random.uniform(0, max_rate)
    for _index, region in enumerate(regions):
        cur_num += region
        if num <= cur_num:
            return _index
    return index


def ran_regions(regions):
    """ 概率运算,regions是字典, 每一个value都代表一个概率 """
    _sum = sum(regions.itervalues())
    ran_num = random.randint(0, _sum)
    for k, v in regions.iteritems():
        _sum -= v
        if ran_num >= _sum:
            return k
    return k

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

def str2dict1(s):
    """level:1|role:7|role:8|task:1|obj:1:3|equ:5 -->
    {level:[1,], role:[7,8], ...}"""
    if not s:
        return
    rs = {}
    for i in s.split('|'):
        v = i.split(':')
        rs[v[0]] = v[1:]
    return rs

def str2dict2(s):
    """ a:a1:a2:a3|b:b1:b2:b3|c:c1:c2:c3 -->
        {a:[a1,a2,a3], b:[b1,b2,b3], c:[c1,c2,c3]}
    """
    if not s:
        return
    rs = {}
    for i in s.split('|'):
        v = i.split(':')
        rs[v[0]] = v[1:]
    return rs

def str2dict3(s):
    """ a:a1:a2:a3|b:b1:b2:b3|c:c1:c2:c3 -->
        {a:[(a1,a2,a3)], b:[(b1,b2,b3)], c:[(c1,c2,c3)]}
    """
    if not s:
        return
    rs = {}
    for i in s.split('|'):
        v = i.split(':')
        d = rs.setdefault(v[0], [])
        d.append(v[1:])
    return rs

def str2list(s, vtype=int):
    """ 1|2|3|4|5
    返回: [1,2,3,4,5]
    """
    if not s:
        return
    rs = []
    rs = s.split('|')
    rs = map(vtype, rs)
    return rs



def pack_json_pb2(pb2obj, data):
    """打包成json格式pb2数据"""
    res = pb2obj.res.add()
    for k, v in data.iteritems():
        res.keys.append(k)
        try:
            if isinstance(eval(v), dict):
                res.params.append(json.dumps(eval(v)))
            else:
                res.params.append(v)
        except:
            res.params.append(v)
    return res


def field_dumps(value, protocol=0):
    if hasattr(value, 'dumps'):
        return value.dumps()
    else:
        return pickle.dumps(value, protocol)

def field_loads(data):
    if data:
        #修复win系统,由于浮点型数据异常，引起cPickle downs,loads报错
        if sys.platform == 'win32' and '-1.#IN' in data:
            data = data.replace('-1.#IND', '0')
            data = data.replace('1.#INF', '0')
        try:
            return pickle.loads(data)
        except StandardError, e:
            #对象持续化错误，可能对象属性变了或者py版本变了？
            log.exception(e)

class Pickler:
    dumps = staticmethod(field_dumps)
    loads = staticmethod(field_loads)

#######使用zlib压缩的###############
from zlib import compress, decompress
_zlib_length = 1024
def zlib_field_dumps(value, protocol=2):
    data = field_dumps(value, protocol)
    if len(data) > _zlib_length:
        return compress(data, 1)
    return data

def zlib_field_loads(data):
    try:
        data1 = decompress(data)
    except Exception:
        data1 = data
    return field_loads(data1)

class ZlibPickler:
    dumps = staticmethod(zlib_field_dumps)
    loads = staticmethod(zlib_field_loads)


def module_to_dict(md):
    """ 过滤模块内容,返回可序列化的数据对象 """
    d1 = {}
    for name in dir(md):
        if name.startswith('_'):
            continue
        value = getattr(md, name)
        if type(value) not in (bool, int, str, unicode, float, tuple, list, dict):
            continue
        d1[name] = value
    return d1




def get_face_direction(x1, x2):
    if x1 > x2:
        return FACE_LEFT
    else:
        return FACE_RIGHT


INF = 1e10000
INFS = (-INF, INF)
POS_MAX = 999999
class Position(object):
    __slots__ = ('x', 'y', 'h')
    def __init__(self, x=0, y=0, h=0):
        self.x = x
        self.y = y
        self.h = h

    def __getstate__(self):
        return dict(x=self.x, y=self.y, h=self.h)

    def __setstate__(self, adict):
        self.x = adict['x']
        self.y = adict['y']
        self.h = adict['h']

##    def _set_h(self, v):
##        self._h = v
##    def _get_h(self):
##        return self._h
##    h = property(_get_h, _set_h)

    def __str__(self):
        return '%s(x=%f, y=%f, h=%f)' % (self.__class__.__name__, self.x, self.y, self.h)

    def __repr__(self):
        name = super(Position, self).__repr__()
        return '%s(x=%f, y=%f, h=%f)' % (name, self.x, self.y, self.h)

    def __mul__(self, other):
        """ 乘算法 """
        new = self.clone()
        if isinstance(other, (int, float)) and other not in INFS:
            new.x *= other
            new.y *= other
            new.h *= other
        return new

    def __div__(self, other):
        """ 除 """
        new = self.clone()
        if isinstance(other, (int, float)) and other != 0 and other not in INFS:
            new.x /= other
            new.y /= other
            new.h /= other
        return new

    def __iter__(self):
        yield self.x
        yield self.y
        yield self.h

    def __getitem__(self, key):
        if key == 0:
            return self.x
        if key == 1:
            return self.y
        if key == 2:
            return self.h
        raise IndexError, 'key out of (0, 1, 2)'

    def clear(self):
        self.x = 0
        self.y = 0
        self.h = 0

    def assign_by(self, pos):
        if -POS_MAX < pos.x < POS_MAX:
            self.x = pos.x
        if -POS_MAX < pos.y < POS_MAX:
            self.y = pos.y
        if -POS_MAX < pos.h < POS_MAX:
            self.h = pos.h

    def assign_to(self, pos):
        if -POS_MAX < self.x < POS_MAX:
            pos.x = self.x
        if -POS_MAX < self.y < POS_MAX:
            pos.y = self.y
        if -POS_MAX < self.h < POS_MAX:
            pos.h = self.h

    def clone(self):
        pos = self.__class__(self.x, self.y, self.h)
        return pos

    def add(self, pos):
        self.x += pos.x
        self.y += pos.y
        self.h += pos.h

    def dec(self, pos):
        self.x -= pos.x
        self.y -= pos.y
        self.h -= pos.h

    def distance(self):
        """ 二维：离原点距离 """
        return abs(math.sqrt(pow(self.x, 2) + pow(self.y, 2)))

    def distance_xy(self, pos):
        """ 二维：到pos的距离 """
        return abs(math.sqrt(pow(self.x-pos.x, 2) + pow(self.y-pos.y, 2)))

    def distance_xyz(self, pos):
        """ 三维：到pos的距离 """
        return abs(math.sqrt(pow(self.x-pos.x, 2) + pow(self.y-pos.y, 2) + pow(self.h - pos.h, 2)))

    def in_distance_xy(self, pos, distance):
        """ 二维：判断是否在xy范围内 """
        return not ((abs(self.x - pos.x) > distance) or (abs(self.y - pos.y) > distance))

    def get_direct(self, pos):
        """ 获取当前点到目标点的方向值, """
        dis_x = int(pos.x) - int(self.x)
        dis_y = int(pos.y) - int(self.y)
        return get_move_direction(dis_x, dis_y)

#    def end_pos(self, distance, speed):
#        """ 根据 """
#        rate = distance / speed.distance()
#        end = Position(self.x * rate, self.y * rate, self.h)
#        return end

class Speed(Position):
    __slots__ = ('x', 'y', 'h')
    def speed_for_time(self, time):
        return Speed(self.x * time, self.y * time, self.h * time)

    def speed_by_vector(self, v_speed):
        """ 根据向量速度，设置速度和移动方向，其中z轴和xy轴处理不同；
            z轴和移动方向没关系，用正负代表方向
        """
        self.x = abs(v_speed.x)
        self.y = abs(v_speed.y)
        self.h = v_speed.h

def zero_day_time():
    """ 今天早上凌晨0点time """
    return time.mktime(now().date().timetuple())

def cur_day_hour_time(hour=0):
    """
    今日的几点时间
    """
    z_t = zero_day_time()
    return z_t + 3600*hour

def week_time(weekday, zero=1, delta=0):
    """ 根据指定的周几(week_day 1~7),返回本星期的具体时间,
    zero: 1 返回早上凌晨0点的time
    delta: 延迟周数
    """
    if zero:
        n = now().date()
    else:
        n = now()
    d = n + ONE_DAY_DELTA * ((weekday - 1 - n.weekday()) + 7 * delta)
    return time.mktime(d.timetuple())


def is_pass_day(aTime):
    """ 判断时间是否已过(超过凌晨十二点) """
    zero_time = time.mktime(now().date().timetuple())
    return aTime < zero_time

def is_pass_day_time(aTime):
    """ 判断时间是否是下一天(超过凌晨12点) """
    zero_time = time.mktime(now().date().timetuple()) + 86400
    return aTime >= zero_time

def current_time():
    """ 得到当前时间int形式 """
    return int(time.time())

def is_today(aTime):
    """判断时间是否当天"""
    now_zero = time.mktime(now().date().timetuple())
    next_zero = now_zero + 86400
    return now_zero <= aTime < next_zero

def is_yesterday(aTime):
    """判断时间是否昨天"""
    now_zero = time.mktime(now().date().timetuple())
    yt_zero = now_zero - 86400
    return yt_zero <= aTime < now_zero

def get_days(aTime):
    """ aTime距离现在相多少天 """
    format_pass_time = datetime.date.fromtimestamp(aTime)
    format_now_time = datetime.date.fromtimestamp(current_time())
    return (format_now_time - format_pass_time).days

def decode_dict(adict, ktype=None, vtype=None):
    data = copy.deepcopy(adict)
    tmp = {}
    for k,v in data.iteritems():
        tk, tv = k, v
        if ktype is not None:
            tk = ktype(k)
        if vtype is not None:
            tv = vtype(v)
        tmp[tk] = tv
    return tmp

def decode_list(alist, type=int):
    tmp = []
    for v in alist:
        tmp.append(type(v))
    return tmp

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

