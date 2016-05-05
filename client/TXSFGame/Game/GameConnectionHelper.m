//
//  GameConnectionHelper.m
//  TXSFGame
//
//  Created by Soul on 13-4-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameConnectionHelper.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "TaskManager.h"

static GameConnectionHelper* s_GameConnectionHelper = nil;

@implementation GameConnectionHelper

+(GameConnectionHelper*)shared{
	if (s_GameConnectionHelper == nil) {
		s_GameConnectionHelper = [[GameConnectionHelper alloc] init];
	}
	return s_GameConnectionHelper;
}

+(void)stopAll{
	if (s_GameConnectionHelper) {
		[s_GameConnectionHelper release];
		s_GameConnectionHelper = nil;
	}
}

-(void)dealloc{
	CCLOG(@"GameConnectionHelper->dealloc");
	[GameConnection removePostTarget:self];
	[super dealloc];
}

-(void)start{
	[GameConnection addPost:ConnPost_writeDataSecurity target:self call:@selector(writeDataSecurity:)];
}

-(void)writeDataSecurity:(NSNotification*)notification{
	NSDictionary * sender = notification.object;
	CCLOG(@"writeDataSecurity:%@",[sender description]);
	
	NSDictionary* json = [sender objectForKey:@"json"];
	NSDictionary* argument = [sender objectForKey:@"arg"];
	
	NSString* func = getResponseFunc(json);
	NSDictionary* data = getResponseData(json);
	
	if (func == nil || data == nil) return ;
	
	CCLOG(@"Warning:",[json description]);
	CCLOG(@"Warning:",[argument description]);
	
	if ([func isEqualToString:@"posActive"]) {
		int playerPid = [[argument objectForKey:@"playerPhalanxId"] intValue];
		[[GameConfigure shared] updatePlayerPosId:playerPid];
	}
	else if ([func isEqualToString:@"posUpgrade"]) {
		int posId = [[argument objectForKey:@"posId"] intValue];
		int level = [[argument objectForKey:@"level"] intValue];
		[[GameConfigure shared] updatePlayerPhalanxWithId:posId level:level+1];
		[[GameConfigure shared] updatePlayerMoney:[[data objectForKey:@"coin1"] intValue]];
	}
	else if ([func isEqualToString:@"posStudy"]) {
		NSMutableDictionary *playerPhalanx = [NSMutableDictionary dictionary];
		int _id = [[data objectForKey:@"pid"] intValue];
		int pid = [[argument objectForKey:@"pid"] intValue];
		int posId = [[argument objectForKey:@"posId"] intValue];
		
		[playerPhalanx setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[playerPhalanx setObject:[NSNumber numberWithInt:pid] forKey:@"pid"];
		[playerPhalanx setObject:[NSNumber numberWithInt:posId] forKey:@"posId"];
		[playerPhalanx setObject:[NSNumber numberWithInt:1] forKey:@"level"];
		for (int i = 1; i <= 15; i++) {
			NSString *key = [NSString stringWithFormat:@"s%d", i];
			[playerPhalanx setObject:[NSNumber numberWithInt:0] forKey:key];
		}
		[[GameConfigure shared] addPlayerPhalanx:playerPhalanx];
		[[GameConfigure shared] updatePlayerMoney:[[data objectForKey:@"coin1"] intValue]];
	}
	else if ([func isEqualToString:@"posSet"]) {
		NSDictionary *dict = [argument objectForKey:@"dict"];
		
		[[GameConfigure shared] updatePlayerPhalanx:dict];
	}
	else if ([func isEqualToString:@"invite"]) {
		[[GameConfigure shared] updatePackage:data];
		
		NSArray * roles = [data objectForKey:@"role"];
		if([roles count]>0){
			NSDictionary * role = [roles objectAtIndex:0];
			[[GameConfigure shared] addPlayerRole:role];
		}
	}
	else if ([func isEqualToString:@"roleReturn"]) {
		int _id = [[data objectForKey:@"rid"] intValue];
		[[GameConfigure shared] updatePlayerRoleWithId:_id status:1];
	}
	else if ([func isEqualToString:@"fete"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"bfTaskGet"]) {
		NSDictionary *newTask = [data objectForKey:@"task"];
		[[GameConfigure shared] addNewUserTasks:[NSArray arrayWithObject:newTask]];
		[[TaskManager shared] reloadNewTaskList];
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"bfTaskFinish"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"bfTaskRe"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"bfTaskBox"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"armUpgrade"]) {
		int _id = [[data objectForKey:@"rid"] intValue];
		int _level = [[data objectForKey:@"armLevel"] intValue];
		int _train = [[data objectForKey:@"train"] intValue];
		[[GameConfigure shared] updatePlayerTrain:_train];
		[[GameConfigure shared] updateArmLevel:_id level:_level];
		if (_level == 3) {
			[[GameConfigure shared] activePlayerRoleSkillWithType:_id type:1];
		}
	}
	else if ([func isEqualToString:@"skillBack"]) {
		int _id = [[data objectForKey:@"rid"] intValue];
		[[GameConfigure shared] updateArmLevel:_id level:0];
		[[GameConfigure shared] activePlayerRoleSkillWithType:_id type:0];//取消激活技能
		
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"armSkill"]) {
		int _id = [[data objectForKey:@"rid"] intValue];
		int _sk = [[data objectForKey:@"sid"] intValue];
		[[GameConfigure shared] activePlayerRoleSkillWithId:_id sid:_sk];
	}
	else if ([func isEqualToString:@"shopBuy"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"carExchange"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"waitFetch"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"tBoxEnter"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"tBoxKill"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"tBoxReset"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([func isEqualToString:@"tBoxHitEnd"]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([@"sellAll" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
	else if ([@"roleLeave" isEqualToString:func]) {
		int ___id = [[data objectForKey:@"rid"] intValue];
		[[GameConfigure shared] removeTeamMember:___id];
	}
	else if ([@"useItem" isEqualToString:func]){
		[[GameConfigure shared] updatePackage:data];
	}
    //物品合成
    if ([@"mergeItem" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //强化
    if ([@"eqStr" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //进入猎命
    if ([@"enterHitFate" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //猎命
    if ([@"hitFate" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //待收物品收取
    if ([@"waitFetch" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //穿命格
    if ([@"wearFt" isEqualToString:func]) {
        [[GameConfigure shared] wearFate:[[[argument objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue] part:[[argument objectForKey:@"cardPlace"] intValue] target:[[argument objectForKey:@"cardRoleID"] intValue]];
    }
    //脱命格
    if ([@"tackOffFt" isEqualToString:func]) {
        [[GameConfigure shared] tackOffFate:[[[argument objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue]  part:[[argument objectForKey:@"cardPlace"] intValue] target:[[argument objectForKey:@"cardRoleID"] intValue]];
    }
    //合命格
    if ([@"mergeFt" isEqualToString:func]) {
		NSArray *arrData = [data objectForKey:@"fate"];
		if (!([arrData count]==1)) {
			CCLOG(@"sender data error in fate");
			return;
		}
		NSDictionary *newData = [arrData objectAtIndex:0];
        [[GameConfigure shared] tackOffFate:[[[argument objectForKey:@"tagetCardDict"] objectForKey:@"id"] intValue]  target:[[argument objectForKey:@"cardRoleID"] intValue]];
		[[GameConfigure shared] tackOffFate:[[[argument objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue]  target:[[argument objectForKey:@"cardRoleID"] intValue]];
        
        [[GameConfigure shared] removeFate:[[newData objectForKey:@"id"] intValue]];
		[[GameConfigure shared] updatePackage:data];
		
		if ([[[argument objectForKey:@"tagetCardDict"] objectForKey:@"used"] intValue] == FateStatus_used) {
			[[GameConfigure shared] wearFate:[[newData objectForKey:@"id"] intValue] part:[[argument objectForKey:@"cardPlace"] intValue] target:[[argument objectForKey:@"cardRoleID"] intValue]];
		}
    }
    //全部合成命格
    if ([@"mergeAllFt" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //进食
    if ([@"foodEat" isEqualToString:func]) {
        [[GameConfigure shared] setPlayerBuff:[[data objectForKey:@"buff"] objectAtIndex:0] type:Buff_Type_foot];
		[[GameConfigure shared] updatePackage:data];
    }
    //直接购买
    if ([@"dshopBuy" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //退出同盟
    if ([@"allyQuit" isEqualToString:func]) {
        [[GameConfigure shared] removePlayerAlly];
    }
    //创建同盟
    if ([@"allyCreate" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //招财猫
    if ([@"allyCat" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //同盟铭刻
    if ([@"allyGrave" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //兑换码领取
    if ([@"rewardCode" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //领取成就
    if ([@"achiReward" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //使用物品
    if ([@"useItem" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //起杆
    if ([@"fishUp" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
    //深渊宝箱
    if ([@"deepBox" isEqualToString:func]) {
        [[GameConfigure shared] updatePackage:data];
    }
	//穿装备
	if ([@"wearEq" isEqualToString:func]) {
		int _id = [[data objectForKey:@"id"] intValue];
		int _uid = [[data objectForKey:@"uid"] intValue];
		int _rid = [[data objectForKey:@"rid"] intValue];
		[[GameConfigure shared] doEquipmentAction:_rid off:_uid input:_id];
	}
	//脱装备
	if ([@"tackOffEq" isEqualToString:func]) {
		int _role = [[argument objectForKey:@"rid"] intValue];
		int _ueid = [[argument objectForKey:@"id"] intValue];
		
		[[GameConfigure shared] doEquipmentAction:_role off:_ueid input:0];
	}
	//等级转移
	if ([@"eqMove" isEqualToString:func]) {
		int eid1 = [[data objectForKey:@"eid1"] intValue];
		int eid2 = [[data objectForKey:@"eid2"] intValue];
		int _role = [[argument objectForKey:@"rid"] intValue];
		
		[[GameConfigure shared] updatePackage:data];
		
		[[GameConfigure shared] doEquipmentMoveLevel:eid1 with:eid2];
		[[GameConfigure shared] doEquipmentAction:_role off:eid1 input:eid2];
	}
    //等级转移
	if ([@"ctreeExchange" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
    //培养武将
	if ([@"roleUpTrain" isEqualToString:func]) {
        if ([data objectForKey:@"update"]) {
            [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
        }
	}
	//珠宝镶嵌
	if ([@"gemInlay" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
	//珠宝移除
	if ([@"gemRemove" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
	//原石开采
	if ([@"gemMine" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
	//原石打磨
	if ([@"gemSanding" isEqualToString:func]) {
		[[GameConfigure shared] updatePackage:data];
	}
	//珠宝提纯
	if ([@"gemUpgrade" isEqualToString:func]) {
		if ([data objectForKey:@"info"]) {
            [[GameConfigure shared] updatePackage:[data objectForKey:@"info"]];
        }
	}
    //同盟boss
	if ([@"allybossCdEnd" isEqualToString:func]) {
		if ([data objectForKey:@"update"]) {
            [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
        }
	}
    //世界boss
	if ([@"bossCdEnd" isEqualToString:func]) {
		if ([data objectForKey:@"update"]) {
            [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
        }
	}
}

@end
