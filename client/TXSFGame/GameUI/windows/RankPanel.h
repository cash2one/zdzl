//
//  RankPanel.h
//  TXSFGame
//
//  Created by efun on 13-1-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Window.h"
#import "MessageBox.h"
#import "CCSimpleButton.h"
#import "CCLayerList.h"
#import "CCPanel.h"
#import "WindowComponent.h"

typedef enum {
	RankType_level=1,	// 等级榜
	RankType_fight,		// 战斗力
	RankType_arena,		// 竞技场
    RankType_abyss,//深渊榜
    RankType_boss,//BOSS榜
    RankType_union,//同盟榜
    } RankType;

@interface RankPanel : WindowComponent <CCListDelegate>
{
	int currentPageCount;
	
	CCLabelTTF *updateLabel;
	CCLabelTTF *rankTitle;
	CCLabelTTF *rankLabel;
	CCLabelTTF *mineTitle;
	CCLabelTTF *mineLabel;
	
	CCLabelTTF *listRank;
	CCLabelTTF *listData;	// 战斗力（战斗力）或总战力（竞技场）
	
	CCLayerList *tabList;
	
	CCSimpleButton *moreButton;
	NSMutableArray *rankItems;
    //
    BOOL isSend;
}
@property (nonatomic) RankType defaultType;

@end
