//
//  ExchangePanel.h
//  TXSFGame
//
//  Created by efun on 13-3-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import	"cocos2d.h"
#import "WindowComponent.h"

@class ExchangeDetail;
@class ButtonGroup;
@class CCSimpleButton;

@interface ExchangeManager : CCLayer
{
	UITouch *scrollTouch_;
	CGPoint touchSwipe_;
	CGPoint layerSwipe_;
	CGFloat minimumTouchLengthToSlide_;
	int state_;
	
	CCLayer *_canvas;
	
	float moveDis;
}

-(id)initWithSize:(CGSize)size;
-(void)setContentLayer:(CCLayer *)layer;

@end

@interface ExchangePanel : WindowComponent
{
	CCSimpleButton *buyButton;
	ExchangeDetail *exchangeDetail;
	
//	int selectGoodsId;
	NSMutableArray * goodsList;
	NSMutableArray * itemList;
}

@property (nonatomic) int selectGoodsId;

@end
