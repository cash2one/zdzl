//
//  MonsterIconViewerContent.h
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

@interface MonsterIconViewerContent : BaseLoaderViewerContent{
	int monster_id;
	CCSprite * icon;
}

+(MonsterIconViewerContent*)create:(int)mid;

@end
