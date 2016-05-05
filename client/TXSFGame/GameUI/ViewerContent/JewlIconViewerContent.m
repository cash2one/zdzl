//
//  JewlIconViewerContent.m
//  TXSFGame
//
//  Created by Soul on 13-5-17.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "JewlIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"
#import "ClickAnimation.h"

@implementation JewlIconViewerContent

@synthesize isHadRate;

+(JewlIconViewerContent*)create:(int)iid{
	JewlIconViewerContent * node = [JewlIconViewerContent node];
	[node loadTargetJewlIcon:iid];
	return node;
}

-(void)loadTargetJewlIcon:(int)iid{
	jewel_id = iid;
	self.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
	[self showJewelIcon];
}

-(id)init{
	if (self = [super init]) {
		isHadRate = NO;
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
	[self showJewelIcon];
}

-(void)showJewelIcon{
	
	if(!self.parent) return;
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			[self hideLoader];
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"jewel%d.png",jewel_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_jewel target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_jewel;
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

-(void)setIsHadRate:(BOOL)_isHadRate
{
	if (isHadRate == _isHadRate) return;
	
	isHadRate = _isHadRate;
	if (isHadRate) {
		NSString *path = @"images/animations/jewel/hadSuc/";
		[ClickAnimation showInLayer:self
								  z:-1
								tag:500
							   call:nil
							  point:ccp(self.contentSize.width/2,self.contentSize.height/2)
							   path:path
							   loop:YES];
	} else {
		[self removeChildByTag:500];
	}
}

@end
