//
//  NpcEffects.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "NpcEffects.h"


@implementation NpcEffects

-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call{
	NSString * path = [NSString stringWithFormat:@"images/effects/npc-effect/%d/",_eid];
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	
	if([frames count]==0){
		path = [NSString stringWithFormat:@"images/effects/npc-effect/1/"];
		frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	}
	if (_target && _call) {
		id act = [CCCallFunc actionWithTarget:self selector:@selector(endShow)];
		self.target = _target;
		self.removeCall = _call;
		[self playAnimation:frames delay:0.1 call:act];
	}else{
		[self playAnimation:frames delay:0.1];
	}
}
-(void)endShow{
	if(target!=nil&&removeCall!=nil){
		[target performSelector:removeCall ];
	}
	[self removeFromParentAndCleanup:YES];
}
@end
