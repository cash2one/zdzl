//
//  Car.h
//  TXSFGame
//
//  Created by Max on 13-3-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "GameDB.h"
#import "RoleManager.h"
#import "CCPanel.h"
#import "Config.h"
#import "StretchingImg.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "AnimationRole.h"
#import "WindowComponent.h"

@class CarViewerContent;

@interface Car : WindowComponent {
    NSArray *carlist;
	CarViewerContent * cvc;
	CCSprite *carTitleName;
	NSDictionary *currenSelectCar;
	CCSimpleButton *btn_ByCar;
	CCSimpleButton *btn_BuyCar;
	CCSimpleButton *btn_OutCar;
	int pcid;
	AnimationRole *player;
	CCSprite *label24;
	CCSprite *label25;
	
	
	CCSprite *bg_payitem;
	int playerOffset;
}

+(int)getMyPackageCarId;

@end
