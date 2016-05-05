//
//  SocialityCanvas.m
//  TXSFGame
//
//  Created by efun on 13-3-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SocialityCanvas.h"
#import "Config.h"

#define SocialityTag_bg		20000
#define SocialityTag_sex	20001
#define SocialityTag_name	20002
#define SocialityTag_level	20003
#define SocialityTag_panel	20004
#define SocialityTag_more	20005

//#define SocialityItemHeight			 cFixedScale(23)
#define SocialityItemHeight	(iPhoneRuningOnGame()?20.5:23)
//#define SocialityCountPer	15

@implementation SocialityItem

@synthesize pid;
@synthesize rid;
@synthesize level;
@synthesize status;
@synthesize isSelected;
@synthesize name = _name;

-(id)init
{
	if (self = [super init]) {
		self.contentSize = CGSizeMake(cFixedScale(332), SocialityItemHeight);
		CCSprite *bg = nil;
		if (iPhoneRuningOnGame()) {
			bg = [CCSprite spriteWithFile:@"images/ui/wback/t69.png"];
		} else {
			bg = [CCSprite spriteWithFile:@"images/ui/panel/t69.png"];
		}
		bg.anchorPoint = CGPointZero;
		bg.visible = NO;
		bg.tag = SocialityTag_bg;
		[self addChild:bg];
		isSelected = NO;
	}
//    showNode(self);
	return self;
}

-(void)onEnter
{
	[super onEnter];
	CGSize parentSize = self.parent.contentSize;
	CCNode *bg = [self getChildByTag:SocialityTag_bg];
	if (bg) {
		bg.scaleX = parentSize.width/bg.contentSize.width;
	}
}

-(void)setIsSelected:(BOOL)isSelected_
{
	if (isSelected == isSelected_) {
		return;
	}
	
	isSelected = isSelected_;
	CCNode *node = [self getChildByTag:SocialityTag_bg];
	if (node) {
		node.visible = isSelected;
	}
}

-(void)setPid:(int)pid_
{
	pid = pid_;
	
	self.tag = pid;
}

-(void)setRid:(int)rid_
{
	rid = rid_;
	
	[self removeChildByTag:SocialityTag_sex];
	int sex = 1;
	if (rid == 2 || rid == 4 || rid == 6) {
		sex = 2;
	}
	CCSprite *sexSprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/sex%d.png", sex]];
	sexSprite.position = ccp(cFixedScale(60), self.contentSize.height/2);
	sexSprite.tag = SocialityTag_sex;
	if (iPhoneRuningOnGame()) {
		sexSprite.scale = 1.2;
	}
	[self addChild:sexSprite];
}

-(void)setLevel:(int)level_
{
	level = level_;
	
	[self removeChildByTag:SocialityTag_level];
	NSString *levelString = [NSString stringWithFormat:@"lv%d", level];
	float fontSize = 14;
	if (iPhoneRuningOnGame()) {
		fontSize = 10;
	}
	CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:levelString fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	levelLabel.anchorPoint = ccp(0, 0.5);
	levelLabel.position = ccp(	cFixedScale(252), self.contentSize.height/2);
	levelLabel.color = status == 0 ?  ccc3(170, 156, 123): ccc3(236, 228, 206);
	levelLabel.tag = SocialityTag_level;
	[self addChild:levelLabel];
}

-(void)setStatus:(int)status_
{
	status = status_;
	
	CCLabelTTF *nameLabel = (CCLabelTTF *)[self getChildByTag:SocialityTag_name];
	if (nameLabel) {
		nameLabel.color = status == 0 ? ccc3(170, 156, 123) : ccc3(5, 173, 234);
	}
	CCLabelTTF *levelLabel = (CCLabelTTF *)[self getChildByTag:SocialityTag_level];
	if (levelLabel) {
		levelLabel.color = status == 0 ? ccc3(170, 156, 123): ccc3(236, 228, 206);
	}
}

-(void)setName:(NSString *)name_
{
	_name = name_;
	
	[self removeChildByTag:SocialityTag_name];
	float fontSize = 14;
	if (iPhoneRuningOnGame()) {
		fontSize = 10;
	}
	CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:_name fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	nameLabel.color = status == 0 ? ccc3(170, 156, 123) : ccc3(5, 173, 234);
	nameLabel.anchorPoint = ccp(0, 0.5);
	nameLabel.position = ccp(cFixedScale(75), self.contentSize.height/2);
	nameLabel.tag = SocialityTag_name;
	[self addChild:nameLabel];
}

-(void)onExit
{
	[super onExit];
}

@end

@implementation SocialityCanvas

@synthesize onlineCount;
@synthesize totalCount;

-(id)init
{
	if (self = [super init]) {
		self.onlineCount = 0;
		self.totalCount = 0;
	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	parentSize = self.parent.contentSize;
	self.contentSize = parentSize;
	
	float fontSize = 14;
	if (iPhoneRuningOnGame()) {
		fontSize = 10;
	}
	//moreLabel = [CCLabelTTF labelWithString:@"更多" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    moreLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"sociality_canvas_more",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	moreLabel.tag = SocialityTag_more;
	moreLabel.position = ccp(parentSize.width/2, 	cFixedScale(12));
	moreLabel.color = ccc3(170, 156, 123);
	moreLabel.visible = NO;
	[self addChild:moreLabel];
	
	isLoading = NO;
}

-(void)onExit
{
	if (moreLabel) {
		[moreLabel removeFromParentAndCleanup:YES];
		moreLabel = nil;
	}
	[super onExit];
}

-(SocialityItem*)getEventTray:(UITouch*)touch{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	for (CCNode *node in self.children) {
		if (node.tag == SocialityTag_more) {
			continue;
		}
		if (CGRectContainsPoint(node.boundingBox, touchLocation)) {
			return (SocialityItem *)node;
		}
	}
	return nil;
}

-(void)removeSelected
{
	for (SocialityItem *item in self.children) {
		if (item.tag == SocialityTag_more) {
			continue;
		}
		if (item.isSelected) {
			item.isSelected = NO;
		}
	}
}

-(void)removeList
{
	NSMutableArray *nodeArray = [NSMutableArray array];
	for (int i = 0; i < self.children.count; i++) {
		CCNode *node = [self.children objectAtIndex:i];
		if (node.tag == SocialityTag_more) {
			continue;
		}
		[nodeArray addObject:node];
	}
	for (CCNode *node in nodeArray) {
		[node removeFromParentAndCleanup:YES];
	}
	[nodeArray removeAllObjects];
	nodeArray = nil;
}

// 添加成员数组
// 在线玩家clear=YES
-(void)updateMembers:(NSDictionary *)dict clear:(BOOL)clear
{
	self.totalCount = dict.allKeys.count;
	
	// 在线玩家
	if (clear) {
		[self removeList];
		int count = dict.allKeys.count;
		float height = SocialityItemHeight*count;
		self.contentSize = CGSizeMake(parentSize.width,
									  MAX(parentSize.height, height));
		self.position = ccp(0, parentSize.height - self.contentSize.height);
		
		int i = 1;
		int o = 0;// 在线
		for (NSString *key in dict.allKeys) {
			NSDictionary *d = [dict objectForKey:key];
			SocialityItem *item = [SocialityItem node];
			item.pid = [[d objectForKey:@"id"] intValue];
			item.rid = [[d objectForKey:@"rid"] intValue];
			item.name = [d objectForKey:@"name"];
			item.level = [[d objectForKey:@"level"] intValue];
			item.status = [[d objectForKey:@"st"] intValue];
			[self addChild:item];
			
			CGPoint pos = ccp(0, self.contentSize.height-item.contentSize.height*i);
			item.position = pos;
			
			if (item.status == 1) {
				o++;
			}
			
			i++;
		}
		self.onlineCount = o;
		
		// test show
		CCLOG(@"----------总人数%d : 在线%d", self.totalCount, self.onlineCount);
		
		return;
	}

	// 好友，黑名单
	NSMutableArray *allKeys = [NSMutableArray arrayWithArray:[dict allKeys]];
	
	// 数量是15的倍数时，显示更多
	[moreLabel unscheduleAllSelectors];
	//moreLabel.string = @"更多";
    moreLabel.string = NSLocalizedString(@"sociality_canvas_more",nil);
	moreLabel.visible = (allKeys.count % 15 == 0);
	isLoading = NO;
	
	for (CCNode *node in self.children) {
		if (node.tag == SocialityTag_more) {
			continue;
		}
		SocialityItem *item = (SocialityItem *)node;
		NSObject *obj = [NSString stringWithFormat:@"%d", item.pid];
		if ([allKeys containsObject:obj]) {
			[allKeys removeObject:obj];
		}
	}
	if (allKeys.count <= 0) {
		return;
	}
	
	int count = self.children.count;
	int beforeCount = MAX(parentSize.height/SocialityItemHeight, count);
	int afterCount = MAX(parentSize.height/SocialityItemHeight, count+allKeys.count);
	
	int index = count+1;
	for (CCNode *node in self.children) {
		if (node.tag == SocialityTag_more) {
			index--;
			break;
		}
	}
	
	// 添加后高度有变化
	if (afterCount > beforeCount) {
		self.contentSize = CGSizeMake(self.contentSize.width,
									  self.contentSize.height+SocialityItemHeight*(afterCount-beforeCount));
		for (CCNode *node in self.children) {
			if (node.tag != SocialityTag_more) {
				node.position = ccp(node.position.x,
									node.position.y+(afterCount-beforeCount)*SocialityItemHeight);
			}
		}
	}
	for (NSString *key in allKeys) {
		NSDictionary *d = [dict objectForKey:key];
		SocialityItem *item = [SocialityItem node];
		item.pid = [[d objectForKey:@"id"] intValue];
		item.rid = [[d objectForKey:@"rid"] intValue];
		item.name = [d objectForKey:@"name"];
		item.level = [[d objectForKey:@"level"] intValue];
		item.status = [[d objectForKey:@"st"] intValue];
		[self addChild:item];
		
		CGPoint pos = ccp(0, self.contentSize.height-item.contentSize.height*index);
		item.position = pos;
		
		// 在线
		if (item.status == 1) {
			self.onlineCount++;
		}
		if (iPhoneRuningOnGame()) {
//            item.scale = 0.5;
        }
		index++;
	}
	self.position = ccp(self.position.x, self.position.y-(afterCount-beforeCount)*SocialityItemHeight);
	
	// test show
	CCLOG(@"----------总人数%d : 在线%d", self.totalCount, self.onlineCount);
}
// 添加成员
-(void)addMember:(NSDictionary *)dict
{
	if (dict == nil) {
		return;
	}
	
	SocialityItem *item = [SocialityItem node];
	item.pid = [[dict objectForKey:@"id"] intValue];
	item.rid = [[dict objectForKey:@"rid"] intValue];
	item.name = [dict objectForKey:@"name"];
	item.level = [[dict objectForKey:@"level"] intValue];
	item.status = [[dict objectForKey:@"st"] intValue];

	// 玩家数目
	self.totalCount++;
	if (item.status == 1) {
		self.onlineCount++;
	}
	
	// 直接添加在上面
	if (self.children.count >= parentSize.height/SocialityItemHeight) {
		self.contentSize = CGSizeMake(self.contentSize.width,
									  self.contentSize.height+SocialityItemHeight);
	} else {
		for (CCNode *node in self.children) {
			if (node.tag != SocialityTag_more) {
				node.position = ccp(node.position.x, node.position.y-SocialityItemHeight);
			}
		}
	}
	
	item.position = ccp(0, self.contentSize.height-SocialityItemHeight);
	[self addChild:item];
	
	self.position = ccp(0, parentSize.height-self.contentSize.height);
}
// 删除成员
-(void)deleteMember:(NSDictionary *)dict
{
	if (dict == nil) {
		return;
	}
	int _id = [[dict objectForKey:@"id"] intValue];
	SocialityItem *socialityItem = nil;
	for (CCNode *node in self.children) {
		if (node.tag == SocialityTag_more) {
			continue;
		}
		SocialityItem *item = (SocialityItem *)node;
		if (item.pid == _id) {
			socialityItem = item;
			break;
		}
	}
	
	if (socialityItem == nil) {
		return;
	}
	
	// 玩家数目
	self.totalCount = MAX(self.totalCount--, 0);
	if (socialityItem.status == 1) {
		self.onlineCount = MAX(self.onlineCount--, 0);
	}
	
	if (self.children.count >= parentSize.height/SocialityItemHeight+1) {
		self.contentSize = CGSizeMake(self.contentSize.width,
									  self.contentSize.height-SocialityItemHeight);
		for (CCNode *node in self.children) {
			if (node.position.y > socialityItem.position.y) {
				node.position = ccp(node.position.x, node.position.y-SocialityItemHeight);
			}
		}
		self.position = ccp(self.position.x, self.position.y+SocialityItemHeight);
	} else {
		for (CCNode *node in self.children) {
			if (node.tag != SocialityTag_more && node.position.y < socialityItem.position.y) {
				node.position = ccp(node.position.x, node.position.y+SocialityItemHeight);
			}
		}
	}
	
	[socialityItem removeFromParentAndCleanup:YES];
	socialityItem = nil;
}

-(void)hideMoreLabel
{
	moreLabel.visible = NO;
}

// 返回YES表示查看更多
-(BOOL)checkMore
{
	if (!isLoading && moreLabel.visible) {
		isLoading = YES;
		//moreLabel.string = @"加载中...";
        moreLabel.string = NSLocalizedString(@"sociality_canvas_loading",nil);
		[self scheduleOnce:@selector(hideMoreLabel) delay:5.0f];
		return YES;
	}
	return NO;
}

@end