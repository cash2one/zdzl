//
//  BaseLoaderViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class GameLoaderHelper;
@class IconLoadingViewer;
@interface BaseLoaderViewerContent : CCSprite{
	IconLoadingViewer * loader;
	GameLoaderHelper * helper;
}
-(void)showLoaderInContentCenter;
-(void)showLoaderAddY:(float)_y;
-(void)hideLoader;
@end
