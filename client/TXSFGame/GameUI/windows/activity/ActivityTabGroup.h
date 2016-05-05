//
//  ActivityTabGroup.h
//  TXSFGame
//
//  Created by Soul on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class ActivityTab;
@interface CCLayer(LinearLayout)
-(void)LinearLayout:(float)_offset;
-(ActivityTab*)checkEvent:(UITouch*)_touch;
-(void)setFocus:(ActivityTab*)_tab;
-(void)setDefaultFoucus;

@end

@interface ActivityTabGroup : CCLayer {
	CCLayer*	canvas;
	CGPoint		beginPoint;
	CGPoint		canvasPoint;
	UITouch*	touchEvent;
	int			status;
}

@property (nonatomic,retain)NSMutableArray *menuUIData;
+(ActivityTabGroup*)initActivityTabGroup:(float)_width height:(float)_height;

-(void)removeAllTabs;
-(void)addTabs:(NSArray*)array target:(id)_t call:(SEL)_c;

@end
