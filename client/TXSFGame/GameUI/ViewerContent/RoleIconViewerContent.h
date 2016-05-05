//
//  RoleIconViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface RoleIconViewerContent : BaseLoaderViewerContent{
	int role_id;
	int type;
	CCSprite * icon;
}
+(RoleIconViewerContent*)create:(int)rid type:(int)type;
@end
