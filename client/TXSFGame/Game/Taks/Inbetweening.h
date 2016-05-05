//
//  Inbetweening.h
//  TXSFGame
//
//  Created by Soul on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class InbetweeningViewerContent;

@interface Inbetweening : CCLayer {
    NSDictionary* ikonInfo;
	int timeLong;
	int endLong;
	BOOL isEnd;
	id target;
	SEL call;
}

@property(nonatomic,assign)id target;
@property(nonatomic,assign)SEL call;
@property(nonatomic,retain)NSDictionary* ikonInfo;

+(Inbetweening*)createInbetweening:(NSDictionary*)_info target:(id)_target call:(SEL)_call;

@end
