//
//  MonsterIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MonsterIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation MonsterIconViewerContent

+(MonsterIconViewerContent*)create:(int)mid{
	MonsterIconViewerContent * node = [MonsterIconViewerContent node];
	[node loadMonsterIcon:mid];
	return node;
}

-(void)draw{
	[super draw];
	ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}
-(void)loadMonsterIcon:(int)mid{
	monster_id = mid;
	[self loadMonsterIcon];
}

-(void)loadMonsterIcon{
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"monster_icon_%d.png",monster_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_monster target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_monster;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		return;
	}
	
	icon = [CCSprite spriteWithFile:path];
	if(icon){
		icon.anchorPoint = self.anchorPoint;
		[self addChild:icon];
	}
	
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(icon){
		icon.anchorPoint = anchorPoint;
	}
}


@end
