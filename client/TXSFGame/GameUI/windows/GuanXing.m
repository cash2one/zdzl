//
//  GuanXing.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-28.
//  Copyright 2012 eGame. All rights reserved.
//

#import "GuanXing.h"
#import "Config.h"
#import "Window.h"
#import "GameConfigure.h"
#import "RoleCard.h"
#import "GameDB.h"
#import "GameConnection.h"
#import "MessageBox.h"
#import "CFDialog.h"
#import "ClickAnimation.h"
#import "PlayerDataHelper.h"
#import "InfoAlert.h"
#import "intro.h"
#import "RoleViewerContent.h"
#import "FateIconViewerContent.h"

//iphone for chenjunming

#define GX_WAIT_RENDER_TIME (0.51f)

static int s_gx_role_id = 0;

int sortFate(NSDictionary *p1, NSDictionary*p2, void*context){
	
	int exp1 = [[p1 objectForKey:@"exp"] intValue];
	int exp2 = [[p2 objectForKey:@"exp"] intValue];
	
	if(exp1>exp2) return NSOrderedAscending;
	if(exp1<exp2) return NSOrderedDescending;
	
	return NSOrderedSame;
}
//fix chao
int sortFateArray(NSDictionary *p1, NSDictionary*p2, void*context){
	int quality1 = [[p1 objectForKey:@"quality"] intValue];
	int quality2 = [[p2 objectForKey:@"quality"] intValue];
	int bid1 = [[p1 objectForKey:@"bid"] intValue];
	int bid2 = [[p2 objectForKey:@"bid"] intValue];
	if(quality1>quality2){
		return NSOrderedAscending;		
	}else if(quality1==quality2){
		if (bid1>bid2) {
			return NSOrderedAscending;
		}else if(bid1<bid2){
			return NSOrderedDescending;
		}		
	}else if(quality1<quality2){
		return NSOrderedDescending;
	}	
	return NSOrderedSame;
}
//end
#pragma mark - GuanXingCardLayer
@interface GXCardLayer : CardLayer
@end
@interface GXCardLayer(GXCardLayerPrivate)
-(void)updatePageWithMovePos:(CGPoint)pos;
@end

@implementation GXCardLayer
-(void)callbackTouch:(CCLayerList *)_list :(CCListItem *)_listItem :(UITouch *)touch
{
	CCLOG(@"PPCardLayer callbackTouch");
	//TODO
	Card *_card = (Card*)_listItem;	
	if (YES == [_card isOwnItem]){
		[target showMessageWithCard:_card];		
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	CCLOG(@"PPCardLayer layer touch bagan");
	
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (CGRectContainsPoint(cutRect, touchLocation)) {
		////
		touchStartTime = [NSDate timeIntervalSinceReferenceDate];
		
        
        if (startTouch) {
            [startTouch release];
            startTouch = nil;
        }
        
        startTouch = touch;
        [startTouch retain];
        
		isMoveItem = NO;
		isMovePackage = NO;
		isMoveTouch = NO;
		//
		CCLOG(@"touchTime:%f",touchStartTime);		
		startMovePos = touchLocation;
		pageStartMovePos = touchLocation;		
		[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:CL_MOVE_ITEM_TIME/1000.0f],
						 [CCCallFuncN actionWithTarget:self selector:@selector(isMoveItemBackCall)], nil]];
		return YES;
	}
    
    if (startTouch) {
        [startTouch release];
        startTouch = nil;
    }

    return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"moveing");
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	
	
	if ( isMoveTouch == NO && isMoveItem == NO) {
		if([NSDate timeIntervalSinceReferenceDate]-touchStartTime < CL_SHOW_CARD_TIME){
			if (abs(startMovePos.x-touchLocation.x) + abs(startMovePos.y-touchLocation.y)<CL_DITHERING_LEN) {
				isMoveItem = NO;
				isMoveTouch = NO;
				return;
			}else{
				isMovePackage = YES;
			}			
		}else if([NSDate timeIntervalSinceReferenceDate]-touchStartTime < CL_MOVE_PACKAGE_TIME) {
			isMovePackage = YES;
		}else{
			isMoveItem = YES;
		}
	}
	isMoveTouch = YES;//第一次进入标志
	
	//TODO
	if (isMovePackage) {
		//		
		if (CGRectContainsPoint(cutRect, [self convertToNodeSpace:touchLocation])) {
			touchLocation = [self convertToNodeSpace:touchLocation];
			CGPoint dPos = ccpSub(touchLocation, startMovePos);
			if (abs(dPos.x)>30) {
				isMovePage = YES;
			}
			CCLOG(@"dPos.x:%f",dPos.x);
			
			cards.position = ccp(cards.position.x+dPos.x,cards.position.y);
			startMovePos = touchLocation;
		}
	}else if (isMoveItem) {
		//if ([target isTouchGXItem]) {
		//}
		if(NO == [target isTouchGXItem] && NO == [target isSend]){
			Card *card = (Card *)[cards itemForTouch:touch];
			if (YES == [card isOwnItem] && startTouch) {
				[target setIsTouchGXItem:YES];
				[target changeTouchGXCard:card touch:startTouch];
			}
			
		}
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (isMoveItem ==NO && isMovePackage == NO) {
		//TODO 显示弹出框
		[cards ccTouchBegan:touch withEvent:event];
		[cards ccTouchEnded:touch withEvent:event];		
		CCLOG(@"show txt box");
	}else{
		if (isMovePackage) {
			//TODO
			////
			touchLocation = ccpSub(touchLocation,pageStartMovePos );
			[self updatePageWithMovePos:touchLocation];
		}else if (isMoveItem) {
			//TODO
		}
	}

	////
	touchStartTime = -1;
	isMoveTouch = YES;//停isMoveItemBackCall 动作
    
    if (startTouch) {
        [startTouch release];
        startTouch = nil;
    }
}

+(CardLayer*)create{
	CGSize winSize=[[CCDirector sharedDirector] winSize];
	return [[[GXCardLayer alloc] initWithColor:ccc4(0, 0, 0, 0) width:winSize.width height:winSize.height] autorelease];
}
//
-(void)isMoveItemBackCall{
	if (isMoveTouch == NO && NO == [target isSend]) {
		isMoveItem = YES;
		if(NO == [target isTouchGXItem] && startTouch){
			Card *card = (Card *)[cards itemForTouch:startTouch];
			if (YES == [card isOwnItem]) {
				[target setIsTouchGXItem:YES];
				[target changeTouchGXCard:card touch:startTouch];
				//fix chao
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXing_Step_1];
				[[Intro share] runIntroTager:[target getPartCard:1] step:INTRO_GuangXing_Step_2];
				//end
			}else{
                isMoveItem = NO;
            }
		}
		CCLOG(@"set move item");
	}
	
}
//
@end

#pragma mark -
#pragma mark - GuanXing

//#if TARGET_IPHONE
////IPHONE
//static int GX_ROLE_BACK_X =(350/2);
//static int GX_ROLE_BACK_Y =(258/2);
//
//static int GX_FATE_FORCE_X= (138/2);
//static int GX_FATE_FORCE_Y =(465/2);
//
//static int GX_FATE_PACKAGE_X= (700/2);
//static int GX_FATE_PACKAGE_Y =(300/2);
//#else
//IPAD
static int GX_ROLE_BACK_X =(350);
static int GX_ROLE_BACK_Y= (258);

static int GX_FATE_FORCE_X =(138);
static int GX_FATE_FORCE_Y =(465);

static int GX_FATE_PACKAGE_X =(700);
static int GX_FATE_PACKAGE_Y =(300);
//#endif

@implementation GuanXing

enum{
	GX_ROLE_BACK_TAG=123,//角色背景
	GX_ROLE_IMAGE_TAG,//角色图
	GX_ROLE_SHADOW_IMAGE_TAG,//角色阴影图
	GX_FATE_POS01_TAG,//位置1元神
	GX_FATE_POS02_TAG,//位置2元神
	GX_FATE_POS03_TAG,//位置3元神
	GX_FATE_POS04_TAG,//位置4元神
	GX_FATE_POS05_TAG,//位置5元神
	GX_FATE_POS06_TAG,//位置6元神
	GX_FATE_FORCE_LABEL_TAG,//元神力标签
	GX_FATE_FORCE_TOUCHCARD_TAG,//手指上的卡片
	GX_FATE_FORCE_PACKAGE_TAG,//背包
	GX_FATE_MESSAGE_BOX_TAG,//背包Box
	//
	//GX_FATE_MESSAGE_BOX_YES_BUTTON_TAG,//背包Box yes button
	//GX_FATE_MESSAGE_BOX_NO_BUTTON_TAG,//背包Box no button
};
typedef enum {
	GXMT_synthesize = 88,//合并
	GXMT_synthesizeAll,//全合并
	//GXMT_equipUp,//穿
	GXMT_equipOff,//脱
}GuanXingMessageType;

@synthesize isTouchGXItem;
@synthesize isSend;

+(void)setRoleID:(int)rid{
    s_gx_role_id = rid;
}
-(void)showMessageWithCard:(Card*)card{
	
	//CGSize winSize=[[CCDirector sharedDirector] winSize];
	
	//set message
	TextBox *messageBox = (TextBox *)[self getChildByTag:GX_FATE_MESSAGE_BOX_TAG];
	if (!messageBox) {
		messageBox = [TextBox node];
		[self addChild:messageBox z:5 tag:GX_FATE_MESSAGE_BOX_TAG];
	}
	[messageBox setMessageBoxWith:[card getItemType] itemID:[card getItemID] count:[card itemCount]];
	
	if (iPhoneRuningOnGame()) {
		messageBox.scale=0.5f;
	}
	
	messageBox.position = ccp(self.contentSize.width/2-messageBox.contentSize.width/2, self.contentSize.height/2-messageBox.contentSize.height/2);
}
-(void)changeTouchGXCard:(Card*)card{
	
	[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
	if (touchCard != card) {
		[touchCard setItemVisible:YES];
		[touchCard release];
		touchCard=card;
		[touchCard retain];
	}
	//
	[touchCard setItemVisible:NO];
	
	//touchCard	= card;
	if (card) {
		
		//CCSprite * spr = getFateIcon([card getBaseID]);
		FateIconViewerContent * spr = [FateIconViewerContent create:[card getBaseID]];
		
		//int itemQuality = [card itemQuality];
		int cardType = [card getItemType];
		if (spr) {
			if (cardType == IST_FATE) {
				
				spr.quality = [card itemQuality];
				
				/*
				NSString *str_ = nil;
				if (itemQuality == IQ_BLUE) {
					str_ = @"images/animations/fate/blue/";
				}else if(itemQuality == IQ_PURPLE) {
					str_ = @"images/animations/fate/purple/";
				}else{
					str_ = @"images/animations/fate/green/";
				}
				if (str_) {
					[ClickAnimation showInLayer:spr z:-1 tag:GX_FATE_FORCE_TOUCHCARD_TAG call:nil point:ccp(spr.contentSize.width/2, spr.contentSize.height/2) path:str_ loop:YES];
				}
				*/
				
			}
		}
		
		[self addChild:spr z:20 tag:GX_FATE_FORCE_TOUCHCARD_TAG];
		//spr.position = card.position;
		spr.position = [self convertToNodeSpace:card.position];
	}

}
-(Card*)getPartCard:(NSInteger)part{
	Card *t_card=nil;
	if (part>=1 && part<=6 ) {
		t_card = (Card *)[self getChildByTag:GX_FATE_POS01_TAG + part - 1];
	}
	return t_card;
}
-(void)changeTouchGXCard:(Card*)card touch:(UITouch *)touch{
	[self changeTouchGXCard:card];
	CCSprite *spr = (CCSprite *)[self getChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG];
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	[spr setPosition:touchLocation];
}

+(GuanXing*)create
{
	CGSize winSize=[[CCDirector sharedDirector] winSize];
//	return [[[GuanXing alloc] initWithColor:ccc4(0, 0, 0, 0) width:winSize.width height:winSize.height] autorelease];

	GuanXing *layer = [[[GuanXing alloc] init] autorelease];
	layer.contentSize = winSize;
	return layer;
}

-(NSInteger)getFateValueWithRID:(NSInteger)rid{
	int exp1 = 0;
	NSDictionary *userRole=nil;
	userRole = [[GameConfigure shared] getPlayerRoleFromListById:rid];//装备信息
	if (!userRole) {
		CCLOG(@"role dict is error");
		return exp1;
	}
	//元神力
	int _fate1ID = [[userRole objectForKey:@"fate1"] intValue];
	int _fate2ID = [[userRole objectForKey:@"fate2"] intValue];
	int _fate3ID = [[userRole objectForKey:@"fate3"] intValue];
	int _fate4ID = [[userRole objectForKey:@"fate4"] intValue];
	int _fate5ID = [[userRole objectForKey:@"fate5"] intValue];
	int _fate6ID = [[userRole objectForKey:@"fate6"] intValue];
	
	if (_fate1ID > 0) {
		exp1 = [[[[GameConfigure shared] getPlayerFateInfoById:_fate1ID] objectForKey:@"exp"] intValue];
	}
	if (_fate2ID > 0) {
		exp1 += [[[[GameConfigure shared] getPlayerFateInfoById:_fate2ID] objectForKey:@"exp"] intValue];
	}
	if (_fate3ID > 0) {
		exp1 += [[[[GameConfigure shared] getPlayerFateInfoById:_fate3ID] objectForKey:@"exp"] intValue];
	}
	if (_fate4ID > 0) {
		exp1 += [[[[GameConfigure shared] getPlayerFateInfoById:_fate4ID] objectForKey:@"exp"] intValue];
	}
	if (_fate5ID > 0) {
		exp1 += [[[[GameConfigure shared] getPlayerFateInfoById:_fate5ID] objectForKey:@"exp"] intValue];
	}
	if (_fate6ID > 0) {
		exp1 += [[[[GameConfigure shared] getPlayerFateInfoById:_fate6ID] objectForKey:@"exp"] intValue];
	}
	exp1 = exp1/5;	
	return exp1;
}

-(void)onEnter
{
	[super onEnter];
	
	fate_level = [NSMutableDictionary dictionary];
	[fate_level retain];
	
	[self getFateLevels];
	
    self.touchEnabled = YES;
	self.touchPriority = kCCMenuHandlerPriority;
	
	//fix chao
	isTouch = NO;
    isSend = NO;
	//end
	
    GX_ROLE_BACK_X = cFixedScale(-90);
	GX_ROLE_BACK_Y = cFixedScale(-20);
	GX_FATE_FORCE_X = cFixedScale(-300);
	GX_FATE_FORCE_Y = cFixedScale(190);
	GX_FATE_PACKAGE_X = cFixedScale(260);
	GX_FATE_PACKAGE_Y = cFixedScale(26);
    
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            GX_ROLE_BACK_X = cFixedScale(-90)-15;
            GX_ROLE_BACK_Y = cFixedScale(-10);
            GX_FATE_FORCE_X = cFixedScale(-300)-30;
            GX_FATE_FORCE_Y = cFixedScale(190)+15;
            GX_FATE_PACKAGE_X = cFixedScale(260)+15;
            GX_FATE_PACKAGE_Y = cFixedScale(26);
        }else{
            GX_ROLE_BACK_X = cFixedScale(-90)-15;
            GX_ROLE_BACK_Y = cFixedScale(-10);
            GX_FATE_FORCE_X = cFixedScale(-300)-30;
            GX_FATE_FORCE_Y = cFixedScale(190)+15;
            GX_FATE_PACKAGE_X = cFixedScale(260)+15;
            GX_FATE_PACKAGE_Y = cFixedScale(26);
        }
    }
	
	GX_ROLE_BACK_X += self.contentSize.width/2;
	GX_ROLE_BACK_Y += self.contentSize.height/2;
	GX_FATE_FORCE_X += self.contentSize.width/2;
	GX_FATE_FORCE_Y += self.contentSize.height/2;
	GX_FATE_PACKAGE_X += self.contentSize.width/2;
	GX_FATE_PACKAGE_Y += self.contentSize.height/2;
		
    //TODO 透明背景框
	MessageBox *messageBox = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            messageBox.contentSize = CGSizeMake(833/2, 540/2);
            messageBox.position = ccp(-182.5f, -141);
        }else{
            messageBox.contentSize = CGSizeMake(833/2, 540/2);
            messageBox.position = ccp(-182.5f, -141);
        }
    }else{
        messageBox.contentSize = CGSizeMake(719, 490);
        messageBox.position= ccp(-310, -266);
    }
	messageBox.position = ccpAdd(messageBox.position,
								 ccp(self.contentSize.width/2, self.contentSize.height/2));
	[self addChild:messageBox z:0];
    
	menu = [CCMenu menuWithItems:nil];
	menu.ignoreAnchorPointForPosition = YES;
    if (iPhoneRuningOnGame()) {
        menu.position = CGPointZero;
    }else{
        menu.position = CGPointZero;
    }
	[self addChild:menu z:3];

//	showNode(close);
	////角色背景
	CCSprite *back01 =nil;
	if (iPhoneRuningOnGame()) {
		back01=[CCSprite spriteWithFile:@"images/ui/wback/GXBack01.png"];
	}else{
		back01=[CCSprite spriteWithFile:@"images/ui/panel/GXBack01.png"];
	}
	[self addChild:back01 z:0 tag:GX_ROLE_BACK_TAG];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            back01.position = ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y);
        }else{
            back01.position = ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y);
        }
    }else{
        back01.position = ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y);
    }
	
	NSArray *sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_getxingchen");
	CCMenuItem *bt_getXingChen = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	bt_getXingChen.tag = BT_GX_GET_XINGCHEN_TAG;
    if (iPhoneRuningOnGame()) {
		bt_getXingChen.scale=1.3f;
		bt_getXingChen.position = ccp(GX_ROLE_BACK_X,-250/2);
    }else{
        bt_getXingChen.position = ccp(GX_ROLE_BACK_X,-240);
    }
	bt_getXingChen.position = ccpAdd(bt_getXingChen.position,ccp(0, self.contentSize.height/2));
	[menu addChild:bt_getXingChen z:0 tag:BT_GX_GET_XINGCHEN_TAG];
	
	////一键合成 按钮
    //IPhone UI待修改
	//fix chao
	//sprArr = getLabelSprites(@"images/ui/button/bt_background.png",@"images/ui/button/bt_background.png",@"一键合成",18,ccc4(65,197,186,255),ccc4(65,197,186,255) );
	sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_all_synthesize");
	//end
	CCMenuItem *bt_getOneKey = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	bt_getOneKey.tag = BT_GX_ONEKEY_TAG;
    if (iPhoneRuningOnGame()) {
		bt_getOneKey.scale=1.3f;
    	bt_getOneKey.position = ccp(GX_FATE_PACKAGE_X,-250/2);
    }
    else{
    	bt_getOneKey.position = ccp(GX_FATE_PACKAGE_X,-240);
    }
	bt_getOneKey.position = ccpAdd(bt_getOneKey.position, ccp(0, self.contentSize.height/2));
	[menu addChild:bt_getOneKey z:0	tag:BT_GX_ONEKEY_TAG];
	
	
	////
    float fontSize=14;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	//CCLabelTTF *label01 = [CCLabelTTF labelWithString:@"轻点可观察星力属性，长按拖动即可装备到星位之内" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *label01 = [CCLabelTTF labelWithString:NSLocalizedString(@"guanxing_info",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	[self addChild:label01 z:20];
	label01.anchorPoint = ccp(0,0);
	//fix chao
	//label01.position = ccp(self.contentSize.width/2+50,488);
    int off_x = 0;
    int off_y = 0;
    if (iPhoneRuningOnGame() ) {
//        if (isIphone5()) {
//            off_x += cFixedScale(20);
//        }																		//Kevin fixed
		off_x += cFixedScale(20);
        
    }else{
        off_x += cFixedScale(70);
        off_y += cFixedScale(2);
    }
    
    label01.position = ccp(self.contentSize.width/2-label01.contentSize.width - cFixedScale(120)+off_x,
                           self.contentSize.height/2-cFixedScale(90)+off_y
							   );
	//Kevin added
	if (iPhoneRuningOnGame()) {
		label01.position = ccpAdd(label01.position, ccp(-2, -5));
	}
	label01.position = ccpAdd(label01.position,
							  ccp(self.contentSize.width/2, self.contentSize.height/2));
	//---------------------//
    
	//end
	
	////隐藏可交易 复选框
	//fix chao
	/*
	sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",@"隐藏可交易",18,ccc4(255,255,255,255),ccc4(255,255,255,255) );
	CCMenuItemSprite *itemSpr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	CCMenuItemSprite *itemSpr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	CCMenuItem *toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:itemSpr01,itemSpr02, nil];
	[menu addChild:toggle z:0 tag:BTT_GX_NO_HIDE_DEAL_TAG];
	toggle.position = ccp(720+128-8-toggle.contentSize.width/2,488);
	 */
	//end
    
	//装备了的星尘
	Card *fatePos;
	for (int i=GX_FATE_POS01_TAG; i<=GX_FATE_POS06_TAG; i++) {
		fatePos = [Card node];
		[self addChild:fatePos z:3 tag:i];
		fatePos.anchorPoint = ccp(0.5,0.5);
		fatePos.position = [self getFatePositionWithTag:i];
		if (iPhoneRuningOnGame()) {
			fatePos.scale=1.06f;
		}
		if (![self checkIsOpenWithTag:i]) {
			[fatePos setItemClose:YES];
		}
	}
	
	////左上角星力图
	CCSprite *fateForceBg = [CCSprite spriteWithFile:@"images/ui/panel/t30.png"];
	[self addChild:fateForceBg z:3];
	fateForceBg.anchorPoint = ccp(0,0.5);
	if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            fateForceBg.position =(ccp(GX_FATE_FORCE_X,GX_FATE_FORCE_Y));            
        }else{
            fateForceBg.position =(ccp(GX_FATE_FORCE_X,GX_FATE_FORCE_Y));
        }
    }else{
        fateForceBg.position = ccp(GX_FATE_FORCE_X,GX_FATE_FORCE_Y);
    }
	
	////
	CCSprite *fateForceSpr = [CCSprite spriteWithFile:@"images/ui/panel/icon_guanxing.png"];
	[self addChild:fateForceSpr z:3];
	fateForceSpr.anchorPoint = ccp(0,0.5);
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            fateForceSpr.position =(ccp(GX_FATE_FORCE_X-1,GX_FATE_FORCE_Y));            
        }else{
            fateForceSpr.position =(ccp(GX_FATE_FORCE_X-1,GX_FATE_FORCE_Y));
        }
    }else{
        fateForceSpr.position = ccp(GX_FATE_FORCE_X-2,GX_FATE_FORCE_Y);
    }

	////元神力 标签
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	int _rid = 0;
	if (dict) {
		_rid = [[dict objectForKey:@"rid"] intValue];//装备信息
	}

    CCLabelTTF *fateForceLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:NSLocalizedString(@"guanxing_fate",nil),[self getFateValueWithRID:_rid]] fontName:@"Verdana-Bold" fontSize:fontSize];
	[self addChild:fateForceLabel z:3 tag:GX_FATE_FORCE_LABEL_TAG];
	fateForceLabel.anchorPoint = ccp(0,0.5);
	fateForceLabel.color = ccc3(240, 236, 220);
    if (iPhoneRuningOnGame()) {
		fateForceLabel.position =(ccp(GX_FATE_FORCE_X + fateForceSpr.contentSize.width -5/2,GX_FATE_FORCE_Y));
    }else{
        fateForceLabel.position = ccp(GX_FATE_FORCE_X + fateForceSpr.contentSize.width -5,GX_FATE_FORCE_Y);
    }
	
	//加载人物列表用
	[self reload];
	
	////更新背包
	[self initFatePackage];
	
	////
	tagetCard = nil;
	usedFateArray = nil;
	UnUsedFateArray = nil;
	
	////命格表
	[self scheduleOnce:@selector(loadFateList) delay:GX_WAIT_RENDER_TIME];
	////-----
	//fix chao
	CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
	if (gxCardLayer) {
		NSArray *cardArr = [gxCardLayer getLayerItemArray];
		if ([cardArr count]>0) {
			Card *_card = [cardArr objectAtIndex:0];
			if (_card) {
				[[Intro share] runIntroTager:_card step:INTRO_GuangXing_Step_1];	
			}
		}
	}

}
-(void)onExit{
    
    s_gx_role_id = 0;
    
	if (fate_level) {
		[fate_level release];
		fate_level = nil;
	}
	
	[usedFateArray release];
	[UnUsedFateArray release];
	
    if (touchCard) {
        [touchCard release];
        touchCard = nil;
    }

    if (startTouch) {
        [startTouch release];
        startTouch = nil;
    }
	
	//
    [GameConnection freeRequest:self];
	[super onExit];

}

//获取星尘装备的位置
-(CGPoint)getFatePositionWithTag:(NSInteger)tag{
	
	CGPoint pos;
    float r = 300.0f/2;
	float a = 180.0f/55;
    if (iPhoneRuningOnGame()) {
//        a=a/2;
//        CCSprite* back01=(CCSprite*)[self getChildByTag:GX_ROLE_BACK_TAG];
        if (isIphone5()) {
//            r=300.0f*back01.scale/4;
            r=325.0f/4;
        }else{
            r=325.0f/4;
        }
        pos= ccp(GX_ROLE_BACK_X-0.5f,GX_ROLE_BACK_Y+2.7f);
    }else{
        pos= ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y);
    }

	switch (tag) {
		case GX_FATE_POS01_TAG:{
			pos = ccp(pos.x-cos(M_PI/a)*r,pos.y+sin(M_PI/a)*r);
		}
			break;
		case GX_FATE_POS02_TAG:{
			pos = ccp(pos.x+cos(M_PI/a)*r,pos.y+sin(M_PI/a)*r);
		}
			break;
		case GX_FATE_POS03_TAG:{
			pos = ccp(pos.x+r,pos.y);
		}
			break;
		case GX_FATE_POS04_TAG:{
			pos = ccp(pos.x+cos(M_PI/a)*r,pos.y-sin(M_PI/a)*r);
		}
			break;
		case GX_FATE_POS05_TAG:{
			pos = ccp(pos.x-cos(M_PI/a)*r,pos.y-sin(M_PI/a)*r);
		}
			break;
		case GX_FATE_POS06_TAG:{
			pos = ccp(pos.x-r,pos.y);
		}
			break;
		default:
			break;
	}
	return pos;
}

-(void)closeWindow
{
	[super closeWindow];
	if([Intro getCurrenStep]>=INTRO_OPEN_GuangXing){
		[Intro stopAll];
	}
}

-(void)menuCallbackBack:(id)sender
{
    if (isTouch || touchCard) {
        return;
    }
	CCNode *_obj = (CCNode*)sender;
	if(_obj.tag == BT_GX_ONEKEY_TAG){
		[self onekeySynthesizeFate];
		CCLOG(@"BT_GX_ONEKEY_TAG");	
	}else if(_obj.tag == BT_GX_GET_XINGCHEN_TAG){
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_GuangXingRoom];
		[[Window shared] showWindow:PANEL_FATEROOM];
		CCLOG(@"BT_GX_GET_XINGCHEN_TAG");
	}
	
	CCLOG(@"GX_%d",_obj.tag);
}
//重新加载人物列表
-(void)reload
{
	if (cards) {
		[cards removeFromParentAndCleanup:true];
		cards = nil;
	}
    float padingx=5;
    float padingy=4;
    if (iPhoneRuningOnGame()) {
        padingx/=2;
        padingy/=2;
    }
	cards = [CCLayerList listWith:LAYOUT_Y :ccp(0, 0) :padingx :padingy];
	[cards setDelegate:self];
	cards.isDownward = YES;
    
    //fix chao
    BOOL isReset=NO;
    RoleCard *t_card = nil;
    //end
    
	NSArray *_roles = [[GameConfigure shared] getTeamMember];
	for (int i = 0; i < [_roles count]; i++) {
		RoleCard *_card = [RoleCard create:CARD_WEAPON];
		int _rid = [[_roles objectAtIndex:i] intValue];
		[_card initFormID:_rid];
        
		[cards addChild:_card];
        if (NO == isReset) {
            if (s_gx_role_id == _rid) {
                cardRoleRID = _card.RoleID;
                isReset = YES;
                _card.isSelect = YES;
                //[cards setSelected:_card];
            }
        }
		//fix chao
		if (i == 0) {//玩家自己
            t_card = _card;
			//cardRoleRID = _card.RoleID;
            if (s_gx_role_id<=0 && NO==isReset) {
                cardRoleRID = _card.RoleID;
                //[cards setSelected:_card];
                _card.isSelect = YES;
                isReset = YES;
            }
			//_card.isSelect = YES;
			//[cards setSelected:_card];
		}
		//end
	}
    if (NO==isReset) {
        if (t_card) {
            [cards setSelected:t_card];
            cardRoleRID = t_card.RoleID;
        }
    }
    if (iPhoneRuningOnGame()) {
        float _py = 128 - cards.contentSize.height;
		if (isIphone5()) {//IPhone5
//			cards.position =ccp(-263, _py);
			cards.position =ccp(-232.5, _py);

		}else{
			cards.position =ccp(-232.5, _py);
		}
    }else{
        float _py = 225 - cards.contentSize.height;
    	cards.position = ccp(-405, _py);
    }
	cards.position = ccpAdd(cards.position, ccp(self.contentSize.width/2, self.contentSize.height/2));
	
	[self addChild:cards z:1];
}
-(void)initFatePackage{
	
	//CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];	
	CardLayer *gxCardLayer = nil;
	
	////物品
	[self removeChildByTag:GX_FATE_FORCE_PACKAGE_TAG cleanup:YES];
	gxCardLayer = [GXCardLayer create];
	[self addChild:gxCardLayer z:1 tag:GX_FATE_FORCE_PACKAGE_TAG];
	[gxCardLayer setCapacity:0];
	[gxCardLayer reload];
	//gxCardLayer.anchorPoint = ccp(0.5,0.5);无效（已强制（0，0）对位）
	
	if(iPhoneRuningOnGame()){
        if (isIphone5()) {
            gxCardLayer.position = ccp(GX_FATE_PACKAGE_X-gxCardLayer.cutRect.size.width/2,GX_FATE_PACKAGE_Y-gxCardLayer.cutRect.size.height/2);            
        }else{
            gxCardLayer.position = ccp(GX_FATE_PACKAGE_X-gxCardLayer.cutRect.size.width/2,GX_FATE_PACKAGE_Y-gxCardLayer.cutRect.size.height/2);
        }
	}else{
		gxCardLayer.position = ccp(GX_FATE_PACKAGE_X-gxCardLayer.cutRect.size.width/2,GX_FATE_PACKAGE_Y-gxCardLayer.cutRect.size.height/2);
	}
	
	gxCardLayer.target = self;
}
-(CCSprite*)getRoleSpriteWithID:(NSInteger)roleID{
	return [CCSprite spriteWithFile:@"images/ui/panel/GXRoleBack01.png"];
}
-(float)getRoleOffsetWithRoleID:(NSInteger)rid{	
	float offset = 0;	
	// 角色
	NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:rid];
	if (roleInfo) {
		offset = [[roleInfo objectForKey:@"offset"] intValue];
	}else{
		CCLOG(@"rid is error");
	}	
	return offset;
}

-(void)updateRoleInfoWithID:(NSInteger)roleID fateArray:(NSArray*)_fateArray{
	
	if (roleID<=0) {
		CCLOG(@"role is id error");
		return;
	}
	if (!_fateArray) {
		CCLOG(@"_fateArray is error");
		return;
	}
	
	cardRoleRID = roleID;
	NSDictionary *dict = [[GameConfigure shared] getPlayerRoleFromListById:roleID];
	if (dict) {
		cardRoleID = [[dict objectForKey:@"id"] intValue];
	}else{
		CCLOG(@"role is nil");
		return;
	}

	[self removeChildByTag:GX_ROLE_SHADOW_IMAGE_TAG cleanup:YES];
	
	int h = cFixedScale(50);
    CGPoint shadowPt=ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y-h);
//	shadowPt = ccpAdd(shadowPt, ccp(self.contentSize.width/2, self.contentSize.height/2));
	ClickAnimation *shadowClick = [ClickAnimation showInLayer:self z:2 tag:GX_ROLE_SHADOW_IMAGE_TAG call:nil point:shadowPt path:@"images/animations/phalanx/1/" loop:YES];
	shadowClick.anchorPoint = ccp(0.5,0.5);
	
	//fix chao
	//NSString *path = [NSString stringWithFormat:@"images/fight/ani/r%d/1/battle-stand/",roleID];
	
	/*
	NSString *path = nil;
	NSDictionary* d1 = [[GameConfigure shared] getPlayerRoleFromListById:roleID];	
	int eq2 =0;
	int eid =0;
	if (d1) {
		eq2 = [[d1 objectForKey:@"eq2"] intValue];
		NSDictionary* d2 = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
		if (d2) {
			eid = [[d2 objectForKey:@"eid"] intValue];
		}
	}
	if (eid>0 && roleID<=6 && roleID>0) {
		path = [NSString stringWithFormat:@"images/fight/ani/r%d_%d/1/battle-stand/",roleID,eid,RoleAction_stand,RoleDir_up_flat];
	}else{
		path = [NSString stringWithFormat:@"images/fight/ani/r%d/1/battle-stand/",roleID,RoleAction_stand,RoleDir_up_flat];
	}
	
	[self removeChildByTag:GX_ROLE_IMAGE_TAG cleanup:YES];
	ClickAnimation *click = [ClickAnimation showInLayer:self 
													  z:2 
													tag:GX_ROLE_IMAGE_TAG 
												   call:nil 
												  point:ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y-h-[self getRoleOffsetWithRoleID:roleID]) 
												   path:path 
												   loop:YES];
	click.anchorPoint = ccp(0.5,0);
	
	 //TODO 要修改坐标，现在不准确
    if (iPhoneRuningOnGame()) {
//        float offset=[self getRoleOffsetWithRoleID:roleID];
//        float offset=[self getRoleOffsetWithRoleID:roleID];
//        CGPoint rolePt=ccp(shadowClick.position.x,shadowClick.position.y-shadowClick.contentSize.height/2);
        click.position=ccp(click.position.x,click.position.y/2);
    }
    */
	
	[self removeChildByTag:GX_ROLE_IMAGE_TAG cleanup:YES];
	RoleViewerContent * rvc = [RoleViewerContent node];
	rvc.tag = GX_ROLE_IMAGE_TAG;
	rvc.dir = 1;
	[rvc loadTargetRole:roleID];
	[self addChild:rvc z:2];
	
	//TODO 要修改坐标，现在不准确
	if (iPhoneRuningOnGame()) {
        rvc.position = ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y-h+5);
    }else{
		rvc.position = ccp(GX_ROLE_BACK_X,GX_ROLE_BACK_Y-h+10);
	}

	//end
	Card *fatePos;
	NSNumber *fateNumber;
	NSNumber *idNumber;
	NSMutableDictionary *t_dict;
	NSNumber *bidNumber;
	//
	//[self loadFateList];
	
	for (int i=GX_FATE_POS01_TAG; i<=GX_FATE_POS06_TAG; i++) {
		fatePos = (Card *)[self getChildByTag:i];
		if (![fatePos itemClose]) {
			fateNumber = [dict objectForKey:[NSString stringWithFormat:@"fate%d",i-GX_FATE_POS01_TAG+1]];
			[fatePos removeItem];
			if (fateNumber) {
				if (fateNumber.intValue > 0) {
					for (NSMutableDictionary *dict in _fateArray) {
						idNumber = [dict objectForKey:@"id"];
						bidNumber = [dict objectForKey:@"bid"];
						if (fateNumber.intValue == idNumber.intValue) {
							t_dict = [NSMutableDictionary dictionary];
							[t_dict setObject:[NSNumber numberWithInt:IST_FATE] forKey:@"itemSystemType"];
							[t_dict setObject:[dict objectForKey:@"id"] forKey:@"id"];
							[t_dict setObject:bidNumber forKey:@"bid"];
							[t_dict setObject:[dict objectForKey:@"level"] forKey:@"level"];
							[t_dict setObject:[dict objectForKey:@"exp"] forKey:@"exp"];
							[t_dict setObject:[dict objectForKey:@"isTrade"] forKey:@"isTrade"];
							[t_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
							[t_dict setObject:[dict objectForKey:@"used"] forKey:@"used"];
							[t_dict setObject:[[[GameDB shared] getFateInfo:[bidNumber intValue]] objectForKey:@"quality"]  forKey:@"quality"];
							
							[fatePos changeItemWithDict:t_dict];
							break;
						}
					}
					
				}
			}
		}
	}
}

-(void)showRoleViewer{
	
	
}

-(void)updateFatePackage:(NSArray*)arr{
	if (!arr) {
		CCLOG(@"fate array is error");
		return;
	}
	////物品
	[self removeChildByTag:GX_FATE_FORCE_PACKAGE_TAG cleanup:YES];
	CardLayer *gxCardLayer = [GXCardLayer create];
	[self addChild:gxCardLayer z:1 tag:GX_FATE_FORCE_PACKAGE_TAG];
	[gxCardLayer setCapacity:[arr count]];
	[gxCardLayer reload];
	//gxCardLayer.anchorPoint = ccp(0.5,0.5);无效（已强制（0，0）对位）
    gxCardLayer.position = ccp(GX_FATE_PACKAGE_X-gxCardLayer.cutRect.size.width/2,GX_FATE_PACKAGE_Y-gxCardLayer.cutRect.size.height/2);
//	gxCardLayer.position = ccpAdd(gxCardLayer.position, ccp(self.contentSize.width/2, self.contentSize.height/2));
	gxCardLayer.target = self;
//    if (iPhoneRuningOnGame()) {
//        gxCardLayer.scale=1.1f;
//    }
	for (NSDictionary *dict in arr) {
		[gxCardLayer addItemWithDict:dict];
	}
}
-(void)loadUsedFateList{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray *t_arr = [[GameConfigure shared] getPlayerFateList];
		NSDictionary* fateDict =[[GameDB shared] readDB:@"fate"];
		NSMutableDictionary *t_dict=nil;		
		NSMutableArray *fateUsedArr = [NSMutableArray array];
		
		if ([t_arr count]>0) {
			for (int q=IQ_RED; q>=IQ_WHITE; q--) {
				for (NSMutableDictionary *dict in t_arr) {
					int fid = [[dict objectForKey:@"fid"] intValue] ;
					NSString *key = [NSString stringWithFormat:@"%d",fid];
					int used = [[dict objectForKey:@"used"] intValue];
					if (used == FateStatus_used && q == [[[fateDict objectForKey:key] objectForKey:@"quality"] intValue]) {
						t_dict = [NSMutableDictionary dictionary];
						[t_dict setObject:[NSNumber numberWithInt:IST_FATE] forKey:@"itemSystemType"];
						[t_dict setObject:[dict objectForKey:@"id"] forKey:@"id"];
						[t_dict setObject:[dict objectForKey:@"fid"] forKey:@"bid"];
						[t_dict setObject:[dict objectForKey:@"level"] forKey:@"level"];
						[t_dict setObject:[dict objectForKey:@"exp"] forKey:@"exp"];
						[t_dict setObject:[dict objectForKey:@"isTrade"] forKey:@"isTrade"];
						[t_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
						[t_dict setObject:[NSNumber numberWithInt:used] forKey:@"used"];
						[t_dict setObject:[NSNumber numberWithInt:q]  forKey:@"quality"];						
						[fateUsedArr addObject:t_dict];												
					}
				}
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			//通知主线程绘制界面
			//
			[usedFateArray release];
			usedFateArray = fateUsedArr;
			[usedFateArray retain];
			//
			[self updateRoleInfoWithID:cardRoleRID fateArray:usedFateArray];			
		});
	});	
}

-(void)loadUnUsedFateList{

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray *t_arr = [[GameConfigure shared] getPlayerFateList];
		NSDictionary* fateDict =[[GameDB shared] readDB:@"fate"];
		NSMutableDictionary *t_dict=nil;
		NSMutableArray *fateNoUsedArr = [NSMutableArray array];		
		
		if ([t_arr count]>0) {
			for (int q=IQ_RED; q>=IQ_WHITE; q--) {
				for (NSMutableDictionary *dict in t_arr) {
					int fid = [[dict objectForKey:@"fid"] intValue] ;
					NSString *key = [NSString stringWithFormat:@"%d",fid];
					int used = [[dict objectForKey:@"used"] intValue];
					if (used == FateStatus_unused && q == [[[fateDict objectForKey:key] objectForKey:@"quality"] intValue]) {
						t_dict = [NSMutableDictionary dictionary];
						[t_dict setObject:[NSNumber numberWithInt:IST_FATE] forKey:@"itemSystemType"];
						[t_dict setObject:[dict objectForKey:@"id"] forKey:@"id"];
						[t_dict setObject:[dict objectForKey:@"fid"] forKey:@"bid"];
						[t_dict setObject:[dict objectForKey:@"level"] forKey:@"level"];
						[t_dict setObject:[dict objectForKey:@"exp"] forKey:@"exp"];
						[t_dict setObject:[dict objectForKey:@"isTrade"] forKey:@"isTrade"];
						[t_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
						[t_dict setObject:[NSNumber numberWithInt:used] forKey:@"used"];
						[t_dict setObject:[NSNumber numberWithInt:q]  forKey:@"quality"];	
						[fateNoUsedArr addObject:t_dict];						
					}
				}
			}
		}
		//fix chao
		[fateNoUsedArr sortUsingFunction:sortFateArray context:nil];
		//end
		dispatch_async(dispatch_get_main_queue(), ^{
			//通知主线程绘制界面
			//
			[UnUsedFateArray release];
			UnUsedFateArray = fateNoUsedArr;
			[UnUsedFateArray retain];
			//
			[self updateFatePackage:UnUsedFateArray];
		});
	});
}

-(void)loadFateList{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray *t_arr = [[GameConfigure shared] getPlayerFateList];
		NSDictionary* fateDict =[[GameDB shared] readDB:@"fate"];
		NSMutableDictionary *t_dict=nil;
		NSMutableArray *fateNoUsedArr = [NSMutableArray array];
		NSMutableArray *fateUsedArr = [NSMutableArray array];
		
		if ([t_arr count]>0) {
			for (int q=IQ_RED; q>=IQ_WHITE; q--) {
				for (NSMutableDictionary *dict in t_arr) {
					int fid = [[dict objectForKey:@"fid"] intValue] ;
					NSString *key = [NSString stringWithFormat:@"%d",fid];
					int used = [[dict objectForKey:@"used"] intValue];
					if (q == [[[fateDict objectForKey:key] objectForKey:@"quality"] intValue]) {
						t_dict = [NSMutableDictionary dictionary];
						[t_dict setObject:[NSNumber numberWithInt:IST_FATE] forKey:@"itemSystemType"];
						[t_dict setObject:[dict objectForKey:@"id"] forKey:@"id"];
						[t_dict setObject:[dict objectForKey:@"fid"] forKey:@"bid"];
						[t_dict setObject:[dict objectForKey:@"level"] forKey:@"level"];
						[t_dict setObject:[dict objectForKey:@"exp"] forKey:@"exp"];
						[t_dict setObject:[dict objectForKey:@"isTrade"] forKey:@"isTrade"];
						[t_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
						[t_dict setObject:[NSNumber numberWithInt:used] forKey:@"used"];
						[t_dict setObject:[NSNumber numberWithInt:q]  forKey:@"quality"];
						if (used == FateStatus_used ) {
							[fateUsedArr addObject:t_dict];
						}else{
							[fateNoUsedArr addObject:t_dict];
						}
						
					}
				}
			}
		}
		//fix chao
		[fateNoUsedArr sortUsingFunction:sortFateArray context:nil];
		//end
		dispatch_async(dispatch_get_main_queue(), ^{
			//通知主线程绘制界面
			//
			[usedFateArray release];
			usedFateArray = fateUsedArr;
			[usedFateArray retain];
			//
			[UnUsedFateArray release];
			UnUsedFateArray = fateNoUsedArr;
			[UnUsedFateArray retain];
			//
			[self updateRoleInfoWithID:cardRoleRID fateArray:usedFateArray];
			[self updateFatePackage:UnUsedFateArray];
		});
	});
}
-(void)updateFateForceWithRoleID:(NSInteger)roleRID{
	CCLabelTTF *fateForceLabel = (CCLabelTTF *)[self getChildByTag:GX_FATE_FORCE_LABEL_TAG];
	if (fateForceLabel) {
		//[fateForceLabel setString:[NSString stringWithFormat:@"星力 : %d",[self getFateValueWithRID:roleRID]]];
        [fateForceLabel setString:[NSString stringWithFormat:NSLocalizedString(@"guanxing_fate",nil),[self getFateValueWithRID:roleRID]]];
	}
}
-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
	CCLOG(@"selectedEvent!");
	RoleCard *card_ = (RoleCard*)_listItem;
	CCLOG(@"Role = %d",card_.RoleID);
	//-----------------
	//添加需要的属性
	//
	cardRoleRID = card_.RoleID;
	[self updateFateForceWithRoleID:cardRoleRID];
	//[self scheduleOnce:@selector(loadUsedFateList) delay:GX_WAIT_RENDER_TIME];
	[self loadUsedFateList];
	//[self updateRoleInfoWithID:card_.RoleID fateArray:usedFateArray];
}
-(BOOL)checkFateWithTouch:(UITouch *)touch{
    if (NO == isSend) {
        CGPoint touchLocation = [touch locationInView:touch.view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        Card *tCard;
        for (int i = GX_FATE_POS01_TAG; i<= GX_FATE_POS06_TAG; i++) {
            tCard = (Card *)[self getChildByTag:i];
            //[self changeTouchGXCard:(GXCard *)[self getChildByTag:i]];
            if (CGRectContainsPoint(tCard.rect, touchLocation) && YES == [tCard isOwnItem]) {
                isTouchGXItem = YES;
                [self changeTouchGXCard:tCard];
                cardPlace = i-GX_FATE_POS01_TAG+1;
                return YES;
            }
        }
    }
	return NO;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isSend) {
		isLayerTouch = NO;
		isCardsTouch = NO;
		isMoveItem = NO;
		isMovePackage = NO;
		isMoveTouch = NO;
        isMenuTouch = NO;
        isTouch = NO;
        CCLOG(@"GuanXing ccTouchBegan ...");
		return YES;
    }
	//fix chao
	if (isTouch) {
		isMenuTouch = NO;
		isLayerTouch = NO;
		isCardsTouch = NO;
		isMoveItem = NO;
		isMovePackage = NO;
		isMoveTouch = NO;
		CCLOG(@"GuanXing ccTouchBegan is touch...");
		return YES;
	}
	isTouch = YES;
	//end
	CCLOG(@"GuanXing ccTouchBegan");
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpaceAR:touchLocation];
	isMenuTouch = NO;
	isLayerTouch = NO;
	isCardsTouch = NO;
	////
	touchStartTime = [NSDate timeIntervalSinceReferenceDate];
	//
    
    if (startTouch) {
        [startTouch release];
        startTouch = nil;
    }
	
	startTouch = touch;
	[startTouch retain];
    
    
	//
	isMoveItem = NO;
	isMovePackage = NO;
	isMoveTouch = NO;	
	[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:CL_MOVE_ITEM_TIME/1000.0f],[CCCallFuncN actionWithTarget:self selector:@selector(isMoveItemBackCall)], nil]];
	////
	if ([cards ccTouchBegan:touch withEvent:event]) {
		isCardsTouch = YES;
		CCLOG(@"GuanXing menu ccTouchBegan111");
		return YES;
	}
	//fix chao
	int w = self.anchorPoint.x*self.contentSize.width;
	int h = self.anchorPoint.y*self.contentSize.height;
	//end
	CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
	if ( [menu ccTouchBegan:touch withEvent:event] ) {
		CCLOG(@"GuanXing menu ccTouchBegan");
		isMenuTouch = YES;
		return YES;
	}else if([gxCardLayer ccTouchBegan:touch withEvent:event]){
		isLayerTouch = YES;
		CCLOG(@"GuanXing menu ccTouchBegan 222");
		return YES;
	}else if(touchLocation.x+w>=0&&touchLocation.y+h>=0 && touchLocation.x+w<=self.contentSize.width && touchLocation.y+h<=self.contentSize.height){
		CCLOG(@"GuanXing Layer ccTouchBegan");
		return YES;
	}
	CCLOG(@"self.contentSize.width:%f self.contentSize.height:%f",self.contentSize.width,self.contentSize.height);
	CCLOG(@"x:%f y:%f",touchLocation.x,touchLocation.y);
	CCLOG(@"GuanXing menu ccTouchBegan no...");
    return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	CCLOG(@"ccTouchMoved");
	if ( isMoveTouch == NO ) {
		if (isMoveItem == NO && [NSDate timeIntervalSinceReferenceDate]-touchStartTime < CL_MOVE_PACKAGE_TIME) {
			isMovePackage = YES;
		}else{
			isMoveItem = YES;
		}
	}
	isMoveTouch = YES;//第一次进入标志	
	if (isMovePackage) {
	}else if (isMoveItem) {
	}
	///////////////
	
	if (isTouchGXItem && NO == isSend) {
		CCLOG(@"touch.x");
		CCSprite *spr = (CCSprite *)[self getChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG];
		spr.position = touchLocation;		
	}

	if ( isMenuTouch ) {
		[menu ccTouchMoved:touch withEvent:event];
		CCLOG(@"GuanXing menu ccTouchMoved");
	}
	if (isLayerTouch) {
		CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
		[gxCardLayer ccTouchMoved:touch withEvent:event];
		CCLOG(@"GuanXing layer ccTouchMoved");
	}
	if (isCardsTouch) {
		[cards ccTouchMoved:touch withEvent:event];
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isSend) {
        return;
    }
	CCLOG(@"ccTouchEnded");
	BOOL isSynthesizeFate = YES;
	isTouchGXItem = NO;
	////////
	if (isMoveItem ==NO && isMoveTouch == NO) {
		//TODO 显示弹出框
		
		CGPoint touchLocation = [touch locationInView:touch.view];
		touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
		touchLocation = [self convertToNodeSpace:touchLocation];
		Card *tCard;
		for (int i = GX_FATE_POS01_TAG; i<= GX_FATE_POS06_TAG; i++) {
			tCard = (Card *)[self getChildByTag:i];
			//[self changeTouchGXCard:(GXCard *)[self getChildByTag:i]];
			if (CGRectContainsPoint(tCard.rect, touchLocation) ) {
				if (YES == [tCard isOwnItem]) {
					[self showMessageWithCard:tCard];
				}else if(YES == [tCard itemClose]){					
					NSDictionary *setDict = [[GameDB shared] getGlobalConfig];
					NSString *fateLevelsStr = [setDict objectForKey:@"fateLevels"];
					NSArray *levelArr =[fateLevelsStr componentsSeparatedByString:@"|"];
					int openLevel = 0;
					if ([levelArr count] == 6) {						
						int index = i-GX_FATE_POS01_TAG;
						if (index>=0&& index<6) {							
							openLevel = [[levelArr objectAtIndex:index] intValue];				
						}else{
							CCLOG(@"part tag is errorr");
						}
					}else{
						CCLOG(@"get fate level open is errorr");
					}
					//NSString *str = [NSString stringWithFormat:@"解锁等级:%d#ff0000",openLevel];
                    NSString *str = [NSString stringWithFormat:NSLocalizedString(@"guanxing_open_level",nil),openLevel];
					CCSprite *draw = drawString(str, CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
					[InfoAlert show:self drawSprite:draw parent:self position:ccpAdd(tCard.position,ccp(-10,draw.contentSize.height)) anchorPoint:ccp(0, 0) offset:CGSizeMake(18, 18)];
				}

				//[self showMessageWithCard:tCard];
				isSynthesizeFate = NO;
				//fix chao
				[touchCard setItemVisible:YES];
				[self changeTouchGXCard:nil];
				//end
				break;
			}
		}
		
		CCLOG(@"show txt box");
	}else{
		if (isMovePackage) {
			//TODO

		}else if (isMoveItem) {
			//TODO
		}
	}
	
	////
	touchStartTime = -1;
	isMoveTouch = YES;//停isMoveItemBackCall 动作
    
    if (startTouch) {
        [startTouch release];
        startTouch = nil;
    }
    
	///////
	////
	if (isSynthesizeFate) {
		[self synthesizeFate];
	}	
	//[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
	
	/*
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	*/
	
	if ( isMenuTouch ) {
		[menu ccTouchEnded:touch withEvent:event];
		CCLOG(@"GuanXing menu ccTouchEnded");
	}
	if (isLayerTouch) {
		CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
		[gxCardLayer ccTouchEnded:touch withEvent:event];
		CCLOG(@"GuanXing layer ccTouchEnded");
	}else{
        CardLayer *gxCardLayer = (CardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
        [gxCardLayer updatePageWithMovePos:ccp(0, 0)];
    }
	if (isCardsTouch) {
		[cards ccTouchEnded:touch withEvent:event];
	}
	//fix chao
	isTouch = NO;
	//end
}
//
-(void)isMoveItemBackCall{
	if (isMoveTouch == NO) {
		isMoveItem = YES;
        if (startTouch && NO == isSend) {
            CGPoint touchLocation = [startTouch locationInView:startTouch.view];
            touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
            touchLocation = [self convertToNodeSpace:touchLocation];
            if ([self checkFateWithTouch:startTouch]) {
                CCSprite *spr = (CCSprite *)[self getChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG];
                [spr setPosition:touchLocation];			
            }
        }else{
            isMoveItem = NO;
        }
		CCLOG(@"set move item");
	}
	
}
-(CCSprite*)getWearFateTextSprite:(NSInteger)_id{
	CCSprite *textSpr = nil;
	NSDictionary *_dict = [[GameConfigure shared] getPlayerFateInfoById:_id];
	if (!_dict) {
		CCLOG(@"message box fate dict is nil");
		return nil;
	}
	int fid = [[_dict objectForKey:@"fid"] intValue];
	int f_level = [[_dict objectForKey:@"level"] intValue] ;
	if (f_level <= 0 || f_level > 10) {
		CCLOG(@" getFateMessageWithItemID f_level = 0");
		return nil;
	}
	NSDictionary *fateDict = [[GameDB shared] getFateInfo:fid];
	if (!fateDict) {
		CCLOG(@"message box fateDict dict is nil");
		return nil;
	}
	int qu=[[fateDict objectForKey:@"quality"]integerValue];
	//NSString *name = [NSString stringWithFormat:@"装备 #eeee00#16#0|%@",[fateDict objectForKey:@"name"]];
    NSString *name = [NSString stringWithFormat:NSLocalizedString(@"guanxing_equip",nil),[fateDict objectForKey:@"name"]];
//	if (iPhoneRuningOnGame()) {
//		name=[name stringByReplacingOccurrencesOfString:@"#16#" withString:@"#8#"];
//	}
	//NSString *cmd = [name stringByAppendingFormat:@"#%@%@| 成功#eeee00#16#0*",getQualityColorStr(qu),@"#20#0"];
    NSString *cmd = [name stringByAppendingFormat:NSLocalizedString(@"guanxing_equip_ok",nil),getQualityColorStr(qu),@"#20#0"];

	////
	NSDictionary *nowFateLevelDict = [[GameDB shared] getFateLevelInfo:fid level:f_level];
	NSString *t_str = [NSString stringWithFormat:@""];
	t_str = [t_str stringByAppendingString:getAttrDescribetion(nowFateLevelDict, NSLocalizedString(@"guanxing_upgrade_str",nil))];
		 
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}

	textSpr = drawString(cmd, CGSizeMake(150,0), getCommonFontName(FONT_1), 16, 25, getHexStringWithColor3B(ccWHITE));
	return textSpr;
}
-(void)wearFateText:(BOOL)isOK withItemID:(NSInteger)itemID{	
	
	//fix chao
	CGPoint pos = ccp(GX_ROLE_BACK_X,cFixedScale(100)+self.contentSize.height/2);
	CCSprite* spr=nil;
	if (isOK) {
		spr = [self getWearFateTextSprite:itemID];
		//spr = [CCLabelTTF labelWithString:@"装备成功" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
	}else{
		if ([self isEXPFateWithItemID:itemID]) {
			//spr = [CCLabelTTF labelWithString:@"经验星力 不能装备！" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
            spr = [CCLabelTTF labelWithString:NSLocalizedString(@"guanxing_not_equip",nil) fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
		}else{
			//spr = [CCLabelTTF labelWithString:@"装备失败" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
            spr = [CCLabelTTF labelWithString:NSLocalizedString(@"guanxing_equip_fail",nil) fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
		}
	}

	[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
	//end
}
-(void)textBackCall:(id)sender{
	[self removeChild:sender cleanup:YES];
}
-(BOOL)isEXPFateWithItemID:(NSInteger)itemID{
	NSDictionary *_dict = [[GameConfigure shared] getPlayerFateInfoById:itemID];
	if (_dict) {
		int fid = [[_dict objectForKey:@"fid"] intValue];
		int f_level = [[_dict objectForKey:@"level"] intValue] ;
		NSDictionary *nowFateLevelDict = [[GameDB shared] getFateLevelInfo:fid level:f_level];
		if (!nowFateLevelDict && fid == 37) {
			return YES;
		}
	}
	return NO;
}
-(BOOL)isEqualFateWithCard:(Card*)_card otherCard:(Card*)_otherCard{
	
	if (!_card||!_otherCard) {
		return NO;
	}
	
	NSDictionary *nowFateLevelDict = [self getFateWithFid:[_card getBaseID] level:[_card itemLevel]];
	NSDictionary *bodyFateLevelDict = [self getFateWithFid:[_otherCard getBaseID] level:[_otherCard itemLevel]];
	
	if ([_card getBaseID]==[_otherCard getBaseID]) {
		return YES;
	}
		
	BaseAttribute nowFateAttribute = BaseAttributeFromDict(nowFateLevelDict);
	BaseAttribute bodyFateAttribute = BaseAttributeFromDict(bodyFateLevelDict);
	
	NSDictionary *nowFateDict = BaseAttributeToDictionary(nowFateAttribute);
	NSDictionary *bodyFateDict = BaseAttributeToDictionary(bodyFateAttribute);
	
	for (NSString *key in nowFateDict.allKeys) {
		float t1 = [[nowFateDict objectForKey:key] floatValue];
		float t2 = [[bodyFateDict objectForKey:key] floatValue];
		
		if((t1>0 && t2==0)||(t1==0 && t2>0)){
			return NO;
		}
	}
	
	return YES;
}
-(BOOL)isCouldWearFateWithCard:(Card*)_card{
	if (!_card) {
		return NO;
	}	
	////
	////
	for (int i = GX_FATE_POS01_TAG; i<= GX_FATE_POS06_TAG; i++) {
		Card *tCard = (Card *)[self getChildByTag:i];
		if ([tCard isOwnItem]) {
			////
			if ([self isEqualFateWithCard:_card otherCard:tCard]) {
				return NO;
			}
		}
	}
	return YES;
}
-(BOOL)checkWearFate{
	if ([touchCard getItemID] <= 0 ) {
		return NO;
	}
	if ([self isEXPFateWithItemID:[touchCard getItemID]]) {
		return NO;
	}
	return YES;
}
///比较 元神1 是否比 元神2 高级
-(BOOL)compareCard1:(Card*)card1 card2:(Card*)card2{
	if ([card2 itemQuality]<[card1 itemQuality]) {
		return YES;
	}
	return NO;
}
-(NSInteger)getFateLevelWithFid:(NSInteger)fid exp:(NSInteger)exp{
	////
	NSDictionary *levelDict;
	NSNumber *expNumber;
	int level=1;
	for (int i=1; i<11; i++) {
		//soul
		levelDict = [[GameDB shared] getFateLevelInfo:fid level:i];
		if (levelDict) {
			expNumber = [levelDict objectForKey:@"exp"];
			if ([expNumber intValue]<=exp) {
				level = i;				
			}
		}
	}
	if (level>10) {
		level = 10;
	}
	return level;
}
-(BOOL)synthesizeFateFrom:(Card*)fromCard to:(Card*)toCard{
	if ( !fromCard || !toCard ) {
		CCLOG(@"card is nil");
		return NO;
	}	
	
	if (toCard != fromCard) {
		Card *cardMin;
		Card *cardMax;
		if ([self isEXPFateWithItemID:[toCard getItemID]] && [self isEXPFateWithItemID:[fromCard getItemID]]) {
			//CCSprite *spr = [CCLabelTTF labelWithString:@"经验星力 不能合成！" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
			CCSprite *spr = [CCLabelTTF labelWithString:NSLocalizedString(@"guanxing_exp_fate",nil) fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
			CGPoint pos = ccp(GX_ROLE_BACK_X,cFixedScale(100));
			
			[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
			[touchCard setItemVisible:YES];////
			[self changeTouchGXCard:nil];
			return NO;
		}
		if ([self isEXPFateWithItemID:[toCard getItemID]]) {
			cardMax = fromCard;
			cardMin = toCard;
		}else if([self isEXPFateWithItemID:[fromCard getItemID]]){
			cardMax = toCard;
			cardMin = fromCard;
		}else{
			if ([self compareCard1:fromCard card2:toCard]) {
				////
				if (![self isEqualFateWithCard:fromCard otherCard:toCard]) {
					if (![self isCouldWearFateWithCard:fromCard]&& ![fromCard itemUsed] && [toCard itemUsed]) {
						//[self showTextWithString:@"身上已有同类星力!"];
                        [self showTextWithString:NSLocalizedString(@"guanxing_body_use",nil)];
						[touchCard setItemVisible:YES];////
						[self changeTouchGXCard:nil];
						return NO;
					}
				}
				cardMax = fromCard;
				cardMin = toCard;
			}else{
				cardMax = toCard;
				cardMin = fromCard;
			}
		}
		//TODO 合并命格 ??????
		
		////
		NSDictionary *fateDictMax = [[GameDB shared] getFateInfo:[cardMax getBaseID]];
		NSDictionary *fateDictMin = [[GameDB shared] getFateInfo:[cardMin getBaseID]];
		NSString *nameMaxStr = [NSString stringWithFormat:@"%@ %@#20#0",[fateDictMax objectForKey:@"name"],getHexStringWithColor3B(getColorByQuality([cardMax itemQuality]))];
		NSString *nameMinStr = [NSString stringWithFormat:@" %@ %@#20#0",[fateDictMin objectForKey:@"name"],getHexStringWithColor3B(getColorByQuality([cardMin itemQuality]))];
		NSString *expStr = [NSString stringWithFormat:@"%d#00FF00#20#0",[cardMin itemExp]];
		//
		int maxExp = [self getFateMaxExpWithFid:[cardMax getBaseID]];
		if (maxExp <= [cardMax itemExp]) {
			//[self showTextWithString:@"合并的星力已是最高级"];
            [self showTextWithString:NSLocalizedString(@"guanxing_fate_top",nil)];
			[touchCard setItemVisible:YES];////
			[self changeTouchGXCard:nil];
			return NO;
		}
		if (maxExp>0) {
			NSString *name= nil;
			int countExp = [cardMax itemExp]+[cardMin itemExp];
			if (maxExp<countExp) {
				//name = [NSString stringWithFormat:@"%@|将吸收#eeeeee#20#0|%@|获得#eeeeee#20#0|%@|经验,升级为#eeeeee#20#0|最高#00FF00#20#0|级,并有|%d#00FF00#20#0|经验溢出,是否继续?#eeeeee#20#0*^38*",nameMaxStr,nameMinStr,expStr,(countExp-maxExp)];
                name = [NSString stringWithFormat:NSLocalizedString(@"guanxing_synthesize_over",nil),nameMaxStr,nameMinStr,expStr,(countExp-maxExp)];
				//name = [NSString stringWithFormat:@"合并的总经验超出最高级经验 %d ,是否继续?",(countExp-maxExp)];
			}else{
				int level = [self getFateLevelWithFid:[cardMax getBaseID] exp:countExp];
				if (level>[cardMax itemLevel]) {
					NSString *levelStr = [NSString stringWithFormat:@"%d#00FF00#20#0",level];
					//name = [NSString stringWithFormat:@"%@|将吸收#eeeeee#20#0|%@|获得#eeeeee#20#0|%@|经验并升级为#eeeeee#20#0|%@|级，是否继续?#eeeeee#20#0*^38*",nameMaxStr,nameMinStr,expStr,levelStr];
                    name = [NSString stringWithFormat:NSLocalizedString(@"guanxing_synthesize_uplevel",nil),nameMaxStr,nameMinStr,expStr,levelStr];
				}else{
					//name = [NSString stringWithFormat:@"%@|将吸收#eeeeee#20#0|%@|获得#eeeeee#20#0|%@|经验，是否继续?#eeeeee#20#0*^38*",nameMaxStr,nameMinStr,expStr];
                    name = [NSString stringWithFormat:NSLocalizedString(@"guanxing_synthesize",nil),nameMaxStr,nameMinStr,expStr];
				}
			}
			///
			[self addDialogWithTaget:GXMT_synthesize string:name];
		}else{
			[touchCard setItemVisible:YES];////
			[self changeTouchGXCard:nil];
			return NO;
		}
	}else{
		[touchCard setItemVisible:YES];////
		[self changeTouchGXCard:nil];
		return NO;
	}
	return YES;
}
-(void)addDialogWithTaget:(GuanXingMessageType)type string:(NSString*)str{

	if (GXMT_synthesize>type || GXMT_equipOff<type) {
		CCLOG(@"guan xing message type is error");
		return;
	}
	
	if (str) {
		if ([self getChildByTag:GX_FATE_MESSAGE_BOX_TAG]) {
            return;
        }
		CFDialog *dialog = [CFDialog create:self background:1];
		CCSprite *strSprite = drawString(str,CGSizeMake(492, 92),getCommonFontName(FONT_1),18,26,@"ffffff");
		CCMenuItem *bt_yes = nil;
		CCMenuItem *bt_no = nil;
		
		CGPoint yesPos = ccp(cFixedScale(96), cFixedScale(50));
		CGPoint noPos = ccp(cFixedScale(340), cFixedScale(50));
		
		//fix chao
		//确定 按钮		
//		NSArray *sprArrYes = getLabelSprites(@"images/ui/button/bt_background.png", @"images/ui/button/bt_background.png", @"确 认", 20, ccc4(65,197,186, 255), ccc4(65,197,186, 255));
		NSArray *sprArrYes = getBtnSpriteWithStatus(@"images/ui/button/bt_ok");
		//取消 按钮
//		NSArray *sprArrNo = getLabelSprites(@"images/ui/button/bt_background.png", @"images/ui/button/bt_background.png", @"取 消", 20, ccc4(65,197,186, 255), ccc4(65,197,186, 255));
		NSArray *sprArrNo = getBtnSpriteWithStatus(@"images/ui/button/bt_cancel");
		//end 
		if (GXMT_synthesize == type ) {
			bt_yes = [CCMenuItemSprite itemWithNormalSprite:[sprArrYes objectAtIndex:0] selectedSprite:[sprArrYes objectAtIndex:1] target:self selector:@selector(systhesizeBottonYesBackCall:)];			
		}else if (GXMT_synthesizeAll == type) {
			bt_yes = [CCMenuItemSprite itemWithNormalSprite:[sprArrYes objectAtIndex:0] selectedSprite:[sprArrYes objectAtIndex:1] target:self selector:@selector(onekeySynthesizeFateBackCall:)];
		}else if (GXMT_equipOff == type) {
			bt_yes = [CCMenuItemSprite itemWithNormalSprite:[sprArrYes objectAtIndex:0] selectedSprite:[sprArrYes objectAtIndex:1] target:self selector:@selector(unUsedBottonYesBackCall:)];
		}
		//
		if (GXMT_synthesize == type  || GXMT_synthesizeAll == type || GXMT_equipOff == type ) {
			bt_no = [CCMenuItemSprite itemWithNormalSprite:[sprArrNo objectAtIndex:0] selectedSprite:[sprArrNo objectAtIndex:1] target:self selector:@selector(bottonNoBackCall:) ];
		}		
		////
		if (bt_yes) {
			bt_yes.anchorPoint=ccp(0, 0.5);			
			[[dialog menu] addChild:bt_yes z:1];
			[bt_yes setPosition:yesPos];
            if (iPhoneRuningOnGame()) {
                bt_yes.scale = 1.3f;
            }
		}
		if (bt_no) {
			[[dialog menu] addChild:bt_no z:1];
			bt_no.anchorPoint=ccp(0, 0.5);
			[bt_no setPosition:noPos];
            if (iPhoneRuningOnGame()) {
                bt_no.scale = 1.3f;
            }
		}
		////
		if (strSprite) {
			[dialog addChild:strSprite];
			strSprite.position = ccp(dialog.contentSize.width/2,dialog.contentSize.height/2);
		}		
		[self addChild:dialog z:99 tag:GX_FATE_MESSAGE_BOX_TAG];
		
		dialog.position = ccp(self.contentSize.width/2-dialog.contentSize.width/2,
							  self.contentSize.height/2-dialog.contentSize.height/2);
		
		
	}else{
		CCLOG(@"dialog string is nil");
	}
}

-(BOOL)checkIsOpenWithTag:(NSInteger)tag{
//GX_FATE_POS01_TAG:GX_FATE_POS06_TAG
	NSDictionary *setDict = [[GameDB shared] getGlobalConfig];
	NSString *fateLevelsStr = [setDict objectForKey:@"fateLevels"];
	NSArray *levelArr =[fateLevelsStr componentsSeparatedByString:@"|"];	
	if ([levelArr count] == 6) {
		NSDictionary *roleDict = [[GameConfigure shared] getPlayerInfo];
		int level = [[roleDict objectForKey:@"level"] intValue];
		int index = tag-GX_FATE_POS01_TAG;
		if (index>=0&& index<6) {
			if ([[levelArr objectAtIndex:index] intValue]<=level) {
				return YES;
			}else{
				return NO;
			}
		}else{
			CCLOG(@"part tag is errorr");
		}
	}else{
		CCLOG(@"get fate level open is errorr");
	}
	return NO;
}

-(void)synthesizeFate{
	////
    if (!touchCard) {
        return;
    }
	tagetCard = nil;
	
	CCSprite *spr = (CCSprite *)[self getChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG];
	Card *tCard = nil;
	for (int i = GX_FATE_POS01_TAG; i<= GX_FATE_POS06_TAG; i++) {
		tCard = (Card *)[self getChildByTag:i];
		if (CGRectContainsPoint(tCard.rect, spr.position)) {
			if ([self checkIsOpenWithTag:i]) {
				tagetCard = tCard;
				cardPlace = i-GX_FATE_POS01_TAG+1;
				if ([tagetCard isOwnItem]) {
					CCLOG(@"gx card layer isOwnItem");
					[self synthesizeFateFrom:touchCard to:tagetCard];
					//[touchCard setItemVisible:YES];////
					//return;////
				}else{
					//穿命格
					if ([self checkWearFate]) {
						if (![self isCouldWearFateWithCard:touchCard] && !touchCard.itemUsed) {
							//[self showTextWithString:@"身上已有同类星力!"];
                            [self showTextWithString:NSLocalizedString(@"guanxing_body_use",nil)];
							[touchCard setItemVisible:YES];
							[self changeTouchGXCard:nil];
						}else{
							[self setFateIsUsed:YES ];
						}
						//return;////
					}else{
						//装备失败
						[self wearFateText:NO withItemID:[touchCard getItemID]];
						[touchCard setItemVisible:YES];
						[self changeTouchGXCard:nil];
						//return;
					}
					
				}
			}else{
				//fix chao
				
				//CGPoint pos = ccp(0,cFixedScale(100));
				CGPoint pos = ccp(GX_ROLE_BACK_X,cFixedScale(100)+self.contentSize.height/2);
                
				//CCSprite* spr = [CCLabelTTF labelWithString:@"星位未开放！" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
                CCSprite* spr = [CCLabelTTF labelWithString:NSLocalizedString(@"guanxing_not_open",nil) fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
				[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
				[touchCard setItemVisible:YES];
				[self changeTouchGXCard:nil];
				
				if(iPhoneRuningOnGame()){
					spr.scale = 0.7;
				}
				
				//return;
				//end
			}
			return;
		}
	}
	
	//cards
	GXCardLayer *gxCardLayer = (GXCardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
	NSArray *arr = [gxCardLayer getLayerItemArray];
	CGPoint pos = CGPointZero;
	//CGPoint cardPos = CGPointZero;
	//CGPoint cardPos;
	
	pos = [self convertToWorldSpace:spr.position];
	if ([gxCardLayer checkPosIsInNowPage:pos]) {
		for (tCard in arr ) {
			//cardPos = tCard.position;
			
			if (CGRectContainsPoint(tCard.rect, [tCard.parent convertToNodeSpace:pos] ) && [gxCardLayer checkIsInNowPage:tCard]) {
				tagetCard = tCard;
				if ([tagetCard isOwnItem]) {
					CCLOG(@"gx card layer isOwnItem");
					[self synthesizeFateFrom:touchCard to:tagetCard];
					//[touchCard setItemVisible:YES];////
					//return;////
				}else{
					if ([touchCard itemUsed]) {
						//脱命格
						[self setFateIsUsed:NO ];
					}else{
						[tagetCard changeItemWithOther:touchCard];
						[touchCard removeItem];
						[self changeTouchGXCard:nil];
						//[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
					}
					
				}
				return;////
			}
		}
		//脱命格
		if ([touchCard itemUsed]){
			[self setFateIsUsed:NO ];
			return;////
		}		
	}
    //fix chao
    if ([touchCard itemUsed] && (!CGRectContainsPoint(touchCard.rect, spr.position))) {
        //脱命格
        [self setFateIsUsed:NO ];
        return;
    }
    //end
	//
	[touchCard setItemVisible:YES];
	[self changeTouchGXCard:nil];
	//[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
}
-(void)onekeySynthesizeFate{
	//
	if ([self isOwnOutExpFate]) {
		//[self addDialogWithTaget:GXMT_synthesizeAll string:@"同类星力合并后，有经验溢出，你确定继续合并吗? #eeeeee#20#0*^38*"];
        [self addDialogWithTaget:GXMT_synthesizeAll string:NSLocalizedString(@"guanxing_same_synthesize_over",nil)];
	}else{
		///
		//[self addDialogWithTaget:GXMT_synthesizeAll string:@"你确定同类星力的合并吗? #eeeeee#20#0*^38*"];
        [self addDialogWithTaget:GXMT_synthesizeAll string:NSLocalizedString(@"guanxing_same_synthesize",nil)];
	}
}

-(BOOL)isOwnOutExpFate{
	
	GXCardLayer *gxCardLayer = (GXCardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
	if (gxCardLayer) {
		
		NSArray *arr = [gxCardLayer getLayerItemArray];
		
		//int exp = 0;
		
		for (int i=0;i<[arr count];i++) {
			//2013-3-24
			//exp = 0;
			
			int exp = 0;
			
			Card * card = [arr objectAtIndex:i];
			
			int maxExp = [self getFateMaxExpWithFid:[card getBaseID]];
			
			if ( [card isOwnItem] && maxExp>[card itemExp] && [card getBaseID]!=37) {
				
				exp = [card itemExp];
				
				for (int j=i+1;j<[arr count];j++) {
					
					Card *t_card = [arr objectAtIndex:j];
					
					if ([t_card isOwnItem] && 
						[t_card itemQuality]==[card itemQuality] && 
						maxExp>[t_card itemExp]
						) {
						
						if([t_card getBaseID]!=[card getBaseID]){
							if([self isEqualFateWithCard:t_card otherCard:card]){
								exp += [t_card itemExp];
							}
						}else{
							exp += [t_card itemExp];
						}
						
						if (maxExp>0 && exp>maxExp) {
							return YES;
						}
						
					}
				}
				
			}
		}
		
	}
	
	return NO;
}

-(BOOL)checkOnekeySynthesizeFate{
	if([UnUsedFateArray count]>0){
		return YES;
	}
	return NO;
}
-(void)showTextWithString:(NSString*)str{
	if (str) {
		//CGPoint pos = ccp(400, self.contentSize.height/2+100);
		CGPoint pos = ccp(GX_ROLE_BACK_X,cFixedScale(100)+self.contentSize.height/2);
		CCSprite* spr = [CCLabelTTF labelWithString:str fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(26)];
		[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
	}

}
//end
-(void)onekeySynthesizeFateBackCall:(id)sender{
	[self removeChildByTag:GX_FATE_MESSAGE_BOX_TAG cleanup:YES];
	NSDictionary *dict = [NSDictionary dictionary];
	if ([self checkOnekeySynthesizeFate]) {
        //
        isSend = YES;
		[GameConnection request:@"mergeAllFt" data:dict target:self call:@selector(didOnekeySynthesizeFate:)];
	}else{
		//[self showTextWithString:@"无合成星力"];
        [self showTextWithString:NSLocalizedString(@"guanxing_no_synthesize",nil)];
	}
}
////穿命格yes / 脱命格 no
-(void)setFateIsUsed:(BOOL)isUsed{
	if (isUsed) {
        //
        isSend = YES;
		[GameConnection request:@"wearFt" data:[self getDataDict] target:self call:@selector(didUsedFate::) arg:[self getSelectorDict]];
		////
		[touchCard setItemVisible:YES];
		[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
	}else{
		////
		int max = [[GameConfigure shared] getPlayerPackageMaxCapacity];
		if (max <= ([[GameConfigure shared] getPlayerPackageItemCount]) ) {
			//[self showTextWithString:@"行囊已满，请整理行囊！"];
            [self showTextWithString:NSLocalizedString(@"guanxing_package_full",nil)];
			[touchCard setItemVisible:YES];
			[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
			return;
		};
		NSDictionary *fateDict = [[GameDB shared] getFateInfo:[touchCard getBaseID]];
		//NSString* str=@"你确要卸下 #eeeeee#20#0|%@%@#20#0| 吗?#eeeeee#20#0*^38*";
        NSString* str=NSLocalizedString(@"guanxing_take_off",nil);
//		if (iPhoneRuningOnGame()) {
//			str=[str stringByReplacingOccurrencesOfString:@"#20" withString:@"#10#"];
//		}
		NSString *name = [NSString stringWithFormat:str,[fateDict objectForKey:@"name"],getHexStringWithColor3B(getColorByQuality([touchCard itemQuality]))];
		///
		[self addDialogWithTaget:GXMT_equipOff string:name];
	}

}
-(void)systhesizeBottonYesBackCall:(id)sender{
	[self removeChildByTag:GX_FATE_MESSAGE_BOX_TAG cleanup:YES];
	NSMutableDictionary *tDict = [NSMutableDictionary dictionary];
	[tDict setObject:[NSNumber numberWithInt:[touchCard getItemID]] forKey:@"id1"];
	[tDict setObject:[NSNumber numberWithInt:[tagetCard getItemID]] forKey:@"id2"];
	if ( [touchCard itemUsed]|| [tagetCard itemUsed] ) {
		[tDict setObject:[NSNumber numberWithInt:cardRoleID] forKey:@"rid"];
	}
    //
    isSend = YES;
	[GameConnection request:@"mergeFt" data:tDict target:self call:@selector(didSynthesizeFate::) arg:[self getSelectorDict]];
	////
	[touchCard setItemVisible:YES];
	[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
}
-(void)bottonNoBackCall:(id)sender{
	[self removeChildByTag:GX_FATE_MESSAGE_BOX_TAG cleanup:YES];
	[touchCard setItemVisible:YES];
	[self changeTouchGXCard:nil];
}
-(void)unUsedBottonYesBackCall:(id)sender{
	[self removeChildByTag:GX_FATE_MESSAGE_BOX_TAG cleanup:YES];
    //
    isSend = YES;
	[GameConnection request:@"tackOffFt" data:[self getDataDict] target:self call:@selector(didUnUsedFate::) arg:[self getSelectorDict]];
	////
	[touchCard setItemVisible:YES];
	[self removeChildByTag:GX_FATE_FORCE_TOUCHCARD_TAG cleanup:YES];
}
-(NSDictionary*)getDataDict{
	NSMutableDictionary *tDict = [NSMutableDictionary dictionary];
	[tDict setObject:[NSNumber numberWithInt:[touchCard getItemID]] forKey:@"id"];
	[tDict setObject:[NSNumber numberWithInt:cardRoleID] forKey:@"rid"];
	[tDict setObject:[NSNumber numberWithInt:cardPlace] forKey:@"place"];
	
	return tDict;
}
-(NSMutableArray*)getDictArrayWithArray:(NSArray*)array_{
    NSMutableArray *mutArray = [NSMutableArray array];
    NSMutableDictionary *t_dict = nil;
    for (Card *tCard in array_) {
        t_dict = [NSMutableDictionary dictionary];
        [t_dict setObject:[NSNumber numberWithInt:[tCard getItemType]] forKey:@"itemSystemType"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard getItemID]] forKey:@"id"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard getBaseID]] forKey:@"bid"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard itemLevel]] forKey:@"level"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard itemExp]] forKey:@"exp"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard isTrade]] forKey:@"isTrade"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard itemCount]] forKey:@"count"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard itemUsed]] forKey:@"used"];
        [t_dict setObject:[NSNumber numberWithInt:[tCard itemQuality]]  forKey:@"quality"];
        [mutArray addObject:t_dict];
    }
    
    //[mutArray sortUsingFunction:sortFateArray context:nil];
    return mutArray;
}
-(Card *)getNoItemCard{
	GXCardLayer *gxCardLayer = (GXCardLayer *)[self getChildByTag:GX_FATE_FORCE_PACKAGE_TAG];
	NSArray *arr = [gxCardLayer getLayerItemArray];
	for (Card *tCard in arr ) {
		if ( tCard && ![tCard isOwnItem]) {
			return tCard;
		}
	}
    
    [UnUsedFateArray release];
    UnUsedFateArray = [self getDictArrayWithArray:arr];
    [UnUsedFateArray retain];
    
	[gxCardLayer initPageWithCount:([gxCardLayer getPagesCount]+1)];
	if (cards) {
		////物品
		for (NSDictionary *dict in UnUsedFateArray) {
			[gxCardLayer addItemWithDict:dict];
		}
		
	}
    
    arr = [gxCardLayer getLayerItemArray];
	for (Card *tCard in arr) {
		if (tCard && ![tCard isOwnItem]) {
			return tCard;			
		}
	}
	return nil;
}
-(NSDictionary*)getSelectorDict{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:cardRoleID] forKey:@"cardRoleID"];
	[dict setObject:[NSNumber numberWithInt:cardRoleRID] forKey:@"cardRoleRID"];
	[dict setObject:[NSNumber numberWithInt:cardPlace] forKey:@"cardPlace"];
	if (touchCard) {
		[dict setObject:[touchCard getCardDict] forKey:@"touchCardDict"];
	}
	if (tagetCard) {
		[dict setObject:[tagetCard getCardDict] forKey:@"tagetCardDict"];
	}
	return dict;
}

-(int)getAboutZIndex
{
	return 0;
}

////**********************************
#pragma mark -
#pragma mark - Guan Xing net
-(void)didUsedFate:(NSDictionary*)sender :(NSDictionary*)arg{	
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		//if ([touchCard getItemID] == [[data objectForKey:@"id"] intValue]) {
		if (!data) {
			CCLOG(@"data error");
            //
            isSend = NO;
			return;
		}
		if ([[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue] == [[data objectForKey:@"id"] intValue]){
			//if (cardRoleID == [[data objectForKey:@"rid"] intValue]) {
			if ([[arg objectForKey:@"cardRoleID"] intValue] == [[data objectForKey:@"rid"] intValue]) {
				//[[GameConfigure shared] removeFate:[touchCard getItemID]];	
				int tagetCardID = [[[arg objectForKey:@"tagetCardDict"] objectForKey:@"id"] intValue];
				int touchCardID = [[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue];
				if ([tagetCard getItemID] != tagetCardID || [touchCard getItemID] != touchCardID) {
					CCLOG(@"card id change error");
				}
				[tagetCard changeItemWithDict:[arg objectForKey:@"touchCardDict"]];
				[tagetCard setItemUsed:YES];
				[touchCard removeItem];								
				[[GameConfigure shared] wearFate:[[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue] part:[[arg objectForKey:@"cardPlace"] intValue] target:[[arg objectForKey:@"cardRoleID"] intValue]];
				[self changeTouchGXCard:nil];
				//装备
				[self wearFateText:YES withItemID:[tagetCard getItemID]];
				//fix chao
				[self updateFateForceWithRoleID:cardRoleRID];
                [self loadUsedFateList];
				//end
				//fix chao
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXing_Step_2];
				CCMenuItem *bt_getXingChen = (CCMenuItem *)[menu getChildByTag:BT_GX_GET_XINGCHEN_TAG];
				[[Intro share] runIntroTager:bt_getXingChen step:INTRO_OPEN_GuangXingRoom];
				//end
                //
                isSend = NO;
				return;
			}else{
				CCLOG(@"fate role id error");
			}
		}else{
			CCLOG(@"fate item id error");
		}
		//[self changeTouchGXCard:nil];
	}else{
		CCLOG(@"UsedFate error");
		//CCLOG(getResponseMessage(sender));
		//[self showTextWithString:@"不可操作"];
        [self showTextWithString:NSLocalizedString(@"guanxing_no_operate",nil)];
	}
	////
	[touchCard setItemVisible:YES];
	[self changeTouchGXCard:nil];
    //
    isSend = NO;
}
-(void)didUnUsedFate:(NSDictionary*)sender :(NSDictionary*)arg{
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if (!data) {
			CCLOG(@"data error");
            isSend = NO;
			return;
		}
		if ([[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue]== [[data objectForKey:@"uid"] intValue]) {
			int tagetCardID = [[[arg objectForKey:@"tagetCardDict"] objectForKey:@"id"] intValue];
			int touchCardID = [[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue];
			if ([tagetCard getItemID] != tagetCardID || [touchCard getItemID] != touchCardID) {
				CCLOG(@"card id change error");
			}
			[[GameConfigure shared] tackOffFate:[[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue]  part:[[arg objectForKey:@"cardPlace"] intValue] target:[[arg objectForKey:@"cardRoleID"] intValue]];
			
			if (!tagetCard) {
				tagetCard = [self getNoItemCard];
				if (!tagetCard) {
					CCLOG(@" get no itme card error");
				}
			}
			[tagetCard changeItemWithDict:[arg objectForKey:@"touchCardDict"]];
			[tagetCard setItemUsed:NO];
			[touchCard removeItem];
	
			[self changeTouchGXCard:nil];
			//fix chao
			[self updateFateForceWithRoleID:cardRoleRID];
			//end
		}else{
			CCLOG(@"fate item id error");
		}
		//[self changeTouchGXCard:nil];
	}else{
		CCLOG(@"UnUsedFate error");
		//CCLOG(getResponseMessage(sender));
		//[self showTextWithString:@"不可操作"];
        [self showTextWithString:NSLocalizedString(@"guanxing_no_operate",nil)];
	}
    isSend = NO;
}
-(void)didSynthesizeFate:(NSDictionary*)sender :(NSDictionary*)arg{
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if (!data) {
			CCLOG(@"data error");
            isSend = NO;
			return;
		}
		
		NSArray *arrData = [data objectForKey:@"fate"];
		if (!([arrData count]==1)) {
			CCLOG(@"sender data error in fate");
            isSend = NO;
			return;
		}
		NSDictionary *newData = [arrData objectAtIndex:0];
		////
		int tagetCardID = [[[arg objectForKey:@"tagetCardDict"] objectForKey:@"id"] intValue];
		int touchCardID = [[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue];
		if ([tagetCard getItemID] != tagetCardID || [touchCard getItemID] != touchCardID) {
			CCLOG(@"card id change error");
		}
		
		NSMutableDictionary *tDict = [NSMutableDictionary dictionary];
		[tDict setObject:[NSNumber numberWithInt:[[[arg objectForKey:@"tagetCardDict"] objectForKey:@"itemSystemType"] intValue]] forKey:@"itemSystemType"];		
		[tDict setObject:[newData objectForKey:@"id"] forKey:@"id"];
		[tDict setObject:[newData objectForKey:@"fid"] forKey:@"bid"];
		[tDict setObject:[newData objectForKey:@"level"] forKey:@"level"];
		[tDict setObject:[newData objectForKey:@"exp"] forKey:@"exp"];		
		[tDict setObject:[newData objectForKey:@"isTrade"] forKey:@"isTrade"];
		[tDict setObject:[NSNumber numberWithInt:[[[arg objectForKey:@"tagetCardDict"] objectForKey:@"count"] intValue]] forKey:@"count"];
		int quality = 0;
		int tagetQuality = [[[arg objectForKey:@"tagetCardDict"] objectForKey:@"quality"] intValue];
		int touchQuality = [[[arg objectForKey:@"touchCardDict"] objectForKey:@"quality"] intValue];
		if ([self isEXPFateWithItemID:tagetCardID]) {
			quality = touchQuality;
		}else if([self isEXPFateWithItemID:touchCardID]){
			quality = tagetQuality;
		}else{
			quality = touchQuality>tagetQuality?touchQuality:tagetQuality;
		}

		/*
		if([[newData objectForKey:@"id"] intValue] == tagetCardID){
			quality = tagetQuality;
		}else if ([[newData objectForKey:@"id"] intValue] == touchCardID){
			quality = touchQuality;
		}	
		 */
		[tDict setObject:[NSNumber numberWithInt:quality] forKey:@"quality"];
		[tDict setObject:[newData objectForKey:@"used"] forKey:@"used"];
//		if ([[[arg objectForKey:@"touchCardDict"] objectForKey:@"used"] intValue] == FateStatus_used) {
//			[[GameConfigure shared] tackOffFate:[[[arg objectForKey:@"touchCardDict"] objectForKey:@"bid"] intValue]  target:cardRoleID];
//		}
		
		[[GameConfigure shared] tackOffFate:[[[arg objectForKey:@"tagetCardDict"] objectForKey:@"id"] intValue]  target:[[arg objectForKey:@"cardRoleID"] intValue]];
		[[GameConfigure shared] tackOffFate:[[[arg objectForKey:@"touchCardDict"] objectForKey:@"id"] intValue]  target:[[arg objectForKey:@"cardRoleID"] intValue]];
		
		//fix chao
		[[GameConfigure shared] removeFate:[[newData objectForKey:@"id"] intValue]];
		[[GameConfigure shared] updatePackage:data];		
//		[[GameConfigure shared] removeFate:[[data objectForKey:@"id2"] intValue]];
		//[[GameConfigure shared] addFate:newData];
		//end
		
		if ([[[arg objectForKey:@"tagetCardDict"] objectForKey:@"used"] intValue] == FateStatus_used) {
			[[GameConfigure shared] wearFate:[[newData objectForKey:@"id"] intValue] part:[[arg objectForKey:@"cardPlace"] intValue] target:[[arg objectForKey:@"cardRoleID"] intValue]];
		}
		//
		[tagetCard changeItemWithDict:tDict];
		[touchCard removeItem];
		[self changeTouchGXCard:nil];
		//fix chao
		[self updateFateForceWithRoleID:cardRoleRID];
		//end
	}else{
		CCLOG(@"SynthesizeFate error");		
		//CCLOG(getResponseMessage(sender));
		//[self showTextWithString:@"无合成星力"];
        [self showTextWithString:NSLocalizedString(@"guanxing_no_synthesize",nil)];
	}
    //
    isSend = NO;
}

-(void)didOnekeySynthesizeFate:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		[[GameConfigure shared] updatePackage:data];
	}else{
		CCLOG(@"OnekeySynthesizeFate error");
		//CCLOG(getResponseMessage(sender));
		//[self showTextWithString:@"无合成星力"];
        [self showTextWithString:NSLocalizedString(@"guanxing_no_synthesize",nil)];
	}
	//
	//[self updateFatePackage];
	//[self loadFateList];
	[self loadUnUsedFateList];
    //
    isSend = NO;
}

-(void)getFateLevels{
	
	NSArray* array = [[GameConfigure shared] getPlayerFateList];
	NSMutableArray* fids = [NSMutableArray array];
	
	for (NSDictionary* fDict in array) {
		int fid = [fDict intForKey:@"fid"];
		[fids addObject:[NSNumber numberWithInt:fid]];
	}
	
	for (NSNumber *_number in fids) {
		int _fid = [_number intValue];
		NSString *_key = [NSString stringWithFormat:@"%d",_fid];
		NSDictionary* dict = [fate_level objectForKey:_key];
		if (dict) {
			continue ;
		}
		NSString *path = [NSString stringWithFormat:@"%@_%d",@"fate_level",_fid];
		NSDictionary *table = [[GameDB shared] readDB:path];
		if (table) {
			[fate_level setObject:table forKey:_key];
		}
	}
	
	
}

-(int)getFateMaxExpWithFid:(int)_fid{

	//NSString *path = [NSString stringWithFormat:@"%@_%d",@"fate_level",_fid];
	NSString *_key = [NSString stringWithFormat:@"%d",_fid];
	NSDictionary *table = [fate_level objectForKey:_key];
	
	if (table == nil){
		//CCLOG(@"getFateMaxExpWithFid - %@ can't find table",path);
		return 0;
	}
	
	//todo
	//如果是写死的情况 //直接返回 10
	//
	NSMutableArray* array = [NSMutableArray arrayWithArray:[table allValues]];
	if (array.count > 0) {
		[array sortUsingFunction:sortFate context:nil];
	}else{
		return 0;
	}
	
	int max = [[[array objectAtIndex:0] objectForKey:@"exp"] intValue] ;
	
	return max;
}

-(NSDictionary*)getFateWithFid:(int)_fid level:(int)level{
	NSString *_key = [NSString stringWithFormat:@"%d",_fid];
	NSDictionary *table = [fate_level objectForKey:_key];
	if(table!=nil){
		return [table objectForId:level];
	}
	return nil;
}

@end
