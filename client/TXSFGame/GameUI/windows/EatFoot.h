//
//  EatFoot.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCScrollLayer.h"

@class CCSimpleButton;
@class CCLabelFX;
@interface EatFoot : CCLayer<CCScrollLayerDelegate>{
	
	CCSimpleButton * close_btn;
	CCSimpleButton * info_btn;
	
	CCSimpleButton * pay1;
	CCSimpleButton * pay2;
	
	CCSprite * foot_select;
	CCSprite * foot_start;
	CCSprite * foot_full;
	CCSprite * foot_chopstick;
	
	int selectIndex;
	NSArray * foots;
	CCScrollLayer * scrollLayer;
	
	CCNode * footInfo;
	int bTime;
	
	CCSimpleButton * t_foot;
	CCLabelFX * timeCount;
	int touchCount;
	BOOL canTouch;
}

+(void)show;
+(void)hide;

@end
