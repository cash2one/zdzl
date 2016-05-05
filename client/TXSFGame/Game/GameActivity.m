//
//  GameActivity.m
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameActivity.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "AlertManager.h"
#import "Config.h"
#import "ActivityPanel.h"
#import "ActivityTabGroup.h"
#import "ActivityTab.h"
#import "ActivityEDLogin.h"
#import "Notice.h"

static GameActivity * gameActivity;

@implementation GameActivity

+(GameActivity*)shared{
	if(gameActivity==nil){
		gameActivity = [[GameActivity alloc] init];
	}
	return gameActivity;
}
+(void)stopAll{
	if(gameActivity){
		[NSTimer cancelPreviousPerformRequestsWithTarget:gameActivity];
		[gameActivity release];
		gameActivity = nil;
	}
}

-(void)checkStartActivity{
	[NSTimer scheduledTimerWithTimeInterval:2.0f 
									 target:self selector:@selector(doShowStartActivity) 
								   userInfo:nil repeats:NO];
}

-(void)doShowStartActivity{
	
	if([[GameConfigure shared] isPlayerOnChapter]){
		return;
	}
	//公告
    [Notice showNotice];
    
	//todo 调整打开逻辑
	//show window
	
	/*
	NSArray * lists = [self getActivityByType:Activity_Type_main];
	if([lists count]>0){
		NSDictionary * activity = [lists objectAtIndex:0];
		if(activity){
			//TODO
			int type = [[activity objectForKey:@"type"] intValue];
			int tid = [[activity objectForKey:@"id"] intValue];
			if ([self checkActivityCondition:type activityId:tid]) {
				[[AlertManager shared] showActivity:activity];
			}
		}
	}
	*/
    
    //检测抽奖
	[ActivityEDLogin checkMaxhasLuckTime];
}



-(NSArray*)getActivityByType:(Activity_Type)type{
	NSMutableArray * result = [NSMutableArray array];
	NSArray * lists = [[GameConnection share] getAllActivity];
	for(NSDictionary * activity in lists){
		if([[activity objectForKey:@"type"] intValue]==type ||
		   [[activity objectForKey:@"type"] intValue]==Activity_Type_all ){
			[result addObject:activity];
		}
	}
	return result;
}

-(NSDictionary*)getActivity:(Activity_Type)type activityId:(int)_id{
	NSArray * lists = [[GameConnection share] getAllActivity];
	for(NSDictionary * activity in lists){
		if([[activity objectForKey:@"type"] intValue]==type ||
		   [[activity objectForKey:@"type"] intValue]==Activity_Type_all ){
			
			int temp = [[activity objectForKey:@"id"] intValue];
			if (temp == _id && _id != 0) {
				return activity;
			}
			
		}
	}
	return nil;
}


-(BOOL)checkActivityCondition:(Activity_Type)type activityId:(int)_id{
	NSArray * lists = [[GameConnection share] getAllActivity];
	for(NSDictionary * activity in lists){
		if([[activity objectForKey:@"type"] intValue]==type ||
		   [[activity objectForKey:@"type"] intValue]==Activity_Type_all ){
			
			int temp = [[activity objectForKey:@"id"] intValue];
			if (temp == _id && _id != 0) {
				NSString* string = [activity objectForKey:@"condition"];
				if (string) {
					NSArray* ary = [string componentsSeparatedByString:@":"];
					if (ary.count == 2) {
						NSString* head = [ary objectAtIndex:0];
						NSString* content = [ary objectAtIndex:1];
						if ([@"vip" isEqualToString:head]) {
							
							int targetLv = [content intValue];
							int vip= [[GameConfigure shared] getPlayerVipLevel];
							if (vip < targetLv) {
								return YES;
							}
						}
					}
				}
			}
		}
	}
	return NO;
}

@end
