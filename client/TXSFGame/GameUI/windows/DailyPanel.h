//
//  DailyPanel.h
//  TXSFGame
//
//  Created by efun on 13-1-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"
#import "Window.h"
#import "MessageBox.h"
#import "CCLayerList.h"
#import "CCSimpleButton.h"
#import "CCPanel.h"
#import "GameConnection.h"
#import "TimeBox.h"
#import "AbyssManager.h"
#import "EatFoot.h"
#import "Businessman.h"
#import "FishingManager.h"
#import "Arena.h"
#import "GameConfigure.h"
#import "Car.h"
#import "WindowComponent.h"

static inline CCSprite* getIconByDailyType(DailyType type)
{
	return [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/richang_icon/richang%d.png", (int)type]];
}
// 是否需要连服务器
static inline BOOL isNeedLoadData(DailyType type)
{
	NSArray *array = [NSArray arrayWithObjects:
					  [NSString stringWithFormat:@"%d", DailyType_fight],		// 竞技场
					  [NSString stringWithFormat:@"%d", DailyType_mainFight],	// 首领战
					  [NSString stringWithFormat:@"%d", DailyType_cat],			// 招财猫
					  [NSString stringWithFormat:@"%d", DailyType_engrave],		// 宝具铭刻
					  [NSString stringWithFormat:@"%d", DailyType_teamFight],	// 组队挑战
					  [NSString stringWithFormat:@"%d", DailyType_teamBoss],	// 组队BOSS
					  [NSString stringWithFormat:@"%d", DailyType_fishing],		// 钓鱼
                      [NSString stringWithFormat:@"%d", DailyType_ctree],		// 摇钱树
					  [NSString stringWithFormat:@"%d", DailyType_fly],			// 烛龙飞天
					  [NSString stringWithFormat:@"%d", DailyType_cometo],		// 魔龙降世
					  // 需要继续添加
					  nil];
	NSString *key = [NSString stringWithFormat:@"%d", type];
	return [array containsObject:key];
}

@interface DailyPanel : WindowComponent <CCListDelegate>
{
	CCLayerList *layerList;
	NSMutableArray *dailyPanels;
	NSMutableDictionary *dailyButtonDict;
}

@end
