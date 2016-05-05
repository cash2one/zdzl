#coding=utf-8
from functools import wraps

from flask import render_template,request,abort,json,jsonify,current_app,flash, sessions
from flask import redirect, url_for,Response
from flask.ext.wtf import Form
from jinja2 import Markup
# import json
from werkzeug.wrappers import BaseResponse
from .helps import build_url

def resp(template = None,ltemplate = None,ret = None):
    """ 基本的返回 """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs): 
            #kwargs['ltemplate'] = ltemplate
            ctx = f(*args, **kwargs)
            if isinstance(ctx, BaseAjaxForm):
                return ctx.exe(template,ltemplate)
            elif isinstance(ctx,BaseResponse) or isinstance(ctx,unicode):
                return ctx
            elif ret == 'json':
                if isinstance(ctx,dict):
                    # return json.dumps(ctx)
                    return jsonify(ctx)   
            elif ret == 'base':
                r = BaseAjaxForm()
                if ctx[0]:
                    return r.SuccMsg(ctx[1])
                else:
                    return r.ErrorMsg(ctx[1])
            else:
                template_name = template
                if template_name is None:
                    template_name = request.endpoint.replace('.', '/') + '.html'
                if ctx is not None:
                    return render_template(template_name,**ctx)
                else:
                    return render_template(template_name)
        return decorated_function
    return decorator


class BaseAjaxForm(Form):
    """ 基本的AJAX表单 """
    def __init__(self ,ctx = None,obj = None ,*args, **kwargs):
             
        if 'ltemplate' in kwargs:
            self.ltemplate = kwargs.pop('ltemplate')
        else:
            self.ltemplate = None
        
        super(BaseAjaxForm,self).__init__(obj = obj,*args, **kwargs)
        
        self._init()
        #初始化表单的相关变量
        self.obj = obj 
        if self.obj is not None and not self.is_submitted():
            self._load_f_obj()
            
        if ctx is None or not isinstance(ctx, dict):
            self.ctx = {}
        else:
            self.ctx = ctx
            
        self.action = ''
    
    def _init(self):
        pass
        
    def _load_f_obj(self):
        """
        在实现修改数据的时候，可能单纯的从数据库到表单还有一些变量没办法转换，可以在这里实现，
        比如： 数据库中存的是float类型的时间，但是在表单里面肯定是date类型，那么就要在之类转换
        """
        if hasattr(self, 'address'):
            addr = self.address.data.split('://')
            if len(addr) > 1:
                url = addr[1]
            else:
                url = addr[0]
            subdomain = url.split('/')
            if len(subdomain) > 1:
                self.address.data = subdomain[0].lower() + url[url.find('/'):]
            else:
                self.address.data = url.lower()

        if hasattr(self,'_loaddata'): 
            #self.csrf_is_valid = True 
            self.csrf_enabled = False
            if self.validate():
                ret = self._loaddata() 
                self.damy_result = render_template(self.ltemplate,data = ret)
            else:
                self.damy_result = '' 
        
    def show_damy(self): 
        if hasattr(self,'damy_result'): 
            return Markup(self.damy_result)
        else:
            return ''
        
    def _save_db(self):
        """ 
        将表单数据保存到数据库中，这个方法可以给重新，只是实现了最简单的保存，可能中间还有一些数据处理
        比如：
            在数据库中要存入float类型的时间，但是表单使用的是datefield，那么就要在这里对该field进行转换，并赋值。
            又或者数据库中存的是用户ID，但是在表单里面显示的是用户名，那里也要在这里进行查找并赋值。
            也可以做到validate_filename的方法里面
            如果需要传递相关数据到模板里面，可以通过这里设置self.ctx的值进去，ctx是以DICT形式存在的，KEY就是在模板中使用的key
            self.ctx.append('test','abc')
            {{ test }}   ======> abc
            
            注意这里必须返回值。表示执行成功或者失败（True,False) 
        """
        return True,_(u'保存成功')
    
    def form_tag(self,action = None,ok_type = False,target = '__hidden_call', bootstrap=None):
        """ 在HTML页面中调用此方法来实现form标签的render """
        if action is None:
            action = self.action
        form_name = type(self).__name__
        result = []
        if ok_type :
            result.append(u'<div class="submit_succ"></div>')
            
        result.append(u'<form action="')
        result.append(action)
        result.append(u'" method="post" onsubmit="DAMY.loader.submitLoading(this);" target="'+ target +'" id="')
        result.append(form_name)
        result.append(u'_form" name="')
        result.append(form_name)
        if bootstrap is None:
            result.append(u'_form" class="form-signin">')
        else:
            result.append(u'_form" class="well form-inline">')
        result.append(self.hidden_tag())
        return Markup(u"".join(result))
    
    def exe(self,template = None,ltemplate = None):
        """ 最终调用的方法 """
        if ltemplate is None:
            ltemplate = self.ltemplate
        
        if self.validate_on_submit():
            ret,str = self._save_db() 
            if ret == 'url':
                return self._show_redirect(str)
            elif ret=='string':
                return self._show_ret(str)
            elif ret == 'js':
                return self._build_resp_str(str,None)
            elif ret == 'tools':
                return self._show_toolmsg(str)
            elif ret and ltemplate is not None:
                str = render_template(ltemplate,data = str,**self.ctx)
                return self._show_ret(str)
            elif ret:
                return self._show_succ(str)
            else:
                return self._show_error(str)
        elif self.is_submitted():
            return self._show_alarm() 
        
        if template is None:
            template = request.endpoint.replace('.', '/') + '.html'
        
        return render_template(template,form = self,**self.ctx)
    
    def _show_redirect(self,url):
        url = unicode(url)
        url = json.dumps(url)
        return self._build_makup('onRedirect',url)
    
    def SuccMsg(self,ret):
        return self._show_succ(ret)
    def ErrorMsg(self,ret):
        return self._show_error(ret)
    
    
    def _show_ret(self,ret=''):
        return self._build_makup('onRetSucc','$("body").html()',ret)
    
    def _show_succ(self,ret = ''):
        ret = unicode(ret)
        ret = json.dumps(ret)
        return self._build_makup('onSubmitSucc',ret)
    
    def _show_ok(self,ret = ''):
        ret = unicode(ret)
        ret = json.dumps(ret)
        return self._build_makup('showSuccMsg',ret)
    
    def _show_toolmsg(self,ret = ''):
        ret = unicode(ret)
        ret = json.dumps(ret)
        return self._build_makup('showToolMsg',ret)
    
    def _show_error(self,ret = ''):
        ret = unicode(ret)
        ret = json.dumps(ret)
        return self._build_makup('showErrorMsg',ret)
    
    def _show_alarm(self):
        err = self._build_valid_field()
        return self._build_makup('showControllerErrorMsg',json.dumps(err))
        
    def _build_makup(self,act,str,body = None):
        js = [u'parent.DAMY.loader.']
        js.append(act)
        js.append('(')
        js.append(str)
        js.append(',"')
        #print vars(self)
        if hasattr(self,'csrf'):

            js.append(self.csrf.data)
        else:
            js.append(self.csrf_token.data) 
            #js.append(self.csrf_token.current_token)
        js.append('")')
        js = Markup(u"".join(js))
        return self._build_resp_str(js,body)
    
    def _build_valid_field(self):
        err = dict()
        for field in self:
            if field.errors:
                for error in field.errors:
                    err[field.name] = unicode(error)
        return err
    
    def _build_resp_str(self,js,body = None):
        result =  [u'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    </head>''']
        if body is not None: result.append('<script type="text/javascript" src="'+build_url(current_app,action='frontend.static',filename='js/jquery-1.4.4.min.js') + '"></script>') 
        result.append(u'''<script type="text/javascript">''')
        if body is not None: result.append(u'''$(document).ready(function(){''')
        result.append(js)
        if body is not None: result.append(u'''});''')
        result.append(u'''</script><body>''')
        if body is not None:result.append(body)
        result.append(u'''</body></html>''')
        return Markup(u"".join(result))
