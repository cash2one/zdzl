//
//  UnlockAlert.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-3.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnlockAlert.h"
#import "Config.h"
#import "GameAlert.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "GameUI.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "GameConfigure.h"
#import "Window.h"
#import "RoleThumbViewerContent.h"

static UnlockAlert *s_UnlockAlert = nil;

@implementation UnlockAlert
@synthesize unlockId;
@synthesize info;

+(void)show:(NSDictionary *)_dict target:(id)_target call:(SEL)_call{
	int _unlockID = [[_dict objectForKey:@"unlockID"] intValue];
	NSString *_info = [_dict objectForKey:@"unlockInfo"];
	if (s_UnlockAlert){
		if (s_UnlockAlert.unlockId == _unlockID) {
			return ;
		}else{
			[UnlockAlert remove];
		}
	}
	//
	[[RoleManager shared].player stopMove];
	[[Window shared] removeAllWindows];
	//
	if (_dict) {
		s_UnlockAlert = [UnlockAlert node];
		s_UnlockAlert.target = _target;
		s_UnlockAlert.call = _call;
		s_UnlockAlert.unlockId=_unlockID;
		s_UnlockAlert.info=_info;
		[s_UnlockAlert show];
		[s_UnlockAlert doActions];
	}
}

+(void)remove{
	if (s_UnlockAlert) {
		[s_UnlockAlert unscheduleAllSelectors];
		[s_UnlockAlert removeFromParentAndCleanup:YES];
		s_UnlockAlert = nil;
	}
}

+(BOOL)isUnlocking{
	return (s_UnlockAlert != nil);
}

+(UnlockAlert*)shared{
	return s_UnlockAlert;
}

-(void)onExit{
	if (info) {
		[info release];
		info = nil;
	}
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
}
-(void)onEnter{
	[super onEnter];
	//background
	//--------------------------------------------------------------------------------------
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:YES];
	
	CCSprite * background = [CCSprite spriteWithFile:@"images/ui/alert/unlock_bg.png"];
	self.contentSize = background.contentSize;
	[self addChild:background];
	
	background.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	
	if (unlockId != Unlock_partner) {
		
		NSString *tpath = [NSString stringWithFormat:@"images/ui/alert/taskAlert_%d.png",3];
		CCSprite *title =[CCSprite spriteWithFile:tpath];
		[background addChild:title];
		
		if(iPhoneRuningOnGame()){
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 10);
		}else{
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 20);
		}
		
		NSString *ipath = [NSString stringWithFormat:@"images/ui/alert/unlock/unlock%d.png",unlockId];
		CCSprite *icon =[CCSprite spriteWithFile:ipath];
		
		if (icon != nil) {
			[self addChild:icon z:1 tag:999];
			
			if(iPhoneRuningOnGame()){
				icon.position=ccp(self.contentSize.width/2, self.contentSize.height/2-10);
			}else{
				icon.position=ccp(self.contentSize.width/2, self.contentSize.height/2-20);
			}
		}
		
		if (info) {
			CCLabelFX * label = [CCLabelFX labelWithString:info
												dimensions:CGSizeMake(0,0)
												 alignment:kCCTextAlignmentCenter
												  fontName:GAME_DEF_CHINESE_FONT
												  fontSize:24
											  shadowOffset:CGSizeMake(0,0)
												shadowBlur:1.0f];
			label.anchorPoint = ccp(0.5,0.0);
			if(iPhoneRuningOnGame()){
				label.position = ccp(self.contentSize.width/2,10);
			}else{
				label.position = ccp(self.contentSize.width/2,20);
			}
			[self addChild:label z:2 tag:123];
		}
		
		[[GameUI shared] unfoldMainMenu];
		
	}else{
		NSString *tpath = [NSString stringWithFormat:@"images/ui/alert/taskAlert_%d.png",4];
		CCSprite *title =[CCSprite spriteWithFile:tpath];
		[background addChild:title];
		if(iPhoneRuningOnGame()){
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 10);
		}else{
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 20);
		}
		
		if (info && info.length > 0) {
			
			int rid = [info intValue];
			CCSprite *icon = [self getPartner:rid];
			
			if (icon != nil) {
				[self addChild:icon z:1 tag:999];
				if(iPhoneRuningOnGame()){
					icon.position=ccp(self.contentSize.width/2, self.contentSize.height/2-10);
				}else{
					icon.position=ccp(self.contentSize.width/2, self.contentSize.height/2-20);
				}
			}
		}
	}
}
-(CCSprite*)getPartner:(int)_rid{
	if (_rid > 0) {
		NSDictionary *role = [[GameDB shared] getRoleInfo:_rid];
		if (role) {
			NSString *name = [role objectForKey:@"name"];
			int quality = [[role objectForKey:@"quality"] intValue];
			CCSprite *bg = [getRecruitBackground(quality) objectAtIndex:0];
			
			//CCSprite *head = getRecruitIcon(_rid);
			CCSprite * head = [RoleThumbViewerContent create:_rid];
			
			head.anchorPoint=ccp(0.5, 0);
			[bg addChild:head];
			head.position=ccp(bg.contentSize.width/2, 0);
			
			NSString *office = [role objectForKey:@"office"];
			CCSprite *officeIcon = getOfficeIcon(office);
			[bg addChild:officeIcon];
			officeIcon.anchorPoint = ccp(0.5, 1);
			
			if(iPhoneRuningOnGame()){
				officeIcon.position = ccp(15/2, 144/2);
			}else{
				officeIcon.position = ccp(15, 144);
			}
			
			
			CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:11];
			nameLabel.color = ccc3(47, 19, 8);
			
			if(iPhoneRuningOnGame()){
				nameLabel.position = ccp(bg.contentSize.width / 2, 156/2);
			}else{
				nameLabel.position = ccp(bg.contentSize.width / 2, 156);
			}
			
			[bg addChild:nameLabel];
			
			CCSprite *join = [CCSprite spriteWithFile:@"images/ui/alert/zhaomu.png"];
			[bg addChild:join z:2];
			join.anchorPoint=ccp(1, 0);
			
			if(iPhoneRuningOnGame()){
				join.position=ccp(head.contentSize.width + 6, -6);
			}else{
				join.position=ccp(head.contentSize.width + 12, -12);
			}
			
			return bg;
		}
	}
	return nil;
}

-(void)updateDelay{
	_isCanTouch = YES ;
}

-(void)doActions{
	[self unschedule:@selector(updateDelay)];
	[self scheduleOnce:@selector(updateDelay) delay:3];
	/*
	id act1 = [CCDelayTime actionWithDuration:3];
	id act2 = [CCCallFunc actionWithTarget:self selector:@selector(unlockFuntion)];
	[self runAction:[CCSequence actions:act1,act2, nil]];
	 */
}
-(void)unlockFuntion{
	self.visible=NO;
	int value = filterMenuTag(unlockId);
	if (value > 0) {
//		if (![GameUI shared].isShowUI) {
//			[[GameUI shared] openUI];
//		}
        [[GameUI shared] unfoldMainMenu];
		[[GameUI shared] addMenuItem:value];
	}else{
		if (unlockId == Unlock_daily) {
			[[GameUI shared] unlockDaily];
		}else if (unlockId == Unlock_vice ||
				  unlockId == Unlock_offer ||
				  unlockId == Unlock_hide ){
			//新增任务提示
			[[GameUI shared] addTaskFunction];
		}else{
			//新增日常提示
			[[GameUI shared] addDailyFunction];
		}
	}
	[self scheduleOnce:@selector(doCallBack) delay:0.1];
}
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if (_isCanTouch && self.visible) {
		[self unlockFuntion];
		_isCanTouch = NO ;
		[self unschedule:@selector(updateDelay)];
		[self scheduleOnce:@selector(updateDelay) delay:3];
	}
}
-(void)doCallBack{
	//WHT?????? 解锁角色
	[self unlock];
	
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	
	target = nil;
	call = nil;
	
	[UnlockAlert remove];
}
-(void)unlock{
	if (unlockId > 0) {
		NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
		unsigned int _value = [[player objectForKey:@"funcs"] intValue];
		_value = updateFunction(_value, unlockId);
		[[GameConfigure shared] updatePlayerFuncs:_value];
	}
}
@end
