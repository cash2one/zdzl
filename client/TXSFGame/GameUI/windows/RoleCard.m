//
//  RoleCard.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import "RoleCard.h"
#import "Config.h"

@implementation RoleCard
@synthesize type = _type;
@synthesize RoleID = _role_id;

+(RoleCard*)create:(CARD_TYPE)_type
{
	RoleCard *card = [RoleCard node];
	card.type = _type;
	return card;
}
-(id)init
{
	self = [super init];
	//暂时写死一个宽度
    float w=58;
    float h=95;
    //TODO Iphone上面间距太大 要修改 chenjunming
    if (iPhoneRuningOnGame()) {
        w=26+5;
        h/=2;
    }
	self.contentSize = CGSizeMake(h, w);
	return self;
}
-(void)onExit
{
	[super onExit];
}
-(void)updateIcon:(int)_roleid
{
	if (icon) {
		[icon removeFromParentAndCleanup:YES];
		icon = nil;
	}
	//NSString *path = [[GameConfigure shared] findCharacterIcon:_roleid];
	

	icon = getCharacterIcon(_roleid, ICON_PLAYER_NORMAL); //[CCSprite spriteWithFile:path];

	if (icon) {
		[self addChild:icon z:10];
		if (iPhoneRuningOnGame()) {
			icon.scaleX=1.15f;
		}
		icon.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}
-(void)initFormID:(int)_rid
{
	self.RoleID = _rid;
	[self updateIcon:self.RoleID];
}
-(void)onEnter
{
	[super onEnter];
	if (iPhoneRuningOnGame()) {
		bg1 = [CCSprite spriteWithFile:@"images/ui/wback/t26.png"];
		bg2 = [CCSprite spriteWithFile:@"images/ui/wback/t27.png"];		
	}else{
		bg1 = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
		bg2 = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
	}
	bg1.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	bg2.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	[self addChild:bg1];
	[self addChild:bg2];
}
-(void)draw
{
	[super draw];
	
	if (isSelected_) {
		if (bg1) {
			[bg1 setVisible:NO];
		}
		if (bg2) {
			[bg2 setVisible:YES];
		}
	}
	else {
		if (bg1) {
			[bg1 setVisible:YES];
		}
		if (bg2) {
			[bg2 setVisible:NO];
		}
	}
}
@end
