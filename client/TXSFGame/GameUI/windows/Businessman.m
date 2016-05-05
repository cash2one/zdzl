//
//  Businessman.m
//  TXSFGame
//
//  Created by efun on 13-1-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "Businessman.h"
#import "GameMoney.h"
#import "InfoAlert.h"
#import "ButtonGroup.h"
#import "AlertManager.h"
#import "GameDB.h"


#define GOODS_COUNT		6
#define BUY_INFO_COUNT	18
static BOOL s_isBusinessmanTouch = NO;

@interface GoodsItem : CCLayer
{
	int cost;
	int goodId;
	GameMoneyType type;
	CCSimpleButton *button;
	Businessman_show_type goodType;
	Businessman* _delegate;
	GoodType gType;
	int		 goodInfoId;
}
@property(nonatomic,assign)Businessman_show_type goodType;
@property(nonatomic,assign)Businessman* delegate;
@end

@implementation GoodsItem

@synthesize goodType ;
@synthesize delegate = _delegate;

/*
 * gid 神秘商人表数据，没有时为0
 * fid 如果是命格为命格id，普通物品为0
 */
-(id)initWithGoodsId:(int)gid fateId:(int)fid
{
	if (self = [super init]) {		
		CCSprite *bg = nil;
		if (iPhoneRuningOnGame()) {
			bg=[CCSprite spriteWithFile:@"images/ui/wback/p27.png"];
		}else{
			bg=[CCSprite spriteWithFile:@"images/ui/panel/p27.png"];
		}
		bg.anchorPoint = CGPointZero;
		self.contentSize = bg.contentSize;
		[self addChild:bg];
		
		CCSprite *goodsBg = [CCSprite spriteWithFile:@"images/ui/panel/itemNull.png"];
		if (iPhoneRuningOnGame()) {
			goodsBg.position =ccp(89/2.0f,156/2.0f);
		}else{
			goodsBg.position =ccp(75,115);
		}
		[self addChild:goodsBg];
		
		// 物品
		if (gid != 0) {
			
			//商品ID
			goodId = gid ;
			
			NSDictionary *goodsDict = [[GameDB shared] getShopInfo:gid];
			if (goodsDict) {
				int count = [[goodsDict objectForKey:@"c"] intValue];
				cost = [[goodsDict objectForKey:@"coin3"] intValue];
				if (cost > 0) {
					type = GAMEMONEY_YUANBAO_ONE;
				} else {
					cost = [[goodsDict objectForKey:@"coin1"] intValue];
					type = GAMEMONEY_YIBI;
				}
				
				NSDictionary *dict = nil;
				CCSprite *sprite = nil;
				if (fid == 0) {
					int iid =[[goodsDict objectForKey:@"iid"] intValue];
					dict = [[GameDB shared] getItemInfo:iid];
					sprite = getItemIcon(iid);
					gType = GoodType_item;
					goodInfoId = iid;
				} else {
					dict = [[GameDB shared] getFateInfo:fid];
					
					FateIconViewerContent * icon = [FateIconViewerContent create:fid];
					icon.quality = [[dict objectForKey:@"quality"] intValue];
					
					sprite = icon;
					
					gType = GoodType_fate;
					goodInfoId = fid;
				}
				if (dict) {
					NSString *name = [dict objectForKey:@"name"];
					ItemQuality quality = [[dict objectForKey:@"quality"] intValue];
					CCSprite *goodsInfo = nil;
					float fontSize=14;
					float lineH=18;
					if (iPhoneRuningOnGame()) {
						fontSize=22;
						lineH=24;
					}
					goodsInfo = drawString([NSString stringWithFormat:@"|%@%@|x%d", name, getHexColorByQuality(quality), count], CGSizeMake(150, 0), getCommonFontName(FONT_1), fontSize, lineH, @"#EBE2D0");
					if(iPhoneRuningOnGame()){
						goodsInfo.position = ccp(82/2.0f, 90/2.0f);
					}else{
						goodsInfo.position = ccp(75, 63);
					}
					
					CCSprite *costIcon = [CCSprite spriteWithFile:getImagePath(type)];
					costIcon.anchorPoint = ccp(0, 0.5);
					
					CCSprite *goodsCost = nil;
					
					goodsCost = drawString([NSString stringWithFormat:@"%d", cost], CGSizeMake(150, 0), getCommonFontName(FONT_1), fontSize, lineH, @"#EBE2D0");
					
					goodsCost.anchorPoint = ccp(1, 0.5);
                    
					float distance = 3;	// 图标，数字间隔
					float width = goodsCost.contentSize.width+distance+costIcon.contentSize.width;
					float height = costIcon.contentSize.height;
					
					CCSprite *costInfo = [CCSprite node];
					costInfo.contentSize = CGSizeMake(width, height);
                    if (iPhoneRuningOnGame()) {
						costInfo.position =ccp(82/2.0f,60/2.0f);
					}else{
						costInfo.position =ccp(75,42);
					}
					
					costIcon.position = ccp(0, height/2.0f);
					[costInfo addChild:costIcon];
					goodsCost.position = ccp(width, height/2.0f);
					[costInfo addChild:goodsCost];
					
					[self addChild:goodsInfo];
					[self addChild:costInfo];
				}
				if (sprite) {
					if (iPhoneRuningOnGame()) {
						sprite.position =ccp(89/2.0f, 156/2.0f);
					}else{
						sprite.position =ccp(75, 115);
					}
					[self addChild:sprite];
				}
			}
			if (iPhoneRuningOnGame()) {
				button = [CCSimpleButton spriteWithFile:@"images/ui/wback/bts_buy_1.png" select:@"images/ui/wback/bts_buy_2.png" target:self call:@selector(buyTapped:)];
				button.scaleY=1.1f;
				button.scaleX=1.3f;
			}else{
				button = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_buy_1.png" select:@"images/ui/button/bts_buy_2.png" target:self call:@selector(buyTapped:)];
			}
			
			button.tag = gid;
		}
		// 没有物品，灰色按钮
		else {
			if (iPhoneRuningOnGame()) {
				button = [CCSimpleButton spriteWithFile:@"images/ui/wback/bts_buy_3.png" select:@"images/ui/wback/bts_buy_3.png" target:self call:@selector(buyTapped:)];
				button.scaleY=1.1f;
				button.scaleX=1.3f;
				
			}else{
				button = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_buy_3.png" select:@"images/ui/button/bts_buy_3.png" target:self call:@selector(buyTapped:)];
			}
			button.tag = gid;
		}
		if (button) {
			if (iPhoneRuningOnGame()) {
				button.position =ccp(90/2.0f, 25/2.0f);
			}else{
				button.position =ccp(76, 20);
			}
			[self addChild:button];
		}
	}
	return self;
}

-(id)initWithGoodsId:(int)gid
{
	return [self initWithGoodsId:gid fateId:0];
}

-(void)setDisable
{
	if (button) {
		button = nil;
	}
	if (iPhoneRuningOnGame()) {
		button = [CCSimpleButton spriteWithFile:@"images/ui/wback/bts_buy_3.png" select:@"images/ui/wback/bts_buy_3.png" target:self call:@selector(buyTapped:)];
		button.scaleY=1.1f;
		button.scaleX=1.3f;
		
	}else{
		button = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_buy_3.png" select:@"images/ui/button/bts_buy_3.png" target:self call:@selector(buyTapped:)];
	}
	button.tag = 0;
	if (iPhoneRuningOnGame()) {
		button.position = ccp(90/2.0f, 25/2.0f);
	}else{
		button.position = ccp(76, 20);
	}
	[self addChild:button];
}

-(void)buyTapped:(id)sender
{
    if (s_isBusinessmanTouch) {
        return;
    }
    if (_delegate) {
        if ([_delegate showType] != goodType) {
            return;
        }
        [_delegate setButtonTouchWithBOOL:YES];
    }else{
        CCLOG(@"delegate is null");
        return;
    }
    
    
	CCNode *node = sender;
	int tag = node.tag;
	if (tag == 0) {
		return;
	}
	// 银币
	if (type == GAMEMONEY_YIBI) {
		if (cost > [[GameConfigure shared] getPlayerMoney]) {
			//[ShowItem showItemAct:@"银币不足"];
            [ShowItem showItemAct:NSLocalizedString(@"businessman_no_yinbi",nil)];
            [_delegate setButtonTouchWithBOOL:NO];
			return;
		} else {
			[self doShopBuy];
		}
	}
	// 元宝
	else {
		int coin2 = [[GameConfigure shared] getPlayerCoin2];
		int coin3 = [[GameConfigure shared] getPlayerCoin3];
		if (cost > coin2 + coin3) {
			//[ShowItem showItemAct:@"元宝不足"];
            [ShowItem showItemAct:NSLocalizedString(@"businessman_no_yuanbao",nil)];
            [_delegate setButtonTouchWithBOOL:NO];
			return;
		} else {
			BOOL isShopGold = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_SHOP_GOLD] boolValue];
			if (isShopGold) {
				[self doShopBuy];
			} else {
                
				[[AlertManager shared] showGoodMessage:[NSString stringWithFormat:NSLocalizedString(@"businessman_yuanbao_buy",nil), cost]
												  type:gType
												  good:goodInfoId
												target:self
											   confirm:@selector(doShopBuy)
												 canel:@selector(doCancelShopBuy)
												   key:NO_REMIND_SHOP_GOLD
												  tips:NSLocalizedString(@"alert_no_awake",nil)
												father:self.parent];
			}
		}
	}
}

-(void)doCancelShopBuy{
	CCLOG(@"doCancelShopBuy");
    if (_delegate) {
        [_delegate setButtonTouchWithBOOL:NO];
    }else{
        CCLOG(@"delegate is null");
    }
}

-(void)doShopBuy
{
	if (button) {
		int tag = button.tag;
		NSString *sid = [NSString stringWithFormat:@"sid::%d|t::%d", tag,goodType];
		[GameConnection request:@"shopBuy" format:sid target:self call:@selector(didShopBuy:)];
	}else{
        if (_delegate) {
            [_delegate setButtonTouchWithBOOL:NO];
        }else{
            CCLOG(@"delegate is null");
        }
    }
}

-(void)didShopBuy:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			if (_delegate) {
				[_delegate successfulBuy:goodId type:goodType];
			}
			
			// 成功购买，设置按钮灰色
			if (goodType == Businessman_show_2) {
				[self setDisable];
			}
			
			[[GameConfigure shared] updatePackage:dict];
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
    //
    if (_delegate) {
        [_delegate setButtonTouchWithBOOL:NO];
    }else{
        CCLOG(@"delegate is null");
    }
}

-(void)onExit
{
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end

//iphone for chenjunming

@implementation Businessman

@synthesize showType;

-(id)init{
	if ((self = [super init]) != nil) {
		goodsHelper = [NSMutableDictionary dictionary];
		[goodsHelper retain];
	}
	return self;
}

-(void)dealloc{
	if (goodsHelper) {
		[goodsHelper release];
		goodsHelper = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	s_isBusinessmanTouch = NO;
    
	self.touchEnabled = YES;
	self.touchPriority = -1;
    
	MessageBox *box1 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	[self addChild:box1];
	MessageBox *box2 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	[self addChild:box2];
    if (iPhoneRuningOnGame()) {
		box1.contentSize = CGSizeMake(591/2.0f, 546/2.0f);
		box1.position = ccp(12/2.0f+44, 33/2.0f);
		box2.contentSize = CGSizeMake(330/2.0f, 546/2.0f);
		box2.position = ccp(616/2.0f+44, 33/2.0f);
    }else{
        box1.contentSize = CGSizeMake(486, 421);
        box1.position = ccp(25, 19);
        box2.contentSize = CGSizeMake(330, 421);
        box2.position = ccp(518, 19);
    }
	
	float width=470;
    float width2=314;
    if (iPhoneRuningOnGame()) {
		width=565/2.0f;
		width2=315/2.0f;
    }
	CCSprite *shopTitle1 = [self getTitleBackground:NSLocalizedString(@"businessman_flash_item",nil) width:width];
    
    if (iPhoneRuningOnGame()) {
		shopTitle1.position = ccp(307/2.0f+44, 550/2.0f);
    }else{
		shopTitle1.position = ccp(268.5, 421);
    }
	[self addChild:shopTitle1];
	
	//手气榜 679423
    CCSprite *shopTitle2 = [self getTitleBackground:NSLocalizedString(@"businessman_luck_rank",nil) width:width2];
    if (iPhoneRuningOnGame()) {
		shopTitle2.position = ccp(781/2.0f+44, 550/2.0f);
    }else{
        shopTitle2.position = ccp(683.5, 421);
    }
	shopTitle2.tag = 679423;
	[self addChild:shopTitle2];
	
	//珍稀榜 679424
	CCSprite *shopTitle22 = [self getTitleBackground:NSLocalizedString(@"businessman_rare_rank",nil) width:width2];
    if (iPhoneRuningOnGame()) {
		shopTitle22.position = ccp(781/2.0f+44, 550/2.0f);
    }else{
        shopTitle22.position = ccp(683.5, 421);
    }
	shopTitle22.tag = 679424;
	[self addChild:shopTitle22];
	
    
//	float fontSize=14;
//	
//	if (iPhoneRuningOnGame()) {
//		fontSize=9;
//	}
	
//    CCLabelTTF *refreshLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"businessman_flash_time",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
//	refreshLabel.anchorPoint = ccp(0, 0.5);
//    if (iPhoneRuningOnGame()) {
//		refreshLabel.position =ccp(20/2.0f+44, 47/2.0f);
//    }else{
//        refreshLabel.position =ccp(38, 38);
//    }
//	refreshLabel.color = ccc3(171, 147, 108);
//	[self addChild:refreshLabel];
	
	goodsArray = [NSMutableArray array];
	[goodsArray retain];
	
	[self showShopTab];
	
}
-(void)setButtonTouchWithBOOL:(BOOL)isTouch{
    ButtonGroup *_buttons = (ButtonGroup *)[self getChildByTag:6666];
    if (_buttons) {
        //[_buttons setTouchEnabled:(!isTouch)];
    }
    s_isBusinessmanTouch = isTouch;
}
-(void)doSelected:(CCMenuItem*)_item{
	if (_item) {
        if (s_isBusinessmanTouch) {
            ButtonGroup *_buttons = (ButtonGroup *)[self getChildByTag:6666];
            if (_buttons) {
                if (showType == Businessman_show_1) {
                    CCMenuItem* selectItem = (CCMenuItem*)[_buttons getChildByTag:100];
                    if (selectItem) {
                        [_buttons setSelectedItem:selectItem];
                    }
                }else if(showType == Businessman_show_2){
                    CCMenuItem* selectItem = (CCMenuItem*)[_buttons getChildByTag:200];
                    if (selectItem) {
                        [_buttons setSelectedItem:selectItem];
                    }
                }
            }
            return;
        }
        [self setButtonTouchWithBOOL:YES];
        //
		int _myType = _item.tag/100;
		[self updateContent:_myType];
	}
}

-(CCSprite *)getTitleBackground:(NSString*)title width:(float)width
{
	CCSprite *titleBg = [CCSprite node];
	if (iPhoneRuningOnGame()) {
		titleBg.contentSize =CGSizeMake(width, 33/2.0f);
	}else{
		titleBg.contentSize =CGSizeMake(width, 20);
	}
	CCSprite *titleBg1 = [CCSprite spriteWithFile:@"images/ui/panel/t60.png"];
	CCSprite *titleBg2 = [CCSprite spriteWithFile:@"images/ui/panel/t61.png"];
	CCSprite *titleBg3 = [CCSprite spriteWithFile:@"images/ui/panel/t62.png"];
	titleBg1.anchorPoint = ccp(0, 0);
	[titleBg addChild:titleBg1];
	titleBg2.scaleX = (width+1-titleBg1.contentSize.width-titleBg3.contentSize.width) / titleBg2.contentSize.width;
	
	titleBg2.anchorPoint = ccp(0, 0);
	titleBg2.position = ccp(titleBg1.contentSize.width-0.5, 0);
	[titleBg addChild:titleBg2];
	titleBg3.anchorPoint = ccp(1, 0);
	titleBg3.position = ccp(width, 0);
	[titleBg addChild:titleBg3];
	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
		titleBg1.scaleY=1.6f;
		titleBg2.scaleY=titleBg1.scaleY;
		titleBg3.scaleY=titleBg1.scaleY;
	}
	
	CCLabelTTF *label = [CCLabelTTF labelWithString:title fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	label.color = ccc3(48, 18, 7);
	label.position = ccp(titleBg.contentSize.width/2,
						 titleBg.contentSize.height/2);
	[titleBg addChild:label];
	
	return titleBg;
}

#pragma mark -

-(void)showShopTab{
	ButtonGroup *_buttons =[ButtonGroup node];
	
	[_buttons setTouchPriority:-110];
	[self addChild:_buttons z:99 tag:6666];
	
	
	NSArray *sprArr = getLabelSprites(@"images/ui/panel/t25.png",
									  @"images/ui/panel/t24.png",
									  NSLocalizedString(@"businessman_show_type_1",nil),
									  cFixedScale(16),
									  ccc4(169, 156, 124,255),
									  ccc4(235, 229, 206,255) );
	
	if (sprArr && sprArr.count == 2) {
		CCMenuItem* item1 = [CCMenuItemImage itemWithNormalSprite:[sprArr objectAtIndex:0]
												   selectedSprite:[sprArr objectAtIndex:1]
														   target:self selector:@selector(doSelected:)];
		[_buttons addChild:item1 z:10 tag:100];
	}
	
	sprArr = nil ;
	
	sprArr = getLabelSprites(@"images/ui/panel/t25.png",
							 @"images/ui/panel/t24.png",
							 NSLocalizedString(@"businessman_show_type_2",nil),
							 cFixedScale(16),
							 ccc4(169, 156, 124,255),
							 ccc4(235, 229, 206,255) );
	
	if (sprArr &&  sprArr.count == 2) {
		CCMenuItem* item1 = [CCMenuItemImage itemWithNormalSprite:[sprArr objectAtIndex:0]
												   selectedSprite:[sprArr objectAtIndex:1]
														   target:self selector:@selector(doSelected:)];
		[_buttons addChild:item1 z:10 tag:200];
	}
	
	[_buttons alignItemsHorizontallyWithPadding:4];
	
	
	if (iPhoneRuningOnGame()) {
		_buttons.position = ccp(12/2.0f+46, 33/2.0f + 546/2.0f);
    }else{
        _buttons.position = ccp(28, 440);
    }
	
	CCMenuItem* selectItem = (CCMenuItem*)[_buttons getChildByTag:100];
	if (selectItem) {
		[_buttons setSelectedItem:selectItem];
	}
	
}

-(void)showContentWith:(NSDictionary*)dict type:_type{
	if (dict) {
		NSDictionary *retDict = [dict objectForKey:@"ret"];
		if (retDict) {
			[self setGoodsWithDictionary:retDict type:_type];
		}
		[self showPurchaseHistory:dict];
	}
}

-(void)showOther:(NSDictionary*)info type:(Businessman_show_type)_type{
	CCNode* n1 = [self getChildByTag:679424];
	CCNode* n2 = [self getChildByTag:679423];
	if (_type == Businessman_show_1) {
		if (n1 != nil){
			n1.visible = YES;
		}
		if (n2 != nil){
			n2.visible = NO;
		}
	}else if (_type == Businessman_show_2){
		if (n1 != nil){
			n1.visible = NO;
		}
		if (n2 != nil){
			n2.visible = YES;
		}
	}else{
		if (n1 != nil){
			n1.visible = NO;
		}
		if (n2 != nil){
			n2.visible = NO;
		}
	}
	
	[self removeChildByTag:564321 cleanup:YES];
	[self removeChildByTag:564322 cleanup:YES];
	
	if (_type == Businessman_show_2) {
		CCSimpleButton* button = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_refresh_shop_1.png"
														 select:@"images/ui/button/bt_refresh_shop_2.png"
														 target:self
														   call:@selector(refreshContent)
													   priority:-2];
		if (button != nil) {
			button.anchorPoint = ccp(1.0, 0.5);
			if (iPhoneRuningOnGame()) {
				button.position =ccp(20/2.0f + 30 + 591/2.0f, 47/2.0f);
			}else{
				button.position =ccp(38 + 486 - 20, 38);
			}
			[self addChild:button z:10 tag:564321];
		}
		//--------------------------------------------------------------
//		float fontSize=14;
//		
//		if (iPhoneRuningOnGame()) {
//			fontSize=9;
//		}
		
		int times = [[info objectForKey:@"rn"] intValue];
		NSString *buyInfo = [NSString stringWithFormat:NSLocalizedString(@"businessman_flash_remain_time",nil),times];
		CCSprite* spr = drawString(buyInfo, CGSizeMake(150, 30),
								   getCommonFontName(FONT_1), 14, 18,
								   getHexStringWithColor3B(ccc3(171, 147, 108)));
		spr.anchorPoint = ccp(1.0, 0.5);
		spr.position = ccpAdd(button.position, ccp(-cFixedScale(80), 0));
		[self addChild:spr z:10 tag:564322];
		
	}
}

-(void)refreshContent{
    if (s_isBusinessmanTouch || showType != Businessman_show_2) {
        return;
    }
    [self setButtonTouchWithBOOL:YES];
    
	CCLOG(@"refreshContent");
	NSDictionary* showInfo = [self getGoodsWith:Businessman_show_2];
	if (showInfo) {
		int times = [[showInfo objectForKey:@"rn"] intValue];
		if (times > 0) {
			NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
			int coin = [[globalConfig objectForKey:@"shopResetCost"] intValue];
            BOOL isShopGold = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_SHOP_RESET_GOLD] boolValue];
			if (isShopGold) {
				[self doSelectOk];
			} else {
                [[AlertManager shared] showMessageWithSettingFormFather:[NSString stringWithFormat:NSLocalizedString(@"businessman_spend",nil), coin]
															 target:self
															confirm:@selector(doSelectOk)
                                                              canel:@selector(doSelectNo)
																key:NO_REMIND_SHOP_RESET_GOLD
															 father:self.parent];
            }
		}else{
			[ShowItem showItemAct:NSLocalizedString(@"time_box_no_reset_count",nil)];
            [self setButtonTouchWithBOOL:NO];
		}
	}
}

-(void)doSelectOk{
	CCLOG(@"doSelectOk");
	[GameConnection request:@"resetShop" format:@"" target:self call:@selector(didRefreshContent:)];
}
-(void)doSelectNo{
	CCLOG(@"doSelectNo");
    [self setButtonTouchWithBOOL:NO];
}

-(void)didRefreshContent:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			NSDictionary *update = [dict objectForKey:@"up"];
			if (update) {
				// 显示更新的物品
				NSArray *updateData = [[GameConfigure shared] getPackageAddData:update];
				[[AlertManager shared] showReceiveItemWithArray:updateData];
				
				[[GameConfigure shared] updatePackage:update];
			}
			
			[goodsHelper setObject:dict forKey:[NSString stringWithFormat:@"%d",Businessman_show_2]];
			[self updateContent:Businessman_show_2];
		}
	}
    //
    [self setButtonTouchWithBOOL:NO];
}

-(void)updateContent:(Businessman_show_type)_type{
    //
    showType = _type;
    //
	NSDictionary* showInfo = [self getGoodsWith:_type];
	if (showInfo != nil) {
		[self showContentWith:showInfo type:_type];
		[self showOther:showInfo type:_type];
        //
        [self setButtonTouchWithBOOL:NO];
	}else{
		[self getData:_type];
	}

}

-(NSDictionary*)getGoodsWith:(Businessman_show_type)_type{
	if (goodsHelper) {
		return [goodsHelper objectForKey:[NSString stringWithFormat:@"%d",_type]];
	}
	return nil;
}

-(void)getData:(Businessman_show_type)_type{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:_type] forKey:@"t"];
	[GameConnection request:@"shop" data:dict target:self call:@selector(didGetServerData:arg:) arg:dict];
}

-(void)didGetServerData:(NSDictionary*)sender arg:(NSDictionary*)arg{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			int __type = [[arg objectForKey:@"t"] intValue];
			[goodsHelper setObject:dict forKey:[NSString stringWithFormat:@"%d",__type]];
			[self updateContent:__type];
		}
	}
    //
    [self setButtonTouchWithBOOL:NO];
}

#pragma mark

-(void)showPurchaseHistory:(NSDictionary*)dict{
	if (dict == nil) {
		return ;
	}
	[self removeChildByTag:59595 cleanup:YES];
	NSArray *latelys = [dict objectForKey:@"lately"];
	if (latelys && latelys.count > 0) {
		CGSize panelSize;
		if (iPhoneRuningOnGame()) {
			panelSize =CGSizeMake(308, 480);
		}else{
			panelSize =CGSizeMake(308, 378);
		}
		CCLayer *layer = [[[CCLayer alloc] init] autorelease];
		
		int startY = 0;
		for (int i = 0; i < latelys.count && i < BUY_INFO_COUNT; i++) {
			NSDictionary *lately = [latelys objectAtIndex:i];
			NSString *playerName = [lately objectForKey:@"name"];
			
			int iid = [[lately objectForKey:@"iid"] intValue];
			NSDictionary *itemDict = nil;
			
			int type = [[lately objectForKey:@"t"] intValue];
			if (type == 1) {
				itemDict = [[GameDB shared] getItemInfo:iid];
			} else if (type == 2) {
				itemDict = [[GameDB shared] getFateInfo:iid];
			}
			
			if (itemDict) {
				NSString *itemName = [itemDict objectForKey:@"name"];
				ItemQuality quality = [[itemDict objectForKey:@"quality"] intValue];
				//NSString *buyInfo = [NSString stringWithFormat:@"|【%@】#FEFF3B|刚购买了|【%@】%@|", playerName, itemName, getHexColorByQuality(quality)];
				NSString *buyInfo = [NSString stringWithFormat:NSLocalizedString(@"businessman_buying",nil), playerName, itemName, getHexColorByQuality(quality)];
				
				CCSprite *buySprite = nil;
				if(iPhoneRuningOnGame()){
					buySprite = drawString(buyInfo, CGSizeMake(panelSize.width, 0), getCommonFontName(FONT_1), 18, 21, @"#FFFFFF");
				}else{
					buySprite = drawString(buyInfo, CGSizeMake(panelSize.width, 0), getCommonFontName(FONT_1), 16, 21, @"#FFFFFF");
				}
				
				buySprite.anchorPoint = CGPointZero;
				buySprite.position = ccp(0, startY);
				[layer addChild:buySprite];
				startY += buySprite.contentSize.height;
				if (startY >= panelSize.height) {
					break;
				}
			}
		}
		if (iPhoneRuningOnGame()) {
			panelSize =CGSizeMake(308/2.0f, 488/2.0f);
		}
		layer.contentSize = CGSizeMake(panelSize.width, MAX(panelSize.height, startY));
		
		CCPanel *panel = [CCPanel panelWithContent:layer viewSize:panelSize];
		if (iPhoneRuningOnGame()) {
			panel.position =ccp(715/2.0f, 40/2.0f);
		}else{
			panel.position =ccp(525, 27);
		}
		[self addChild:panel z:10 tag:59595];
	}
}

-(void)setGoodsWithDictionary:(NSDictionary *)dict type:(int)_type
{
	//删除之前数据
	if (goodsArray) {
		for (GoodsItem *goodsItem in goodsArray) {
			[goodsItem removeFromParentAndCleanup:YES];
			goodsItem = nil;
		}
		[goodsArray removeAllObjects];
	}
	
	NSArray *sids = [dict objectForKey:@"sids"];
	NSDictionary *fids = [dict objectForKey:@"fids"];
	
	CGPoint	orginPoint = ccp(35, 61);
	
	float offsetX = 158;
	float offsetY = 173.5;
	if (iPhoneRuningOnGame()) {
		offsetX = 158.0/2.0f+13;
		offsetY = 173.5/2.0f+30;
		orginPoint=ccp(124.0/2.0f, 70/2.0f);
	}
	
	for (int i = 0; i < GOODS_COUNT; i++) {
		CGPoint finalPoint = ccp(orginPoint.x+i%3*offsetX, orginPoint.y+(i/3)*offsetY);
		int _id = i < sids.count ? [[sids objectAtIndex:i] intValue] : 0;
		int _fid = 0;
		if (_id != 0) {
			NSString *key = [NSString stringWithFormat:@"%d", _id];
			if ([[fids allKeys] containsObject:key]) {
				_fid = [[fids objectForKey:key] intValue];
			}
		}
		GoodsItem *goodsItem = [[[GoodsItem alloc] initWithGoodsId:_id fateId:_fid] autorelease];
		goodsItem.position = finalPoint;
		goodsItem.goodType = _type ;
		goodsItem.delegate = self;
		
		[self addChild:goodsItem];
		[goodsArray addObject:goodsItem];
		
	}
}
-(void)successfulBuy:(int)_sid type:(int)_buyType{
	if (_buyType == Businessman_show_2) {
		NSMutableDictionary* goodInfo = [NSMutableDictionary dictionaryWithDictionary:[self getGoodsWith:_buyType]];
		NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithDictionary:[goodInfo objectForKey:@"ret"]];
		NSMutableArray *sids = [NSMutableArray arrayWithArray:[retDict objectForKey:@"sids"]];
		NSMutableDictionary *fids = [NSMutableDictionary dictionaryWithDictionary:[retDict objectForKey:@"fids"]];
		//删除
		for (NSNumber *number in sids) {
			if (_sid == [number intValue]) {
				[sids removeObject:number];
				break ;
			}
		}
		NSString *key = [NSString stringWithFormat:@"%d", _sid];
		if ([[fids allKeys] containsObject:key]) {
			[fids removeObjectForKey:key];
		}
		[retDict setObject:fids forKey:@"fids"];
		[retDict setObject:sids forKey:@"sids"];
		[goodInfo setObject:retDict forKey:@"ret"];
		[goodsHelper setObject:goodInfo forKey:[NSString stringWithFormat:@"%d",_buyType]];
	}
}
-(void)closeWindow{
    [self setButtonTouchWithBOOL:YES];
	[[Window shared] removeWindow:self.windowType];
}
-(void)onExit
{
	
	if (goodsArray) {
		[goodsArray removeAllObjects];
		[goodsArray release];
		goodsArray = nil ;
	}
	
	[GameConnection freeRequest:self];
	//
    s_isBusinessmanTouch = NO;
    
	[super onExit];
}

@end
