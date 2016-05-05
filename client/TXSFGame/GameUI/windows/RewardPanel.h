//
//  RewardPanel.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-12.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "WindowComponent.h"

@class CCPanel;
@interface RewardPanel : WindowComponent{
	float panelWidth;
	float panelHeight;
	
	int showCount;
	CCPanel * panel;
	CCLayerColor * content;
}

+(RewardPanel*)shared;
-(void)showList;

@end
