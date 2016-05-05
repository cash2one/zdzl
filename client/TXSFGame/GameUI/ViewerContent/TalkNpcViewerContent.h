//
//  TalkNpcViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;

@interface TalkNpcViewerContent : BaseLoaderViewerContent{
	int npc_id;
	CCSprite * viewer;
}
+(TalkNpcViewerContent*)create:(int)nid;
@end
