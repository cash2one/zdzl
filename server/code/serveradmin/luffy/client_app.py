# -*- coding:utf-8 -*-

from pymongo import MongoClient

from flask import Flask, g, session, request, flash, redirect, jsonify, url_for,render_template
from flask_cache import Cache
from luffy.forms.app_service import AppConfigForm
import config as game_config

application = Flask(__name__.split('.')[0])
application.config['WTF_CSRF_ENABLED'] = False
application.config['SECRET_KEY'] = '12389'
application.config['CACHE_DEFAULT_TIMEOUT'] = 60
cache = Cache(application, config={'CACHE_TYPE': 'simple'})
application.config.from_object(game_config.BaseConfig())
WEB_COLL_PLATFORM = 'platform'

def create_database_connection():
    """
    should be called in handler view function before flask-0.10
    """
    if not hasattr(g, 'mongo'):
        h = application.config.get('MONGOALCHEMY_SERVER')
        p = int(application.config.get('MONGOALCHEMY_PORT'))
        g.web_db = application.config.get('MONGOALCHEMY_DATABASE')
        mongo = MongoClient(host=h, port=p)
        g.mongo = mongo


# @application.route('/edit', methods=['GET', 'POST'])
# def platform_config_edit():
#     editform = AppConfigForm(request.form)
#     kwargs = {'form': editform, 'vertical': True}
#     description = u'例如: %s, 其中124为平台id' % \
#                   url_for('platform_dwonload', platform=124, _external=True)
#     editform.download_url.description = description
#     create_database_connection()
#     db = g.mongo[g.web_db]
#     coll = db[WEB_COLL_PLATFORM]
#     if editform.validate_on_submit():
#         key = 'platform'
#         pdata = editform.data
#         coll.update({key: pdata[key]}, pdata, upsert=True, multi=False)
#         flash(u'成功提交, 当前记录数目%s' % coll.count())
#     data_entries = coll.find()
#     kwargs.update({'data': data_entries})
#     return render_template('service/edit.html', **kwargs)


@application.route('/dlplatform/', methods=['GET', 'POST'])
def dl_agent():
    plf = request.args.get('plf')
    create_database_connection()
    db = g.mongo[g.web_db]
    key = 'platform'
    coll = db[WEB_COLL_PLATFORM]
    one = coll.find_one({key: int(plf)})
    if one:
        plist = one.get('download_url')
        if plist:
            return redirect(url_for('.platform_dwonload', platform=1))
        mobile_url = one.get('mobile_url')
        if mobile_url:
            client = request.environ['HTTP_USER_AGENT']
            if ('iphone' in client) or ('ipad' in client) or ('ipod' in client):
                return redirect(mobile_url)
        web_url = one.get('web_url')
        if web_url:
            return redirect(web_url)





@application.route('/download/<platform>.plist')
@cache.cached()
def platform_dwonload(platform):
    # return "download platform %s" % platform
    # dl_url = 'http://download.52yh.com/zdzl.ipa'
    # icon_url = 'http://zl.52yh.com/iphone/icon.png'
    # bid = 'com.efun.zl91'
    # game_name = u'指点真龙'
    create_database_connection()
    db = g.mongo[g.web_db]
    key = 'platform'
    coll = db[WEB_COLL_PLATFORM]
    one = coll.find_one({key: int(platform)})
    if not one:
        one = {}
    kwargs = {"model": one}
    return render_template('service/zl.plist', **kwargs)


@application.template_filter()
def url(action, filename, _external=False):
    return url_for(action, filename=filename, _external=_external)
