//
//  UnionTab.h
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"
#import "UnionConfig.h"
#import "UnionMember.h"
#import "UnionActivity.h"

@class UnionActivityItem;

// 动态
@interface UnionTrends : CCLayerColor
{
    int unionId;
    int personnelCount;
    int contribCount;
    CCLayer *listLayer;
    BOOL isSelectedPersonnel;
    BOOL isSelectedContrib;
    CCSprite *personnelSelectedDone;
    CCSprite *contribSelectedDone;
	
	CCPanel *trendsPanel;
}
@property (nonatomic, assign) CCPanel *trendsPanel;
@property (nonatomic, retain) NSMutableArray *trendsArray;
-(id)initWithUnionId:(int)uid;
@end

// 审核
@protocol UnionAuditDelegate <NSObject>
@optional
-(void)auditActionWithTarget:(id)target accept:(BOOL)isAccept;
@end

@interface UnionAuditItem : CCSprite
@property (nonatomic, assign) id<UnionAuditDelegate> delegate;
-(id)initWithUserId:(int)userId name:(NSString *)name level:(int)level rank:(int)rank;
@end

@interface UnionAudit : CCLayerColor <UnionAuditDelegate>
{
    int unionId;
    CCLayer *listLayer;
	
	CCPanel *auditPanel;
	
	NSMutableArray *auditArray;
	
}
@property (nonatomic, assign) CCPanel *auditPanel;
//@property (nonatomic, retain) NSMutableArray *auditArray;
-(id)initWithUnionId:(int)uid;
@end


// 同盟选项卡
@interface UnionTab : CCLayerColor
{
    int unionId;
    Tag_Union_Tab_Type tabType;
	NSMutableArray *tabItems;
}
@property (nonatomic, assign) UnionMember *unionMember;
@property (nonatomic, assign) UnionActivity *unionActivity;
@property (nonatomic, assign) UnionTrends *unionTrends;
@property (nonatomic, assign) UnionAudit *unionAudit;
-(id)initWithUnionId:(int)uid;
@end

