//
//  ItemIconViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface ItemIconViewerContent : BaseLoaderViewerContent{
	int item_id;
}
+(ItemIconViewerContent*)create:(int)iid;
-(void)loadTargetItemIcon:(int)iid;
@end
