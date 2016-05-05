//
//  MiningManager.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSimpleButton.h"

typedef enum{
	Collect_wait =  0 ,
	Collect_doing = 1 ,
}Collect_Action;

@interface MiningManager : CCLayer {
	BOOL isBatch;
	BOOL isShieid;
	BOOL isRecordIngot;
	BOOL isRecordBatchIngot;
	NSMutableArray* stones;
	int  cost;
	int  ingot;
	Collect_Action m_Step;
	BOOL bStartCollect;
	CCSimpleButton *back;
	
	int tapCorrect;//双倍区正确点击次数
	int tapCorrect3;//三倍区
	int tapCorrect5;//五倍区
	int tapRemain;//剩余点击次数
	int tapTotal;//总点击次数
	float tapScrollLength;//滚动条长度
	float tapLastPer;//最后一次点击的百分比
	float tapCooling;//点击冷却百分比
	float tapCurStart;//当前点击开始点
	float tapCurLength;//当前点击长度
	NSMutableArray *tapRatio;//点击比率
	NSArray *tapRange;//点击区域范围
	NSArray *tapLength;//点击区域长度
	
	BOOL isCanExit;
}
+(MiningManager*)shared;
+(void)stopAll;
+(BOOL)isMining;

+(void)enterMining;
+(void)quitMining;
+(void)checkStatus;
+(BOOL)checkCanEnter;

-(void)tapOnce;
+(BOOL)isShowLoading;

@end


