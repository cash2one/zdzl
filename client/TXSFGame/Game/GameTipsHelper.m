//
//  GameTipsHelper.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameTipsHelper.h"

#import "GameDB.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "TaskManager.h"

static GameTipsHelper * gameTipsHelper;
@implementation GameTipsHelper

+(void)start{
	if(gameTipsHelper==nil){
		gameTipsHelper = [[GameTipsHelper alloc] init];
	}
}

+(void)stopAll{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if(gameTipsHelper){
		[gameTipsHelper release];
		gameTipsHelper = nil;
	}
}

+(BOOL)checkUpdateCBEWith:(WINDOW_TYPE)_type{
	BOOL isNeed = NO ;
	
	if (_type == PANEL_CHARACTER	||
		_type == PANEL_FATE			||
		_type == PANEL_WEAPON		||
		_type == PANEL_RECRUIT		||
		_type == PANEL_PHALANX		||
		NO) {
		isNeed = YES ;
	}
	
	return isNeed ;
}

#pragma mark -

-(id)init{
	if((self=[super init])!=nil){
		
		totalCanUpArm = 0;
		totalCanUpPos = 0;
		totalCanAddRole = 0;
		
		[GameConnection addPost:ConnPost_updatePackage target:self call:@selector(didUpdate:)];
		[GameConnection addPost:ConnPost_updatePlayerUpLevel target:self call:@selector(didCheckCBEWithLevel:)];
		[GameConnection addPost:ConnPost_window_close target:self call:@selector(didCheckCBEWithCloseWindow:)];
		
		[NSTimer scheduledTimerWithTimeInterval:3.0f
										 target:self
									   selector:@selector(startCheck)
									   userInfo:nil
										repeats:NO];
	}
	return self;
}

-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[GameConnection removePostTarget:self];
	[super dealloc];
}

#pragma mark -

-(void)didUpdate:(NSNotification*)notification{
	[NSTimer scheduledTimerWithTimeInterval:1.0f
									 target:self
								   selector:@selector(startCheck)
								   userInfo:nil
									repeats:NO];
}

-(void)startCheck{
	
	dispatch_queue_t queue = dispatch_queue_create("TipsHelper", NULL);
	dispatch_async(queue, ^{
		
		totalCanUpArm = 0;
		totalCanUpPos = 0;
		totalCanAddRole = 0;
		
		NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
		
		int level = [[playerInfo objectForKey:@"level"] intValue];
		int train = [[playerInfo objectForKey:@"train"] intValue];
		
		////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		NSArray * roles = [[GameConfigure shared] getPlayerRoleList];
		for(NSDictionary * role in roles){
			int armLevel = [[role objectForKey:@"armLevel"] intValue];
			NSDictionary * armExpInfo = [[GameDB shared] getArmExpInfo:(armLevel+1)];
			if(armExpInfo){
				int exp = [[armExpInfo objectForKey:@"exp"] intValue];
				if(train>exp){
					totalCanUpArm += 1;
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		NSArray * userPosition = [[GameConfigure shared] getPlayerPhalanxList];
		NSMutableDictionary * position = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getPositionList]];
		for(NSDictionary * pos in userPosition){
			int pid = [[pos objectForKey:@"posId"] intValue];
			int level = [[pos objectForKey:@"level"] intValue];
			[position removeObjectForKey:[NSString stringWithFormat:@"%d",pid]];
			if([self checkPosition:pid level:level userLevel:level]){
				totalCanUpPos += 1;
			}
		}
		for(NSString * pos in position){
			int pid = [pos intValue];
			if([self checkPosition:pid level:1 userLevel:level]){
				totalCanUpPos += 1;
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		NSMutableDictionary * roleList = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getRoleList]];
		
		for(NSDictionary * role in roles){
			int rid = [[role objectForKey:@"rid"] intValue];
			[roleList removeObjectForKey:[NSString stringWithFormat:@"%d",rid]];
		}
		
		for(NSString * key in roleList){
			int rid = [key intValue];
			if(rid>6){
				
				NSDictionary * tRole = [roleList objectForKey:key];
				int invLV = [[tRole objectForKey:@"invLV"] intValue];
				if(invLV<=level && (invLV!=0)){
					
					BOOL isPass = YES;
					//NSDictionary * invs = getFormatToDict([tRole objectForKey:@"invs"]);
					
					NSArray * ary1 = [[tRole objectForKey:@"invs"] componentsSeparatedByString:@"|"];
					
					for(NSString * value in ary1){
						
						NSArray * ary2 = [value componentsSeparatedByString:@":"];
						
						if(isEqualToKey([ary2 objectAtIndex:0], @"tid")){
							int tid = [[ary2 objectAtIndex:1] intValue];
							if([[TaskManager shared] isCompleteTask:tid]==NO){
								isPass = NO;
								break;
							}
						}else if(isEqualToKey([ary2 objectAtIndex:0], @"rid")){
							int _rid = [[ary2 objectAtIndex:1] intValue];
							NSDictionary * tRole = [[GameConfigure shared] getUserRoleById:_rid];
							if(tRole==nil){
								isPass = NO;
								break;
							}
						}
					}
					
					if(isPass){
						totalCanAddRole += 1;
					}
					
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self didCheckOver];
		});
		
	});
	
	dispatch_release(queue);
}

-(void)didCheckOver{
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	[result setObject:[NSNumber numberWithInt:totalCanUpArm] forKey:@"arm_count"];
	[result setObject:[NSNumber numberWithInt:totalCanUpPos] forKey:@"pos_count"];
	[result setObject:[NSNumber numberWithInt:totalCanAddRole] forKey:@"role_count"];
	
	[GameConnection post:Post_GameTipsHelper_message object:result];
	
}

#pragma mark -
-(BOOL)checkPosition:(int)pid level:(int)level userLevel:(int)userLevel{
	NSDictionary * posLevel = [[GameDB shared] getPositionLevelInfo:pid level:level];
	if(posLevel){
		int lockTask = [[posLevel objectForKey:@"lockTask"] intValue];
		int lockLevel = [[posLevel objectForKey:@"lockLevel"] intValue];
		if(lockLevel<=userLevel && [[TaskManager shared] isCompleteTask:lockTask]){
			return YES;
		}
	}
	return NO;
}

#pragma mark - cbe

-(void)didCheckCBEWithLevel:(NSNotification*)notification{
	CCLOG(@"didCheckCBEWithLevel");
	checkCount = checkCount + 1 ;
	
	//[self startCheckCBE];
	[NSTimer scheduledTimerWithTimeInterval:1.0f
									 target:self
								   selector:@selector(startCheckCBE)
								   userInfo:nil
									repeats:NO];
	
}

-(void)didCheckCBEWithCloseWindow:(NSNotification*)notification{
	CCLOG(@"didCheckCBEWithCloseWindow");
	NSNumber* number = notification.object;
	if (number) {
		if (![GameTipsHelper checkUpdateCBEWith:[number intValue]]) {
			return ;
		}
		checkCount = checkCount + 1 ;
		
		//[self startCheckCBE];
		
		[NSTimer scheduledTimerWithTimeInterval:1.0f
										 target:self
									   selector:@selector(startCheckCBE)
									   userInfo:nil
										repeats:NO];
	}
}

-(void)startCheckCBE {
	if (isChecking) {
		return ;
	}
	if (checkCount > 0) {
		checkCount -= 1 ;
		[self runCheckCBE];
	}
}

//
-(void)endCheckCBE{
	isChecking = NO;
	if (checkCount > 0) {
		[NSTimer scheduledTimerWithTimeInterval:1.0f
										 target:self
									   selector:@selector(startCheckCBE)
									   userInfo:nil
										repeats:NO];
	}else{
		NSDictionary* dict = [[GameConfigure shared] getPlayerCBE];
		int cbe = [[dict objectForKey:@"CBE"] intValue];
		if (cbe < totalCbe) {
			[GameConnection post:ConnPost_updatecbe object:[NSNumber numberWithInt:totalCbe]];
			NSMutableDictionary* rDict = [NSMutableDictionary dictionaryWithDictionary:dict];
			[rDict setObject:[NSNumber numberWithInt:totalCbe] forKey:@"CBE"];
			[[GameConfigure shared] updatePlayerCBE:rDict];
		}
	}
}
//
-(void)runCheckCBE{
	if (isChecking) {
		return ;
	}
	dispatch_queue_t queue = dispatch_queue_create("GameTipsHelper.startCheckCBE", NULL);
	dispatch_async(queue, ^{
		CCLOG(@"startCheckCBE->begin");
		isChecking = YES ;
		totalCbe = 0 ;
		NSArray* teams = [[GameConfigure shared] getUserChoosePositionMember];
		for (NSNumber *number in teams) {
			int _rid = [number intValue];
			BaseAttribute att = [[GameConfigure shared] getRoleAttribute:_rid isLoadOtherBuff:YES];
			int __value = getBattlePower(att);
			totalCbe += __value;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			CCLOG(@"startCheckCBE->end");
			[self endCheckCBE];
		});
	});
	dispatch_release(queue);
}

@end
