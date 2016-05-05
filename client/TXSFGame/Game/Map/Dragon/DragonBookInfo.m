//
//  DragonBookInfo.m
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonBookInfo.h"
#import "Config.h"
#import "DragonReadyData.h"
#import "DragonFightData.h"
#import "CCSimpleButton.h"
#import "ShowItem.h"
#import "AlertManager.h"
#import "Arena.h"
#import "GameStart.h"

#define Offset_x			cFixedScale(86.0f)
#define Offset_x_per		cFixedScale(104.0f)
#define Pos_book_icon_y		cFixedScale(70.0f)

@interface DragonBookItem : CCSprite
{
	int _maxCD;
	int _maxCount;
	int _exchangeMaxCount;	// 最大兑换次数
	
	int _bookId;
	float _cd;
	int _exchange;
	
	BOOL _isRemoveCd;
	BOOL _isBoatHp;
	BOOL _isActive;		// 是否能使用
	DragonTime _dragonTime;
	
	NSString *_name;
	NSString *_desc;
	
	CCSprite *usableBg;
	CCSprite *disableBg;
	
	CCLabelTTF *countdownLabel;
}
@property (nonatomic, assign) int bookId;
@property (nonatomic, assign) int exchange;
@property (nonatomic, assign) BOOL isRemoveCd;
@property (nonatomic, assign) DragonTime dragonTime;

+(DragonBookItem*)create:(int)_bid dragonTime:(DragonTime)_time;

@end

@implementation DragonBookItem

@synthesize bookId = _bookId;
@synthesize exchange = _exchange;
@synthesize isRemoveCd = _isRemoveCd;
@synthesize dragonTime = _dragonTime;

+(DragonBookItem*)create:(int)_bid dragonTime:(DragonTime)_time
{
	DragonBookItem *item = [DragonBookItem node];
	item.dragonTime = _time;	// dragonTime要在bookId前面
	item.bookId = _bid;
	return item;
}

-(void)setBookId:(int)__bookId
{
	_bookId = __bookId;
	
	NSDictionary *dict = [[GameDB shared] getAwarBook:_bookId];
	if (dict != nil) {
		if (_name != nil) {
			[_name release];
			_name = nil;
		}
		_name = [dict objectForKey:@"name"];
		[_name retain];
		
		if (_desc != nil) {
			[_desc release];
			_desc = nil;
		}
		_desc = [dict objectForKey:@"des"];
		[_desc retain];
		
		_maxCD = [[dict objectForKey:@"time"] intValue];
		_exchange = [[dict objectForKey:@"exchange"] intValue];
		
		if (_dragonTime == DragonTime_fight) {
			_exchangeMaxCount = [self getExchangeMaxCount];
		}
		
		int uncd = [[dict objectForKey:@"uncd"] intValue];
		_isRemoveCd = (uncd == 1);	// 判断解冻书
		
		int hard = [[dict objectForKey:@"hard"] intValue];
		_isBoatHp = (hard > 0);		// 判断修船书
		
		// 检查激活状态
		[self checkActive];
	}
}

-(id)init
{
	if (self = [super init]) {
		_maxCount = 3;
		_isActive = NO;
	}
	return self;
}

-(void)dealloc
{
	if (_name != nil) {
		[_name release];
		_name = nil;
	}
	if (_desc != nil) {
		[_desc release];
		_desc = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCLayer *bg = [CCLayerColor layerWithColor:ccc4(200, 0, 0, 0) width:cFixedScale(90) height:cFixedScale(110)];
	[self addChild:bg z:-1];
	
	self.contentSize = bg.contentSize;
	
	CCSimpleButton *button = [CCSimpleButton node];
	button.contentSize = self.contentSize;
	button.touchScale = 1.0f;
	button.anchorPoint = CGPointZero;
	button.position = CGPointZero;
	button.target = self;
	button.call = @selector(doUseBook);
	button.priority = -300;
	[self addChild:button];
	
	[self updateIcon];

	float fontSize = 30;
	if (iPhoneRuningOnGame()) {
		fontSize = 20;
	}
	countdownLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	countdownLabel.position = ccp(self.contentSize.width/2, Pos_book_icon_y);
	countdownLabel.color = ccc3(255, 0, 0);
	[self addChild:countdownLabel z:20];
	
	[self updateAll];
	[self scheduleOnce:@selector(checkActive) delay:0.5f];
	
	[GameConnection addPost:ConnPost_Dragon_local_result_win target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_result_lose_time target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_result_lose_boat target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_result_gm_exit target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_cd_add_after target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_cd_remove_after target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_boatHard target:self call:@selector(checkActive)];
	[GameConnection addPost:ConnPost_Dragon_local_glory target:self call:@selector(checkActive)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(int)getExchangeMaxCount
{
	int ascId = [DragonFightData shared].ascId;
	NSDictionary *dict = [[GameDB shared] getAwarStartConfig:ascId];
	if (dict != nil) {
		NSString *string = [dict objectForKey:@"books"];
		if (string != nil) {
			NSArray *array = [string componentsSeparatedByString:@"|"];
			for (NSString *__string in array) {
				NSArray *__array = [__string componentsSeparatedByString:@":"];
				if (__array.count >= 3) {
					int __id = [[__array objectAtIndex:0] intValue];
					if (__id == _bookId) {
						return [[__array objectAtIndex:2] intValue];
					}
				}
			}
		}
	}
	
	return 3;
}

-(void)updateIcon
{
	if (usableBg == nil) {
		usableBg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/dragon/book/%d_1.png", _bookId]];
		usableBg.position = ccp(self.contentSize.width/2, Pos_book_icon_y);
		
		[self addChild:usableBg];
	}
	if (disableBg == nil) {
		disableBg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/dragon/book/%d_2.png", _bookId]];
		disableBg.position = ccp(self.contentSize.width/2, Pos_book_icon_y);
		
		[self addChild:disableBg];
	}
	usableBg.visible = _isActive;
	disableBg.visible = !_isActive;
}

-(void)setIsActive:(BOOL)__isActive
{
	if (_isActive == __isActive) return;
	_isActive = __isActive;
	
	if (self.parent == nil) return;
	
	[self updateIcon];
}

-(void)checkActive
{
	// 准备房间无效
	if (_dragonTime == DragonTime_ready) {
		self.isActive = NO;
		return;
	}
	
	// 狩龙战结束
	if ([DragonFightData checkIsOver]) {
		self.isActive = NO;
		return;
	}
	
	// 天书cd不为0
	if (_cd > 0) {
		self.isActive = NO;
		return;
	}
	
	// 玩家CD
	if ([DragonFightData checkIsCD]) {
		self.isActive = _isRemoveCd;
		if (!_isActive) return;
	}
	// 玩家非CD
	else {
		self.isActive = !_isRemoveCd;
		if (!_isActive) return;
	}
	
	// 额外次数可用
	if ([[DragonFightData shared] checkUseExchangeBook:_bookId]) {
		// 普通次数不可用，此时可用同盟建设点兑换
		if (![[DragonFightData shared] checkUseNormalBook:_bookId]) {
			int currentExchange = [DragonFightData shared].glory;
			// 同盟建设点不足
			if (_exchange > currentExchange) {
				self.isActive = NO;
				return;
			}
		}
	}
	// 额外次数用完
	else {
		self.isActive = NO;
		return;
	}
	
	// 如果是修船书
	if (_isBoatHp) {
		self.isActive = [DragonFightData checkIsBoatHarm];
		if (!_isActive) return;
	}
	
	self.isActive = YES;
}

-(void)doUseBook
{
    if(!self.visible || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] || [GameStart isOpen] ){
		return;
	}
	
	// 上一次请求还没返回时无效
	if (![DragonFightData checkCanBookRequest]) return;
	
	// 准备房间
	if (_dragonTime == DragonTime_ready) return;
	
	// 同盟建设点不足
	if ([[DragonFightData shared] checkUseExchangeBook:_bookId]) {
		
		if (![[DragonFightData shared] checkUseNormalBook:_bookId]) {
			int currentExchange = [DragonFightData shared].glory;
			if (_exchange > currentExchange) {
				[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"dragon_book_use_noenough_glory",nil), _exchange]];
				return;
			}
		}
	}
	// 额外兑换次数已用完
	else {
		[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"dragon_book_use_over",nil), _exchangeMaxCount]];
		return;
	}
	
	// 没激活，无效
	if (!_isActive) return;
	
	if ([[DragonFightData shared] checkUseNormalBook:_bookId]) {
		
		[self confirmUseBook];
		
	} else if ([[DragonFightData shared] checkUseExchangeBook:_bookId]) {
		
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"dragon_book_use_by_glory",nil), _exchange, _name];
		[[AlertManager shared] showMessageWithConfirm:message target:self call:@selector(confirmUseBook)];
	}
}

-(void)confirmUseBook
{
	// 狩龙战结束时点击无效
	if ([DragonFightData checkIsOver]) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_fight_end",nil)];
		return;
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_bookId] forKey:@"bid"];
	
	NSMutableDictionary *argDict = [NSMutableDictionary dictionary];
	[argDict setObject:[NSNumber numberWithBool:_isRemoveCd] forKey:@"removeCd"];
	[argDict setObject:[NSNumber numberWithInt:_bookId] forKey:@"bookId"];
	[argDict setObject:[NSNumber numberWithInt:_maxCD] forKey:@"bookCd"];
	
	if (_desc != nil) {
		NSArray *array = [_desc componentsSeparatedByString:@"|"];
		if (array.count >= 2) {
			NSString *bookDesc = [array objectAtIndex:1];
			[argDict setObject:bookDesc forKey:@"bookDesc"];
		}
	}
	
	[GameConnection request:@"awarBookUse" data:dict target:[DragonFightData class] call:@selector(didUseBook:arg:) arg:argDict];
	
	// 设置天书请求中
	[DragonFightData setCanBookRequest:NO];
}

// 更新相关
-(void)updateAll
{
	[self updateItemCount];
	[self updateCd];
}

// 刷新天书数目
-(void)updateItemCount
{
	for (int i = 0; i < _maxCount; i++) {
		[self removeChildByTag:1000+i];
	}
	
	int count = [self getBookCount:_bookId];
	
	float perWidth = self.contentSize.width*1.0f/(_maxCount+1);
	CCSprite *icon = nil;
	for (int i = 0; i < _maxCount; i++) {
		if (i < count) {
			icon = [CCSprite spriteWithFile:@"images/ui/dragon/item_have.png"];
		} else {
			icon = [CCSprite spriteWithFile:@"images/ui/dragon/item_null.png"];
		}
		icon.position = ccp(perWidth*(i+1), cFixedScale(12));
		icon.tag = 1000+i;
		[self addChild:icon];
	}
}

// 更新cd，播放cd倒计时动画
-(void)updateCd
{
	[self unscheduleUpdate];
	
	if (![DragonFightData checkIsFight]) return;
	
	_cd = [[DragonFightData shared] getBookCD:_bookId];
	if (_cd <= 0) return;
	
	// 检查激活状态
	[self checkActive];
	
	[self scheduleUpdate];
}

-(void)update:(ccTime)delta
{
	_cd -= delta;
	if (_cd <= 0) {
		_cd = 0;
		countdownLabel.string = @"";
		
		// 检查激活状态
		[self checkActive];
		
		[self unscheduleUpdate];
	} else {
		if (_cd != [countdownLabel.string intValue]) {
			countdownLabel.string = [NSString stringWithFormat:@"%d", (int)_cd];
		}
	}
}

-(int)getBookCount:(int)__bookId
{
	if (_dragonTime == DragonTime_ready) {
		return [[DragonReadyData shared] getBookCount:_bookId];
	} else {
		return [[DragonFightData shared] getBookCount:_bookId];
	}
}

@end

@implementation DragonBookInfo

@synthesize dragonTime = _dragonTime;

+(DragonBookInfo*)create:(DragonTime *)_time
{
	DragonBookInfo *dragonBookInfo = [DragonBookInfo node];
	dragonBookInfo.dragonTime = _time;
	return dragonBookInfo;
}

-(id)init
{
	if (self = [super init]) {
		_bookArray = [NSMutableArray array];
		[_bookArray retain];
	}
	return self;
}

-(void)dealloc
{
	if (_bookArray != nil) {
		[_bookArray release];
		_bookArray = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_book.png"];
	bg.anchorPoint = CGPointZero;
	bg.position = ccp(0, cFixedScale(42.0f));
	[self addChild:bg];
	
	self.contentSize = CGSizeMake(bg.contentSize.width, cFixedScale(120.f));
	
	int i = 0;
	NSDictionary *bookDict = nil;
	if (_dragonTime == DragonTime_ready) {
		bookDict = [DragonReadyData shared].skyBookDict;
	} else {
		bookDict = [DragonFightData shared].booksData;
	}
	
	NSArray *allKeys = [bookDict allKeys];
	int bookCount = allKeys.count;
	
	for (NSString *key in allKeys) {
		
		float x = self.contentSize.width-Offset_x-(bookCount-i-1)*Offset_x_per;
		CGPoint point = ccp(x, self.contentSize.height/2);
		
		int bookId = [key intValue];
		DragonBookItem *dragonBookItem = [DragonBookItem create:bookId dragonTime:_dragonTime];
		dragonBookItem.position = point;
		[self addChild:dragonBookItem];
		
		[_bookArray addObject:dragonBookItem];
		
		i++;
	}
	
	[GameConnection addPost:ConnPost_Dragon_local_callback_useBook target:self call:@selector(didUseBook:)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[_bookArray removeAllObjects];
	
	[super onExit];
}

-(DragonBookItem*)getBook:(int)__bookId
{
	for (DragonBookItem *bookItem in _bookArray) {
		
		if (bookItem.bookId == __bookId) {
			return bookItem;
		}
		
	}
	return nil;
}

-(void)didUseBook:(NSNotification*)notification
{
	NSDictionary *data = notification.object;
	
	int __bookId = [[data objectForKey:@"bookId"] intValue];
	DragonBookItem *bookItem = [self getBook:__bookId];
	if (bookItem != nil) {
		[bookItem updateAll];
	}
}

@end
