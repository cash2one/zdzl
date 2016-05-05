//
//  SocialHelper.h
//  TXSFGame
//
//  Created by Soul on 13-3-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>


#define Post_socialHelper_update_friends						@"SocialHelper_update_friends"
#define Post_socialHelper_update_enemies						@"SocialHelper_update_enemies"
#define Post_socialHelper_update_strangers						@"SocialHelper_update_strangers"

#define Post_socialHelper_add_friends							@"Post_socialHelper_add_friends"
#define Post_socialHelper_del_friends							@"Post_socialHelper_del_friends"

#define Post_socialHelper_add_enemies							@"Post_socialHelper_add_enemies"
#define Post_socialHelper_del_enemies							@"Post_socialHelper_del_enemies"

typedef enum{
	
	SocialHelper_none = 0 ,
	
	SocialHelper_addFriend,
	SocialHelper_delFriend,
	SocialHelper_addBlack,
	SocialHelper_delBlack,
	//SocialHelper_battle,
	
}SocialHelper_action;

typedef enum{
	SocialHelper_relation_none		= 0 ,
	SocialHelper_relation_friend	= 1 ,//好友
	SocialHelper_relation_enemy		= 2 ,//敌对
	SocialHelper_relation_stranger	= 3 ,//陌生人
	
}SocialHelper_relation;

@interface NSMutableDictionary (SocialDictHelper)

+(id)dictionaryWithInt:(int)object forKey:(NSString*)_key;

-(void)addMembersWithArray:(NSArray*)_array;
-(void)removeMembersWithArray:(NSArray*)_array;

-(BOOL)removeMember:(NSDictionary*)_member;

@end

@interface SocialHelper : NSObject{
	
	NSMutableDictionary* friends;
	NSMutableDictionary* blacklists;
	NSMutableDictionary* otherMembers;
	
	BOOL		_isReady;
	
	//----------------------------------
	NSDictionary*		 otherPlayer;
	
	int			_fPage;
	int			_ePage;
	int			_oPage;
	bool		isOverWindows;
}
@property(nonatomic,assign)BOOL isReady;
@property(nonatomic,assign)NSMutableDictionary* friends;
@property(nonatomic,assign)NSMutableDictionary* blacklists;
@property(nonatomic,assign)NSMutableDictionary* otherMembers;
@property(nonatomic,assign)bool isOverWindows;


+(SocialHelper*)shared;
+(void)stopAll;


-(void)freeMembers;

-(void)socialAction:(int)_pid action:(SocialHelper_action)_act;
-(void)socialActionWithName:(NSString *)_name action:(SocialHelper_action)_act;
-(void)socialGetInfo:(int)_pid name:(NSString*)_name;
-(void)socialGetInfo:(NSString *)_name isOver:(bool)_isOver;

-(void)socialRelationmembers:(SocialHelper_relation) _relation;

@end
