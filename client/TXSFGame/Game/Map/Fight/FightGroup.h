//
//  FightGroup.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-3.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class FightPlayer;
@class FightCharacter;
@interface FightGroup : NSObject{
	int groupId;
	int playerId;
	NSMutableArray * groups;
	FightPlayer * player;
	
	int selectIndex;
	NSArray * buffs;
	
	FightGroup * targetGroup;
	
	BOOL isShowHeadIcon;
	
	NSArray * playerIds;
	
}
@property(nonatomic,assign) int groupId;
@property(nonatomic,assign) int playerId;
@property(nonatomic,assign) BOOL isCurrentUser;
@property(nonatomic,assign) FightPlayer * player;
@property(nonatomic,assign) FightGroup * targetGroup;

-(void)setGroupInfo:(NSString*)info;
-(void)setGroupTeam:(NSString*)info;

-(FightCharacter*)getCharacterByIndex:(int)i;
-(void)showEffect:(int)eid offset:(int)offset;

-(int)getLiveCount;

-(void)openHeadIcon;
-(void)closeHeadIcon;

-(void)updateSpeed;
//fix chao
-(void)hideInfo;
//end

@end
