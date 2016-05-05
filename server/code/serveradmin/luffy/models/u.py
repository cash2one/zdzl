#coding=utf-8
from flask.ext.mongoengine import MongoEngine
from flask.ext.mongoengine.wtf import model_form
from wtforms.widgets import HiddenInput
from werkzeug import cached_property
from bson.objectid import ObjectId
from mongoalchemy.document import Index
from flask.ext.mongoalchemy import BaseQuery
# from flask.ext.principal import RoleNeed, UserNeed
from tprincipal import RoleNeed, UserNeed
from luffy.extensions import db
import config as game_config
from time import time
from luffy.helps import md5

mdb = MongoEngine()
web_db_alias = game_config.BaseConfig().MONGODB_SETTINGS['DB']

class UserQuery(BaseQuery):
    def from_identity(self, identity):
        """
        根据用户的当前标识获取用户信息，并提供验证信息
        """
        try:
            user = self.get_or_404(identity.name)
        except:
            user = None

        if user:
            identity.provides.update(user.provides)
            #user.token
        return user

    def fromid(self,id):
        return self.get_or_404(ObjectId(id))

    def valid(self, login, password):
        u = self.filter(AdminUser.username==login).first()
        if u is not None:
            authenticated = u.check_password(password)
        else:
            authenticated = False
        return u, authenticated

    def authenticate(self, login, password):
        return self.valid(login, password)

class AdminUser(db.Document):
    # 角色，待激活会员
    UNACTIVE = 1
    # 角色，普通会员
    MEMBER = 100
    # 角色，网站编辑
    MODERATOR = 200
    # 角色, 测试帐号
    TEST = 210
    # 角色, 客服帐号
    CUSTOMER = 220
    # 角色，管理员
    ADMIN = 300
    # other
    OTHER = 400

    query_class = UserQuery

    username_index = Index().ascending('u').unique(drop_dups = True)

    # 登录帐号
    username = db.StringField(db_field='u',required=True,allow_none=False)
    # 密码
    _pwd = db.StringField(db_field='p',required=True,allow_none=False)
    # 昵称
    nickname = db.StringField(db_field='n',required=False,allow_none=True,default = None)
    # 注册时间
    regdate = db.FloatField(db_field='g',required=False,allow_none=True,default = time())
    # 最后一次登录时间
    lastlogin = db.FloatField(db_field='l',required=False,allow_none=True,default = time())
    # 是否已经禁用
    ban = db.BoolField(db_field='b',required=False,default = False)
    # 角色
    role = db.IntField(db_field='r',required=False,default = MODERATOR)
    # 权限, index = 0:基础数据查看，1：基础数据修改，2:用户数据查看
    # 3:用户数据修发, 4:服务器备份恢复, 5:GM管理，6:角色查询, 7:数据统计
    right = db.ListField(db.IntField(),db_field='i', required=False, default=[0,0,0,0,0,0,0,0,0])
    # 经验值
    value = db.IntField(db_field='v',required=False,default = 0)
    # 性别  0:男，1：女
    sex = db.IntField(db_field='s',required=False,default = 0)
    # default server
    server = db.ObjectIdField(db_field='sr', required=False, allow_none=True, default=None)
    # 服务器组
    server_group = db.StringField(db_field='sg',required=True,allow_none=False, default="td_res")


    def __init__(self, *args, **kwargs):
        super(AdminUser, self).__init__(*args, **kwargs)

    def new_login(self):
        """ 注意，此方法会自动保存用户数据 """
        self.lastlogin = time()
        self.value += 1
        self.save()

    @cached_property
    def message(self):
        """ 用户信息辅助类 """
        return str(self.mongo_id)

    def new_msg(self,msg,*nickname):
        """ 新信息，可以批量指定用户昵称 """
        for n in nickname:
            u = AdminUser.query.filter(AdminUser.nickname == n).first()
            if u.mongo_id != self.mongo_id:
                self.message.new(u.mongo_id, msg)
        return True

    @cached_property
    def role_name(self):
        if self.role == self.UNACTIVE:
            return u'待激活'
        elif self.role == self.MEMBER:
            return u'普通会员'
        elif self.role == self.MODERATOR:
            return u'编辑'
        elif self.role == self.ADMIN:
            return u'管理员'
        elif self.role == self.OTHER:
            return u'other'
        else:
            return u'未知'
    @cached_property
    def ban_cn(self):
        if self.ban : return u'是'
        else: return u'否'


    @property
    def password(self):
        return self._pwd

    @password.setter
    def password(self, value):
        self._pwd = md5(value)

    @property
    def is_moderator(self):
        """ 是否网站编辑 """
        return self.role >= self.MODERATOR

    @property
    def is_admin(self):
        """ 是否管理员 """
        return self.role >= self.ADMIN

    @property
    def is_other(self):
        """ """
        return self.role>=self.OTHER

    @cached_property
    def provides(self):
        """ 用于登录验证提供 """
        needs = [RoleNeed('authenticated'),
                 UserNeed(self.mongo_id)]
        if self.is_moderator:
            needs.append(RoleNeed('moderator'))
        if self.is_admin:
            needs.append(RoleNeed('admin'))
        if self.is_other:
            needs.append(RoleNeed('other'))
        return needs

    @cached_property
    def usex(self):
        """ 用户的性别-中文显示 """
        if self.sex == 0:
            return u'男'
        else:
            return u'女'


    def check_password(self,password):
        '检查密码是否一致'
        if self.password is None:
            return False
        return self.password == md5(password)

class Servers(db.Document):
    """ 服务器列表 """
    # 名
    name = db.StringField(db_field='n', required=False,allow_none=True)
    # ip
    ip = db.StringField(db_field='i', required=False,allow_none=True)
    # 端口
    port = db.IntField(db_field='p',required=False,allow_none=True)
    # 用户名
    username = db.StringField(db_field='u',required=False,allow_none=True)
    # 密码
    _pwd = db.StringField(db_field='w',required=False,allow_none=True)
    # GRPC端口
    gport = db.StringField(db_field='g', required=True, default='127.0.0.1:8001')
    # 类型, 1
    t = db.IntField(db_field='t', required=True, default=1)
    # 简繁体
    tf = db.StringField(db_field='tf', required=True, default='zh-CN')
    # 资源库
    db_res = db.StringField(db_field='r', required=False,allow_none=True, default='td_res')
    # 用户库
    db_user = db.StringField(db_field='s', required=False,allow_none=True, default='td')
    # 日志库
    db_log = db.StringField(db_field='l', required=False,allow_none=True, default='td_log')
    # sid
    sid = db.StringField(db_field='sid', required=False, default='')
    # 服务器
    st = db.StringField(db_field='st', default='td_count')
    # res path
    res = db.StringField(db_field='res', default='')

    @property
    def password(self):
        return self._pwd

    @password.setter
    def password(self, value):
        self._pwd = value

class Mongos(db.Document):
    #服务器IP
    ip = db.StringField(db_field='i', required=True, allow_none=False, default='127.0.0.1')
    #端口
    port = db.IntField(db_field='p', required=True, allow_none=False, default=27017)
    #本地库名
    localdatabase = db.StringField(db_field='l', required=False, allow_none=True)
    #服务器库名
    database = db.StringField(db_field='d', required=False, allow_none=True)
    #(mtype=1时记录需要备份的collections, mtype=2 时记录需要恢复的collections)
    backup = db.StringField(db_field='c', required=False, allow_none=True)
    #用户名
    username = db.StringField(db_field='u', required=False, allow_none=True, default=None)
    #密码
    password = db.StringField(db_field='w', required=False, allow_none=True, default=None)
    #备注
    remark  = db.StringField(db_field='r', required=False, allow_none=True)
    # 服务器
    st = db.StringField(db_field='st', default='zl')
    #is drop
    is_drop = db.IntField(db_field='dr', default=1)

    _tables = db.ObjectIdField(db_field='o', allow_none=True)

    @property
    def tables(self):
        tables = SyncTables.query.get_or_404(ObjectId(self._tables))
        return tables.title

    @property
    def tables_oid(self):
        return self._tables

    @tables.setter
    def tables(self, value):
        self._tables = ObjectId(value)

    @property
    def table_names(self):
        tables = SyncTables.query.get_or_404(ObjectId(self._tables))
        return tables.names

class SyncTables(db.Document):
    title = db.StringField(db_field='t')
    names = db.StringField(db_field='n')
    remark = db.StringField(db_field='r')


class UserLog(db.Document):
    """ 用户登录，GM LOG """
    # 用户帐号
    u = db.StringField(db_field='u')
    # 类型：1=登录, 2=GM操作
    ty = db.IntField(db_field='ty')
    # 详细
    i = db.StringField(db_field='i', required=False, allow_none=True)
    # 时间
    t = db.FloatField(db_field='t')
    # 服务器id
    st = db.StringField(db_field='st', default='zl')

class FilterPlayer(db.Document):
    """ 过滤名单 """
    # 名单
    n = db.StringField(db_field='n')
    # 类型：1=pid, 2=uid
    t = db.IntField(db_field='t')

    @classmethod
    def get_uids(cls):
        tmp = cls.query.filter(cls.t==2)
        return [item.n for item in tmp]

    @classmethod
    def get_pids(cls):
        tmp = cls.query.filter(cls.t==1)
        return [item.n for item in tmp]

class RenRate(db.Document):
    """ 留存率比率 """
    t = db.FloatField(db_field='t')
    r = db.FloatField(db_field='r', default=1.0)
    s = db.StringField(db_field='s', default='app_1')

    @classmethod
    def get_r(cls, t, s):
        try:
            ret = cls.query.filter(cls.t==t, cls.s==s).first()
            if ret:
                return ret.r
            return 1.0
        except:
            return 1.0

    @classmethod
    def change_r(cls, t, r, s='app_1'):
        try:
            ret = cls.query.filter(cls.t==t, cls.s==s).first()
            if ret:
                ret.r = r
                ret.s = s
                ret.save()
                return True
            ret = cls()
            ret.s = s
            ret.t = t
            ret.r = r
            ret.save()
        except:
            return False
        return True


class LangConf(mdb.Document):
    """ 翻译配置表"""
    id = mdb.StringField(db_field='lid', primary_key=True, unique=True)
    lang_name = mdb.StringField(db_field='lidn')
    meta = {"db_alias": web_db_alias, 'collection': 'langconf'}


class PathMap(mdb.Document):
    """字段的路径与翻译词条的影射"""
    coll_name = mdb.StringField(db_field='cn')
    path = mdb.StringField(db_field='pth', unique_with='coll_name')
    meta = {"db_alias": web_db_alias, 'collection': 'pathmap'}


class LangMap(mdb.DynamicDocument):
    """ 翻译字串影射表"""
    id = mdb.StringField(db_field='_id', primary_key=True)
    cn_str = mdb.StringField()
    # lang_map_fields = mdb.ListField(mdb.StringField(default=u""),
    #                                 db_field='lmf')
    meta = {"db_alias": web_db_alias, 'collection': 'LangMap', 'index': ['id']}


class AnyDoc(mdb.DynamicDocument):
    meta = {"db_alias": web_db_alias}

class ListStringField(mdb.StringField):
    sep = ','

    def to_python(self, value):
        if not isinstance(value, unicode):
            try:
                value = value.decode('utf-8')
            except:
                value = unicode(value)
                pass

        try:
            value = value.split(self.sep)
        except:
            pass
        return value

    def to_mongo(self, value):
        try:
            value = [ e for e in set(value) if e ]
            if len(value) == 1:
                value = str(value[0])
            else:
                value = self.sep.join(value)
        except :
            self.error(u'不是有效的list "," 字符串: %s ', str(value))

        return value

    def validate(self, value):
        for e in value:
            super(ListStringField, self).validate(e)

    def _validate(self, value, **kwargs):
        # check choices
        if self.choices:
            value_to_check = value
            err_msg = 'one'
            if isinstance(self.choices[0], (list, tuple)):
                option_keys = [k for k, v in self.choices]
                if isinstance(value_to_check, (list, tuple)):
                    if not set(value_to_check).issubset(set(option_keys)):
                        msg = ('list Value must be %s of %s' %
                            (err_msg, unicode(option_keys)))
                        self.error(msg)

                elif value_to_check not in option_keys:
                    msg = ('Value must be %s of %s' %
                           (err_msg, unicode(option_keys)))
                    self.error(msg)
            elif value_to_check not in self.choices:
                msg = ('Value must be %s of %s' %
                       (err_msg, unicode(self.choices)))
                self.error(msg)

        # check validation argument
        if self.validation is not None:
            if callable(self.validation):
                if not self.validation(value):
                    self.error('Value does not match custom validation method')
            else:
                raise ValueError('validation argument for "%s" must be a '
                                 'callable.' % self.name)

        self.validate(value, **kwargs)


_SYSIDS = [('1', u"登陆次数"), ('2', u"登陆时长"), ('3', u"招募"), ('4', u"装备升级"),
           ('5', u"玩家升级"), ('6', u"排行榜"), ('7', u"boss战"), ('8', u"充值"), ('9', u"钓鱼"),
           ('10', u"战斗"), ('11', u"观星"), ('12', u"采矿"), ('13', u"商店"),
           ('14', u"竞技场"), ('15', u"时光盒"), ('16', u"消费"), ('17', u"深渊")]


class ActivitySetting(mdb.DynamicDocument):
    """
    活动设置表
    """
    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    begin = mdb.IntField(db_field='begin', verbose_name=u'开始')
    end = mdb.IntField(db_field='end', verbose_name=u'结束')
    type = mdb.IntField(db_field='type', verbose_name=u'类型id',
                        choices=[(0, u'通用')])
    state = mdb.IntField(db_field='state', choices=[(0, u'关'), (1, u'开')],
                         verbose_name=u'状态')
    name = mdb.StringField(db_field='name', verbose_name=u'活动名称')
    fmt = mdb.StringField(db_field='fmt', verbose_name=u'内容格式说明')
    sids = ListStringField(db_field='sids', verbose_name=u'作用服的id',
                           choices=[('', u'通用')])
    data = mdb.StringField(db_field='data', verbose_name=u'奖励内容')

    sysid = ListStringField(db_field='sysid', choices=_SYSIDS,
                            verbose_name=u'选择活动所属的系统分类')
    desc = mdb.StringField(db_field='desc', verbose_name=u'当前活动描述')
    mt = mdb.StringField(db_field='mt', verbose_name=u'邮件类型')
    # exclude_id = mdb.StringField(db_field='exclude_id',
    #                              verbose_name=u'排除作用的服id')

    meta = {'collection': 'reward_setting'}

_field_args = {'sids': {'multiple': True},
               'sysid': {'multiple': True},
               'type': {'coerce': int},
               'state': {'coerce': int},
               'id': {'widget': HiddenInput()},
               }
RewardSetForm = model_form(ActivitySetting, field_args=_field_args,
                           exclude=['name'])

LangIDForm = model_form(LangConf, field_args={'id': {'label': u'语言id'},
                                              'lang_name': {'label': u'名称'}})

class BoatLevel(mdb.Document):
    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    lv = mdb.IntField(db_field='lv', verbose_name=u'等级')
    nlv = mdb.IntField(db_field='nlv', verbose_name=u'增加天舟经验需求同盟的最低等级')
    t = mdb.IntField(db_field='t', verbose_name=u'类型')
    exp = mdb.IntField(db_field='exp', verbose_name=u'升下一级的经验')
    us = mdb.IntField(db_field='us', verbose_name=u'等级')
    meta = {'collection': 'ally_boat_level'}

    # @property
    def model_name():
        return u'天舟等级'

class BoatExchange(mdb.Document):
    """
    天舟兑换物品
    """
    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'ally_boat_exchange'}


class AwarBook(mdb.Document):
    """
    天书
    """
    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_book'}


class AwarStartConfig(mdb.Document):
    """
    战斗开启配置表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_start_config'}


class AwarPerConfig(mdb.Document):
    """
    每场战斗配置表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_per_config'}


class AwarNpcConfig(mdb.Document):
    """
    战斗npc配置表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_npc_config'}


class AwarWorldScore(mdb.Document):
    """
    魔龙降世评分表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_world_score'}


class AwarWorldAssess(mdb.Document):
    """
    魔龙降世评级表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_world_assess'}


class AwarStrongMap(mdb.Document):
    """
    魔龙降世势力地图表
    """

    id = mdb.IntField(db_field='_id', min_value=0, primary_key=True)
    meta = {'collection': 'awar_strong_map'}
