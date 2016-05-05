//
//  InfoAlert.h
//  TXSFGame
//
//  Created by efun on 13-1-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"
#import "Window.h"
#import "StretchingImg.h"
//fix chao
#define FULL_WINDOW_RULE_OFF_X (270)
#define FULL_WINDOW_RULE_OFF_X2 (80)
#define FULL_WINDOW_RULE_OFF_Y (30)
#define WINDOW_RULE_OFF_X (60)
#define WINDOW_RULE_OFF_Y (0)
//end
@class InfoAlert;

typedef enum {
	InfoAlertSite_none,		    // 无设定(默认)
	InfoAlertSite_parentCenter,	// 父类中心
	InfoAlertSite_screenCenter,	// 屏幕中心
} InfoAlertSite;

@protocol InfoAlertDelegate <NSObject>
@optional
-(void)onInfoAlertEnter:(InfoAlert *)infoAlert;		// 如果要手动画内容，实现此方法
-(void)onInfoAlertExit:(InfoAlert *)infoAlert;		// 退出时执行方法
@end

@interface InfoAlert : CCLayer <CCTouchOneByOneDelegate>
{
	int countdown;
	InfoAlertSite site;
	CGPoint position;
	CGPoint anchorPoint;
	CCNode *parent;
	NSObject<InfoAlertDelegate> *_delegate;
}
@property(nonatomic, retain) NSObject <InfoAlertDelegate> *delegate;
@property(nonatomic, retain) CCLabelTTF *countdownLabel;

// anchorPoint默认ccp(0,0)
// 屏幕居中
+(void)show:(id)t drawSprite:(CCSprite *)d;
// 父类居中
+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p;
// 自定义位置
+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos;
+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an;
+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an offset:(CGSize)o;

@end

@interface RuleButton : CCSimpleButton
{
	NSString *name;
	ccColor3B color;
	int size;
	RuleType type;
	
    RuleModelType ruleModel;
	// 详细规则
	float ruleWidth;
	CGPoint ruleAnchorPoint;
	CGPoint rulePosition;
	CCNode *ruleParent;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic) ccColor3B color;
@property (nonatomic) int size;
@property (nonatomic) RuleType type;// 需要赋值
@property (nonatomic) RuleModelType ruleModel;

@property (nonatomic) float ruleWidth;
@property (nonatomic) CGPoint ruleAnchorPoint;
@property (nonatomic) CGPoint rulePosition;
@property (nonatomic, retain) CCNode *ruleParent;

@end
