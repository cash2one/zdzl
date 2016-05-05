#coding=utf-8
from flask import Blueprint, render_template, request, current_app,\
    redirect, g,jsonify,Session,session,send_from_directory, url_for

from luffy.resp import resp  
from bson.objectid import ObjectId 
from luffy.forms import LoginForm,RegForm,FindPwdForm,PasswordForm 
import os
frontend = Blueprint('frontend', __name__,static_folder='static')


@frontend.route("/", methods = ("GET", "POST"))
@resp()
def index():

    return redirect(url_for('frontend.login'))

@frontend.route("/link/", methods = ("GET", "POST"))
@resp()
def link():

    return {}


@frontend.route("/login/", methods = ("GET", "POST"))
@resp()
def login():
    '''
    登录系统
    '''    
    return LoginForm(next = request.args.get('next',None))

@frontend.route("/reg/", methods = ("GET", "POST"))
@resp()
def reg():
    '''
    注册用户，注意无需激活
    '''
    return RegForm()


@frontend.route("/forgot/", methods = ("GET", "POST"))
@resp()
def forgot():
    '''
    忘记密码
    '''
    return FindPwdForm()

@frontend.route("/password/<string:key>/<string:id>/", methods = ("GET", "POST"))
@resp()
def password(key,id):
    '''
    找回密码邮件后重设密码
    '''
    return PasswordForm(uid = id,token = key)

 



