//
//  SacrificePanel.h
//  TXSFGame
//
//  Created by efun on 12-12-5.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"
#import "CCLayerList.h"
#import "GameConfigure.h"
#import "Window.h"
#import "MessageBox.h"
#import "AnimationViewer.h"
#import "CFDialog.h"
#import "GameConnection.h"
#import "GameDB.h"
#import "AlertManager.h"
#import "InfoAlert.h"
#import "ShowItem.h"
#import "WindowComponent.h"

#define Tag_Seal        50

typedef enum {
    Sacrifice_Button_Free = 1,
    Sacrifice_Button_Gold
} Sacrifice_Button_Type;

typedef enum {
    Seal_Tiger = 1,	// 对应狮子
    Seal_Dragon,	// 龙
    Seal_Deer,		// 鹿
    Seal_Phoenix	// 对应狼
} Seal_Type;

@interface SacrificePanel : WindowComponent
{
    CCLabelTTF *tigerLabel;
    CCLabelTTF *dragonLabel;
    CCLabelTTF *buttonInfo;
    
	CCMenuItemSprite *ruleItem;
    CCMenuItemSprite *freeItem;
    CCMenuItemSprite *goldItem;
    
    MessageBox *ruleInfo;
    
    CGPoint sealPoint;
    
    int freeCount;
    int goldCount;
    int costCoin;
    
    Seal_Type currentSealType;
    int currentSealCount;
	
	BOOL isBusy;
}

@end
