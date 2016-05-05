//
//  SpiritIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SpiritIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation SpiritIconViewerContent

+(SpiritIconViewerContent*)create:(int)sid index:(int)index{
	SpiritIconViewerContent * node = [SpiritIconViewerContent node];
	[node showSpirit:sid index:index];
	return node;
}

-(void)showSpirit:(int)sid index:(int)ind{
	spirit_id = sid;
	index = ind;
	self.contentSize = CGSizeMake(cFixedScale(65), cFixedScale(83));
	[self showSpirit];
}
-(void)showSpirit{
	
	[self removeChildByTag:123 cleanup:YES];
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"spirits%d_%d.png",spirit_id,index];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_spirit target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_spirit;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		[self showLoaderInContentCenter];
		
		return;
	}
	
	CCSprite * icon = [CCSprite spriteWithFile:path];
	if(icon){
		icon.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
		[self addChild:icon];
	}
	
	[self hideLoader];
	
}
@end
