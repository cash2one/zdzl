//
//  TalkNpcViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "TalkNpcViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation TalkNpcViewerContent

+(TalkNpcViewerContent*)create:(int)nid{
	TalkNpcViewerContent * node = [TalkNpcViewerContent node];
	[node loadNpc:nid];
	return node;
}

-(void)loadNpc:(int)nid{
	npc_id = nid;
	[self showNpc];
}

-(void)showNpc{
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"npc_big_%d.png",npc_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_talk_npc target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_talk_npc;
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
