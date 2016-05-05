//
//  ShowItem.h
//  TXSFGame
//
//  Created by Max on 13-1-12.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"
#import "Config.h"
#import "AlertManager.h"
#import "Window.h"
#import "FightManager.h"


@interface ShowItem :NSObject{
    
}

+(void)stopAll;

+(void)showItemAct:(NSString*)itemTipsString;
+(void)showErrorAct:(NSString *)key;
+(void)tipsFinlish:(id)fun data:(id)_data;
+(void)removeAllTips;
@end
