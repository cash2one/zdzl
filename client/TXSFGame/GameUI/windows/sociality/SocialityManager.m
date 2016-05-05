//
//  SocialityManager.m
//  TXSFGame
//
//  Created by efun on 13-3-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SocialityManager.h"
#import "SocialityPanel.h"
#import "ItemManager.h"
#import "ChatPanelBase.h"

#define SocialityPanelSize		CGSizeMake(iPhoneRuningOnGame()?184:332, iPhoneRuningOnGame()?164:345)
#define SocialityMorePer		0.2
@implementation SocialityManager

@synthesize currentType;
@synthesize friendCanvas = _friendCanvas;
@synthesize onlineCanvas = _onlineCanvas;
@synthesize blacklistCanvas = _blacklistCanvas;
@synthesize currentCanvas = _currentCanvas;

static SocialityManager *s_SocialityManager = nil;

+(SocialityManager*)shared{
	if (!s_SocialityManager) {
		s_SocialityManager = [[[SocialityManager alloc] initWithSize:SocialityPanelSize] autorelease];
	}
	
	return s_SocialityManager;
}

// size.height为SocialityItemHeight(23)的倍数
-(id)initWithSize:(CGSize)size{
	
	if ((self = [super init])) {
		self.contentSize = size;
		
		self.friendCanvas = [SocialityCanvas node];
		[self addChild:_friendCanvas z:100 tag:Sociality_friend];
		
		self.onlineCanvas = [SocialityCanvas node];
		[self addChild:_onlineCanvas z:100 tag:Sociality_online];
		
		self.blacklistCanvas = [SocialityCanvas node];
		[self addChild:_blacklistCanvas z:100 tag:Sociality_blacklist];
		
		_friendCanvas.visible = NO;
		_onlineCanvas.visible = NO;
		_blacklistCanvas.visible = NO;
		
		self.currentType = -1;
		[[SocialHelper shared] freeMembers];
		
		// 添加通知
		[GameConnection addPost:Post_socialHelper_update_friends target:self call:@selector(updateMembers:)];
		[GameConnection addPost:Post_socialHelper_update_enemies target:self call:@selector(updateMembers:)];
		[GameConnection addPost:Post_socialHelper_update_strangers target:self call:@selector(updateMembers:)];
		
		[GameConnection addPost:Post_socialHelper_add_friends target:self call:@selector(addMember:)];
		[GameConnection addPost:Post_socialHelper_add_enemies target:self call:@selector(addMember:)];
		
		[GameConnection addPost:Post_socialHelper_del_friends target:self call:@selector(deleteMember:)];
		[GameConnection addPost:Post_socialHelper_del_enemies target:self call:@selector(deleteMember:)];
	}
	
	s_SocialityManager = self;
	
	return self;
}

-(void)setCanvasWithType:(SocialityType)type
{
	_friendCanvas.visible = NO;
	_onlineCanvas.visible = NO;
	_blacklistCanvas.visible = NO;
	
	if (type == Sociality_friend) {
		_friendCanvas.visible = YES;
		_currentCanvas = _friendCanvas;
	} else if (type == Sociality_online) {
		_onlineCanvas.visible = YES;
		_currentCanvas = _onlineCanvas;
	} else if (type == Sociality_blacklist) {
		_blacklistCanvas.visible = YES;
		_currentCanvas = _blacklistCanvas;
	}
}

-(void)dealloc{
	CCLOG(@"ItemManager->dealloc");
	s_SocialityManager = nil ;
	
	[GameConnection removePostTarget:self];
	
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
	
	stealTouches_ = YES;
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

-(void)checkTrayEvent{
	if (state_  == tCCScrollLayerStateTopIn_) {
		if (scrollTouch_ != nil) {
			state_ = tCCScrollLayerStateBottomIn_;
			_socialityItem = nil;
			if (_currentCanvas != nil) {
				_socialityItem = [_currentCanvas getEventTray:scrollTouch_];
			}
		}
	}
}

-(void)removeCurrentSelected
{
	if (_currentCanvas) {
		[_currentCanvas removeSelected];
	}
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    if( scrollTouch_ == touch ) {
        scrollTouch_ = nil;
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	// 清除选中
	[self removeCurrentSelected];
	
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint sPt = [self.parent convertToWorldSpace:self.position];
	
	float rx = sPt.x + self.contentSize.width;
	float ty = sPt.y + self.contentSize.height;
	
	if ([self checkIn:touchPoint start:sPt end:ccp(rx, ty)]) {
		scrollTouch_ = touch;
		touchSwipe_ = touchPoint;
		
		state_ = tCCScrollLayerStateTopIn_;
		
		return YES;
	}
	
	[[SocialityPanel shared] hideAction];
	
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
		
		if (_currentCanvas) {
			[_currentCanvas stopAllActions];
			layerSwipe_ = _currentCanvas.position;
		}
		
	}
	
	//上层滑动
	if (state_ == tCCScrollLayerStateTopSlid_){
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		temp.x = 0 ;
		CGPoint newPt = ccpAdd(temp, layerSwipe_);
		if (_currentCanvas != nil) {
			_currentCanvas.position = newPt;
		}
	}
	
	[[SocialityPanel shared] hideAction];
	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	scrollTouch_ = nil;
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	//单纯的点击事件
	if (state_ == tCCScrollLayerStateTopIn_) {
		
		CGPoint _point = [[SocialityPanel shared] convertToNodeSpace:touchPoint];
		if (![[SocialityPanel shared] checkTouchAction:_point]) {
			
			if (_socialityItem == nil) {
				_socialityItem = [_currentCanvas getEventTray:touch];
			}
			if (_socialityItem != nil) {
				_socialityItem.isSelected = YES;
				
				// 好友列表
				if (self.isFriendList) {
					[ChatPanelBase sendPrivateChannle:_socialityItem.name pid:_socialityItem.pid];
				}
				// 多种列表
				else {
					[[SocialityPanel shared] setAction:_point playerId:_socialityItem.pid name:_socialityItem.name];
				}
				
			}
			
		}
	}
	
	//结束顶层拖拽
	if (state_ == tCCScrollLayerStateTopSlid_){
		CCLOG(@"Finish-top-layer-slid");
		
		if (_currentCanvas.position.y > self.contentSize.height*SocialityMorePer &&
			[_currentCanvas checkMore]) {
			
			SocialHelper_relation action = SocialHelper_relation_none;
			if (_currentCanvas == _friendCanvas) {
				action = SocialHelper_relation_friend;
			} else if (_currentCanvas == _blacklistCanvas) {
				action = SocialHelper_relation_enemy;
			}
			[[SocialHelper shared] socialRelationmembers:action];
		}
		
		[self revisionSwipe];
	}
	
	state_ = tCCScrollLayerStateNo_;
	_socialityItem = nil;
	
}

-(void)revisionSwipe{
	if (_currentCanvas != nil) {
		id move = nil;
		if (_currentCanvas.position.y > 0) {
			move = [CCMoveTo actionWithDuration:1 position:ccp(0, 0)];
		} else if (_currentCanvas.position.y+_currentCanvas.contentSize.height < self.contentSize.height) {
			move = [CCMoveTo actionWithDuration:1 position:ccp(0, self.contentSize.height-_currentCanvas.contentSize.height)];
		}
		if (move) {
			[_currentCanvas stopAllActions];
			id action = [CCEaseElasticOut actionWithAction:move period:0.8f];
			[_currentCanvas runAction:action];
		}
	}
}

-(void)deleteAllContainer{
	if (_friendCanvas) {
		[_friendCanvas removeFromParentAndCleanup:YES];
		_friendCanvas = nil;
	}
	if (_onlineCanvas) {
		[_onlineCanvas removeFromParentAndCleanup:YES];
		_onlineCanvas = nil;
	}
	if (_blacklistCanvas) {
		[_blacklistCanvas removeFromParentAndCleanup:YES];
		_blacklistCanvas = nil;
	}
}

-(void)updateMembers:(NSNotification *)notification
{
	SocialityCanvas *canvas = nil;
	NSMutableDictionary *members = nil;
	
	BOOL clear = NO;
	NSString *name = notification.name;
	if ([name isEqualToString:Post_socialHelper_update_friends]) {
		
		canvas = _friendCanvas;
		members = [[SocialHelper shared] friends];
		
	} else if ([name isEqualToString:Post_socialHelper_update_strangers]) {
		
		canvas = _onlineCanvas;
		members = [[SocialHelper shared] otherMembers];
		clear = YES;
		
	} else if ([name isEqualToString:Post_socialHelper_update_enemies]) {
		
		canvas = _blacklistCanvas;
		members = [[SocialHelper shared] blacklists];
		
	}
	
	if (canvas && members) {
		[canvas updateMembers:members clear:clear];
	}
}

-(void)addMember:(NSNotification *)notification
{
	NSString *name = notification.name;
	if ([name isEqualToString:Post_socialHelper_add_friends]) {
		
		[_friendCanvas addMember:notification.object];
		
	} else if ([name isEqualToString:Post_socialHelper_add_enemies]) {
		
		[_blacklistCanvas addMember:notification.object];
		
	}
}

-(void)deleteMember:(NSNotification *)notification
{
	NSString *name = notification.name;
	if ([name isEqualToString:Post_socialHelper_del_friends]) {
		
		[_friendCanvas deleteMember:notification.object];
		
	} else if ([name isEqualToString:Post_socialHelper_del_enemies]) {
		
		[_blacklistCanvas deleteMember:notification.object];
		
	}
}

@end