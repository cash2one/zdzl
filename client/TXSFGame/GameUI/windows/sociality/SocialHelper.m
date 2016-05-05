//
//  SocialHelper.m
//  TXSFGame
//
//  Created by Soul on 13-3-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SocialHelper.h"
#import "PlayerDataHelper.h"
#import "GameConnection.h"
#import "OtherPlayerPanel.h"
#import "ShowItem.h"

static SocialHelper* s_SocialHelper = nil ;

@implementation NSMutableDictionary(SocialDictHelper)

+(id)dictionaryWithInt:(int)_value forKey:(NSString *)_key{
	NSNumber* number = [NSNumber numberWithInt:_value];
	return [NSMutableDictionary dictionaryWithObject:number forKey:_key];
}

-(void)addMembersWithArray:(NSArray *)_array{
	if (_array == nil)  return ;
	
	for (NSDictionary* dict in _array) {
		int pid = [dict intForKey:@"id"];
		if (pid > 0) {
			NSString* ____key = [NSString stringWithFormat:@"%d",pid];
			[self setObject:dict forKey:____key];
		}
	}
	
}

-(void)removeMembersWithArray:(NSArray *)_array{
	if (_array == nil)  return ;
	
	for (NSDictionary* dict in _array) {
		int pid = [dict intForKey:@"id"];
		if (pid > 0) {
			NSString* ____key = [NSString stringWithFormat:@"%d",pid];
			[self removeObjectForKey:____key];
		}
	}
	
}

-(BOOL)removeMember:(NSDictionary *)_member{
	if(_member == nil) return NO;
	
	int id1 = [_member intForKey:@"id"];
	NSString* ____key = [NSString stringWithFormat:@"%d",id1];
	
	NSArray* array = [self allKeys];
	
	if ([array containsObject:____key]) {
		[self removeObjectForKey:____key];
		return YES ;
	}
	
	return NO;
}

@end

@implementation SocialHelper

@synthesize isReady = _isReady;
@synthesize friends;
@synthesize blacklists;
@synthesize otherMembers;
@synthesize isOverWindows;

+(SocialHelper*)shared{
	if (s_SocialHelper == nil) {
		s_SocialHelper = [[SocialHelper alloc] init];
		[s_SocialHelper retain];
	}
	return s_SocialHelper;
}

+(void)stopAll{
	if(s_SocialHelper){
		[s_SocialHelper release];
		s_SocialHelper = nil;
	}
}

-(void)dealloc{
	
	CCLOG(@"SocialHelper dealloc!");
	if (friends) {
		[friends release];
		friends = nil ;
	}
	
	if (blacklists) {
		[blacklists release];
		blacklists = nil ;
	}
	
	if (otherMembers) {
		[otherMembers release];
		otherMembers = nil ;
	}
	//[GameConnection freeRequest:self];
	[super dealloc];
}

-(id)init{
	if ((self = [super init])) {
		
		if (friends == nil) {
			friends = [NSMutableDictionary dictionary];
			[friends retain];
		}
		
		if (blacklists == nil) {
			blacklists = [NSMutableDictionary dictionary];
			[blacklists retain];
		}
		
		if (otherMembers == nil) {
			otherMembers = [NSMutableDictionary dictionary];
			[otherMembers retain];
		}
		
		_fPage = 1 ;
		_ePage = 1 ;
		_oPage = 1 ;
		
	}
	return self;
}

-(void)freeMembers{
	
	if (friends) {
		[friends removeAllObjects];
	}
	
	if (blacklists) {
		[blacklists removeAllObjects];
	}
	
	if (otherMembers) {
		[otherMembers removeAllObjects];
	}
	
	_oPage = 1 ;
	_ePage = 1 ;
	_fPage = 1 ;
	
}

#pragma mark -- action --

-(void)socialAction:(int)_pid action:(SocialHelper_action)_act{
	if (_act == SocialHelper_none) return ;
	if (_pid <= 0) return ;
	
	SEL				_call = nil ;
	NSString*		_msg  = nil ;
	
	
	if (_act == SocialHelper_addFriend){
		_call = @selector(doAddFriend::);
		_msg  = [NSString stringWithFormat:@"socialAddFriend"];
	}
	
	if (_act == SocialHelper_delFriend){
		_call = @selector(doDelFriend::);
		_msg  = [NSString stringWithFormat:@"socialDelFriend"];
	}
	
	if (_act == SocialHelper_addBlack){
		_call = @selector(doAddBlack::);
		_msg  = [NSString stringWithFormat:@"socialAddBlack"];
	}
	
	if (_act == SocialHelper_delBlack){
		_call = @selector(doDelBlack::);
		_msg  = [NSString stringWithFormat:@"socialDelBlack"];
	}
	
	if (_msg != nil && _call != nil) {
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithInt:_pid forKey:@"pid"];
		NSMutableDictionary* dict2 = [NSMutableDictionary dictionaryWithInt:_pid forKey:@"id"];
		[GameConnection request:_msg
						   data:dict
						 target:self
						   call:_call
							arg:dict2];
	}
	
}

-(void)socialActionWithName:(NSString *)_name action:(SocialHelper_action)_act
{
	if (_act == SocialHelper_none) return ;
	if (_name == nil || [_name isEqualToString:@""]) return ;
	
	SEL				_call = nil ;
	NSString*		_msg  = nil ;
	
	if (_act == SocialHelper_addFriend){
		_call = @selector(doAddFriend::);
		_msg  = [NSString stringWithFormat:@"socialAddFriend"];
	}
	if (_act == SocialHelper_addBlack){
		_call = @selector(doAddBlack::);
		_msg  = [NSString stringWithFormat:@"socialAddBlack"];
	}

	
	if (_msg != nil && _call != nil) {
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObject:_name forKey:@"name"];
		[GameConnection request:_msg
						   data:dict
						 target:self
						   call:_call
							arg:dict];
	}
}

-(void)doAddFriend:(NSDictionary *)_sender :(NSDictionary*)_arg{
	CCLOG(@"doAddFriend");
	if (checkResponseStatus(_sender)) {
		
		//[ShowItem showItemAct:@"好友添加成功"];
		[ShowItem showItemAct:NSLocalizedString(@"social_helper_add_ok",nil)];
		
		NSDictionary* data = getResponseData(_sender);
		
		if (data != nil) {
			NSArray* array1 = [NSArray arrayWithObject:data];
			
			if (friends) {
				[friends addMembersWithArray:array1];
				[GameConnection post:Post_socialHelper_add_friends object:data];
			}
			
			if (blacklists) {
				
				if ([blacklists removeMember:data]) {
					[GameConnection post:Post_socialHelper_del_enemies object:data];
				}
			}
		}
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)doDelFriend:(NSDictionary *)_sender :(NSDictionary*)_arg{
	CCLOG(@"doDelFriend");
	if (checkResponseStatus(_sender)) {
		
		//[ShowItem showItemAct:@"好友删除成功"];
		[ShowItem showItemAct:NSLocalizedString(@"social_helper_del_ok",nil)];
        
		if (friends) {
			if ([friends removeMember:_arg]) {
				[GameConnection post:Post_socialHelper_del_friends object:_arg];
			}
		}
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)doAddBlack:(NSDictionary *)_sender :(NSDictionary*)_arg{
	CCLOG(@"doAddBlack");
	if (checkResponseStatus(_sender)) {
		
		//[ShowItem showItemAct:@"黑名单添加成功"];
        [ShowItem showItemAct:NSLocalizedString(@"social_helper_add_blacklist_ok",nil)];
		
		NSDictionary* data = getResponseData(_sender);
 		
		if (data != nil) {
			NSArray* array1 = [NSArray arrayWithObject:data];
			
			if (blacklists) {
				[blacklists addMembersWithArray:array1];
				[GameConnection post:Post_socialHelper_add_enemies object:data];
			}
			
			if (friends) {
				if ([friends removeMember:data]) {
					[GameConnection post:Post_socialHelper_del_friends object:data];
				}
			}
		}
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)doDelBlack:(NSDictionary *)_sender :(NSDictionary*)_arg{
	CCLOG(@"doDelBlack");
	if (checkResponseStatus(_sender)) {
		
		//[ShowItem showItemAct:@"黑名单删除成功"];
        [ShowItem showItemAct:NSLocalizedString(@"social_helper_del_blacklist_ok",nil)];
		
		if (blacklists) {
			if ([blacklists removeMember:_arg]) {
				[GameConnection post:Post_socialHelper_del_enemies object:_arg];
			}
		}
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}



-(void)socialGetInfo:(int)_pid name:(NSString *)_name{
	if (_pid  <= 0 )		return ;
	if (_name == nil)		return ;
	
	if (otherPlayer != nil) {
		NSDictionary* _player = [otherPlayer objectForKey:@"player"];
		if (_player != nil) {
			int pid = [_player intForKey:@"id"];
			if (pid == _pid) {
				return ;
			}
		}
	}
	
	if (otherPlayer != nil) {
		[otherPlayer release];
		otherPlayer = nil ;
	}
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:_pid] forKey:@"pid"];
	[dict setObject:_name forKey:@"name"];
	
	[GameConnection request:@"lookPlayer"
					   data:dict
					 target:self
					   call:@selector(doGetInfo:)];
}

-(void)socialGetInfo:(NSString *)_name isOver:(bool)_isOver{
	
	if (_name == nil)		return ;
	
	if (otherPlayer != nil) {
		NSDictionary* _player = [otherPlayer objectForKey:@"player"];
		if (_player != nil) {
			NSString *pname = [_player valueForKey:@"name"];
			if (_name == pname) {
				return ;
			}
		}
	}
	isOverWindows = _isOver;
	if (otherPlayer != nil) {
		[otherPlayer release];
		otherPlayer = nil ;
	}
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:_name forKey:@"name"];
	
	[GameConnection request:@"lookPlayer"
					   data:dict
					 target:self
					   call:@selector(doGetInfo:)];
}


-(void)doGetInfo:(NSDictionary *)_sender{
	CCLOG(@"doGetInfo");
	if (checkResponseStatus(_sender)) {
		if (otherPlayer != nil) {
			[otherPlayer release];
			otherPlayer = nil ;
		}
		
		NSDictionary* data = getResponseData(_sender);
		if(isOverWindows){
			[OtherPlayerPanel showOver:data];
			isOverWindows = false;
		}else{
			[OtherPlayerPanel show:data];
		}
		
	}else{
		CCLOG(@"doGetInfo->error!");
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)socialRelationmembers:(SocialHelper_relation)_relation{
	
	SEL		  _call		= nil ;
	int		  _page		= 0 ;
	
	if (_relation == SocialHelper_relation_friend) {
		_page = _fPage;
		_call = @selector(doForMoreFriend:);
	}
	
	if (_relation == SocialHelper_relation_enemy) {
		_page = _ePage;
		_call = @selector(doForMoreEnemy:);
	}
	
	if (_relation == SocialHelper_relation_stranger) {
		_page = _oPage;
		_call = @selector(doForMoreStranger:);
	}
	
	if (_call != nil) {
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:_relation] forKey:@"t"];
		[dict setObject:[NSNumber numberWithInt:_page] forKey:@"page"];
		
		[GameConnection request:@"socialGetInfo"
						   data:dict
						 target:self
						   call:_call];
		
	}
	
}

-(void)doForMoreFriend:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		NSDictionary* dict = getResponseData(_sender);
		NSArray* array = [dict objectForKey:@"rl"];
		if (array != nil && array.count > 0) {
			if (friends) {
				[friends addMembersWithArray:array];
				[GameConnection post:Post_socialHelper_update_friends object:nil];
				_fPage++;
			}
		}else{
			CCLOG(@"have no friends");
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)doForMoreEnemy:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		NSDictionary* dict = getResponseData(_sender);
		NSArray* array = [dict objectForKey:@"rl"];
		if (array != nil && array.count > 0) {
			if (blacklists) {
				[blacklists addMembersWithArray:array];
				[GameConnection post:Post_socialHelper_update_enemies object:nil];
				_ePage++;
			}
		}else{
			CCLOG(@"have no enemies");
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

-(void)doForMoreStranger:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		NSDictionary* dict = getResponseData(_sender);
		NSArray* array = [dict objectForKey:@"rl"];
		if (array != nil && array.count > 0) {
			
			[otherMembers removeAllObjects];
			
			if (otherMembers) {
				[otherMembers addMembersWithArray:array];
				[GameConnection post:Post_socialHelper_update_strangers object:nil];
				_oPage++;
			}
			
		}else{
			CCLOG(@"have no strangers");
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}

#pragma mark -- action end --

@end











