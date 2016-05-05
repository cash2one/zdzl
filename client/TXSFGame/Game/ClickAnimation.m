//
//  ClickAnimation.m
//  TXSFGame
//
//  Created by chao chen on 13-1-11.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ClickAnimation.h"
#import "GameLayer.h"
#define CLICK_MOVE_TIME (1.0f)
@implementation ClickAnimation
@synthesize looped;
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint sprite:(CCSprite*)spr loop:(BOOL)isLoop{
	CCSprite *t_spr = nil;
	if (content) {
		t_spr = [ClickAnimation getSpriteWithSprite:spr call:call point:_point moveTo:_toPoint loop:isLoop];
		if (spr) {
			[content addChild:spr z:z];
		}else{
			CCLOG(@"error:Sprite is nil");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return t_spr;
}
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint sprite:(CCSprite*)spr loop:(BOOL)isLoop{
	CCSprite *t_spr = nil;
	if (content) {
		t_spr = [ClickAnimation getSpriteWithSprite:spr call:call point:_point moveTo:_toPoint loop:isLoop];
		if (spr) {
			[content addChild:spr z:z tag:tag];
		}else{
			CCLOG(@"error:Sprite is nil");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return t_spr;
}
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint path:(NSString*)path loop:(BOOL)isLoop{
	CCSprite *spr = nil;
	if (content) {
		spr = [ClickAnimation getSpriteWithCall:call point:_point moveTo:_toPoint path:path loop:isLoop];
		if (spr) {
			[content addChild:spr z:z];
		}else{
			CCLOG(@"error:Sprite is nil");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return spr;
}
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint path:(NSString*)path loop:(BOOL)isLoop{
	CCSprite *spr = nil;		
	if (content) {
		spr = [ClickAnimation getSpriteWithCall:call point:_point moveTo:_toPoint path:path loop:isLoop];
		if (spr) {
			[content addChild:spr z:z tag:tag];
		}else{
			CCLOG(@"error:Sprite is nil");
		}		
	}else{
		CCLOG(@"error:content is nil");
	}
	return spr;
}

+(id)getSpriteWithSprite:(CCSprite *)spr call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint loop:(BOOL)isLoop{
	if (spr) {
		id ac = nil;
		id stop = [CCDelayTime actionWithDuration:1.0f];
		if (isLoop) {			
			id move1 = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_point];
			id move2 = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_toPoint];
			if (call) {
				ac = [CCRepeatForever actionWithAction:[CCSequence actions:stop,move1,move2,call,nil]];
			}else{
				ac = [CCRepeatForever actionWithAction:[CCSequence actions:stop,move1,move2,nil]];
			}
		}else{			
			id fade = [CCFadeOut actionWithDuration:CLICK_MOVE_TIME*2];
			id removeSelfBackCall = [CCCallFuncN actionWithTarget:[ClickAnimation class] selector:@selector(removeSprBackCall:)];
			id move = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_toPoint];
			ac =  [CCSpawn actions:move,fade,nil];
			if (call) {
				ac = [CCSequence actions:stop,ac,call,removeSelfBackCall,nil];
			}else{
				ac = [CCSequence actions:stop,ac,removeSelfBackCall,nil];
			}
		}
		spr.position = _point;
		[spr runAction:ac];
	}
	return spr;
}

+(id)getSpriteWithCall:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint path:(NSString*)path loop:(BOOL)isLoop{
	CCSprite *spr = nil;
	spr = [CCSprite spriteWithFile:path];
	if (spr) {
		id ac = nil;
		id stop = [CCDelayTime actionWithDuration:1.0f];
		if (isLoop) {
			id move1 = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_point];
			id move2 = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_toPoint];
			if (call) {
				ac = [CCRepeatForever actionWithAction:[CCSequence actions:stop,move1,move2,call,nil]];
			}else{
				ac = [CCRepeatForever actionWithAction:[CCSequence actions:stop,move1,move2,nil]];
			}
		}else{
			id fade = [CCFadeOut actionWithDuration:CLICK_MOVE_TIME*2];
			id removeSelfBackCall = [CCCallFuncN actionWithTarget:[ClickAnimation class] selector:@selector(removeSprBackCall:)];
			id move = [CCMoveTo actionWithDuration:CLICK_MOVE_TIME position:_toPoint];
			ac =  [CCSpawn actions:move,fade,nil];
			if (call) {
				ac = [CCSequence actions:stop,ac,call,removeSelfBackCall,nil];
			}else{
				ac = [CCSequence actions:stop,ac,removeSelfBackCall,nil];
			}
		}
		spr.position = _point;
		[spr runAction:ac];
	}
	return spr;	
}
+(id)showInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point scaleX:(float)scale_x  scaleY:(float)scale_y path:(NSString*)path loop:(BOOL)isLoop{
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	ClickAnimation *clickAnimation = nil;
	if (content) {
		if (frames) {
			clickAnimation = [ClickAnimation node];
            clickAnimation.scaleX = scale_x;
            clickAnimation.scaleY = scale_y;
			[clickAnimation setLooped:isLoop];
			if (isLoop) {
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}else{
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}
			[content addChild:clickAnimation z:z];
			clickAnimation.position = _point;
			clickAnimation.tag = tag;
		}else{
			CCLOG(@"error:frames is error");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return clickAnimation;
}
+(id)showInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop{
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	ClickAnimation *clickAnimation = nil;
	if (content) {
		if (frames) {
			clickAnimation = [ClickAnimation node];
			[clickAnimation setLooped:isLoop];
			if (isLoop) {
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}else{
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}
			[content addChild:clickAnimation z:z];
			clickAnimation.position = _point;
			clickAnimation.tag = tag;
		}else{
			CCLOG(@"error:frames is error");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return clickAnimation;
}
+(id)showInLayer:(CCNode*)content tag:(NSInteger)tag call:(id)call point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop{
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	ClickAnimation *clickAnimation = nil;
	if (content) {
		if (frames) {
			clickAnimation = [ClickAnimation node];
			[clickAnimation setLooped:isLoop];
			if (isLoop) {				
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}else{
				[clickAnimation playAnimation:frames delay:1/8.0f call:call];
			}
			[content addChild:clickAnimation z:999];
			clickAnimation.position = _point;
			clickAnimation.tag = tag;
		}else{
			CCLOG(@"error:frames is error");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return clickAnimation;
}
+(id)showInLayer:(CCNode*)content point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop;{
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	ClickAnimation *clickAnimation = nil;
	if (content) {
		if (frames) {
			clickAnimation = [ClickAnimation node];
			[clickAnimation setLooped:isLoop];
			if (isLoop) {
				[clickAnimation playAnimation:frames delay:1/8.0f];				
			}else{
				[clickAnimation playAnimation:frames delay:1/8.0f call:nil];
			}
			[content addChild:clickAnimation z:999];
			clickAnimation.position = _point;
		}else{
			CCLOG(@"error:frames is error");
		}
	}else{
		CCLOG(@"error:content is nil");
	}
	return clickAnimation;
}
+(id)show:(CGPoint)_point{
	return [ClickAnimation showInLayer:[GameLayer shared].content point:_point path:@"images/animations/uicursorclick/" loop:NO];
}
+(void)removeSprBackCall:(id)sender{
	CCNode *node = sender;
	[node removeFromParentAndCleanup:YES];
}
-(void)touchSprBackCall:(id)sender{
	[self removeFromParentAndCleanup:YES];
}
-(void)playAnimation:(NSArray*)ary delay:(float)delay call:(id)call{
	if(!ary) return;
	if([ary count]==0) return;
	
	[self setDisplayFrame:[ary objectAtIndex:0]];
	
	[self stopAllActions];
	if([ary count]>1){
		CCAnimation * animation = [CCAnimation animationWithSpriteFrames:ary delay:delay];
		CCAnimate * animate = [CCAnimate actionWithAnimation:animation];
		if (looped) {
			CCSequence * seq;
			if(call){
				seq = [CCSequence actions:animate, call, nil];
			}else{
				seq = [CCSequence actions:animate, nil];
			}
			[self runAction:[CCRepeatForever actionWithAction:seq]];
		}else{
			id removeSelfBackCall = [CCCallFuncN actionWithTarget:self selector:@selector(touchSprBackCall:)];
			CCSequence * seq;
			if(call){
				seq = [CCSequence actions:animate, call,removeSelfBackCall, nil];
			}else{
				seq = [CCSequence actions:animate,removeSelfBackCall, nil];
			}
			[self runAction:seq];
		}
	}
}
@end
