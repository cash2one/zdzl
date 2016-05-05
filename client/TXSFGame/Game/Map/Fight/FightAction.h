//
//  FightAction.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class FightTeam;
@class FightMember;
@class FightStatus;

@interface FightAction : NSObject{
	
	int fightId;
	
	FightTeam * targetTeam;
	FightTeam * userTeam;
	
	int roundIndex;
	NSMutableArray * allMember;
	
	NSMutableDictionary * allTeamInfo;
	NSMutableArray * allActionInfo;
	
	NSTimer * timer;
	
}
@property(nonatomic,assign) int fightId;
@property(nonatomic,assign) int roundIndex;

+(void)stopAll;

+(void)startFight:(int)fid;
+(void)startFightAbyss:(NSDictionary*)data;
+(void)startCustomizeFight:(NSDictionary*)data;
+(void)startByPlayer:(NSDictionary*)data;

+(void)startByTeam:(NSDictionary*)data fight:(int)fid;
+(void)startByTeams:(NSDictionary*)data;

+(void)startFightWorldBoss:(NSDictionary*)data;

+(void)startFightDragonByNPC:(NSDictionary*)data fight:(int)fid;//狩龙战NPC战
+(void)startFightDragonByPlayer:(NSDictionary*)data;//狩龙战影分身

+(void)cleanFight;



//==============================================================================
//==============================================================================

-(void)logActionChangeHP:(FightMember*)member hp:(int)hp isBok:(BOOL)isBok isCpr:(BOOL)isCpr isPen:(BOOL)isPen;
-(void)logActionChangePower:(FightMember*)member power:(int)power;
-(void)logActionDie:(FightMember*)member;

-(void)logActionReadySkill:(FightMember*)member;
-(void)logActionRemoveSkill:(FightMember*)member;

-(void)logActionMove:(FightMember*)member target:(FightMember*)target;
-(void)logActionBack:(FightMember*)member;

-(void)logActionAttack:(FightMember*)member;
-(void)logActionSkill:(FightMember*)member;

-(void)logActionAddStatus:(FightMember*)member status:(FightStatus*)status;
-(void)logActionUpdateStatus:(FightMember*)member status:(FightStatus*)status;
-(void)logActionRemoveStatus:(FightMember*)member status:(FightStatus*)status;

-(void)logActionDelay:(float)time;

-(void)logActionEnd:(FightTeam*)team;

-(void)logActionEffectSingle:(FightMember*)member effect:(int)eid offset:(int)offset;
-(void)logActionEffectAll:(FightTeam*)team effect:(int)eid offset:(int)offset;

-(void)logActionEffectAdd:(FightMember*)member;
-(void)logActionEffectBok:(FightMember*)member;
-(void)logActionEffectCob:(FightMember*)member;
-(void)logActionEffectCot:(FightMember*)member;
-(void)logActionEffectCpr:(FightMember*)member;
-(void)logActionEffectMis:(FightMember*)member;
-(void)logActionEffectPen:(FightMember*)member;

@end



