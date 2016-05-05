//
//  ItemIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ItemIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation ItemIconViewerContent

+(ItemIconViewerContent*)create:(int)iid{
	ItemIconViewerContent * node = [ItemIconViewerContent node];
	[node loadTargetItemIcon:iid];
	return node;
}

-(void)onEnter{
	[super onEnter];
	[self showItemIcon];
}

-(void)loadTargetItemIcon:(int)iid{
	item_id = iid;
	self.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
	[self showItemIcon];
}

-(void)showItemIcon{
	
	if(!self.parent) return;
	if(item_id < 0) {
		CCLOG(@"showItemIcon->item is -1 or o -> %d",item_id);
		return;
	}
	
	//[self removeChildByTag:123 cleanup:YES];
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			[self hideLoader];
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"item%d.png",item_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_item target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_item;
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
