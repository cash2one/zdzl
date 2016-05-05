#coding=utf-8
import re
from flask import session,current_app as app,url_for,request
## from tprincipal import identity_changed, Identity
from flask.ext.principal import identity_changed, Identity
#from flask.ext.wtf import Form, TextAreaField, HiddenField, BooleanField,RadioField, \
#        PasswordField, SubmitField, TextField, ValidationError, DateField,IntegerField,SelectField,\
#        required, email as is_email, equal_to, regexp,Length

from wtforms import Form, TextAreaField, HiddenField, BooleanField,RadioField,\
    PasswordField, SubmitField, TextField, ValidationError, DateField,IntegerField,SelectField
from wtforms.validators import required, email as is_email, equal_to, regexp,Length

from flask.ext.mongoengine.wtf import model_form
from flask.ext.mongoengine.wtf.fields import QuerySetSelectField

from luffy.resp import BaseAjaxForm
from luffy.models import AdminUser
from datetime import date
from time import mktime
from bson.objectid import ObjectId
import wtforms
from wtforms import validators


from luffy.models.u import LangIDForm


class MailSendForm(BaseAjaxForm):
    tos = TextField(u"收件人列表",description= u'用户昵称或登录帐号（即邮件地址,以空格隔开）,留空：全部用户 0：未激活用户 1：已激活用户 2：网站编辑 3：管理员')
    subject = TextField(u"邮件标题",description= u'请输入要发送的邮件标题',validators=[required(u'请输入邮件标题')])
    content = TextAreaField(u"邮件正文",description= u'请输入要发送的邮件正文',validators=[required(u'请输入邮件正文。')])

    def validate_tos(self,field):
        u_list = []
        tmp = field.data.strip()
        if tmp == '':
            u_list = AdminUser.query.all()
        elif tmp == '0':
            u_list = AdminUser.query.filter(AdminUser.role == AdminUser.UNACTIVE).all()
        elif tmp == '1':
            u_list = AdminUser.query.filter(AdminUser.role != AdminUser.UNACTIVE).all()
        elif tmp == '2':
            u_list = AdminUser.query.filter(AdminUser.role == AdminUser.MODERATOR).all()
        elif tmp == '3':
            u_list = AdminUser.query.filter(AdminUser.role == AdminUser.ADMIN).all()
        else:
            tmp = tmp.split(' ')
            for item in tmp:
                if item.find('@')!=-1:
                    u = AdminUser.query.filter(User.username == item).first()
                else:
                    u = AdminUser.query.filter(User.nickname == item).first()
                if u is not None: u_list.append(u)
        if len(u_list)<=0:
            raise ValidationError,u'无收件人。'
        ret = []
        for u in u_list:
            ret.append(u.username)
        field.data = ret

    def _save_db(self):
        '开始发送邮件'
        from luffy.helps import mail_send
        mail_send(self.tos.data,self.subject.data,context = self.content)
        return True,u'发送完毕'


class UserEditForm(BaseAjaxForm):
    username = TextField(u"登陆账号",validators = [is_email(message=u'账号填写错误')])
    nickname = TextField(u"用户昵称")
    psd = PasswordField(u"密码",description= u'请输入密码')
    value = IntegerField(u'积分')
    sex = RadioField(u'性别',choices=[(0,u'男'), (1,u'女')], default = 0, coerce = int, description = u'性别')

    def validate_username(self,field):
        field.data = field.data.lower().strip()
        if self.obj.username == field.data:
            return True
        u = User.query.filter(User.username == field.data).count()
        if u!=0 :
            raise ValidationError,u'请保证登录帐号的唯一。'

    def _save_db(self):
        self.populate_obj(self.obj)
        if self.psd.data != '':
            self.obj.password = self.psd.data
        self.obj.save()
        return True,u'保存成功'


class UserForm(BaseAjaxForm):
    email = TextField(u"匹配用户")
    reg_begin = DateField(u"注册开始时间",default = date.today())
    reg_end = DateField(u"注册结束时间",default = date.today())
    lastlogin_begin = DateField(u"登陆开始时间",default = date.today())
    lastlogin_end = DateField(u"登陆结束时间",default = date.today())

    ban= SelectField(u"账户是否禁用",choices = [(0,u'不筛选'),(1,u'是'),(2,u'否')],coerce = int,default = 0)
    role = SelectField(u'角色',choices = [(5,u'不筛选'),(0,u'推广用户'),(1,u'未激活用户'),(100,u'普通用户'),(200,u'网站编辑'),(300,u'管理员')],coerce = int,default = 5)

    order = SelectField(u"排序", choices = [(0,u'注册时间降序'),(1,u'注册时间升序'),(2,u'最后登录时间降序'),(3,u'最后登录时间升序')],coerce = int)
    page = HiddenField(default = 1)
    nums = SelectField(u"每页显示条数", choices = [(10,'10'),(20,'20'),(30,'30'),(50,'50'),(100,'100')],default = 30,coerce = int)


    def v_date(self,field):
        if len(field.errors) >0:
            return False
        if field.data:
            field.data = mktime(field.data.timetuple())

    def validate_reg_begin(self,field):
        return self.v_date(field)

    def validate_reg_end(self,field):
        return self.v_date(field)

    def validate_lastlogin_begin(self,field):
        return self.v_date(field)

    def validate_lastlogin_end(self,field):
        return self.v_date(field)

    def _save_db(self):

        query = AdminUser.query

        if self.email.data != '':
            regex = r"^.*" + self.email.data+ ".*$"
            query.filter({User.email : re.compile(regex, re.IGNORECASE)})

        if self.reg_end.data > self.reg_begin.data:
            query.filter(User.regdate >= self.reg_begin.data)
            query.filter(User.regdate < self.reg_end.data + 86400)

        if self.lastlogin_end.data > self.lastlogin_begin.data:
            query.filter(User.lastlogin >= self.lastlogin_begin.data)
            query.filter(User.lastlogin < self.lastlogin_end.data + 86400)

        if self.ban.data != 0:
            query.filter(User.ban == (self.ban.data == 1))


        if self.role.data != 5:
            query.filter(User.role == self.role.data)

        if self.order.data == 0:
            query.descending(User.regdate)
        elif self.order.data == 1:
            query.ascending(User.regdate)
        elif self.order.data == 2:
            query.descending(User.lastlogin)
        else:
            query.ascending(User.lastlogin)

        ret = query.paginate(int(self.page.data),per_page = self.nums.data)

        return True,ret


class QaccoutForm(Form):
    """
    用于订单查询
    """
    order_token = wtforms.TextField(u"订单号")
    submit = wtforms.SubmitField(u"提交")


class FilterActivityForm(Form):
    """
    活动设置表单
    """
    filter_sids = wtforms.SelectField(u"根据服务器id选择活动")
    filter_sysids = wtforms.SelectField(u"根据活动所属系统过滤")



class LangForm(wtforms.Form):
    """翻译功能表"""
    current_lang = QuerySetSelectField(label=u'选择语言', label_attr='lang_name')
    filter_entries = wtforms.SelectField(u'显示筛选')
    filter_show = wtforms.SelectField(u'根据属性显示', choices=[(0, u'全部'), (1, u'已翻译'), (2, u'未翻译')], coerce=int)
    # add_lang_id = wtforms.StringField(u'语言id', [validators.length(max=30)])
    # add_lang_name = wtforms.StringField(u'名称', [validators.length(max=30)])
    lang = wtforms.FormField(LangIDForm)
    add_lang_submit = wtforms.SubmitField(u'添加')
    add_collection_name = wtforms.StringField(u'mongo表名')
    add_field_name = wtforms.StringField(u'mongo字段名')
    add_path_submit = wtforms.SubmitField(u'添加')


class CoinQueryForm(Form):
    """
    消耗元宝查询
    """

    date_beg = wtforms.DateField(u'开始日期', format='%Y-%m-%d')
    date_end = wtforms.DateField(u'结束日期', format='%Y-%m-%d')
    filter_coins_gt = wtforms.SelectField(u'数目大于', choices=[(0, '全部元宝'), (1, u'真元宝'), (2, u'绑元宝')], coerce=int)
    coins_num = wtforms.IntegerField()
    pid = wtforms.IntegerField(u'角色id')
    filter_coins_type = wtforms.SelectField(u'流转类型', choices=[(1, '消耗元宝'), (2, '添加元宝')], coerce=int)
    submit =  wtforms.SubmitField(u'查询')

class MailForm(Form):
    """邮件参数表"""
    platform = wtforms.SelectField(u'发送平台', coerce=int)

class PUserInfo(Form):
    """平台用户信息"""
    id = wtforms.IntegerField(u'id')
    userName = wtforms.StringField(u'用户名')
    lastIn = wtforms.IntegerField(u'上次登录时间')
    email = wtforms.StringField(u'电子邮箱')
    createDate = wtforms.IntegerField(u'创建时间')

    def order_keys(self):
        """ Iterate form fields in their order of definition on the form. """
        for name, _ in self._unbound_fields:
            if name in self._fields:
                yield name
