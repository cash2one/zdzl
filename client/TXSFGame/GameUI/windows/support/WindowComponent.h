//
//  WindowComponent.h
//  TXSFGame
//
//  Created by Soul on 13-5-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class CCSimpleButton;

@interface WindowComponent : CCNode<CCTouchOneByOneDelegate> {
	WINDOW_TYPE windowType;
	CCSprite* _background;
	CCSimpleButton* _closeBnt;
	
	BOOL __touchEnabled;
	int __touchPriority;
	int _closePy;
}
@property(nonatomic, assign) BOOL touchEnabled;
@property(nonatomic, assign) int touchPriority;
@property(nonatomic,assign)WINDOW_TYPE windowType;

-(void)closeWindow;


-(CCSprite*)getBackground:(NSString*)path;
-(CGPoint)getCaptionPosition;
-(CGPoint)getClosePosition;

-(NSString*)getBackgroundPath;
-(NSString*)getCaptionPath;
-(int)getAboutZIndex;

@end
