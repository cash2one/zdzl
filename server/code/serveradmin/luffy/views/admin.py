#coding=utf-8
from functools import partial
import json
from flask import Blueprint,g, render_template, request, current_app, redirect, url_for
from flask import jsonify
from luffy.resp import resp
from luffy.models import AdminUser,MongoFive, xls2mongo, Servers, code2mongo
from bson.objectid import ObjectId
from datetime import date,timedelta,datetime
from time import mktime, time
from luffy.permissions import administrator as p_admin, auth, moderator
import luffy.define as EXT
from luffy.helps import xlsupload, pop_id, print_traceback
from werkzeug import secure_filename
import os
import config as game_config
from luffy.viewsmethods import from_html
from luffy.forms.cp import FilterActivityForm
from luffy.forms.cp import LangForm
from luffy.models import Servers
from luffy.models.u import LangConf
from luffy.models.u import PathMap
from luffy.models.u import LangMap
from luffy.models.u import AnyDoc
from luffy.models.u import RewardSetForm
from luffy.models.u import ActivitySetting
from luffy.models.u import AwarWorldAssess,AwarWorldScore,AwarNpcConfig,AwarPerConfig, \
                            AwarStartConfig,AwarBook,BoatExchange,BoatLevel, AwarStrongMap

from flask.ext.mongoengine import Pagination
from luffy.helps import md5

from mongoengine.context_managers import switch_db, switch_collection
admin = Blueprint('admin', __name__,static_folder='static')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1] in ['xls', 'xlsx']

@admin.route("/", methods = ("GET", "POST"))
@moderator.require(401)
@resp()
def index():
    SIDEBAR = 'SERVER_STATUS'
    ret = {}
    admin_index = 'dont who'
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'admin_index':admin_index }

@admin.route("/show/", methods = ("GET", "POST"))
@moderator.require(401)
@resp(template="admin/index.html")
def index_show():
    SIDEBAR = 'SERVER_STATUS'
    ret = {}
    return { 'ret':ret, 'SIDEBAR':SIDEBAR }

@admin.route("/translation/op_content/", methods = ("POST", ))
@moderator.require(401)
def translate_op_content():
    """編輯後上傳"""
    try:
        md5id = request.form['id']
        c = request.form['c']
        cl = request.form['cl']
        with switch_db(LangMap, g.GAMEBASE) as LM:
            e = LM.objects.get(id=md5id)
        if cl in e._data:
            orig_txt = e._data[cl]
            if md5(orig_txt) == md5(c):
                return jsonify({'ost': 'err', 'msg': '内容未发生变化'})
        setattr(e, cl, c)
        e.save()


    except:
        return jsonify({'ost': 'err', 'msg': '保存失败'})

    return jsonify({'ost': 'ok', 'msg': '保存成功'})

@admin.route("/translation/table_entry/", methods = ("GET", "POST"))
@moderator.require(401)
def translate_opertate_coll():
    """添加翻译字段"""
    SIDEBAR = 'LANG'
    per_page = 10
    if request.method == "GET":
        page = request.args.get('page', 1, int)
        form = LangForm(request.form)
        ctx = {}
        with switch_db(PathMap, g.GAMEBASE) as PM:
            coll_names = PM.objects.distinct('coll_name')
        coll_names = [(n, n) for n in coll_names]
        entries = [('-1', '全部')]
        entries.extend(coll_names)
        form.filter_entries.choices = entries
        cn = request.args.get(form.filter_entries.id)
        if not cn or cn == '-1':
            with switch_db(PathMap, g.GAMEBASE) as PM:
                pagination = PM.objects.paginate(page=page, per_page=per_page)
            form.filter_entries.data = "-1"
        else:
            form.filter_entries.data = cn
            with switch_db(PathMap, g.GAMEBASE) as PM:
                pagination = PM.objects(coll_name=cn).paginate(page=page, per_page=per_page)
        ctx.update(dict(pagination=pagination, form=form, SIDEBAR=SIDEBAR, endpoint='admin.translate_opertate_coll'))
        return render_template("admin/translate_colls.html", **ctx)
    elif request.method == "POST":
        oid = request.form.get('id', None)
        op = request.form.get('op', '')
        if oid and op == 'del':
            with switch_db(PathMap, g.GAMEBASE) as PM:
                obj = PM.objects.get(id=oid)
            if obj:
                obj.delete()
                return jsonify(dict(ost="ok"))
        form = LangForm(request.form)
        if form.add_path_submit.data:
            cn, cf = form.add_collection_name.data, form.add_field_name.data

            if cn and cf:
                with switch_db(AnyDoc, g.GAMEBASE) as adc:
                    with switch_collection(adc, cn) as adcc:
                        qs = adcc.objects.only(cf).as_pymongo()
                        e = qs.first()
                        if not cf in e:
                            return jsonify(dict(ost="err", msg="指定的表名或字段不存在"))
                        with switch_db(PathMap, g.GAMEBASE) as PM:
                            new_colls_fields, created = PM.objects.get_or_create(path=cf, coll_name=cn)
                        if created:
                            with switch_db(LangMap, g.GAMEBASE) as LM:
                                for e in qs:
                                    c = e[cf]
                                    if not isinstance(c, (basestring,)):
                                        c = json.dumps(c)
                                    key = md5(c)
                                    lang_e = LM(id=key, cn_str=c)
                                    lang_e.save()

                # redirect(url_for("admin.translate_opertate_coll"))
                return jsonify(dict(ost="ok"))
        return jsonify(dict(ost="err", msg="操作失败"))


@admin.route("/translation/", methods = ("GET", "POST"))
@moderator.require(401)
@resp(template="admin/translate.html")
def tranlate_language():
    SIDEBAR = 'LANG'
    entries = [('-1', '全部')]
    with switch_db(PathMap, g.GAMEBASE) as PM:
        coll_names = PM.objects.distinct('coll_name')
    coll_names = [(n, n) for n in coll_names]
    form = LangForm(request.form)
    entries.extend(coll_names)
    form.filter_entries.choices = entries
    if request.method == 'POST':
        if form.add_lang_submit.data:  # 添加語言
            if form.lang.form.lang_name.data and form.lang.form.id.data:
                form.lang.form.save(commit=True)

    form.current_lang.queryset = LangConf.objects

    page = request.args.get('page', 1, int)
    cl = request.args.get(form.current_lang.id)
    cn = request.args.get(form.filter_entries.id)
    show_favor = request.args.get(form.filter_show.id, 0, int)
    form.filter_show.data = show_favor
    print(show_favor)
    cl = cl or 'zh-HK'
    current_lang, created = LangConf.objects.get_or_create(id=cl, defaults={'lang_name': u'繁体'})
    form.current_lang.data = current_lang


    cn = cn or '-1'
    if show_favor == 1:
        qq = {cl: {'$exists': True}}
    elif show_favor == 2:
        qq = {cl: {'$exists': False}}
    else:
        qq = {}
    with switch_db(LangMap, g.GAMEBASE) as LM:
        qs = LM.objects(__raw__=qq).only('id', 'cn_str', cl)
    form.filter_entries.data = cn
    if cn != '-1':
        with switch_db(AnyDoc, g.GAMEBASE) as adc:
            with switch_collection(adc, cn) as adcc:
                with switch_db(PathMap, g.GAMEBASE) as PM:
                    cfs = [o.path for o in PM.objects(coll_name=cn)]
                ex_qs = adcc.objects.only(*cfs).as_pymongo()
                keys = []
                kvs = {}
                for e in ex_qs:
                    for f in cfs:
                        try:
                            c = e[f]
                        except:
                            continue
                        if not isinstance(c, (basestring,)):
                            c = json.dumps(c)
                        key = md5(c)
                        keys.append(key)
                        kvs[key] = c
                qs = qs.in_bulk(keys)
                if len(keys) > len(qs):  # 有新的词条加入了
                    new_keys = set(keys) - set(qs.keys())
                    with switch_db(LangMap, g.GAMEBASE) as LM:
                        for k in new_keys:
                            lang_e = LM(id=k, cn_str=kvs[k])
                            lang_e.save()
                            qs[k] = lang_e

                pagination = Pagination(qs.values(), page=page, per_page=20)
    else:
        pagination = qs.paginate(page=page, per_page=20)

    ctx = {}
    return {'SIDEBAR': SIDEBAR, 'form': form, "ctx": ctx,
            'pagination': pagination, 'endpoint': 'admin.tranlate_language'}


@admin.route('/admin/user/', methods=('GET','POST'))
@p_admin.require(401)
@resp()
def admin_user():
    """ 后台管理－管理员帐户 """
    page = int(request.args.get('page','1'))
    auser = AdminUser.query.all()
    # auser = AdminUser.query.paginate(page=page, per_page=1000)
    return { 'auser':auser }

@admin.route('/admin/user/change/right/',methods=('GET','POST'))
@p_admin.require(401)
@resp(ret='json')
def admin_user_change_right():
    try:
        id = request.args.get('id')
        index = int(request.args.get('index'))
        user = AdminUser.query.get_or_404(ObjectId(id))
        try:
            if user.right[index] == 0:
                user.right[index] = 1
            else:
                user.right[index] = 0
        except IndexError:
            end_pos = len(user.right)
            if index >= end_pos:
                [user.right.append(0) for i in range(end_pos, index + 1)]
                user.right[index] = 1
        user.save()
        return { 'success':1 }
    except:
        print_traceback()
        return { 'success':0 }

@admin.route('/admin/user/add/', methods=('GET','POST'))
@p_admin.require(401)
@resp(ret='json')
def admin_user_add():
    try:
        id = request.form.get('id', None)
        if id:
            user = AdminUser.query.get_or_404(ObjectId(id))
        else:
            user = AdminUser()
        email = request.form.get('email')
        password = request.form.get('password')
        nickname = request.form.get('nickname')
        role = int(request.form.get('role'))
        user.username = email
        user.password = password
        user.nickname = nickname
        user.role = role
        if not id:
            user.right = [0,0,0,0,0]
        user.save()
        return { 'success':1 }
    except:
        print_traceback()
        return { 'success':0 }

@admin.route('/admin/user/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_user_delete():
    try:
        id = request.args.get('id')
        user = AdminUser.query.get_or_404(ObjectId(id))
        user.remove()
        return { 'success':'1' }
    except:
        return { 'success':'0' }

@admin.route('/admin/user/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_user_data():
    try:
        id = request.args.get('id')
        user = AdminUser.query.get_or_404(ObjectId(id))
        user = {'username':user.username, 'password':user.password,
                '_id':str(user.mongo_id), 'role':user.role,
                'nickname':user.nickname}
    except:
        print_traceback()
        return { 'success':'0'}
    return { 'success':'1', 'ret':user}

@admin.route('/admin/confirm/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_confirm_delete():
    try:
        coll = request.args.get('collection')
        mongo = MongoFive(g.GAMEBASE,coll, host=g.mongo_host)
        mongo.drop()
    except:
        return { 'status':'0' }
    return { 'status':'1' }

#================后台管理－下载所有表====================
@admin.route('/admin/create/database/', methods=('GET','POST'))
@moderator.require(401)
@resp( ret='json')
def admin_create_database():
    import json
    import zlib
    from luffy.models import new_aes_encrypt
    from langcvt import langconv
    collection = "gconfig"
    mongo_ver = MongoFive(g.GAMEBASE, collection, host=g.mongo_host)
    dataver = mongo_ver.find_one({'key':'dbVer'})

    #需要生成的表
    collections = EXT.EXPORT_DATABASE
    #纪录版本号，如果存在了则＋１
    if dataver:
        ver = int(dataver['value'])+1
    else:
        ver = 1

    needSplit = {'role_level':'rid','eq_level':'part','arm_level':'aid',
                'fate_level':'fid','pos_level':'pid', 'gem_level':'gid',
                 'monster_level':'mid', 'daily':'type'}

    # 当前服务器简繁类型 1:简, 2:繁
    # print g.current_server.tf

    def transl_dict_by_keys(a_dict, filter_keys=EXT.LANG_COMMON_TRANSLATE_FIELDS, trans_func=langconv.cn2hk):
        for key in a_dict.keys():
            if key in filter_keys:
                if isinstance(a_dict[key], unicode):
                    a_dict[key] = trans_func(a_dict[key])
                else:
                    json_str = json.dumps(a_dict[key], ensure_ascii=False)
                    trans_str = trans_func(json_str)
                    a_dict[key] = json.loads(trans_str)

    def cn2any(to_lang, content):
        """
        转换为其他语言
        """
        key = md5(content)
        try:
            with switch_db(LangMap, g.GAMEBASE) as LM:
                e = LM.objects.get(id=key)
            return e._data[to_lang]
        except:
            return content


    for item in collections:
        data = {}
        mongo = MongoFive(g.GAMEBASE, item, host=g.mongo_host)
        #版本地址
        filePath = ''.join([g.res_path, str(ver)])
        #如果版本地址不存在则创建文件夹
        if os.path.isdir(filePath) is False:
            os.mkdir(filePath)
        datafile = filePath+'/'+item

        #如果在needSplit中的表，则需要根据dict中的value分类
        if item in needSplit.keys():
            data[item] = {}
            rid_list = mongo.distinct(needSplit[item])
            for t in rid_list:
                data[item][str(t)]= mongo.filter({needSplit[item]:t})
                #'pop_id将_id弹出并写入id字段'
                data[item][str(t)] = pop_id(data[item][str(t)])
        elif item == 'task':
            data[item] = {}
            #任务表task中固定只有４个任务，根据４个任务分开
            for t in xrange(1,5):
                data[item][str(t)]= mongo.filter({'type':t})
                data[item][str(t)] = pop_id(data[item][str(t)])
        elif item == 'tips':
            data[item] = {}
            for t in xrange(1,3):
                data[item][str(t)]= mongo.filter({'type':t})
                data[item][str(t)] = pop_id(data[item][str(t)])
        else:
            data[item] = mongo.all()
            data[item] = pop_id(data[item])

        #转换字符编码 added by 彭柏流
        langid = g.current_server.tf
        clang = langid.lower()
        if clang != 'zh-cn':
            with switch_db(PathMap, g.GAMEBASE) as PM:
                filter_fields = PM.objects(coll_name=item).distinct('path')
            if clang == 'zh-hk':
                translate_func = langconv.cn2hk
                filter_fields =  EXT.LANG_COMMON_TRANSLATE_FIELDS
            else:
                translate_func = partial(cn2any, langid)
            for entry in data[item]:
                if isinstance(entry, str):
                    if item == EXT.COLL_TASK or item == 'tips':  #任务列表特殊处理
                        for entity in data[item][entry]:
                            transl_dict_by_keys(entity, filter_keys=filter_fields, trans_func=translate_func)

                    continue
                    transl_dict_by_keys(entity, filter_keys=filter_fields, trans_func=translate_func)

        #将json转为字符并写入文件
        d = json.dumps(data[item])
        tmp_d = zlib.compress(d,6)
        tmp_d = new_aes_encrypt('xf3R0xdcmx8bxc0J')(tmp_d)
        with open(datafile,'a') as f:
            f.writelines(tmp_d)

    #'判断有无基础数据文件，有则修改数据库中的版本，无则创建'
    if dataver:
        args = {}
        args['condition'] = {'key':'dbVer'}
        args['data'] = { '$set':{'value':ver} }
        mongo_ver.update(args)
    else:
        args = {'key':'dbVer', 'value':1}
        mongo_ver.insert(args)
    return { 'ret':'success', 'ver':ver }
#=======================================================
#================后台管理－导出xls文件====================
@admin.route('/admin/database/xls/', methods=('GET', 'POST'))
@moderator.require(401)
@resp( ret = 'json' )
def admin_database_xls():
    import pyExcelerator
#    collection = "gconfig"
#    '需要生成的表'
    collections = EXT.EXPORT_DATABASE
    ex_export = [EXT.COLL_BAN_WORD, EXT.COLL_HORN]
    [collections.append(item) for item in ex_export]
#    '版本地址'
    filePath = ''.join([os.path.dirname(admin.root_path), '/static/mongobackup/', str(datetime.now()).split(' ')[0]])
#    '如果版本地址不存在则创建文件夹'
    if os.path.isdir(filePath) is False:
        os.mkdir(filePath)
    for item in collections:
        mongo = MongoFive(g.GAMEBASE, item, host=g.mongo_host)
        w = pyExcelerator.Workbook()
        ws = w.add_sheet('sheet1')
        ret = mongo.filter({})
        if ret:
            keys = ret[-1].keys()
            i = 4
            j = 1
            for k in keys:
                ws.write(i, j, k)
                j += 1
            row = 5
            for r in ret:
                for k in keys:
                    try:
                        ws.write(row, keys.index(k)+1, r[k])
                    except:
                        ws.write(row, keys.index(k)+1, '')
                row += 1
            today = str(datetime.now()).split(' ')[0]
            w.save(''.join([filePath, '/', item,'.xls']))
    return { 'ret':'success' }

@admin.route('/admin/show/xls/<string:date>/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_show_xls(date=None):
    allFile = None
    filePath = [os.path.dirname(admin.root_path), '/static/mongobackup/']
    if date:
        filePath.append(date)
    lastPath = ''.join(filePath)
    if os.path.isdir(lastPath):
        allFile = os.listdir(lastPath)
    return { 'allFile':allFile, 'date':date }

#'================后台管理－获取当前数据库版本===================='
@admin.route('/admin/database/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_database():
    collection = "gconfig"
    mongo_ver = MongoFive(g.GAMEBASE, collection, host=g.mongo_host)
    dataver = mongo_ver.find_one({'key':'dbVer'})
    if dataver:
        return { 'ver':dataver['value']}
    else:
        return { 'ver':u'未生成文件' }
#'======================================================='

@admin.route('/admin/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_delete():
    """ 公用方法，删除单条纪录 """
    try:
        tmp_id = int(request.args.get('id'))
        db = request.args.get('db')
        table = request.args.get('table')
        querys = {EXT.KEY_MONGO_ID:tmp_id}
        g.mongo_drive.remove(db, table, querys)
    except:
        print_traceback()
        return { 'success':'0' }
    return { 'success':'1' }

@admin.route('/admin/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_data():
    """ 公用方法，返回单条纪录 """
    try:
        tmp_id = int(request.args.get('id'))
        db = request.args.get('db')
        table = request.args.get('table')
        querys = {EXT.KEY_MONGO_ID:tmp_id}
        ret = g.mongo_drive.find_one(db, table, querys)
    except:
        print_traceback()
        return { 'success':'0' }
    return { 'success':'1', 'ret':ret }

#'================后台管理－新手指引表管理===================='
@admin.route('/admin/intro/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_intro():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_INTRO, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_intro'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_INTRO}

@admin.route('/admin/intro/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_intro_save():
    t = {'type':int, 'id':int, 'dir':int, 'islogo':int,
        'force':int, 'content':str, 'dropPosition':str, 'dropPositionIP':str}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_INTRO, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－战斗失败提示表管理===================='
@admin.route('/admin/tips/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_tips():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_TIPS, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_tips'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_TIPS}

@admin.route('/admin/tips/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_tips_save():
    t = {'type':int, 'id':int, 'stype':int, 'info':str}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_TIPS, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－新手指引表管理===================='
@admin.route('/admin/goods/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_goods():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_GOODS, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_goods'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_GOODS}

@admin.route('/admin/goods/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_goods_save():
    t = {
        'name':str,'info':str,'act' :str,'type':int,'price':int,'oprice':int,
        'rid':int,'status':int,'coin':int, 'id':int, 'freeCoin':int, 'snsType':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_GOODS, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'================后台管理－新手指引表管理===================='
@admin.route('/admin/error/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_error():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_ERROR, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_error'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_ERROR}

@admin.route('/admin/error/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_error_save():
    t = {'info':str, 'id':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ERROR, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－敏感词表管理===================='
@admin.route('/admin/ban/word/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_ban_word():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_BAN_WORD, host=g.mongo_host)
    ret = mongo.paginate(page=page)
    page_count = mongo.page_count()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_ban_word'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_BAN_WORD,
             'page_count':page_count}

@admin.route('/admin/ban/word/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_ban_word_save():
    t = {'banword':str, 'id':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BAN_WORD, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－功能规则说明表管理===================='
@admin.route('/admin/rule/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_rule():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_RULE, host=g.mongo_host)
    ret = mongo.paginate(page=page)
    page_count = mongo.page_count()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_rule'))
    return { 'page':page, 'ret':ret,'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_RULE,
             'page_count':page_count}

@admin.route('/admin/rule/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_rule_save():
    t = {'info':str, 'id':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_RULE, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='

#'================后台管理－角色表管理===================='
@admin.route('/admin/role/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_role():
    SIDEBAR = 'ADMIN'

    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_ROLE, host=g.mongo_host)
    ret = mongo.all()

    mongo_sk = MongoFive(g.GAMEBASE, EXT.COLL_SKILL, host=g.mongo_host)
    sk_ret = mongo_sk.find({},{'_id':1, 'name':1})

    mongo_npc = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    npc_ret = mongo_npc.find({},{'_id':1, 'name':1})
    showsk = {}
    for item in sk_ret:
        showsk[item['_id']] = item['name']
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_role'))
    return { 'page':page, 'ret':ret, 'npc_ret':npc_ret,'SIDEBAR':SIDEBAR,
             'coll': EXT.COLL_ROLE, 'quality':EXT.QUALITY, 'sk_ret':sk_ret,
             'showsk':showsk}

@admin.route('/admin/role/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_role_save():
    t = {
        'name':str, 'npc':str, 'job':str, 'office':str, 'info':str, 'act':str,
        'arm':int, 'quality':int, 'sex':int, 'sk1':int, 'sk2':int, 'index':int,
        'disLV':int, 'invLV':int, 'invs':str, 'useId':int, 'useNum':int,
        'offset':int, 'body':float, 'boffset':str, 'id':int, 'type':int,
        'chapter':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ROLE, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


@admin.route('/admin/roleup/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_roleup():
    SIDEBAR = 'ADMIN'
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_ROLEUP, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo, coll=EXT.COLL_ROLEUP):
        return redirect(url_for('admin.admin_roleup'))
    return { 'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_ROLEUP, 'ret':ret}

@admin.route('/admin/roleup/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_roleup_save():
    t = {
        'type':int, 'quality':int, 'grade':int, 'check':int,
        'attr':int, 'id':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ROLEUP, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/roleup/type/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_roleup_type():
    SIDEBAR = 'ADMIN'
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_ROLEUP_TYPE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_roleup_type'))
    return { 'SIDEBAR':SIDEBAR, 'coll': EXT.COLL_ROLEUP_TYPE, 'ret':ret}

@admin.route('/admin/roleup/type/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_roleup_type_save():
    t = {
        'type':int, 'rid':int, 'id':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ROLEUP_TYPE, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－角色等级表管理===================='
@admin.route('/admin/role/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_role_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ROLE_LEVEL, host=g.mongo_host)
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()
    role_five = MongoFive(g.GAMEBASE,EXT.COLL_ROLE, host=g.mongo_host)
    role_ret = role_five.find({},{'_id':1, 'name':1})
    showrole = {}
    for item in role_ret:
        showrole[item['_id']] = item['name']
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_role_level'))
    return { 'page':page,'page_count':page_count, 'ret':ret, 'SIDEBAR':SIDEBAR,
    'role_ret':role_ret,'showrole':showrole, 'coll':EXT.COLL_ROLE_LEVEL  }

@admin.route('/admin/role/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_role_level_save():
    t = {
        'rid':int, 'level':int, 'STR':float, 'DEX':float, 'VIT':float, 'INT':float,
        'HP':float, 'ATK':float, 'STK':float, 'DEF':float, 'SPD':float, 'MP':int,
        'MPS':int, 'MPR':float, 'HIT':float, 'MIS':float, 'BOK':float, 'COT':float,
        'COB':float, 'CRI':float, 'CPR':float, 'PEN':float, 'TUF':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ROLE_LEVEL, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－角色经验表管理===================='
@admin.route('/admin/role/exp/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_role_exp():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ROLE_EXP, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_role_exp'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ROLE_EXP}

@admin.route('/admin/role/exp/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_role_exp_save():
    t = {'id':int, 'level':int, 'exp':int, 'siteExp':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ROLE_EXP, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'======================================================='
#'================后台管理－祭天表管理===================='
@admin.route('/admin/fete/rate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fete_rate():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FETE_RATE, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fete_rate'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FETE_RATE}

@admin.route('/admin/fete/rate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fete_rate_save():
    t = {
        'id':int, 'info':str, 'act':str, 'type':int, 'rate':int, 'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FETE_RATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'======================================================='
#'================后台管理－武器表管理===================='
@admin.route('/admin/arm/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_arm():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ARM, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_arm'))

    skfive = MongoFive(g.GAMEBASE,EXT.COLL_SKILL, host=g.mongo_host)
    sk_ret = skfive.find({},{'_id':1, 'name':1})
    showsk = {}
    for item in sk_ret:
        showsk[item['_id']] = item['name']
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ARM, 'sk_ret':sk_ret,
             'showsk':showsk }

@admin.route('/admin/arm/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_arm_save():
    t = {
        'id':int, 'name':str, 'sk1':int, 'sk2':int, 'quality':int,
        'act':str, 'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ARM, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－技能表管理===================='
@admin.route('/admin/skill/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_skill():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_SKILL, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_skill'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_SKILL}

@admin.route('/admin/skill/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_skill_save():
    t = {
        'id':int,'name':str,'far':int, 'effect':str, 'effectRG':int,
        'effectDIS':int, 'range':int, 'act':str,'info':str,'rHurt1':str,
        'rHurt2':str,'shock':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_SKILL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－技能状态表管理===================='
@admin.route('/admin/state/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_state():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_STATE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_state'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_STATE}

@admin.route('/admin/state/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_state_save():
    t = {
        'id':int,'name':str,'info':str,'type':int,'act':str,'rate':int,
        'target':int, 'num':int, 'round':int, 'action':int, 'ahp':int,
        'bhp':int, 'nomis':int, 'nobok':int, 'nocot':int, 'noatk':int,
        'value':str, 'mp':int, 'mp_p':int, 'hp':int, 'hp_p':int, 'eff':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_STATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－技能状态关系表管理===================='
@admin.route('/admin/sk/state/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_sk_state():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_SK_STATE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_sk_state'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_SK_STATE}

@admin.route('/admin/sk/state/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_sk_state_save():
    t = {
        'id':int,'skid':int,'stid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_SK_STATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－武器等级表管理===================='
@admin.route('/admin/arm/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_arm_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ARM_LEVEL, host=g.mongo_host)
    #ret = five.all()
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()

    arm_five = MongoFive(g.GAMEBASE,EXT.COLL_ARM, host=g.mongo_host)
    arm_ret = arm_five.find({},{'_id':1, 'name':1})
    showarm = {}
    for item in arm_ret:
        showarm[item['_id']] = item['name']
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo, coll=EXT.COLL_ARM_LEVEL):
        return redirect(url_for('admin.admin_arm_level'))
    return { 'page':page, 'ret':ret,'page_count':page_count, 'SIDEBAR':SIDEBAR,
    'arm_ret':arm_ret, 'showarm':showarm, 'coll':EXT.COLL_ARM_LEVEL}

@admin.route('/admin/arm/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_arm_level_save():
    t = {
        'id':int,'aid':int,'level':int,'STR':float,'DEX':float,'VIT':float,
        'INT':float,'HP':float,'ATK':float,'STK':float,'DEF':float,
        'SPD':float,'MP':int,'MPS':int,'MPR':int,'HIT':float,'MIS':float,
        'BOK':float,'COT':float,'COB':float,'CRI':float,'CPR':float,
        'PEN':float,'TUF':float,'hurt_p':float,'addHp':int,'addHp_p':float,
        'SPD_P':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ARM_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－武器等级练历表管理===================='
@admin.route('/admin/arm/exp/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_arm_exp():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ARM_EXP, host=g.mongo_host)
    ret = mongo.all()

    arm_level_five = MongoFive(g.GAMEBASE,EXT.COLL_ARM_LEVEL, host=g.mongo_host)
    arm_level_ret = arm_level_five.find({},{'_id':1, 'level':1})
    show_arm_level = {}
    for item in arm_level_ret:
        show_arm_level[item['_id']] = item['level']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_arm_exp'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR,
    'arm_level_five':arm_level_five,'show_arm_level':show_arm_level,
    'coll':EXT.COLL_ARM_EXP}

@admin.route('/admin/arm/exp/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_arm_exp_save():
    t = {
        'id':int,'level':int,'exp':int,'limit':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ARM_EXP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理-装备表===================='
@admin.route('/admin/equip/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_equip():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EQUIP, host=g.mongo_host)
    ret = mongo.all()

    eqset_five = MongoFive(g.GAMEBASE,EXT.COLL_EQ_SET, host=g.mongo_host)
    eqset_ret = eqset_five.find({},{'_id':1, 'name':1})
    show_eqset_ret = {}
    for item in eqset_ret:
        show_eqset_ret[item['_id']] = item['name']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_equip'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'eqset_ret':eqset_ret,
    'show_eqset_ret':show_eqset_ret , 'coll':EXT.COLL_EQUIP}

@admin.route('/admin/equip/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_equip_save():
    t = {
        'id':int,'name':str,'act':str,'sid':int,'part':int,'limit':int,
        'price':int,'rate':int,'info':str,'STR':float,'DEX':float,
        'VIT':float,'INT':float,'HP':float,'ATK':float,'STK':float,
        'DEF':float,'SPD':float,'MP':int,'MPS':int,'MPR':int,
        'HIT':float,'MIS':float,'BOK':float,'COT':float,'COB':float,
        'CRI':float,'CPR':float,'PEN':float,'TUF':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_EQUIP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－装备等级表管理===================='
@admin.route('/admin/eq/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_eq_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EQ_LEVEL, host=g.mongo_host)
    ret = mongo.all()
    eq_five = MongoFive(g.GAMEBASE,EXT.COLL_EQUIP, host=g.mongo_host)
    eq_ret = eq_five.find({},{'_id':1, 'name':1})

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_eq_level'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'eq_ret':eq_ret,
    'coll':EXT.COLL_EQ_LEVEL}

@admin.route('/admin/eq/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_eq_level_save():
    t = {
        'id':int,'part':int,'level':int,'STR':float,'DEX':float,'VIT':float,
        'INT':float,'HP':float,'ATK':float,'STK':float,'DEF':float,'SPD':float,
        'MP':int,'MPS':int,'MPR':int,'HIT':float,'MIS':float,'BOK':float,
        'COT':float,'COB':float,'CRI':float,'CPR':float,'PEN':float,'TUF':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_EQ_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理-套装表==================================='
@admin.route('/admin/eq/set/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_eq_set():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EQ_SET, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_eq_set'))
    return { 'success':'1', 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_EQ_SET}


@admin.route('/admin/eq/set/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_eq_set_save():
    t = {
        'id':int,'name':str,'info':str,'effect2':str,'effect4':str,
        'effect6':str,'quality':int,'lv':int, 'cond':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_EQ_SET, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}



#'======================================================='
#'=====================后台管理-装备强化表======================'
@admin.route('/admin/str/eq/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_str_eq():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_STR_EQ, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_str_eq'))
    return { 'success':'1', 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_STR_EQ}

@admin.route('/admin/str/eq/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_str_eq_save():
    t = {
        'id':int,'level':int,'useId':int,'count':int,'mvCoin1':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_STR_EQ, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=====================后台管理-玄铁获取概率表======================'
@admin.route('/admin/mine/rate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_mine_rate():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_MINE_RATE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_mine_rate'))
    return { 'success':'1', 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_MINE_RATE}

@admin.route('/admin/mine/rate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_mine_rate_save():
    t = {
        'id':int,'type':int,'level1':int,'level2':int,'rids':str,
        'coin1':int,'coin2':int,'coin3':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_MINE_RATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=====================后台管理-命格表======================'
@admin.route('/admin/fate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fate():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FATE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fate'))
    return { 'success':'1', 'ret':ret , 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FATE}

@admin.route('/admin/fate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fate_save():
    t = {
        'id':int,'name':str,'info':str,'act':str,'quality':int,'beginExp':int,
        'rate':float,'price':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－命格等级表管理===================='
@admin.route('/admin/fate/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fate_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FATE_LEVEL, host=g.mongo_host)
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()
    fate_five = MongoFive(g.GAMEBASE,EXT.COLL_FATE, host=g.mongo_host)
    fate_ret = fate_five.find({},{'_id':1, 'name':1})
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo, coll=EXT.COLL_FATE_LEVEL):
        return redirect(url_for('admin.admin_fate_level'))
    return { 'page':page, 'ret':ret,'page_count':page_count, 'SIDEBAR':SIDEBAR,
            'fate_ret':fate_ret, 'coll':EXT.COLL_FATE_LEVEL}

@admin.route('/admin/fate/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fate_level_save():
    t = {
        'id':int,'fid':int,'level':int,'exp':int,'STR':float,'DEX':float,
        'VIT':float,'INT':float,'HP':float,'ATK':float,'STK':float,'DEF':float,
        'SPD':float,'MP':int,'MPS':int,'MPR':int,'HIT':float,'MIS':float,
        'BOK':float,'COT':float,'COB':float,'CRI':float,'CPR':float,
        'PEN':float,'TUF':float,'SPD_P':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FATE_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－命格获取概率表管理===================='
@admin.route('/admin/fate/rate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fate_rate():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FATE_RATE, host=g.mongo_host)
    ret = mongo.all()

    monster_five = MongoFive(g.GAMEBASE,EXT.COLL_MONSTER, host=g.mongo_host)
    monster_ret = monster_five.find({},{'_id':1, 'name':1})
    show_monster = {}
    for item in monster_ret:
        show_monster[item['_id']] = item['name']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fate_rate'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'monster_ret':monster_ret,
    'show_monster':show_monster, 'coll':EXT.COLL_FATE_RATE }

@admin.route('/admin/fate/rate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fate_rate_save():
    t = {'id':int,'type':int,'mid':int,'rate':float,'rid':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FATE_RATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－猎命消耗表管理===================='
@admin.route('/admin/fate/cost/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fate_cost():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FATE_COST, host=g.mongo_host)
    ret = mongo.all()


    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fate_cost'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FATE_COST }

@admin.route('/admin/fate/cost/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fate_cost_save():
    t = {'id':int,'num':int,'coin1':int,'coin2':int,'coin3':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FATE_COST, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－物品表管理===================='
@admin.route('/admin/item/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_item():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ITEM, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_item'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ITEM }

@admin.route('/admin/item/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_item_save():
    t = {
        'id':int,'name':str,'act':str,'quality':int,'type':int,'price':int,
        'stack':int,'info':str,'rid':int, 'lv':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ITEM, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－物品合成表管理===================='
@admin.route('/admin/fusion/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fusion():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FUSION, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fusion'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FUSION }

@admin.route('/admin/fusion/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fusion_save():
    t = {
        'id':int,'name':str,'info':str,'type':str,'desId':int,'srcId':int,
        'count':int,'coin1':int,'coin2':int,'coin3':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FUSION, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－奖励表管理===================='
@admin.route('/admin/reward/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_REWARD, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_reward'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_REWARD }

@admin.route('/admin/reward/edit/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward_edit():
    SIDEBAR = 'ADMIN'
    id = int(request.args.get('id','1'))
    rewardFive = MongoFive(g.GAMEBASE,EXT.COLL_REWARD, host=g.mongo_host)
    ret = rewardFive.get_by_id(int(id))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_REWARD }

@admin.route('/admin/reward/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_reward_save():
    t = {'id':int,'name':str,'info':str,'reward':str,'useId':str,'useNum':str}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_REWARD, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－怪物表管理===================='
@admin.route('/admin/monster/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_monster():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_MONSTER, host=g.mongo_host)
    ret = mongo.all()

    skfive = MongoFive(g.GAMEBASE,EXT.COLL_SKILL, host=g.mongo_host)
    sk_ret = skfive.find({},{'_id':1, 'name':1})

    npc = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    npc_ret = npc.find({},{'_id':1, 'name':1})
    showsk = {}
    for item in sk_ret:
        showsk[item['_id']] = item['name']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_monster'))
    return { 'page':page, 'ret':ret, 'npc_ret':npc_ret,'SIDEBAR':SIDEBAR,'sk_ret':sk_ret,
             'showsk':showsk, 'coll':EXT.COLL_MONSTER}

@admin.route('/admin/monster/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_monster_save():
    t = {
        'id':int, 'name':str,'act' :str,'type':int,'sex':int,'sk1':int,
        'sk2':int,'body':float, 'offset':int, 'boffset':str,'quality':int,
        'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_MONSTER, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－怪物等级表管理===================='
@admin.route('/admin/monster/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_monster_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_MONSTER_LEVEL, host=g.mongo_host)
    #ret = five.all()
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()
    monster_five = MongoFive(g.GAMEBASE,EXT.COLL_MONSTER, host=g.mongo_host)
    monster_ret = monster_five.find({},{'_id':1, 'name':1})
    show_monster = {}
    for item in monster_ret:
        show_monster[item['_id']] = item['name']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_monster_level'))
    return { 'page':page, 'page_count':page_count, 'ret':ret, 'SIDEBAR':SIDEBAR, 'monster_ret':monster_ret, 'show_monster':show_monster, 'coll':EXT.COLL_MONSTER_LEVEL }

@admin.route('/admin/monster/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_monster_level_save():
    t = {
        'id':int,'mid':int, 'level':int,'STR':str,'DEX':str,'VIT':str,
        'INT':str,'HP':str,'ATK':str,'STK':str,'DEF':str,'SPD':str,
        'MP':str,'MPS':str,'MPR':str,'HIT':str,'MIS':str,'BOK':str,
        'COT':str,'COB':str,'CRI':str,'CPR':str,'PEN':str,'TUF':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_MONSTER_LEVEL, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－NPC表管理===================='
@admin.route('/admin/npc/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_npc():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_npc'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_NPC}

@admin.route('/admin/npc/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_npc_save():
    t = {
        'id':int,'name':str,'func':str,'msg':str,'isShowName':int,'info':str,
        'isDown':int,'body':float,'offset':int,'isshadow':int,'dir':int,'res':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_NPC, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－坐骑表管理===================='
@admin.route('/admin/car/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_car():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_CAR, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_car'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_CAR}

@admin.route('/admin/car/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_car_save():
    t = {
        'id':int,'name':str,'act':str,'quality':int,'speed':float,'isDir':int,
        'isExchange':int,'useId':int,'count':int,'coin1':int, 'coin2':int,
        'coin3':int, 'offset':int, 'isshadow':int, 'high':int, 'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_CAR, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－同盟等级表管理===================='
@admin.route('/admin/ally/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_ally_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ALLY_LEVEL, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_ally_level'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ALLY_LEVEL}

@admin.route('/admin/ally/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_ally_level_save():
    t = {
        'id':int,'level':int,'exp':int,'maxNum':int,'dt1Num':int,'dt2Num':int,
        'dt3Num':int,'dt4Num':int,'dt5Num':int,'dt6Num':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ALLY_LEVEL, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－同盟权限表管理===================='
@admin.route('/admin/ally/right/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_ally_right():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ALLY_RIGHT, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_ally_right'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ALLY_RIGHT}

@admin.route('/admin/ally/right/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_ally_right_save():
    t = {
        'id':int,'name':str,'duty':int,'change':int,'kick':int,'check':int,
        'post':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ALLY_RIGHT, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－同盟-宝具铭刻管理===================='
@admin.route('/admin/ally/grave/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_ally_grave():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_ALLY_GRAVE, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_ally_grave'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ALLY_GRAVE}

@admin.route('/admin/ally/grave/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_ally_grave_save():
    t = {
        'id':int,'t':int,'coin1':int,'coin3':int,'lv1arm':int,'lv2arm':int,
        'lv3arm':int,'lv4arm':int,'lv5arm':int,'lv6arm':int,'lv7arm':int,
        'lv8arm':int,'lv9arm':int,'lv10arm':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ALLY_GRAVE, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－地图表管理===================='
@admin.route('/admin/map/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_map():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_MAP, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_map'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_MAP }

@admin.route('/admin/map/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_map_save():
    t = {
        'id':int,'name':str,'type':int,'pmid':int,'tiledFile':str,
        'multi':int,'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_MAP, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－副本表管理===================='
@admin.route('/admin/stage/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_stage():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_STAGE, host=g.mongo_host)
    ret = mongo.all()

    map_five = MongoFive(g.GAMEBASE,EXT.COLL_MAP, host=g.mongo_host)
    map_ret = map_five.find({},{'_id':1, 'name':1})
    show_map = {}
    for item in map_ret:
        show_map[item['_id']] = item['name']

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_stage'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'map_ret':map_ret, 'show_map':show_map,
             'coll':EXT.COLL_STAGE }

@admin.route('/admin/stage/edit/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_stage_edit():
    SIDEBAR = 'ADMIN'
    id = int(request.args.get('id','1'))
    stageFive = MongoFive(g.GAMEBASE,EXT.COLL_STAGE, host=g.mongo_host)
    ret = stageFive.get_by_id(int(id))

    map_five = MongoFive(g.GAMEBASE,EXT.COLL_MAP, host=g.mongo_host)
    map_ret = map_five.find({},{'_id':1, 'name':1})

    monster = MongoFive(g.GAMEBASE,EXT.COLL_MONSTER, host=g.mongo_host)
    monster_ret = monster.find({},{'_id':1, 'name':1})
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_STAGE, 'map_ret':map_ret,
             'monster_ret':monster_ret, 'id':id }

@admin.route('/admin/stage/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_stage_save():
    t = {
        'id':int,'name':str,'mapId':int,'monster':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_STAGE, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－战斗表管理===================='
@admin.route('/admin/fight/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fight():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FIGHT, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fight'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FIGHT }

@admin.route('/admin/fight/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fight_save():
    t = {
        'id':int,'name':str,'BG':str,'icon':str,'s1':str,'s2':str,'s3':str,
        's4':str,'s5':str,'s6':str,'s7':str,'s8':str,'s9':str,'s10':str,
        's11':str,'s12':str,'s13':str,'s14':str,'s15':str,'rid':int,'par':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FIGHT, querys, ret, _set=True)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－阵型表管理===================='
@admin.route('/admin/position/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_position():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_POSITION, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_position'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_POSITION }

@admin.route('/admin/position/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_position_save():
    t = {
        'id':int,'name':str,'act':str,'eye':int,'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_POSITION, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－阵型等级表管理===================='
@admin.route('/admin/pos/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_pos_level():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_POS_LEVEL, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_pos_level'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_POS_LEVEL }

@admin.route('/admin/pos/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_pos_level_save():
    t = {
        'id':int,'level':int,'pid':int,'lockLevel':int,'lockTask':int,'coin1':int,
        's1':str,'s2':str,'s3':str,'s4':str,'s5':str,'s6':str,'s7':str,'s8':str,
        's9':str,'s10':str,'s11':str,'s12':str,'s13':str,'s14':str,'s15':str,
        'info':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_POS_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'======================================================='
#'================后台管理－食馆buff表管理===================='
@admin.route('/admin/buff/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_buff():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_BUFF, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_buff'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BUFF }


@admin.route('/admin/buff/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_buff_save():
    t = {
        'id':int,'name':str,'info':str,'act':str,'type':int,'stype':int,
        'buff':str,'cost':int,'plan':str,'coin2':str,'coin3':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BUFF, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'================后台管理－任务表管理===================='
@admin.route('/admin/task/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_task():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_TASK, host=g.mongo_host)
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()

    maps = MongoFive(g.GAMEBASE,EXT.COLL_MAP, host=g.mongo_host)
    map_ret = maps.all()

    role = MongoFive(g.GAMEBASE,EXT.COLL_ROLE, host=g.mongo_host)
    role_ret = role.all()

    reward = MongoFive(g.GAMEBASE,EXT.COLL_REWARD, host=g.mongo_host)
    reward_ret = reward.all()

    npc = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    npc_ret = npc.all()

    chapter = MongoFive(g.GAMEBASE,EXT.COLL_CHAPTER, host=g.mongo_host)
    chapter_ret = chapter.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_task'))
    return { 'page':page, 'ret':ret,'map_ret':map_ret ,'role_ret':role_ret,'reward_ret':reward_ret, \
            'npc_ret':npc_ret,'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_TASK, 'page':int(page),
            'page_count':page_count, 'chapter_ret':chapter_ret }

@admin.route('/admin/task/edit/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_task_edit():
    SIDEBAR = 'ADMIN'
    import json
    id = int(request.args.get('id'))
    taskFive = MongoFive(g.GAMEBASE,EXT.COLL_TASK, host=g.mongo_host)
    ret = taskFive.get_by_id(int(id))

    showDict = { '_id':1,'name':1}
    maps = MongoFive(g.GAMEBASE,EXT.COLL_MAP, host=g.mongo_host)
    map_ret = maps.all(isShow=showDict)
    map_ret = json.dumps(map_ret)

    role = MongoFive(g.GAMEBASE,EXT.COLL_ROLE, host=g.mongo_host)
    role_ret = role.all(isShow=showDict)
    role_ret = json.dumps(role_ret)

    fight = MongoFive(g.GAMEBASE,EXT.COLL_FIGHT, host=g.mongo_host)
    fight_ret = fight.all(isShow=showDict)
    fight_ret = json.dumps(fight_ret)

    stage = MongoFive(g.GAMEBASE,EXT.COLL_STAGE, host=g.mongo_host)
    stage_ret = stage.all(isShow=showDict)
    stage_ret = json.dumps(stage_ret)

    reward = MongoFive(g.GAMEBASE,EXT.COLL_REWARD, host=g.mongo_host)
    reward_ret = reward.all(isShow=showDict)
    reward_ret = json.dumps(reward_ret)

    npc = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    npc_ret = npc.all(isShow=showDict)
    npc_ret = json.dumps(npc_ret)

    chapter = MongoFive(g.GAMEBASE,EXT.COLL_CHAPTER, host=g.mongo_host)
    chapter_ret = chapter.all(isShow=showDict)
    chapter_ret = json.dumps(chapter_ret)

    position = MongoFive(g.GAMEBASE,EXT.COLL_POSITION, host=g.mongo_host)
    pos_ret = position.all(isShow=showDict)
    pos_ret = json.dumps(pos_ret)
    return { 'SIDEBAR':SIDEBAR,'ret':ret,'role_ret':role_ret,'map_ret':map_ret, 'reward_ret':reward_ret,\
            'npc_ret':npc_ret, 'fight_ret':fight_ret, 'pos_ret':pos_ret, 'stage_ret':stage_ret,
            'id':id, 'chapter_ret':chapter_ret}

@admin.route('/admin/task/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_task_save():
    t = {
        'id':int,'name':str,'info':str,'icon':str,'type':int,'unlock':str,
        'nextId':int,'rid':int,'step':str,
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_TASK, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－章节表管理===================='
@admin.route('/admin/chapter/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_chapter():
    SIDEBAR = 'ADMIN'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_CHAPTER, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_chapter'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_CHAPTER }

@admin.route('/admin/chapter/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_chapter_save():
    t = {
        'id':int,'name':str,'start':int,'startTid':int,'endTid':int,'mid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_CHAPTER, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－兵符表管理===================='
@admin.route('/admin/bf/task/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_bf_task():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_BF_TASK, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_bf_task'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BF_TASK }

@admin.route('/admin/bf/task/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_bf_task_save():
    t = {
        'id':int,'type':int,'quality':int,'tid':int,'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BF_TASK, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－兵符任务概率表管理===================='
@admin.route('/admin/bf/rate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_bf_rate():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_BF_RATE, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_bf_rate'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BF_RATE }

@admin.route('/admin/bf/rate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_bf_rate_save():
    t = {
        'id':int,'type':int,'quality':int,'rate':int,'part':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BF_RATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'======================================================='
#'================后台管理－时光盒管理===================='
@admin.route('/admin/tbox/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_tbox():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_TBOX, host=g.mongo_host)
    ret = mongo.all()
    npc = MongoFive(g.GAMEBASE,EXT.COLL_NPC, host=g.mongo_host)
    npc_ret = npc.filter(dic={},show={'_id':1, 'name':1})
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_tbox'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_TBOX, 'npc_ret':npc_ret }

@admin.route('/admin/tbox/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_tbox_save():
    t = {
        'id':int,'mid':int,'chapter':int,'rid':int,'place':int,'fids':str,
        'trid':int, 'tfids':str, 'tmid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_TBOX, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－深渊－宝箱配置管理===================='
@admin.route('/admin/deep/box/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_deep_box():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_DEEP_BOX, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_deep_box'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DEEP_BOX}

@admin.route('/admin/deep/box/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_deep_box_save():
    t = {
        'id':int,'fr1':int,'fr2':int,'rd':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DEEP_BOX, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－深渊－阵型表管理===================='
@admin.route('/admin/deep/pos/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_deep_pos():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_DEEP_POS, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_deep_pos'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DEEP_POS}

@admin.route('/admin/deep/pos/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_deep_pos_save():
    t = {
        'id':int,'lv1':int,'lv2':int,'pos':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DEEP_POS, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－深渊－精英配置表管理===================='
@admin.route('/admin/deep/guard/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_deep_guard():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_DEEP_GUARD, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_deep_guard'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DEEP_GUARD}

@admin.route('/admin/deep/guard/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_deep_guard_save():
    t = {
        'id':int,'lv1':int,'lv2':int,'guard':str, 'up':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DEEP_GUARD, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－神秘管理===================='
@admin.route('/admin/shop/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_shop():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_SHOP, host=g.mongo_host)
    ret = shop.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_shop'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_SHOP}

@admin.route('/admin/shop/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_shop_save():
    t = {
        'id':int,'t':int,'iid':int,'r':int,'c':int,'coin1':int,
        'coin2':int,'coin3':int,'hide':int, 'qt':int, 'start':int,
        'end':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_SHOP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－可购商品管理===================='
@admin.route('/admin/direct/shop/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_direct_shop():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_DIRECT_SHOP, host=g.mongo_host)
    ret = shop.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_direct_shop'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DIRECT_SHOP}

@admin.route('/admin/direct/shop/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_direct_shop_save():
    t = {'id':int,'iid':int,'coin1':int,'coin2':int,'coin3':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DIRECT_SHOP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－活动表管理===================='
@admin.route('/admin/activity/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_activity():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_ACTIVITY, host=g.mongo_host)
    ret = shop.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_activity'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ACTIVITY}

@admin.route('/admin/activity/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_activity_save():
    t = {'id':int,'type':int,'time':int,'blid':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ACTIVITY, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－boss奖励表管理===================='
@admin.route('/admin/boss/reward/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_boss_reward():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_BOSS_REWARD, host=g.mongo_host)
    ret = shop.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_boss_reward'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BOSS_REWARD}

@admin.route('/admin/boss/reward/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_boss_reward_save():
    t = {'id':int,'type':int,'target':str,'rid':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BOSS_REWARD, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


#'======================================================='
#'================后台管理－boss战玩家冷却时间表管理===================='
@admin.route('/admin/boss/cd/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_boss_cd():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_BOSS_CD, host=g.mongo_host)
    ret = shop.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_boss_cd'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BOSS_CD}

@admin.route('/admin/boss/cd/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_boss_cd_save():
    t = {'id':int,'type':int,'h1':int,'h2':int,'times':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BOSS_CD, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－boss等级表管理===================='
@admin.route('/admin/boss/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_boss_level():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    shop = MongoFive(g.GAMEBASE,EXT.COLL_BOSS_LEVEL, host=g.mongo_host)
    ret = shop.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, shop):
        return redirect(url_for('admin.admin_boss_level'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_BOSS_LEVEL}

@admin.route('/admin/boss/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_boss_level_save():
    t = {'id':int,'type':int,'mid':int,'level':int,'deads':int}
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_BOSS_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－任务表管理===================='
@admin.route('/admin/setting/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_setting():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_SETTING, host=g.mongo_host)
    ret = mongo.all()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_setting'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_SETTING }

@admin.route('/admin/setting/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_setting_save():
    t = {
        'id':int, 'key':str, 'value':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_SETTING, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－随机名管理===================='
@admin.route('/admin/names/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_names():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_NAME, host=g.mongo_host)
    ret = mongo.paginate(page=int(page))
    page_count = mongo.page_count()

    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_names'))
    return { 'page':page,'page_count':page_count, 'ret':ret, 'SIDEBAR':SIDEBAR,
            'coll':EXT.COLL_NAME  }

@admin.route('/admin/names/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_names_save():
    t = {
        'id':int, 'sex':int, 't':int, 'n':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_NAME, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－日常活动表管理===================='
@admin.route('/admin/daily/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_daily():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_DAILY, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_daily'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DAILY  }

@admin.route('/admin/daily/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_daily_save():
    t = {
        'id':int, 'type':int, 'subType':int, 'name':str, 'info':str,
        'tip':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DAILY, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－在线奖励表管理===================='
@admin.route('/admin/reward/online/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward_online():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_REWARD_ONLINE, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_reward_online'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR,
            'coll':EXT.COLL_REWARD_ONLINE  }

@admin.route('/admin/reward/online/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_reward_online_save():
    t = {
        'id':int, 't':int, 'tNum':int, 'val':int, 'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_REWARD_ONLINE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－奖励活动设置表管理===================='
@admin.route('/admin/reward/setting/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward_setting():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_REWARD_SETTING, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_reward_setting'))
    act_ids = []
    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(ActivitySetting, g.GAMEBASE) as Act:
        activities = Act.objects
        distinc_ids = {}
        for a in activities:
            if a.type not in distinc_ids:
                distinc_ids[a.type] = a
                act_ids.append((a.type, a.name))
        if mid != 0:
            model = activities.filter(id=mid).first()


    if model:
        addform = RewardSetForm(obj=model)
    else:
        model = ActivitySetting()
        addform = RewardSetForm(request.form)
        addform.id.data = -1
    addform.type.choices[:] = []
    addform.type.choices.extend(act_ids)

    filter_form = FilterActivityForm(request.form)
    # addform.reward_id.choices = act_ids
    # # server_groups = Servers.query.distinct(Servers.db_res)
    addform.sids.choices[1:] = []
    addform.sids.choices.extend([(f.sid, f.name) for f in g.servers])
    addform._id = type(addform).__name__

    filter_form.filter_sids.choices = [("-1", "全部")]
    filter_form.filter_sids.choices.extend(addform.sids.choices)
    filter_form.filter_sysids.choices = [("-1", "全部")]
    filter_form.filter_sysids.choices.extend(addform.sysid.choices)


    if request.method == 'POST' and addform.validate():
        addform.populate_obj(model)
        model.id = request.form.get('id', -1, int)
        with switch_db(ActivitySetting, g.GAMEBASE) as Act:
            if model.id < 0:
                if Act.objects.count() == 0:
                    model.id = 1
                else:
                    model.id = max(Act.objects.distinct('id')) + 1
            model.name = distinc_ids[model.type].name
            model.save()
            addform.id.data = model.id
            addform.id.raw_data = []

    all_record = mongo.all()
    filter_sid = request.args.get(filter_form.filter_sids.id, '-1')
    filter_sysids = request.args.get(filter_form.filter_sysids.id, '-1')
    filter_form.filter_sids.data = filter_sid
    ret = []

    for r in all_record:
        sids = r['sids']
        try:
            sysids = r['sysid'].split(',')
        except:
            sysids = []

        if (len(filter_sid) == 0 and len(sids) == 0 \
            or filter_sid == '-1' or filter_sid in sids.split(',')) \
            and (filter_sysids == '-1' or filter_sysids in sysids):
            ret.append(r)

    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'f_form': filter_form,
            'coll':EXT.COLL_REWARD_SETTING, 'form': addform, 'form_widget_args': form_widget_args}

#'================后台管理－天龙传===================='
@admin.route('/admin/boatlevel/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_boatlevel():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_boatlevel'
    page = request.args.get('page', 1, int)
    model_class = BoatLevel
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()

    ret = all_record

    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarWorldAssess/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarworldassess():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarworldassess'
    page = request.args.get('page', 1, int)
    model_class = AwarWorldAssess
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()

    ret = all_record

    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarWorldScore/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarworldscore():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarworldscore'
    page = request.args.get('page', 1, int)
    model_class = AwarWorldScore
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()

    ret = all_record

    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarNpcConfig/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarnpcconfig():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarnpcconfig'
    page = request.args.get('page', 1, int)
    model_class = AwarNpcConfig
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()
    ret = all_record


    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarPerConfig/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarperconfig():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarperconfig'
    page = request.args.get('page', 1, int)
    model_class = AwarPerConfig
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()
    ret = all_record



    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarStartConfig/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarstartconfig():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarstartconfig'
    page = request.args.get('page', 1, int)
    model_class = AwarStartConfig
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()
    ret = all_record


    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarBook/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarbook():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarbook'
    page = request.args.get('page', 1, int)
    model_class = AwarBook
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()
    ret = all_record


    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/BoatExchange/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_boatexchange():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_boatexchange'
    page = request.args.get('page', 1, int)
    model_class = BoatExchange
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()
    ret = all_record


    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/AwarStrongMap/', methods=('GET','POST'))
@moderator.require(401)
@resp(template='admin/admin_common.html')
def admin_awarstrongmap():
    SIDEBAR = 'ACHI'
    ep = 'admin.admin_awarstrongmap'
    page = request.args.get('page', 1, int)
    model_class = AwarStrongMap
    coll = model_class._get_collection_name()
    # print(coll)
    mongo = MongoFive(g.GAMEBASE, coll, host=g.mongo_host)
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for(ep))

    mid = request.args.get('mid', 0, int)
    model = None
    with switch_db(model_class, g.GAMEBASE) as Act:
        model = Act.objects.filter(id=mid).first()

    model = model_class()
    addform = RewardSetForm(request.form)

    # if request.method == 'POST' and addform.validate():
    #     addform.populate_obj(model)
    #     with switch_db(ActivitySetting, g.GAMEBASE) as Act:
    #         if model.id < 0:
    #             if Act.objects.count() == 0:
    #                 model.id = 1
    #             else:
    #                 model.id = max(Act.objects.distinct('id')) + 1
    #         model.name = distinc_ids[model.type].name
    #         model.save()
    #         addform.id.data = model.id
    #         addform.id.raw_data = []

    all_record = mongo.all()

    ret = all_record

    pg = Pagination([0,1], page=page, per_page=20)
    # form_wedgets_args = {'begin': {'onclick': 'WdatePicker()'},
    #                      'end': {'onclick': 'WdatePicker()'}}
    # form_widget_args = {addform.id.name: {"type": "hidden", "value": addform.id.data}}
    form_widget_args = {}

    return {'page':page, 'table_data':ret, 'SIDEBAR':SIDEBAR,'pagination': pg,
            'coll':coll, 'form': addform, 'form_widget_args': form_widget_args,
            'endpoint': ep}


@admin.route('/admin/reward/setting/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_reward_setting_save():
    t = {
        'id':int, 'type':int, 'begin':int, 'end':int, 'data':str,
        'state':int, 'sids':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_REWARD_SETTING, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－活动奖励表管理===================='
@admin.route('/admin/reward/activity/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward_activity():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_REWARD_ACTIVITY, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_reward_activity'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR,
                'coll':EXT.COLL_REWARD_ACTIVITY  }

@admin.route('/admin/reward/activity/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_reward_activity_save():
    t = {
        'id':int, 't':int, 'val':int, 'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_REWARD_ACTIVITY, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'================后台管理－fish表管理===================='
@admin.route('/admin/fish/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_fish():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_FISH, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_fish'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_FISH  }

@admin.route('/admin/fish/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_fish_save():
    t = {
        'id':int, 'fid':int, 'qt':int, 'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_FISH, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/reward/mail/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_reward_mail():
    """ 活动奖励邮件配置表 """
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_REWARD_MAIL, host=g.mongo_host)
    ret = mongo.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_reward_mail'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR,
                'coll':EXT.COLL_REWARD_MAIL  }

@admin.route('/admin/reward/mail/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_reward_mail_save():
    """ 活动奖励邮件配置表修改保存数据 """
    t = {
        'id':int, 't':int, 'title':str, 'content':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_REWARD_MAIL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

# ===============兑换码====================
# ========================================
@admin.route('/admin/exchange/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_exchange():
    """ 兑换码 """
    dic = None
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)
    name = request.args.get('name', '0')
    if name != "0":
        dic = {'name':name}
    ret = mongo.paginate(page=page, dic=dic)
    page_count = mongo.page_count(dic=dic)
    all_ret = mongo.distince(key="name")
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, code2mongo, mongo):
        return redirect(url_for('admin.admin_exchange'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_EXCHANGE,
             'page_count':page_count, 'all_ret':all_ret, 'name':name }

@admin.route('/admin/exchange/makexls/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def admin_exchange_makexls():
    import pyExcelerator
    name = request.args.get('name')
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)

    if name == '0':
        ret = mongo.all()
    else:
        dic = { 'name':name }
        ret = mongo.filter(dic)
    if name == '0':
        name = 'allcode'
    filePath = ''.join([os.path.dirname(admin.root_path), '/static/mongobackup/exchange/',name, '.xls'])
    w = pyExcelerator.Workbook()
    ws = w.add_sheet('sheet1')
    ws.write(0, 0, 'name')
    ws.write(0, 1, 'code')
    ws.write(0, 2, 'one')
    ws.write(0, 3, 'et')
    ws.write(0, 4, 'rid')
    ws.write(0, 5, 'ct')
    ws.write(0, 6, 'num')
    row = 1
    for r in ret:
        ws.write(row, 0, r['name'])
        ws.write(row, 1, r['code'])
        ws.write(row, 2, r['one'])
        ws.write(row, 3, r['et'])
        ws.write(row, 4, r['rid'])
        ws.write(row, 5, r['ct'])
        if 'num' in r:
            ws.write(row, 6, r['num'])
        row += 1
    w.save(filePath)
    return { "success":1 }


@admin.route('/admin/exchange/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_exchange_save():
    name = request.args.get('name')
    ct = request.args.get('ct')
    et = request.args.get('et')
    one = request.args.get('one')
    rid = request.args.get('rid')
#    svrs = request.args.get('svrs')
    length = int(request.args.get('length'))
    nums = request.args.get('nums')
    num = request.args.get('num')
    import uuid, random
    from luffy.views import FiveMethods
    try:
        mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)
        ret = mongo.all()
        start_time_str, end_time_str, start_time, end_time = FiveMethods.dealTime(ct, et, searchCondition='day')
        i = 0
        while 1:
            uuid_tmp = uuid.uuid1()
            uuid_tmp = str(uuid_tmp).replace('-', '')
            if length != 32:
                uuid_tmp = ''.join(random.sample(uuid_tmp, length))
            if uuid_tmp in ret:
                continue
            insert_val = {
                'name':name,
                'ct':int(start_time),
                'et':int(end_time),
                'one':int(one),
                'code':uuid_tmp,
                'num':int(num),
                #                'svrs':svrs,
                'rid':int(rid)
            }
            mongo.insert(insert_val)
            i += 1
            if i == int(nums):break
        return { 'success':'1'}
    except:
        print_traceback()
        return { 'success':'0' }

@admin.route('/admin/exchange/reset/', methods=('GET', 'POST'))
@moderator.require(401)
@resp(ret='json')
def admin_exchange_reset():
    id = request.args.get('id')
    name = request.args.get('name')
    ct = request.args.get('ct')
    et = request.args.get('et')
    one = request.args.get('one')
    rid = request.args.get('rid')
    num = request.args.get('num')
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)
    from luffy.views import FiveMethods
    start_time_str, end_time_str, start_time, end_time = FiveMethods.dealTime(ct, et, searchCondition='day')
    set_val = {'ct':int(start_time), 'et':int(end_time), 'one':int(one), 'rid':int(rid) }
    if num != 'None':
        set_val.update({'num':int(num)})
    insert_val = { '$set': set_val }
    querys = {'name':name }
    ret = mongo.filter(querys)
    for r in ret:
        args = { 'condition':{'_id':r['_id']}, 'data':insert_val }
        mongo.update(args)
    return {'success':1}


@admin.route('/admin/exchange/delete/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_exchange_delete():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)
        ret = mongo.first({"_id":id})
        dic = {'name':ret['name']}
        mongo.remove(dic)
#        five.delete(id)
        return { 'success':'1' }
    except:
        print_traceback()
        return { 'success':'0' }

@admin.route('/admin/exchange/data/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_exchange_data():
    try:
        id = int(request.args.get('id'))
        mongo = MongoFive(g.GAMEBASE,EXT.COLL_EXCHANGE, host=g.mongo_host)
        ret = mongo.get_by_id(int(id))
        from datetime import datetime
        date = datetime.fromtimestamp(ret['ct'])
        ret['ct'] = date.strftime('%Y-%m-%d')
        date = datetime.fromtimestamp(ret['et'])
        ret['et'] = date.strftime('%Y-%m-%d')
        return { 'success':'1', 'ret':ret}
    except:
        print_traceback()
        return { 'success':'0'}
#'======================================================='
#==============大喇叭码===============
@admin.route('/admin/horn/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_horn():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE,EXT.COLL_HORN, host=g.mongo_host)
    ret = mongo.paginate(page=page)
    page_count = mongo.page_count()
    all_ret = mongo.distince(key="name")
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_horn'))
    return { 'page':page, 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_HORN,
             'page_count':page_count, 'all_ret':all_ret }


@admin.route('/admin/horn/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_horn_save():
    t = {
        'id':int, 'type':int, 'msg':str, 'cond':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_HORN, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/funcs/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_funcs():
    SIDEBAR = 'ACHI'
    page = int(request.args.get('page','1'))
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_FUNCS, host=g.mongo_host)
    ret = mongo.paginate(page=page)
    page_count = mongo.page_count()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, mongo):
        return redirect(url_for('admin.admin_funcs'))
    return { 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_HORN, 'page':page, 'ret':ret,
             'page_count':page_count}


@admin.route('/admin/funcs/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_funcs_save():
    t = {
        'id':int, 'level':int, 'tid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_HORN, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'================用户数据表开始========================'
@admin.route('/baseuser/user/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_user():
    """ 用户表(user) """
    SIDEBAR = 'USER'
    page = request.args.get('page','1')
    user = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_USER, host=g.mongo_host)
    count = user.count()
    ret = user.paginate(page=int(page))
    page_count = user.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_USER,
            'page':int(page), 'page_count':page_count, 'count':count }

@admin.route('/baseuser/user/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_user_save():
    """ 用户表(user)修改保存 """
    t = {
        'id':int, 'name':str, 'pwd':str, 'email':str, 'UDID':str, 'DT':str,
        'tNew':int, 'tLogin':int, 'tLogout':int, 'fbLogin':int, 'fbChat':int
    }
    try:
        ret = from_html(method='POST', t=t)
        print '*'*20, ret
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_USER, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/baseuser/player/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_player():
    """ 玩家表(player) """
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_PLAYER, host=g.mongo_host)
    count = player.count()
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_PLAYER,
        'page':int(page), 'page_count':page_count, 'count':count }

@admin.route('/baseuser/player/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_player_save():
    """ 玩家表(player)修改保存 """
    t = {
        'id':int, 'name':str, 'uid':int, 'coin1':int, 'coin2':int, 'coin3':int,
        'level':int, 'exp':int, 'rid':int, 'train':int, 'vip':int, 'car':int,
        'tNew':int, 'tTotal':int, 'tLogin':int, 'tLogout':int, 'mapId':int,
        'pos':str, 'posId':int, 'stage':str, 'chapter':int, 'state':int,
        'funcs':int, 'fbLogin':int, 'fbChat':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_PLAYER, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=======================玩家属性表(p_attr)======================='
@admin.route('/baseuser/p/attr/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_attr():
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_ATTR, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_ATTR,
        'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/attr/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_attr_save():
    t = {
        'id':int,'pid':int,'hitFateNum1':int,'hitFateNum2':int,
        'hitFateLastTime':int,'endTasks':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_ATTR, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=======================玩家角色表(p_role)======================='
@admin.route('/baseuser/p/role/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_role():
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_ROLE, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_ROLE,
            'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/role/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_role_save():
    t = {
        'id':int,'pid':int, 'rid':int, 'status':int, 'sk':int, 'armLevel':int,
        'eq1':int, 'eq2':int, 'eq3':int, 'eq4':int, 'eq5':int, 'eq6':int,
        'fate1':int, 'fate2':int, 'fate3':int, 'fate4':int, 'fate5':int,
        'fate6':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_ROLE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=======================玩家角色表(p_equip)======================='
@admin.route('/baseuser/p/equip/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_equip():
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_EQUIP, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_EQUIP,
            'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/equip/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_equip_save():
    t = {
        'id':int,'pid':int, 'eid':int, 'level':int, 'used':int,
        'isTrade':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_EQUIP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

#'======================================================='
#'=======================玩家角色表(p_item)======================='
@admin.route('/baseuser/p/item/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_item():
    """ 玩家物品表页面 """
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_ITEM, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_ITEM, 'page':int(page),'page_count':page_count }

@admin.route('/baseuser/p/item/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_item_save():
    """ 玩家物品表保存 """
    t = {
        'id':int,'pid':int,'iid':int,'count':int,'isTrade':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_ITEM, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/baseuser/p/fate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_fate():
    """ 玩家命格表页面 """
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_FATE, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_FATE,
            'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/fate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_fate_save():
    """ 玩家命格表保存 """
    t = {
        'id':int,'pid':int,'fid':int,'level':int, 'exp':int, 'used':int,
        'isTrade':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_FATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/baseuser/p/position/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_position():
    """ 玩家阵型表页面 """
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_POSITION, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_POSITION,
            'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/position/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_position_save():
    """ 玩家阵形表保存 """
    t = {
        'id':int,'pid':int,'posId':int,'level':int,'s1':int,'s2':int,
        's3':int,'s4':int,'s5':int, 's6':int,'s7':int,'s8':int,'s9':int,
        's10':int,'s11':int, 's12':int,'s13':int, 's14':int,'s15':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_POSITION, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/baseuser/p/task/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_task():
    """ 玩家任务表 """
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    player = MongoFive(g.GAME_BASEUSER,EXT.BASEUSER_P_TASK, host=g.mongo_host)
    ret = player.paginate(page=int(page))
    page_count = player.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_TASK, 'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/task/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def baseuser_p_task_save():
    """ 玩家任务表保存 """
    t = {
        'id':int,'pid':int,'tid':int, 'step':int, 'status':int, 'isRun':int,
        'rid':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAME_BASEUSER, EXT.BASEUSER_P_TASK, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/baseuser/p/map/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_map():
    """ 玩家地图"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_map = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_MAP, host=g.mongo_host)
    ret = p_map.paginate(page=int(page))
    page_count = p_map.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_MAP,
             'page':int(page), 'page_count':page_count }


@admin.route('/baseuser/p/car/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_car():
    """ 玩家坐骑"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_map = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_CAR, host=g.mongo_host)
    ret = p_map.paginate(page=int(page))
    page_count = p_map.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_CAR,
             'page':int(page), 'page_count':page_count }


@admin.route('/baseuser/p/mail/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_mail():
    """ 玩家邮件"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_MAIL, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_MAIL,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/social/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_social():
    """ 玩家社交"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_SOCIAL, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_SOCIAL,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/arena/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_arena():
    """ 玩家竞技场"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_ARENA, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_ARENA,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/buff/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_buff():
    """ 玩家buff"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_BUFF, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_BUFF,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/deep/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_deep():
    """ 玩家深渊"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_DEEP, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_DEEP,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/tbox/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_tbox():
    """ 玩家时光盒"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_TBOX, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_TBOX,
             'page':int(page), 'page_count':page_count }

@admin.route('/baseuser/p/wait/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def baseuser_p_wait():
    """ 玩家待收物品"""
    SIDEBAR = 'USER'
    page = request.args.get('page',1)
    p_mail = MongoFive(g.GAME_BASEUSER, EXT.BASEUSER_P_WAIT, host=g.mongo_host)
    ret = p_mail.paginate(page=int(page))
    page_count = p_mail.page_count()
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.BASEUSER_P_WAIT,
             'page':int(page), 'page_count':page_count }

# =====================成就系统=============
@admin.route('/achi/day/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def achi_day():
    """ achi day """
    SIDEBAR = 'ACHI'
    page = request.args.get('page',1)
    page_count = 0
    achi = MongoFive(g.GAMEBASE,EXT.COLL_ACHI_DAY, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi):
        return redirect(url_for('admin.achi_day'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ACHI_DAY,
            'page':int(page), 'page_count':page_count }

@admin.route('/achi/day/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def achi_day_save():
    """ achi day保存 """
    t = {
        'id':int, 'name':str,'info':str,'rid':int,'target':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ACHI_DAY, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}


@admin.route('/achi/eternal/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def achi_eternal():
    """ 成就 eternal """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    achi = MongoFive(g.GAMEBASE,EXT.COLL_ACHI_ETERNAL, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi):
        return redirect(url_for('admin.achi_eternal'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_ACHI_ETERNAL,
            'page':int(page), 'page_count':page_count }

@admin.route('/achi/eternal/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def achi_eternal_save():
    """ 成就 eternal保存 """
    t = {
        'id':int, 'name':str,'info':str,'rid':int,'target':str
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_ACHI_ETERNAL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/gem/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_gem():
    """ 珠宝表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    achi = MongoFive(g.GAMEBASE,EXT.COLL_GEM, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi):
        return redirect(url_for('admin.admin_gem'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_GEM,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/gem/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_gem_save():
    """ 珠宝表保存 """
    t = {
        'id':int, 'name':str,'info':str,'act':str, 'quality':int,
        'rate':int, 'price':int, 'parts':str, 'type':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_GEM, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/gem/level/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_gem_level():
    """ 珠宝等级表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    achi = MongoFive(g.GAMEBASE,EXT.COLL_GEM_LEVEL, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi, coll=EXT.COLL_GEM_LEVEL):
        return redirect(url_for('admin.admin_gem_level'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_GEM_LEVEL,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/gem/level/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_gem_level_save():
    """ 珠宝等级保存 """
    t = {
        'id':int,'gid':int,'level':int,'STR':float,'DEX':float,'VIT':float,
        'INT':float,'HP':float,'ATK':float,'STK':float,'DEF':float,
        'SPD':float,'MP':int,'MPS':int,'MPR':int,'HIT':float,'MIS':float,
        'BOK':float,'COT':float,'COB':float,'CRI':float,'CPR':float,
        'PEN':float,'TUF':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_GEM_LEVEL, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/gem/up/rate/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_gem_up_rate():
    """ 珠宝等级表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    achi = MongoFive(g.GAMEBASE, EXT.COLL_GEM_UP_RATE, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi):
        return redirect(url_for('admin.admin_gem_up_rate'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_GEM_UP_RATE,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/gem/up/rate/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_gem_up_rate_save():
    """ 珠宝等级保存 """
    t = {
        'id':int, fq:int,flv:int,tq:int,tlv:int,succ:int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_GEM_UP_RATE, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/gem/shop/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_gem_shop():
    """ 珠宝等级表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    achi = MongoFive(g.GAMEBASE, EXT.COLL_GEM_SHOP, host=g.mongo_host)
    ret = achi.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, achi):
        return redirect(url_for('admin.admin_gem_shop'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_GEM_SHOP,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/gem/shop/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_gem_shop_save():
    """ 珠宝等级保存 """
    t = {
        'id':int,'gid':int,'lv':int, 'r':int,'coin1':int,'coin2':int,'coin3':float
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_GEM_SHOP, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/day/lucky/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_day_lucky():
    """ 珠宝等级表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    day = MongoFive(g.GAMEBASE, EXT.COLL_DAY_LUCKY, host=g.mongo_host)
    ret = day.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, day):
        return redirect(url_for('admin.admin_day_lucky'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DAY_LUCKY,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/day/lucky/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_day_lucky_save():
    """ 珠宝等级保存 """
    t = {
        'id':int,'rid':int,'srate':int, 'lrate':int,'cond':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DAY_LUCKY, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

@admin.route('/admin/day/sign/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def admin_day_sign():
    """ 珠宝等级表 """
    SIDEBAR = 'ACHI'
    page_count = 0
    page = request.args.get('page',1)
    day = MongoFive(g.GAMEBASE, EXT.COLL_DAY_SIGN, host=g.mongo_host)
    ret = day.all()
    xlsfile = request.files.get('xlsfile')
    if xlsupload(xlsfile, admin, xls2mongo, day):
        return redirect(url_for('admin.admin_day_sign'))
    return { 'ret':ret, 'SIDEBAR':SIDEBAR, 'coll':EXT.COLL_DAY_SIGN,
            'page':int(page), 'page_count':page_count }

@admin.route('/admin/day/sign/save/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def admin_day_sign_save():
    """ 珠宝等级保存 """
    t = {
        'id':int,'need':int,'tid':int, 'vip':int
    }
    try:
        ret = from_html(method='POST', t=t)
        querys = {EXT.KEY_MONGO_ID: ret.pop(EXT.KEY_ID)}
        g.mongo_drive.update(g.GAMEBASE, EXT.COLL_DAY_SIGN, querys, ret)
    except:
        print_traceback()
        return {'success':0}
    return {'success':1}

# 生成JSON
@admin.route('/create/json/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def create_json():
    """ 生成json """
    file_list = None
    values    = None
    SIDEBAR = 'ACHI'
    saved   = False
    STRING_RESURL, STRING_VALUE = 'resUrl', 'value'
    STRING_ACTIVITY = 'activity'
    images = request.files.get('uploadify')
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
    res_querys = {EXT.KEY_KEY: STRING_RESURL}
    # 查找res地址
    res_ret = mongo.find_one(res_querys)
    if res_ret:
        # url = '/'.join(res_ret[STRING_VALUE].split('//')[1].split('/')[2:])
        # url = ''.join([game_config.RESOUCE_ROOT, url, 'resources/activity'])
        url = '/data/webroot/www/resources/activity'
        # 查找当前目录下的所有文件
        if os.path.isdir(url):
            file_list = os.listdir(url)
    if images:
        images.save(''.join([url, '/',images.filename]))
        saved = True
    querys = {EXT.KEY_KEY: STRING_ACTIVITY}
    ret = mongo.find_one(querys)
    if ret:
        import json
        values = json.dumps(ret[STRING_VALUE])
        file_list = json.dumps(file_list)
    return { 'SIDEBAR':SIDEBAR, 'values':values, 'file_list':file_list, 'saved':saved }

@admin.route('/create/json/edit/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def create_json_edit():
    """ 生成json """
    STRING_CONDITION, STRING_DATA = 'condition', 'data'
    STRING_ACTIVITY, STRING_VALUE = 'activity', 'value'
    values = request.form.get('values')
    mongo = MongoFive(g.GAMEBASE, EXT.COLL_GCONFIG, host=g.mongo_host)
    querys = {EXT.KEY_KEY: STRING_ACTIVITY}
    import json
    values = json.loads(values)
    args = {}
    args[STRING_CONDITION] = querys
    args[STRING_DATA] = {EXT.MONGO_SET:{STRING_VALUE:values}}
    mongo.update(args=args)
    return { 'ret':1 }

@admin.route('/common/search/', methods=('GET','POST'))
@moderator.require(401)
@resp()
def common_search():
    """ 通用查询 """
    db = request.form.get('db')
    querys = request.form.get('querys')
    sort_key = request.form.get('sort_key')
    sort_by  = int(request.form.get('sort_by'))
    collections = request.form.get('collection')
    mongo = MongoFive(db, collections, host=g.mongo_host)
    import json
    if querys != '':
        querys = json.loads(querys)
    else:
        querys = {}
    if sort_key != '':
        sort = sort_key
    else:
        sort = None
    ret = mongo.filter(querys, sort=sort, sort_by=sort_by)
    return { 'ret':ret, 'db':db, 'table':collections }

@admin.route('/common/search/edit/', methods=('GET','POST'))
@moderator.require(401)
@resp(ret='json')
def common_search_edit():
    """ 修改数据库 """
    type_dict = {'str':str, 'int':int, 'float':float}
    db      = request.form.get('db')
    table   = request.form.get('table')
    key     = request.form.get('key')
    value   = request.form.get('value')
    t       = request.form.get('t')
    tmp_id  = int(request.form.get('id'))
    querys  = {EXT.KEY_MONGO_ID:tmp_id}
    inserts = {key:type_dict[t](value)}
    g.mongo_drive.update(db, table, querys, inserts, _set=True)
    return { 'success':1 }
