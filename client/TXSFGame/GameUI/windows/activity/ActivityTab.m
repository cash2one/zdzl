//
//  ActivityTab.m
//  TXSFGame
//
//  Created by Soul on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ActivityTab.h"
#import "Config.h"
#import "CCNode+AddHelper.h"

@implementation ActivityTab

@synthesize isSelected;
@synthesize call;
@synthesize target;

@synthesize activityId = _activityId;
@synthesize type = _type;

-(id)init{
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	spriteNormal = [CCSprite spriteWithFile:@"images/ui/panel/t54.png"];
	spriteSelect = [CCSprite spriteWithFile:@"images/ui/panel/t55.png"];
	
	CCSprite *icon = [CCSprite spriteWithFile:@"images/ui/panel/t56.png"];
	if (iPhoneRuningOnGame()) {
		icon.position = ccp(spriteSelect.contentSize.width+4, spriteSelect.contentSize.height/2);
	}else{
		icon.position = ccp(spriteSelect.contentSize.width + 10, spriteSelect.contentSize.height/2);
	}
	[spriteSelect addChild:icon z:0 tag:12345];
	if (iPhoneRuningOnGame()) {
		self.scale=1.15f;
		self.contentSize =CGSizeMake(spriteNormal.contentSize.width*self.scaleX,spriteNormal.contentSize.height*self.scaleY);
	}else{
		self.contentSize = spriteNormal.contentSize;
	}
	[self Category_AddChildToCenter:spriteNormal];
	[self Category_AddChildToCenter:spriteSelect];
	
	spriteNormal.visible =YES;
	spriteSelect.visible =YES;
	
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	if (name) {
		[name release];
		name = nil;
	}
	if (tips) {
		[tips release];
		tips = nil;
	}
	spriteNormal = nil ;
	spriteSelect = nil ;
	[super onExit];
}

-(void)setName:(NSString *)_name{
	if (name) {
		[name release];
		name = nil;
	}
	
	[spriteNormal removeChild:100 cleanup:YES];
	[spriteSelect removeChild:100 cleanup:YES];
	
	if (_name == nil) {
		return ;
	}
	
	name = _name;
	[name retain];
	
	if ([name length] == 0) {
		return ;
	}
	
	CCLabelTTF *txtName1 = [CCLabelTTF labelWithString:name
											  fontName:getCommonFontName(FONT_1)
											  fontSize:cFixedScale(20)];
	txtName1.color = ccc3(47, 19, 8);
	
	CCLabelTTF *txtName2 = [CCLabelTTF labelWithString:name
											  fontName:getCommonFontName(FONT_1)
											  fontSize:cFixedScale(20)];
	txtName2.color = ccc3(253, 243, 111);
	
	[spriteNormal addChild:txtName1 z:2 tag:100];
	[spriteSelect addChild:txtName2 z:2 tag:100];
	
	CCNode* n1 = [spriteNormal getChildByTag:101];
	CCNode* n2 = [spriteSelect getChildByTag:101];
	if (n1 != nil && n2 != nil) {
		float startY = self.contentSize.height/2;
		txtName1.position = txtName2.position = ccp(spriteSelect.contentSize.width/2,
													startY + txtName1.contentSize.height/2);
		
		n1.position = n2.position = ccp(spriteSelect.contentSize.width/2,
										startY - n2.contentSize.height/2);
	}else{
		txtName1.position = txtName2.position = ccp(spriteSelect.contentSize.width/2, self.contentSize.height/2);
	}
}
//这里最多12个汉字
-(void)setTips:(NSString *)_tips{
	if (tips) {
		[tips release];
		tips = nil;
	}
	
	[spriteNormal removeChild:101 cleanup:YES];
	[spriteSelect removeChild:101 cleanup:YES];
	
	if (_tips == nil) {
		return ;
	}
	
	tips = _tips;
	[tips retain];
	
	if ([tips length] == 0) {
		return ;
	}
	
	CCLabelTTF *txt1 = [CCLabelTTF labelWithString:tips
										  fontName:getCommonFontName(FONT_1)
										  fontSize:cFixedScale(14)];
	txt1.color = ccc3(237, 228, 207);
	
	CCLabelTTF *txt2 = [CCLabelTTF labelWithString:tips
										  fontName:getCommonFontName(FONT_1)
										  fontSize:cFixedScale(14)];
	txt2.color = ccc3(237, 228, 207);
	
	[spriteNormal addChild:txt1 z:2 tag:101];
	[spriteSelect addChild:txt2 z:2 tag:101];
	
	CCNode* n1 = [spriteNormal getChildByTag:100];
	CCNode* n2 = [spriteSelect getChildByTag:100];
	if (n1 != nil && n2 != nil) {
		float startY = self.contentSize.height/2;
		n1.position = n2.position = ccp(spriteSelect.contentSize.width/2,
										startY + n1.contentSize.height/2);
		
		txt1.position = txt2.position = ccp(spriteSelect.contentSize.width/2,
											startY - n2.contentSize.height/2);
	}else{
		txt1.position = txt2.position = ccp(spriteSelect.contentSize.width/2, self.contentSize.height/2);
	}
	
}

-(void)setIsSelected:(BOOL)_isSelected{
	isSelected = _isSelected;
	
	if (isSelected) {
		spriteNormal.visible = NO;
		spriteSelect.visible = YES;
	}else{
		spriteNormal.visible = YES;
		spriteSelect.visible = NO;
	}
	
	if (isSelected) {
		if (target != nil && call != nil) {
			//动作
			[target performSelector:call withObject:[NSNumber numberWithInt:self.activityId]];
		}
	}
}

-(BOOL)checkTouch:(UITouch *)touch{
	return [self isTouchInSite:touch];
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

@end

