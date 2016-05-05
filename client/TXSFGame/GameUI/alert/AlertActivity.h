//
//  AlertActivity.h
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
//#import "GameAlert.h"
#import "WindowComponent.h"

@interface AlertActivity : WindowComponent{
	NSDictionary * activity;
}

@property(nonatomic,assign) NSDictionary * activity;

@end
