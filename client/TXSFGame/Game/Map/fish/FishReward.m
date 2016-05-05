//
//  FishReward.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "FishReward.h"
#import "Window.h"
#import "GameConnection.h"
#import "ShowItem.h"
#import "CCPanelPage.h"


#define Fish_Reward_box		1001
#define Fish_Item_use		1002

#define Fish_Item_bg		2001
#define Fish_Item_Icon		2002
#define Fish_Item_label		2003

#define Fish_Item_Row_count		4
#define Fish_Item_Column_count	3
#define Fish_Item_Page_count	(Fish_Item_Row_count*Fish_Item_Column_count)

static CGPoint Fish_Item_orgin;
static CGSize Fish_Item_Offer;
static CGSize Fish_Item_Page_size;

typedef enum {
	FishReward_close,
	FishReward_button,
	FishReward_open
} FishRewardType;

@interface FishItem : CCLayer
@property (nonatomic) int iid;
@property (nonatomic) int count;

@end

@implementation FishItem

@synthesize iid;
@synthesize count;

// dict=nil,表示该item为空
-(id)initWithDict:(NSDictionary *)dict
{
	if (self = [super init]) {
		[self setDict:dict];
	}
	return self;
}

-(void)setDict:(NSDictionary*)dict{
	if (dict) {
		self.tag = [[dict objectForKey:@"id"] intValue];
		self.count = [[dict objectForKey:@"count"] intValue];
		
		self.iid = [[dict objectForKey:@"iid"] intValue];
		NSDictionary *itemDict = [[GameDB shared] getItemInfo:iid];
		ItemQuality quality = [[itemDict objectForKey:@"quality"] intValue];
		CCSprite *itemBg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png",quality]];
		if (!itemBg) {
			itemBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
		}
		self.contentSize = itemBg.contentSize;
		itemBg.anchorPoint = CGPointZero;
		[self addChild:itemBg z:0 tag:Fish_Item_bg];
		
		CCSprite *icon = getItemIcon(iid);
		if (icon) {
			icon.position = ccp(self.contentSize.width/2,
								self.contentSize.height/2);
			[self addChild:icon z:1 tag:Fish_Item_Icon];
		}
		
	} else {
		[self setNull];
	}
}

-(void)setCount:(int)_count
{
	CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:Fish_Item_label];
	if (!label) {
		label = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:22];
		label.anchorPoint = ccp(1, 0.5);
		if (iPhoneRuningOnGame()) {
			label.scale=0.5f;
			label.position = ccp(75/2, 75/2);
		}else{
			label.position = ccp(75, 75);
		}
		[self addChild:label z:2 tag:Fish_Item_label];
		
	}
	label.string = [NSString stringWithFormat:@"%d", _count];
}

-(void)setNull
{
	CCNode *bg = [self getChildByTag:Fish_Item_bg];
	if (bg) {
		[bg removeFromParentAndCleanup:YES];
		bg = nil;
	}
	CCNode *icon = [self getChildByTag:Fish_Item_Icon];
	if (icon) {
		[icon removeFromParentAndCleanup:YES];
		icon = nil;
	}
	CCNode *label = [self getChildByTag:Fish_Item_label];
	if (label) {
		[label removeFromParentAndCleanup:YES];
		label = nil;
	}
	
	count = 0;
	self.tag = 0;
	
	CCSprite *itemBg = [CCSprite spriteWithFile:@"images/ui/panel/itemNull.png"];
	self.contentSize = itemBg.contentSize;
	itemBg.anchorPoint = CGPointZero;
	[self addChild:itemBg];
}

-(void)onEnter
{
	[super onEnter];
	
}

-(void)onExit
{
	[super onExit];
}

@end

@implementation FishReward

@synthesize playerItemId;

-(void)onEnter
{
	[super onEnter];
	if (iPhoneRuningOnGame()) {
			Fish_Item_orgin		=	ccp(10/2.0f,400/2.0f);
			Fish_Item_Offer		=	CGSizeMake(50,50);
			Fish_Item_Page_size	=	CGSizeMake(304/2.0f, 548/2.0f);
	}else{
	  Fish_Item_orgin		=	ccp(4, 320);
	  Fish_Item_Offer		=	CGSizeMake(92, 92);
	  Fish_Item_Page_size	=	CGSizeMake(276, 408);
	}

	self.touchEnabled = YES;
	self.touchPriority = -100;
	
	playerItemId = 0;
	lockUse = NO;
	
	if (iPhoneRuningOnGame()) {
		MessageBox *bg3 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
		bg3.contentSize = CGSizeMake(628/2.0f,546/2.0f);
		bg3.position = ccp(97/2.0f, 32/2.0f);
		[self addChild:bg3];
	}
	
	CCSprite *bg2 =nil;
	if (iPhoneRuningOnGame()) {
		bg2=[CCSprite spriteWithFile:@"images/ui/wback/p29.jpg"];		
	}else{
		bg2=[CCSprite spriteWithFile:@"images/ui/panel/p29.jpg"];
	}
	bg2.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		bg2.scale=1.01f;
		bg2.position = ccp(12/2.0f+44, 17.5);
	}else{
		bg2.position = ccp(25, 19);
	}
	[self addChild:bg2];
	
	itemBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			itemBg.position =  ccp(333/2.0f+44, 495/2.0f);
		}else{
			itemBg.position =  ccp(333/2.0f+44, 495/2.0f);
		}
	}else{
		itemBg.position =  ccp(270, 349);
	}
	[self addChild:itemBg];
	
	if(iPhoneRuningOnGame()){
		CCSprite* down=[CCSprite spriteWithFile:@"images/ui/npc_alert/7.png"];
		down.position=ccp(itemBg.position.x,itemBg.position.y-itemBg.contentSize.height-10);
		[self addChild:down];
	}
	
	listLayer = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	if (iPhoneRuningOnGame()) {
		listLayer.contentSize = CGSizeMake(307/2.0f,546/2.0f);
		listLayer.position = ccp(733/2.0f, 32/2.0f);
	}else{
		listLayer.contentSize = CGSizeMake(330, 421);
		listLayer.position = ccp(519, 19);
	}
	[self addChild:listLayer];
	
	[self initFishItemData];
	[self initScrollPanel];
	
	[self showBox:FishReward_close];
	
	// 宝箱闪烁
	NSString *fullPath1 = @"images/animations/boxopen/1/";
	NSString *fullPath2 = @"images/animations/boxopen/2/";
	NSArray *roleFrames1 = [AnimationViewer loadFileByFileFullPath:fullPath1 name:@"%d.png"];
	NSArray *roleFrames2 = [AnimationViewer loadFileByFileFullPath:fullPath2 name:@"%d.png"];
	
	shineOver = [AnimationViewer node];
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			shineOver.position = ccp(307/2.0f+44, 185/2);
		}else{
			shineOver.position = ccp(307/2.0f+44, 185/2);
		}
	}else{
		shineOver.position = ccp(273, 150);
	}
	shineOver.visible = NO;
	[shineOver playAnimation:roleFrames1];
	[self addChild:shineOver z:15];
	
	shineUnder = [AnimationViewer node];
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			shineUnder.position = ccp(307/2+44, 185/2);
		}else{
			shineUnder.position = ccp(307/2+44, 185/2);
		}
	}else{
		shineUnder.position = ccp(273, 150);
	}
	shineUnder.visible = NO;
	[shineUnder playAnimation:roleFrames2];
	[self addChild:shineUnder z:5];
	
}

-(void)initFishItemData
{
	NSMutableArray *_array = [[[NSMutableArray alloc] init] autorelease];
	NSDictionary *tableDict = [[GameDB shared] readDB:@"item"];
	
	NSArray *items = [[GameConfigure shared] getPlayerItemByType:Item_fish_item];
	for (NSDictionary *dict in items) {
		NSString *key = [[dict objectForKey:@"iid"] stringValue];
		NSDictionary *itemDict = [tableDict objectForKey:key];
		int iid = [key intValue];
		int quality = [[itemDict objectForKey:@"quality"] intValue];
		int num = iid+quality*1000;
		NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
		[_dict setValue:[NSNumber numberWithInt:num] forKey:@"num"];
		[_array addObject:_dict];
	}
	fishItems = (NSMutableArray *)[_array sortedArrayUsingComparator:^(id obj1, id obj2){
		int iid1 = [[obj1 objectForKey:@"num"] intValue];
		int iid2 = [[obj2 objectForKey:@"num"] intValue];
		if(iid1 < iid2) {
			return(NSComparisonResult)NSOrderedDescending;
		}
		if(iid1 > iid2) {
			return(NSComparisonResult)NSOrderedAscending;
		}
		return(NSComparisonResult)NSOrderedSame;
	}];
	_array = nil;
	[fishItems retain];
}

-(FishItem *)initFishItem:(NSDictionary *)dict index:(int)index
{
	int pageIndex = index / Fish_Item_Page_count;
	index = index % Fish_Item_Page_count;
	CGPoint fishItemOrgin = ccpAdd(Fish_Item_orgin, ccp(Fish_Item_Page_size.width*pageIndex, 0));
	CGPoint finalPosition = ccp(fishItemOrgin.x + Fish_Item_Offer.width*(index%Fish_Item_Column_count),
								fishItemOrgin.y - Fish_Item_Offer.height*(index/Fish_Item_Column_count));
	FishItem *item = [FishItem node];
	[item setDict:dict];
	item.position = finalPosition;
	
	return [item retain];
}

-(void)initScrollPanel
{
	int pageCount = fishItems.count>Fish_Item_Page_count?ceil((float)fishItems.count/Fish_Item_Page_count):1;
	CGSize size = CGSizeMake(Fish_Item_Page_size.width*pageCount,
							 Fish_Item_Page_size.height);
	itemLayer = [CCLayer node];
	itemLayer.contentSize = size;
	int i = 0;
	for (NSDictionary *dict in fishItems) {
		FishItem *item = [self initFishItem:dict index:i];
		[itemLayer addChild:item];
		[item release];
		i += 1;
	}
	int j = Fish_Item_Page_count - i % Fish_Item_Page_count;
	j = (j==Fish_Item_Page_count&&i!=0)?0:j;
	for (int k = 0; k < j; k++) {
		FishItem *item = [self initFishItem:nil index:i];
		[itemLayer addChild:item];
		[item release];
		i += 1;
	}
	
	CCPanelPage *panel = [CCPanelPage panelWithContent:itemLayer viewSize:Fish_Item_Page_size];
	if (iPhoneRuningOnGame()) {
		panel.position = ccp(735.0/2, 32/2);
	}else{
		panel.position = ccp(546, 26);
	}
	panel.tag = 20012;
	[self addChild:panel];
}

-(void)useFishItem:(int)_id iid:(int)_iid
{
	if (playerItemId == _id || _id == 0 || _iid == 0) {
		return;
	}
	if (playerItemId != 0) {
		FishItem *item = (FishItem *)[itemLayer getChildByTag:playerItemId];
		if (item) {
			[item setCount:++item.count];
		}
	}
	playerItemId = _id;
	FishItem *fishItem = (FishItem *)[itemLayer getChildByTag:playerItemId];
	if (fishItem) {
		int count = MAX(--fishItem.count, 0);
		[fishItem setCount:count];
	}
	CCNode *node = [self getChildByTag:Fish_Item_use];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	CCSprite *useSprite = getItemIcon(_iid);
	if (useSprite) {
		if (iPhoneRuningOnGame()) {
			if (isIphone5()) {
				useSprite.position =ccp(333/2.0f+44, 495/2.0f);
			}else{
				useSprite.position =ccp(333/2.0f+44, 495/2.0f);
			}
		}else{
			useSprite.position = ccp(270, 349);
		}
		useSprite.tag = Fish_Item_use;
		[self addChild:useSprite];
	}
	
	[self showBox:FishReward_button];
}

-(void)showBox:(FishRewardType)_type
{
	CCNode *node = [self getChildByTag:Fish_Reward_box];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	CGPoint point = ccp(273, 150);
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			point = ccp(307/2+44, 185/2.0f);
		}else{
			point = ccp(307/2+44, 185/2.0f);
		}
	}
	if (_type == FishReward_close) {
		CCSprite *sprite = [CCSprite spriteWithFile:@"images/ui/panel/t64.png"];
		if (sprite) {
			sprite.position = point;
			[self addChild:sprite z:10 tag:Fish_Reward_box];
			
			shineOver.visible = NO;
			shineUnder.visible = NO;
		}
	} else if (_type == FishReward_open) {
		CCSprite *sprite = [CCSprite spriteWithFile:@"images/ui/panel/t65.png"];
		if (sprite) {
			sprite.position = point;
			[self addChild:sprite z:10 tag:Fish_Reward_box];
			
			shineOver.visible = YES;
			shineUnder.visible = YES;
		}
	} else if (_type == FishReward_button) {
		CCSimpleButton *boxButton = [CCSimpleButton spriteWithFile:@"images/ui/panel/t65.png"
															select:@"images/ui/panel/t65.png"
															target:self
															  call:@selector(openBox)
														  priority:-101];
		boxButton.position = point;
		[self addChild:boxButton z:10 tag:Fish_Reward_box];
		
		shineOver.visible = YES;
		shineUnder.visible = YES;
	}
}

-(void)showBoxClose
{
	lockUse = NO;
	[self showBox:FishReward_close];
}

-(void)openBox
{
	if (playerItemId != 0) {
		lockUse = YES;
		
		NSString *idString = [NSString stringWithFormat:@"id::%d", playerItemId];
		[GameConnection request:@"useItem" format:idString target:self call:@selector(didUseFish:)];
	}
}

-(void)didUseFish:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			[self showBox:FishReward_open];
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			float delay = 1.5 * MAX(1, updateData.count);
			[self scheduleOnce:@selector(showBoxClose) delay:delay];
			
			// 移除用光的鱼获
			if (playerItemId != 0) {
				FishItem *fishItem = (FishItem *)[itemLayer getChildByTag:playerItemId];
				if (fishItem) {
					if (fishItem.count == 0) {
						[fishItem setNull];
					}
				}
			}
			CCNode *node = [self getChildByTag:Fish_Item_use];
			if (node) {
				[node removeFromParentAndCleanup:YES];
				node = nil;
			}
			
			[[GameConfigure shared] updatePackage:dict];
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	
	// 点击有效区域
	CCNode *panel = [self getChildByTag:20012];
	if (panel != nil) {
		CGPoint location = [panel convertToNodeSpace:touchLocation];
		if (!CGRectContainsPoint(CGRectMake(0, 0, panel.contentSize.width, panel.contentSize.height), location)) {
			return;
		}
	}
	
	touchLocation = [itemLayer convertToNodeSpace:touchLocation];
	
	if (!lockUse) {
		FishItem *item;
		CCARRAY_FOREACH(itemLayer.children, item) {
			if (CGRectContainsPoint(item.boundingBox, touchLocation)) {
				[self useFishItem:item.tag iid:item.iid];
				break;
			}
		}
	}
}

-(void)onExit
{
	if (fishItems) {
		[fishItems release];
		fishItems = nil;
	}
	
	if (shineOver) {
		[shineOver removeFromParentAndCleanup:YES];
		shineOver = nil;
	}
	
	if (shineUnder) {
		[shineUnder removeFromParentAndCleanup:YES];
		shineUnder = nil;
	}
	[GameConnection freeRequest:self];
	[super onExit];
}

@end
