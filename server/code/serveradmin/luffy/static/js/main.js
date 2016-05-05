String.prototype.trim = function()
{
	return this.replace(/^\s*|\s*$/g,"");
};
Array.prototype.remove = function(n)
{
	if (n < 0)
	{
		return this;
	}
	else
	{
		return this.slice(0, n).concat(this.slice(n + 1, this.length));
	}
};
var DAMY = new Object();
DAMY.loader = {
		form : null,
		showdlg :function(message,css,callback){
    		$('#confirm').modal({
    			overlayId: 'confirm-overlay',
    			containerId: 'confirm-container', 
    			closeHTML: '<a title="关闭" class="close modal-close" href="javascript:;"></a>',
    			onShow: function (dialog) {
    				var modal = this;
    				$('.message', dialog.data[0]).append(message);
    				$('.btn_normal', dialog.data[0]).click(function () { 
    					if ($.isFunction(callback)) {
    						callback.apply();
    					} 
    					modal.close();  
    				});
    				if(css){
    					css = 'PY_ib_' + css;    					
    				}else{
    					css = 'PY_ib_1';
    				}
    				$('.PY_ib',dialog.data[0]).addClass(css);
    			}
    		});
    	},
		submitLoading : function(frm){
			$(frm).find('input[class="textinp"]').each(function(i,n){
				if($(n).val() == $(n).attr('title')){
					$(n).val('');
				}
			}); 
			this.form = frm
			return true;
		},
		finishSubmit:function(token){
			var frm = this.form;
			$(frm).find('input[class="textinp"]').each(function(i,n){
				if($(n).val() == ''){
					$(n).val($(n).attr('title'));
				} 
			}); 
			
			var btn_class = $(frm).find('a[name="submit"]').attr('class');
			btn_class = btn_class.split(' '); 
			$(frm).find('a[name="submit"]').attr('class',btn_class[0]);
			
			if(token){
				$(frm).find('#csrf').val(token);
			}
			this.form = null;
		},
		showControllerErrorMsg:function(msg,token){
			for (name in msg){ 
				if(name == 'csrf' && msg.length == 1){ 
					this.showdlg('提交失败，您在当前页面停留太长时间了，请重新点击提交按钮。','2');
					this.finishSubmit(token);
					return false;
				}
				//$('#red_'+name).find('span').html(msg[name]);
				$('#red_'+name).show();
			} 
			$.notty({ 
		         content : '提交失败，请检查表单各项是否填写正确。',
		         showTime: false,
		         img:'notice',
		         timeout: 5000
		    });
			this.finishSubmit(token);
		},
		showErrorMsg:function(msg,csrf){
			this.showdlg(msg);
			this.finishSubmit(csrf);
		},
		showSuccMsg:function(msg,csrf){ 
			$.notty({ 
		         content :   msg +'。',
		         showTime: false,
		         timeout: 5000,
		         img:'ok'
		    }); 
		},
		onSubmitSucc:function (msg,csrf){
			this.showdlg(msg,'3');
			this.finishSubmit(csrf);
			if (typeof succ_callback != 'undefined'){
				succ_callback();
			}
		},
		onRedirect:function(url,csrf){
			parent.window.location.href = url;
		},
		getRandomUrl:function (url,param){
			return url + param + '?cache=' + Math.floor(100000*Math.random());
		},
		onRetSucc:function(msg,csrf)
		{  
			this.finishSubmit(csrf);
			$('#msg_ret_container').html(msg); 
		},
		ajax_img:function(obj,load,url,cb,before){
			if (before!='' && typeof before!='undefined' && before!=false){
				if(!before(obj)){
					return
				}
			}
			old_img = $(obj).attr('src');
			url = this.getRandomUrl(url, '');
			$(obj).attr('src',load);
			$.get(url,function(data){
				if(data.ok){ 
					if (cb!='' && typeof cb!='undefined' && cb!=false){
						ret = cb(data);
					}else{
						ret = data.msg;
					}
					$.notty({ 
				         content : ret,
				         showTime: false,
				         img:'ok',
				         timeout: 5000
				    });
				}else{
					ret = $(obj).attr('title') + '失败。'
					if(data.msg){
						ret = ret + data.msg;
					} 
					$.notty({ 
				         content : ret,
				         showTime: false,
				         img:'notice',
				         timeout: 5000
				    });
				}
				$(obj).attr('src',old_img);
			});
		},
		toggle_img:function(obj,o,x,load,url,cb){
			old_img = $(obj).attr('src');
			url = this.getRandomUrl(url, '');
			$(obj).attr('src',load);
			$.get(url,function(data){
				if(data.ok){ 
					if (cb!='' && typeof cb!='undefined' && cb!=false){
						ret = cb(data);
					}else{
						ret = data.msg;
					}
					if(data.status){
						$(obj).attr('src',o);
					}else{
						$(obj).attr('src',x);
					}
					$.notty({ 
				         content : ret,
				         showTime: false,
				         img:'ok',
				         timeout: 5000
				    });
				}else{
					ret = $(obj).attr('title') + '失败。'
					if(data.msg){
						ret = ret + data.msg;
					} 
					$.notty({ 
				         content : ret,
				         showTime: false,
				         img:'notice',
				         timeout: 5000
				    });
					$(obj).attr('src',old_img);
				}
			});
		}
};
 