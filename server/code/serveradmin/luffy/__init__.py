#coding=utf-8
from os.path import join
from bson.objectid import ObjectId
from flask import Flask, g, session, request, flash, redirect, jsonify, url_for,render_template
from werkzeug.wsgi import DispatcherMiddleware
# from flask.ext.principal import Principal, RoleNeed, UserNeed, identity_loaded
from tprincipal import Principal, RoleNeed, UserNeed, identity_loaded
from time import time
from models import AdminUser, Servers
from models.u import mdb
from extensions import db
from define import GAMEBASE_LOCAL, GAMEBASE_SERVER, GAME_LOG_LOCAL, GAME_LOG_SERVER
from define import GAME_BASEUSER_TEST_SERVER, GAMEBASE_TEST,  GAME_BASEUSER_LOCAL
from define import TEST_ROLE_LIST, GAME_BASEUSER_SERVER, GAME_TD_G
# from adminconfig import AdminConfig, Admin91Config, ZLConfig, ZLTestConfig
from helps import build_url
from define import NUM_UNIX_A_DAY
import config as game_config
from corelib import log
import views
import pymongo
from luffy.models import MongoDrive
from luffy.client_app import application as clientsvr


DEFAULT_MODULES = (
    (views.frontend,""),
    (views.user,"/user"),
    (views.admin,"/admin"),
    (views.other,"/other")
)

def create_app(config=None, modules=None):
    if modules is None:
        modules = DEFAULT_MODULES

    app = Flask(__name__)

    # 安装配置文件
#    app.config.from_pyfile(config)
    app.config.from_object(game_config.BaseConfig())
    # 配置一些扩展组件
    configure_extensions(app)
    # 配置权限功能
    configure_identity(app)
    # 错误处理模块
    configure_errorhandlers(app)
    # 用户信息加载模块
    configure_before_handlers(app)
    # 模板的一些过滤功能
    configure_template_filters(app)
    # 上传的一些功能配置
    #configure_uploads(app, (photos,))
    # 注册所有站点模块
    configure_modules(app, modules)

    application = DispatcherMiddleware(app, {
    '/service':     clientsvr
    })
    return application

_conns = {}
def get_conn(host):
    print '*****', host
    if host in _conns:
        return _conns[host]
    else:
        _conns[host] = pymongo.Connection(host=host[0], port=int(host[1]))
        return _conns[host]

_mongo_conns = {}
def get_mongo_conn(host, port):
    if host in _mongo_conns:
        return _mongo_conns[host]
    else:
        mongo = MongoDrive()
        _mongo_conns[host] = mongo.connect(host, int(port))
        return _mongo_conns[host]

def configure_identity(app):
    """ 对用户权限进行配置 """
    Principal(app)
    @identity_loaded.connect_via(app)
    def on_identity_loaded(sender, identity):
        KEY_USERNAME    = 'username'
        KEY_PASSWORD    = 'password'
        GRPC_PORT       = '8001'
        MONGO_USERNAME_PASSWORD  = 'mongodb://%s:%s@%s'
        MONGO_IP                 = 'mongodb://%s'
        DB_RES_DEFAULT  = 'td_res'
        DB_USER_DEFAULT = 'td'
        DB_LOG_DEFAULT  = 'td_log'
        DB_COUNT        = 'td_count'
        RES_PATH_DEFAULT = '/data/webroot/www/game/config/zl/ver/'

        g.servers_group = Servers.query.distinct(Servers.db_res)
        g.user = AdminUser.query.from_identity(identity)
        if g.user is not None:
            if not g.user.server_group:
                g.servers = Servers.query.filter().sort((Servers.name,-1)).all()
            else:
                g.servers = Servers.query.filter(Servers.db_res==g.user.server_group).sort((Servers.name,-1)).all()
            mongo_host = None
            for s in g.servers:
                if s.mongo_id == g.user.server:
                    mongo_host = s
            if not mongo_host:
                if g.user.role == 400:
                    mongo_host = g.servers[0]
                else:
                    for s in g.servers:
                        try:
                            if g.user.right[14] == 1:
                                if s.t == 3:
                                    mongo_host = s
                            if g.user.right[13] == 0:
                                if s.t != 3:
                                    mongo_host = s
                        except:
                            continue

            mongo_host = mongo_host or g.servers[-1]


            if mongo_host:
                ip = mongo_host.ip
                port = mongo_host.port
                gport = mongo_host.gport
                if hasattr(mongo_host, KEY_USERNAME) and hasattr(mongo_host, KEY_PASSWORD):
                    if mongo_host.username and mongo_host.password:
                        ip = MONGO_USERNAME_PASSWORD % (mongo_host.username, mongo_host.password, ip)
                else:
                    ip = MONGO_IP % ip
                db_res  = mongo_host.db_res
                db_user = mongo_host.db_user
                db_log  = mongo_host.db_log
                db_count  = mongo_host.st
                res_path = mongo_host.res
                current_server = mongo_host
                g.user.server = ObjectId(mongo_host.mongo_id)
                session['g_user_server'] = mongo_host.mongo_id
            else:
                base_config = game_config.BaseConfig()
                ip          = base_config.MONGOALCHEMY_SERVER
                port        = base_config.MONGOALCHEMY_PORT
                cuser       = base_config.MONGOALCHEMY_USER
                cpassword   = base_config.MONGOALCHEMY_PASSWORD
                gport       = ':'.join([ip, GRPC_PORT])
                if cuser is None and cpassword is None:
                    ip = MONGO_IP % ip
                else:
                    ip = MONGO_USERNAME_PASSWORD % (cuser, cpassword, ip)
                db_res  = DB_RES_DEFAULT
                db_user = DB_USER_DEFAULT
                db_log  = DB_LOG_DEFAULT
                db_count = DB_COUNT
                res_path = RES_PATH_DEFAULT
                current_server = None
#            ip = '172.16.40.2'
            g.conns = get_conn((ip, port))
            g.mongo_drive = get_mongo_conn(ip, port)
            g.current_server = current_server
            g.GAMEBASE      = db_res
            g.GAME_BASEUSER = db_user
            g.GAME_LOG      = db_log
            g.GAME_COUNT    = db_count
            g.mongo_host    = ip
            g.res_path      = res_path
        #更新用户的最后登录时间
        if g.user is not None  and time() - g.user.lastlogin > NUM_UNIX_A_DAY:
                g.user.new_login()

def configure_extensions(app):
    # 初始化一些扩展
    db.init_app(app)
    mdb.init_app(app)
    db_config = app.config.get('MONGODB_SETTINGS')

    db_config = dict([(k.lower(), v) for k, v in db_config.items() if v])
    db_name = db_config.pop('db')
    mdb.register_connection(db_name, db_name, **db_config)
    dbs = Servers.query.distinct(Servers.db_res)
    for res_db in dbs:
        s = Servers.query.filter(Servers.db_res == res_db, Servers.ip!='127.0.0.1').first()
        if s:
            host = s.ip
            db_config.update({'host': host, 'username': s.username, 'password': s.password})
            mdb.register_connection(res_db, res_db, **db_config)

def configure_modules(app, modules):
    for module, url_prefix in modules:
        app.register_blueprint(module, url_prefix = url_prefix)

def configure_before_handlers(app):
    @app.before_request
    def authenticate():
        if not hasattr(g,'user'):
            g.user = None

def configure_template_filters(app):
    @app.template_filter()
    def url(action,filename,_external = False):
        return build_url(app,action,filename,_external)

    @app.template_filter()
    def string(val):
        return str(val)

    @app.template_filter()
    def rd(val, val2):
        return '%.20f' % (val/val2)

    @app.template_filter()
    def division(val=None, val2=None):
        if not val:
            val = 0
        if not val2 or val2 == 0:
            return 0
        return '%.2f' % (val/float(val2))

    @app.template_filter()
    def percent(val=None, val2=None):
        if not val:
            val = 0
        if not val2 or val2 == 0:
            return 0
        return '%.2f' % (val/float(val2)*100)

    @app.template_filter()
    def setRen(val, date):
        if date == '2013-06-20':
            return round(val*1.4, 2)
        return val

    @app.template_filter()
    def show_cout_day(alist, stype):
        ret = []
        for val in alist:
            if stype == 'year':
                ret.append(val.split('-')[0])
            if stype == 'month':
                ret.append(val)
            if stype == 'day':
                tmp = val.split('-')
                ret.append('-'.join([tmp[1], tmp[2]]))
            if stype == 'hour':
                ret.append('-'.join([val.split(' ')[0].split('-')[2], val.split(' ')[1]]))
        return ret


    @app.template_filter()
    def format_date(date,s='%Y-%m-%d %H:%M'):
        from datetime import datetime
        try:
            date = datetime.fromtimestamp(date)
            return date.strftime(s)
        except:
            return ''

    @app.template_filter()
    def short(val, num=33):
        if len(val) > num:
            return val[:num]
        return val

    @app.template_filter()
    def cout_day(alist, stype):
        ret = []
        for val in alist:
            val = format_date(val, s='%Y-%m-%d %H')
            if stype == 'year':
                ret.append(val.split('-')[0])
            if stype == 'month':
                ret.append(val)
            if stype == 'day':
                tmp = val.split('-')
                ret.append('-'.join([tmp[1], tmp[2]]))
            if stype == 'hour':
                ret.append('-'.join([val.split(' ')[0].split('-')[2], val.split(' ')[1]]))
        return ret

    @app.template_filter()
    def integer(val):
        if val:
            return int(val)
        return ''

    @app.template_filter()
    def float2(val, dec=2):
        return round(float(val), dec)

    @app.template_filter()
    def format_date_list(alist, s='%Y-%m-%d %H:%M'):
        try:
            return [format_date(item, s) for item in alist]
        except:
            return []

    @app.template_filter()
    def encode(val):
        return val.decode('utf-8')

    @app.template_filter()
    def strList(alist):
        return [a.encode('utf-8') for a in alist]

def configure_errorhandlers(app):
    @app.errorhandler(401)
    def unauthorized(error):
        if request.is_xhr:
            return jsonify(error=u"请先登录")
        return redirect(url_for("frontend.login", next=request.path))
