//
//  ChatPanel.h
//  TXSFGame
//
//  Created by Max on 13-3-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"
#import "LowerLeftChat.h"


@interface ChatPanel : ChatPanelBase {
	CGPoint cupoint;
	NSMutableString *cuUserName;
	bool isHasOtherWindows;
}




+(ChatPanel*)getChatPanel;


@end
