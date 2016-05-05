# -*- coding:utf-8 -*-


from flask import url_for
from flask_wtf import Form
from wtforms import TextAreaField, HiddenField, BooleanField,RadioField,\
    TextField, ValidationError, DateField,IntegerField, SubmitField, SelectField
from wtforms.validators import DataRequired, URL
from webapi import SNS_MAP


class AppConfigForm(Form):
    """
    苹果软件配置
    """
    platform = SelectField(u'选择平台', choices=[(k, v) for k, v in SNS_MAP.iteritems() if k > 0], coerce=int)
    download_url = TextField(u'下载地址')
    name = TextField(u'游戏名称')
    icon = TextField(u'图标')
    bundleid = TextField(u'软件包的bundle-id')
    web_url = TextField(u'web下载地址',
            validators=[DataRequired(u'web下载地址不能为空'), URL(message=u"地址格式不正确")])
    mobile_url = TextField(u'手机端下载地址')

