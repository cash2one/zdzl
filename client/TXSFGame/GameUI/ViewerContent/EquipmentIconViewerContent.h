//
//  EquipmentIconViewerContent.h
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

@interface EquipmentIconViewerContent : BaseLoaderViewerContent{
	int equip_id;
}

+(EquipmentIconViewerContent*)create:(int)eid;
-(void)loadTargetEquipIcon:(int)eid;

@end
