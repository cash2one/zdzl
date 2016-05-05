//
//  Game.m
//  TXSFGame
//
//  Created by chao chen on 12-10-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "Game.h"
#import "RoleManager.h"
#import "MapManager.h"

#import "GameLayer.h"
#import "RolePlayer.h"
#import "NPCManager.h"
#import "GameUI.h"
#import "ActionMove.h"
#import "NPCManager.h"
#import "GameUI.h"
#import "StageManager.h"
#import "TaskManager.h"
#import "AbyssManager.h"
#import "ClickAnimation.h"
#import "GameConnection.h"
#import "GameSoundManager.h"
#import "RoleOption.h"

@implementation GameLayer

static GameLayer *s_GameLayer=nil;

@synthesize content;
@synthesize isAction;

+(GameLayer*)shared{
    if (nil == s_GameLayer){
        s_GameLayer = [GameLayer node] ;
    }
    return s_GameLayer;

}
+(void)stopAll{
	
	if(s_GameLayer!=nil){
		
		[s_GameLayer removeMap];
		
		[MapManager stopAll];
		[RoleManager stopAll];
		[NPCManager stopAll];
		
		[s_GameLayer removeAllChildrenWithCleanup:YES];
		[s_GameLayer removeFromParentAndCleanup:YES];
		s_GameLayer = nil;
		
	}
}

+(BOOL)isShowing{
	if(s_GameLayer){
		return YES;
	}
	return NO;
}

-(void)dealloc{
	
	[super dealloc];
	CCLOG(@"GameLayer dealloc");
	
}

/*
 -(void)registerWithTouchDispatcher{
 [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
 }
 */

-(void)setTouchEnabled:(BOOL)touchEnabled{
	selfIsCanTouch = touchEnabled;
	if(touchEnabled){
		checkOpenTouchTime = 0.0f;
	}else{
		checkOpenTouchTime = INT16_MAX;
		[super setTouchEnabled:NO];
	}
}

-(BOOL)isTouchEnabled{
	return selfIsCanTouch;
}

-(void)onEnter{
	
	self.touchEnabled = YES;
	self.touchMode = kCCTouchesAllAtOnce;
	self.touchPriority = 0;
	
	[super onEnter];
	
	content = [CCLayer node];
	[self addChild:content];
	
	//[content addChild:[MapManager shared] z:-1];
	
    //
    [GameConnection addPost:ConnPost_response_error target:self call:@selector(showResponseError:)];
}
-(void)onExit{
	
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	
	if(content){
		//[content removeFromParentAndCleanup:YES];
		content = nil;
	}
	s_GameLayer = nil;
    //
	[GameConnection removePostTarget:self];
    //
	[super onExit];
}

-(void)showResponseError:(id)sender{
    if (!checkResponseStatus(sender)) {
		CCLOG(@"----数据错误!");
        [ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(void)showMap{
	
    if ([MapManager shared].parent != NULL) {
        CCLOG(@"<<<<<<map is add>>>>>>>>");
        return ;
    }
	[content addChild:[MapManager shared] z:-1];
	[[MapManager shared] loadMap];
	[[RoleManager shared] loadPlayer];
	[self updatePlayerView];
	[[MapManager shared] checkMapPoint:content.position];
	[self schedule:@selector(checkTimer:) interval:1/60.0f];
	
	[GameConnection post:ConnPost_loadMapInit object:nil];
	//[GameConnection post:ConnPost_loadMapOver object:nil];
	
	//CCLOG(@" content :%f %f",[[GameLayer shared] content].contentSize.width,[[GameLayer shared] content].contentSize.height);
	//CCLOG(@" map: %f %f",[MapManager shared].size.width,[MapManager shared].size.height);
	
	[[GameSoundManager shared] playBackgroundMusic];
}

-(void)removeMap{
	
	[self unschedule:@selector(checkTimer:)];
	
	[[MapManager shared] removeMap];
	[[RoleManager shared] clearAllPlayer];
	[[NPCManager shared] clearAllNPC];
	[[StageManager shared] cleanStageMapData];
	
	[content removeAllChildren];
	
	[[GameSoundManager shared] pauseBackgroundMusic];
	[[CCDirector sharedDirector] purgeCachedData];
	
}

-(void)checkTimer:(ccTime)time{
	
	//check open touch
	if(checkOpenTouchTime<1.38f){
		checkOpenTouchTime+=time;
	}else{
		if(selfIsCanTouch && checkOpenTouchTime<INT16_MAX){
			checkOpenTouchTime = INT16_MAX;
			[super setTouchEnabled:YES];
		}
	}
	
	//self.position = ccpAdd(self.position, ccp(1, 0));
	[self updateFocus];
	
}

-(void)updateFocus{
	
	if([RoleManager shared].player.actionMove.isMove || isAction){
		[self updatePlayerView];
	}
	
}
-(void)updatePlayerView{
	
	if(![RoleManager shared].player.parent) return;
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CGPoint mapPos = content.position;
	
	CGPoint point = [RoleManager shared].player.position;
	
	float tx = point.x-abs(mapPos.x);
	float ty = point.y-abs(mapPos.y);
	
	int tmp_x = winSize.width;
	int tmp_y = winSize.height;
	
	CGPoint min = ccp(tmp_x/2,tmp_y/2);
	CGPoint max = ccp(tmp_x/2,tmp_y/2);
	
	BOOL isMovePoint = NO;
	
	if(tx<min.x || tx>max.x) isMovePoint = YES;
	if(ty<min.y || ty>max.y) isMovePoint = YES;
	
	if(isMovePoint){
		
		CGPoint newPos = content.position;
		
		if(tx<min.x) newPos.x += min.x-tx;
		if(tx>max.x) newPos.x -= tx-max.x;
		if(ty<min.y) newPos.y += min.y-ty;
		if(ty>max.y) newPos.y -= ty-max.y;
		
		newPos.x = (newPos.x>0?0:newPos.x);
		newPos.y = (newPos.y>0?0:newPos.y);
		
		//CGSize mapSize = [[MapManager shared] maxSize];
		CGSize mapSize = [[MapManager shared] size];
		CGPoint minPoint = ccp(winSize.width-mapSize.width,winSize.height-mapSize.height);
		newPos.x = (newPos.x<minPoint.x?minPoint.x:newPos.x);
		newPos.y = (newPos.y<minPoint.y?minPoint.y:newPos.y);
		
		if(winSize.width>mapSize.width){
			newPos.x = (winSize.width-mapSize.width)/2;
		}
		if(winSize.height>mapSize.height){
			newPos.y = (winSize.height-mapSize.height)/2;
		}
		
		content.position = newPos;
		
		[[MapManager shared] checkMapPoint:newPos];
		
	}
}
-(CGPoint)getContentPoint{
	return content?content.position:ccp(0, 0);
}
-(CGPoint)getPlayerViewPosition{
	CGPoint pt1 = [RoleManager shared].player.position;
	CGPoint pt2 = [self getContentPoint];
	CGPoint pt3 = ccpAdd(pt1, pt2);
	return pt3;
}
-(CGPoint)getPlayerViewPosition:(CGPoint)pt{
	CGPoint pt2 = [self getContentPoint];
	CGPoint pt3 = ccpAdd(pt, pt2);
	return pt3;
}

////响应键盘
-(BOOL)ccTouchBegan:(UITouch*)touch withEvent:(UIEvent*)event{
	
	//check player can run on map for isPlayerOnChapter
	//soul test colse
	if([[GameConfigure shared] isPlayerOnChapter]) return NO;
	
	BOOL isTouch = [[RoleManager shared].player isCanRun];
    return isTouch;
}

-(void)ccTouchEnded:(UITouch*)touch withEvent:(UIEvent*)event{
	
	CGPoint touchLocation = [touch locationInView:[touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [content convertToNodeSpace:touchLocation];
	touchLocation = ccp((int)touchLocation.x,(int)touchLocation.y);
	
	[ClickAnimation show:touchLocation];
	
	//check can run role to target point
	if([[GameConfigure shared] isPlayerOnChapter]) return;
	if(![[RoleManager shared].player isCanRun]) return;
	
	[RoleManager shared].player.targetPoint = ccp(0,0);
	[[RoleManager shared] movePlayerTo:touchLocation];
	
	//[[RoleManager shared].player updateDir:touchLocation];
	[[LowerLeftChat share]EventOpenChat:nil];
	
	[[RoleOption shared] binding:Nil];
	
	
	
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	touch_distance=0;
	isMultiTouch=NO;
	end_touch_distance=0;
	touchCount=0;
	[self ccTouchEnded:[touches anyObject] withEvent:event];
}
-(void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	touch_distance = 0;
}

-(void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	
	if([touches count]>=2){
		isMultiTouch=YES;
		touchCount = [touches count];
		if(touch_distance==0){
			touch_distance = getDistanceByTouchs(touches);
		}
		end_touch_distance=getDistanceByTouchs(touches);
	}
	
}
-(void)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
	
	if(isMultiTouch){
		touchCount -= [touches count];
		if(touchCount<=0 && abs(touch_distance-end_touch_distance)>cFixedScale(100)){
			if(touch_distance<end_touch_distance){
				[[GameUI shared] closeUI];
				//[[GameUI shared] closeOtherUI];
			}else{
				[[GameUI shared] openUI];
				//[[GameUI shared] openOtherUI];
			}
			isMultiTouch=NO;
			return;
		}
		return;
	}
	
	if([touches count]==1){
		[self ccTouchEnded:[touches anyObject] withEvent:event];
	}
	
	isMultiTouch=NO;
	touch_distance=0;
	end_touch_distance = 0;
	touchCount = 0;
	
}

@end
