//
//  SpiritIconViewerContent.h
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

@interface SpiritIconViewerContent : BaseLoaderViewerContent{
	int spirit_id;
	int index;
}
+(SpiritIconViewerContent*)create:(int)sid index:(int)index;
@end
