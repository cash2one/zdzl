//
//  InbetweeningViewerContent.h
//  TXSFGame
//
//  Created by Soul on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface InbetweeningViewerContent : BaseLoaderViewerContent {
    NSDictionary* iKonInfo;
}
+(InbetweeningViewerContent*)create:(NSDictionary*)data;

@end
