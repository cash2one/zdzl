//
//  TaskPanel.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-20.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "CCLayerList.h"
#import "GameConnection.h"
#import "CFDialog.h"
#import "InfoAlert.h"
#import "AlertManager.h"
#import "CCPanel.h"
#import "AnimationViewer.h"
#import "WindowComponent.h"

@class Task;
@class CCLabelFX;

// 悬赏任务按钮
typedef enum {
	
	OfferDetailBox = 1,				// 开启宝箱
	OfferDetailBuy,				// 购买冰符
	
	
	
	OfferDetailDisalbeDone,		// 直接完成(不能点击)
	OfferDetailFindRode,		// 自动寻路
	OfferDetailDisalbeFindRode,	// 自动寻路(不能点击)
	
	
	
	OfferDetailOwn,			// 拥有
	OfferDetailTaskIcon,	// 任务Icon
	OfferDetailItemIcon,	// 物品Icon
	
	// 1.15
	OfferDetailDone,			// 直接完成
	OfferDetailGet,				// 领取任务
	
	OfferDetailAllPurple,		// 一键全紫
	OfferDetailRefresh,			// 免费刷新
	OfferDetailGoldRefresh,		// 元宝刷新
	
	OfferDetailAllPurpleDisable,
	OfferDetailRefreshDisable,
	OfferDetailGoldRefreshDisable,
	
	OfferDetailRule,			// 悬赏规则
	
} OfferDetailTag;

// 任务状态
typedef enum {
	TaskStatus_Can_Accept = 1,	// 可接
	TaskStatus_Had_Accept,	// 已接
	TaskStatus_Done_Accept,	// 完成
} TaskStatus;

// 刷新类型
typedef enum {
	RefreshTypeFree = 1,
	RefreshTypeGold,
	RefreshTypePurple,
} RefreshType;

@protocol TaskOfferItemDelegate <NSObject>
@optional
-(void)menuItemTapped:(id)sender taskId:(int)tid index:(int)index;
@end

// 一级任务菜单项
@interface TaskMenuItem : CCListItem {
    CCSprite *itemBg;
    CCSprite *currentItemBg;
    CCSprite *currentIcon;
    BOOL isMenuSelect;
	
	CCLabelTTF *label;
}
@property(nonatomic,assign) CCLabelTTF *label;
@property(nonatomic,assign) BOOL isLock;

-(void)setMenuSelected:(BOOL)select;

@end

// 二级任务菜单项
@interface TaskDetailMenuItem : CCLayer
{
    CCSprite *itemBg;
    CCSprite *currentItemBg;
	CCLabelFX * label;
    BOOL isMenuSelect;
	
	Task * task;
}
-(void)setTask:(Task*)task;
-(Task*)getTask;
//@property(nonatomic,assign) Task * task;

-(void)setMenuSelected:(BOOL)select;

@end

// 一级任务列表
@interface TaskList : CCLayerColor <CCListDelegate>
{
    CCLayerList *layerList;
}

@end

// 二级任务列表
@interface TaskDetailList : CCLayerColor{
	CCLayer *layerList;
}
-(void)showList:(NSArray*)list withType:(Task_Type)type;
-(void)showTaskList:(Task_Type)type;
@end

// 详细任务数据
@interface TaskDetail : CCLayerColor{
	CCLabelTTF *titleLabel;
	CCLabelTTF *mainLockLabel;
	CCLabelTTF *detailLabel;
	//CCLabelTTF *acceptNPCLabel;
	//CCLabelTTF *doneNPCLabel;
	CCLabelTTF *rewardLabel;
	Task * task;
	
	CCMenu *findRoadMenu;
}
-(void)setTask:(Task*)task;
@end

// 悬赏任务
@interface TaskOfferPanel : CCLayerColor <TaskOfferItemDelegate>
{
	CCLabelTTF *refreshTimeTitle;
	CCLabelTTF *refreshTimeLabel;
	CCLabelTTF *refreshCountTitle;
	CCLabelTTF *refreshCountLabel;
	int refreshCount;
	int addSeconds;
	
	CCLabelTTF *offerCountLabel;
	int offerCountMax;
	int offerCount;
	
	CCLabelTTF *offerScoreLabel;
	
	int selectedIndex;
	int boxNeedExp;
	int currentTaskId;
	BOOL firstCountDown;
	
	CCSprite *boxExp;
	NSMutableArray *offerItems;
}
@property (nonatomic) BOOL needLoad;	// 是否需要重新载入数据

// 载入数据
-(void)loadDataByServer;
// 载入悬赏任务列表
-(void)loadDataWithTaskIds:(NSArray *)taskIds qualitys:(NSArray *)qualitys statusArray:(NSArray *)statusArray exps:(NSArray *)exps;
@end

@interface TaskPanel : WindowComponent
{
//	CCMenuItemImage *closeMenuItem;
	CCMenuItemImage *boxMenuItem;
	
	BOOL hasBox;
	CCLayerColor *maskLayer;
	AnimationViewer *shineUnder;
	AnimationViewer *shineOver;
}
//-(void)showWithTaskType:(Task_Type)type;	// 显示任务类型
//-(void)setRewardBox:(BOOL)showBox;

@end
