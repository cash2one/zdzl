#coding=utf-8

from bson.objectid import ObjectId
from luffy.define import STRING_NONE

import traceback
from flask import Blueprint, request, current_app, redirect, g,session,url_for, flash
import luffy.define as EXT
from luffy.models import MongoFive, Servers, Mongos, UserLog,DEFAULT_PORT, MongoDrive
from luffy.models import SyncTables, FilterPlayer, RenRate
from luffy.resp import resp
from bson.objectid import ObjectId
from luffy.permissions import moderator
from tprincipal import identity_changed,  AnonymousIdentity
from luffy.helps import print_traceback, range_list
from luffy.helps import format_date, get_format, xlsupload
import time, os, datetime, re, json
from bson.code import Code
from corelib import log
from webapi  import  SNS_MAP
import config as game_config
from game.base.common import get_days
from luffy.helps import strptime, time_to_hour, grpc_get_proxy
from luffy.forms.cp import QaccoutForm
from luffy.forms.cp import CoinQueryForm
from luffy.forms.cp import MailForm
from luffy.forms.cp import LangForm
from luffy.models.u import LangConf
from luffy.forms.app_service import AppConfigForm
from corelib import log
from corelib.tools import http_post_ex

user = Blueprint('user', __name__,static_folder='static')

is_check = ic_retention2 = ic_retention7 = ic_retention15 = True

@user.route("/", methods = ("GET", "POST"))
@moderator.require(401)
@resp()
def index():
    return {  }

@user.route("/show/", methods = ("GET", "POST"))
@moderator.require(401)
@resp(template="user/index.html")
def index_show():
    user_index = 'user_index'
    return { 'user_index':user_index }

@user.route('/client/servers/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def client_servers():
    """ 客户端服务器列表 """
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_SERVER, host=g.mongo_host)
    ret = mongo.all()
    return { 'SIDEBAR':'ADMIN', 'ret':ret }

@user.route('/client/servers/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def client_servers_save():
    """ 客户端服务器列表数据保存 """
    STR_DATA, STR_HOST, STR_PORT, STR_SID, STR_APP   = 'data', 'host', 'port', 'sid', 'app'
    STR_NAME, STR_STATUS, STR_CONDITION     = 'name', 'status', 'condition'
    id      = request.form.get(EXT.KEY_ID)
    host    = request.form.get(STR_HOST)
    port    = request.form.get(STR_PORT)
    name    = request.form.get(STR_NAME)
    status  = request.form.get(STR_STATUS)
    sid     = request.form.get(STR_SID)
    app     = request.form.get(STR_APP)
    try:
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_SERVER, host=g.mongo_host)
        insert_val = {
            EXT.KEY_MONGO_ID    : int(id),
            STR_HOST            : host,
            STR_PORT            : int(port),
            STR_NAME            : name,
            STR_STATUS          : int(status),
            STR_SID             : int(sid),
            STR_APP             : app
        }
        args = { STR_CONDITION:{EXT.KEY_MONGO_ID:int(id)}, STR_DATA:insert_val}
        mongo.update(args)
        return { 'success':'1', 'id':id }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/client/servers/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def client_servers_delete():
    """ 客户端服务器列表单数据删除 """
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_SERVER, host=g.mongo_host)
        mongo.delete(id)
        return { 'success':'1' }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/client/servers/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def client_servers_data():
    """ 客户端服务器列表单数据获取 """
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_SERVER, host=g.mongo_host)
        ret = mongo.get_by_id(int(id))
        return { 'success':'1', 'ret':ret}
    except:
        print_traceback()
        return { 'success':'0'}
#=============================================================

@user.route('/database/backup/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def database_backup():
    """ 数据库备份页面 """
#    backup_path = current_app.config.get('MONGO_BACKUP_PATH')
    backup_path = game_config.MONGO_BACKUP_PATH
    ret = None
    if os.path.isdir(backup_path):
        ret = os.listdir(backup_path)
        ret = [item for item in ret if not item.startswith('.')]
    return { 'SIDEBAR':'ADMIN', 'ret':ret }

@user.route('/database/backup/operation/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def database_backup_operation():
    """ 数据库备份操作部份 """
#    backup_path = current_app.config.get('MONGO_BACKUP_PATH')
    backup_path = game_config.MONGO_BACKUP_PATH
    opType = request.args.get('opType')
    server = Servers.query.get(g.user.server)
    if opType == 'dump':
        tmp_path = ''.join([backup_path, str(datetime.date.fromtimestamp(time.time())), '/'])
        dump_order = ['mongodump', '-h', server.ip, '-o', tmp_path]
        if hasattr(server, 'username') and server.username:
            dump_order.append('-u')
            dump_order.append(server.username)
        if hasattr(server, 'password') and server.password:
            dump_order.append('-p')
            dump_order.append(server.password)
        os.system(' '.join(dump_order))
    if opType != 'dump':
        backup_date = request.args.get('backup_date')
        path = ''.join([backup_path, backup_date])
    if opType == 'del':
        import shutil
        shutil.rmtree(path)
    if opType == 'restore':
        restore_order = ['mongorestore', '-h', server.ip, '-directoryperdb', path]
        os.system(' '.join(restore_order))
    return { 'success':1 }


@user.route('/database/restore/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def database_restore():
    """ 数据库同步页面 """
    ret = Mongos.query.sort().all()
    tables = SyncTables.query.all()
    return { 'SIDEBAR':'ADMIN', 'ret':ret, 'tables':tables }

@user.route('/database/restore/tables/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def database_restore_tables():
    """ 数据库同步表 """
    tables = SyncTables.query.all()
    return { 'SIDEBAR':'ADMIN', 'tables':tables }

@user.route('/database/restore/tables/save/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def database_restore_tables_save():
    """ 数据库同步表保存 """
    names = request.form.get('names', None)
    title = request.form.get('title', None)
    remark = request.form.get('remark', None)
    oid = request.form.get('id', None)
    opType = request.form.get('opType')
    if opType == 'add':
        tables = SyncTables()
    if opType == 'edit':
        tables = SyncTables.query.get_or_404(ObjectId(oid))
    if opType == 'add' or opType == 'edit':
        tables.names = names
        tables.title = title
        tables.remark = remark
        tables.save()
    if opType == 'del':
        tables = SyncTables.query.get_or_404(ObjectId(oid))
        tables.remove()
    return { 'SIDEBAR':'ADMIN', 'success':1 }

@user.route('/database/restore/operation/<string:opType>/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def database_restore_operation(opType):
    """ 数据库同步配置操作 """
    mongos = Mongos()
    if opType == 'add' or opType == 'edit':
        ip              = request.form.get('ip', None)
        port            = request.form.get('port', None)
        username        = request.form.get('username', None)
        password        = request.form.get('password', None)
        database        = request.form.get('database', None)
        tables          = request.form.get('tables', None)
        remark          = request.form.get('remark', None)
        st          = request.form.get('st', 'zl')
        isDrop          = int(request.form.get('isDrop', '1'))
        localdatabase   = request.form.get('localdatabase', None)
        t = int(request.form.get('t', 1))
        id = request.form.get('id', '')
        if id:
            mongos = Mongos.query.get_or_404(ObjectId(id))
        else:
            mongos = Mongos()
            if not ip:
                return {'success':0}
        if ip:
            mongos.ip = ip
        if port:
            mongos.port = int(port)
        mongos.username = username
        mongos.password = password
        if tables:
            mongos.tables = ObjectId(tables)
        if database:
            mongos.database = database
        if remark:
            mongos.remark = remark
        if localdatabase:
            mongos.localdatabase = localdatabase
        mongos.t = t
        mongos.st = st
        mongos.is_drop = isDrop
        mongos.save()
        return {'success':1}
    elif opType == 'del':
        id = request.form.get('id', '')
        try:
            id = ObjectId(id)
        except:
            raise 404
        mongos = Mongos.query.get_or_404(id)
        mongos.remove()
        return {'success':1}
    return { 'success':0 }

#@user.route('/database/server/restore/', methods=('GET', 'POST'))
#@moderator.require(401)
#@resp(ret='json')
#def database_server_restore():
#    """ 数据库同步操作 """
#    import subprocess
#    success = 1
#    info    = ''
#    opType = request.args.get('opType')
#    mid = request.args.get('mid')
#    isDrop = int(request.args.get('isDrop'))
#    print "isDrop************", isDrop
#    #获取source源地址信息， target目标信息
#    if opType == 'push':
#        source = Servers.query.get(g.user.server)
#        target = Mongos.query.get_or_404(ObjectId(mid))
#        database = target.database
#        collections = target.table_names.split('\n')
#        local_database = target.localdatabase
#        fileDatabase = local_database
#    if opType == 'pull':
#        source = Mongos.query.get_or_404(ObjectId(mid))
#        target = Servers.query.get(g.user.server)
#        local_database = source.database
#        collections = source.table_names.split('\n')
#        database = source.localdatabase
#        fileDatabase = database
#
#    filePath = ''.join([os.path.dirname(user.root_path), '/static/sync/', fileDatabase, '/' ])
#    if os.path.isdir(filePath) is False:
#        os.mkdir(filePath)
#    #定义从source接数据的命令
#    mongo_export_order = ['mongoexport', '-h', source.ip, '--port', str(source.port),
#                          '-d', local_database]
#    if hasattr(source, 'username') and source.username:
#        mongo_export_order.append('-u')
#        mongo_export_order.append(source.username)
#
#    if hasattr(source, 'password') and source.password:
#        mongo_export_order.append('-p')
#        mongo_export_order.append(source.password)
#    #定义推向source的命令
#    mongo_import_order = ['mongoimport', '-h', target.ip, '--port', str(target.port), '-d', database] #, '--drop'
#    if isDrop:
#        mongo_import_order.append("--drop")
#    if hasattr(target, 'username') and target.username:
#        mongo_import_order.append('-u')
#        mongo_import_order.append(target.username)
#    if hasattr(target, 'password') and target.password:
#        mongo_import_order.append('-p')
#        mongo_import_order.append(target.password)
#    try:
#        for item in collections:
#            print "mongoimort collection is ", item
#            if item == '':
#                continue
#            export_tmp = mongo_export_order[:]
#            export_tmp.append('-c')
#            export_tmp.append(item)
#            export_tmp.append('-o')
#            export_tmp.append(filePath+item+'.bson')
#            import_tmp = mongo_import_order[:]
#            import_tmp.append('-c')
#            import_tmp.append(item)
#            import_tmp.append('--file')
#            import_tmp.append(filePath+item+'.bson')
#            p = subprocess.Popen(export_tmp, stdout=subprocess.PIPE)
#            while p.poll() == None:
#                time.sleep(1)
#            export_ret = p.communicate()
#
#            p = subprocess.Popen(import_tmp, stdout=subprocess.PIPE)
#            while p.poll() == None:
#                time.sleep(1)
#            import_ret = p.communicate()
#            print item, ":info =", import_ret
#            info = ''.join([export_ret[0], '\n', import_ret[0]])
#    except:
#        import traceback
#        info = traceback.format_exc()
#        success = 0
#    import shutil
#    shutil.rmtree(filePath)
#    return { 'success':success, 'info':info }

@user.route('/database/server/restore/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def database_server_restore():
    """ 数据库同步操作 """
    import subprocess
    success = 1
    info    = ''
    opType = request.args.get('opType')
    mid = request.args.get('mid')
    isDrop = int(request.args.get('isDrop'))
    #获取source源地址信息， target目标信息
    local_mongo = MongoDrive()
    server_mongo = MongoDrive()

    if opType == 'push':
        source = Servers.query.get(g.user.server)
        target = Mongos.query.get_or_404(ObjectId(mid))
        database = target.database
        collections = target.table_names.split('\n')
        local_database = target.localdatabase

    if opType == 'pull':
        source = Mongos.query.get_or_404(ObjectId(mid))
        target = Servers.query.get(g.user.server)
        local_database = source.database
        collections = source.table_names.split('\n')
        database = source.localdatabase

    local_host_url = "mongodb://%s:%s@%s"%(source.username, source.password, source.ip)
    local_host = local_mongo.connect(local_host_url, int(source.port))

    server_host_url = "mongodb://%s:%s@%s"%(target.username, target.password, target.ip)
    server_host = server_mongo.connect(server_host_url, int(target.port))



    try:
        log.info("[mongodb asyn collections:%s]", collections)
        for item in collections:
            if not item:
                continue
            log.info("[mongodb asyn] %s", item)
            print 'local_database, collection **', local_database, item
            document = local_host.all(local_database, item, querys={})
            if not item.startswith("system."):
                server_host.drop(database, item)
            for data in document:
                if EXT.KEY_MONGO_ID not in data:
                    continue
                tmp_id = data.pop(EXT.KEY_MONGO_ID)
                server_host.update(database, item, {EXT.KEY_MONGO_ID:tmp_id}, data)
        info = u'数据同步完成'
    except:
        import traceback
        info = traceback.format_exc()
        print info
        log.log_except()
        success = 0

#    import shutil
#    shutil.rmtree(filePath)
    return { 'success':success, 'info':info }


@user.route("/server/manage/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_manage():
    """ 服务器管理页面 """
    ret = Servers.query.sort((Servers.name,-1)).all()
    print "****server_manage::"
    form = LangForm()
    form.current_lang.queryset = LangConf.objects
    return { 'SIDEBAR':'ADMIN', 'ret':ret, 'form': form}

@user.route('/server/manage/operation/<string:opType>/', methods=('GET','POST'))
@moderator.require(401)
@resp( ret='json')
def server_manage_operation(opType):
    """ 服务器管理数据操作部份 """
    from bson.objectid import ObjectId
    if opType == 'add' or opType == 'edit':
        name        = request.form.get('name', None)
        ip          = request.form.get('ip', None)
        port        = request.form.get('port', None)
        username    = request.form.get('username', None)
        password    = request.form.get('password', None)
        gport       = request.form.get('gport', None)
        t           = int(request.form.get('t', 1))
        tf          = request.form.get('tf', 'zh-CN')
        db_res      = request.form.get('db_res', None)
        db_user     = request.form.get('db_user', None)
        db_log      = request.form.get('db_log', None)
        id          = request.form.get('id', '')
        st          = request.form.get('st', 'zl')
        res         = request.form.get('res_path', '')
        sid         = request.form.get('sid', '')
        if id:
            server = Servers.query.get_or_404(ObjectId(id))
        else:
            server = Servers()
            if not ip or not name:
                return {'success':0}
        server.name = name
        server.ip = ip
        server.port = int(port)
        server.username = username
        server.password = password
        server.gport = gport
        server.t = t
        server.tf = tf
        server.db_log = db_log
        server.db_res = db_res
        server.db_user = db_user
        server.st = st
        server.res = res
        server.sid = sid
        server.save()
        return {'success':1}
    elif opType == 'del':
        id = request.form.get('id', '')
        try:
            id = ObjectId(id)
        except:
            raise 404
        server = Servers.query.get_or_404(id)
        server.remove()
        return {'success':1}
    return { 'success':0 }


@user.route("/server/function/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_function():
    """ 服务器其他功能 """
    ret = Servers.query.all()
    return { 'SIDEBAR':'ADMIN', 'ret':ret }

# ==========================
@user.route('/server/gconfig/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_gconfig():
    """ gconfig """
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
    ret = mongo.all()
    return { 'SIDEBAR':'ADMIN', 'ret':ret }

@user.route('/server/gconfig/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def server_gconfig_save():
    STR_KEY, STR_VALUE  = 'key', 'value'
    id      = request.form.get(EXT.KEY_ID)
    key    = request.form.get(STR_KEY, EXT.STRING_NONE)
    value    = request.form.get(STR_VALUE, EXT.STRING_NONE)
    try:
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
        insert_val = {
            EXT.KEY_MONGO_ID    : int(id),
            STR_KEY            : key,
            STR_VALUE          : value,
        }
        args = { EXT.STRING_CONDITION:{EXT.KEY_MONGO_ID:int(id)},
            EXT.STRING_DATA:insert_val}
        mongo.update(args)
        return { 'success':'1', 'id':id }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/server/gconfig/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def server_gconfig_delete():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
        mongo.delete(id)
        return { 'success':'1' }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/server/gconfig/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def server_gconfig_data():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
        ret = mongo.get_by_id(int(id))
        return { 'success':'1', 'ret':ret}
    except:
        print_traceback()
        return { 'success':'0'}

#===========================

# ==========================
@user.route('/customer/account/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def customer_account():
    """ 客服系统帐号管理 """
    mongo = MongoFive('customer', 'users', host=g.mongo_host)
    ret = mongo.all()
    return { 'SIDEBAR':'ADMIN', 'ret':ret }

@user.route('/customer/account/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def customer_account_save():
    from luffy.helps import md5
    STR_EMAIL, STR_PASSWORD, STR_T  = 'email', 'password', 't'
    id      = request.form.get(EXT.KEY_ID)
    email    = request.form.get(STR_EMAIL, EXT.STRING_NONE)
    password    = request.form.get(STR_PASSWORD, EXT.STRING_NONE)
    t    = request.form.get(STR_T, EXT.STRING_NONE)
    try:
        mongo = MongoFive('customer', 'users', host=g.mongo_host)
        insert_val = {
            EXT.KEY_MONGO_ID    : int(id),
            STR_EMAIL           : email,
            STR_PASSWORD        : md5(password),
            STR_T               : int(t)
        }
        args = { EXT.STRING_CONDITION:{EXT.KEY_MONGO_ID:int(id)},
            EXT.STRING_DATA:insert_val}
        mongo.update(args)
        return { 'success':'1', 'id':id }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/customer/account/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def customer_account_delete():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive('customer', 'users', host=g.mongo_host)
        mongo.delete(id)
        return { 'success':'1' }
    except:
        print_traceback()
        return { 'success':'0' }

@user.route('/customer/account/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def customer_account_data():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive('customer', 'users', host=g.mongo_host)
        ret = mongo.get_by_id(int(id))
        return { 'success':'1', 'ret':ret}
    except:
        print_traceback()
        return { 'success':'0'}

#===========================

@user.route("/server/manage/builder/", methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def server_manage_builder():
    """ 执行builder.shell脚本 """
    cwd = '/home/game/gameres'
    builder_shell = './builder.shell'
    import subprocess
    p = subprocess.Popen([builder_shell], shell=True, cwd=cwd, stdout=subprocess.PIPE)
    info = p.stdout.read()
    return { 'success':1, 'info':info }

@user.route("/server/set/default/", methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def server_set_default():
    """ 选择服务器 """
    server_id = request.args.get('serverid')
    g.user.server = ObjectId(server_id)
    session['g_user_server'] = server_id
    g.user.save()
    return { 'success':1 }

@user.route("/server/set/group/", methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def server_set_group():
    """ 选择服务器 """
    group = request.args.get('group')
    g.user.server_group = group
    g.user.save()
    return { 'success':1 }

@user.route("/server/gm/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_gm():
    """ GM管理，全局 """
    form = MailForm()
    form.platform.choices = [(k, v) for k, v in SNS_MAP.iteritems()]
    return {'SIDEBAR': EXT.SIDEBAR_SERVER, 'form': form}

@user.route("/server/gm/players/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_gm_players():
    """ GM在线角色管理页面 """
    import config as game_config
    players = None
    players_cols    = ['level', 'exp', 'vip', 'pos', 'mapId', 'coin1', 'coin2', 'coin3',
                        'vipCoin', 'posId', 'name', '_id', 'train', 'chapter']
    count = 0
    total = 0
    pre_page        = 100
    info_list       = None
    page            = int(request.args.get('page','1'))
    proxy           = grpc_get_proxy(g.user.server)
    if proxy:
        count = total = proxy.get_count()
        tmp_count = float(count) / 100
        if tmp_count > 1:
            tmp = tmp_count % 1
            count = int(tmp_count)
            if tmp != 0:
                count += 1
        else:
            count = 1
        start = page*pre_page - 100
        end = page*pre_page
        players = proxy.get_onlines(start, end)
        players_list = [item[0] for item in players]
        if players_list:
            try:
                info_list = proxy.get_rpc_player_info(players_list, players_cols)
            except:
                info_list = None
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'players':players, 'count':count, 'page':page,
            'info_list':info_list, 'total':total, 'platform':game_config.SERVER_VER_CONFIG}

@user.route("/server/gm/player/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_gm_player():
    """ 单人角色GM管理页面 """
    pid = int(request.args.get('pid'))
    name = request.args.get('name','')
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'pid':pid, 'name':name }

@user.route("/server/gm/player/order/", methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def server_gm_player_order():
    """ GM管理接收页面信息发送至GRPC """
    from luffy.models import Gm

    proxy = grpc_get_proxy(g.user.server)
    user_log = UserLog()
    gtype = request.args.get('gtype')
    pid = request.args.get('pid', 1)
    if pid == '':
        pid = 1
    else:
        pid = int(pid)
    gm = Gm(gtype, pid)
    ret = gm.execute()
    return { 'ret':ret }

@user.route('/server/gm/change/notice/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def server_gm_change_notice():
    msg = request.args.get('notice')
    if not msg:
        return {'ret':u"信息不能为空"}
    msg = msg.replace("\n", "*")
    user = MongoFive(g.GAME_BASEUSER, EXT.COLL_GCONFIG, host=g.mongo_host)
    import pymongo
    db = pymongo.Connection(host=g.mongo_host, port=DEFAULT_PORT)
    collection = db[g.GAMEBASE][EXT.COLL_GCONFIG]
    collection.update({'key':'notice'}, {"$set":{'value':msg}})
    return {'ret': u'操作成功'}


@user.route('/udid/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def udid():
    user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    querys = {}
    ret = user.distince_filter('MAC', querys)
    # ret = user.distince('UDID')
    return {'ret':ret, 'count':len(ret)}

@user.route('/complex/count/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def complex_count():
    """ 综合报表 """
    D_U, STR_T = 'd.u', 't'
    from luffy.models import ComplexCount, NewComplexCount, NewComplexCountToday

    t = int(request.args.get('t','-1'))
    # 时间格式转换
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    start_time_str, end_time_str, start_time, end_time = FiveMethods.get_time(searchCondition)
    # 统计类型
    time_format     = get_format(searchCondition)
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)
    # 从数据库获取统计结果
    ret = ComplexCount.query.filter(ComplexCount.t>=start_time, ComplexCount.t<=end_time,
        ComplexCount.s==g.GAME_BASEUSER).descending(ComplexCount.t).all()
    # 时间范围内存在的纪录时间集
    had_time = ComplexCount.query.filter(ComplexCount.t>=start_time,
            ComplexCount.t<=end_time, ComplexCount.s==g.GAME_BASEUSER).distinct(ComplexCount.t)
    need_check = list(set(time_list)-set(had_time))
    # 去获取数据并写入数据库
    global is_check
    if is_check:
        is_check = False
        NewComplexCount(need_check, time_format, searchCondition)
        is_check = True
    # 今日数据(实时)
    (today, create_users, login_ret, online_max, online_avg,
        max_login_pid, pay_ret, all_deals,pay_nums,
        new_pay_nums) = NewComplexCountToday(time_format, searchCondition)
    # 当前在线人数
    proxy = grpc_get_proxy(g.user.server)
    if proxy:
        total = proxy.get_count()
    else:
        total = 0
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
    'end_time':end_time_str,'searchCondition':searchCondition, 'total':total,
    'ret':ret, "create_users":create_users, "login_ret":login_ret,
    "online_max":online_max, "online_avg":online_avg,  "max_login_pid":max_login_pid,
    "pay_ret":pay_ret, "all_deals":all_deals, "pay_nums":pay_nums,
    "new_pay_nums":new_pay_nums, "today":today}

@user.route('/complex/count/new/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def complex_count_new():
    """ 综合报表 """
    D_U = 'd.u'
    from luffy.models import CCount, NewCCount, NewCCountToday, ccount_all
    # 时间格式转换
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    st = int(request.args.get(EXT.KEY_T, -1))
    print 'st***', st
    start_time_str, end_time_str, start_time, end_time = FiveMethods.get_time(searchCondition)
    # 统计类型
    time_format     = get_format(searchCondition)
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)
    # 从数据库获取统计结果
    query = {CCount.t:{'$gte':start_time, '$lte':end_time}, CCount.s:g.GAME_BASEUSER}
    if st != -1:
        query.update({CCount.platform:st})
    ret = CCount.query.filter(query).descending(CCount.t).all()
    if st == -1:
        ret = ccount_all(ret)
    # 时间范围内存在的纪录时间集
    had_time = CCount.query.filter(query).distinct(CCount.t)
    need_check = list(set(time_list)-set(had_time))
    # 去获取数据并写入数据库
    global is_check
    if is_check:
        is_check = False
        NewCCount(need_check, time_format, searchCondition)
        is_check = True
    # 今日数据(实时)
    (today, create_users, login_ret, online_max, online_avg,
        max_login_pid, pay_ret, all_deals,pay_nums,
        new_pay_nums) = NewCCountToday(time_format, searchCondition, st)
    # 当前在线人数
    proxy = grpc_get_proxy(g.user.server)
    if proxy:
        total = proxy.get_count()
    else:
        total = 0
    print '***************', login_ret
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
    'end_time':end_time_str,'searchCondition':searchCondition, 'total':total,
    'ret':ret, "create_users":create_users, "login_ret":login_ret,
    "online_max":online_max, "online_avg":online_avg,  "max_login_pid":max_login_pid,
    "pay_ret":pay_ret, "all_deals":all_deals, "pay_nums":pay_nums,
    "new_pay_nums":new_pay_nums, "today":today }

@user.route('/reg/level/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def reg_level():
    def tmp_count_level(item, ret, time_key):
        for x in xrange(1, 18):
            if item[EXT.KEY_LEVEL] == x:
                if x in ret[time_key]:
                    ret[time_key][x] += 1
                else:
                    ret[time_key][x] = 1
        if item[EXT.KEY_LEVEL] > 17:
            if 18 in ret[time_key]:
                ret[time_key][18] += 1
            else:
                ret[time_key][18] = 1

    e_name = FilterPlayer.get_pids()
    e_u_name = FilterPlayer.get_uids()
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=searchCondition)
    # 调用统计类进行统计
    from luffy.count import Count, time_to_hour
    database = (g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, g.mongo_host)
    player_count = Count(start_time, end_time, database)
    # 根据类型进行统计
    time_format = get_format(searchCondition)
    # 过滤
    mongo_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    uids_query = {EXT.KEY_NAME:{EXT.MONGO_IN:e_u_name}}
    uids_ret = mongo_user.distince_filter(EXT.KEY_MONGO_ID, uids_query)
    querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_name}},
                        EXT.KEY_UID:{EXT.MONGO_NOT:{EXT.MONGO_IN:uids_ret}}}
    mongo_ret = player_count.getRetByQuerys(EXT.KEY_TNEW, querys_addition=querys_addition)
    ret = {}
    for item in mongo_ret:
        time_key = time_to_hour(item[EXT.KEY_TNEW], time_format)
        if time_key in ret:
            ret[time_key][EXT.STRING_COUNT] += 1
        else:
            ret[time_key] = {EXT.STRING_COUNT:1}
        tmp_count_level(item, ret, time_key)
    ret = sorted(ret.items(), key=lambda d:d[0], reverse=True)
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
            'end_time':end_time_str, 'ret':ret}


@user.route('/pay/accouts/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def pay_accouts_query():
    """ 实时充值账号统计 """
    form = QaccoutForm()
    entries = []
    if form.validate_on_submit():
        mongo_log = MongoFive(g.GAMEBASE, EXT.COLL_PAY_LOG, host=g.mongo_host)
        accout_str = form.order_token.data
        querys_addition = {EXT.KEY_PL_TORDER: accout_str}
        log_entries = mongo_log.first(querys_addition)
        if log_entries:
            sid = log_entries[EXT.KEY_SID]
            sid = str(sid)
            detail = log_entries['data']
            detail_str = ''
            for key, value in detail.iteritems():
                detail_str = detail_str + str(key) + ': '
                if isinstance(value, (basestring,)):
                    value = value.encode('utf-8')
                detail_str  = detail_str + str(value) + ', '
            log_entries['detail'] = detail_str
            server_entry = Servers.query.filter(Servers.sid == sid, Servers.db_res == g.GAMEBASE)
            if server_entry.count() > 0:
                entry = server_entry.one()
                user_db = entry.db_user
                uid = int(log_entries[EXT.KEY_UID])
                mongo_user = MongoFive(user_db, EXT.BASEUSER_USER, host=entry.ip)
                user_nickname = mongo_user.first({'_id': uid})
                log_entries['username'] = user_nickname[EXT.KEY_NAME] if user_nickname else u'未知用户名'
                entries.append(log_entries)

    return {'form': form, "table_entries": entries}


@user.route('/pay/count/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def pay_count():
    """ 实时充值统计 """
    from luffy.helps import check_dict_item
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    stype = int(request.args.get(EXT.STRING_STYPE, -1))
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_HOUR)
    # 转换时间格式
    time_format     = get_format(searchCondition)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(
        start_time_str, end_time_str, beforeDay=EXT.NUMBER_ONE, searchCondition='hour')
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_ONE_HOUR)
    time_day_ticks = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)
    e_name = FilterPlayer.get_pids()
    e_list = FilterPlayer.get_uids()
    mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    e_uids = mongo_player.distince_filter(EXT.KEY_UID, {EXT.KEY_NAME:{EXT.MONGO_IN:e_name}})
    querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_list}},
                        EXT.KEY_MONGO_ID:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
    if stype != -1:
        querys_addition.update({EXT.KEY_T:stype})
    from luffy.count import Count
    database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
    pay_count_mongo = Count(start_time, end_time, database)
    # 充值金额
    ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
    querys_addition.update(ex_q)
    pay_ret         = pay_count_mongo.getAccumulateCount(EXT.KEY_CT, EXT.STRING_PRICE,
                        time_format, querys_addition=querys_addition)
    pay_ret_list    = [check_dict_item(pay_ret,item) for item in time_list]
    # 充值人数
    players_nums    = pay_count_mongo.getNewPlayer(EXT.KEY_CT, time_list,
                        time_range=EXT.NUM_UNIX_ONE_HOUR-1, querys_addition=querys_addition)
    players_nums_list = [check_dict_item(players_nums,item) for item in time_list]
    # 充值次数
    pay_nums        = pay_count_mongo.getCount(EXT.KEY_CT, time_format, 'dict',
                    querys_addition=querys_addition)
    pay_nums_list = [check_dict_item(pay_nums,item) for item in time_list]
    day_pay_list = []
    day_pay_nums_list = []
    day_players_nums_list = []
    hours_per_day = 24
    for i in range(len(time_day_ticks)):
        s = i*hours_per_day
        e = s + hours_per_day
        day_pay_list.append(sum(pay_ret_list[s:e]))
        day_pay_nums_list.append(sum(pay_nums_list[s:e]))
        day_players_nums_list.append(sum(players_nums_list[s:e]))

    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
            'end_time':end_time_str, 'searchCondition':searchCondition, 'pay_nums':pay_nums,
            'time_list':time_list, 'day_ticks': time_day_ticks, 'pay_ret':pay_ret, 'players_nums':players_nums,
            'pay_ret_list':day_pay_list, 'players_nums_list':day_players_nums_list,
            'pay_nums_list':day_pay_nums_list, 'stype':stype }

@user.route('/get/pay/log/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def get_pay_log():
    from luffy.models import get_pay_log
    path = ''.join([os.path.dirname(user.root_path), '/static/xlsdatabase/pay.xls'])
    try:
        get_pay_log(path)
    except:
        return {'success':0}
    return {'success':1}


@user.route('/platform/userinfo/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='user/common_search_result.html')
def puser_info():
    from luffy.forms.cp import PUserInfo
    import config as game_config

    def format_date(date,s='%Y-%m-%d %H:%M'):
        from datetime import datetime
        try:
            date = datetime.fromtimestamp(date)
            return date.strftime(s)
        except:
            return ''

    api_host = game_config.WEBAPI_HOST
    api_port = game_config.WEBAPI_PORT
    api_url = game_config.WEBAPI_URL
    query_key = request.args.get('puid')
    params = {'uid': query_key}

    f = PUserInfo()
    try:
	data = http_post_ex(api_host, api_port, api_url, params=params)
        uinfo = json.loads(data)
        u = uinfo['user']
        if 'createDate' in u:
            u['createDate'] = format_date(u['createDate'])
        qdata = [u]
    except:
	if query_key:
	    qdata = [{"id": query_key, "createDate": u"未绑定平台"}]
	else:
	    qdata = []

    kwargs = {'SIDEBAR': EXT.SIDEBAR_SERVER,
              'data': qdata,
              'form': f,
              }
    return kwargs

@user.route('/pay/nums/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def pay_nums():
    """ 实时充值统计 """
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 统计类型
    time_format     = get_format(searchCondition)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(
            start_time_str, end_time_str, searchCondition=searchCondition)
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)

    q = {}
    stype = int(request.args.get(EXT.STRING_STYPE, -1))
    if stype != -1:
        q.update({EXT.KEY_T:stype})
    from luffy.count import Count
    ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
    q.update(ex_q)
    database        = (g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
    pay_count       = Count(start_time, end_time, database)
    # pay_ret         = pay_count.getAccumulateCount(EXT.KEY_CT, EXT.STRING_PRICE, time_format)
    users           = pay_count.getPlayer(EXT.KEY_CT, time_list, q=q)
    from luffy.helps import check_dict_item
    player_list = [check_dict_item(users,item) for item in time_list]

    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
            'end_time':end_time_str, 'searchCondition':searchCondition,
            'time_list':time_list, 'player_list':player_list, 'users':users, 'stype':stype}

@user.route("/server/reg/count/", methods = ("GET", "POST"))
@moderator.require(401)
@resp()
def server_reg_count():
    """ 注册统计 """
    # 从页面获取信息
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    stype           = int(request.args.get(EXT.STRING_STYPE, '-1'))
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)
    from luffy.count import Count, hour_count
    database = (g.GAME_BASEUSER, EXT.BASEUSER_USER, g.mongo_host)
    user_count = Count(start_time, end_time, database)
    time_format = get_format(searchCondition)
    # ret = user_count.getCount(EXT.KEY_TNEW, time_format)

    e_name = FilterPlayer.get_pids()
    e_list = FilterPlayer.get_uids()
    mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    e_uids = mongo_player.distince_filter(EXT.KEY_UID, {EXT.KEY_NAME:{EXT.MONGO_IN:e_name}})
    querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_list}},
                        EXT.KEY_MONGO_ID:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_uids}}}
    if stype != -1:
        querys_addition = {EXT.STRING_SNS:stype}

    mongo_ret = user_count.getRetByQuerys(EXT.KEY_TNEW, querys_addition=querys_addition)
    ret = hour_count(mongo_ret, EXT.KEY_TNEW, time_format)
    keys = [format_date(item[0], time_format) for item in ret]
    rets = [item[1] for item in ret]

    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'keys':keys,'rets':rets,
            'start_time':start_time_str, 'end_time':end_time_str,
            'searchCondition':searchCondition, 'stype':stype }

@user.route("/server/player/search/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_player_search():
    """ 角色查询 """
    import config as game_config
    STR_ALL = 'all'
    player_ret  = []
    pid_list    = []
    player      = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    page_count  = 0
    page        = int(request.args.get('page', '1'))
    playerId    = request.args.get('playerId','')
    playerName  = request.args.get('playerName','')
    querys      = request.args.get('querys', '')
    stype       = request.args.get('stype', None)
    dic         = {}

    # try:
    if stype == STR_ALL:
        player_ret = player.paginate(page=page, sort=EXT.KEY_TNEW)
        page_count = player.page_count()
    else:
        if playerId != EXT.STRING_NONE:
            dic[EXT.KEY_MONGO_ID] = int(playerId)
        if playerName != EXT.STRING_NONE:
            dic[EXT.KEY_NAME] = re.compile('.*'+playerName+'.*')
        if querys != EXT.STRING_NONE:
            querys_tmp = json.loads(querys)
            dic.update(querys_tmp)
        if playerId != EXT.STRING_NONE or playerName != EXT.STRING_NONE or querys != EXT.STRING_NONE:
            player_ret = player.paginate(page=page,dic=dic, sort=EXT.KEY_TNEW)
            page_count = player.page_count(dic=dic)
            pid_list   = player.distince_filter(EXT.KEY_MONGO_ID, dic)
    pids = [item['_id'] for item in player_ret]
    attr = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_ATTR, host=g.mongo_host)
    attr_querys = {"pid":{"$in":pids}}
    attr_data = {}
    attr_ret = attr.filter(attr_querys)
    [attr_data.update({item['pid']:item['CBE']}) for item in attr_ret if 'CBE' in item]
    login = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    login_data = {}
    for p in pids:
        login_querys = {"p":p, "t":1}
        login_ret = login.last(login_querys)
        if login_ret:
            login_data[p] = login_ret['ct']

    user_coll = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    for p in player_ret:

        u = user_coll.find_one({'_id': p[EXT.KEY_UID]})
        if u:
            p['sns'] = SNS_MAP.get(u.get('sns', 0))
            p['sns_id'] = u.get('name', '')


    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'player_ret':player_ret, 'page':page,
             'page_count':page_count, 'stype':stype, 'playerId':playerId,
             'playerName':playerName, 'querys':querys, 'pid_list':pid_list,
             'attr_data':attr_data, 'login_data':login_data,'platform':game_config.SERVER_VER_CONFIG }


@user.route("/server/player/pay/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_player_pay():
    """ 角色查询 """
    STR_ALL = 'all'
    pid = request.args.get(EXT.KEY_PID, EXT.STRING_NONE)
    total_price  =0
    mongo  = MongoFive(g.GAMEBASE, EXT.COLL_PAY_LOG, g.mongo_host)
    querys = {EXT.KEY_PID:int(pid), EXT.KEY_SID: int(g.current_server.sid)}
    ret    = mongo.find(querys)
    per_price = []
    date_ticks = {}
    for r in ret:
        p = r['price']
        total_price += p
        per_price.append(p)
        t = r['ct']
        d = get_days(t)
        if d in date_ticks:
            date_ticks[d][1] = date_ticks[d][1] + p
        else:
            date_ticks[d] = [t, p]

    if date_ticks:
        un_sorted_pairs_val = date_ticks.values()
        sorted_pairs = sorted(un_sorted_pairs_val, key=lambda x: x[0])
        day_ticks, day_p = zip(*sorted_pairs)
    else:
        day_ticks, day_p = [], []

    return {'SIDEBAR': EXT.SIDEBAR_SERVER, 'total_price': total_price, 'pid': pid, 'per_price': per_price,
            'day_per_price': list(day_p), 'date_ticks': list(day_ticks), 'ret': ret}

@user.route("/server/player/action/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_player_action():
    """ 角色行为纪录 """
    KEY_PID = 'pid'
    KEY_CT  = 'ct'
    KEY_P   = 'p'
    KEY_T   = 't'
    ret = []
    pid = None
    page_count = 0
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = int(request.args.get(EXT.STRING_PAGE, 1))
    pid = request.args.get(KEY_PID, None)
    t = request.args.get(KEY_T, None)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
                          end_time_str, searchCondition=EXT.DATE_DAY, beforeDay=EXT.NUM_MONTH_DAYS)
    if pid:
        log_info = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
        if t:
            dic = { KEY_CT:{ EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time }, KEY_P:int(pid), KEY_T:int(t)}
        else:
            dic = { KEY_CT:{ EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time }, KEY_P:int(pid) }
        ret = log_info.paginate(page=page,dic=dic)
        page_count = log_info.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str, 'end_time':end_time_str, 'ret':ret,
             'page':page, 'page_count':page_count, 'pid':pid}

@user.route("/server/player/count/", methods = ("GET", "POST"))
@moderator.require(401)
@resp()
def server_player_count():
    """ 角色创建统计 """
    # 获取网页传递的数据
    e_name = FilterPlayer.get_pids()
    e_u_name = FilterPlayer.get_uids()
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)
    # 调用统计类进行统计
    from luffy.count import Count
    database = (g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, g.mongo_host)
    player_count = Count(start_time, end_time, database)
    # 根据类型进行统计
    time_format = get_format(searchCondition)

    # 过滤
    mongo_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    uids_query = {EXT.KEY_NAME:{EXT.MONGO_IN:e_u_name}}
    uids_ret = mongo_user.distince_filter(EXT.KEY_MONGO_ID, uids_query)
    querys_addition = {EXT.KEY_NAME:{EXT.MONGO_NOT:{EXT.MONGO_IN:e_name}},
                        EXT.KEY_UID:{EXT.MONGO_NOT:{EXT.MONGO_IN:uids_ret}}}

    ret = player_count.getCount(EXT.KEY_TNEW, time_format, querys_addition=querys_addition)
    keys = [format_date(item[0], time_format) for item in ret]
    rets = [item[1] for item in ret]
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'keys':keys,'rets':rets, 'start_time':start_time_str, \
            'end_time':end_time_str, 'searchCondition':searchCondition}


@user.route("/server/vip/info/", methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_vip_info():
    """ VIP信息查询 """
    playerList = []
    page_count = 0
    userList = None
    STRING_STYPE = 'stype'
    playerId = request.args.get(EXT.STRING_PLAYER_ID, EXT.STRING_NONE)
    playerName = request.args.get(EXT.STRING_PLAYER_NAME, EXT.STRING_NONE)
    page        = int(request.args.get(EXT.STRING_PAGE, EXT.NUMBER_ONE))
    stype       = request.args.get(STRING_STYPE, EXT.STRING_NONE)
    playerSearchList = [] #player查询条件
    if playerId:
        playerSearchList.append({EXT.KEY_MONGO_ID:int(playerId)})
    if playerName:
        playerSearchList.append({EXT.KEY_NAME:re.compile('.*'+playerName+'.*')})
    pdic = {EXT.KEY_VIP:{EXT.MONGO_GT:0} }
    if playerId or playerName and stype == EXT.STRING_NONE:
        pdic.update({EXT.MONGO_OR:playerSearchList})
    player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    if playerId or playerName or stype:
        playerList = player.paginate(page=page,dic=pdic, sort=EXT.KEY_TNEW)
        page_count = player.page_count(dic=pdic)
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'ret':playerList,'page':page,
            'page_count':page_count, 'stype':stype }

@user.route('/log/rpc/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_rpc():
    """ log_rpc统计 """
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_RPC, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    rpcRet = rpcConn.filter(dic=dic)
    ret = {}
    for r in rpcRet:
        if r['func'] in ret:
            ret[r['func']]['use'] += r['use']
            ret[r['func']]['total'] += r['total']
            ret[r['func']]['err'] += r['err']
        else:
            ret[r['func']] = { 'use':r['use'], 'total':r['total'], 'err':r['err'] }
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str, 'end_time':end_time_str, 't':t }

@user.route('/edit/plist/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='user/edit_plist.html')
def config_plist():
    """ plist 编辑"""
    import config as game_config
    base_config = game_config.BaseConfig()

    db = base_config.MONGOALCHEMY_DATABASE
    coll_name = 'platform'

    coll = MongoFive(db, coll_name, host=g.mongo_host)

    mid = request.args.get('mid', '')
    model = None
    if mid:
        oid = ObjectId(mid)
        model = coll.find_one({'_id': oid})

    if model:
        modelclass = type("modelform", (object,), model)
        editform = AppConfigForm(obj=modelclass)

    else:
        editform = AppConfigForm(request.form)

    kwargs = {'SIDEBAR': 'OP', 'form': editform, 'vertical': True}
    full_url = url_for('.config_plist', _external=True)
    url_prefix_idx = full_url.rfind('/user/')
    url_prefix = full_url[:url_prefix_idx]
    description = u'plist下载 地址. 例如: %s%s,, 其中plf参数为平台id' % \
                  (url_prefix, '/service/dlplatform/?plf=平台id')
    editform.platform.description = description
    if editform.validate_on_submit():
        key = 'platform'
        pdata = editform.data
        param = {'condition': {key: pdata[key]}, 'data': pdata}
        coll.update(param)
        flash(u'成功提交, 当前记录数目%s' % coll.count())
    data_entries = coll.find({})
    kwargs.update({'data': data_entries})
    return kwargs

@user.route('/log/user/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_user():
    """ 用户操作log """
    collection = ''
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
                    end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    if t != EXT.STRING_NONE:
        ret = UserLog.query.filter(UserLog.t>float(start_time),
              UserLog.t<float(end_time), UserLog.ty==int(t)).descending(UserLog.t).all()
    else:
        ret = UserLog.query.filter(UserLog.t>float(start_time),
              UserLog.t<float(end_time)).descending(UserLog.t).all()
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'end_time':end_time_str, 't':t }

@user.route('/log/online/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_online():
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_ONLINE, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t }


@user.route('/log/gm/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_gm():
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_GM, host=g.mongo_host)
    dic = {}
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t }


@user.route('/log/item/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_item():
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    pid = request.args.get(EXT.KEY_PID, "")
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_ITEM, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    if pid:
        dic.update({EXT.KEY_P:int(pid)})
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t,'pid':pid }


@user.route('/log/equip/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_equip():
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_EQUIP, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t }


@user.route('/log/info/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_info():
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t }


@user.route('/log/coin/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def log_coin():
    """钱币使用"""
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    page = request.args.get('page', 1)
    t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    if t != EXT.STRING_NONE:
        t = int(t)
        dic.update({EXT.KEY_T:t})
    ret = rpcConn.paginate(page=int(page), dic=dic)
    page_count = rpcConn.page_count(dic=dic)
    return { 'SIDEBAR':EXT.SIDEBAR_LOG, 'ret':ret, 'start_time':start_time_str,
             'page':int(page), 'page_count':page_count, 'end_time':end_time_str, 't':t }

@user.route('/log/coin/consume/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='user/query_consume_coin.html')
def query_consume_coin():
    """元宝消耗情况"""
    try:
        page = request.args.get('page', 1)
    except KEY_Error, ke:
        page = 1
    form = CoinQueryForm(request.form)
    query = {}
    map_func = """function(){
    required_f = {c1:this.c1, c2:this.c2, c3:this.c3};
    emit(this.p, required_f);
    }"""
    reduce_func = """function(key, countObjVals){
    reducedVal = {c1:0, c2:0, c3:0};
    for (var idx = 0; idx < countObjVals.length; idx++) {
                         reducedVal.c1 += countObjVals[idx].c1;
                         reducedVal.c2 += countObjVals[idx].c2;
                         reducedVal.c3 += countObjVals[idx].c3;
                     }
    return reducedVal;
    }
    """

    final_func = """function(key, final_value){
    final_value.p = key;
    final_value.ca = final_value.c2 + final_value.c3;
    return final_value;
    }
    """
    targetcoll = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    entries_list = []
    if request.method == 'POST':
        if form.date_beg.data and form.date_end.data:
            start_time = time.mktime(form.date_beg.data.timetuple())
            end_time = time.mktime(form.date_end.data.timetuple())
            end_time = end_time + EXT.NUM_UNIX_A_DAY -1
            query.update({EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}})
        if form.filter_coins_type.data == 1:
            query.update({EXT.MONGO_OR: [{EXT.KEY_T: {EXT.MONGO_LTE: 100}}, {EXT.KEY_T: 301}]})
        else:
            query.update({EXT.KEY_T: {EXT.MONGO_GT: 100, EXT.MONGO_LTE: 200}})
        if form.pid.data:
            query.update({EXT.KEY_P: form.pid.data})

        entries_list = targetcoll.inline_map_reduce(map_func, reduce_func, query=query, finalize=final_func)
        if form.coins_num.data:
            gt_k = {0: 'ca', 1: 'c2', 2: 'c3'}.get(form.filter_coins_gt.data, 0)
            gt_v = form.coins_num.data
            entries_list = [e for e in entries_list if e['value'][gt_k] >= gt_v]






    # t = request.args.get(EXT.KEY_T, EXT.STRING_NONE)
    # start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
    #     end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
    # rpcConn = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    # if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
    #     dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}}
    # if t != EXT.STRING_NONE:
    #     t = int(t)
    #     dic.update({EXT.KEY_T:t})
    # ret = rpcConn.paginate(page=int(page), dic=dic)
    # page_count = rpcConn.page_count(dic=dic)
    page = 1
    pages = 10
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'coins_items': entries_list,
            'page':int(page), 'page_count': pages, 'form': form}


@user.route('/server/rank/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_rank():
    rank = MongoFive(g.GAME_LOG, EXT.LOG_RANK, host=g.mongo_host)
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)

    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=1, searchCondition=searchCondition)

    t = int(request.args.get(EXT.STRING_STYPE , 1))
    query = {"t":t, "ct":{EXT.MONGO_GTE:start_time, EXT.MONGO_LTE:end_time}}
    ret = rank.filter(dic=query)
    ret = sorted(ret, reverse=True)
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
        'end_time':end_time_str, 'searchCondition':searchCondition,
        'ret':ret, 'stype':t }


#'玩家在线统计'
@user.route('/server/online/count/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_online_count():
    """ 在线角色统计 """
    STR_MAX, STR_MIN, STR_AVG = 'max', 'min', 'avg'
    # 从网页获取信息
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 转换时间格式
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUM_MONTH_DAYS, searchCondition=searchCondition)
    from luffy.count import OnlineCount
    database = (g.GAME_LOG, EXT.LOG_ONLINE, g.mongo_host)
    login_count = OnlineCount(start_time, end_time, database, searchCondition)
    # 根据类型进行统计
    time_format = get_format(searchCondition)
    ret = login_count.get_ret(EXT.KEY_CT, EXT.KEY_C)

    keys = [format_date(item[0], time_format) for item in ret]
    max_rets = [item[1][STR_MAX] for item in ret]
    min_rets = [item[1][STR_MIN] for item in ret]
    avg_rets = [item[1][STR_AVG] for item in ret]

    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
        'end_time':end_time_str, 'keys':keys, 'max_rets':max_rets,
        'min_rets':min_rets, 'searchCondition':searchCondition,
        'avg_rets':avg_rets }

@user.route('/server/online/pertime/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_online_pertime():
    """在线角色平均时长"""
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    time_format = get_format(searchCondition)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, beforeDay=EXT.NUM_MONTH_DAYS, searchCondition=searchCondition)
    player = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    condition = {EXT.KEY_T:{"$in":[1,2]}, EXT.KEY_CT:{"$gte":start_time, "$lte":end_time}}
    querys = player.find(condition)
    #格式为
    # {
    # "时期":     {玩家id1:  [[上线时间1,上线时间2], [下线时间1,下线时间2]]},
    # 2013-06-26:{pid1:     [ [login1,  login2],   [logout1,  logout2]], pid2:[[login1, login2],[logout1, logout2]]},
    # }
    date_dict = {}
    for query in querys:
        login_t = query[EXT.KEY_CT]
        ct = time.localtime(login_t)
        dt = time.strftime(time_format, ct)
        pid = query[EXT.KEY_P]
        pid_logtime = date_dict.setdefault(dt, {})
        log_list = pid_logtime.setdefault(pid, [[],[]])
        log_list[query[EXT.KEY_T] - 1].append(login_t)
    sum_pids = {}
    times_dict = {}
    for dt, pid_dics in date_dict.iteritems():              #补齐凌晨的数据
        sum_pids[dt] = len(pid_dics)
        times_lis = times_dict.setdefault(dt, [])
        t = datetime.datetime.strptime(dt, time_format)
        t_zero = time.mktime(t.timetuple())                 #今日凌晨
        n_zero = t_zero + 86400                             #明日凌晨
        for pid, login_list in pid_dics.iteritems():
            times_lis.append(login_list)
            in_list,out_list = login_list
            if len(in_list) == len(out_list):
                #上线下线对称，可不用管
                continue
            else:
                add_num = len(in_list) - len(out_list)
                if add_num > 0:
                    #玩家今日在0晨左右上线未下线
                    for i in range(add_num):
                        out_list.append(n_zero)
                else:
                    #玩家在昨天0晨左右上线未下线
                    for i in range(abs(add_num)):
                        in_list.append(t_zero)
    per_times = {}
    from ..helps import time_range
    time_list = times_dict.keys()
    time_list.sort()
    keys = []
    pids = []
    for dt in time_list:
        pids.append(sum_pids[dt])
        time_lis = times_dict[dt]
        in_sum_t  = 0
        out_sum_t = 0
        for in_list, out_list in time_lis:
            for in_t in in_list:
                in_sum_t += in_t
            for out_t in out_list:
                out_sum_t += out_t
        t = int((out_sum_t - in_sum_t)/sum_pids[dt])
        keys.append(t)
        per_times[dt] = time_range(t)+'---平均'+str(t)+'秒'
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
             'end_time':end_time_str, 'searchCondition':searchCondition,
             'time_list':time_list, 'sum_pids':sum_pids, 'per_times':per_times,
             'keys':keys, 'pids':pids
    }

#'资金流转'
@user.route('/server/user/money/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_user_money():
    """ 玩家资金流转 """
    KEY_SEARCH_TYPE         = 'searchType'
    page_count              = 0
    coinRet                 = None
    playerId = request.args.get(EXT.STRING_PLAYER_ID, EXT.STRING_NONE)
    if playerId != EXT.STRING_NONE:
        playerId = int(playerId)
    playerName = request.args.get(EXT.STRING_PLAYER_NAME, EXT.STRING_NONE)
    page = int(request.args.get(EXT.STRING_PAGE, EXT.NUMBER_ONE))
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=EXT.DATE_DAY)
    if playerId == EXT.STRING_NONE and playerName != EXT.STRING_NONE:
        player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
        condation = { EXT.KEY_NAME:playerName }
        player = player.find_one(condation)
        playerId = player[EXT.KEY_MONGO_ID]
    coin = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    if start_time_str != EXT.STRING_NONE and end_time_str != EXT.STRING_NONE:
        dic = {EXT.KEY_CT: {EXT.MONGO_LT:end_time, EXT.MONGO_GT:start_time}, EXT.KEY_P:playerId }
        searchType = int(request.args.get(KEY_SEARCH_TYPE, EXT.NUMBER_ONE))
        if searchType == EXT.NUMBER_ONE:
            coinRet = coin.paginate(page=page,dic=dic)
            page_count = coin.page_count(dic=dic)
        else:
            tmp_coinRet = {}
            coinRet = coin.filter(dic=dic)
            for r in coinRet:
                if r[EXT.KEY_T] in tmp_coinRet:
                    if EXT.KEY_C1 in r:
                        tmp_coinRet[r[EXT.KEY_T]][EXT.KEY_C1] += r[EXT.KEY_C1]
                    if EXT.KEY_C2 in r:
                        tmp_coinRet[r[EXT.KEY_T]][EXT.KEY_C2] += r[EXT.KEY_C2]
                    if EXT.KEY_C3 in r:
                        tmp_coinRet[r[EXT.KEY_T]][EXT.KEY_C3] += r[EXT.KEY_C3]
                else:
                    if EXT.KEY_C1 in r:
                        C1 = r[EXT.KEY_C1]
                    else:
                        C1 = 0
                    if EXT.KEY_C2 in r:
                        C2 = r[EXT.KEY_C2]
                    else:
                        C2 = 0
                    if EXT.KEY_C3 in r:
                        C3 = r[EXT.KEY_C3]
                    else:
                        C3 = 0
                    tmp_coinRet[r[EXT.KEY_T]] = { EXT.KEY_C1:C1, EXT.KEY_C2:C2,
                                                  EXT.KEY_C3:C3, EXT.KEY_P:r[EXT.KEY_P],
                                                  EXT.KEY_T:r[EXT.KEY_T] }
            coinRet = tmp_coinRet.values()
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'coinRet':coinRet, 'page':page, 'page_count':page_count,'searchType':searchType, \
            'start_time':start_time_str, 'end_time':end_time_str, 'playerId':playerId, 'playerName':playerName }

#'所有玩家等级分布'
@user.route('/server/all/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_level():
    """ 所有玩家等级分布 """
    levelList = []
    valueList = []
    startLevel = int(request.args.get('startLevel','1'))-1
    endLevel = int(request.args.get('endLevel','100'))+1
    player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    e_name = FilterPlayer.get_pids()
    e_list = FilterPlayer.get_uids()
    user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    e_u_query = {'name':{'$in':e_list}}
    e_user = user.distince_filter('_id', e_u_query)
    e_query = {'uid':{'$in':e_user}}
    e_player = player.distince_filter('_id', e_query)
    e_query = {'name':{'$in':e_name}}
    e_player2 = player.distince_filter('_id', e_query)
    e_player = list(set(e_player)|set(e_player2))
    key = {"level": True}
    initial = {"countlevel": 0}
    red = Code("function(obj,prev){prev.countlevel++;}")
    condition = {"level": {"$gt": startLevel,"$lt": endLevel},
                    "_id":{"$not":{"$in":e_player}}}
    ret = player.group(key, condition, initial, red)
    ret.sort(key=lambda x:x['level'])
    for r in ret:
        levelList.append(int(r['level']))
        valueList.append(int(r['countlevel']))
    #    =========统计等级=========
    # import pyExcelerator
    # from luffy.helps import time_range
    # querys = {'level':1}
    # tmp = player.distince_filter('_id', querys)
    # log_info = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    # w = pyExcelerator.Workbook()
    # ws = w.add_sheet('sheet1')
    # ws.write(0, 0, u'角色id')
    # ws.write(0, 1, u'登陆时间')
    # ws.write(0, 2, u'退出时间')
    # ws.write(0, 3, u'停留时间')
    # ws.write(0, 4, u'最后完成任务')
    # i = 1
    # for t in tmp:
    #     log_ret = log_info.filter(dic={'p':t, 't':{'$in':[1,2]}}, sort='ct')
    #     last_task = log_info.last(dic={'p':t, 't':4})
    #     #        print 'last_task==========', last_task
    #     tmp = {}
    #     while len(log_ret) >= 2:
    #         login = log_ret.pop(0)
    #         tmp['p'] = login['p']
    #         tmp['login'] = login['ct']
    #         logout = log_ret.pop(0)
    #         tmp['logout'] = logout['ct']
    #         if 'login' in tmp and 'logout' in tmp:
    #             ws.write(i, 0, tmp['p'])
    #             ws.write(i, 1, format_date(tmp['login'], '%Y-%m-%d %H:%M:%S'))
    #             ws.write(i, 2, format_date(tmp['logout'], '%Y-%m-%d %H:%M:%S'))
    #             print "time_range(tmp['logout']-tmp['login']):", time_range(tmp['logout']-tmp['login'])
    #             ws.write(i, 3, time_range(tmp['logout']-tmp['login']))
    #             if last_task and 'tid' in last_task:
    #                ws.write(i, 4, last_task['tid'])
    #             tmp = {}
    #             i += 1
    # w.save('lv1count.xls')
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'levelList':levelList, 'valueList':valueList,
            'startLevel':startLevel+1, 'endLevel':endLevel-1, 'ret':ret }

@user.route('/server/all/coin/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_coin():
    """ 所有玩家资金消费分布 """
    cateList = []
    c1List = []
    c2List = []
    c3List = []
    all_count = {}
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    start_time_str, end_time_str, start_time, end_time = FiveMethods.get_time(searchCondition)
    print start_time_str, end_time_str, start_time, end_time
    coin = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    from luffy.count import count_coin
    key = {"t": True }
    initial = {"sumc1": 0,"sumc2": 0,"sumc3": 0}
    red = Code("function(obj,prev){prev.sumc1 += obj.c1;prev.sumc2 += obj.c2;prev.sumc3 += obj.c3;}")
    condition = {"t": {"$gt": 0,"$lt": 100}, 'ct':{'$gte':start_time, '$lt':end_time}}
    ret = coin.group(key, condition, initial, red)
    for r in ret:
        cateList.append(int(r['t']))
        c1List.append(int(r[EXT.COIN_SUMC1]))
        c2List.append(int(r[EXT.COIN_SUMC2]))
        c3List.append(int(r[EXT.COIN_SUMC3]))
        count_coin(r, all_count)
    pid_count = len(coin.distince_filter(EXT.KEY_P, condition))
    # =============== 获取的资金 ==================
    get_count = {}
    key = {"t": True }
    initial = {"sumc1": 0,"sumc2": 0,"sumc3": 0}
    red = Code("function(obj,prev){prev.sumc1 += obj.c1;prev.sumc2 += obj.c2;prev.sumc3 += obj.c3;}")
    condition = {"t": {"$gt": 100,"$lt": 200}, 'ct':{'$gte':start_time, '$lt':end_time}}
    add_ret = coin.group(key,condition, initial, red)
    for r in add_ret:
        count_coin(r, get_count)
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'cateList':cateList, 'c1List':c1List,
        'c2List':c2List, 'c3List':c3List, 'all_count':all_count, 'pid_count':pid_count,
        'get_count':get_count, 'start_time':start_time_str, 'end_time':end_time_str }

@user.route('/server/all/coin/count/time/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_coin_count_time():
    """ 所有玩家资金消费分布 """
    cateList = []
    c1List = []
    c2List = []
    c3List = []
    all_count = {}
    STR_C1, STR_C2, STR_C3, STR_P = 'c1', 'c2', 'c3', 'p'
    start_time_str = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(
        start_time_str, end_time_str,beforeDay=EXT.NUMBER_SEVEN,
        searchCondition=EXT.DATE_DAY)
    coin = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    from luffy.count import CoinCount
    coin_count = CoinCount(coin, start_time, end_time)
    keys, c1s, c2s, c3s, pids = [], [], [], [], []
    for item in coin_count.getRet():
        keys.append(item[0])
        c1s.append(item[1][STR_C1])
        c2s.append(item[1][STR_C2])
        c3s.append(item[1][STR_C3])
        pids.append(item[1][STR_P])
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'keys':keys, 'c1s':c1s, 'c2s':c2s,
                'c3s':c3s, 'pids':pids}

#'所有玩家资金消费时间分布'
@user.route('/server/all/coin/time/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_coin_time():
    """ 所有玩家资金消费时间分布 """
    cateList = []
    c1List = []
    c2List = []
    c3List = []
    typeList = []
    lastRet = {}
    keyDict = {}
    ctype = int(request.args.get('ctype',1))

    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 统计类型
    time_format     = get_format(searchCondition)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
                end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=searchCondition)
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)
    from luffy.count import CoinCount
    # 资金使用量
    coin            = MongoFive(g.GAME_LOG, EXT.LOG_COIN, host=g.mongo_host)
    querys_addition = { EXT.KEY_T:ctype }
    coin_count      = CoinCount(coin, start_time, end_time, querys_addition)
    coin_ret        = coin_count.getRet(p_count=False, time_format=time_format)
    cateList = [k[0] for k in coin_ret]
    c1List = [k[1][EXT.KEY_C1] for k in coin_ret]
    c2List = [k[1][EXT.KEY_C2] for k in coin_ret]
    c3List = [k[1][EXT.KEY_C3] for k in coin_ret]
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'cateList':cateList, 'c1List':c1List,
             'c2List':c2List, 'c3List':c3List, 'ctype':ctype, 'start_time':start_time_str,
             'end_time':end_time_str, 'time_format':time_format }

#玩家任务完成分布
@user.route('/server/all/task/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_task():
    """ 玩家任务完成分布 """
    cateList = []
    countList = []
    startTask = int(request.args.get('startTask','1'))-1
    endTask = int(request.args.get('endTask','10'))+1
    task = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    key = {"tid": True}
    initial = {"countstar": 0}
    red = Code("function(obj,prev){prev.countstar++;}")
    condition = {"tid": {"$gt": startTask,"$lt": endTask}, "t":4}
    ret = task.group(key,condition, initial, red)
    ret.sort(key=lambda d:d['tid'])
    for r in ret:
        cateList.append(int(r['tid']))
        countList.append(int(r['countstar']))
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'startTask':startTask+1, 'endTask':endTask-1, 'cateList':cateList, 'countList':countList }

@user.route('/server/all/get/task/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_get_task():
    """ 玩家任务接受分布 """
    cateList = []
    countList = []
    startTask = int(request.args.get('startTask','1'))-1
    endTask = int(request.args.get('endTask','10'))+1
    task = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)

    key = {"tid": True}
    initial = {"countstar": 0}
    red = Code("function(obj,prev){prev.countstar++;}")
    condition = {"tid": {"$gt": startTask,"$lt": endTask}, "t":-4}
    ret = task.group(key,condition, initial, red)
    ret.sort(key=lambda x:x['tid'])
    for r in ret:
        cateList.append(int(r['tid']))
        countList.append(int(r['countstar']))
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'startTask':startTask+1, 'endTask':endTask-1, 'cateList':cateList, 'countList':countList }

@user.route('/server/all/prologue/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def server_all_prologue():
    """ 统计进入章节人数 """
    cateList = []
    countList = []

    startTask = int(request.args.get('startTask','1'))-1
    endTask = int(request.args.get('endTask','10'))+1
    task = MongoFive(g.GAME_LOG, EXT.LOG_INFO, host=g.mongo_host)
    #    dic = { 't':4, 'tid':{ '$gt': startTask, '$lt':endTask } }
    key = {"d.chapter": True}
    initial = {"countstar": 0}
    red = Code("function(obj,prev){prev.countstar++;}")
    condition = {"d.chapter": {"$gt": startTask,"$lt": endTask}, "t":12}
    ret = task.group(key,condition, initial, red)
    ret.sort(key=lambda x:x['d.chapter'])
    for r in ret:
        cateList.append(int(r['d.chapter']))
        countList.append(int(r['countstar']))
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'startTask':startTask+1, 'endTask':endTask-1, 'cateList':cateList,
             'countList':countList }

@user.route('/server/create/player/count/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def server_create_player_count():
    """ 创建角色统计 """
    KEY_UID = 'uid'
    KEY_MAC = 'MAC'
    mongo_user  = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    uid_count   = len(mongo_user.distince(KEY_MAC))
    user_count = mongo_user.count()
    mongo_player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    user_list_count = len(mongo_player.distince(KEY_UID))
    player_count = mongo_player.count()
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'user_count':user_count, 'user_list_count':user_list_count,
            'player_count':player_count, 'uid_count':uid_count }

@user.route('/retention/rate/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def retention_rate():
    """ 留存率 """
    D_U = 'd.u'
    from luffy.models import RetentionCount2, RetentionCount7, RetentionCount15
    from luffy.models import get_r, c2dict
    global ic_retention2, ic_retention7, ic_retention15
    # 时间格式转换
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    start_time_str, end_time_str, start_time, end_time = FiveMethods.get_time(searchCondition)
    # 统计类型
    time_format     = get_format(searchCondition)
    time_list = range_list(start_time, end_time, EXT.NUM_UNIX_A_DAY)
    # ==========次日留存率
    # 从数据库获取统计结果
    ret_2 = RetentionCount2.query.filter(RetentionCount2.t>=start_time, RetentionCount2.t<=end_time,
        RetentionCount2.s==g.GAME_BASEUSER).all()
    # 时间范围内存在的纪录时间集
    had_time_2 = RetentionCount2.query.filter(RetentionCount2.t>=start_time,
            RetentionCount2.t<=end_time, RetentionCount2.s==g.GAME_BASEUSER).distinct(RetentionCount2.t)
    need_check_2 = list(set(time_list)-set(had_time_2))
    # 去获取数据并写入数据库
    if need_check_2:
        ic_retention2 = False
        get_r(need_check_2, time_format, searchCondition, 2)
        ic_retention2 = True

    # ==========7日留存率
    # 从数据库获取统计结果
    ret_7 = RetentionCount7.query.filter(RetentionCount7.t>=start_time, RetentionCount7.t<=end_time,
        RetentionCount7.s==g.GAME_BASEUSER).all()
    # 时间范围内存在的纪录时间集
    had_time_7 = RetentionCount7.query.filter(RetentionCount7.t>=start_time,
            RetentionCount7.t<=end_time, RetentionCount7.s==g.GAME_BASEUSER).distinct(RetentionCount7.t)
    need_check_7 = list(set(time_list)-set(had_time_7))
    if need_check_7:
        ic_retention7 = False
        get_r(need_check_7, time_format, searchCondition, 7)
        ic_retention7 = True

    # ==========15日留存率
    # 从数据库获取统计结果
    ret_15 = RetentionCount15.query.filter(RetentionCount15.t>=start_time, RetentionCount15.t<=end_time,
        RetentionCount15.s==g.GAME_BASEUSER).all()
    # 时间范围内存在的纪录时间集
    had_time_15 = RetentionCount15.query.filter(RetentionCount15.t>=start_time,
            RetentionCount15.t<=end_time, RetentionCount15.s==g.GAME_BASEUSER).distinct(RetentionCount15.t)
    need_check_15 = list(set(time_list)-set(had_time_15))
    if need_check_15:
        ic_retention15 = False
        get_r(need_check_15, time_format, searchCondition, 15)
        ic_retention15 = True
    r2, r7, r15 = c2dict(ret_2, ret_7, ret_15)
    return { 'SIDEBAR':EXT.SIDEBAR_SERVER, 'start_time':start_time_str,
    'end_time':end_time_str,'searchCondition':searchCondition,
    'time_list':time_list, 'r2':r2, 'r7':r7, 'r15':r15,"renRate":RenRate()}

@user.route('/exchange/count/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def exchange_count():
    STRING_CODE = 'code'
    STRING_ALL  = 'all'
    STRING_PID  = 'pid'
    page_count = 0
    page    = int(request.args.get(EXT.STRING_PAGE, EXT.NUMBER_ONE))
    stype   = request.args.get(EXT.STRING_STYPE, EXT.STRING_NONE)
    code    = request.args.get(STRING_CODE, EXT.STRING_NONE)
    pid     = request.args.get(STRING_PID, EXT.STRING_NONE)
    mongo   = MongoFive(g.GAMEBASE, EXT.COLL_EXCHANGE_LOG, host=g.mongo_host)
    querys = {}
    if stype != STRING_ALL and code != EXT.STRING_NONE:
        querys  = {STRING_CODE:code}
    if pid:
        querys.update({STRING_PID:int(pid)})
    if querys == {}: querys = None
    ret = mongo.paginate(page=page, dic=querys)
    page_count = mongo.page_count(dic=querys)
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'page':page, 'page_count':page_count,
            'ret':ret}

@user.route('/mac/count/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def mac_count():
    """ 根据mac地址进行统计 """
    request_name = 'xlsfile'
    all_file = None
    xlsfile = request.files.get(request_name)
    database_addr = (g.GAME_BASEUSER, g.mongo_host, g.GAME_LOG)
    file_path = xlsupload(xlsfile, user, save_mongo=False, database_addr=database_addr)
    mac_path = ''.join([os.path.dirname(user.root_path), '/static/xlsdatabase/'])
    mac_path = ''.join([mac_path,"/mac"])
    if file_path:
        from luffy.models import mac2count
        try:
            mac2count(file_path, database_addr)
        except:
            print_traceback()
        finally:
            os.remove(file_path)
    if xlsupload(xlsfile, user, save_mongo=False, database_addr=database_addr):
        return redirect(url_for('user.mac_count'))
    if os.path.isdir(mac_path):
        all_file = os.listdir(mac_path)
        all_file = [item for item in all_file if not item.startswith('.')]
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'allFile':all_file}


@user.route('/mac/compare/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def mac_compare():
    """ 根据mac地址进行统计 """
    import xlrd
    request_name = 'xlsfile'
    count = None
    all_file = None
    xlsfile = request.files.get(request_name)
    database_addr = (g.GAME_BASEUSER, g.mongo_host, g.GAME_LOG)
    file_path = xlsupload(xlsfile, user, save_mongo=False)
    start_time_str, end_time_str = '1955-01-01', ''
    if file_path:
        xl = xlrd.open_workbook(file_path)
        mac_list = []
        for s in xrange(len(xl.sheets())):
            sheet = xl.sheet_by_index(s)
            for row in xrange(sheet.nrows):
                if row == 0:
                    start_time_str = sheet.cell_value(row, 0)
                    end_time_str = sheet.cell_value(row, 1)
                else:
                    mac_list.append(sheet.cell_value(row, 0))
        start_time_str, end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
                    end_time_str, beforeDay=EXT.NUMBER_SEVEN, searchCondition=EXT.DATE_DAY)
        servers = ['zl_1', 'bd91_1', 'app_1', 'app_2', 'app_3']
        t_query = {'tNew':{'$gte':start_time, '$lt':end_time}}
        last_s = {}
        for s in servers:
            mongo   = MongoFive(s, EXT.BASEUSER_USER, host=g.mongo_host)
            query = {'MAC':{'$in':mac_list}}
            if start_time_str != '1955-01-01':
                print 'start_time_str != 1955-01-01*****'
                query.update(t_query)
            last_s[s] = mongo.distince_filter('MAC', query)
        count = len(set(last_s['zl_1'])|set(last_s['bd91_1'])|set(last_s['app_1'])|set(last_s['app_2'])|set(last_s['app_3']))
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'count':count}

@user.route('/server/pay/count/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def server_pay_count():
    """ 根据mac地址进行统计 """
    from luffy.models import get_pay_log
    start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)
    return {'SIDEBAR':EXT.SIDEBAR_SERVER,"start_time":start_time_str,
        "end_time":end_time_str}

@user.route('/server/pay/count/create/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def server_pay_count_create():
    """ 根据mac地址进行统计 """
    from luffy.models import get_pay_log
    file_path = ''.join([os.path.dirname(user.root_path), '/static/xlsdatabase/pay.xls'])
    start_time_str  = request.form.get(EXT.START_TIME, EXT.STRING_NONE)
    end_time_str    = request.form.get(EXT.END_TIME, EXT.STRING_NONE)
    searchCondition = request.form.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)
#    ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
    get_pay_log(file_path, start_time, end_time)
    return { 'success':1, 'file_path':file_path}

@user.route('/last/login/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def last_login():
    """ 上次 """
    STRING_SNS, STRING_UDID = 'sns', 'MAC'
    zl = request.args.get('zl', 'app_1')
    new_user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
    old_user = MongoFive(zl, EXT.BASEUSER_USER, host=g.mongo_host)
    # 91帐号
    user_query = {STRING_SNS:1}
    news = new_user.distince_filter(EXT.KEY_NAME, user_query)
    olds = old_user.distince_filter(EXT.KEY_NAME, user_query)
    sns91 = len(set(news)&set(olds))
    # UUID
    news = new_user.distince(STRING_UDID)
    olds = old_user.distince(STRING_UDID)
    uuid = len(set(news)&set(olds))
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'sns91':sns91, 'uuid':uuid}

@user.route('/app/mac/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def app_mac():
    """ 上次 """
    zl, bd91, app = "zl_1", "bd91_1", "app_1"

    start_time_str  = request.form.get(EXT.START_TIME, "2013-06-15")
    end_time_str    = request.form.get(EXT.END_TIME, "2013-06-15")
    searchCondition = request.form.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)

    zl_user = MongoFive(zl, EXT.BASEUSER_USER, host=g.mongo_host)
    bd91_user = MongoFive(bd91, EXT.BASEUSER_USER, host=g.mongo_host)
    app_user = MongoFive(app, EXT.BASEUSER_USER, host=g.mongo_host)
    # 91帐号
    user_query = {"tNew":{EXT.MONGO_GTE:start_time, EXT.MONGO_LTE:end_time}}
    zl_mac = zl_user.distince("MAC")
    bd91_mac = bd91_user.distince("MAC")
    app_mac = app_user.distince_filter("MAC", user_query)

    all_mac = list(set(zl_mac)&set(bd91_mac))

    start_time += 86400
    end_time += 86400
    login = MongoFive("app_1_log", "log_info", host=g.mongo_host)
    querys = {"ct":{EXT.MONGO_GTE:start_time, EXT.MONGO_LTE:end_time},"t":1}
    login16 = login.filter(querys)
    login_uid = []
    for item in login16:
        login_uid.append(item['d']['u'])
    querys = {"_id":{"$in":list(set(login_uid))}}
    login_mac = app_user.distince_filter("MAC", querys)

    login_nums = len(set(all_mac)&set(login_mac))

    from_zl = len(set(zl_mac)&set(app_mac))
    from_bd91 = len(set(bd91_mac)&set(app_mac))

    return {'from_zl':from_zl, 'from_bd91':from_bd91, 'app_nums':len(app_mac),
            'login_nums':login_nums}

@user.route('/player/info/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def player_info():
    """  """
    import pyExcelerator
    from luffy.models import create_ws
    querys = {EXT.KEY_LEVEL:{EXT.MONGO_GT:40}}
    players = g.mongo_drive.all(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, querys)
    ret = []
    for p in players:
        mac_querys = {EXT.KEY_MONGO_ID:p[EXT.KEY_UID]}
        user = g.mongo_drive.find_one(g.GAME_BASEUSER, EXT.BASEUSER_USER, mac_querys)
        if user and EXT.KEY_MAC in user:
            p.update({EXT.KEY_MAC:user[EXT.KEY_MAC]})
        ret.append(p)
    keys = [EXT.KEY_NAME, EXT.KEY_LEVEL, EXT.KEY_MAC]
    w, ws = create_ws(*keys)
    j = 1
    for r in ret:
        ws.write(j, 0, r[EXT.KEY_NAME])
        ws.write(j, 1, r[EXT.KEY_LEVEL])
        if EXT.KEY_MAC in r:
            ws.write(j, 2, r[EXT.KEY_MAC])
        j += 1
    w.save('/home/game/mac3.xls')
    return {'SIDEBAR':EXT.SIDEBAR_SERVER}


@user.route('/per/pay/count/', methods=('GET', 'POST'))
@moderator.require(401)
@resp()
def per_pay_count():
    """  """
    def r_add(x, y):
        return x + y

    platform_type = int(request.args.get(EXT.STRING_STYPE, -1))
    start_time_str  = request.args.get(EXT.START_TIME, "")
    end_time_str    = request.args.get(EXT.END_TIME, "")
    searchCondition = request.args.get(EXT.SEARCH_COND, EXT.DATE_DAY)
    # 时间格式转换
    start_time_str,end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
        end_time_str, searchCondition=searchCondition)
    q = {}

    if platform_type != -1:
        q.update({EXT.KEY_T: platform_type})
    q.update({EXT.KEY_CT:{EXT.MONGO_GTE:start_time, EXT.MONGO_LT:end_time}})

    ex_q = {EXT.KEY_SID: int(g.current_server.sid)}
    q.update(ex_q)

    pay = MongoFive(g.GAMEBASE, EXT.COLL_PAY_LOG, host=g.mongo_host)
    player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
    key = {"pid": True}
    initial = {"sumprice": 0}
    red = Code("function(obj, prev) {prev.sumprice += obj.price;}")
    ret = pay.group(key, q, initial, red)
    all_price = [item['sumprice'] for item in ret]
    if len(all_price) != 0:
        all_pay = reduce(r_add, all_price)
    else:
        all_pay = 0

    pids = [int(item['pid']) for item in ret]
    querys = {EXT.KEY_MONGO_ID:{EXT.MONGO_IN:pids}}
    shows = {'_id':1, 'level':1, 'vip':1, 'name':1}
    info = player.filter(querys, shows)
    all_uids = len(player.distince_filter('uid', querys))
    infos = {}
    [infos.update({item.pop('_id'):item}) for item in info]
    return {'SIDEBAR':EXT.SIDEBAR_SERVER, 'ret':ret, 'infos':infos,
            'all_pay':all_pay, 'all_uids':all_uids, 'pt': platform_type,
            "start_time":start_time_str, "end_time":end_time_str}

# @user.route('/del/user/', methods=('GET', 'POST'))
# @moderator.require(401)
# @resp(ret='json')
# def del_user():
#     player = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, host=g.mongo_host)
#     user = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_USER, host=g.mongo_host)
#     uids = player.distince('uid')
#     query = {'_id':{'$not':{'$in':uids}}}
#     dels = user.distince_filter('_id', query)
#     for d in dels:
#         user.delete(d)
#     return {}



@user.route('/app/dev/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def app_dev():
    ret = {}
    users = g.mongo_drive.all(g.GAME_BASEUSER, 'user')
    for u in users:
        if 'tNew' not in u or 'DEV' not in u:
            continue
        t = time_to_hour(u['tNew'], EXT.UNIX_TIME_YMD_FORMAT)
        t = format_date(t, '%Y-%m-%d')
        ipod = u['DEV'].find('iPod')
        iphone = u['DEV'].find('iPhone')
        ipad = u['DEV'].find('iPad')
        if t in ret:
            if ipod != -1 or iphone != -1:
                if 'iphone' in ret[t]:
                    ret[t]['iphone'] += 1
                else:
                    ret[t]['iphone'] = 1
            elif ipad != -1:
                if 'ipad' in ret[t]:
                    ret[t]['ipad'] += 1
                else:
                    ret[t]['ipad'] = 1
        else:
            ret[t] = {}
            if ipod != -1 or iphone != -1:
                ret[t]['iphone'] = 1
            elif ipad != -1:
                ret[t]['ipad'] = 1
        # if t in ret:
        #     if u['DEV'] in ret[t]:
        #         ret[t][u['DEV']] += 1
        #     else:
        #         ret[t][u['DEV']] = 1
        # else:
        #     ret[t] = {}
        #     ret[t][u['DEV']] = 1
    ret = sorted(ret.items(), key=lambda d:d[0])
    return {'ret':ret}

@user.route('/logout/', methods=('GET', 'POST'))
@moderator.require(401)
def logout():
    identity_changed.send(current_app._get_current_object(),identity=AnonymousIdentity())
    next_url = request.args.get('next','')
    if not next_url or next_url == request.path:
        next_url = url_for("frontend.index")
    return redirect(next_url)

class FiveMethods():
    @staticmethod
    def get_time(searchCondition=EXT.DATE_DAY, beforeDay=EXT.NUMBER_SEVEN):
        start_time_str  = request.args.get(EXT.START_TIME, EXT.STRING_NONE)
        end_time_str    = request.args.get(EXT.END_TIME, EXT.STRING_NONE)
        start_time_str, end_time_str, start_time, end_time = FiveMethods.dealTime(start_time_str,
            end_time_str, beforeDay=beforeDay, searchCondition=searchCondition)
        return start_time_str, end_time_str, start_time, end_time

    @staticmethod
    def dealTime(start_time_str = '', end_time_str = '', beforeDay=EXT.NUM_MONTH_DAYS,
                 searchCondition='hour'):
        """时间处理，将格式为2012-12-21转换为unix时间截"""
        if start_time_str != '' and end_time_str != '':
            start_time = time.mktime(time.strptime(start_time_str, EXT.UNIX_TIME_YMD_FORMAT))
            end_time = time.mktime(time.strptime(end_time_str, EXT.UNIX_TIME_YMD_FORMAT))
            if searchCondition == 'hour':
                start_time = end_time - EXT.NUM_UNIX_A_DAY
                start_time_str = time.strftime(EXT.UNIX_TIME_YMD_FORMAT,time.localtime(start_time))
            end_time += EXT.NUM_UNIX_A_DAY-1
        else:
            if start_time_str == '':
                start_time = time.mktime(datetime.date.today().timetuple()) -EXT.NUM_UNIX_A_DAY*beforeDay
            else:
                start_time = time.mktime(time.strptime(start_time_str, EXT.UNIX_TIME_YMD_FORMAT))
            end_time = time.mktime(datetime.date.today().timetuple()) + EXT.NUM_UNIX_A_DAY-1
            start_time_str = time.strftime(EXT.UNIX_TIME_YMD_FORMAT,time.localtime(start_time))
            end_time_str = time.strftime(EXT.UNIX_TIME_YMD_FORMAT,time.localtime(end_time))
        return start_time_str, end_time_str, start_time, end_time

