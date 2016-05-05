//
//  SocialityAction.m
//  TXSFGame
//
//  Created by Soul on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "SocialityAction.h"
#import "MessageBox.h"
#import "CCSimpleButton.h"
#import "SocialHelper.h"
#import "ChatPanelBase.h"

#define Sociality_messagebox	10001

@implementation SocialityAction

@synthesize type = _type;
@synthesize name;

-(NSArray *)getActionList
{
	NSMutableArray *_array = [NSMutableArray arrayWithObjects:
							  [NSNumber numberWithInt:Sociality_speak],
							  [NSNumber numberWithInt:Sociality_add_friend],
							  [NSNumber numberWithInt:Sociality_copy_name],
							  [NSNumber numberWithInt:Sociality_check_info],
							  [NSNumber numberWithInt:Sociality_black_list],
							  [NSNumber numberWithInt:Sociality_delete_friend],
							  [NSNumber numberWithInt:Sociality_delete_blacklist],
							  nil];
	switch (_type) {
		case Sociality_friend:
			[_array removeObject:[NSNumber numberWithInt:Sociality_add_friend]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_delete_blacklist]];
			break;
		case Sociality_online:
			[_array removeObject:[NSNumber numberWithInt:Sociality_delete_friend]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_delete_blacklist]];
			break;
		case Sociality_blacklist:
			[_array removeObject:[NSNumber numberWithInt:Sociality_speak]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_add_friend]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_copy_name]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_check_info]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_black_list]];
			[_array removeObject:[NSNumber numberWithInt:Sociality_delete_friend]];
			break;
			
		default:
			break;
	}
	return _array;
}

-(id)init
{
	if (self = [super init]) {
		_type = Sociality_friend;
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
	
	NSArray *actionList = [self getActionList];
	self.contentSize = CGSizeMake(SocialityActionSize.width+2, SocialityActionTop+SocialityActionBottom+actionList.count*SocialityActionSize.height+2);
	
	MessageBox *box = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	box.contentSize = self.contentSize;
	[self addChild:box z:0 tag:Sociality_messagebox];
	
	int fontSize = 14;
	if (iPhoneRuningOnGame()) {
		fontSize = 10;
	}
	int i = 1;
	for (NSNumber *num in actionList) {
		Sociality_action _act = [num intValue];
		CCSimpleButton *button = [CCSimpleButton node];
		button.anchorPoint = CGPointZero;
		button.tag = _act;
		button.contentSize = SocialityActionSize;
		button.position = ccp(1, self.contentSize.height-1-SocialityActionTop-SocialityActionSize.height*i);
		button.priority = -301;
		button.target = self;
		button.call = @selector(doAction:);
		[self addChild:button];
		
		CCSprite *normal = [CCSprite node];
		normal.contentSize = SocialityActionSize;
		CCLabelTTF *normalLabel = [CCLabelTTF labelWithString:actionToString(_act) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
		normalLabel.color = ccc3(238, 228, 207);
		normalLabel.position = ccp(SocialityActionSize.width/2,
								   SocialityActionSize.height/2);
		[normal addChild:normalLabel];
		
		CCSprite *selected = [CCSprite node];
		selected.contentSize = SocialityActionSize;
		CCLabelTTF *selectedLabel = [CCLabelTTF labelWithString:actionToString(_act) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
		selectedLabel.color = ccc3(238, 180, 70);
		selectedLabel.position = ccp(SocialityActionSize.width/2,
									 SocialityActionSize.height/2);
		[selected addChild:selectedLabel];
		CCSprite *selectedSprite = [CCSprite spriteWithFile:@"images/ui/panel/p15.png"];
		selectedSprite.position = ccp(SocialityActionSize.width/2,
									 SocialityActionSize.height/2);
		[selected addChild:selectedSprite];
        if (iPhoneRuningOnGame()) {			
			selectedSprite.scaleX = SocialityActionSize.width/selectedSprite.contentSize.width;
			selectedSprite.scaleY = SocialityActionSize.height/selectedSprite.contentSize.height;
        }
		
		[button setNormalSprite:normal];
		[button setSelectSprite:selected];
		
		i++;
	}
}

-(void)setVisible:(BOOL)__visible
{
	[super setVisible:__visible];
	
	for (CCNode *node in self.children) {
		if (node.tag == Sociality_messagebox) {
			continue;
		}
		node.visible = __visible;
	}
}

-(void)doAction:(id)sender
{
	CCNode *node = sender;
	int tag = node.tag;
	switch (tag) {
		case Sociality_speak:
			CCLOG(@"do action pid-%d : 私聊", self.pid);
			
			[ChatPanelBase sendPrivateChannle:self.name pid:self.pid];
			break;
		case Sociality_add_friend:
			[[SocialHelper shared] socialAction:self.pid action:SocialHelper_addFriend];
			break;
		case Sociality_copy_name:
		{
			[[UIPasteboard generalPasteboard] setPersistent:YES];
			[[UIPasteboard generalPasteboard] setValue:self.name forPasteboardType:[UIPasteboardTypeListString objectAtIndex:0]];
		}
			break;
		case Sociality_check_info:
			[[SocialHelper shared] socialGetInfo:self.pid name:self.name];
			break;
		case Sociality_black_list:
			[[SocialHelper shared] socialAction:self.pid action:SocialHelper_addBlack];
			break;
		case Sociality_delete_friend:
			[[SocialHelper shared] socialAction:self.pid action:SocialHelper_delFriend];
			break;
		case Sociality_delete_blacklist:
			[[SocialHelper shared] socialAction:self.pid action:SocialHelper_delBlack];
			break;
			
		default:
			break;
	}
	self.visible = NO;
}

-(void)onExit
{
	[super onExit];
}

@end
