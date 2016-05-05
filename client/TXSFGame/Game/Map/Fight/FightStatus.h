//
//  FightStatus.h
//  TXSFGame
//
//  Created by TigerLeung on 12-11-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@class FightMember;

@interface FightStatus : NSObject{
	
	int statusId;
	int statusIndex;
	
	BOOL isActive;
	
	FightMember * member;
	
	Fight_Status_Type type;
	Fight_Action_Type action;
	
	int count;
	
	float ahp;
	float bhp;
	
	BOOL isNoAtk;
	BOOL isNoMis;
	BOOL isNoBok;
	BOOL isNoCot;
	
	float t_hp;
	float t_mp;
	float hp_p;
	float mp_p;
	
	BaseAttribute attribute;
	
	int parentCutHP;
	
	NSString * effect;
	
}
@property(nonatomic,assign) int statusId;
@property(nonatomic,assign) int statusIndex;
@property(nonatomic,assign) BOOL isActive;
@property(nonatomic,assign) FightMember * member;
@property(nonatomic,assign) int parentCutHP;
@property(nonatomic,assign) BaseAttribute attribute;

@property(nonatomic,assign) int count;
@property(nonatomic,assign) BOOL isNoAtk;
@property(nonatomic,assign) BOOL isNoMis;
@property(nonatomic,assign) BOOL isNoBok;
@property(nonatomic,assign) BOOL isNoCot;

@property(nonatomic,assign) float add_hurt_hp_percent;//伤害加成
@property(nonatomic,assign) float cut_hurt_hp_percent;//伤害减免

@property(nonatomic,assign) NSString * effect;

+(void)member:(FightMember*)member addStatus:(int)sid to:(FightMember*)main other:(NSArray*)targets cut:(int)cut hit:(BOOL)hit;

+(FightStatus*)getStatusbyInfo:(NSDictionary*)info member:(FightMember*)member cut:(int)cut;

-(void)checkStatusType:(Fight_Action_Type)at;
-(void)checkStatusByAttackBefore;
-(void)checkStatusByAttackAfter;

@end
