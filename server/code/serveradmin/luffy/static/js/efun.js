var GAME = new Object();
GAME.load = {
	href_click:function(obj){
		var id = $(obj).attr("val");
		var url = $(obj).attr("href");
		if(confirm('确定删除数据？')){
			$.get(url,{id:id},function(data){
				if(data['success'] == "1"){
					location.reload()
					//$('#'+id+'').hide();
				}
			});
		}
	},
    delete:function(obj){
        var url = $(obj).attr("href");
        if(confirm('确定删除数据？')){
            $.get(url,function(data){
                if(data['success'] == "1"){
                    location.reload()
                }
            });
        }
    },
    get_data:function(obj){
        var url = $(obj).attr("href");
        $.post(url, function(d){
            $('#edit_id').val(d['ret']['_id']);
            for (var key in d['ret']){
                $('#edit_'+key).val(d['ret'][key]);
            };
            $('#disfive').attr('class','well form-inline');
        });
    },
	current_database:function(obj){
		$.get('/admin/admin/current/version/',function(data){
			$('#current_ver').val(data['ver']);
		});
	},
	delete_all:function(obj){
		var url = $(obj).attr("href");
		var coll = $(obj).attr("val");
		var pass = prompt("密码","请输入清除密令");
		if (pass == '123456'){
			$.get(url,{ collection:coll },function(data){
				if (data['status'] == '1'){
					location.reload();
				}
			});
		}
	},
	reg_search:function(obj,searchCondition, platform_t){
		var start_time = $('#start_time').val();
		var end_time = $('#end_time').val();
		var url = $(obj).attr('href');
		 
		if (searchCondition){
			url = url+'?start_time='+start_time+'&end_time='+end_time + '&searchCondition='+searchCondition;
		}else{
			url = url+'?start_time='+start_time+'&end_time='+end_time;
		}

		if (platform_t){
			var platform_t = $('#stype').val();
			url = url + '&stype=' + platform_t;
		}
		location.href = url 

	},
    log_rpc:function(obj){
        var start_time = $('#start_time').val();
        var end_time = $('#end_time').val();
        var t = $('#t').val();
        var pid = $('#pid').val();
        var url = $(obj).attr('href');
        location.href = url+'?start_time='+start_time+'&end_time='+end_time+'&t='+t+'&pid='+pid;

    },
	coin_time:function(obj,searchCondition){
		var start_time = $('#start_time').val();
		var end_time = $('#end_time').val();
		var ctype = $('#ctype_select').val();
		var url = $(obj).attr('href');
		location.href = url+'?start_time='+start_time+'&end_time='+end_time + '&searchCondition='+searchCondition+'&ctype='+ctype;

	},
	add_server:function(obj, opType){
		var url = $(obj).attr("href");
		var ip = $('#ip').val();
		var port = $('#port').val();
		var username = $('#username').val();
		var password = $('#password').val();
		var data = {};
		data['ip'] = ip;
		data['port'] = port;
		data['username'] = username;
		data['password'] = password;
		if (opType == 'add'){
			data['id'] = $('#id').val();
		}
		$.post(url,data,function(d){
			if (d['success']== 1){
				
			}
		})
	}
	,
	all_task:function(obj, type){
		if (type=='Task'){
			var startTask = $('#startTask').val();
			var endTask = $('#endTask').val();
			var startStr = '?startTask='
			var endStr = '&endTask='
		}
		if (type == 'Level'){
			var startTask = $('#startLevel').val();
			var endTask = $('#endLevel').val();
			var startStr = '?startLevel='
			var endStr = '&endLevel='
		}
		var url = $(obj).attr('href');
		location.href = url+startStr+startTask+endStr+endTask;
	},
	player_search:function(obj, query){
		var playerId = $('#playerId').val();
		var playerName = $('#playerName').val();
		var url = $(obj).attr('href');
        last_url = url+'?playerId='+playerId+'&playerName='+playerName
        if(query){
            var querys = $('#querys').val();
            last_url += '&querys=' + querys;
        }
		location.href = last_url;
	},
	exchange_count:function(obj){
		var code = $('#code').val();
        var pid = $('#pid').val();
		var url = $(obj).attr('href');
        last_url = url+'?code='+code+'&pid='+pid;
		location.href = last_url;
	},
    player_search_all:function(obj){
        var stype = "all";
        var url = $(obj).attr('href');
        location.href = url+'?stype='+stype;
    },
	user_money:function(obj, searchType){
		var playerId = $('#playerId').val();
		var playerName = $('#playerName').val();
        var start_time = $('#start_time').val();
        var end_time = $('#end_time').val();
		var url = $(obj).attr('href');
		location.href = url+'?playerId='+playerId+'&playerName='+playerName+'&searchType='+searchType+'&start_time='+start_time+'&end_time='+end_time;
	},
	vip_info:function(obj){
		var playerId = $('#playerId').val();
		var playerName = $('#playerName').val();
		var url = $(obj).attr('href'); 
		location.href = url+'?playerId='+playerId+'&playerName='+playerName;
	},
	player_tlogin:function(obj){
		var pid = $('#pid').val();
		var start_time = $('#start_time').val();
		var end_time = $('#end_time').val();
		var url = $(obj).attr('href');
		location.href = url+'?pid='+pid+'&start_time='+start_time+'&end_time='+end_time;
	},
    player_action:function(obj){
        var t = $('#t').val();
        var pid = $('#pid').val();
        var start_time = $('#start_time').val();
        var end_time = $('#end_time').val();
        var url = $(obj).attr('href');
        location.href = url+'?pid='+pid+'&start_time='+start_time+'&end_time='+end_time+'&t='+t;
    },
	server_manage:function(obj, id){
		var stype = $(obj).attr('stype');
		if (stype =='edit'){
			$('#edit_id').val(id);
			$('#edit_name').val($('#'+id+'_name').text());
			$('#edit_ip').val($('#'+id+'_ip').text());
			$('#edit_port').val($('#'+id+'_port').text());
			$('#edit_username').val($('#'+id+'_username').text());
			$('#edit_password').val($('#'+id+'_password').text());
            $('#edit_gport').val($('#'+id+'_gport').text());
            $('#edit_t').val($('#'+id+'_t').text());
            $('#edit_tf').val($('#'+id+'_tf').text());
            $('#edit_db_res').val($('#'+id+'_db_res').text());
            $('#edit_db_user').val($('#'+id+'_db_user').text());
            $('#edit_db_log').val($('#'+id+'_db_log').text());
            $('#edit_st').val($('#'+id+'_st').text());
            $('#edit_res_path').val($('#'+id+'_res_path').text());
            $('#edit_sid').val($('#'+id+'_sid').text());
			$('#disfive').attr('class','well form-inline');
		}else if(stype == 'del'){
			var url = $(obj).attr('href');
			url = url + stype +'/';
			$.post(url, {id:id}, function(d){
				if (d['success']==1){
					location.reload();
				}
			});
		}
	}
	,
    filter:function(obj, id){
        var stype = $(obj).attr('stype');
        if (stype =='edit'){
            $('#edit_id').val(id);
            $('#edit_names').val($('#'+id+'_names').text());
            $('#edit_t').val($('#'+id+'_t').text());
            $('#disfive').attr('class','well form-inline');
        }else if(stype == 'del'){
            var url = $(obj).attr('href');
            // url = url + stype +'/';
            $.post(url, {id:id,opType:"del"}, function(d){
                if (d['success']==1){
                    location.reload();
                }
            });
        }
    }
    ,
    other_setting:function(obj, id){
        var stype = $(obj).attr('stype');
        if (stype =='edit'){
            $('#edit_id').val(id);
            $('#edit_key').val($('#'+id+'_key').text());
            $('#edit_value').val($('#'+id+'_value').text());
            $('#disfive').attr('class','well form-inline');
        }else if(stype == 'del'){
            var url = $(obj).attr('href');
            // url = url + stype +'/';
            $.post(url, {id:id,opType:"del"}, function(d){
                if (d['success']==1){
                    location.reload();
                }
            });
        }
    }
    ,
    database_backup:function(obj, id){
        var stype = $(obj).attr('stype');
        if (stype =='edit'){
            $('#edit_id').val(id);
            $('#edit_ip').val($('#'+id+'_ip').text());
            $('#edit_port').val($('#'+id+'_port').text());
            $('#edit_username').val($('#'+id+'_username').text());
            $('#edit_password').val($('#'+id+'_password').val());
            $('#edit_tables').val($('#'+id+'_tables').val());
            $('#edit_local_database').val($('#'+id+'_local_database').text());
            $('#edit_database').val($('#'+id+'_database').text());
            $('#edit_remark').val($('#'+id+'_remark').text());
            $('#edit_st').val($('#'+id+'_st').text());
//            $('#edit_local_database').val($('#'+id+'local_database').text());
            $('#edit_t').val($('#'+id+'_t').text());
            $('#disfive').attr('class','well form-inline');
        }else if(stype == 'del'){
            var url = $(obj).attr('href');
            url = url + stype +'/';
            $.post(url, {id:id}, function(d){
                if (d['success']==1){
                    location.reload();
                }
            });
        }
    },
    database_restore_tables_save:function(obj, id){
        var stype = $(obj).attr('stype');
        if (stype =='edit'){
            $('#edit_id').val(id);
            $('#edit_title').val($('#'+id+'_title').text());
            $('#edit_names').val($('#'+id+'_names').text());
            $('#edit_remark').val($('#'+id+'_remark').text());
            $('#disfive').attr('class','well form-inline');
        }else if(stype == 'del'){
            var url = $(obj).attr('href');
            var data = {"id":id, "opType":"del"};
            $.post(url, data, function(d){
                if (d['success']==1){
                    location.reload();
                }
            });
        }
    }
    ,
    server_default:function(obj){
        //var serverid = $('#default_server_type').val();
        var serverid = $(obj).val();
        var url = $(obj).attr('href');
        $.get(url, {serverid:serverid},function(d){
           if (d['success']==1){
               location.reload();
           }
        });
    }
    ,
	edit_click:function(obj, act){
		var id = $(obj).attr("val");
		var url = $(obj).attr("href");
		if (act=='exchange'){
            $.get(url,{id:id},function(data){
                $('#edit_id').val(data['ret']['_id']);
                $('#edit_name').val(data['ret']['name']);
                $('#edit_ct').val(data['ret']['ct']);
                $('#edit_et').val(data['ret']['et']);
                $('#edit_one').val(data['ret']['one']);
                $('#edit_rid').val(data['ret']['rid']);
                $('#edit_num').val('None');
//                $('#edit_length').val(data['ret']['length']);
//                $('#edit_nums').val(data['ret']['nums']);
                $('#disfive').attr('class','well form-inline');
            });
        }
        else if (act=='client_servers'){
            $.get(url,{id:id},function(data){
                $('#edit_id').val(data['ret']['_id']);
                $("#edit_host").val(data['ret']['host']);
                $("#edit_port").val(data['ret']['port']);
                $("#edit_name").val(data['ret']['name']);
                $("#edit_status").val(data['ret']['status']);
                $("#edit_sid").val(data['ret']['sid']);
                $('#disfive').attr('class','well form-inline');
            });
        }
        else if (act=='server_gconfig'){
            $.get(url,{id:id},function(data){
                $('#edit_id').val(data['ret']['_id']);
                $("#edit_key").val(data['ret']['key']);
                $("#edit_value").val(data['ret']['value']);
                $('#disfive').attr('class','well form-inline');
            });
        }
        else if (act=='customer_account'){
            $.get(url,{id:id},function(data){
                $('#edit_id').val(data['ret']['_id']);
                $("#edit_email").val(data['ret']['email']);
                $("#edit_t").val(data['ret']['t']);
                $('#disfive').attr('class','well form-inline');
            });
        }
        else if (act=='user'){
            $.get(url,{id:id},function(data){
                $('#edit_id').val(data['ret']['_id']);
                $('#edit_email').val(data['ret']['username']);
                $('#edit_nickname').val(data['ret']['nickname']);
                $('#edit_role').val(data['ret']['role']);
                $('#disfive').attr('class','well form-inline');
            });
        }
	}
}

