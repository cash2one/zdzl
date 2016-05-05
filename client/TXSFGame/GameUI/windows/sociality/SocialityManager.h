//
//  SocialityManager.h
//  TXSFGame
//
//  Created by efun on 13-3-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SocialityCanvas.h"
#import "Config.h"

@interface SocialityManager : CCLayer
{
	UITouch *scrollTouch_;
	CGPoint touchSwipe_;
	CGPoint layerSwipe_;
	CGFloat minimumTouchLengthToSlide_;
	CGFloat minimumTouchLengthToChangePage_;
	int state_;
	BOOL stealTouches_;
	
	SocialityItem *_socialityItem;
	
	SocialityCanvas *_friendCanvas;
	SocialityCanvas *_onlineCanvas;
	SocialityCanvas *_blacklistCanvas;
	SocialityCanvas *_currentCanvas;
}

@property (nonatomic) SocialityType currentType;	// 当前tab对应的类型

// 好友列表
@property (nonatomic) BOOL isFriendList;
@property (nonatomic, retain) SocialityCanvas *friendCanvas;
@property (nonatomic, retain) SocialityCanvas *onlineCanvas;
@property (nonatomic, retain) SocialityCanvas *blacklistCanvas;
@property (nonatomic, retain) SocialityCanvas *currentCanvas;

+(SocialityManager *)shared;
-(id)initWithSize:(CGSize)size;
-(void)setCanvasWithType:(SocialityType)type;
-(void)removeCurrentSelected;

@end
