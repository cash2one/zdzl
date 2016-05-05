//
//  JewlIconViewerContent.h
//  TXSFGame
//
//  Created by Soul on 13-5-17.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface JewlIconViewerContent : BaseLoaderViewerContent {
    int jewel_id;
	BOOL isHadRate;
}
@property (nonatomic, assign) BOOL isHadRate;	// 珠宝有成功率显示特效

+(JewlIconViewerContent*)create:(int)iid;
-(void)loadTargetJewlIcon:(int)iid;

@end
