//
//  BuyPanel.h
//  TXSFGame
//
//  Created by efun on 13-1-10.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "StretchingImg.h"
#import "Config.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "GameMoney.h"
#import "GameConnection.h"
#import "MessageAlert.h"
#import "ShowItem.h"

@class BuyPanel;

typedef enum {
	Buy_Btn_Confirm,
	Buy_Btn_Cancel
} Buy_Btn_Tag;

@protocol BuyDelegate <NSObject>
@optional
-(void)buySuccess:(BuyPanel*)_buyPanel;		// 成功购买后回调
//-(void)buyConfirm:(BuyPanel*)_buyPanel;
-(void)buyCancel:(BuyPanel*)_buyPanel;
@end

@interface BuyPanel : CCLayer <UITextFieldDelegate>
{
	NSObject<BuyDelegate> *_delegate;
	int cost;	// 单个花费
	CCLabelFX *countLabel;
	
	UITextField *countInput;
	
	NSMutableArray *menuItemRects;
}

@property (nonatomic) int itemCount;
@property (nonatomic) int itemId;
@property (nonatomic, assign) NSObject<BuyDelegate> *delegate;
@property (nonatomic, assign) GameMoney *gameMoney;

+(void)create:(id)targer itemId:(int)iid count:(int)count;
-(void)setItemCount:(int)_itemCount;
-(void)remove;

@end
