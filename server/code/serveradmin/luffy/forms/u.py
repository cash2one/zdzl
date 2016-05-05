#coding=utf-8
import re
from flask import session,current_app as app,url_for,request
from tprincipal import identity_changed, Identity
#from flask.ext.wtf import Form, TextAreaField, HiddenField, BooleanField,RadioField, \
#        PasswordField, SubmitField, TextField, ValidationError, DateField,IntegerField,SelectField,\
#        required, email as is_email, equal_to, regexp,Length
from wtforms import Form, TextAreaField, HiddenField, BooleanField,RadioField, \
        PasswordField, SubmitField, TextField, ValidationError, DateField,IntegerField,SelectField
from wtforms.validators import required, email as is_email, equal_to, regexp,Length
        
from luffy.resp import BaseAjaxForm 
from luffy.models import AdminUser, UserLog
#from redis import Redis
from luffy.helps import md5
from bson.objectid import ObjectId
import time

class LoginForm(BaseAjaxForm):
    next = HiddenField()
    username = TextField(u"邮箱", validators=[required(message=u'请输入您的邮箱'), is_email(message=u"邮箱帐号填写错误")],description = u'登录邮箱')
    password = PasswordField(u"密码", validators=[required(message=u'请输入密码')],description= u'请输入密码')
    remember = BooleanField(u'下次自动登录') 
    submit = SubmitField(u'登录')
    
    def _save_db(self): 
        user,auth = AdminUser.query.authenticate(self.username.data.lower(), self.password.data)
        if auth:
            if user.ban:
                return False,u'很抱歉，您的帐号以被管理员禁用，请联系管理员：' + ','.join(app.config.get('ADMINS',[]))
            user_log = UserLog()
            user_log.u = user.username
            user_log.ty = 1
            user_log.t = time.time()
            user_log.save()
            return self.Login(user.mongo_id,self.remember.data, self.next.data)
        else:
            return False,u'登录失败，用户名或者密码错误'
        
    @classmethod
    def Login(cls,user_id,remeber,next_url = None):
        '''
        保存登录信息
        '''
        #记住密码
        # session.new = True
        session.permanent = remeber
        #保存session
        identity_changed.send(app._get_current_object(),identity=Identity(user_id))
        if next_url is None or not next_url or next_url == request.path:
            next_url = url_for('user.index')

        #跳转到链接
        return 'url',next_url
    
class RegForm(BaseAjaxForm):
    username = TextField(u"我的邮箱", validators=[required(message=u'请输入常用的邮箱。'), is_email(message=u"请输入正确的邮箱地址。")],description = u'请输入常用的邮箱,用于登录')
    password = PasswordField(u"密码", validators=[required(message=u'请输入密码'),Length(min = 6, max = 20, message = u'密码位数应该在6至20个之间')],description= u'请输入密码')
    sex = RadioField(u'性别',choices=[(0,u'男'), (1,u'女')], default = 0, coerce = int, description = u'性别')
    nickname = TextField(u"昵称", validators=[required(message=u'请输入昵称'),regexp(u"^[\u4E00-\u9FA5_A-Za-z0-9]+$",re.IGNORECASE,message= u'支持中英文、数字或者“_”。')],description = u'请输入昵称，用户公开场合显示')
    
    def validate_username(self, field):
        if len(field.errors) >0:
            return False 
        field.data = field.data.lower().strip()
        if ' ' in field.data:
            raise ValidationError, u"请填写正确的邮箱地址，邮箱地址不能带有空格符。"
        user = AdminUser.query.filter(AdminUser.username == field.data.lower()).first()
        if user:
            raise ValidationError, u"邮箱已被注册。"
        field.data = field.data.lower()
    
    def validate_nickname(self,field):
        if len(field.errors) >0:
            return False
        #Length(min = 4, max = 30, message = ),
        field.data = field.data.lower().strip() 
        lth = len(field.data.encode('utf-8'))
        if lth < 6 or lth > 20: 
            raise ValidationError, u'可输入4-30位，包含英文、数字和中文'

        user = AdminUser.query.filter(AdminUser.nickname == field.data).first()
        if user:
            raise ValidationError, u"此昵称太受欢迎，已有人抢了。" 
        
    def _save_db(self): 
        self.obj = AdminUser()
        self.populate_obj(self.obj)
        if self.username.data == 'admin@efun.com':
            self.obj.role = 300
        #self.obj.init_reg()
        self.obj.save() 
        return LoginForm.Login(self.obj.mongo_id,False, url_for('user.index')) 
    
class FindPwdForm(BaseAjaxForm):
    username = TextField(u"登录名", validators=[required(message=u'请输入您的邮箱'),  is_email(message=u"邮箱帐号填写错误")],description = u'邮箱地址')
    
    def validate_username(self,field):
        self.user = AdminUser.query.filter(AdminUser.username == field.data.lower().strip()).first()
        if self.user is None:
            raise ValidationError, u"您填写的Email不存在，请确认您是否使用该邮件注册了。"
        
#    def _save_db(self):
#        user = self.user
#        if user is None:
#            return False,u'找回密码失败，未知错误'
#
#        r = Redis()
#        r_key = 'FIND_PSW_USER_' + str(user.mongo_id)
#        last_time = r.get(r_key)
#        if last_time:
#            return False,u'为节省资源，一小时内只能发送一封找回密码邮件'
#        else:
#            active_key = md5(str(user.mongo_id) + app.config.get('SECRET_KEY','damy'))
#            r.set(r_key,active_key)
#            r.expire(r_key, 3600)
#            mail_send(user.username,app.config.get('SITE_NAME',u'开源项目') + u'确认您的密码重设申请','findpwd_text',user,active_key)
#            return True,u'帐号确认成功！接下来您需要重设密码，我们已经发送了一封重设密码的电子邮件到：' + user.username

class PasswordForm(BaseAjaxForm):
    token = HiddenField()
    uid = HiddenField()
    pwd = PasswordField(u"新密码", validators=[required(message=u"请填入密码"),Length(min = 6, max = 20, message = u'密码位数应该在6至20个之间')],description = u'设置新密码')
    password_again = PasswordField(u"重复新密码", validators=[equal_to("pwd", message=u"两次填写的密码必须一致")],description = u'确认密码')
    
    def _init(self):
        user = AdminUser.query.get_or_404(ObjectId(self.uid.data))
        self.user = user
    
#    def _save_db(self):
#        r = Redis()
#        r_key = 'FIND_PSW_USER_' + str(self.user.mongo_id)
#        active_key = r.get(r_key)
#        if active_key != self.token.data:
#            return False,u'对不起，您的找回密码邮件已过期。请重新使用找回密码功能接收最新邮件。'
#        self.user.password = self.pwd.data
#        self.user.save()
#        return True,u'设置密码成功，请直接点击登录'