//
//  CarNameViewContent.h
//  TXSFGame
//
//  Created by Max on 13-5-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@interface CarNameViewContent : BaseLoaderViewerContent {
    int name_id;
}

+(CarNameViewContent*)create:(int)nid;

@end
