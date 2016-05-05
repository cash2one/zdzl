//
//  UnionConfig.h
//  TXSFGame
//
//  Created by Max on 13-3-14.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "StretchingImg.h"
#import "CCPanel.h"

typedef enum {
	UnionDuty_main		= 1, //盟主
	UnionDuty_vice			= 2,//副盟主
	UnionDuty_elder		= 3,//长老
    UnionDuty_bodyGuard		= 4,//护法
	UnionDuty_diaphysis		= 5,//精英
    UnionDuty_member		= 6,//盟友
}UnionDuty;

typedef enum {
    Tag_Union_Tab_Activity = 1,     // 活动
    Tag_Union_Tab_Trends,           // 动态
    Tag_Union_Tab_Audit,            // 审核
    Tag_Union_Tab_Member            // 成员列表
} Tag_Union_Tab_Type;

typedef enum {
    Tag_Union_Set = 1,              // 同盟信息设置
    Tag_Union_BossSet,              // 同盟boss信息设置
    Tag_Union_Quit,                 // 同盟信息退出
    Tag_Union_Other,                // 其他同盟
    Tag_Union_Manor,                 // 领地
    Tag_Union_Disband,              // 同盟解散
} Tag_Union_button_Type;

typedef enum {
    Tag_Union_Member_Talk = 1,      // 私聊
    Tag_Union_Member_Add,           // 加为好友
    Tag_Union_Member_Look,          // 查看信息
    /*
    Tag_Union_Member_setMain,          // 任职盟主
    Tag_Union_Member_setVice,          // 任职副盟主
    Tag_Union_Member_setElder,         // 任职长老
    Tag_Union_Member_setBodyGuard,      // 任职护法
    Tag_Union_Member_setDiaphysis,     // 任职精英
    Tag_Union_Member_setMember,     // 任职盟友
    */
    Tag_Union_Member_changeDuty,          //改变职责
	Tag_Union_Member_kick,			// 剔除
} Tag_Union_Member_Action;

typedef enum {
    Tag_Union_Trends_Personnel = 1,     // 人事
    Tag_Union_Trends_Contrib            // 贡献
} Tag_Union_Trends_Type;

typedef enum {
    Tag_Union_Activity_Money			= 1,// 招财猫
    Tag_Union_Activity_Challenge		= 2,// 组队挑战
    Tag_Union_Activity_Donate			= 3,// 捐献斗舰
    Tag_Union_Activity_Engrave			= 4,// 宝具铭刻
    Tag_Union_Activity_MainChallenge	= 5,// 同盟首领战
    Tag_Union_Activity_Fly              = 6,// 烛龙飞天
	Tag_Union_Activity_Cometo           = 7,// 魔龙降世
} Tag_Union_Activity_Type;

typedef enum {
    Tag_Union_Activity_Progress = 1,    // 正在进行
    Tag_Union_Activity_Unopened,        // 未开启
    Tag_Union_Activity_Ended            // 已结束
} Tag_Union_Activity_Status;

static NSString * getJobName(int duty){
//	if(duty==1) return @"盟主";
//	if(duty==2) return @"副盟主";
//	if(duty==3) return @"长老";
//	if(duty==4) return @"护法";
//	if(duty==5) return @"精英";
//	if(duty==6) return @"盟友";
    if(duty==1) return NSLocalizedString(@"union_config_main",nil);
	if(duty==2) return NSLocalizedString(@"union_config_vice",nil);
	if(duty==3) return NSLocalizedString(@"union_config_elder",nil);
	if(duty==4) return NSLocalizedString(@"union_config_body_guard",nil);
	if(duty==5) return NSLocalizedString(@"union_config_diaphysis",nil);
	if(duty==6) return NSLocalizedString(@"union_config_member",nil);
	return @"";
}

static NSString * getTime(int time){
	
	int stime = [GameConnection share].server_time;
	int ctime = stime - time;

	if(ctime>(365*24*60*60)){
		//return @"一年前";
        return NSLocalizedString(@"union_config_one_year",nil);
	}else{
//		if(ctime>(6*30*24*60*60)) return @"半年前";
//		if(ctime>(3*30*24*60*60)) return @"3个月前";
//		if(ctime>(2*30*24*60*60)) return @"2个月前";
//		if(ctime>(1*30*24*60*60)) return @"1个月前";
        if(ctime>(6*30*24*60*60)) return NSLocalizedString(@"union_config_half_year",nil);
		if(ctime>(3*30*24*60*60)) return NSLocalizedString(@"union_config_three_month",nil);
		if(ctime>(2*30*24*60*60)) return NSLocalizedString(@"union_config_two_month",nil);
		if(ctime>(1*30*24*60*60)) return NSLocalizedString(@"union_config_one_month",nil);
		int dd = ctime/(24*60*60);
		if(dd>0){
			//return [NSString stringWithFormat:@"%d天前",dd];
            return [NSString stringWithFormat:NSLocalizedString(@"union_config_day",nil),dd];
		}else{
			int dm = ctime/(60*60);
			if(dm>0){
				//return [NSString stringWithFormat:@"%d小时前",dm];
                return [NSString stringWithFormat:NSLocalizedString(@"union_config_hour",nil),dm];
			}else{
				int ds = ctime/60;
				if(ds>0){
					//return [NSString stringWithFormat:@"%d分钟前",ds];
                    return [NSString stringWithFormat:NSLocalizedString(@"union_config_minute",nil),ds];
				}else{
					//return @"1分钟前";
                    return NSLocalizedString(@"union_config_one_minute",nil);
				}
			}
		}
	}
	return @"";
}


