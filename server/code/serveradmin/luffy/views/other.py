#coding=utf-8

from flask import Blueprint, request, current_app, redirect, g,session,url_for
from luffy.permissions import other as o
from luffy.resp import resp
from luffy.models import FilterPlayer, RenRate
from bson.objectid import ObjectId

other = Blueprint('other', __name__,static_folder='static')

@other.route("/", methods=("GET", "POST"))
@o.require(401)
@resp()
def index():
    return {'SIDEBAR':'other'}

@other.route('/server/filter/', methods=('GET', 'POST'))
@o.require(401)
@resp()
def server_filter():
    """  """
    page = int(request.args.get('page', '1'))
    filter_player = FilterPlayer.query.paginate(page, per_page=50)
    count = FilterPlayer.query.count()
    tmp = count%50 
    page_count = count/50
    if tmp != 0:
        page_count += 1
    return {'SIDEBAR':'other', "ret":filter_player, "page":page, "page_count":page_count}

@other.route('/server/filter/order/', methods=('GET', 'POST'))
@o.require(401)
@resp(ret='json')
def server_filter_order():
    """  """
    STR_TYPE, STR_NAMES, STR_T = 'opType', 'names', 't'
    opType = request.form.get(STR_TYPE)
    names = request.form.get(STR_NAMES)
    t = request.form.get(STR_T)
    if t:
        t=int(t)
    if opType == 'new':
        names = names.split("\n")
        for item in names:
            if item != '':
                filter_player = FilterPlayer()
                filter_player.n = item
                filter_player.t = t
                filter_player.save()
    elif opType == 'edit':
        sid = request.form.get("id")
        player = FilterPlayer.query.get_or_404(ObjectId(sid))
        player.n = names
        player.t = t 
        player.save()
    elif opType == 'del':
        print 'opType', opType
        sid = request.form.get("id")
        player = FilterPlayer.query.get_or_404(ObjectId(sid))
        player.remove()
    return {'SIDEBAR':'other', 'success':1}


@other.route('/rate/order/', methods=('GET', 'POST'))
@o.require(401)
@resp(ret='json')
def rate_order():
    """  """
    STR_T, STR_R, STR_S = 't', 'r', 's'
    t = float(request.form.get(STR_T))
    r = float(request.form.get(STR_R))
    s = request.form.get(STR_S)
    if RenRate.change_r(t,r,s):
        return {'success':1}
    return {'success':0}