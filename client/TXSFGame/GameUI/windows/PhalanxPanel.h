//
//  PhalanxPanel.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-17.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "CCLayerList.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "Panel.h"
#import "CFDialog.h"
#import "GameConnection.h"
#import "AnimationViewer.h"
#import "AlertManager.h"
#import "CCPanel.h"
#import "TaskManager.h"
#import "intro.h"
#import "ShowItem.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "WindowComponent.h"

typedef enum {
    Tag_Selected_Role = 1001,
} Tag_Phalanx_Type;

static inline CCSprite *getPhalanxIcon(int pid)
{
    CCSprite *icon = nil;
    if (pid > 0) {
        icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/phalanx_icon/phalanx_%d.png", pid]];
    }
    if (!icon) {
        CCLOG(@"phalanxIcon with pid %d is nil", pid);
        icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/phalanx_icon/phalanx_%d.png", 1]];
    }
    return icon;
}

// 是否可以升级该阵形
static inline BOOL getCanLevelupByPhalanxId(int pid)
{
    // 玩家阵形id
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    if (playerPhalanx) {
        int level = [[playerPhalanx objectForKey:@"level"] intValue];
        NSDictionary *phalanxLevel = [[GameDB shared] getPositionLevelInfo:pid level:level+1];
        if (phalanxLevel) {
            int unlock = [[phalanxLevel objectForKey:@"unlock"] intValue];
            NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
            int playerLevel = [[playerInfo objectForKey:@"level"] intValue];
            if (playerLevel >= unlock) {
                return YES;
            }
        }
    }
    
    return NO;
}

@class PhalanxAttributeTips;
@protocol PhalanxPanelDelegate <NSObject>
@optional
-(void)clickMemberWithRoleId:(int)rid touch:(UITouch *)touch;
-(void)updateMemberListByPhalanxId:(int)pid;
-(void)updatePanelByPlayerPhalanxId:(int)pid;
-(void)studyWithPhalanxId:(int)pid;

@end

// 阵型成员菜单项
@interface PhalanxMemberMenu : CCSprite
{
    CCSprite *characterIcon;
    CCSprite *inIcon; // 出战图标
}
-(id)initWithRoleId:(int)rid;
// 设置是否在阵中
-(void)setInArray:(BOOL)inArray;

@end

// 成员列表
@interface PhalanxMemberList : CCLayerColor
{
	NSMutableArray *memberArray;
}

@property (nonatomic, assign) id<PhalanxPanelDelegate> delegate;

// 通过阵形id更新角色列表的出战状态
-(void)updateByPhalanxId:(int)pid;

@end

// 阵型详细内容
@interface PhalanxDetail : CCLayerColor
{
    int movePhalanxId;              // 拖拽角色移到的阵位id（如没移到阵位id为-1）
    int currentphalanxId;
    AnimationViewer *normalPhalanxIcon;
    AnimationViewer *eyePhalanxIcon;
    BOOL fromMember;                // 拖拽角色是否来之角色列表
    int adjustPos;                  // 调整阵位，阵位1，3向后移
	
	CCLabelTTF * title;        // 阵名，等级
	CCLabelTTF * effect;       // 阵形效果
//	CCSprite *selectRole;          // 拖拽的玩家
	
	NSArray *posArray;        // 阵型位置
	PhalanxAttributeTips *phalanxAttributeTips;   // 提示框
	NSMutableArray *phalanxIconArray;
	NSMutableArray *roleArray;  // 阵位中五个玩家
	
	int selectedRoleId;
}

@property (nonatomic, assign) id<PhalanxPanelDelegate> delegate;
@property (nonatomic) int phalanxId;
@property (nonatomic) BOOL dragRole;                    // 是否在拖拽角色
@property (nonatomic, assign) NSArray *posArray;        // 阵型位置
//@property (nonatomic, retain) CCLabelTTF *title;        // 阵名，等级
//@property (nonatomic, retain) CCLabelTTF *effect;       // 阵形效果
@property (nonatomic, assign) PhalanxAttributeTips *phalanxAttributeTips;   // 提示框
// 一个阵眼，四个普通位置
@property (nonatomic, assign) NSMutableArray *phalanxIconArray;
@property (nonatomic, assign) NSMutableArray *roleArray;  // 阵位中五个玩家

// 通过阵形id更新角色列表的出战状态
// phalanxLevel：阵形等级表数据
// level：该阵形当前等级
-(void)updateDetailByPhalanxLevel:(NSDictionary *)phalanxLevel level:(int)level;
// 显示隐藏属性
-(void)showAttribute:(NSString *)attribute isEye:(BOOL)isEye atPoint:(CGPoint)point;
-(void)hiddenAttribute;
-(void)setSelectRoleWithRoleId:(int)rid touch:(UITouch *)touch;
-(void)updateRoleByPhalanxIndex:(int)index;

@end

// 阵形信息项
@interface PhalanxInfoMenu : CCListItem
{
    CCSprite *itemBg;           // 背景，当前背景
    CCSprite *currentItemBg;
    CCSprite *icon;             // 阵形图标
    ccColor3B color;            // 标题颜色，当前标题颜色
    ccColor3B currentColor;
	
	CCSprite *study;      // 学习，升级按钮
	CCSprite *levelup;
	CCLabelTTF *use;      // 启用中
	CCLabelTTF *title;
	
}
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isSelected;
@property (nonatomic, assign) CCSprite *study;      // 学习，升级按钮
@property (nonatomic, assign) CCSprite *levelup;
@property (nonatomic, assign) CCLabelTTF *use;      // 启用中
@property (nonatomic, assign) CCLabelTTF *title;

@end

// 阵型列表
@interface PhalanxList : CCLayerColor <CCListDelegate>
{
    int cost;
    int phalanxId;
    int playerPhalanxId;
    int activePid;
    int selectedPid;
    CCLayer *layerList;
	
	BOOL requesting;		// YES=发送学习/升级协议，未返回
}

@property (nonatomic, assign) id<PhalanxPanelDelegate> delegate;

-(void)setActiveWithPhalanxId:(int)pid;
-(void)setSelectedWithPhalanxId:(int)pid;
-(void)updateByPhalanxId:(int)pid;              // 学习或者，升级阵形后，更新对应信息

@end

@class PhalanxBox;

/*
 * 整型界面
 */

@interface PhalanxPanel : WindowComponent <PhalanxPanelDelegate> {
    PhalanxBox *phalanxBox;
    PhalanxMemberList *phalanxMemberList;
//    PhalanxDetail *phalanxDetail;
    PhalanxList *phalanxList;
	CCMenuItemImage *closeMenuItem;
}

-(void)updateByPhalanxId:(int)pid;

@end
