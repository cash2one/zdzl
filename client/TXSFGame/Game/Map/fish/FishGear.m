//
//  FishGear.m
//  TXSFGame
//
//  Created by efun on 13-2-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "FishGear.h"
#import "Config.h"
#import "MapManager.h"
#import "GameLayer.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "GameEffects.h"

#define Fish_Gear_normal	100

@implementation FishGearViewer

@synthesize fishTarget;
@synthesize fishCall;

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *normal = [CCSprite spriteWithFile:@"images/animations/uiflsh/start/0.png"];
	normal.anchorPoint = ccp(0.5, 0.186);
	normal.tag = Fish_Gear_normal;
	[self addChild:normal];
	
	self.anchorPoint = ccp(0.5, 0.186);
	int z = (GAME_MAP_MAX_Y-self.position.y);
	[self.parent reorderChild:self z:z];
}

-(void)run:(NSArray *)frames
{
	CCNode *node = [self getChildByTag:Fish_Gear_normal];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	id action = [CCCallFunc actionWithTarget:self selector:@selector(callback)];
	[self playAnimation:frames delay:0.1f call:action];
}

-(void)runForever:(NSArray *)frames
{
	[self playAnimation:frames delay:0.1f];
}

-(void)callback
{
	[GameEffectsBlockTouck unlockScreen];
	
	if (fishTarget != nil && fishCall != nil) {
		if ([fishTarget respondsToSelector:fishCall]) {
			[fishTarget performSelector:fishCall];
		}
	}
}

@end

@implementation FishGear

@synthesize target;
@synthesize call;
@synthesize points;

-(id)init
{
	if (self = [super init]) {
		loopFrames = [AnimationViewer loadFileByFileFullPath:@"images/animations/uiflsh/loop/" name:@"%d.png"];
		[loopFrames retain];
		
		gearFrames = [AnimationViewer loadFileByFileFullPath:@"images/animations/uiflsh/start/" name:@"%d.png"];
		[gearFrames retain];
		
		reverseGearFrames = [NSMutableArray array];
		NSEnumerator *enumerator = [gearFrames reverseObjectEnumerator];
		for (id element in enumerator) {
			[reverseGearFrames addObject:element];
		}
		[reverseGearFrames retain];
		
		fishGears = [NSMutableArray array];
		[fishGears retain];
	}
	return self;
}

-(void)setPoints:(NSMutableArray *)_points
{
	points = _points;
	
	for (NSValue *value in _points) {
		FishGearViewer *item = [FishGearViewer node];
		item.fishTarget = self;
		item.fishCall = @selector(fishCallback);
		item.position = getTiledRectCenterPoint([value CGRectValue]);
		[[GameLayer shared].content addChild:item];
		[fishGears addObject:item];
	}
}

-(void)showStart:(int)index
{
	[GameEffectsBlockTouck lockScreen];
	[self show:index start:YES];
}

-(void)showStop:(int)index
{
	[GameEffectsBlockTouck lockScreen];
	[self show:index start:NO];
}

-(void)show:(int)index start:(BOOL)start
{
	fishStart = start;
	if (points) {
		if (index >= points.count) {
			index = 0;
		}
		NSValue *value = [points objectAtIndex:index];
		CGPoint point = getTiledRectCenterPoint([value CGRectValue]);
		
		for (int i = 0; i < fishGears.count; i++) {
			FishGearViewer *item = [fishGears objectAtIndex:i];
			if (item && CGPointEqualToPoint(item.position, point)) {
				
				currentViewer = item;
				if (start) {
					[currentViewer run:gearFrames];
				} else {
					[currentViewer run:reverseGearFrames];
				}
			}
		}
	}
}

-(void)fishCallback
{
	if (fishStart && currentViewer) {
		[currentViewer runForever:loopFrames];
	}
	
	if (target != nil && call != nil) {
		if ([target respondsToSelector:call]) {
			[target performSelector:call];
		}
	}
	call = nil;
}

-(void)removeAll
{
	if (fishGears) {
		for (int i = 0; i < fishGears.count; i++) {
			
			CCNode *node = [fishGears objectAtIndex:i];
			if (node) {
				[node removeFromParentAndCleanup:YES];
				node = nil ;
			}
			
		}

		[fishGears release];
		fishGears = nil;
	}
	if (loopFrames) {
		[loopFrames release];
		loopFrames = nil;
	}
	if (gearFrames) {
		[gearFrames release];
		gearFrames = nil;
	}
	if (reverseGearFrames) {
		[reverseGearFrames release];
		reverseGearFrames = nil;
	}
}

@end