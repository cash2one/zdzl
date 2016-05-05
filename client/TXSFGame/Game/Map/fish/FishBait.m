//
//  FishBait.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "FishBait.h"
#import "StretchingImg.h"
#import "FishingManager.h"
#import "CCSimpleButton.h"
#import "GameConfigure.h"
#import "FishAction.h"
#import "ItemIconViewerContent.h"

#define Pos_BatchSprite		ccp(cFixedScale(25), 0)
#define Pos_SelectBox		ccp(cFixedScale(6), cFixedScale(11))
#define Tag_selectBoxDone	2002

static void setBatchFishStatus(BOOL isBatch){
	[[GameConfigure shared] recordPlayerSetting:@"IS_BATCH_FISH" value:[NSNumber numberWithBool:isBatch]];
}

static BOOL getBatchFishStatus(){
	BOOL isBatchFish = [[[GameConfigure shared] getPlayerRecord:@"IS_BATCH_FISH"] boolValue];
	return isBatchFish;
}

// 根据vip等级判断是否开启批量钓鱼
static int getBatchCount(){
	int vipLevel = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"vip"] intValue];
	
	NSString *batchString = [[[GameDB shared] getGlobalConfig] objectForKey:@"vipFishBatch"];
	NSArray *batchArray = [batchString componentsSeparatedByString:@"|"];
	if (batchArray && batchArray.count >= 2) {
		for (int i = batchArray.count-1; i >= 0; i--) {
			NSString *vipBatchString = [batchArray objectAtIndex:i];
			NSArray *vipBatchArray = [vipBatchString componentsSeparatedByString:@":"];
			if (vipBatchArray && vipBatchArray.count >= 2) {
				int needLevel = [[vipBatchArray objectAtIndex:0] intValue];
				if (vipLevel >= needLevel) {
					return [[vipBatchArray objectAtIndex:1] intValue];
				}
			}
		}
	}
	
	return 0;
}

static BOOL getCanBatch(){
	int vipLevel = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"vip"] intValue];
	
	NSString *batchString = [[[GameDB shared] getGlobalConfig] objectForKey:@"vipFishBatch"];
	NSArray *batchArray = [batchString componentsSeparatedByString:@"|"];
	if (batchArray && batchArray.count >= 2) {
		NSString *vipBatchString = [batchArray objectAtIndex:1];
		NSArray *vipBatchArray = [vipBatchString componentsSeparatedByString:@":"];
		if (vipBatchArray && vipBatchArray.count >= 2) {
			int needLevel = [[vipBatchArray objectAtIndex:0] intValue];
			if (vipLevel >= needLevel) {
				return YES;
			}
		}
	}
	if (getBatchFishStatus()) {
		setBatchFishStatus(NO);
	}
	return NO;
}

@implementation FishBaitItem

@synthesize isSelected;
@synthesize quality;
@synthesize delegate;

-(id)init
{
	if (self = [super init]) {
		batchMaxCount = getBatchCount();
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
	
	self.contentSize = CGSizeMake(122, 164);
	
	CCSimpleButton *button2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_toggle01.png"
													  select:@"images/ui/button/bt_toggle01.png"
													  target:self
														call:@selector(selectBait)
													priority:-201];
	if (iPhoneRuningOnGame()) {
		button2.scale=1.3f;
		button2.position = ccp(55/2.0f, 40/2.0f);
	}else{
		button2.position = ccp(55, 53);
	}
	[self addChild:button2];
	
	selectedIcon = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
	selectedIcon.scale=button2.scale;
	selectedIcon.position = button2.position;
	selectedIcon.visible = isSelected;
	[self addChild:selectedIcon z:10];
	
	
}

-(void)onExit
{
	[super onExit];
}

-(void)showWithQuality:(ItemQuality)_quality count:(int)_count
{
	quality = _quality;
	count = _count;
	iid = 34 + quality;
	
	CCSimpleButton *button = [CCSimpleButton spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png", quality]
													 select:[NSString stringWithFormat:@"images/ui/common/quality%dSelect.png", quality]
													 target:self
													   call:@selector(selectBait)
												   priority:-201];
    if (iPhoneRuningOnGame()) {
        button.scale=1.2f;
        button.position = ccp(55/2, 119/2);
    }else{
        button.position = ccp(55, 119);
    }
	[self addChild:button];
	
	CCSprite *itemIcon = nil;
	if (quality == IQ_WHITE) {
		/*
		NSString *itemPath = [NSString stringWithFormat:@"images/ui/item/item0.png"];
		itemIcon = [CCSprite spriteWithFile:itemPath];
		*/
		itemIcon = [ItemIconViewerContent create:0];
	} else {
		itemIcon = getItemIcon(iid);
	}
	if (itemIcon) {
		itemIcon.position = button.position;
		[self addChild:itemIcon z:10];
	}
	
	NSString *name = @"";
	switch (quality) {
//		case IQ_WHITE:	name = @"普通鱼饵";	break;
//		case IQ_GREEN:	name = @"初级鱼饵";	break;
//		case IQ_BLUE:	name = @"中级鱼饵";	break;
//		case IQ_PURPLE:	name = @"高级鱼饵";	break;
        case IQ_WHITE:	name = NSLocalizedString(@"fish_common",nil);	break;
		case IQ_GREEN:	name = NSLocalizedString(@"fish_elementary",nil);	break;
		case IQ_BLUE:	name = NSLocalizedString(@"fish_middle",nil);	break;
		case IQ_PURPLE:	name = NSLocalizedString(@"fish_height",nil);	break;
		default:
			break;
	}
	float fontSize=22;
	if (iPhoneRuningOnGame()) {
		fontSize=12;
	}
	CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	nameLabel.color = ccc3(238, 228, 207);
    if (iPhoneRuningOnGame()) {
//        nameLabel.scale=FONT_SIZE_SCALE;
        nameLabel.position = ccp(55/2, 10/2);
    }else{
        nameLabel.position = ccp(55, 20);
    }
	[self addChild:nameLabel];
	fontSize=21;
	if (iPhoneRuningOnGame()) {
		fontSize=21/2.0f;
	}
	countLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", count] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	countLabel.color = ccc3(238, 228, 207);
	countLabel.anchorPoint = ccp(1, 1);
    if (iPhoneRuningOnGame()) {
//        countLabel.scale=FONT_SIZE_SCALE;
        countLabel.position = ccp(97/2.0f, 155/2.0f);
        
    }else{
        countLabel.position = ccp(94, 150);
    }
	[self addChild:countLabel z:20];
}

-(void)updateShow
{
	if (countLabel) {
		int showCount = count;
		
		BOOL isBatch = getBatchFishStatus();
		if (isBatch && batchMaxCount!=0) {
			showCount = MIN(count, batchMaxCount);
		}
		
		countLabel.string = [NSString stringWithFormat:@"%d", showCount];
	}
}

-(void)setIsSelected:(BOOL)_isSelected
{
	if (isSelected == _isSelected) return;
	
	isSelected = _isSelected;
	selectedIcon.visible = isSelected;
}

-(void)selectBait
{
	if (quality != IQ_WHITE && count == 0) {
		[BuyPanel create:self itemId:iid count:1];
		CCNode *node = delegate;
		if (node) {
			node.visible = NO;
		}
	}
	
	if (isSelected) return;
	
	if (delegate && [delegate respondsToSelector:@selector(selectBait:)]) {
		[delegate selectBait:quality];
	}
}

-(void)buySuccess:(BuyPanel *)_buyPanel
{
	count = [[GameConfigure shared] getPlayerItemCountByIid:iid];
	
	int showCount = count;
	
	BOOL isBatch = getBatchFishStatus();
	if (isBatch && batchMaxCount!=0) {
		showCount = MIN(count, batchMaxCount); 
	}
	countLabel.string = [NSString stringWithFormat:@"%d", showCount];
	
	CCNode *node = delegate;
	if (node) {
		node.visible = YES;
	}
	[_buyPanel remove];
}

-(void)buyCancel:(BuyPanel *)_buyPanel
{
	CCNode *node = delegate;
	if (node) {
		node.visible = YES;
	}
	[_buyPanel remove];
}

@end

static FishBait* s_FishBait = nil;

@implementation FishBait
@synthesize target;
@synthesize selectCall;

+(void)show:(id)_target call:(SEL)_selectCall{
	//-----
	if([FishAction checkFishing]) return ;
	
	//s_FishBait = nil;
	[FishBait stopAll];
	
	s_FishBait = [FishBait node];
	s_FishBait.target=_target;
	s_FishBait.selectCall=_selectCall;
	[[FishingManager shared] addChild:s_FishBait z:INT16_MAX tag:98];
}

+(void)stopAll{
	if (s_FishBait) {
		[s_FishBait removeFromParentAndCleanup:YES];
		s_FishBait = nil;
	}
}

-(id)init
{
	if (self = [super init]) {
		batchMaxCount = getBatchCount();
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-200 swallowsTouches:YES];
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	CCSprite *bg =nil;
    if (iPhoneRuningOnGame()) {
        bg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:540/2 height:372/2 capx:8/2 capy:8/2];
    }else{
        bg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:540 height:372 capx:8 capy:8];
    }
	self.contentSize = bg.contentSize;

	self.position = ccp(winSize.width/2-self.contentSize.width/2,
						winSize.height/2-self.contentSize.height/2);
	bg.anchorPoint = ccp(0, 0);
	[self addChild:bg z:-1];
	
	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=18/2.0f;
	}
	
//	CCLabelTTF *selectLabel = [CCLabelTTF labelWithString:@"选择鱼饵" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *selectLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"fish_select",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	selectLabel.color = ccc3(238, 228, 207);
	selectLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        selectLabel.position = ccp(18/2, 350/2);
    }else{
        selectLabel.position = ccp(18, 350);
    }
	[self addChild:selectLabel];
	
	
	
//	CCLabelTTF *freeCountLabel = [CCLabelTTF labelWithString:@"免费次数" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *freeCountLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"fish_free",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	freeCountLabel.color = ccc3(238, 228, 207);
	freeCountLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        freeCountLabel.position = ccp(418/2, 98/2);
    }else{
        freeCountLabel.position = ccp(418, 98);
    }
	[self addChild:freeCountLabel z:0 tag:100];
	
	items = [NSMutableArray array];
	[items retain];
	
	quality = IQ_WHITE;
	
	for (int i = IQ_WHITE; i <= IQ_PURPLE; i++) {
		if (i == IQ_WHITE) {
			FishBaitItem *item = [FishBaitItem node];
            if (iPhoneRuningOnGame()) {
                item.position = ccp(30/2, 141/2);
            }else{
                item.position = ccp(30, 141);
            }
			[item showWithQuality:i count:0];
			[self addChild:item z:0 tag:101];
			item.delegate = self;
			[GameConnection request:@"fishEnter" data:[NSDictionary dictionary] target:self call:@selector(didFishEnter:)];
		} else {
			int iid = 34 + i;
			int count = [[GameConfigure shared] getPlayerItemCountByIid:iid];
			FishBaitItem *item = [FishBaitItem node];
            if (iPhoneRuningOnGame()) {
                item.position = ccp(30/2+123/2*i, 141/2);
            }else{
                item.position = ccp(30+123*i, 141);
            }
			[item showWithQuality:i count:count];
			[self addChild:item];
			
			[item updateShow];
			
			item.delegate = self;
			
			[items addObject:item];
		}
	}
	
	CCSprite *line = [CCSprite spriteWithFile:@"images/ui/alert/line.png"];
	line.scale = self.contentSize.width / line.contentSize.width;
    if (iPhoneRuningOnGame()) {
        line.position=ccp(bg.contentSize.width/2, 78/2);
    }else{
        line.position=ccp(bg.contentSize.width/2, 78);
    }
	[bg addChild:line];
	
	CCSimpleButton *btOk = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_ok_1.png" select:@"images/ui/alert/bt_ok_2.png" target:self call:@selector(selectOK:)];
	btOk.priority=-201;
	[self addChild:btOk];
	btOk.anchorPoint=ccp(0.5, 0);
    if (iPhoneRuningOnGame()) {
		btOk.scale=1.2f;
        btOk.position=ccp(self.contentSize.width/2, 11/2);
    }else{
        btOk.position=ccp(self.contentSize.width/2, 11);
	}
	CCSimpleButton *btNo = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_cancel_1.png" select:@"images/ui/alert/bt_cancel_2.png" target:self call:@selector(selectNO:)];
	btNo.priority=-201;
	[self addChild:btNo];
	btNo.anchorPoint=ccp(0.5, 0);
	if (btOk) {
        if (iPhoneRuningOnGame()) {
			btNo.scale=1.2f;
            btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width/2-10/2, 11/2);
            btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10/2, 11/2);
        }else{
            btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width/2-10, 11);
            btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10, 11);
        }
	}else{
		btNo.position=ccp(self.contentSize.width/2, 11);
	}
	
	if (getCanBatch()) {
		[self makeSelectBatchFish];
	}
}

// 是否批量钓鱼状态
-(void)updateBatchFishStatus
{
	if (batchFishTips) {
		CCNode *done = [batchFishTips getChildByTag:Tag_selectBoxDone];
		if (done) {
			done.visible = !done.visible;
			setBatchFishStatus(done.visible);
			
			for (int i = 0; i < items.count; i++) {
				FishBaitItem *item = [items objectAtIndex:i];
				[item updateShow];
			}
		}
	}
}

-(void)makeSelectBatchFish
{
	if (selectBatchFish) {
		[selectBatchFish removeFromParentAndCleanup:YES];
		selectBatchFish = nil;
	}
	
	selectBatchFish = [CCSimpleButton node];
	selectBatchFish.target = self;
	selectBatchFish.call = @selector(updateBatchFishStatus);
	selectBatchFish.anchorPoint = ccp(0, 0.5);
	selectBatchFish.priority = INT32_MIN;
	selectBatchFish.position = ccp(cFixedScale(200), cFixedScale(96));
	
	//NSString *tipsString = @"批量钓鱼";
    NSString *tipsString = NSLocalizedString(@"fish_batch",nil);
	CCSprite *batchSprite = drawString(tipsString, CGSizeMake(350, 100), getCommonFontName(FONT_1), 22, 30, getHexStringWithColor3B(ccc3(255, 241, 207)));
	batchSprite.anchorPoint = ccp(0, 0);
	batchSprite.position = Pos_BatchSprite;
	
	selectBatchFish.contentSize = CGSizeMake(batchSprite.contentSize.width+Pos_BatchSprite.x,
											 batchSprite.contentSize.height);
	[self addChild:selectBatchFish];
	
	if (batchFishTips) {
		[batchFishTips removeFromParentAndCleanup:YES];
		batchFishTips = nil;
	}
	batchFishTips = [CCSprite node];
	batchFishTips.anchorPoint = selectBatchFish.anchorPoint;
	batchFishTips.position = selectBatchFish.position;
	batchFishTips.contentSize = selectBatchFish.contentSize;
	[batchFishTips addChild:batchSprite];
	
	CCSprite *selectBox = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
	selectBox.position = ccp(Pos_SelectBox.x, batchFishTips.contentSize.height/2);
	[batchFishTips addChild:selectBox];
	
	CCSprite *selectDone = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
	selectDone.visible = getBatchFishStatus();
	selectDone.position = ccp(Pos_SelectBox.x, batchFishTips.contentSize.height/2);
	selectDone.tag = Tag_selectBoxDone;
	[batchFishTips addChild:selectDone];
	
	[self addChild:batchFishTips];
	
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}

-(void)selectOK:(id)sender
{
	int baitCount = (quality == IQ_WHITE) ? whiteNum : [[GameConfigure shared] getPlayerItemCountByIid:34+quality];
	if (baitCount <= 0) {
		//[ShowItem showItemAct:@"所选鱼饵数目不足"];
        [ShowItem showItemAct:NSLocalizedString(@"fish_minus",nil)];
	} else {
		if (target != nil && selectCall != nil) {
			if ([target respondsToSelector:selectCall]) {
				BaitType baitQuality = BaitType_white;
				switch (quality) {
					case IQ_WHITE:	baitQuality = BaitType_white;	break;
					case IQ_GREEN:	baitQuality = BaitType_green;	break;
					case IQ_BLUE:	baitQuality = BaitType_blue;	break;
					case IQ_PURPLE:	baitQuality = BaitType_purple;	break;
					default:
						break;
				}
				
				int upCount = 1;
				BOOL isBatch = getBatchFishStatus();
				if (isBatch && batchMaxCount!=0) {
					upCount = MIN(baitCount, batchMaxCount);
				}
				
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				[dict setValue:[NSNumber numberWithInt:baitQuality] forKey:@"baitType"];
				[dict setValue:[NSNumber numberWithInt:upCount] forKey:@"upCount"];
				[target performSelector:selectCall withObject:dict];
			}
		}
	}
	
	[FishBait stopAll];
}

-(void)selectNO:(id)sender
{
	[FishBait stopAll];
}

-(void)selectBait:(ItemQuality)_quality
{
	quality = _quality;
	
	for (int i = 0; i < items.count; i++) {
		FishBaitItem *item = [items objectAtIndex:i];
		item.isSelected = item.quality == quality;
	}
}

-(void)didFishEnter:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			whiteNum = [[dict objectForKey:@"n"] intValue];
			
			// 白色鱼饵
			CCNode *whiteNode = [self getChildByTag:101];
			if (whiteNode) {
				[whiteNode removeFromParentAndCleanup:YES];
				whiteNode = nil;
			}
			FishBaitItem *item = [FishBaitItem node];
            if (iPhoneRuningOnGame()) {

                item.position = ccp(30/2, 141/2);
            }else{
                item.position = ccp(30, 141);
            }
			[item showWithQuality:IQ_WHITE count:whiteNum];
			item.isSelected = quality == IQ_WHITE;
			[self addChild:item];
			
			[item updateShow];
			
			item.delegate = self;
			
			[items addObject:item];
			
			CCNode *freeCountNode = [self getChildByTag:100];
			if (freeCountNode) {
				[freeCountNode removeFromParentAndCleanup:YES];
				freeCountNode = nil;
			}
			//CCLabelTTF *freeCountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"免费次数:%d", whiteNum] fontName:getCommonFontName(FONT_1) fontSize:16];
            CCLabelTTF *freeCountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@:%d",NSLocalizedString(@"fish_free",nil), whiteNum] fontName:getCommonFontName(FONT_1) fontSize:16];
			freeCountLabel.color = ccc3(238, 228, 207);
			freeCountLabel.anchorPoint = ccp(0, 0.5);
            if (iPhoneRuningOnGame()) {
                freeCountLabel.scale=FONT_SIZE_SCALE;
                freeCountLabel.position = ccp(418/2, 98/2);
            }else{
                freeCountLabel.position = ccp(418, 98);
            }
			[self addChild:freeCountLabel z:0 tag:100];
		}
	}
}

-(void)onExit
{
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	if (items) {
		[items release];
		items = nil;
	}
	if (s_FishBait) {
		s_FishBait = nil;
	}
	[GameConnection freeRequest:self];
	[super onExit];
}

@end
