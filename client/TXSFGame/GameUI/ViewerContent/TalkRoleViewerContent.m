//
//  TalkRoleViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "TalkRoleViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation TalkRoleViewerContent

+(TalkRoleViewerContent*)create:(int)rid{
	TalkRoleViewerContent * node = [TalkRoleViewerContent node];
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
	
	NSString * name = [NSString stringWithFormat:@"player_big_%d.png",role_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_talk_role target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_talk_role;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		return;
	}
	
	viewer = [CCSprite spriteWithFile:path];
	if(viewer){
		viewer.anchorPoint = self.anchorPoint;
		[self addChild:viewer];
	}
	
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(viewer){
		viewer.anchorPoint = anchorPoint;
	}
}

@end
