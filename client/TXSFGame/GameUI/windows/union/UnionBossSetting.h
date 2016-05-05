//
//  UnionBossSetting.h
//  TXSFGame
//
//  Created by Max on 13-4-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface UnionBossSetting : CCLayer {
	CCSprite *bg;
	CCSprite *weekDayStr;
	NSMutableString *tStr;
	NSMutableString *wdStr;
	int currenWD;
	CCSprite *timeStr;
	CCSprite *timeBtnBg;
}
+(void)show;
+(void)hide;

@end
