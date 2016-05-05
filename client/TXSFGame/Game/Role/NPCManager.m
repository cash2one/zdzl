//
//  NPCManager.m
//  TXSFGame
//
//  Created by chao chen on 12-10-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "NPCManager.h"
#import "GameNPC.h"
#import "GameLayer.h"
#import "MapManager.h"
#import "RolePlayer.h"

NPCManager *s_NPCManager;

@implementation NPCManager

+(NPCManager*)shared{
	if(!s_NPCManager){
		s_NPCManager = [[NPCManager alloc] init];		
	}
	return s_NPCManager;
}
+(void)stopAll{
	if(s_NPCManager){
		[s_NPCManager release];
		s_NPCManager = nil;
	}
}

-(id)init{
	if ( (self = [super init]) ){		
		npcs = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc{
	[npcs release];
	npcs = nil;
	[super dealloc];
	CCLOG(@"NPCManager dealloc");
}

-(void)clearAllNPC{
	
	for(GameNPC * npc in npcs){
		[npc removeFromParentAndCleanup:YES];
	}
	[npcs removeAllObjects];
	
}

-(NSArray*)getAllNPC
{
	return npcs;
}

//==============================================================================

-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction{
	
	GameNPC * npc = [GameNPC node];
	npc.npcId = npcId;
	npc.position = [[MapManager shared] getTileToPosition:pos];
	npc.direction = direction;
	[[[GameLayer shared] content] addChild:npc];
	
	[npcs addObject:npc];
}
//chao
-(void)addNPCByPlayerDict:(NSDictionary*)playerDict tilePoint:(CGPoint)pos direction:(int)direction{
    if (playerDict) {
        NSDictionary *npcDict = [[GameDB shared] getAwarNpcConfig:[[playerDict objectForKey:@"ancid"] intValue]];
        if (npcDict) {
            int npcId = [[npcDict objectForKey:@"mnpcid"] intValue];
            GameNPC * npc = [GameNPC node];
            npc.npcId = npcId;
            npc.position = [[MapManager shared] getTileToPosition:pos];
            npc.direction = direction;
            npc.isCopyPlayer = YES;
            
            [[[GameLayer shared] content] addChild:npc];
            
            [npcs addObject:npc];
            //
            [npc changeNPCWithDict:playerDict];
        }else{
            CCLOG(@"-------get npc dict error.....");
        }
    }  
}
//chao
-(void)addNPCByPlayerDict:(NSDictionary*)playerDict tilePoint:(CGPoint)pos direction:(int)direction target:(id)tar select:(SEL)sel tag:(int)tag{
    if (playerDict) {
        NSDictionary *npcDict = [[GameDB shared] getAwarNpcConfig:[[playerDict objectForKey:@"ancid"] intValue]];
        if (npcDict) {
            int npcId = [[npcDict objectForKey:@"mnpcid"] intValue];
            GameNPC * npc = [GameNPC node];
            npc.npcId = npcId;
            npc.position = [[MapManager shared] getTileToPosition:pos];
            npc.direction = direction;
            npc.isCopyPlayer = YES;
            
            [[[GameLayer shared] content] addChild:npc];
            
            [npcs addObject:npc];
            //
            [npc changeNPCWithDict:playerDict];
            npc.tag=tag;
            npc.call=sel;
            npc.calltarget=tar;
        }else{
            CCLOG(@"-------get npc dict error.....");
        }
    }
}

-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction with:(id)_useObj
{
	GameNPC * npc = [GameNPC node];
	
	npc.npcId = npcId;
	npc.position = [[MapManager shared] getTileToPosition:pos];
	npc.direction = direction;
	[npc setUserObject:_useObj];
	
	[[[GameLayer shared] content] addChild:npc];
	
	[npcs addObject:npc];
}

-(void)addNPCById:(int)npcId tilePoint:(CGPoint)pos direction:(int)direction target:(id)tar select:(SEL)sel tag:(int)tag{
	GameNPC * npc = [GameNPC node];
	npc.tag=tag;
	npc.npcId = npcId;
	npc.direction = direction;
	npc.position= [[MapManager shared] getTileToPosition:pos];
	[[[GameLayer shared] content] addChild:npc];
	npc.call=sel;
	npc.calltarget=tar;
	[npcs addObject:npc];
}

-(GameNPC*)getNPCById:(int)npcId{
	GameNPC * target = nil;
	for(GameNPC * npc in npcs){
		if(npc.npcId==npcId){
			target = npc;
		}
	}
	return target;
}
-(void)removeNPCById:(int)npcId{
	GameNPC * target = [self getNPCById:npcId];
	if(target){
		[target removeFromParentAndCleanup:YES];
		[npcs removeObject:target];
	}
}

-(GameNPC*)getNPCByTag:(int)tag
{
	GameNPC * target = nil;
	for(GameNPC * npc in npcs){
		if(npc.tag==tag){
			target = npc;
		}
	}
	return target;
}

-(void)removeNPCByTag:(int)tag
{
	GameNPC * target = [self getNPCByTag:tag];
	if(target){
		[target removeFromParentAndCleanup:YES];
		[npcs removeObject:target];
	}
}

-(GameNPC*)getNPCByUserObject:(id)_userObj
{
	GameNPC * target = nil;
	for(GameNPC * npc in npcs){
		if([npc.userObject isEqual:_userObj]){
			target = npc;
		}
	}
	return target;
}

-(CGPoint)getNPCPointById:(int)npcId{
	for(GameNPC * npc in npcs){
		if(npc.npcId==npcId){
			return [npc getPlayerPoint];
		}
	}
	return ccp(0,0);
}

-(void)showNPC:(int)npcId showTips:(BOOL)isShowTips{
	for(GameNPC * npc in npcs){
		if(npc.npcId==npcId){
			if(isShowTips){
				[npc showAlert];
			}else{
				[npc hideAlert];
			}
		}
	}
}
-(void)hideAllTips{
	for(GameNPC * npc in npcs){
		[npc hideAlert];
	}
}

-(void)bondTask:(Task*)task toNpc:(int)npcId{
	for(GameNPC * npc in npcs){
		if(npc.npcId==npcId){
			npc.task = task;
		}
	}
}
-(void)unbondTask:(Task*)task{
	for(GameNPC * npc in npcs){
		if(npc.task==task){
			npc.task = nil;
		}
	}
}

-(void)checkStageNpcByTask:(Task *)task{
	for(GameNPC * npc in npcs){
		if(npc.task != task){
			npc.visible = NO ;
		}
	}
}

-(void)unSelectNPC{
	for(GameNPC * npc in npcs){
		npc.isSelected = NO;
	}
}

@end
