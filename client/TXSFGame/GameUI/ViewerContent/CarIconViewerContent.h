//
//  CarIconViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface CarIconViewerContent : BaseLoaderViewerContent{
	int car_id;
}

+(CarIconViewerContent*)create:(int)cid;

@end
