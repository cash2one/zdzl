#coding=utf-8
from flask.ext.wtf import Form, TextAreaField, BooleanField, RadioField,TextField, \
        SubmitField, PasswordField,ValidationError, DateField, required
        
from luffy.resp import BaseAjaxForm
        
        
class RoleLevelForm(BaseAjaxForm):
    level = TextField(u'等级',validators=[required(message=u'请输入等级')])
    exp = TextField(u'经验', validators=[required(message=u'请输入经验')])
    siteExp = TextField(u'打坐经验', validators=[required(message=u'打坐经难')])
    
    def validate_level(self, field):
        if field.data == '':
            raise ValidationError, u"等级不能为空。"