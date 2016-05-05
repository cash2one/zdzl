//
//  SettingPanel.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-12.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"

@interface SettingPanel : WindowComponent {
	CCMenu *menu;
	//fix chao
	BOOL isPlateTouch;
	BOOL isMenuTouch;
    BOOL isTouch;
	//end
	
	CCSprite * serviceTips;
	
	int mapRolesMax;
	
}
-(void)setLoadWithValue:(NSInteger)value;
@end
