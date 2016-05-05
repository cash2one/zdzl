//
//  RecruitPanel.h
//  TXSFGame
//
//  Created by efun on 12-11-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "CCLayerList.h"
#import "GameConfigure.h"
#import "ScrollPanel.h"
#import "CCPanel.h"
#import "AnimationViewer.h"
#import "GameConnection.h"
#import "ClickAnimation.h"
#import "TaskManager.h"
#import "intro.h"
#import "ShowItem.h"
#import "ItemIconViewerContent.h"
#import "WindowComponent.h"

// 帅印
static inline CCSprite *getSealIcon(int sid)
{
    CCSprite *icon = nil;
    if (sid >= 0) {
		icon = [ItemIconViewerContent create:sid];
    }
    return icon;
}

// 角色状态
static inline CCSprite *getStatusBgIcon(ROLE_STATUS roleStatus)
{
    switch (roleStatus) {
        case ROLE_STATUS_AGAIN:
        {
            return [CCSprite spriteWithFile:@"images/ui/panel/recruit_statusbg3.png"];
        }
            break;
        case ROLE_STATUS_OWN:
        {
            return [CCSprite spriteWithFile:@"images/ui/panel/recruit_statusbg.png"];
        }
            break;
        case ROLE_STATUS_RECRUIT:
        {
            return [CCSprite spriteWithFile:@"images/ui/panel/recruit_statusbg2.png"];
        }
            break;
        case ROLE_STATUS_CANT_OWN:
        {
            return [CCSprite spriteWithFile:@"images/ui/panel/recruit_statusbg4.png"];
        }
            break;
            
        default:
            break;
    }
    
    return nil;
}
typedef enum {
    Tag_Seal = 100,
	Tag_Role,
	Tag_Role_def,
    Tag_Status_Bg,
	Tag_Role_detail,
} Tag_Type;

typedef enum {
    RECRUIT_ROLE_TAG = 1000,
    RECRUIT_HIDE_ROLE_TAG
} RECRUIT_TAG;

// 点将

@protocol RecruitPanelDelegate <NSObject>

@optional
-(void)clickRecruitInfoWithRoleId:(int)rid;         // 角色信息
-(void)clickRecruitRoleWithRoleId:(int)rid;         // 招募按钮
-(void)clickRecruitAgainWithRoleId:(int)rid;        // 归队按钮
-(void)getSealEvent;                                // 获取帅印
-(void)updateListWithRoleId:(int)rid;               // 更新角色列表

@end

@interface RecruitRoleInfo : CCLayerColor
{
    CCSprite *bg;
    CCSprite *currentBg;
    BOOL hideBoss;
	
	CCLabelTTF *statusLabel;
	NSMutableArray *conditionStatusArray;
	NSMutableDictionary *recruitTypeDict;
}

@property (nonatomic) BOOL unlock;          // YES为可招募
@property (nonatomic) BOOL unlockLook;      // YES为可查看角色详细内容
@property (nonatomic) BOOL isSelected;
@property (nonatomic) int currentRoleId;
@property (nonatomic) ROLE_STATUS currentRoleStatus;
@property (nonatomic, assign) CCLabelTTF *statusLabel;
@property (nonatomic, assign) NSMutableArray *conditionStatusArray;

-(void)select:(BOOL)select;
-(void)updateByStatus:(ROLE_STATUS)roleStatus;
-(id)initWithRoleId:(int)rid;

@end

@interface RecruitHideRoleInfo : CCLayerColor
{
    CCSprite *bg;
    CCSprite *currentBg;
    float iconX;
    float labelX;
    float startY;
    float offsetY;
	
	RecruitRoleInfo *recruitRoleInfo;
	
}

@property (nonatomic) BOOL isSelected;
@property (nonatomic) int currentRoleId;
@property (nonatomic, assign) RecruitRoleInfo *recruitRoleInfo;

-(void)setRecruitRoleInfo:(RecruitRoleInfo *)recruitRoleInfo_;
-(void)select:(BOOL)select;

@end

@interface RecruitRoleList : CCLayerColor
{
    CCLayer *listLayer;
    CGPoint startPoint;
    CGPoint offsetPoint;
    CCLayer *layerList;
	int lastIndex;
	
	CGSize pageSize;
	float offsetY;
	float offsetX2;
	float offsetY2;
}

@property (nonatomic) int lastRoleId;
@property (nonatomic, assign) id<RecruitPanelDelegate> delegate;

-(void)setLayerPosition:(CCLayer *)layer index:(int)index;
-(void)setCurrentRoleInfoWithId:(int)rid;
-(void)updateById:(int)rid;

@end

@interface RecruitRoleDetail : CCLayerColor
{
    CCSprite *scrollLeft;
    CCSprite *scrollMiddle;
    CCSprite *scrollRight;
	CCSprite *sealBg;
    CCLabelTTF *sealNameLabel;
    CCLabelTTF *sealNumLabel;
    CCLabelTTF *ownLabel;

    int useNum;
    int currentUseNum;
    BOOL unlockRecruit;     // YES为点击招募
    BOOL playSkill;
	
	CCLabelTTF *nameLabel;
	CCLabelTTF *rankLabel;		// 位阶
	CCLabelTTF *weaponLabel;	// 宝具
	CCLabelTTF *jobLabel;		// 职阶
	CGPoint namePoint;
	CGPoint rankPoint;
	CGPoint weaponPoint;
	CGPoint jobPoint;
	CGPoint skillPoint;
	
	id<RecruitPanelDelegate> delegate;
	
	BOOL backing;		// YES=发送归队协议，未返回
	BOOL recruiting;	// YES=发送招募协议，未返回
}

@property (nonatomic) int currentRoleId;
@property (nonatomic, assign) CCLabelTTF *nameLabel;
@property (nonatomic, assign) CCLabelTTF *jobLabel;
@property (nonatomic, assign) CCLabelTTF *skillLabel;
@property (nonatomic, assign) id<RecruitPanelDelegate> delegate;

-(void)setScroll:(float)scrollValue;
-(void)updateByRoleId:(int)rid;
-(void)getRoleTapped;
-(void)getRoleAgainTapped;

@end

@interface RecruitPanel : WindowComponent <RecruitPanelDelegate>
{
    RecruitRoleList *recruitRoleList;
    RecruitRoleDetail *recruitRoleDetail;
}

@end
