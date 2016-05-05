//
//  CCSimpleButton.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

//
//update by: soul
//

#import "CCSimpleButton.h"
#import "CCLabelFX.h"

@implementation CCSimpleButton

@synthesize target;
@synthesize call;
@synthesize isEnabled = isEnabled_;
@synthesize touchScale;
@synthesize priority;
@synthesize delayTime;
@synthesize swallows;
@synthesize selected;
-(id)init{
	if(self=[super init]){
		touchScale = 1.2;
		//原来是-2
		priority = -2;
		delayTime = 0.5f;
		swallows=YES;
	}
	return self;
}

-(void)dealloc{
	CCLOG(@"CCSimpleButton->dealloc");
	if (_block) {
		[_block release];
		_block = nil ;
	}
	[super dealloc];
}

+(CCSimpleButton*)spriteWithSize:(CGSize)_rect block:(void(^)(void))_block {
	CCSimpleButton *bts=[CCSimpleButton node];
	CCSprite *spr=[CCSprite node];
	bts.contentSize=_rect;
	[bts setNormalSprite:spr];
	[bts setBlock:_block];
	return bts;
}

+(CCSimpleButton*)spriteWithFile:(NSString *)_normal{
	CCSimpleButton *bts = [CCSimpleButton node];
	CCSprite *spr = [CCSprite spriteWithFile:_normal];
	bts.contentSize = spr.contentSize;
	[bts setNormalSprite:spr];
	return bts;
}

+(CCSimpleButton*)spriteWithNode:(CCNode*)_normal{
	CCSimpleButton *bts = [CCSimpleButton node];
	CCSprite *spr = (CCSprite*)_normal;
	bts.contentSize = spr.contentSize;
	[bts setNormalSprite:spr];
	return bts;
}


+(CCSimpleButton*)spriteWithFile:(NSString *)_normal select:(NSString *)_select{
	CCSimpleButton *bts = [CCSimpleButton spriteWithFile:_normal];
	if (_select != nil) {
		CCSprite *spr = [CCSprite spriteWithFile:_select];
		[bts setSelectSprite:spr];
	}
	return bts;
}
+(CCSimpleButton*)spriteWithFile:(NSString *)_normal select:(NSString *)_select target:(id)_target call:(SEL)_call{
	CCSimpleButton *bts = [CCSimpleButton spriteWithFile:_normal select:_select];
	bts.target= _target;
	bts.call=_call;
	return bts;
}

+(CCSimpleButton*)spriteWithFile:(NSString*)_normal select:(NSString*)_select invalid:(NSString*)_invalid target:(id)_target call:(SEL)_call{
	CCSimpleButton *bts = [CCSimpleButton spriteWithFile:_normal select:_select];
	CCSprite *invalid=[CCSprite spriteWithFile:_invalid];
	bts.target=_target;
	bts.call=_call;
	[bts setInvalidSprite:invalid];
	return bts;
	
	
}

+(CCSimpleButton*)spriteWithSpriteFrameName:(NSString*)_normal{
	CCSimpleButton *bts = [CCSimpleButton node];
	CCSprite *spr = [CCSprite spriteWithSpriteFrameName:_normal];
	bts.contentSize = spr.contentSize;
	[bts setNormalSprite:spr];
	return bts;
}

+(CCSimpleButton*)spriteWithFile:(NSString *)_normal select:(NSString *)_select target:(id)_target call:(SEL)_call priority:(int)_priority{
	CCSimpleButton *bts = [CCSimpleButton spriteWithFile:_normal select:_select];
	bts.target= _target;
	bts.call=_call;
	bts.priority=_priority;
	return bts;
}

-(void)onEnter{
	[super onEnter];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:priority swallowsTouches:swallows];
	self.isEnabled=YES;
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}


-(void)setNormalSprite:(CCSprite *)_sprite{
	if (normal) {
		[normal removeFromParentAndCleanup:YES];
		normal = nil;
	}
	normal = _sprite;
	[self addChild:normal];
	normal.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
}
-(void)setSelectSprite:(CCSprite *)_sprite{
	if (select) {
		[select removeFromParentAndCleanup:YES];
		select = nil;
	}
	select = _sprite;
	[self addChild:select];
	select.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	select.visible=NO;
}
-(void)setInvalidSprite:(CCSprite*)_sprite{
	if(invalid){
		[invalid removeFromParentAndCleanup:true];
		invalid=nil;
	}
	invalid=_sprite;
	[self addChild:invalid];
	invalid.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	invalid.visible=NO;
}

-(void)setInvalid:(bool)b{
	if(b && invalid){
		invalid.visible=YES;
		normal.visible=NO;
		self.isEnabled=NO;
	}
	if(!b){
		invalid.visible=NO;
		normal.visible=YES;
		self.isEnabled=YES;
	}
}

-(void)setSelected:(bool)b{
	if(normal && select){
		if(b){
			normal.visible=NO;
			select.visible=YES;
			selected=YES;
		}else{
			normal.visible=YES;
			select.visible=NO;
			selected=NO;
		}
	}
	
}

-(void)setBlock:(void(^)(void))block{
	if (_block) {
		[_block release];
		_block = nil ;
	}
	_block=[block copy];
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

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	for( CCNode *c = self.parent; c != nil; c = c.parent )
		if( c.visible == NO )
			return NO;
	
	if(self.visible && [self isTouchInSite:touch] && self.isEnabled){
		if (normal && !select) {
			normal.scale = touchScale;
		}else if (normal && select){
			normal.visible=NO;
			select.visible=YES;
		}else{
			self.scale=touchScale;
		}
		return YES;
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if(self.visible && [self isTouchInSite:touch] && self.isEnabled){
		if (normal && !select) {
			normal.scale = touchScale;
		}else if (normal && select){
			normal.visible=NO;
			select.visible=YES;
		}else{
			self.scale=touchScale;
		}
	}else{
		if (normal && !select) {
			normal.scale = 1;
		}else if (normal && select){
			normal.visible=YES;
			select.visible=NO;
		}else{
			self.scale=1;
		}
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if(self.visible && [self isTouchInSite:touch] && self.isEnabled){
		if (!bTouchDelay) {
			CCLOG(@"CCSimpleButton-ccTouchEnded!");
			bTouchDelay = YES ;
			[self unschedule:@selector(updateDelay)];
			[self scheduleOnce:@selector(updateDelay) delay:delayTime];
			if(_block!=nil){
				_block();
			}
			
			if(target!=nil && call!=nil){
				[target performSelector:call withObject:self];
			}
			
		}else{
			CCLOG(@"CCSimpleButton-ccTouchEnded-bTouchDelay");
		}
		[self removeSuggest];
		//[self hideCount];
	}
	if (normal && !select) {
		normal.scale = 1;
	}else if (normal && select){
		normal.visible=YES;
		select.visible=NO;
	}else{
		self.scale=1;
	}
	if (normal && select) {
		if(selected){
			normal.visible=NO;
			select.visible=YES;
		}else{
			normal.visible=YES;
			select.visible=NO;
		}
	}
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	if (normal && !select) {
		normal.scale = 1;
	}else if (normal && select){
		normal.visible=YES;
		select.visible=NO;
	}else{
		self.scale=1;
	}
}

-(void)updateDelay{
	bTouchDelay = NO ;
}

-(void)removeSuggest{
	CCSprite* spr = (CCSprite*)[self getChildByTag:-7898];
	if (spr) {
		[spr stopAllActions];
		[spr removeFromParentAndCleanup:YES];
		spr = nil;
	}
}

-(void)showSuggest{
	[self removeSuggest];
	
	id _up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 10)];
	id _dn = [_up reverse];
	id sequence = [CCSequence actions:_up,_dn,nil];
	id act = [CCRepeatForever actionWithAction:sequence];
	
	CCSprite* spr = [CCSprite spriteWithFile:@"images/ui/alert/tips.png"];
	if (spr) {
		[self addChild:spr z:2 tag:-7898];
		if (iPhoneRuningOnGame()) {
			spr.position=ccp(self.contentSize.width -10.0f, self.contentSize.height - 10.0f);
		}else{
			spr.position=ccp(self.contentSize.width - 20, self.contentSize.height - 20);
		}
		[spr runAction:act];
	}
}

-(void)showCount:(int)count{
	[self hideCount];
	if(count<=0) return;
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/common/tips-count.png"];
	
	bg.anchorPoint = ccp(0,0);
	bg.position = ccp(self.contentSize.width-bg.contentSize.width,
					  self.contentSize.height-bg.contentSize.height);
	
	[self addChild:bg z:100 tag:12301];
	
	CCLabelFX * label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",count]
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:@"STHeitiTC-Medium"
										  fontSize:18
									  shadowOffset:CGSizeMake(-1, -1)
										shadowBlur:2.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2);
	[bg addChild:label];
	
}

-(void)hideCount{
	[self removeChildByTag:12301 cleanup:YES];
}

@end
