//
//  FateIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "FateIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"
#import "ClickAnimation.h"
#import "GameDB.h"

@implementation FateIconViewerContent

@synthesize fateId;
@synthesize quality;

+(FateIconViewerContent*)create:(int)fid{
	FateIconViewerContent * node = [FateIconViewerContent node];
	node.fateId = fid;
	[node loadTargetFateIcon:fid];
	return node;
}

+(FateIconViewerContent*)create:(int)fid quality:(int)qualit{
	FateIconViewerContent * node = [FateIconViewerContent node];
	node.fateId = fid;
	node.quality = qualit;
	[node loadTargetFateIcon:fid];
	return node;
}

-(void)onEnter{
	[super onEnter];
	//[self showQuality];
	[self showFateIcon];
}

-(void)setQuality:(int)_quality{
	quality = _quality;
	[self showQuality];
}

-(void)showQuality{
	
	NSString * path = nil;
	
	if(quality==0 && fateId>0){
		NSDictionary * info = [[GameDB shared] getFateInfo:fateId];
		quality = [[info objectForKey:@"quality"] intValue];
	}
	
	if(quality == IQ_BLUE){
		path = @"images/animations/fate/blue/";
	}else if(quality == IQ_PURPLE){
		path = @"images/animations/fate/purple/";
	}else{
		path = @"images/animations/fate/green/";
	}
	
	if(path){
		[ClickAnimation showInLayer:self z:-1 tag:100 call:nil point:ccp(cFixedScale(30),cFixedScale(30)) path:path loop:YES];
	}
	
	
}

-(void)loadTargetFateIcon:(int)fid{
	fateId = fid;
	self.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
	[self showFateIcon];
}

-(void)showFateIcon{
	
	if(!self.parent) return;
	
	[self removeChildByTag:123 cleanup:YES];
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"soul%d.png",fateId];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_fate target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_fate;
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
