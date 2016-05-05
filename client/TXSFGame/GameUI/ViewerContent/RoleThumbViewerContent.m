//
//  RoleThumbViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RoleThumbViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation RoleThumbViewerContent

+(RoleThumbViewerContent*)create:(int)rid{
	return [RoleThumbViewerContent create:rid hide:NO];
}

+(RoleThumbViewerContent*)create:(int)rid hide:(BOOL)hide{
	RoleThumbViewerContent * node = [RoleThumbViewerContent node];
	[node loadRoleThumb:rid hide:hide];
	return node;
}

-(void)loadRoleThumb:(int)rid hide:(BOOL)hide{
	role_id = rid;
	isHide = hide;
	self.contentSize = CGSizeMake(cFixedScale(113), cFixedScale(147));
	[self showRoleThumb];
}

-(void)showRoleThumb{
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"player_dj_%d.png",role_id];
	if(isHide){
		name = [NSString stringWithFormat:@"player_dj_%d_1.png",role_id];
	}
	
	NSString * path = [GameResourceLoader getFilePathByType:PathType_role_thumb target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_role_thumb;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		[self showLoaderInContentCenter];
		
		return;
	}
	
	CCSprite * thumb = [CCSprite spriteWithFile:path];
	if(thumb){
		thumb.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
		[self addChild:thumb];
	}
	
	[self hideLoader];
	
}

@end
