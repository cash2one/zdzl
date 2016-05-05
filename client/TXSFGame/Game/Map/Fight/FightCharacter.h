//
//  FightCharacter.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-4.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class FightGroup;
@class FightAnimation;
@class ActionMove;

@interface FightCharacter : CCSprite<CCTouchOneByOneDelegate>{
	
	ActionMove * actionMove;
	FightAnimation * animation;
	FightGroup * group;
	
	NSString * name;
	NSString * aniName;
	
	CGPoint barOffset;
	
	int targetId;
	Fight_member_type type;
	
	int suit_id;
	
	int index;
	
	int totalHP;
	int currentHP;
	
	int totalPower;
	int currentPower;
	
	int id_atk;
	int id_skl;
	
	CGSize animationSize;
	
	NSMutableDictionary * allStatus;
	
	CCSprite * bar_hp;
	CCSprite * shadow;
	
	float tScale;
	
	int show_skl_id;
	BOOL isShake;
	
	BOOL isAction;
	NSString * actionData;
	
	int quality;
	
	BOOL isDie;
	
	NSMutableArray *effStatus;
    //fix chao
	CCSprite * characterInfo;
    //end
}
@property(nonatomic,assign) FightGroup * group;
@property(nonatomic,assign) int index;
@property(nonatomic,assign) BOOL isDie;

@property(nonatomic,assign) int totalHP;
@property(nonatomic,assign) int currentHP;
@property(nonatomic,assign) int totalPower;
@property(nonatomic,assign) int currentPower;

-(void)show:(NSString*)info;

-(void)action:(NSString*)data;

-(void)cutHP:(int)cut currentHP:(int)chp isBok:(BOOL)isBok isCpr:(BOOL)isCpr isPen:(BOOL)isPen;
-(void)showPower:(int)power;

-(void)moveTo:(FightCharacter*)target;
-(void)goBack;

-(void)showAttack;
-(void)showSkill;
-(void)showDie;
-(void)showReadySkill;

-(void)addStatus:(int)sid index:(int)sin effect:(NSString*)effect;
-(void)updateStatus:(int)sid index:(int)sin;
-(void)removeStatus:(int)sid index:(int)sin;

-(void)showEffect:(int)eid offset:(int)offset;

-(void)showEffectAdd;
-(void)showEffectBok;
-(void)showEffectCob;
-(void)showEffectCot;
-(void)showEffectCpr;
-(void)showEffectPen;
-(void)showEffectMis;
//fix chao
-(void)showInfo;
-(void)hideInfo;
//end
-(void)updateSpeed;

@end
