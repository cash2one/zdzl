//
//  RoleImageViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RoleImageViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation RoleImageViewerContent

+(RoleImageViewerContent*)create:(int)rid{
	RoleImageViewerContent * node = [RoleImageViewerContent node];
	[node loadRole:rid];
	return node;
}

-(void)loadRole:(int)rid{
	role_id = rid;
	[self showRole];
}

-(void)showRole{
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"player_ui_%d.png",role_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_role_image target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_role_image;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		[self showLoaderAddY:cFixedScale(200)];
		return;
	}
	
	viewer = [CCSprite spriteWithFile:path];
	if(viewer){
		viewer.anchorPoint = self.anchorPoint;
		[self addChild:viewer];
	}
	
	[self hideLoader];
	
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(viewer){
		viewer.anchorPoint = anchorPoint;
	}
}

@end
