//
//  ItemSizer.m
//  TXSFGame
//
//  Created by Soul on 13-3-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ItemSizer.h"
#import "CCNode+AddHelper.h"
#import "Config.h"

@implementation CSizer

-(void)onExit{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-171 swallowsTouches:YES];
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self isTouchInSite:touch]) {
		CCLOG(@"SizerMember->ccTouchBegan");
		return YES;
	}
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self isTouchInSite:touch]) {
		CCLOG(@"SizerMember->ccTouchEnded");
	}
}
@end

@implementation SizerMumber
@synthesize type = _type;
@synthesize target = _target;
@synthesize call =_call;

-(id)init{
	if ((self = [super init])) {
		
		if (_background == nil) {
			_background = [CCSprite spriteWithFile:@"images/ui/panel/filterItem.png"];
			if (iPhoneRuningOnGame()) {
				_background.scale=1.6f;
			}
			self.contentSize =CGSizeMake(_background.contentSize.width*_background.scale, _background.contentSize.height*_background.scale);
			[self Category_AddChildToCenter:_background z:0 tag:3008];
			_background.visible = NO ;
		}
		
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(int)getFontSize{
	if (iPhoneRuningOnGame()) {
		return 14;
	}else{
		return 18;
	}
}
-(void)setType:(int)type{
	_type = type;
	
	if (_text == nil) {
		_text = [CCLabelTTF labelWithString:@""
								   fontName:@"Verdana-Bold"
								   fontSize:[self getFontSize]];
		
		_text.color = ccc3(200, 200, 200);
		[self Category_AddChildToCenter:_text z:2 tag:78];
	}
	
	if (_type == 1){//全部
		//[_text setString:@"全 部"];
        [_text setString:NSLocalizedString(@"item_sizer_all",nil)];
	}
	if (_type == 2){//装备
		//[_text setString:@"装 备"];
        [_text setString:NSLocalizedString(@"item_sizer_equip",nil)];
	}
	if (_type == 3){//消耗品
		//[_text setString:@"消耗品"];
        [_text setString:NSLocalizedString(@"item_sizer_expendable",nil)];
	}
	if (_type == 4){//元神
		//[_text setString:@"元 神"];
        [_text setString:NSLocalizedString(@"item_sizer_fate",nil)];
	}
	if (_type == 5){//材料
		//[_text setString:@"材 料"];
        [_text setString:NSLocalizedString(@"item_sizer_material",nil)];
	}
	if (_type == 6){//材料
		//[_text setString:@"材 料"];
        [_text setString:NSLocalizedString(@"item_sizer_jewel",nil)];
	}
}
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self isTouchInSite:touch]) {
		if (_background != nil) {
			_background.visible = YES ;
		}
		if (_text != nil) {
			_text.color = ccc3(255, 255, 255);
		}
		return YES;
	}
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{

	if (_background != nil) {
		_background.visible = NO ;
	}
	
	if (_text != nil) {
		_text.color = ccc3(200, 200, 200);
	}
	
	if ([self isTouchInSite:touch]) {
		CCLOG(@"SizerMember->ccTouchEnded");
		
		if (_target != nil && _call != nil) {
			
			[_target performSelector:_call withObject:[NSNumber numberWithInt:_type]];
			_target = nil ;
			_call = nil ;
			
		}
	}
}

@end


@implementation ItemSizer

@synthesize selectIndex = _selectIndex ;
@synthesize target = _target;
@synthesize call = _call ;


-(void)onEnter{
	[super onEnter];
	
	CCSprite* background = [CCSprite spriteWithFile:@"images/ui/panel/bt_filterBack.png"];

	if (iPhoneRuningOnGame()) {
		background.scale=1.6f;
		self.contentSize =CGSizeMake(background.contentSize.width*background.scale,background.contentSize.height*background.scale);
	}else{
		self.contentSize = background.contentSize;
	}
	[self Category_AddChildToCenter:background z:0];
//	showNode(self);
}

-(void)onExit{
	[super onExit];
}


-(void)showSelectArray{
	
	if ([self getChildByTag:4006]) {
		return ;
	}
	
	CCSprite* _sprite = [CCSprite spriteWithFile:@"images/ui/panel/filterBack.png"];
	CCLayer* layer=[CCLayer node];
	if (iPhoneRuningOnGame()) {
		_sprite.scale=1.6f;
		layer.contentSize=CGSizeMake(_sprite.contentSize.width*_sprite.scale,_sprite.contentSize.height*_sprite.scale);
		_sprite.position=ccp(layer.contentSize.width/2.0f,layer.contentSize.height/2.0f);
		[layer addChild:_sprite];
		layer.anchorPoint = ccp(0.5, 1.0);
		layer.position = ccp(0,-layer.contentSize.height );
	}else{
		_sprite.anchorPoint = ccp(0.5, 1.0);
		_sprite.position = ccp(self.contentSize.width/2, -1 );	
	}
	
	float startX = 0.0f;
	float startY =0.0f;
	if (iPhoneRuningOnGame()) {
		startY= layer.contentSize.height - 2;
		startX= layer.contentSize.width/2.0f;
	}else{
		startY= _sprite.contentSize.height -cFixedScale(2);
		startX= _sprite.contentSize.width/2;
	}
	for (int i = 1; i <= 6; i++) {
		SizerMumber* _sizer = [SizerMumber node];
		if (iPhoneRuningOnGame()) {
			[layer addChild:_sizer];
		}else{
			[_sprite addChild:_sizer];
		}
		_sizer.target = self;
		_sizer.call = @selector(updateBySizer:);
		_sizer.anchorPoint = ccp(0.5, 1.0);
		_sizer.type = i;
		_sizer.position = ccp(startX, startY);
		startY -= _sizer.contentSize.height;
	}
	if (iPhoneRuningOnGame()) {
		[self addChild:layer z:1 tag:4006];
	}else{
		[self addChild:_sprite z:1 tag:4006];
	}
	
}

-(void)updateBySizer:(NSNumber*)_sender{
	int _value = [_sender intValue];
	
	CCLOG(@"updateBySizer->%d",_value);
	
	[self removeChildByTag:4006 cleanup:YES];
	
	self.selectIndex = _value ;
}

-(void)setSelectIndex:(int)selectIndex{
	
	if (_selectIndex == selectIndex) {
		return ;
	}
	
	_selectIndex = selectIndex;
	
	if (_text == nil) {
		float fontSize=14;
		if (iPhoneRuningOnGame()) {
			fontSize=20/2.0f;
		}
		
		_text = [CCLabelTTF labelWithString:@""
								   fontName:@"Verdana-Bold"
								   fontSize:fontSize];
		
		_text.color = ccc3(200, 200, 200);
		_text.anchorPoint = ccp(0, 0.5);
		if (iPhoneRuningOnGame()) {
			_text.position = ccp(10, self.contentSize.height/2);
		}else{
			_text.position = ccp(5, self.contentSize.height/2);
		}
		[self addChild:_text z:5];
	}
	
	
	if (_selectIndex == 1){//全部
		//[_text setString:@"全 部"];
        [_text setString:NSLocalizedString(@"item_sizer_all",nil)];
	}
	if (_selectIndex == 2){//装备
		//[_text setString:@"装 备"];
        [_text setString:NSLocalizedString(@"item_sizer_equip",nil)];
	}
	if (_selectIndex == 3){//消耗品
		//[_text setString:@"消耗品"];
        [_text setString:NSLocalizedString(@"item_sizer_expendable",nil)];
	}
	if (_selectIndex == 4){//元神
		//[_text setString:@"元 神"];
        [_text setString:NSLocalizedString(@"item_sizer_fate",nil)];
	}
	if (_selectIndex == 5){//材料
		//[_text setString:@"材 料"];
        [_text setString:NSLocalizedString(@"item_sizer_material",nil)];
	}
	if (_selectIndex == 6){//材料
		//[_text setString:@"材 料"];
        [_text setString:NSLocalizedString(@"item_sizer_jewel",nil)];
	}
    
	if (_target != nil && _call != nil) {
		
		id	_targetTemp = _target ;
		SEL _callTemp = _call;
		
		_target = nil ;
		_call = nil ;
		
		[_targetTemp performSelector:_callTemp withObject:[NSNumber numberWithInt:_selectIndex]];
		
	}
	
}

-(void)finishDelay{
	_isDelay = NO ;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if ([self isTouchInSite:touch]) {
		return YES;
	}
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	if (_isDelay) {
		return ;
	}
	
	_isDelay = YES ;
	[self unschedule:@selector(finishDelay)];
	[self scheduleOnce:@selector(finishDelay) delay:0.5];
	
	if ([self isTouchInSite:touch]) {
		CCNode* __node = [self getChildByTag:4006];
		if (__node) {
			[__node removeFromParentAndCleanup:YES];
			__node = nil;
		}else{
			[self showSelectArray];
		}
	}
}

@end
