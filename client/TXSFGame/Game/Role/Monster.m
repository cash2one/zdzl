//
//  Monster.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "Monster.h"
#import "GameLayer.h"
#import "Config.h"
#import "AnimationMonster.h"
#import "MapManager.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "ActionMove.h"
#import "StageManager.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "Window.h"
#import "Game.h"

@implementation Monster

@synthesize monsterId;
@synthesize fightId;
@synthesize index;
@synthesize point;
@synthesize type;

+(Monster*)getMonsterByStageData:(NSArray*)ary{	
	if([ary count]==3){
		Monster * monster = [Monster node];
		monster.monsterId = [[ary objectAtIndex:0] intValue];
		monster.point = CGPointFromString([ary objectAtIndex:1]);
		monster.fightId = [[ary objectAtIndex:2] intValue];
		[[[GameLayer shared] content] addChild:monster];
		
		return monster;
	}
	return nil;
}

+(Monster*)getMonster:(int)_mid point:(CGPoint)_pt{
	Monster * monster = [Monster node];
	monster.monsterId = _mid;
	monster.point = [[MapManager shared] getPositionToTile:_pt];
	monster.fightId = 0 ;
	[[[GameLayer shared] content] addChild:monster];
	return monster;
}

-(void)dealloc{
	[super dealloc];
	
	CCLOG(@"Monster dealloc");
	
}
-(void)setPosition:(CGPoint)position{
	[super setPosition:position];
	if(shadow){
		shadow.position = position;
	}
}

-(void)onEnter{
	
	[super onEnter];
	[self updateZ];
	
	self.anchorPoint = ccp(0.5,0);
	self.position = [[MapManager shared] getTileToPosition:point];
	
	NSDictionary * info = [[GameDB shared] getMonsterInfo:monsterId];
	
	type = [[info objectForKey:@"type"] intValue];
	if(type<=0){
		type = MONSTER_TYPE_MONSTER;
	}
	
	actionMove = [[ActionMove alloc] init];
	actionMove.viewer = self;
	
	viewer = [AnimationMonster node];
	viewer.anchorPoint = ccp(0.5,0);
	viewer.monster_dir = RoleDir_up;
	
	if([Game iPhoneRuningOnGame]){
		actionMove.speed = 125;
		viewer.position = ccp(0,-[[info objectForKey:@"offset"] intValue]/2);
	}else{
		actionMove.speed = 250;
		viewer.position = ccp(0,-[[info objectForKey:@"offset"] intValue]);
	}
	
	//BOSS 和 小怪的类型
	[viewer showAnimationByMonsterId:monsterId type:type];
	
	viewer.scale = getAniScale(monsterId);
	
	[self addChild:viewer z:1];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	
	runTime = 0;
	
	//todo ???转由外面手动开启动作
	//[self startMonsterAction:YES];
	
	int body = [[info objectForKey:@"body"] floatValue];
	if(body<=0) body = 1;
	shadow = [CCSprite spriteWithFile:@"images/shadow.png"];
	shadow.scale = body;
	shadow.position = self.position;
	[self.parent addChild:shadow z:0 tag:555];
	
	CGPoint cp = [[MapManager shared] getTileToPosition:point];
	CGPoint sp = [[MapManager shared] getTileToPosition:[MapManager shared].startPoint];
	
	isFirstCheckX = (abs(cp.x-sp.x)>abs(cp.y-sp.y));
	if(cp.x>sp.x){
		checkTypeX = MOMSTER_CHECK_TYPE_X_M;
	}else{
		checkTypeX = MOMSTER_CHECK_TYPE_X_L;
	}
	if(cp.y>sp.y){
		checkTypeY = MOMSTER_CHECK_TYPE_Y_M;
	}else{
		checkTypeY = MOMSTER_CHECK_TYPE_Y_L;
	}
	
}

-(void)onExit{
	
	CCLOG(@"Monster onExit");
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	if(shadow){
		[shadow removeFromParentAndCleanup:YES];
	}
	if(actionMove){
		[actionMove release];
		actionMove = nil;
	}
	if(viewer){
		[viewer removeFromParentAndCleanup:YES];
		viewer = nil;
	}
	
	[[RoleManager shared].player checkFollowTarget:self];
	
	[super onExit];
}

-(void)restart{
	
	self.position = [[MapManager shared] getTileToPosition:point];
	
	if(actionMove){
		[actionMove release];
	}
	
	actionMove = [[ActionMove alloc] init];
	actionMove.viewer = self;
	if(iPhoneRuningOnGame()){
		actionMove.speed = 125;
	}else{
		actionMove.speed = 250;
	}
	
	runTime = 0;
	[self startMonsterAction:YES];
	
}

-(void)startMonsterAction:(BOOL)isStop{
	[self unschedule:@selector(checkTimer:)];
	[self unschedule:@selector(startCheckTimer)];
	if(isStop){
		[self scheduleOnce:@selector(startCheckTimer) delay:1.08f];
	}
}

-(void)startCheckTimer{
	[self schedule:@selector(checkTimer:) interval:1/30.0f];
}

-(void)checkTimer:(ccTime)time{
	
	[self updateZ];
	
	if ([[Window shared] isHasWindow]) {
		//CCLOG(@"Monster checkTimer back!! Window is hasWindow");
		runTime = 0 ;
		return ;
	}
	
	if ([Game shared].isTurnning) {
		//CCLOG(@"Monster checkTimer back!! [Game shared].isTurnning");
		return ;
	}
	
	[actionMove update:time];
	
	BOOL isCheck = NO;
	runTime+=time;
	if(runTime>1.0f){
		runTime = 0;
		
		isCheck = YES;
		
	}
	
	if(type==MONSTER_TYPE_MONSTER){
		if(!isFollow){
			
			/*
			float distance = ccpDistance(self.position, [RoleManager shared].player.position);
			if(distance<100){
				isFollow = YES;
				[self fight];
				return;
			}
			*/
			
			CGPoint cp = [[MapManager shared] getTileToPosition:point];
			CGPoint pp = [RoleManager shared].player.position;
			
			if(isFirstCheckX){
				if(checkTypeX==MOMSTER_CHECK_TYPE_X_M && pp.x>=cp.x){
					isFollow = YES;
				}
				if(checkTypeX==MOMSTER_CHECK_TYPE_X_L && pp.x<=cp.x){
					isFollow = YES;
				}
				if(checkTypeY==MOMSTER_CHECK_TYPE_Y_M && pp.y>=cp.y){
					isFollow = YES;
				}
				if(checkTypeY==MOMSTER_CHECK_TYPE_Y_L && pp.y<=cp.y){
					isFollow = YES;
				}
			}else{
				if(checkTypeY==MOMSTER_CHECK_TYPE_Y_M && pp.y>=cp.y){
					isFollow = YES;
				}
				if(checkTypeY==MOMSTER_CHECK_TYPE_Y_L && pp.y<=cp.y){
					isFollow = YES;
				}
				if(checkTypeX==MOMSTER_CHECK_TYPE_X_M && pp.x>=cp.x){
					isFollow = YES;
				}
				if(checkTypeX==MOMSTER_CHECK_TYPE_X_L && pp.x<=cp.x){
					isFollow = YES;
				}
			}
			
			if(isFollow){
				float distance = ccpDistance(self.position, [RoleManager shared].player.position);
				if(iPhoneRuningOnGame()){
					if(distance>100){
						isFollow = NO;
					}
				}else{
					if(distance>200){
						isFollow = NO;
					}
				}
			}
			
			if(isFollow){
				
				[Game shared].isCanBackToMap = NO;
				
				CCLOG(@"\n\n======Monster follow player======\n\n");
				
				[RoleManager shared].player.followTarget = nil;
				[[RoleManager shared] stopMovePlayer];
				
				
				CGPoint p = [RoleManager shared].player.position;
				
				if(p.y>self.position.y){
					viewer.monster_dir = RoleDir_up;
				}else{
					viewer.monster_dir = RoleDir_down;
				}
				
				if(iPhoneRuningOnGame()){
					actionMove.speed = 250;
				}else{
					actionMove.speed = 500;
				}
				
				actionMove.call = @selector(fight);
				
				[actionMove moveTo:[NSArray arrayWithObject:NSStringFromCGPoint(p)]];
				
				return;
			}
			
		}else{
			
			float distance = ccpDistance(self.position, [RoleManager shared].player.position);
			
			float td = 500;
			if(iPhoneRuningOnGame()){
				td /= 2;
			}
			
			if(distance<td){
				if(actionMove.call){
					[actionMove moveEnd];
				}
				return;
			}
			
			return;
		}
		
	}
	
	if(type==MONSTER_TYPE_BOSS){
		float distance = ccpDistance(self.position, [RoleManager shared].player.position);
		float td = 150;
		if(iPhoneRuningOnGame()){
			td /= 2;
		}
		if(distance<td){
			
			CCLOG(@"fight boss...");
			
			[RoleManager shared].player.followTarget = nil;
			[[RoleManager shared] stopMovePlayer];
			[self fight];
			
			return;
		}
	}
	
	if(!actionMove.isMove && isCheck && type==MONSTER_TYPE_MONSTER){
		
		int t_x = getRandomInt(point.x-5, point.x+5);
		int t_y = getRandomInt(point.y-5, point.y+5);
		CGPoint p = ccp(t_x,t_y);
		
		if([[MapManager shared] tiledPointIsOpen:p]){
			p = [[MapManager shared] getTileToPosition:p];
			
			if(p.y>self.position.y){
				viewer.monster_dir = RoleDir_up;
			}else{
				viewer.monster_dir = RoleDir_down;
			}
			
			if(iPhoneRuningOnGame()){
				actionMove.speed = 75;
			}else{
				actionMove.speed = 150;
			}
			
			[actionMove moveTo:[NSArray arrayWithObject:NSStringFromCGPoint(p)]];
			
		}
		
	}
	
}

-(void)updateZ{
	if(self.parent){
		int zz = (GAME_MAP_MAX_Y-self.position.y);
		[self.parent reorderChild:self z:zz];
	}
}

-(void)fight{
	
	CCLOG(@"Monster start fight 1:---%d",self.monsterId);
	[self startMonsterAction:NO];
	
	//[self doFight];
	//[self scheduleOnce:@selector(doFight) delay:0.05f];
	
	[NSTimer scheduledTimerWithTimeInterval:0.05f 
									 target:self
								   selector:@selector(doFight) 
								   userInfo:nil
									repeats:NO];
	
}

-(void)doFight{
	CCLOG(@"Monster start fight 2:---%d",self.monsterId);
	[[StageManager shared] startFight:fightId];
	
}

//==============================================================================

-(BOOL)isTouchInSite:(UITouch*)touch{
	
	if(![GameLayer shared].touchEnabled) return NO;
	
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	CGSize size = viewer.contentSize;
	size.height = size.height - viewer.position.y;
	
	if(p.x<-size.width/2) return NO;
	if(p.x>size.width/2) return NO;
	if(p.y<0) return NO;
	if(p.y>size.height) return NO;
	return YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return [self isTouchInSite:touch];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if([self isTouchInSite:touch]){
		[[RoleManager shared] movePlayerTo:self.position
									target:nil 
									  call:nil
		 ];
	}
}
//==============================================================================

@end
