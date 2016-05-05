//
//  BaseLoaderViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "BaseLoaderViewerContent.h"
#import "IconLoadingViewer.h"
#import "GameFileUtils.h"
#import "GameResourceLoader.h"

@implementation BaseLoaderViewerContent

-(void)dealloc{
	if(helper){
		[helper free];
		helper = nil;
	}
	[super dealloc];
}

-(void)onExit{
	if(helper){
		[helper free];
		helper = nil;
	}
	[super onExit];
}

-(void)showLoader{
	loader = [IconLoadingViewer node];
	loader.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	[self addChild:loader z:100 tag:100];
}

-(void)showLoaderInContentCenter{
	if(loader) return;
	[self showLoader];
}
-(void)showLoaderAddY:(float)_y{
	if(loader) return;
	[self showLoader];
	loader.position = ccp(loader.position.x,loader.position.y+_y);
}

-(void)hideLoader{
	if(loader){
		[self removeChild:loader cleanup:YES];
	}
}

@end
