//
//  ExchangePanel.m
//  TXSFGame
//
//  Created by efun on 13-3-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ExchangePanel.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "CCPanel.h"
#import "MessageBox.h"
#import "ButtonGroup.h"
#import "CCPanelPage.h"
#import "AlertManager.h"
#import "InfoAlert.h"
#import "ItemManager.h"
#import "GameUI.h"

#import "CJSONDeserializer.h"

// 充值默认选项索引（0为第一项，1为第二项，...）
#define Exchange_Default_Index	0

#define ExchangeItem_height		cFixedScale(86)

#define Exchange_Status_Tag		10001
#define Exchange_Count_tag		10002
#define Exchange_Panel_tag		20001

#define Exchange_Vip_begin		100	// vip1为101，...
static int s_exchange_off_x1 = 0;
static int s_exchange_off_y1 = 0;

static int s_exchange_off_x2 = 0;
static int s_exchange_off_y2 = 0;

static ExchangePanel *exchangePanel;

@interface ExchangeItem : CCLayer
{
	CCSprite *normal;
	CCSprite *selected;
	CCSprite *selectedIcon;
	CCSprite *coinsIcon;
	
	BOOL _isSelected;
}

@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isFirstExchange;	// YES=首冲状态（还没冲过值）,NO=非首冲状态
@property (nonatomic) int gid;
@property (nonatomic) int count;
@property (nonatomic) int freeCount;
@property (nonatomic) int level;
@property (nonatomic, retain) NSString *name;

@end

@implementation ExchangeItem

@synthesize isSelected = _isSelected;
@synthesize isFirstExchange;
@synthesize gid;
@synthesize count;
@synthesize freeCount;
@synthesize level;
@synthesize name;

-(id)init
{
	if (self = [super init]) {
		self.isSelected = NO;
		self.contentSize = CGSizeMake(cFixedScale(307), ExchangeItem_height);
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
	
	switch (level) {
		case 0:
			normal = [CCSprite spriteWithFile:@"images/ui/panel/p30.png"];
			selected = [CCSprite spriteWithFile:@"images/ui/panel/p31.png"];
			coinsIcon = [CCSprite spriteWithFile:@"images/ui/common/exchange1.png"];
			break;
		case 1:
			coinsIcon = [CCSprite spriteWithFile:@"images/ui/common/exchange2.png"];
		case 2:
			normal = [CCSprite spriteWithFile:@"images/ui/panel/p32.png"];
			selected = [CCSprite spriteWithFile:@"images/ui/panel/p33.png"];
			if (!coinsIcon) coinsIcon = [CCSprite spriteWithFile:@"images/ui/common/exchange3.png"];
			break;
		case 3:
			coinsIcon = [CCSprite spriteWithFile:@"images/ui/common/exchange4.png"];
			
		default:
			normal = [CCSprite spriteWithFile:@"images/ui/panel/p34.png"];
			selected = [CCSprite spriteWithFile:@"images/ui/panel/p35.png"];
			if (!coinsIcon) coinsIcon = [CCSprite spriteWithFile:@"images/ui/common/exchange5.png"];
			break;
	}
	
	self.anchorPoint = CGPointZero;
	
	normal.anchorPoint = CGPointZero;
	selected.anchorPoint = CGPointZero;
	[self addChild:normal];
	[self addChild:selected];
	
	normal.visible = !_isSelected;
	selected.visible = _isSelected;
	
	coinsIcon.position = ccp(cFixedScale(85), cFixedScale(42));
	[self addChild:coinsIcon];
	
	selectedIcon = [CCSprite spriteWithFile:@"images/ui/panel/t23.png"];
	selectedIcon.anchorPoint = ccp(0, 0.5);
	selectedIcon.position = ccp(cFixedScale(282), self.contentSize.height/2);
	selectedIcon.visible = _isSelected;
	[self addChild:selectedIcon z:10];
	
	CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
	nameLabel.color = ccc3(47, 19, 8);
	nameLabel.position = ccp(cFixedScale(214), cFixedScale(54));
	[self addChild:nameLabel];
	
	CCLabelTTF *countLable = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", count] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
	countLable.color = ccc3(253, 243, 111);
	countLable.position = ccp(cFixedScale(198), cFixedScale(29));
	[self addChild:countLable];
	
	CCSprite *coin = [CCSprite spriteWithFile:@"images/ui/object-icon/2.png"];
	coin.position = ccp(cFixedScale(237), cFixedScale(29));
	[self addChild:coin];
}

-(void)setIsSelected:(BOOL)isSelected_
{
	if (_isSelected == isSelected_) {
		return;
	}
	
	_isSelected = isSelected_;
	if (selectedIcon) {
		selectedIcon.visible = _isSelected;
		normal.visible = !_isSelected;
		selected.visible = _isSelected;
	}
}

-(void)setIsFirstExchange:(BOOL)isFirstExchange_
{
	isFirstExchange = isFirstExchange_;
	
	[self removeChildByTag:20201];
	if (isFirstExchange) {
		CCSprite *firstIcon = [CCSprite spriteWithFile:@"images/ui/panel/p39.png"];
		firstIcon.anchorPoint = CGPointZero;
		firstIcon.position = ccp(cFixedScale(-7), cFixedScale(-8));
		[self addChild:firstIcon z:200 tag:20201];
	}
}

-(void)setFreeCount:(int)freeCount_
{
	freeCount = freeCount_;
	
	[self removeChildByTag:20202];
	if (freeCount > 0) {
		CCSprite *freeBg = [CCSprite spriteWithFile:@"images/ui/panel/p40.png"];
		freeBg.position = ccp(cFixedScale(290), cFixedScale(20));
		[self addChild:freeBg z:200 tag:20202];
		
		CCLabelTTF *freeLable = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", freeCount] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
		freeLable.color = ccc3(253, 243, 111);
		freeLable.position = ccp(freeBg.contentSize.width/2+cFixedScale(6), freeBg.contentSize.height/2-cFixedScale(2));
		freeLable.scaleY = 1.5;
		[freeBg addChild:freeLable];
	}
}

@end

@implementation ExchangeManager

-(id)initWithSize:(CGSize)size{
	
	if (self = [super init]) {
		
		self.contentSize = size;
		
	}
	
	return self;
}

-(void)setContentLayer:(CCLayer *)layer
{
	if (layer != nil) {
		_canvas = layer;
		_canvas.position = ccp(0, self.contentSize.height-layer.contentSize.height);
		[self addChild:_canvas];
	}
}

-(void)canvasTapped:(UITouch *)touch
{
	if (_canvas) {
		CGPoint touchLocation = [touch locationInView:touch.view];
		touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
		touchLocation = [_canvas convertToNodeSpace:touchLocation];
		
		ExchangeItem *curItem = nil;
		for (CCNode *node in _canvas.children) {
			if (CGRectContainsPoint(node.boundingBox, touchLocation)) {
				curItem = (ExchangeItem *)node;
				if (exchangePanel) {
					exchangePanel.selectGoodsId = curItem.tag-10000;
				}
				
				break;
			}
		}
		if (curItem) {
			for (ExchangeItem *item in _canvas.children) {
				item.isSelected = [item isEqual:curItem];
			}
		}
	}
}

-(void)dealloc
{
	if (_canvas) {
		[_canvas removeFromParentAndCleanup:YES];
		_canvas = nil;
	}
	[super dealloc];
}

-(void)onExit{
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-300 swallowsTouches:YES];
	
}

-(void)visit{
	if (state_ == tCCScrollLayerStateBottomSlid_) {
		[super visit];
	}else{
		CGPoint pt = [self.parent convertToWorldSpace:self.position];
		int clipX = pt.x;
		int clipY = pt.y;
		int clipW = self.contentSize.width;
		int clipH = self.contentSize.height;
		float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
		glScissor(clipX*zoom, clipY*zoom, clipW*zoom, clipH*zoom);
		glEnable(GL_SCISSOR_TEST);
		[super visit];
		glDisable(GL_SCISSOR_TEST);
	}
}

-(BOOL)checkIn:(CGPoint)_pt start:(CGPoint)_stPt end:(CGPoint)_ePt{
	BOOL isIn = YES;
	isIn = isIn && (_pt.x >= _stPt.x);
	isIn = isIn && (_pt.x <= _ePt.x);
	isIn = isIn && (_pt.y >= _stPt.y);
	isIn = isIn && (_pt.y <= _ePt.y);
	return isIn;
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    if( scrollTouch_ == touch ) {
        scrollTouch_ = nil;
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint sPt = [self.parent convertToWorldSpace:self.position];
	
	float rx = sPt.x + self.contentSize.width;
	float ty = sPt.y + self.contentSize.height;
	
	moveDis = 0;
	
	if ([self checkIn:touchPoint start:sPt end:ccp(rx, ty)]) {
		scrollTouch_ = touch;
		touchSwipe_ = touchPoint;
		
		state_ = tCCScrollLayerStateTopIn_;
		
		return YES;
	}
	
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	//
	//把顶层的操作点击指派为顶层的滑动
	//
	if ( (state_  == tCCScrollLayerStateTopIn_)
		&& ((fabsf(touchPoint.x-touchSwipe_.x) >= minimumTouchLengthToSlide_)
			||(fabsf(touchPoint.y-touchSwipe_.y) >= minimumTouchLengthToSlide_) ) ){
			
			state_ = tCCScrollLayerStateTopSlid_;
			
			CCLOG(@"Begin-Scroll-top-layer");
			touchSwipe_ = touchPoint;
			
			if (_canvas) {
				[_canvas stopAllActions];
				layerSwipe_ = _canvas.position;
			}
			
		}
	
	//上层滑动
	if (state_ == tCCScrollLayerStateTopSlid_){
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		temp.x = 0 ;
		CGPoint newPt = ccpAdd(temp, layerSwipe_);
		if (_canvas) {
			_canvas.position = newPt;
		}
		
		moveDis += ABS(temp.y);
	}
	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	scrollTouch_ = nil;
	/*
	 CGPoint touchPoint = [touch locationInView:[touch view]];
	 touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	 */
	//单纯的点击事件
	if (state_ == tCCScrollLayerStateTopIn_) {
		
		// 判断点击面板
		[self canvasTapped:touch];
		
	}
	
	//结束顶层拖拽
	if (state_ == tCCScrollLayerStateTopSlid_){
		
		// 判断滑动距离是否触发点击事件
		float distance = cFixedScale(10);
		if (moveDis < distance) {
			[self canvasTapped:touch];
		}
		
		[self revisionSwipe];
	}
	
	state_ = tCCScrollLayerStateNo_;
	
}

-(void)revisionSwipe{
	if (_canvas != nil) {
		id move = nil;
		if (_canvas.position.y > 0) {
			move = [CCMoveTo actionWithDuration:1 position:ccp(0, 0)];
		} else if (_canvas.position.y+_canvas.contentSize.height < self.contentSize.height) {
			move = [CCMoveTo actionWithDuration:1 position:ccp(0, self.contentSize.height-_canvas.contentSize.height)];
		}
		if (move) {
			[_canvas stopAllActions];
			id action = [CCEaseElasticOut actionWithAction:move period:0.8f];
			[_canvas runAction:action];
		}
	}
}

@end

@interface ExchangeDetail : CCLayer
{
	CGSize pageSize;
	int currentLevel;
	int maxLevel;
	NSMutableDictionary *levelDict;
	NSMutableDictionary *giftDict;	// vip邮件礼包
	NSDictionary *ruleDicts;
	
	NSMutableArray *vipCountArray;
	
	CCSprite *scrollLeft;
	CCSprite *scrollMiddle;
	CCSprite *scrollRight;
	CCSprite *scrollSpot;
	
	CCLayer *vipContent;
	
	BOOL isShowing;
}

@end

@implementation ExchangeDetail

-(id)init
{
	if (self = [super init]) {
		currentLevel = -1;
		isShowing = NO;
		
		NSString *levelString = [[[GameDB shared] getGlobalConfig] objectForKey:@"vipLevels"];
		NSArray *levelArray = [levelString componentsSeparatedByString:@"|"];
		maxLevel = levelArray.count - 1;
		
		levelDict = [NSMutableDictionary dictionary];
		[levelDict retain];
		for (NSString *string in levelArray) {
			NSArray *array = [string componentsSeparatedByString:@":"];
			int value = [[array objectAtIndex:0] intValue];
			NSString *key = [array objectAtIndex:1];
			[levelDict setValue:[NSNumber numberWithInt:value]
						 forKey:key];
		}
		
		giftDict = [NSMutableDictionary dictionary];
		[giftDict retain];
		
		ruleDicts = [[GameDB shared] readDB:@"rule"];
		[ruleDicts retain];
		
		vipCountArray = [NSMutableArray array];
		[vipCountArray retain];
		
		NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
		int level = [[playerInfo objectForKey:@"vip"] intValue];
		int showLevel = MIN(level+1, maxLevel);
		for (int i = showLevel+1; i <= maxLevel; i++) {
			[vipCountArray addObject:[NSNumber numberWithInt:i]];
		}
		for (int i = showLevel-1; i >= 1; i--) {
			[vipCountArray addObject:[NSNumber numberWithInt:i]];
		}
	}
	return self;
}


-(void)dealloc
{
	if (levelDict) {
		[levelDict release];
		levelDict = nil;
	}
	if (giftDict) {
		[giftDict release];
		giftDict = nil;
	}
	if (ruleDicts) {
		[ruleDicts release];
		ruleDicts = nil;
	}
	if (vipCountArray) {
		[vipCountArray release];
		vipCountArray = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	self.contentSize = CGSizeMake(cFixedScale(478), cFixedScale(489));
	
	CCSprite *coin = [CCSprite spriteWithFile:@"images/ui/object-icon/2.png"];
	coin.position = ccp(cFixedScale(426), cFixedScale(394));
	[self addChild:coin];
	
	// 进度条
	CCSprite *scrollBg = [CCSprite spriteWithFile:@"images/ui/common/eprogress_bg.png"];
	scrollBg.position = ccp(self.contentSize.width/2+cFixedScale(1), cFixedScale(428));
	[self addChild:scrollBg];
	
	scrollLeft = [CCSprite spriteWithFile:@"images/ui/common/progress1.png"];
	scrollLeft.anchorPoint = ccp(0, 0);
	scrollLeft.position = ccp(cFixedScale(9.5), cFixedScale(8));
	scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/progress2.png"];
	scrollMiddle.anchorPoint = ccp(0, 0);
	scrollMiddle.position = ccp(cFixedScale(13.5), cFixedScale(8));
	scrollRight = [CCSprite spriteWithFile:@"images/ui/common/progress3.png"];
	scrollRight.anchorPoint = ccp(0, 0);
	scrollSpot = [CCSprite spriteWithFile:@"images/start/loading/p-4.png"];
	scrollSpot.scale = 0.5;
	scrollLeft.visible = NO;
	scrollMiddle.visible = NO;
	scrollRight.visible = NO;
	scrollSpot.visible = NO;
	[scrollBg addChild:scrollLeft];
	[scrollBg addChild:scrollMiddle];
	[scrollBg addChild:scrollRight];
	[scrollBg addChild:scrollSpot];
	
	pageSize = CGSizeMake(cFixedScale(478), cFixedScale(360));
	vipContent = [CCLayer node];
	
	[GameConnection addPost:@"AAA" target:self call:@selector(showGift:)];
}

// scrollValue为0~1.0
-(void)setScroll:(float)scrollValue
{
    if (scrollValue == 0) {
        scrollLeft.visible = NO;
        scrollMiddle.visible = NO;
        scrollRight.visible = NO;
		scrollSpot.visible = NO;
        return;
    }
    scrollLeft.visible = YES;
    scrollMiddle.visible = YES;
    scrollRight.visible = YES;
	scrollSpot.visible = YES;
    float minWidth = cFixedScale(4);
    float maxWidth = cFixedScale(371.5);
    float realWidth = MAX(MIN(maxWidth * scrollValue, maxWidth), minWidth);
    scrollMiddle.scaleX = realWidth / scrollMiddle.contentSize.width;
    scrollRight.position = ccp(scrollMiddle.position.x + realWidth,
                               scrollMiddle.position.y);
	scrollSpot.position = ccpAdd(scrollRight.position, ccp(scrollRight.contentSize.width/2,scrollRight.contentSize.height/2));
}

-(void)showGift:(NSNotification*)notification{
	int vip = [notification.object integerValue];
	NSString *key = [NSString stringWithFormat:@"%d", vip];
	NSString *message = [giftDict objectForKey:key];
	CCSprite *sprite = drawString(message, CGSizeMake(160, 0), getCommonFontName(FONT_1), 18, 24, @"#EBE2D0");
	[InfoAlert show:self drawSprite:sprite parent:self position:ccp(cFixedScale(115), cFixedScale(110)) anchorPoint:CGPointZero offset:CGSizeMake(cFixedScale(12), cFixedScale(10))];
}

-(void)showVipInfo:(int)level
{
	float offsetX = (level - 1) * pageSize.width;
	CCSprite *vipIcon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/VIP_%d.png", level]];
	if (vipIcon) {
		vipIcon.anchorPoint = ccp(0, 0.5);
		vipIcon.position = ccp(offsetX+cFixedScale(18), cFixedScale(327));
		[vipContent addChild:vipIcon];
	}
	
	// vip说明
	NSString *ruleKey = [NSString stringWithFormat:@"%d", Exchange_Vip_begin+level];
	NSDictionary *ruleDict = [ruleDicts objectForKey:ruleKey];
	if (ruleDict) {
		NSString *ruleInfo = [ruleDict objectForKey:@"info"];
		NSArray *ruleArray = [ruleInfo componentsSeparatedByString:@"ZZZ"];
		
		// 说明1
		NSString *message1 = [ruleArray objectAtIndex:0];
		CCSprite *sprite1 = drawString(message1, CGSizeMake(300, 0), getCommonFontName(FONT_1), 18, 24, @"#FA9429");
		sprite1.anchorPoint = ccp(0, 0.5);
		sprite1.position = ccp(offsetX+cFixedScale(118), cFixedScale(317));
		[vipContent addChild:sprite1];
		
		// 说明2
		NSString *message2 = [ruleArray objectAtIndex:1];
		CCSprite *sprite2 = drawString(message2, CGSizeMake(438, 0), getCommonFontName(FONT_1), 18, 24, @"#EBE2D0");
		sprite2.anchorPoint = ccp(0, 0.5);
		sprite2.position = ccp(offsetX+cFixedScale(18), cFixedScale(171));
		[vipContent addChild:sprite2];
		
		// 说明3
		NSString *message3 = [ruleArray objectAtIndex:2];
		[giftDict setObject:message3 forKey:[NSString stringWithFormat:@"%d", level]];
	}
}

-(void)showOtherInfo
{
	if (vipCountArray.count > 0) {
		int vipLevel = [[vipCountArray objectAtIndex:0] intValue];
		[self showVipInfo:vipLevel];
		
		[vipCountArray removeObjectAtIndex:0];
	}
	
	if (vipCountArray.count <= 0) {
		[self unschedule:@selector(showOtherInfo)];
	}
}

-(void)updateDetail
{
	// 获取数据
	NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
	int level = [[playerInfo objectForKey:@"vip"] intValue];
	int showLevel = MIN(level+1, maxLevel);
	int current = [[playerInfo objectForKey:@"vipCoin"] intValue];
	int total = [[levelDict objectForKey:[NSString stringWithFormat:@"%d", showLevel]] intValue];
	
	// 购买元宝情况
	[self removeChildByTag:Exchange_Status_Tag cleanup:YES];
	NSString *statusMessage = nil;
	if (level >= maxLevel) {
		//statusMessage = [NSString stringWithFormat:@"恭喜您成为永久VIP！"];
        statusMessage = [NSString stringWithFormat:NSLocalizedString(@"exchange_forever_vip",nil)];
	} else {
		//statusMessage = [NSString stringWithFormat:@"再充值|%d元宝#FEF46F|，即可永久成为|VIP %d#FEF46F|", (total - current), showLevel];
        statusMessage = [NSString stringWithFormat:NSLocalizedString(@"exchange_full_money",nil), (total - current), showLevel];
	}
	CCSprite *statusSprite = drawString(statusMessage, CGSizeMake(435, 0), getCommonFontName(FONT_1), 18, 26, @"#EBE2D0");
	statusSprite.anchorPoint = ccp(0, 0.5);
	statusSprite.position = ccp(cFixedScale(39), cFixedScale(461));
	statusSprite.tag = Exchange_Status_Tag;
	[self addChild:statusSprite];
	
	[self removeChildByTag:Exchange_Count_tag cleanup:YES];
	NSString *countMessage = [NSString stringWithFormat:@"|%d/%d#FEF46F|", current, total];
	CCSprite *countSprite = drawString(countMessage, CGSizeMake(200, 0), getCommonFontName(FONT_1), 18, 26, @"#EBE2D0");
	countSprite.anchorPoint = ccp(1, 0.5);
	countSprite.position = ccp(cFixedScale(403), cFixedScale(399));
	countSprite.tag = Exchange_Count_tag;
	[self addChild:countSprite];
	
	// 进度条
	float percent = current * 1.0f / total;
	percent = MIN(percent, 1.0f);
	[self setScroll:percent];
	
	// 初始化，加载vip介绍
	if (currentLevel == -1) {
		currentLevel = level;
		
		vipContent.contentSize = CGSizeMake(pageSize.width * maxLevel, pageSize.height);
		
		// 先画要显示的
		[self showVipInfo:showLevel];
		
		if (!isShowing) {
			[self schedule:@selector(showOtherInfo) interval:0.2];
			isShowing = YES;
		}
		
		CCPanelPage *panel = [CCPanelPage panelWithContent:vipContent viewSize:pageSize];
		panel.position = ccp(cFixedScale(1), cFixedScale(56));
		panel.tag = Exchange_Panel_tag;
		[self addChild:panel];
		
		CGPoint finalyPoint = CGPointMake((showLevel-1) * pageSize.width * -1, 0);
		[panel updateContentPosition:finalyPoint];
		
	} else if (currentLevel < level) {
		currentLevel = level;
		
		CGPoint finalyPoint = CGPointMake((showLevel-1) * pageSize.width * -1, 0);
		CCPanelPage *panel = (CCPanelPage *)[self getChildByTag:Exchange_Panel_tag];
		if (panel) {
			[panel updateContentPosition:finalyPoint];
		}
	}
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	
	[super onExit];
}

@end

@implementation ExchangePanel

@synthesize selectGoodsId;

-(BOOL)check_open_the_Platform_page{
	BOOL isOpen = NO ;
#if GAME_SNS_TYPE==9
	[self open_the_Platform_page:nil];
	isOpen = YES ;
#endif
	return isOpen;
}

-(void)onEnter
{
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            s_exchange_off_x1 = 150;
            s_exchange_off_y1 = 50;
            
            s_exchange_off_x2 = 150;
            s_exchange_off_y2 = 50;
        }else{
            s_exchange_off_x1 = 126;
            s_exchange_off_y1 = 50;
            
            s_exchange_off_x2 = 126;
            s_exchange_off_y2 = 50;
        }
    }else{
        s_exchange_off_x1 = 0;
        s_exchange_off_y1 = 0;
        
        s_exchange_off_x2 = 0;
        s_exchange_off_y2 = 0;
    }
	
	[super onEnter];
	
	if ([self check_open_the_Platform_page]) {
		[[Window shared] removeWindow:PANEL_EXCHANGE];
		return ;
	}
	
	exchangePanel = self;
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	MessageBox *box1 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	box1.contentSize = CGSizeMake(cFixedScale(334), cFixedScale(491));
	box1.position = ccp(cFixedScale(26+s_exchange_off_x1), cFixedScale(19+s_exchange_off_y1));
	[self addChild:box1];
	
	MessageBox *box2 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	box2.contentSize = CGSizeMake(cFixedScale(480), cFixedScale(491));
	box2.position = ccp(cFixedScale(367+s_exchange_off_x2), cFixedScale(19+s_exchange_off_y2));
	[self addChild:box2];
	
	exchangeDetail = [ExchangeDetail node];
	exchangeDetail.position = ccp(cFixedScale(368+s_exchange_off_x2), cFixedScale(30+s_exchange_off_y2));
	[self addChild:exchangeDetail];
	[exchangeDetail updateDetail];
	
	buyButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_buy3_1.png"
										select:@"images/ui/button/bt_buy3_2.png"
										target:self
										  call:@selector(doBuyGoods)];
	buyButton.position = ccp(cFixedScale(607+s_exchange_off_x2), cFixedScale(55+s_exchange_off_y2));
	[self addChild:buyButton];
	
	goodsList = [[NSMutableArray alloc] init];
	[self loadGoods];
	
	itemList = [NSMutableArray array];
	[itemList retain];
	
	[GameConnection addPost:ConnPost_goodsGive target:self call:@selector(updateGoodsGive:)];
	
}

-(void)updateGoodsGive:(NSNotification*)notification
{
	[exchangeDetail updateDetail];
	
	int getCoin = [[notification.object objectForKey:@"getCoin"] intValue];
	//[[AlertManager shared] showMessageWithConfirm:[NSString stringWithFormat:@"获得 |%d#FF0000| 元宝", getCoin] target:nil call:nil];
    [[AlertManager shared] showMessageWithConfirm:[NSString stringWithFormat:NSLocalizedString(@"exchange_get_yuanbao",nil), getCoin] target:nil call:nil];
	
	//[ExchangePanel checkPlayerFirstRecharge];
	[self updateListWithStatus];
	
}

-(int)getExchangeLevel:(int)_count
{
	int i;
	if (_count <= 100) {
		i = 0;
	} else if (_count <= 500) {
		i = 1;
	} else if (_count <= 1000) {
		i = 2;
	} else if (_count <= 5000) {
		i = 3;
	} else {
		i = 4;
	}
	return i;
}

-(void)showList{
	
	if([goodsList count]>0){
		
		[self removeChildByTag:123456 cleanup:YES];
		
		float padding = cFixedScale(13);
		float itemPadding = cFixedScale(8);
		float contentHeight = padding*2+ExchangeItem_height*goodsList.count+itemPadding*(goodsList.count-1);
		CGSize viewSize = CGSizeMake(cFixedScale(357), cFixedScale(489));
		
		CCLayer *contentLayer = [CCLayer node];
		contentLayer.contentSize = CGSizeMake(viewSize.width, contentHeight>viewSize.height?contentHeight:viewSize.height);
		
		BOOL isIndex = NO;
		for (int i=0;i<[goodsList count];i++) {
			
			isIndex = (i==Exchange_Default_Index)?YES:NO;
			
			NSDictionary * goods = [goodsList objectAtIndex:i];
			
			int gid = [[goods objectForKey:@"id"] intValue];
			int count = [[goods objectForKey:@"coin"] intValue];
			int freeCount = [[goods objectForKey:@"freeCoin"] intValue];
			NSString * name = [goods objectForKey:@"name"];
			
			ExchangeItem *item = [ExchangeItem node];
			item.gid = gid;
			item.level = [self getExchangeLevel:count];
			item.name = name;
			item.count = count;
			item.isFirstExchange = [[GameConfigure shared] checkPlayerIsFirstRecharge];	// 是否首冲状态
			item.freeCount = freeCount;
			item.isSelected = isIndex;
			item.position = ccp(cFixedScale(13), contentLayer.contentSize.height-padding-itemPadding*i-ExchangeItem_height*(i+1));
			item.tag = (10000+gid);
			
			[contentLayer addChild:item];
			
			// 设置默认selectGoodsId
			if (item.isSelected) {
				self.selectGoodsId = item.tag-10000;
			}
			
			[itemList addObject:item];
			
		}
		
		ExchangeManager *manager = [[[ExchangeManager alloc] initWithSize:viewSize] autorelease];
		manager.tag = 123456;
		manager.position = ccp(cFixedScale(27+s_exchange_off_x1), cFixedScale(20+s_exchange_off_y1));
		[manager setContentLayer:contentLayer];
		[self addChild:manager];
		
	}
}

-(void)updateListWithStatus
{
	BOOL isFirst = [[GameConfigure shared] checkPlayerIsFirstRecharge];
	for (ExchangeItem *item in itemList) {
		item.isFirstExchange = isFirst;
	}
}

-(void)onExit
{
	if(goodsList){
		[goodsList release];
		goodsList  =nil;
	}
	
	if (itemList) {
		[itemList release];
		itemList = nil;
	}
	
	exchangePanel = nil;
	
	[GameConnection removePostTarget:self];
	[GameConnection freeRequest:self];
	
	[super onExit];
}

-(void)doBuyGoods{
	buyButton.isEnabled = NO;
	[self doBuySelect];
}

#pragma mark -

-(void)loadGoods{
	[GameConnection request:@"goodsList"
					 format:@""
					 target:self
					   call:@selector(didLoadGoodList:)];
}

-(void)didLoadGoodList:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSArray * goods = getResponseData(response);
		
		[goodsList removeAllObjects];
		[goodsList addObjectsFromArray:goods];
		
		[self showList];
	}
}

-(void)doBuySelect{
	
	NSDictionary * goods = nil;
	
	for(NSDictionary * data in goodsList){
		int gid = [[data objectForKey:@"id"] intValue];
		if(self.selectGoodsId==gid){
			goods = [NSDictionary dictionaryWithDictionary:data];
		}
	}
	
	if(goods){
		
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:[SNSHelper getHelperType]] forKey:@"t"];
		[data setObject:[goods objectForKey:@"id"] forKey:@"gid"];
		[GameConnection request:@"goodsBuy"
						   data:data
						 target:self
						   call:@selector(didBuyGoodList: arg:)
							arg:goods
		 ];
		
	}
	
}

-(void)open_the_Platform_page:(NSDictionary*)_buyInfo{
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	NSDictionary * server = [[GameConnection share] getServerInfoById:[GameConnection share].currentServerId];
	
	NSMutableDictionary * other = [NSMutableDictionary dictionary];
	[other setObject:[player objectForKey:@"id"] forKey:@"playerId"];
	[other setObject:[player objectForKey:@"name"] forKey:@"playerName"];
	[other setObject:[NSString stringWithFormat:@"%d",[[server objectForKey:@"sid"] intValue]] forKey:@"serverId"];
	[other setObject:[server objectForKey:@"name"] forKey:@"serverName"];
	
	[[SNSHelper shared] purchase:_buyInfo
						  target:[ExchangePanel class]
							call:@selector(didGetReceipt:)
						   other:other
	 ];
}

-(void)didBuyGoodList:(NSDictionary*)response arg:(NSDictionary*)good{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		NSMutableDictionary * buyInfo = [NSMutableDictionary dictionary];
		[buyInfo addEntriesFromDictionary:good];
		[buyInfo addEntriesFromDictionary:data];
		[self open_the_Platform_page:buyInfo];
	}
	
	buyButton.isEnabled = YES;
}

+(void)didGetReceipt:(id)data{
	
	if([SNSHelper isMustVerify]){
		if(data){
			NSMutableDictionary * pay = [NSMutableDictionary dictionary];
			[pay setObject:[data objectForKey:@"gorder"] forKey:@"gorder"];
			[pay setObject:[data objectForKey:@"receipt"] forKey:@"pid"];
			[GameConnection request:@"goodsPay" data:pay target:self call:@selector(didOverReceipt:)];
		}
	}
}

+(void)didOverReceipt:(NSDictionary*)response{
	[[SNSHelper shared] purchaseVerify:checkResponseStatus(response)];
}

/*
 +(void)checkPlayerFirstRecharge{
 // 如果首次充值，撤销首充状态
 BOOL isFirst = [[GameConfigure shared] checkPlayerIsFirstRecharge];
 if (isFirst) {
 [[GameConfigure shared] closePlayerFirstRecharge];
 [[GameUI shared] updateStatus];
 // 列表更新为非首冲状态
 if (exchangePanel) {
 [exchangePanel updateListWithStatus];
 }
 }
 }
 */

@end
