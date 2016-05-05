//
//  FishBait.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "BuyPanel.h"
#import "Window.h"
#import "ShowItem.h"

typedef enum {
	BaitType_white	= 1,	// 白色
	BaitType_green	=35,	// 绿色
	BaitType_blue	=36,	// 蓝色
	BaitType_purple =37,	// 紫色
} BaitType;

@protocol FishBaitDelegate <NSObject>
@optional
-(void)selectBait:(ItemQuality)_quality;

@end

@interface FishBaitItem : CCLayer <BuyDelegate>
{
	int iid;
	int count;
	CCLabelTTF *countLabel;
	CCSprite *selectedIcon;
	
	int batchMaxCount;
}

@property (nonatomic, assign) id<FishBaitDelegate> delegate;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) int quality;

-(void)showWithQuality:(ItemQuality)_quality count:(int)_count;

@end

@interface FishBait : CCLayer <FishBaitDelegate>
{
	id  target;
	SEL selectCall;
	ItemQuality quality;
	NSMutableArray *items;
	
	int whiteNum;
	
	// 是否批量钓鱼
	CCSimpleButton *selectBatchFish;
	CCSprite *batchFishTips;
	
	int batchMaxCount;
}
@property(nonatomic,assign)id target;
@property(nonatomic,assign)SEL selectCall;

+(void)show:(id)_target call:(SEL)_selectCall;
+(void)stopAll;

@end
