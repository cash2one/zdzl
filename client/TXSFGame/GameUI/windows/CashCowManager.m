//
//  CashCowManager.m
//  TXSFGame
//
//  Created by Soul on 13-5-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "CashCowManager.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "Config.h"
#import "Window.h"
#import "AlertManager.h"
#import "GameMoney.h"

#define CARDS_STEP_W (180)
#define CARDS_SPACE_W (30)
#define CASH_CARD_H (50)
#define CASH_FONT_SIZE (20)
//money
/*
typedef enum{
    CashMoneyType_1 = 0 ,//银币
    CashMoneyType_2 ,//真元宝
}CashMoneyType;

@interface CashMoney:CCSprite{
    CashMoneyType type;
    int value;
}
@property (nonatomic,assign) CashMoneyType type;
@property (nonatomic,assign) int value;
enum{
    CashMoney_text_tag = 23,
    CashMoney_money_tag,
    CashMoney_name_tag,
};
@end
@implementation CashMoney
@synthesize value;
@synthesize type;
-(id)init{
    if ((self = [super init])!=nil) {
        type = CashMoneyType_1;
        value = 0;
        self.contentSize = CGSizeMake(cFixedScale(CASH_FONT_SIZE*15), cFixedScale(20));
    }
    return self;
}
-(void)onEnter{
    [super onEnter];
    //
    [self setType:type];
    //
}
-(void)setType:(CashMoneyType)type_{
    type = type_;
    //
    CCSprite *moneySpr = nil;
    moneySpr = (CCSprite *)[self getChildByTag:CashMoney_money_tag];
    if (moneySpr) {
        [moneySpr removeFromParentAndCleanup:YES];
        moneySpr = nil;
    }
    if (type == CashMoneyType_1) {
        moneySpr = [CCSprite spriteWithFile:@"images/ui/object-icon/1.png"];
    }else{
        moneySpr = [CCSprite spriteWithFile:@"images/ui/object-icon/2.png"];
    }
    [self addChild:moneySpr];
    moneySpr.tag = CashMoney_money_tag;
    moneySpr.anchorPoint = ccp(0,0.5);
    moneySpr.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
    //
    if (moneySpr) {
        CCSprite *nameSpr = nil;
        nameSpr = (CCSprite *)[self getChildByTag:CashMoney_name_tag];
        if (nameSpr) {
            [nameSpr removeFromParentAndCleanup:YES];
            nameSpr = nil;
        }
        if (type == CashMoneyType_1) {
            nameSpr = drawString(NSLocalizedString(@"cash_cow_coin1",nil), CGSizeMake(200,0), getCommonFontName(FONT_1), cFixedScale(CASH_FONT_SIZE-1), cFixedScale(CASH_FONT_SIZE), @"#EBE2D0");
        }else{
            nameSpr = drawString(NSLocalizedString(@"cash_cow_coin2",nil), CGSizeMake(200,0), getCommonFontName(FONT_1), cFixedScale(CASH_FONT_SIZE-1), cFixedScale(CASH_FONT_SIZE), @"#EBE2D0");
        }
        [self addChild:nameSpr];
        nameSpr.tag = CashMoney_name_tag;
        nameSpr.anchorPoint = ccp(0,0.5);
        nameSpr.position = ccpAdd(moneySpr.position, ccp(moneySpr.contentSize.width,0));
    }
}
-(void)setValue:(int)value_{
    value = value_;
    CCSprite *spr_text = nil;
    spr_text = (CCSprite *)[self getChildByTag:CashMoney_text_tag];
    if (spr_text) {
        [spr_text removeFromParentAndCleanup:YES];
        spr_text = nil;
    }
    spr_text = drawString([NSString stringWithFormat:@"%d #ffff00",value], CGSizeMake(200,0), getCommonFontName(FONT_1), cFixedScale(CASH_FONT_SIZE-1), cFixedScale(CASH_FONT_SIZE), @"#EBE2D0");
    [self addChild:spr_text];
    spr_text.tag = CashMoney_text_tag;
    spr_text.anchorPoint = ccp(1,0.5);
    spr_text.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
}
@end
//end
*/
@implementation CashCard
enum{
    CashCard_bg_tag = 103,
    CashCard_button_1_tag ,
    CashCard_button_2_tag ,
    CashCard_button_3_tag ,
    //CashCard_label ,
    //
    CashCard_text_bg ,
    CashCard_text_change ,
    CashCard_text_coin1 ,
    CashCard_text_coin2 ,
};
@synthesize redeemType;
@synthesize isTouch;

-(id)init{
	if ((self = [super init]) != nil) {
		self.touchEvent = YES;
		self.contentSize = CGSizeMake(cFixedScale(CARDS_STEP_W-CARDS_SPACE_W), cFixedScale(CASH_CARD_H));
        coin1 = 0;//银币
        coin2 = 0;//元宝
        self.arg = self;
	}
	return self;
}
-(int)getBGSpriteWithType:(int)type_{
    CCSprite *bg_spr = [CCSprite spriteWithFile:@"images/ui/ctree/ctree_bg.jpg"];
    return bg_spr;
}

-(void)addTextSprite{
    CCSprite *bt_spr_bg = nil;
    bt_spr_bg = (CCSprite *)[self getChildByTag:CashCard_text_bg];
    if (bt_spr_bg) {
        [bt_spr_bg removeFromParentAndCleanup:YES];
        bt_spr_bg = nil;
    }
    bt_spr_bg = [CCSprite spriteWithFile:@"images/ui/car/select_bg.png"];
    if (bt_spr_bg) {
        [self addChild:bt_spr_bg];
        bt_spr_bg.tag = CashCard_text_bg;
        bt_spr_bg.position = ccp(self.contentSize.width/2,bt_spr_bg.contentSize.height*2.5);
    }
    //
    CCSprite *bt_spr_change = nil;
    bt_spr_change = (CCSprite *)[self getChildByTag:CashCard_text_change];
    if (bt_spr_change) {
        [bt_spr_change removeFromParentAndCleanup:YES];
        bt_spr_change = nil;
    }
    bt_spr_change = [CCSprite spriteWithFile:@"images/ui/ctree/ctree_change.png"];
    if (bt_spr_change && bt_spr_bg) {
        [self addChild:bt_spr_change];
        bt_spr_change.tag = CashCard_text_change;
        bt_spr_change.position = bt_spr_bg.position;
    }
    //
//    CashMoney *bt_spr_coin1 = nil;
//    bt_spr_coin1 = (CashMoney *)[self getChildByTag:CashCard_text_coin1];
//    if (bt_spr_coin1) {
//        [bt_spr_coin1 removeFromParentAndCleanup:YES];
//        bt_spr_coin1 = nil;
//    }
    GameMoney *bt_spr_coin1 = nil;
    bt_spr_coin1 = (GameMoney *)[self getChildByTag:CashCard_text_coin1];
    if (bt_spr_coin1) {
        [bt_spr_coin1 removeFromParentAndCleanup:YES];
        bt_spr_coin1 = nil;
    }
    bt_spr_coin1 = [GameMoney node];
    bt_spr_coin1.type = GAMEMONEY_YIBI;
    bt_spr_coin1.moneyValue = coin1;
    if (bt_spr_coin1 && bt_spr_bg && bt_spr_change) {
        [self addChild:bt_spr_coin1];
        bt_spr_coin1.tag = CashCard_text_coin1;
        bt_spr_coin1.position = ccpAdd(bt_spr_bg.position, ccp(bt_spr_coin1.contentSize.width/2+bt_spr_change.contentSize.width/2+bt_spr_coin1.contentSize.width/2,0)) ;
        bt_spr_coin1.visible = YES;
    }
    //
    GameMoney *bt_spr_coin2 = nil;
    bt_spr_coin2 = (GameMoney *)[self getChildByTag:CashCard_text_coin2];
    if (bt_spr_coin2) {
        [bt_spr_coin2 removeFromParentAndCleanup:YES];
        bt_spr_coin2 = nil;
    }
    bt_spr_coin2 = [GameMoney node];
    bt_spr_coin2.type = GAMEMONEY_YUANBAO_ONE;
    bt_spr_coin2.moneyValue = coin2;
    if (bt_spr_coin2 && bt_spr_bg && bt_spr_change) {
        [self addChild:bt_spr_coin2];
        bt_spr_coin2.tag = CashCard_text_coin2;
        bt_spr_coin2.position = ccpAdd(bt_spr_bg.position, ccp(-(bt_spr_coin2.contentSize.width/2+bt_spr_change.contentSize.width/2+bt_spr_coin1.contentSize.width/2),0)) ;
        bt_spr_coin2.visible = YES;
    }
}
-(void)setRedeemType:(int)redeemType_{
    [self setRedeemType:redeemType_ coin1:coin1 coin2:coin2];
}
-(void)changeRedeemType:(int)redeemType_ coin1:(int)coin1_ coin2:(int)coin2_{
    if (redeemType_!=redeemType) {
        [self setRedeemType:redeemType_ coin1:coin1_ coin2:coin2_];
    }else{
        coin1 = coin1_;//银币
        coin2 = coin2_;//元宝
        GameMoney *bt_spr_coin1 = (GameMoney *)[self getChildByTag:CashCard_text_coin1];
        if (bt_spr_coin1) {
            bt_spr_coin1.moneyValue = coin1;
        }
        GameMoney *bt_spr_coin2 = (GameMoney *)[self getChildByTag:CashCard_text_coin2];
        if (bt_spr_coin2) {
            bt_spr_coin2.moneyValue = coin2;
        }
    }
}
-(void)setRedeemType:(int)redeemType_ coin1:(int)coin1_ coin2:(int)coin2_{
	redeemType = redeemType_;
	//背景的图片
    
    CCSprite *bg_spr = nil;
    bg_spr = (CCSprite *)[self getChildByTag:CashCard_bg_tag];
    if (bg_spr) {
        [bg_spr removeFromParentAndCleanup:YES];
        bg_spr = nil;
    }
    bg_spr = [self getBGSpriteWithType:redeemType];
    if (bg_spr) {
        [self addChild:bg_spr];
        int y = 0;
        if (iPhoneRuningOnGame()) {
            bg_spr.scaleX = 1.17;
            bg_spr.scaleY = 1.136;
            y = 4;
        }
        
        bg_spr.tag = CashCard_bg_tag;
        bg_spr.anchorPoint = ccp(0.5, 0);
        bg_spr.position = ccp(self.contentSize.width/2,y);
    }
	
    //
    coin1 = coin1_;//银币
    coin2 = coin2_;//元宝
    [self addTextSprite];
	
    int button_h = cFixedScale(30);
	
    //加按钮图
    CCSprite *bt_spr_1 = nil;
    bt_spr_1 = (CCSprite *)[self getChildByTag:CashCard_button_1_tag];
    if (bt_spr_1) {
        [bt_spr_1 removeFromParentAndCleanup:YES];
        bt_spr_1 = nil;
    }
    bt_spr_1 = [CCSprite spriteWithFile:@"images/ui/button/bt_change_1.png"];
    if (bt_spr_1) {
        [self addChild:bt_spr_1];
        bt_spr_1.tag = CashCard_button_1_tag;
        bt_spr_1.anchorPoint = ccp(0.5, 0.5);
        bt_spr_1.position = ccp(self.contentSize.width/2,button_h);
        bt_spr_1.visible = YES;
    }
	
    //
    CCSprite *bt_spr_2 = nil;
    bt_spr_2 = (CCSprite *)[self getChildByTag:CashCard_button_2_tag];
    if (bt_spr_2) {
        [bt_spr_2 removeFromParentAndCleanup:YES];
        bt_spr_2 = nil;
    }
    bt_spr_2 = [CCSprite spriteWithFile:@"images/ui/button/bt_change_2.png"];
    if (bt_spr_2) {
        [self addChild:bt_spr_2];
        bt_spr_2.tag = CashCard_button_2_tag;
        bt_spr_2.anchorPoint = ccp(0.5, 0.5);
        bt_spr_2.position = ccp(self.contentSize.width/2,button_h);
        bt_spr_2.visible = NO;
    }
    //
    CCSprite *bt_spr_3 = nil;
    bt_spr_3 = (CCSprite *)[self getChildByTag:CashCard_button_3_tag];
    if (bt_spr_3) {
        [bt_spr_3 removeFromParentAndCleanup:YES];
        bt_spr_3 = nil;
    }
    bt_spr_3 = [CCSprite spriteWithFile:@"images/ui/button/bt_change_3.png"];
    if (bt_spr_3) {
        [self addChild:bt_spr_3];
        bt_spr_3.tag = CashCard_button_3_tag;
        bt_spr_3.anchorPoint = ccp(0.5, 0.5);
        bt_spr_3.position = ccp(self.contentSize.width/2,button_h);
        bt_spr_3.visible = NO;
    }
	
    //
    //showNode(self);
}

-(void)setIsTouch:(BOOL)_isTouch{
	isTouch = _isTouch;
	//点击的图片的状态
    CCSprite *bt_spr_1 = (CCSprite *)[self getChildByTag:CashCard_button_1_tag];
    CCSprite *bt_spr_2 = (CCSprite *)[self getChildByTag:CashCard_button_2_tag];
    CCSprite *bt_spr_3 = (CCSprite *)[self getChildByTag:CashCard_button_3_tag];
    if (isTouch) {
        [bt_spr_1 setVisible:NO];
        [bt_spr_2 setVisible:YES];
        [bt_spr_3 setVisible:NO];
    }else{
        [bt_spr_1 setVisible:YES];
        [bt_spr_2 setVisible:NO];
        [bt_spr_3 setVisible:NO];
    }
}

-(BOOL)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self checkEvent:touch]) {
		self.isTouch = YES;
	}
	return NO;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self checkEvent:touch]) {
		if (self.isTouch) {
			[self doEvent];
		}
	}
	self.isTouch = NO;
}

-(void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	self.isTouch = NO;
}

@end

@implementation CashCowManager

enum{
    CashCowManager_label_bg_tag = 234,
    CashCowManager_label_tag,
};

+(BOOL)checkOpenSystem{
	NSDictionary* s_setting = [[GameDB shared] getGlobalConfig];
	int tLv = [[s_setting objectForKey:@"ctreeOpen"] intValue];
	int pLv = [[GameConfigure shared] getPlayerLevel];
	return (pLv >= tLv);
}

-(void)onEnter{
	[super onEnter];
    //
    self.touchEnabled = YES;
    self.touchPriority = -128;
    _closePy = -129;
	cards = [[NSMutableArray alloc] init];
    //
    redeemTimes = 0;
    redeemCoin1 = 0;
    redeemCoin2 = 0;
    isSender = NO;
    //
    [self startSystem];
}

-(void)onExit{
	if (cards != nil) {
		[cards release];
		cards = nil;
	}
    //
    [GameConnection freeRequest:self];
    //
	[super onExit];
}

-(void)showTextLabelWithTimes:(int)times_{
   if (times_>=0) {
       CCSprite *spr_label = nil;
       spr_label = (CCSprite *)[self getChildByTag:CashCowManager_label_tag];
       if (spr_label) {
           [spr_label removeFromParentAndCleanup:YES];
           spr_label = nil;
       }
       NSString *text = [NSString stringWithFormat:@" %d #ffff00",times_];
       spr_label = drawString(text, CGSizeMake(200,0), getCommonFontName(FONT_1), (CASH_FONT_SIZE-1), (CASH_FONT_SIZE), @"#EBE2D0");
       spr_label.anchorPoint = ccp(0,0.5);
       [self addChild:spr_label z:3 tag:CashCowManager_label_tag];
       //
       CCSprite *spr_label_bg = (CCSprite *)[self getChildByTag:CashCowManager_label_bg_tag];
       if (spr_label_bg) {
           spr_label.position = spr_label_bg.position;
       }
       
    }else{
        CCLOG(@"times is error");
    }
}

-(void)addCardWithCount:(int)count_ coin1:(int)coin1_ coin2:(int)coin2_{
    //
    [self showTextLabelWithTimes:count_];
    //
    if (count_>=0) {
        CashCard *card = nil;
        //
        card = [CashCard node];
        [self addChild:card];
        card.anchorPoint = ccp(0.5,0);
        [card setRedeemType:0 coin1:coin1_ coin2:coin2_];
        [cards addObject:card];
        card.target = self;
        card.call = @selector(cashCardCallBack:);
    }
}
-(void)addLabelBG{
    CCSprite *label_bg = nil;
    label_bg = (CCSprite *)[self getChildByTag:CashCowManager_label_bg_tag];
    if (label_bg) {
        [label_bg removeFromParentAndCleanup:YES];
        label_bg = nil;
    }
    label_bg = [CCSprite spriteWithFile:@"images/ui/ctree/ctree_times.png"];
    [self addChild:label_bg z:3 tag:CashCowManager_label_bg_tag];
    label_bg.anchorPoint = ccp(1,0.5);
    if (iPhoneRuningOnGame()) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        label_bg.position = ccp(size.width-cFixedScale(CASH_FONT_SIZE)*3,cFixedScale(CASH_FONT_SIZE)*2);
    }else{
        label_bg.position = ccp(self.contentSize.width-cFixedScale(CASH_FONT_SIZE)*3,cFixedScale(CASH_FONT_SIZE)*2);
    }
}
-(void)showAll{
    //
    [self addLabelBG];
    //
    [self addCardWithCount:redeemTimes coin1:redeemCoin1 coin2:redeemCoin2];
    //
    [self setCardPosition];
}
-(void)setCardPosition{
    CGPoint startPos;
    startPos.y = cFixedScale(20);
    
    if ([cards count]>0) {
        startPos.x = self.contentSize.width/2 - [cards count]/2*CARDS_STEP_W;
        if ([cards count]%2 == 0 ) {
            startPos.x += CARDS_STEP_W/2;
        }
        for (CashCard *card in cards) {
            card.position = startPos;
            startPos.x += CARDS_STEP_W;
        }
    }

    
}
-(void)closeWindow{
	//todo what do you want??
	[super closeWindow];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if (isSender == NO) {
        CashCard * ____node = nil;
        for (____node in cards) {
            if(____node!=nil){
                if ([____node isKindOfClass:[CashCard class]]) {
                    if ([____node touchBegan:touch withEvent:event]) {
                        break;
                    }
                }
            }
        }
    }
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	CashCard * ____node = nil;
	for (____node in cards) {
		if(____node!=nil){
			if ([____node isKindOfClass:[CashCard class]]) {
				[____node touchEnded:touch withEvent:event];
			}
		}
	}
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	CashCard * ____node = nil;
	for (____node in cards) {
		if(____node!=nil){
			if ([____node isKindOfClass:[CashCard class]]) {
				[____node touchCancelled:touch withEvent:event];
			}
		}
	}
}

//摇钱树进入ctreeEnterctreeEnter_r剩余次数(num int)兑换ctreeExchange类型(etype, int)1=财运亨通, 2=招财进宝, 3=财通天下ctreeExchange_r(items, dict)物品更新结构

-(void)startSystem{
	[GameConnection request:@"ctreeEnter" format:@"" target:self call:@selector(endStartSystem:)];
}
-(void)cashCardCallBack:(id)sender{
    CashCard *card = sender;
    int type = [card redeemType];
    [self redeem:type];
}
-(void)endStartSystem:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		NSDictionary* dict = getResponseData(sender);
        if (dict && [dict objectForKey:@"num"] && [dict objectForKey:@"c2toc1"]) {
            redeemTimes = [[dict objectForKey:@"num"] intValue];
            NSString *str = [dict objectForKey:@"c2toc1"] ;
            NSArray * ary2 = [str componentsSeparatedByString:@":"];
            if ([ary2 count]>1) {
                redeemCoin1 = [[ary2 objectAtIndex:1] integerValue];
                redeemCoin2 = [[ary2 objectAtIndex:0] integerValue];
                //绘制全部东西
                [self showAll];
                return;
            }
        }
	}else{
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    //
    CCLOG(@"cash cow enter error");
    [self closeWindow];
}

-(void)redeem:(int)_type{
    NSString *typestr = nil;
    if (_type==0) {
        typestr = @"cash_cow_change_coin1";
    }else if (_type==1) {
        typestr = @"cash_cow_change_coin2";
    }
    if (redeemTimes>0) {
        if (typestr) {
            NSString *paystr =[NSString stringWithFormat:NSLocalizedString(typestr,nil),redeemCoin2,redeemCoin1];
            if (paystr) {
                [[AlertManager shared]showMessage:paystr target:self confirm:@selector(ctreeSend) canel:nil];
            }
        }
    }else{
        [ShowItem showErrorAct:@"413"];
    }
}
-(void)ctreeSend{
    isSender = YES;
	[GameConnection request:@"ctreeExchange" format:@"" target:self call:@selector(endRedeem:)];
}
-(void)endRedeem:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
        NSDictionary *data = getResponseData(sender);
        if (data && [data objectForKey:@"items"] && [data objectForKey:@"c2toc1"]) {
            NSDictionary *itemsDict = [data objectForKey:@"items"];
            //
            NSArray *updateData = [[GameConfigure shared] getPackageAddData:itemsDict];
            [[AlertManager shared] showReceiveItemWithArray:updateData];
            
            [[GameConfigure shared] updatePackage:itemsDict];
            //
            NSString *str = [data objectForKey:@"c2toc1"] ;
            NSArray * ary2 = [str componentsSeparatedByString:@":"];
            if ([ary2 count]>1) {
                redeemCoin1 = [[ary2 objectAtIndex:1] integerValue];
                redeemCoin2 = [[ary2 objectAtIndex:0] integerValue];
                //
                redeemTimes--;
                [self showTextLabelWithTimes:redeemTimes];
                //绘制全部东西
                CashCard *card = [cards objectAtIndex:0];
                if (card) {
                    [card changeRedeemType:[card redeemType] coin1:redeemCoin1 coin2:redeemCoin2];
                }
                isSender = NO;
                return;
            }
        }
	}else{
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    //
    CCLOG(@"coin data error");
    isSender = NO;
}

@end
