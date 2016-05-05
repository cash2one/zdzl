//
//  ActionMove.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-10-31.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "ActionMove.h"
#import "RolePlayer.h"
#import "Monster.h"
#import "AStarPathFinder.h"
#import "MapManager.h"
#import "Game.h"

#define Step_interval 2

@implementation ActionMove

@synthesize isMove;
@synthesize viewer;
@synthesize speed;
@synthesize call;
@synthesize distance;

@synthesize isNotChangeFlipX;

-(id)init{
	if((self=[super init])){
		[self start];
	}
	return self;
}

-(void)start{
	targetPoints = [NSMutableArray array];
	[targetPoints retain];
}

-(void)moveTo:(NSArray*)points{
	
	[self stop];
	
	[targetPoints removeAllObjects];
	[targetPoints addObjectsFromArray:points];
	
	step = 0;
	[self checkPoint];
	
}
-(void)moveEnd{
	isMove = NO;
	distance = 0;
	if(call){
		[viewer performSelector:call];
		call = nil;
	}
}

-(void)checkPoint{
	
	if(!targetPoints){
		[self moveEnd];
		return;
	}
	if([targetPoints count]==0){
		[self moveEnd];
		return;
	}
	startPoint = viewer.position;
	
	@try{
		id t = [targetPoints objectAtIndex:0];
		
		targetPoint = [self getTargetPoint:t];
	}
	@catch (NSException *exception){
		[self moveEnd];
		return;
	}
	
	[targetPoints removeObjectAtIndex:0];
	
	if(!isNotChangeFlipX){
		if(startPoint.x<targetPoint.x){
			viewer.scaleX = 1;
		}else{
			viewer.scaleX = -1;
		}
	}
	
	if([viewer isKindOfClass:[RolePlayer class]]){
		RolePlayer * player = (RolePlayer*)viewer;
		
		RoleDir t_dir = getDirByPoints(startPoint,targetPoint);
		
		if(step==0){
			player.roleDir = t_dir;
		}else{
			
			BOOL isTrun = player.roleDir!=t_dir;
			if(isTrun && [targetPoints count]>0){
				CGPoint np = [self getTargetPoint:[targetPoints objectAtIndex:0]];
				for(int i=1;i<3&&i<[targetPoints count];i++){
					CGPoint ep = [self getTargetPoint:[targetPoints objectAtIndex:i]];
					RoleDir e_dir = getDirByPoints(np,ep);
					if(e_dir!=t_dir){
						isTrun = NO;
						break;
					}
					np = [self getTargetPoint:[targetPoints objectAtIndex:i]];
				}
			}
			
			if(isTrun) player.roleDir = t_dir;
			
		}
		
	}
	
	if([viewer isKindOfClass:[Monster class]]){
		//TODO uodate dir ???
		
	}
	
	aTime = 0;
	fTime = ccpDistance(startPoint, targetPoint)/speed;
	delta = ccpSub(targetPoint, startPoint);
	isMove = YES;
	
	step++;
	
}

-(CGPoint)getTargetPoint:(id)t{
	if([t isKindOfClass:[AStarNode class]]){
		AStarNode * aStarNode = t;
		return [[MapManager shared] getTileToPosition:aStarNode->point];
	}else{
		NSString * pString = [targetPoints objectAtIndex:0];
		return CGPointFromString(pString);
	}
	return ccp(0, 0);
}

-(void)stop{
	isMove = NO;
}

-(void)update:(ccTime)time{
	if(isMove){
		aTime += time;
		float p = aTime/fTime;
		BOOL isEnd = NO;
		if(p<1){
			[viewer setPosition: ccp((startPoint.x+delta.x*p), (startPoint.y+delta.y*p))];
			if(distance>0){
				float dis = ccpDistance(startPoint, viewer.position);
				if(dis>=distance){
					isEnd = YES;
				}
			}
		}else{
			[viewer setPosition: ccp((startPoint.x+delta.x), (startPoint.y+delta.y))];
			isEnd = YES;
		}
		
		if(isEnd){
			[self checkPoint];
		}
	}
}

-(BOOL)isPrepareMoveEnd{
	if (self.isMove &&
		targetPoints != nil &&
		targetPoints.count > 0 &&
		targetPoints.count < Step_interval) {
		return YES ;
	}
	return NO ;
}

-(void)dealloc{
	CCLOG(@"MoveAction dealloc");
	if(targetPoints){
		[targetPoints release];
		targetPoints = nil;
	}
	[super dealloc];
}

@end
