//
//  Weapon.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "CFDialog.h"
#import "CCSimpleButton.h"
#import "WindowComponent.h"

#pragma mark - Weapon
@interface Weapon : WindowComponent <CCListDelegate,CCDialogDelegate> {
    CCMenu *menu;
	CCMenuItemSprite *bt_sk1;
	CCMenuItemSprite *bt_sk2;

	CCLayerList *cards;
	
	CCLabelTTF *arm_name;
	CCLabelTTF *arm_host;

	CCMenuItem *skill_name;
	
	//end
	CCLabelTTF *effects;		// 左边
	CCLabelTTF *per_effects;	// 右边，有百分比
	CCLabelTTF *next_effect;
	
	CCLabelTTF *level_need;
	CCLabelTTF *train_need;
	
	CCLabelTTF *trainInfo;
	CCSprite   *weapon;
	
	int	id_select;
    int m_arm_level;
	
	// 是否花费元宝返回
	CCSprite *skillBackGoldTips;
	CCSimpleButton *skillBack;
}

+(void)setRoleID:(int)rid;
-(void)reload;
-(void)menuCallbackBack: (id) sender;
@end
