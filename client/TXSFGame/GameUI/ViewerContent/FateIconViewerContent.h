//
//  FateIconViewerContent.h
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

@interface FateIconViewerContent : BaseLoaderViewerContent{
	int fateId;
	int quality;
}
@property(nonatomic,assign) int fateId;
@property(nonatomic,assign) int quality;
+(FateIconViewerContent*)create:(int)fid;
+(FateIconViewerContent*)create:(int)fid quality:(int)quality;
-(void)loadTargetFateIcon:(int)fid;
@end
