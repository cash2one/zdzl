//
//  FishReward.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "CCSimpleButton.h"
#import "MessageBox.h"
#import "Config.h"
#import "AnimationViewer.h"
#import "WindowComponent.h"

@interface FishReward : WindowComponent {
    CCSprite *itemBg;
	MessageBox *listLayer;
	NSMutableArray *fishItems;
	CCLayer *itemLayer;
	BOOL lockUse;
	
	AnimationViewer *shineUnder;
	AnimationViewer *shineOver;
	
}
@property (nonatomic) int playerItemId;

@end
