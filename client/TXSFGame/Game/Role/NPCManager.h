//
//  NPCManager.h
//  TXSFGame
//
//  Created by chao chen on 12-10-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

typedef enum {
	NPC_FUNC_MAP		= 1, 
	NPC_FUNC_OPEN_WIN	= 2,
	NPC_FUNC_STAGE		= 3,
	NPC_FUNC_FIGHT		= 4,
	NPC_FUNC_FOOT		= 5,
	NPC_FUNC_BLOCK		= 6,
	NPC_FUNC_TURRET		= 7,
}NPC_FUNC;

@class Task;
@class GameNPC;

@interface NPCManager : NSObject{
	NSMutableArray * npcs;
}

+(NPCManager*)shared;
+(void)stopAll;

-(void)clearAllNPC;

-(NSArray*)getAllNPC;

//TODO
//chao
-(void)addNPCByPlayerDict:(NSDictionary*)playerDict tilePoint:(CGPoint)pos direction:(int)direction;
-(void)addNPCByPlayerDict:(NSDictionary*)playerDict tilePoint:(CGPoint)pos direction:(int)direction target:(id)tar select:(SEL)sel tag:(int)tag;
//

-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction;
-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction with:(id)_useObj;


-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction target:(id)tar select:(SEL)sel tag:(int)tag;
-(GameNPC*)getNPCById:(int)npcId;
-(void)removeNPCById:(int)npcId;

-(GameNPC*)getNPCByTag:(int)tag;
-(void)removeNPCByTag:(int)tag;

-(GameNPC*)getNPCByUserObject:(id)_userObj;

-(CGPoint)getNPCPointById:(int)npcId;

-(void)showNPC:(int)npcId showTips:(BOOL)isShowTips;
-(void)hideAllTips;

-(void)bondTask:(Task*)task toNpc:(int)npcId;
-(void)unbondTask:(Task*)task;

-(void)checkStageNpcByTask:(Task*)task;

-(void)unSelectNPC;

@end
