<?php

$urls = array();

/*
#平台类型
SNS_NONE = 0
SNS_91 = 1 #91
SNS_DPAY = 2 # 点金
SNS_EFUN = 3 # 官网
SNS_PP = 4  # pp助手
SNS_APP = 5 #app store
SNS_APPTW = 6 # app store 台湾
SNS_IDS = 7 #云顶
SNS_UC = 8 #uc
SNS_IDSC = 9 #云顶破解平台
SNS_TONGBU = 10 #同步推
SNS_DCN = 11 #当乐
SNS_PP_APPLE = 12 #PP苹果园
*/

//ZL-91
$urls['1'] = array();
$urls['1']['site'] = 'http://app.91.com/Soft/iPhone/com.efun.zl91-1.0.5-1.0.5.html';
$urls['1']['path'] = 'http://app.91.com/Soft/iPhone/com.efun.zl91-1.0.5-1.0.5.html';

//ZL-BD
$urls['2'] = array();
$urls['2']['site'] = 'itms-services:///?action=download-manifest&url=http://zl.52yh.com/iphone/zl.plist';
$urls['2']['path'] = 'itms-services:///?action=download-manifest&url=http://zl.52yh.com/iphone/zl.plist';

//ZL-NET
$urls['3'] = array();
$urls['3']['site'] = 'itms-services:///?action=download-manifest&url=http://zl.52yh.com/iphone/zl.plist';
$urls['3']['path'] = 'itms-services:///?action=download-manifest&url=http://zl.52yh.com/iphone/zl.plist';

//ZL-PP
$urls['4'] = array();
$urls['4']['site'] = 'http://www.25pp.com/ipad/game/info_1026326.html';
$urls['4']['path'] = 'http://www.25pp.com/ipad/game/info_1026326.html';

//ZL-APPLE
$urls['5'] = array();
$urls['5']['site'] = 'https://itunes.apple.com/cn/app/zhi-dian-zhen-long/id643533098?mt=8';
$urls['5']['path'] = 'https://itunes.apple.com/cn/app/zhi-dian-zhen-long/id643533098?mt=8';

//台湾app
$urls['6'] = array();
$urls['6']['site'] = 'https://itunes.apple.com/cn/app/zhi-dian-zhen-long/id643533098?mt=8';
$urls['6']['path'] = 'https://itunes.apple.com/cn/app/zhi-dian-zhen-long/id643533098?mt=8';

//云顶

//uc
$urls['8'] = array();
$urls['8']['site'] = 'http://ng.9game.cn/game/detail_516088.html';
$urls['8']['path'] = 'http://ng.9game.cn/game/detail_516088.html';

//云顶破解平台

//10 #同步推
$urls['10'] = array();
$urls['10']['site'] = 'http://ng.9game.cn/game/detail_516088.html';
$urls['10']['path'] = 'http://ng.9game.cn/game/detail_516088.html';


//11 #当乐
$urls['11'] = array();
$urls['11']['site'] = 'http://ng.d.cn/zhidianzhenlong/';
$urls['11']['path'] = 'http://ng.d.cn/zhidianzhenlong/';

//12 #PP苹果园
$urls['12'] = array();
$urls['12']['site'] = 'http://www.app111.com/info/51104/';
$urls['12']['path'] = 'http://www.app111.com/info/51104/';


if(strstr($_SERVER['HTTP_USER_AGENT'],'iPhone') || 
	strstr($_SERVER['HTTP_USER_AGENT'],'iPod') ||
	strstr($_SERVER['HTTP_USER_AGENT'],'iPad') ){
	header('Location:'.$urls[$_GET['type']]['path']);
}else{
	header('Location:'.$urls[$_GET['type']]['site']);
}


?>