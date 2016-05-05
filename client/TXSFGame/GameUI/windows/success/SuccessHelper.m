//
//  SuccessHelper.m
//  TXSFGame
//
//  Created by Soul on 13-4-12.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SuccessHelper.h"
#import "GameConnection.h"
#import "Config.h"
#import "GameDB.h"
#import "ShowItem.h"
#import "GameConfigure.h"
#import "AlertManager.h"
#import "CJSONDeserializer.h"

int sortSuccessKeys(NSString *p1, NSString* p2, void *context){
	
	int eid1 = [p1 intValue];
	int eid2 = [p2 intValue];
	
	if(eid1>eid2) return NSOrderedDescending;
	if(eid1<eid2) return NSOrderedAscending;
	
	return NSOrderedSame;
}


static SuccessHelper* s_SuccessHelper = nil ;

@implementation SuccessHelper

@synthesize isReady = _isReady;

+(SuccessHelper*)shared{
	if (s_SuccessHelper == nil) {
		s_SuccessHelper = [[SuccessHelper alloc] init];
	}
	return s_SuccessHelper;
}

+(void)start{
	[[SuccessHelper shared] achiEnter];
}

+(void)stopAll{
	if(s_SuccessHelper){
		//[GameConnection freeRequest:self];
		[s_SuccessHelper release];
		s_SuccessHelper = nil;
	}
}

-(void)dealloc{
	CCLOG(@"SuccessHelper->dealloc");
	[GameConnection freeRequest:self];
	[self freeData];
    //[GameConnection freeRequest:self];
	[super dealloc];
}

-(void)freeData{
	if (successDict != nil) {
		[successDict release];
		successDict = nil;
	}
}

-(void)achiEnter{
	_isReady = NO;
	[GameConnection request:@"achiEnter" format:@"" target:self call:@selector(endAchiEnter:)];
}

-(void)endAchiEnter:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		[self freeData];
		NSDictionary* dict = getResponseData(_sender);
		if (dict != nil) {
			successDict = [NSMutableDictionary dictionaryWithDictionary:dict];
			[successDict retain];
		}
		_isReady = YES;
		[GameConnection post:@"SuccessHelper_refresh" object:nil];
		
	}else{
		//[ShowItem showItemAct:@"加载成就数据出错"];
        [ShowItem showItemAct:NSLocalizedString(@"success_helper_load_error",nil)];
	}
}

-(void)achiUpdate:(NSNotification*)notification{
	NSDictionary * data = notification.object;
	if (data != nil) {
		
		NSDictionary* day = [data objectForKey:@"day"];
		if (day != nil) {
			NSArray* keys = [day allKeys];
			for (NSString* key in keys) {
				NSDictionary* vDict  = [day objectForKey:key];
				[successDict setObject:vDict forKey:key];
			}
		}
		
		NSDictionary* ever = [data objectForKey:@"ever"];
		if (ever != nil) {
			NSArray* keys = [ever allKeys];
			for (NSString* key in keys) {
				NSDictionary* vDict  = [day objectForKey:key];
				SuccessStatus status = [[vDict objectForKey:@"s"] intValue];
				if (status == SuccessStatus_done) {
					[successDict setObject:vDict forKey:key];
				}else{
					[successDict setObject:vDict forKey:key];
					int _id = [key intValue];
					_id = _id -1 ;
					NSString* tmp = [NSString stringWithFormat:@"%d",_id];
					[successDict removeObjectForKey:tmp];
				}
			}
		}
	}
}

-(void)endGetSuccrss:(NSDictionary *)_sender{
	if (checkResponseStatus(_sender)) {
		NSDictionary* data = getResponseData(_sender);
		
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:data
																   type:PackageItem_all];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
		
		[[GameConfigure shared] updatePackage:data];
		//全部更新
		[GameConnection request:@"achiEnter" format:@"" target:self call:@selector(endAchiEnter:)];
	}
}

-(NSArray*)getSuccessesInfo:(SuccessType)_type{
	NSMutableArray* results = [NSMutableArray array];
	
	if (_type == SuccessType_none) {
		return results;
	}
	if (successDict == nil) {
		return results;
	}
	
	NSDictionary* tabels = nil ;
	
	if (_type == SuccessType_day) {
		tabels = [successDict objectForKey:@"day"];
	}else if (_type == SuccessType_ever){
		tabels = [successDict objectForKey:@"ever"];
	}
	
	if (tabels == nil) {
		return results ;
	}
	
	NSMutableArray* keys = [NSMutableArray arrayWithArray:[tabels allKeys]];
	
	[keys sortUsingFunction:sortSuccessKeys context:nil];
	
	for (NSString* key in keys) {
		NSDictionary* info_ = [tabels objectForKey:key];
		if (info_ != nil) {
			int count1 = 0;
			int count2 = 0;
			
			NSArray* cubKeys = [info_ allKeys];
			if ([cubKeys containsObject:@"c"]) {
				count1 = [[info_ objectForKey:@"c"] intValue];
			}
			if ([cubKeys containsObject:@"n"]) {
				count2 = [[info_ objectForKey:@"n"] intValue];
			}
			
			SuccessStatus status = [[info_ objectForKey:@"s"] intValue];
			
			NSDictionary* successInfo = nil;
			
			if (_type == SuccessType_day) {
				successInfo = [[GameDB shared] getDaySuccessInfo:[key intValue]];
			}else if (_type == SuccessType_ever){
				successInfo = [[GameDB shared] getEverSuccessInfo:[key intValue]];
			}
			
			if (successInfo == nil) continue ;
			
			NSString* type_ = [NSString stringWithFormat:@"%d",_type];
			NSString* name = [successInfo objectForKey:@"name"];
			NSString* describe = [successInfo objectForKey:@"info"];
			NSString* outcome = [NSString stringWithFormat:@"%d/%d",count1,count2];
			NSString* bnts = [NSString stringWithFormat:@"%d",status];
			NSString* result = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@",
								key,
								type_,
								name,
								describe,
								outcome,
								bnts];
			[results addObject:result];
		}
	}
	
	
	return results;
}

-(NSArray*)getSuccessesLog{
	NSMutableArray* results = [NSMutableArray array];
	if (successDict == nil) {
		return results;
	}
	NSDictionary* dict = [successDict objectForKey:@"finish"];
	
	NSMutableArray* keys = [NSMutableArray arrayWithArray:[dict allKeys]];
	[keys sortUsingFunction:sortSuccessKeys context:nil];
	
	for (NSString* key in keys) {
		NSString* times = [dict objectForKey:key];
		int _id = [key intValue];
		NSDictionary* successInfo = [[GameDB shared] getEverSuccessInfo:_id];
		if (successInfo != nil) {
			int rid = [[successInfo objectForKey:@"rid"] intValue];
			
			NSDictionary* rDict = [[GameDB shared] getRewardInfo:rid];
			if (rDict != nil) {
				NSError * error = nil;
				NSData * data = getDataFromString([rDict objectForKey:@"reward"]);
				NSDictionary * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
				if(!error){
					
					NSString* rewardString = [NSString stringWithFormat:@""];
					
					for(NSDictionary * reward in rewards){
						
						NSString * type = [reward objectForKey:@"t"];
						int i = [[reward objectForKey:@"i"] intValue];
						int count = [[reward objectForKey:@"c"] intValue];
						
						if (type != nil) {
							NSDictionary* item = nil;
							if ([@"i" isEqualToString:type]) {
								item = [[GameDB shared] getItemInfo:i];
							}
							if ([@"e" isEqualToString:type]) {
								item = [[GameDB shared] getEquipmentInfo:i];
							}
							if ([@"f" isEqualToString:type]) {
								item = [[GameDB shared] getFateInfo:i];
							}
							if ([@"c" isEqualToString:type]) {
								item = [[GameDB shared] getCarInfo:i];
							}
							if ([@"r" isEqualToString:type]) {
								item = [[GameDB shared] getRoleInfo:i];
							}
							
							if (item != nil) {
								NSString* rewardDes = [item objectForKey:@"name"];
								rewardDes = [rewardDes stringByAppendingFormat:@"x%d",count];
								if ([rewardString length] == 0) {
									rewardString = [rewardString stringByAppendingFormat:@"%@",rewardDes];
								}else{
									rewardString = [rewardString stringByAppendingFormat:@"::%@",rewardDes];
								}
							}
						}
					}
					
					NSString* name = [successInfo objectForKey:@"name"];
					NSString* describe = [successInfo objectForKey:@"info"];
					//times = timestmpToTime(times, @"MM月dd日 HH:mm");
                    times = timestmpToTime(times, NSLocalizedString(@"success_helper_date",nil));
					
					NSString* result = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",
										key,
										name,
										describe,
										rewardString,
										times];
					
					[results addObject:result];
				}
			}
		}
	}
	return results;
}

@end









