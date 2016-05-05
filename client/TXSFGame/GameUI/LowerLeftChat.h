//
//  LowerLeftChat.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-18.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"
#import "GameUI.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "GameConnection.h"
#import "StretchingImg.h"
#import "FightManager.h"
#import "AlertTuba.h"
#import "ChatPanelBase.h"

/*
 *左下方的聊天窗口
 */
@interface LowerLeftChat : ChatPanelBase <UITextFieldDelegate> {
	int touchDis;
	int chatPosY;
	CCSprite *msgCbg;
	int pmc;
}

+(LowerLeftChat*)share;
-(void)EventCloseChat:(id)sender;
-(void)EventOpenChat:(id)sender;
+(void)clearText;

@end
