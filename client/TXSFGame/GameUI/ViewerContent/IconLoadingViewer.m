//
//  IconLoadingViewer.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "IconLoadingViewer.h"
#import "AnimationViewer.h"

@implementation IconLoadingViewer

-(void)onEnter{
	
	[super onEnter];
	
	AnimationViewer * node = [AnimationViewer node];
	[self addChild:node];
	[node showAnimationByPathForever:@"images/animations/defaultItem/%d.png"];
	
}



@end
