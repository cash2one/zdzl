//
// GameWidgetManager.h
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

////
typedef enum {
    TXSF_GameRoleWidget,
    TXSF_GamePackWidget,    
}WidgetID;

@class GamePackWidget;
@class GameRoleWidget;

@interface GameWidgetManager : CCSprite
{
	GamePackWidget *packWidget_;
	GameRoleWidget *roleWidget_;
	//NSMutableDictionary *widgetDictionary;
}
+(GameWidgetManager*)shared;

////控件触发
-(void)widgetTapped:(WidgetID) widgetID;

@end
