//
//  SocialityPanel.m
//  TXSFGame
//
//  Created by Soul on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "SocialityPanel.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "MessageBox.h"
#import "StretchingImg.h"
#import "ButtonGroup.h"
#import "SocialHelper.h"
#import "GameConnection.h"
#import "MessageAlert.h"

#define  SocialityTabHeight		cFixedScale(25)

static SocialityPanel *s_SocialityPanel = nil;
static CCLabelTTF *s_KeyLabel = nil;

// Tab
@interface SocialityTab : CCSprite

@end

@implementation SocialityTab

-(id)initWithName:(NSString *)name width:(float)width isSelected:(BOOL)isSelected
{
	if (self = [super init]) {
		self.contentSize = CGSizeMake(width, SocialityTabHeight);
		
		NSString *bgPath = [NSString stringWithFormat:@"images/ui/panel/t%d.png", isSelected ? 24 : 25];
		CCSprite *bg = [CCSprite spriteWithFile:bgPath];
		bg.scaleX = width / bg.contentSize.width;
		
		bg.anchorPoint = CGPointZero;
		[self addChild:bg];
		
		int fontSize = 16;
		if (iPhoneRuningOnGame()) {
			fontSize = 7;
		}
		CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:fontSize];
		nameLabel.position = ccp(self.contentSize.width/2,
								 self.contentSize.height/2);
		nameLabel.color = isSelected ? ccc3(236, 228, 206) : ccc3(170, 155, 124);
		[self addChild:nameLabel];
	}
	return self;
}

@end

@implementation SocialityPanel

@synthesize justShowBoxType;


+(SocialityPanel *)shared
{
	return s_SocialityPanel;
}

-(id)init
{
	if (self = [super init]) {
		// 社交动作
		_friendAction = [SocialityAction node];
		_friendAction.type = Sociality_friend;
		_friendAction.visible = NO;
		[self addChild:_friendAction z:1000];
		
		_onlineAction = [SocialityAction node];
		_onlineAction.type = Sociality_online;
		_onlineAction.visible = NO;
		[self addChild:_onlineAction z:1000];
		
		_blacklistAction = [SocialityAction node];
		_blacklistAction.type = Sociality_blacklist;
		_blacklistAction.visible = NO;
		[self addChild:_blacklistAction z:1000];
	}
	return self;
}

-(void)dealloc
{
	if (_friendAction) {
		[_friendAction removeFromParentAndCleanup:YES];
		_friendAction = nil;
	}
	if (_onlineAction) {
		[_onlineAction removeFromParentAndCleanup:YES];
		_onlineAction = nil;
	}
	if (_blacklistAction) {
		[_blacklistAction removeFromParentAndCleanup:YES];
		_blacklistAction = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	s_SocialityPanel = self;
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	if(justShowBoxType){
		return;
	}
	
	CCSprite *roleBg = nil;
    if (iPhoneRuningOnGame()) {
		roleBg = [CCSprite node];
        roleBg.position = ccp(30/2, 496/2);
    } else {
		roleBg = [CCSprite spriteWithFile:@"images/ui/panel/t68.png"];
        roleBg.position = ccp(26, 452);
	}
	roleBg.anchorPoint = CGPointZero;
	[self addChild:roleBg];
	
	// 添加角色信息
	int mainId = [[GameConfigure shared] getPlayerRole];

	CCSprite * roleIcon = getCharacterIcon(mainId,ICON_PLAYER_NORMAL);
	roleIcon.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		roleIcon.scale = 1.11;
	}
	[roleBg addChild:roleIcon];
	
	NSString *name = [[GameConfigure shared] getPlayerName];
	CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:18];
	nameLabel.color = ccc3(5, 172, 238);
	nameLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        nameLabel.scale = 0.7;
        nameLabel.position = ccp(108/2, 45/2.0);
    }else {
        nameLabel.position = ccp(100, 42);
	}
	[roleBg addChild:nameLabel];
	
	MessageBox *box = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
    if (iPhoneRuningOnGame()) {
        box.contentSize = CGSizeMake(391/2, 372/2);
        box.position = ccp(26/2, 80/2);
		box.visible = NO;
    }else{
        box.contentSize = CGSizeMake(391, 372);
        box.position = ccp(26, 80);
	}
    [self addChild:box];
	
	CCSimpleButton *addButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_add_1.png"
														select:@"images/ui/button/bt_add_2.png"
														target:self
														  call:@selector(openAddFriendBox)];
	addButton.tag = 10123;
    if (iPhoneRuningOnGame()) {
        addButton.position = ccp(self.contentSize.width/2, 57/2);
		addButton.scale = 1.3;
    } else {
		addButton.position = ccp(self.contentSize.width/2, 45);
	}
	[self addChild:addButton];
	
	// Tab按钮
	float friendWidth = 47;
	float onlineWidth = 73;
	float blacklistWidth = 57;
	if (iPhoneRuningOnGame()) {
		friendWidth = 70;
		onlineWidth = 70;
		blacklistWidth = 70;
	}
	NSMutableArray *tabArray = [NSMutableArray array];
//	[tabArray addObject:[NSArray arrayWithObjects:
//						 [NSNumber numberWithInt:Sociality_friend],
//						 @"好友",
//						 [NSNumber numberWithFloat:friendWidth], nil]];
//	[tabArray addObject:[NSArray arrayWithObjects:
//						 [NSNumber numberWithInt:Sociality_online],
//						 @"在线玩家",
//						 [NSNumber numberWithFloat:onlineWidth], nil]];
//	[tabArray addObject:[NSArray arrayWithObjects:
//						 [NSNumber numberWithInt:Sociality_blacklist],
//						 @"黑名单",
//						 [NSNumber numberWithFloat:blacklistWidth], nil]];
    [tabArray addObject:[NSArray arrayWithObjects:
						 [NSNumber numberWithInt:Sociality_friend],
						 NSLocalizedString(@"sociality_friend",nil),
						 [NSNumber numberWithFloat:friendWidth], nil]];
	[tabArray addObject:[NSArray arrayWithObjects:
						 [NSNumber numberWithInt:Sociality_online],
						 NSLocalizedString(@"sociality_online",nil),
						 [NSNumber numberWithFloat:onlineWidth], nil]];
	[tabArray addObject:[NSArray arrayWithObjects:
						 [NSNumber numberWithInt:Sociality_blacklist],
						 NSLocalizedString(@"sociality_blacklist",nil),
						 [NSNumber numberWithFloat:blacklistWidth], nil]];
	
	ButtonGroup *buttonGroup = [ButtonGroup node];
	[buttonGroup setTouchPriority:-60];
    if (iPhoneRuningOnGame()) {
		buttonGroup.position = ccp(144/2, -21/2.0);
		
		CCSprite *line = [CCSprite spriteWithFile:@"images/ui/panel/t72.png"];
		line.anchorPoint = CGPointZero;
		line.position = ccp(30/2.0, 457/2.0);
		line.scale = 0.8;
		[self addChild:line];
    } else {
		buttonGroup.position = ccp(298, 12.5);
	}
	
	BOOL first = YES;
	for (NSArray *array in tabArray) {
		NSString *name = [array objectAtIndex:1];
		float width = cFixedScale( [[array objectAtIndex:2] floatValue]);
		SocialityTab *normalTab = [[[SocialityTab alloc] initWithName:name
																width:width
														   isSelected:NO]
								   autorelease];
		SocialityTab *selectedTab = [[[SocialityTab alloc] initWithName:name
																  width:width
															 isSelected:YES]
									 autorelease];
		CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:normalTab
															 selectedSprite:selectedTab
																	 target:self
																   selector:@selector(doSelected:)];
		menuItem.tag = [[array objectAtIndex:0] intValue];

        if (iPhoneRuningOnGame()) {
            menuItem.scale = 1.3;
        }
		[buttonGroup addChild:menuItem];
		if (first) {
			[buttonGroup setSelectedItem:menuItem];
			first = NO;
		}
	}
	
	[buttonGroup alignItemsHorizontallyWithPadding:cFixedScale(5)];
	[roleBg addChild:buttonGroup];
	
	// 添加SocialityManager
	manager = [SocialityManager shared];
    if (iPhoneRuningOnGame()) {
        manager.position = ccp(63/2.0, 118/2);
    }else
	manager.position = ccp(55, 92);
	[self addChild:manager z:100];
}

+(void)openAddTypeBox:(SocialityType)var :(CCNode*)par{
	SocialityPanel *so = [SocialityPanel node];
	so.windowType = PANEL_CHAT;
	so.justShowBoxType = var;
	[so setPosition:ccp(so.contentSize.width/2, so.contentSize.height/2)];
	[so openAddFriendBox];
	[par addChild:so];
}

-(void)openAddFriendBox
{
	// 请求好友数量
	[self didFriendCount];
}

-(void)didFriendCount
{
	int online = 0;
	int total = 0;
	if (manager.friendCanvas) {
		online = manager.friendCanvas.onlineCount;
		total = manager.friendCanvas.totalCount;
	}

	// 添加好友提示框
	//NSString *friend = [NSString stringWithFormat:@"当前好友数量:%d/%d", online, total];
    NSString *friend =nil;
	
	switch (justShowBoxType) {
		case 0:
			friend=[NSString stringWithFormat:NSLocalizedString(@"sociality_friend_count",nil), online, total];
			break;
		case 1:
			friend=[NSString stringWithFormat:NSLocalizedString(@"sociality_add_friend",nil)];
			break;
		case 3:
			friend=[NSString stringWithFormat:NSLocalizedString(@"sociality_add_blacklist",nil)];
			break;
		default:
			break;
	}
	
	GameAlert *alert = [[AlertManager shared] showMessage:friend target:self confirm:@selector(doAddFriend) canel:@selector(doCancelFriend) father:nil];
	
	CCSprite *inputBg = [CCSprite spriteWithFile:@"images/ui/panel/p19.png"];
	inputBg.position = ccp(alert.contentSize.width/2, cFixedScale(160));
	[alert addChild:inputBg];
	
	CGSize inputSize = CGSizeMake(cFixedScale(232), cFixedScale(38));
	CCSimpleButton *inputButton = [CCSimpleButton spriteWithFile:@"images/btn-tmp.png"
														  select:@"images/btn-tmp.png"
														  target:self
															call:@selector(doShowInput)];
	inputButton.scaleX = inputSize.width / inputButton.contentSize.width;
	inputButton.scaleY = inputSize.height / inputButton.contentSize.height;
	inputButton.position = inputBg.position;
	inputButton.priority = INT32_MIN;
	[alert addChild:inputButton z:-1];
	
	CCLabelTTF *keyLabel = [CCLabelFX labelWithString:@""
							   dimensions:CGSizeMake(0,0)
								alignment:kCCTextAlignmentCenter
								 fontName:GAME_DEF_CHINESE_FONT
								 fontSize:18
							 shadowOffset:CGSizeMake(-1.5, -1.5)
							   shadowBlur:2.0f];
	keyLabel.anchorPoint = ccp(0, 0.5);
	keyLabel.position = ccp(cFixedScale(168), cFixedScale(160));
	[alert addChild:keyLabel];
	
	s_KeyLabel = keyLabel;
}

#pragma mark 键盘相关

-(void)doShowInput
{
	if (keyInput) {
		return;
	}
    if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			keyInput = [[UITextField alloc] initWithFrame:CGRectMake(cFixedScale(459), cFixedScale(182),cFixedScale( 218), cFixedScale(29))];
		} else {
			keyInput = [[UITextField alloc] initWithFrame:CGRectMake(cFixedScale(371), cFixedScale(182),cFixedScale( 218), cFixedScale(29))];
			
		}
    }else{
		keyInput = [[UITextField alloc] initWithFrame:CGRectMake(cFixedScale(404), cFixedScale(247),cFixedScale( 218), cFixedScale(29))];
	}
	
	[keyInput setHidden:YES];
	[keyInput setBorderStyle:UITextBorderStyleRoundedRect];
	[keyInput setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:iPhoneRuningOnGame()?cFixedScale(16):cFixedScale(16)]];
	
	keyInput.delegate = self;
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:keyInput];
	[keyInput becomeFirstResponder];
	[keyInput setHidden:NO];
}

-(void)removeInputField
{
	if (keyInput) {
		[keyInput resignFirstResponder];
		[keyInput removeFromSuperview];
		[keyInput release];
		keyInput = nil;
	}
}

-(void)editKeyEnd:(UITextField *)textField
{
	[self removeInputField];
	
	if (s_KeyLabel) {
		s_KeyLabel.string = textField.text;
	}
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	if(isEmo(string)){
		return NO;
	}
	
	return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (s_KeyLabel) {
		s_KeyLabel.string = textField.text;
	}
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self editKeyEnd:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[keyInput resignFirstResponder];
    return YES;
}

#pragma mark 键盘相关 end

-(void)doCancelFriend
{
	[self removeInputField];
	
	if(justShowBoxType){
		[self removeFromParent];
	}
}

-(void)doAddFriend
{
	[self removeInputField];
	
	if (s_KeyLabel == nil || [s_KeyLabel.string isEqualToString:@""]) {
		return;
	}
	
	NSString *name = s_KeyLabel.string;
	
	SocialHelper_action act=justShowBoxType==Sociality_blacklist?SocialHelper_addBlack:SocialHelper_addFriend;
	
	[[SocialHelper shared] socialActionWithName:name action:act];
	
	if(justShowBoxType){
		[self removeFromParent];
	}
}

-(void)doSelected:(id)sender
{
	CCMenuItem *menuItem = sender;
	int tag = menuItem.tag;
	if (tag == currentType) {
		return;
	}
	currentType = tag;
	manager.currentType = currentType;
	
	_friendAction.visible = NO;
	_onlineAction.visible = NO;
	_blacklistAction.visible = NO;
	
	SocialHelper_relation action = Sociality_none;
	
	CCNode *addButton = [self getChildByTag:10123];
	if (addButton) {
		BOOL isShowAdd = !(tag == 3);	// tag==3，点击了黑名单tab
		addButton.visible = isShowAdd;
	}
	
	if (tag == 1) {
		[[SocialityManager shared] setCanvasWithType:Sociality_friend];
		action = SocialHelper_relation_friend;
		_currentAction = _friendAction;
	} else if (tag == 2) {
		[[SocialityManager shared] setCanvasWithType:Sociality_online];
		action = SocialHelper_relation_stranger;
		_currentAction = _onlineAction;
	} else if (tag == 3) {
		[[SocialityManager shared] setCanvasWithType:Sociality_blacklist];
		action = SocialHelper_relation_enemy;
		_currentAction = _blacklistAction;
	}
	[[SocialHelper shared] socialRelationmembers:action];
}

-(void)setAction:(CGPoint)point playerId:(int)pid name:(NSString *)name
{
	if (_currentAction) {
		_currentAction.position = ccpAdd(point, ccp(0, SocialityActionTop+SocialityActionSize.height-_currentAction.contentSize.height));
		_currentAction.pid = pid;
		_currentAction.name = name;
		_currentAction.visible = YES;
	}
}

-(BOOL)checkTouchAction:(CGPoint)point
{
	if (_currentAction && _currentAction.visible) {
		
		if (!CGRectContainsPoint(_currentAction.boundingBox, point)) {
			[manager removeCurrentSelected];
			_currentAction.visible = NO;
		} else {
			return YES;
		}
	}
	return NO;
}

-(void)hideAction
{
	if (_currentAction.visible) {
		_currentAction.visible = NO;
	}
}

-(void)onExit
{
	s_SocialityPanel = nil;
	s_KeyLabel = nil;
	
	if (manager) {
		[manager removeFromParentAndCleanup:YES];
		manager = nil;
	}
	
	[self removeInputField];
	
	[super onExit];
}

@end
