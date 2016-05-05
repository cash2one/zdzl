//
//  FightManager.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-20.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum{
	Fight_Type_normal		= 1,
	Fight_Type_abyss		= 2,
	Fight_Type_custom		= 3,
	Fight_Type_pk			= 4,
	Fight_Type_pve			= 5,
	Fight_Type_bossFight	= 6,
	Fight_Type_record		= 7,
	Fight_Type_team			= 8,
	Fight_Type_teams		= 9,
    //
	Fight_Type_dragon_npc		= 10,
    Fight_Type_dragon_player	= 11,
}Fight_Type;

@interface FightManager : NSObject{
	
	id target;
	SEL call;
	SEL sele;
	
	Fight_Type type;
	int fightId;
	NSDictionary * resource;
	
	BOOL isPlay;
	BOOL isWin;
	int dieLeftkindCount;
	
	NSDictionary * fightData;
	
	//NSArray*	_targetsdamages;
	NSDictionary* targetDamages;
	NSDictionary* userDamages;
	
	id temp_data;
}

@property(nonatomic,assign) int fightId;
@property(nonatomic,assign) BOOL isWin;
@property(nonatomic,assign) BOOL isPlay;
@property(nonatomic,assign) int dieLeftkindCount;
@property(nonatomic,assign) Fight_Type type;

@property(nonatomic,retain) NSDictionary* targetDamages;
@property(nonatomic,retain) NSDictionary* userDamages;

//@property(nonatomic,retain)NSArray*	targetsdamages;

+(FightManager*)isFighting;
+(FightManager*)shared;
+(void)cleanMemory;
+(BOOL)isWinFight;
+(void)stopAll;
+(void)stopAllByError;
+(int)currentFightId;

+(void)checkEndFight;
+(BOOL)checkCanStartFight;

+(void)removeAllUI;
+(int)getFightType;

-(void)startFightById:(int)fid target:(id)t call:(SEL)c;
-(void)startFightAbyss:(NSDictionary*)data target:(id)t call:(SEL)c;
-(void)startCustomizeFight:(NSDictionary*)data target:(id)_target call:(SEL)_call;//开始自定义战斗

-(void)startFightPlayerByOrder:(int)order target:(id)_target call:(SEL)_call;
-(void)startFightPlayerBySociality:(int)pid target:(id)_target call:(SEL)_call;

-(void)startFightBoss:(NSDictionary*)_data target:(id)_target call:(SEL)_call;
-(void)startFightBoss:(NSDictionary*)_data target:(id)_target call:(SEL)_call sele:(SEL)_sele;

-(void)startFightById:(int)fid team:(int)teamId target:(id)_target call:(SEL)_call sele:(SEL)_sele;

-(void)startFightTeam:(int)selfTeamId byTeam:(int)targetTeamId target:(id)_target call:(SEL)_call sele:(SEL)_sele;

-(void)startFightDragonByNPCId:(int)ancid target:(id)_target call:(SEL)_call;//狩龙战NPC战
-(void)startFightDragonByPlayerId:(int)ancid target:(id)_target call:(SEL)_call;//狩龙战影分身

-(void)seleFightResult:(NSDictionary*)info isUserWin:(BOOL)isUserWin;
-(void)playFightResult;

-(void)playFightRecord:(int)rid target:(id)_target call:(SEL)_call;
-(void)playFightRecord:(int)rid;
-(void)playFight:(NSDictionary*)info;

-(void)endFight;
-(void)checkEndFight;

-(NSString*)getFigthSub;
-(void)fightAgain;

-(int)getTargetDamage:(int)_tid;
-(int)getUserDamage:(int)_tid;

@end
