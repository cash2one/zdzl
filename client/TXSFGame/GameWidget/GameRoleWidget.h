//
//  GameRoleWidget.h
//  TXSFGame
//
//  Created by chao chen on 12-10-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//
#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"



@interface GameRoleWidget : CCSprite
{
	CGSize size;
}
@property(nonatomic,assign) CGSize size;

////左移一步
-(void)moveToLeftStep;
////右移一步
-(void)moveToRightStep;


@end
