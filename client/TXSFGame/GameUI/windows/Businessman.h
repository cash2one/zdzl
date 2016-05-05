//
//  Businessman.h
//  TXSFGame
//
//  Created by efun on 13-1-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "MessageBox.h"
#import "Config.h"
#import "Window.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "CCSimpleButton.h"
#import "GameDB.h"
#import "ShowItem.h"
#import "AlertManager.h"
#import "CCPanel.h"
#import "WindowComponent.h"

typedef enum{
	Businessman_show_0 = 0 , //没有类型
	Businessman_show_1 = 1 , //珍宝类型
	Businessman_show_2 = 2 , //手气类型
}Businessman_show_type;

@interface Businessman : WindowComponent
{
	Businessman_show_type showType ;
	NSMutableDictionary*	goodsHelper;
	NSMutableArray*			goodsArray;
}

@property(nonatomic,assign)Businessman_show_type showType;

-(void)successfulBuy:(int)_sid type:(int)_buyType;
-(void)setButtonTouchWithBOOL:(BOOL)isTouch;
@end
