//
//  RoleOption.m
//  TXSFGame
//
//  Created by Soul on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "RoleOption.h"
#import "GameLayer.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "Window.h"
#import "SocialHelper.h"
#import "OtherPlayerPanel.h"
#import "FightManager.h"
#import "ChatPanelBase.h"
#import "TaskManager.h"

#define Radius		cFixedScale(110)

static RoleOption* s_RoleOption = nil ;

@implementation RoleOption

@synthesize role = _role ;

+(RoleOption*)shared{
	
	if (s_RoleOption == nil) {
		s_RoleOption = [RoleOption node];
		[[GameLayer shared].content addChild:s_RoleOption z:INT16_MAX];
		s_RoleOption.visible = NO ;
	}
	
	return s_RoleOption;
}

+(void)stopAll{
	if (s_RoleOption != nil) {
		[s_RoleOption unscheduleAllSelectors];
		[s_RoleOption removeFromParentAndCleanup:YES];
		s_RoleOption = nil;
	}
}

-(void)binding:(RolePlayer *)_nRole{
	
	if (_role != nil) {
		_role.isSelected = NO ;
	}
	
	_role = nil ;
	
	if (_nRole == nil) {
		self.visible = NO;
		
		[self showExit];
		
		return;
	}
	
	if (!_nRole.isShow) return ;
	
	//#1496
	if ([[RoleManager shared].player isPrepareMoveEnd]) {
		CCLOG(@"PlayerOption->doLogic->player->isPrepareMoveEnd");
		return ;
	}
	
	
	//#1496
	//[[RoleManager shared].player stopMoveAndTask];
	
	_role = _nRole ;
	_role.isSelected = YES;
	self.visible = YES;
	
	[self showEnter];

}

-(void)updateBattleDelay{
	_battleDelay = NO ;
}

-(void)doLogic:(CCSimpleButton*)sender{
	
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	
	if (self.visible == NO) {
		return ;
	}
	
	if ([[RoleManager shared].player isPrepareMoveEnd]) {
		CCLOG(@"PlayerOption->doLogic->player->isPrepareMoveEnd");
		[self binding:nil];
		return ;
	}
	
	[[RoleManager shared].player stopMoveAndTask];
	
	if (sender.tag == 100) {
		CCLOG(@"battle");
		if (_battleDelay) {
			return ;
		}
		
		
		
		_battleDelay = YES ;
		
		
		
		int _pid = 0 ;
		if (_role != nil) {
			_pid =_role.player_id;
		}
		
		
		if (_pid > 0) {
			//TODO 测试  soul
			[[TaskManager shared] freeTaskStep];
			[[FightManager shared] startFightPlayerBySociality:_pid target:nil call:nil];
		}
		
		[self scheduleOnce:@selector(updateBattleDelay) delay:1.0f];
		
		
	}else if (sender.tag == 101){
		CCLOG(@"check");
		if (_role != nil) {
			
			int pid = _role.player_id;
			
			NSString* name = [NSString stringWithFormat:@"%@",_role.name];
			[[SocialHelper shared] socialGetInfo:pid name:name];
			
		}
	}else if (sender.tag == 102){
		CCLOG(@"talk");
		if (_role != nil) {
			
			int pid = _role.player_id;
			
			NSString* name = [NSString stringWithFormat:@"%@",_role.name];
			[ChatPanelBase sendPrivateChannle:name pid:pid];
			
		}
	}else if (sender.tag == 103){
		CCLOG(@"add friend");
		if (_role != nil) { 
			int pid = _role.player_id ;
			if (pid > 0) {
				[[SocialHelper shared] socialAction:pid action:SocialHelper_addFriend];
			}
		}
	}
	
	[self binding:nil];
	
}

-(void)onEnter{
	[super onEnter];
	
	NSString* path1 = nil;
	NSString* path2 = nil;
	NSString* path3 = nil;
	
	int __________tag = 100;
	
	float _fAngle = 3.1415926/5;
	float _r = 3.1415926 - (3.1415926 - _fAngle*3)/2;
	
	for (int i = 1; i <= 4; i++) {
		
		path1 = [NSString stringWithFormat:@"images/ui/sociality/a%d_1.png",i];
		path2 = [NSString stringWithFormat:@"images/ui/sociality/a%d_2.png",i];
		path3 = [NSString stringWithFormat:@"images/ui/sociality/a%d_3.png",i];
		
		CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:path1
													  select:path2
													 invalid:path3
													  target:self
														call:@selector(doLogic:)];
		bnt.priority = -57;
		bnt.delayTime = 1.0f;
		bnt.tag = __________tag;
		__________tag++;
		
		[self addChild:bnt z:1];
		
		float _x = cosf(_r)*Radius;
		float _y = sinf(_r)*Radius;
		
		_r -= _fAngle;
		
		bnt.position=ccp(_x, _y);
		
	}
	
}

-(void)onExit{
	_role = nil;
	s_RoleOption = nil;
	[super onExit];
}

-(void)setRole:(RolePlayer *)role{
	_role = role;
	
	if (_role != nil) {
		self.visible = YES ;
	}
	
}

-(void)setVisible:(BOOL)visible{
	[super setVisible:visible];
	
	/*
	if (visible) {
		
		if (_role != nil) {
			CGSize _size = [_role getRolePlayerSize];
			CGPoint pt = ccpAdd(_role.position, ccp(0, _size.height*3/4));
			self.position = pt ;
		}
		
		[self schedule:@selector(checkTimer:) interval:1/30.0f];
		[self showEnter];
		
	}else{
		
		[self unschedule:@selector(checkTimer:)];
		[self showExit];
		
	}
	*/
	
	for (int i = 100; i < 105; i++) {
		CCSimpleButton* bnt = (CCSimpleButton*)[self getChildByTag:i];
		if (bnt != nil) {
			bnt.visible = visible;
		}
	}
	
	
}

-(void)showEnter{
	
	[self schedule:@selector(checkTimer:) interval:1/30.0f];
	
	float _fAngle = 3.1415926/5;
	float _r = 3.1415926 - (3.1415926 - _fAngle*3)/2;
	
	for (int i = 100; i < 105; i++) {
		CCSimpleButton* bnt = (CCSimpleButton*)[self getChildByTag:i];
		if (bnt != nil) {
			
			bnt.position = ccp(0, 0);
			
			float _x = cosf(_r)*Radius;
			float _y = sinf(_r)*Radius;
			
			_r -= _fAngle;
			
			bnt.visible = YES;
            //
			[bnt stopAllActions];
            
			CCMoveTo* act1 = [CCMoveTo actionWithDuration:0.3 position:ccp(_x, _y)];
			id a1 = [CCEaseBackOut actionWithAction:act1];
			[bnt runAction:a1];
			
		}
	}
	CCLOG(@"role option show enter....");
}

-(void)showExit{
	
	[self unschedule:@selector(checkTimer:)];
	
	/*
	for (int i = 100; i < 105; i++) {
		CCSimpleButton* bnt = (CCSimpleButton*)[self getChildByTag:i];
		if (bnt != nil) {
			
			CCMoveTo* act1 = [CCMoveTo actionWithDuration:0.2 position:ccp(0, 0)];			
			[bnt runAction:act1];
			
		}
	}*/
}

-(void)checkTimer:(ccTime)time{
	
	if (!self.visible) {
		return ;
	}
	
	if (_role != nil) {
		
		CGSize _size = [_role getRolePlayerSize];
		CGPoint pt = ccpAdd(_role.position, ccp(0, _size.height*3/4));
		self.position = pt;
		
		self.visible = _role.visible;
		
	}else{
		[self binding:Nil];
	}
	
}

@end
