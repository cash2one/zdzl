//
//  FightTeam.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@class FightMember;
@interface FightTeam : NSObject{
	
	int classIndex;
	int playerId;
	int level;
	int icon;
	Fight_team_icon_type icon_type;
	
	NSMutableArray * members;
	NSMutableArray * buffs;
	NSMutableArray * playerIds;
	
	NSMutableDictionary* damages;
	
}
@property(nonatomic,assign) int classIndex;
@property(nonatomic,assign) int playerId;
@property(nonatomic,assign) int level;
@property(nonatomic,assign) int icon;
@property(nonatomic,assign) Fight_team_icon_type icon_type;
@property(nonatomic,assign) NSMutableArray * members;
@property(nonatomic,assign) NSMutableDictionary * damages;

-(BOOL)isEmpty;
-(BOOL)isKillAll;
-(int)getDieLeftkindCount;

-(void)addMember:(FightMember*)member;
-(void)removeMember:(FightMember*)member;

-(void)addPlayer:(int)pid;

-(int)getTeamTopType;

-(FightMember*)getTargetByIndex:(int)index;

-(NSArray*)getMembersByMode:(Attack_mode)mode index:(int)index;
-(NSArray*)getMembersSortDownHP:(int)count;
-(NSArray*)getMembersSortDownMP:(int)count;

-(NSArray*)getMembersDamages;

-(void)logTeamBuff:(NSDictionary*)buff type:(Fight_Buff_Type)type;

-(NSDictionary*)getTeamInfo;
-(NSString*)getTeamInfoSting;

-(void)logMemberDamages;

@end
