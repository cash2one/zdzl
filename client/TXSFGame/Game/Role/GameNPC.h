//
//  GameNPC.h
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "AnimationNPC.h"

typedef enum {
	
	NPC_DIR_1 = 1,
	NPC_DIR_2 = 2,
	NPC_DIR_3 = 3,
	NPC_DIR_4 = 4,
	
	NPC_DIR_5 = 5,
	NPC_DIR_6 = 6,
	NPC_DIR_7 = 7,
	NPC_DIR_8 = 8,
	
	NPC_DIR_9 = 9,
}NPC_DIR;

@class Task;

@interface GameNPC : CCSprite<CCTouchOneByOneDelegate>{
	
	int npcId;
	int direction;
	NPC_DIR dir;
	
	AnimationNPC * viewer;
	CCSprite * alert;
	CCSprite * shadowSpr;
	
	Task * task;
	BOOL isShowName;
	BOOL isDown;
	BOOL isShadow;
	BOOL isBattle;
	
	BOOL isFighting;	// 是否战斗状态(狩龙npc)
	BOOL isFire;		// 是否开炮状态(狩龙炮塔)
	float fireTotalTime;	// 打炮总时间
	float fireCurtTime;		// 打炮当前时间
	
	CGSize baseSize;
	
	float offset;

	id calltarget;
	SEL call;
	
	BOOL isHasFunc;
	BOOL func_type;
	
	NSString * funcString;
	NSString * msgString;
	
	CCSprite * funcTips;
	
	BOOL bTouchDelay;
	BOOL _isSelected;
	
	int		_winType;
    //
    BOOL isCopyPlayer;
}

@property(nonatomic,assign) BOOL isFighting;
@property(nonatomic,assign) BOOL isFire;
@property(nonatomic,assign) id calltarget;
@property(nonatomic,assign) SEL call;
@property(nonatomic,assign) int npcId;
@property(nonatomic,assign) Task * task;
@property(nonatomic,assign) int direction;
@property(nonatomic,assign) BOOL isHasFunc;
@property(nonatomic,assign) NPC_DIR dir;
@property(nonatomic,assign)BOOL isCopyPlayer;

@property(nonatomic,assign) BOOL isSelected;
@property(nonatomic,assign) CGSize baseSize;

-(CGPoint)getPlayerPoint;
-(void)showAlert;
-(void)hideAlert;

//soul
//添加NPC
//-(void)showEffectWithDictionary:(NSDictionary*)_info target:(id)_target call:(SEL)_call;
-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call offset:(float)_off;

-(void)showBattle;

// 战斗，狩龙战怪物使用
-(void)showFighting;
-(void)removeFighting;

// 打炮，狩龙战炮塔使用
-(void)showFire:(float)percent;
-(void)removeFire;

-(int)getNpcHeight;
//chao
-(void)changeNPCWithDict:(NSDictionary*)dict;
@end

/*
@interface GameNPC_msg : CCSprite{
	
}
-(void)showMessage:(NSString*)msg;
@end
*/


