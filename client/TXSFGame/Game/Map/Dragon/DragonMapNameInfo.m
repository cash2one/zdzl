//
//  DragonMapNameInfo.m
//  TXSFGame
//
//  Created by efun on 13-10-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonMapNameInfo.h"
#import "DragonReadyData.h"
#import "DragonReadyManager.h"
#import "Config.h"
#import "Arena.h"
#import "GameStart.h"
#import "GameConnection.h"
#import "CCSimpleButton.h"
#import "InfoAlert.h"

#define Offset_back		CGSizeMake(cFixedScale(13.0f), cFixedScale(1.0f))

@implementation DragonMapNameInfo

@synthesize dragonType = _dragonType;
@synthesize dragonTime = _dragonTime;

+(DragonMapNameInfo*)create:(DragonType)_type time:(DragonTime)_time
{
	DragonMapNameInfo *dragonMapNameInfo = [DragonMapNameInfo node];
	dragonMapNameInfo.dragonType = _type;
	dragonMapNameInfo.dragonTime = _time;
	
	return dragonMapNameInfo;
}

-(void)onEnter
{
	[super onEnter];
	
	// 准备房间，显示返回
	if (_dragonTime == DragonTime_ready) {
		
		CCSimpleButton *backButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_back.png"
															 select:@"images/ui/button/bt_back.png"
															 target:self
															   call:@selector(exitTapped)];
		backButton.anchorPoint = CGPointZero;
		[self addChild:backButton];
		
		self.contentSize = CGSizeMake(backButton.contentSize.width+Offset_back.width,
									  backButton.contentSize.height+Offset_back.height);
        //
        RuleButton *bt2 = [RuleButton node];
        if (iPhoneRuningOnGame()) {
            bt2.scale = 1.19;
        }
        bt2.position = ccpAdd(backButton.position, ccp(-backButton.contentSize.width/2-bt2.contentSize.width/2,+cFixedScale(15)));
        bt2.priority = -129;
        bt2.ruleModel = RuleModelType_help;
        if ( DragonType_fly == _dragonType) {
            bt2.type = RuleType_dragon_fly;
        }else if(DragonType_cometo == _dragonType){
            bt2.type = RuleType_dragon_cometo;
        }
		[self addChild:bt2];
	}
	// 战斗房间，显示地图名字
	else {
		
		CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_map_name.png"];
		bg.anchorPoint = CGPointZero;
		[self addChild:bg];
		
		self.contentSize = bg.contentSize;
		
		NSString *readyName = (_dragonType == DragonType_fly) ?
								NSLocalizedString(@"dragon_fly_name",nil) :
								NSLocalizedString(@"dragon_cometo_name",nil);
		
		float fontSize = 20;
		if (iPhoneRuningOnGame()) {
			fontSize = 10;
		}
		CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:readyName
												   fontName:getCommonFontName(FONT_1)
												   fontSize:fontSize];
		nameLabel.anchorPoint = ccp(1, 0.5);
		nameLabel.position = ccp(self.contentSize.width-cFixedScale(21.0f), cFixedScale(31.0f));
		nameLabel.color = ccc3(235, 180, 70);
		
		[bg addChild:nameLabel];
	}
}

-(void)onExit
{
	[super onExit];
}

-(void)exitTapped
{
    if(!self.visible || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] || [GameStart isOpen] ){
		return;
	}
	// 已经点击了开始的时候，点击退出无效
	if ([DragonReadyData checkIsStart]) return;
	
	CCLOG(@"你点击了 退出狩龙战");
	if (_dragonTime == DragonTime_ready) {
		[GameConnection request:@"awarExitRoom" data:[NSDictionary dictionary] target:[DragonReadyManager class] call:@selector(quitDragonReady)];
	}
}

@end
