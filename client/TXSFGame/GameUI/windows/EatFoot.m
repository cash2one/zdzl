//
//  EatFoot.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EatFoot.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "Game.h"
#import "GameMoney.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "CCLabelFX.h"
#import "StretchingImg.h"
#import "GameDB.h"

#import "GameUI.h"
#import "GameLayer.h"

#import "GameLoading.h"

#import "TalkNpcViewerContent.h"
#import "TalkRoleViewerContent.h"

#define def_npc_id 14

static EatFoot * eatFoot;

@implementation EatFoot

+(void)show{
	[GameLoading showMessage:@"" target:[EatFoot class] call:@selector(showViewer) loading:YES];
}

+(void)showViewer{
	if(!eatFoot){
		eatFoot = [EatFoot node];
		[[Game shared] addChild:eatFoot z:INT32_MAX];
		[[GameUI shared] removeUI];
		[GameLayer shared].touchEnabled = NO;
	}
	[GameLoading hide];
}

+(void)hide{
	if(eatFoot){
		[[Game shared] removeChild:eatFoot cleanup:YES];
		eatFoot = nil;
		
		[[GameUI shared] displayUI];
		[GameLayer shared].touchEnabled = YES;
		
	}
}

-(void)onEnter{
	[super onEnter];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * bg1 = [CCSprite spriteWithFile:@"images/ui/foot/bg-1.png"];
	CCSprite * bg2 = [CCSprite spriteWithFile:@"images/ui/foot/bg-2.png"];
	bg1.anchorPoint = ccp(0,1);
	bg2.anchorPoint = ccp(0,0);
	
	bg1.position = ccp(0,winSize.height);
	bg2.position = ccp(0,0);
	
	[self addChild:bg1 z:1];
	[self addChild:bg2 z:3];
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	
	[self showPlayerCoin];
	
	int rid = [[player objectForKey:@"rid"] intValue];
	//NSString * path = [NSString stringWithFormat:@"images/talk/r/%d.png",rid];
	//CCSprite * role = [CCSprite spriteWithFile:path];
	CCSprite * role = [TalkRoleViewerContent create:rid];
	role.scaleX = -1;
	role.anchorPoint = ccp(1,0);
	role.position = ccp(0,270);
	[self addChild:role z:2];
	
	//role = [CCSprite spriteWithFile:@"images/talk/n/14.png"];
	role = [TalkNpcViewerContent create:def_npc_id];
	role.anchorPoint = ccp(1,0);
	role.position = ccp(winSize.width,270);
	[self addChild:role z:2];
	
	close_btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	close_btn.target = self;
	close_btn.call = @selector(doClose:);
	close_btn.position = ccp(winSize.width-30,winSize.height-30);
	[self addChild:close_btn z:100];
	
//	CCLabelFX * label = [CCLabelFX labelWithString:@"食馆规则"
//										dimensions:CGSizeMake(0,0)
//							alignment:kCCTextAlignmentCenter 
//										  fontName:GAME_DEF_CHINESE_FONT 
//										  fontSize:22 
//									  shadowOffset:CGSizeMake(-1.5, -1.5) 
//										shadowBlur:1.0f];
    CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"eatfood_rule",nil)
										dimensions:CGSizeMake(0,0)
                                         alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:22
									  shadowOffset:CGSizeMake(-1.5, -1.5)
										shadowBlur:1.0f];
    
	label.anchorPoint = ccp(0.0,0.0);
	
	info_btn = [CCSimpleButton node];
	info_btn.target = self;
	info_btn.call = @selector(doShowInfo:);
	info_btn.anchorPoint = ccp(0.5,0.5);
	info_btn.position = ccp(winSize.width-60,winSize.height-90);
	info_btn.contentSize = label.contentSize;
	[info_btn addChild:label];
	[self addChild:info_btn z:100];
	
	CCSprite * ticket = [CCSprite spriteWithFile:@"images/ui/foot/ticket.png"];
	ticket.anchorPoint = ccp(0,0);
	ticket.position = ccp(10,10);
	[self addChild:ticket z:100 tag:1002];
	
	CCLabelFX * ticketCount = [CCLabelFX labelWithString:@"0"
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentLeft 
										  fontName:GAME_DEF_CHINESE_FONT 
										  fontSize:28 
									  shadowOffset:CGSizeMake(-1.5, -1.5) 
										shadowBlur:1.0f];
	ticketCount.anchorPoint = ccp(0.0,0.0);
	ticketCount.position = ccp(100,52);
	[self addChild:ticketCount z:100 tag:1001];
	[self updateTicketCount];
	
	pay1 = [CCSimpleButton spriteWithFile:@"images/ui/foot/btn/pay1-1.png" 
								   select:@"images/ui/foot/btn/pay1-2.png"];
	pay2 = [CCSimpleButton spriteWithFile:@"images/ui/foot/btn/pay2-1.png" 
								   select:@"images/ui/foot/btn/pay2-2.png"];
	
	pay1.position = ccp(winSize.width/2-80,80);
	pay2.position = ccp(winSize.width/2+80,80);
	pay1.target = self;
	pay2.target = self;
	pay1.call = @selector(doPay:);
	pay2.call = @selector(doPay:);
	
	[self addChild:pay1 z:100 tag:3001];
	[self addChild:pay2 z:100 tag:3002];
	
	foot_select = [CCSprite spriteWithFile:@"images/ui/foot/f-select.png"];
	foot_start = [CCSprite spriteWithFile:@"images/ui/foot/f-start.png"];
	foot_full = [CCSprite spriteWithFile:@"images/ui/foot/f-full.png"];
	
	foot_select.position = ccp(winSize.width/2,winSize.height*0.68);
	foot_start.position = ccp(winSize.width/2,winSize.height*0.68);
	foot_full.position = ccp(winSize.width/2,winSize.height*0.68);
	
	[self addChild:foot_select z:100];
	[self addChild:foot_start z:100];
	[self addChild:foot_full z:100];
	
	foot_start.visible = NO;
	foot_full.visible = NO;
	
	foot_chopstick = [CCSprite spriteWithFile:@"images/ui/foot/f-chopstick.png"];
	foot_chopstick.position = ccp(winSize.width/2-260,winSize.height*0.2);
	foot_chopstick.visible = NO;
	[self addChild:foot_chopstick z:100];
	
	[self showFoots];
	
	timeCount = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentLeft 
								  fontName:GAME_DEF_CHINESE_FONT 
								  fontSize:26 
							  shadowOffset:CGSizeMake(-1.5, -1.5) 
								shadowBlur:1.0f];
	timeCount.anchorPoint = ccp(0.0,0.0);
	timeCount.position = ccp(10,winSize.height-100);
	[self addChild:timeCount z:100];
	
	bTime = 0;
	NSDictionary * buff = [[GameConfigure shared] getPlayerBuffByType:Buff_Type_foot];
	if(buff){
		int et = [[buff objectForKey:@"et"] intValue];
		bTime = et-[GameConfigure shared].time;
		[self checkTime:0];
		[self schedule:@selector(checkTime:) interval:1.0f];
	}
	//[GameConnection request:@"foodEnter" format:@"" target:self call:@selector(didFoodEnter:)];
	
}

-(void)checkTime:(ccTime)time{
	
	if(timeCount && bTime>0){
		
		/*
		int s = bTime%60;
		int m = bTime/60%60;
		int h = bTime/(60*60);
		
		timeCount.string = [NSString stringWithFormat:@"食物有效时间:%@%@%@",
						(h>0?[NSString stringWithFormat:@"%d小时",h]:@""),
						((h>0||m>0)?[NSString stringWithFormat:@"%d分",m]:@""),
						[NSString stringWithFormat:@"%@秒",
						 (s<10?[NSString stringWithFormat:@"0%d",s]:
						  [NSString stringWithFormat:@"%d",s])]];
		*/
		
		NSString * time = getTimeFormat(bTime);
		//timeCount.string = [NSString stringWithFormat:@"食物有效时间:%@",time];
        timeCount.string = [NSString stringWithFormat:NSLocalizedString(@"eatfood_time",nil),time];
		bTime--;
	}
	
}

-(void)onExit{
	if(foots){
		[foots release];
		foots = nil;
	}
    [GameConnection freeRequest:self];
	[super onExit];
	
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	
}

/*
-(void)didFoodEnter:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		bTime = [[data objectForKey:@"bTime"] intValue];
	}
}
*/

-(void)doClose:(CCNode*)sender{
	[EatFoot hide];
}

-(void)showPlayerCoin{
	
	[self removeChildByTag:201 cleanup:YES];
	[self removeChildByTag:202 cleanup:YES];
	[self removeChildByTag:203 cleanup:YES];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	
	GameMoney *yuanBao01 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE 
												  value:[[player objectForKey:@"coin2"] intValue]];
	yuanBao01.anchorPoint = ccp(0,0.5);
	yuanBao01.position = ccp(20,winSize.height-20);
	[self addChild:yuanBao01 z:100 tag:201];
	
	GameMoney *yuanBao02 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO 
												  value:[[player objectForKey:@"coin3"] intValue]];
	yuanBao02.anchorPoint = ccp(0,0.5);
	yuanBao02.position = ccp(120,winSize.height-20);
	[self addChild:yuanBao02 z:100 tag:202];
	
	GameMoney *yinBi = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI 
											  value:[[player objectForKey:@"coin1"] intValue]];
	yinBi.anchorPoint = ccp(0,0.5);
	yinBi.position = ccp(20,winSize.height-50);
	[self addChild:yinBi z:100 tag:203];
}

-(BOOL)removeInfo{
	if([self getChildByTag:123456]){
		[self removeChildByTag:123456 cleanup:YES];
		return YES;
	}
	return NO;
}
-(void)doShowInfo:(CCNode*)sender{
	
	if([self removeInfo]) return;
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CCSprite * background = [StretchingImg stretchingImg:@"images/ui/bound.png" 
												   width:300 
												  height:190
													capx:8 capy:8];
	background.position = ccp(winSize.width-10,winSize.height-110);
	background.anchorPoint = ccp(1,1);
	[self addChild:background z:INT16_MAX tag:123456];
	
	NSString * info = @"食馆规则食馆规则食馆规则食馆规则\n食馆规则\n食馆规则\n食馆规则\n食馆规则\n食馆规则\n";
	
	CCLabelFX * label = [CCLabelFX labelWithString:info
										dimensions:CGSizeMake(290,190)
										 alignment:kCCTextAlignmentLeft 
										  fontName:GAME_DEF_CHINESE_FONT 
										  fontSize:22 
									  shadowOffset:CGSizeMake(-1.5, -1.5) 
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.0,0.0);
	label.position = ccp(8,-8);
	[background addChild:label];
}

-(void)updateTicketCount{
	int count = [[GameConfigure shared] getPlayerItemCountByIid:10001];
	CCLabelFX * ticketCount = (CCLabelFX*)[self getChildByTag:1001];
	ticketCount.string = [NSString stringWithFormat:@"%d",count];
}

-(void)doPay:(CCNode*)sender{
	
	NSDictionary * foot = [foots objectAtIndex:selectIndex];
	if(sender==pay1){
		NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
		int coin2 = [[player objectForKey:@"coin2"] intValue];
		int coin3 = [[player objectForKey:@"coin3"] intValue];
		int total = coin2 + coin3;
		int c2 = [[foot objectForKey:@"coin2"] intValue];
		int c3 = [[foot objectForKey:@"coin3"] intValue];
		int c = (c2>c3?c2:c3);
		if(total<c){
			//TODO alert 
			return;
		}
	}
	if(sender==pay2){
		int t1 = [[GameConfigure shared] getPlayerItemCountByIid:10001];
		int t2 = [[foot objectForKey:@"cost"] intValue];
		if(t2>t1){
			//TODO alert 
			
			return;
		}
	}
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	[self unschedule:@selector(checkTime:)];
	
	pay1.visible = NO;
	pay2.visible = NO;
	info_btn.visible = NO;
	[self removeInfo];
	[self removeChildByTag:1001 cleanup:YES];
	[self removeChildByTag:1002 cleanup:YES];
	[self removeChild:footInfo cleanup:YES];
	[self removeChild:scrollLayer cleanup:YES];
	[self removeChild:timeCount cleanup:YES];
	timeCount = nil;
	
	foot_select.visible = NO;
	foot_chopstick.visible = YES;
	foot_start.visible = YES;
	
	close_btn.visible = NO;
	
	int fid = [[foot objectForKey:@"id"] intValue];
	t_foot = [CCSimpleButton spriteWithFile:
			  [NSString stringWithFormat:@"images/ui/foot/objs/%d/foot.png",fid]
			  ];
	t_foot.anchorPoint = ccp(0.5,0);
	t_foot.position = ccp(winSize.width/2,winSize.height*0.18);
	t_foot.touchScale = 1.0;
	[self addChild:t_foot z:1001];
	
	NSString * fm = [NSString stringWithFormat:@"id::%d|t::%d",fid,(sender==pay1?2:1)];
	[GameConnection request:@"foodEat" format:fm target:self call:@selector(didFootEat:)];
	
}

-(void)didFootEat:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		NSDictionary * data = getResponseData(response);
		[[GameConfigure shared] setPlayerBuff:[[data objectForKey:@"buff"] objectAtIndex:0] type:Buff_Type_foot];
		[[GameConfigure shared] updatePackage:data];
		
		touchCount = 0;
		foot_start.visible = NO;
		t_foot.target = self;
		t_foot.call = @selector(doTouchFoot:);
		
		canTouch = YES;
		
	}else{
		//TODO
		
	}
	   
}

-(void)doTouchFoot:(CCNode*)sender{
	
	if(!canTouch) return;
	canTouch = NO;
	
	NSDictionary * buff = [[GameConfigure shared] getPlayerBuffByType:Buff_Type_foot];
	NSArray * bs = [[buff objectForKey:@"buff"] componentsSeparatedByString:@"|"];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	if(touchCount<[bs count]){
		
		NSArray * ary = [[bs objectAtIndex:touchCount] componentsSeparatedByString:@":"];
		NSString * t = getPropertyName([ary objectAtIndex:0]);
		NSString * v = [ary objectAtIndex:1];
		if(!t){
			t = getPropertyName(fixBaseAttributeKey([ary objectAtIndex:0]));
			v = [v stringByAppendingString:@"%"];
		}
		
		CCLabelFX * label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%@ +%@",t,v]
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:GAME_DEF_CHINESE_FONT 
											  fontSize:30 
										  shadowOffset:CGSizeMake(-1.5, -1.5) 
											shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(winSize.width/2,winSize.height*0.5);
		label.tag = 7600+touchCount;
		[self addChild:label z:1100];
		
		id move = [CCMoveTo actionWithDuration:1.0 position:ccpAdd(label.position,ccp(0,200))];
		id call = [CCCallFunc actionWithTarget:self selector:@selector(removeHit)];
		[label runAction:[CCSequence actions:move, call, nil]];
		
		touchCount++;
	}
	if(touchCount>=[bs count]){
		
		[self removeChild:t_foot cleanup:YES];
		t_foot = nil;
		
		CCSprite * cup = [CCSprite spriteWithFile:@"images/ui/foot/f-cup.png"];
		cup.anchorPoint = ccp(0.5,0);
		cup.position = ccp(winSize.width/2,winSize.height*0.18);
		[self addChild:cup z:1000];
		
	}
}

-(void)removeHit{
	[self removeChildByTag:(7600+touchCount-1) cleanup:YES];
	
	NSDictionary * buff = [[GameConfigure shared] getPlayerBuffByType:Buff_Type_foot];
	NSArray * bs = [[buff objectForKey:@"buff"] componentsSeparatedByString:@"|"];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	if(touchCount>=[bs count]){
		
		foot_full.visible = YES;
		
		CCSimpleButton * quit = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_quit_1.png" 
														select:@"images/ui/button/bts_quit_2.png" 
								 ];
		quit.position = ccp(winSize.width/2,winSize.height*0.1);
		quit.target = self;
		quit.call = @selector(doClose:);
		[self addChild:quit z:100];
		
		int h = (60+[bs count]*25);
		CCSprite * background = [StretchingImg stretchingImg:@"images/ui/bound.png" 
													   width:200 
													  height:h
														capx:8 capy:8];
		background.position = ccp(winSize.width-10,50);
		background.anchorPoint = ccp(1,0);
		[self addChild:background z:INT16_MAX tag:123456];
		
//		CCLabelFX * label = [CCLabelFX labelWithString:@"食物属性"
//											dimensions:CGSizeMake(0,0)
//											 alignment:kCCTextAlignmentCenter
//											  fontName:GAME_DEF_CHINESE_FONT 
//											  fontSize:26
//										  shadowOffset:CGSizeMake(-1.5, -1.5) 
//											shadowBlur:1.0f];
        CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"eatfood_property",nil)
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:GAME_DEF_CHINESE_FONT
											  fontSize:26
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,1.0);
		label.position = ccp(100,h-10);
		[background addChild:label];
		
		for(int i=0;i<[bs count];i++){
			NSArray * ary = [[bs objectAtIndex:i] componentsSeparatedByString:@":"];
			NSString * t = getPropertyName([ary objectAtIndex:0]);
			NSString * v = [ary objectAtIndex:1];
			if(!t){
				t = getPropertyName(fixBaseAttributeKey([ary objectAtIndex:0]));
				v = [v stringByAppendingString:@"%"];
			}
			
			label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%@ +%@",t,v]
									dimensions:CGSizeMake(0,0)
									 alignment:kCCTextAlignmentLeft
									  fontName:GAME_DEF_CHINESE_FONT 
									  fontSize:24 
								  shadowOffset:CGSizeMake(-1.5, -1.5) 
									shadowBlur:1.0f];
			label.anchorPoint = ccp(0.0,1.0);
			label.position = ccp(10,h-15-(25*(i+1)));
			[background addChild:label];
			
		}
		
	}else{
		canTouch = YES;
	}
	
}

-(void)showFoots{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	NSMutableArray * layers = [NSMutableArray array];
	
	foots = [[GameDB shared] getFootBuffs];
	[foots retain];
	for(int i=0;i<[foots count];i++){
		NSDictionary * foot = [foots objectAtIndex:i];
		CCLayer * layer = [CCLayer node];
		int fid = [[foot objectForKey:@"id"] intValue];
		
		CCSprite * s_name = [CCSprite spriteWithFile:
							 [NSString stringWithFormat:@"images/ui/foot/objs/%d/name.png",fid]
							 ];
		CCSprite * s_foot = [CCSprite spriteWithFile:
							 [NSString stringWithFormat:@"images/ui/foot/objs/%d/foot.png",fid]
							 ];
		s_name.anchorPoint = ccp(0.5,0);
		s_foot.anchorPoint = ccp(0.5,0);
		s_name.position = ccp(winSize.width/2-s_foot.contentSize.width/2-s_name.contentSize.width/2-10,
							  winSize.height*0.33);
		s_foot.position = ccp(winSize.width/2,winSize.height*0.18);
		
		[layer addChild:s_foot];
		[layer addChild:s_name];
		[layers addObject:layer];
	}
	
	if([layers count]==0) return;
	
	scrollLayer = [CCScrollLayer nodeWithLayers:layers widthOffset:0];
	//buyLayer.marginOffset = 50;
	scrollLayer.delegate = self;
	scrollLayer.pagesIndicatorNormalColor = ccc4(255, 255, 255, 255);
	scrollLayer.pagesIndicatorSelectedColor = ccc4(178, 67, 0, 255);
	scrollLayer.pagesIndicatorPosition = ccp(winSize.width/2, 120);
	scrollLayer.contentSize = winSize;
	//scrollLayer.isInContent = YES;
	[scrollLayer updatePages];
	[self addChild:scrollLayer z:10];
	
	selectIndex = 0;
	[self showFootInfo];
}

-(void)showFootInfo{
	NSDictionary * foot = [foots objectAtIndex:selectIndex];
	
	if(footInfo){
		[self removeChild:footInfo cleanup:YES];
	}
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CCSprite * background = [StretchingImg stretchingImg:@"images/ui/bound.png" 
												   width:280 
												  height:180
													capx:8 capy:8];
	background.position = ccp(winSize.width-15,60);
	background.anchorPoint = ccp(1,0);
	[self addChild:background z:INT16_MAX];
	
	CCLabelFX * label = [CCLabelFX labelWithString:[foot objectForKey:@"name"]
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter 
										  fontName:GAME_DEF_CHINESE_FONT 
										  fontSize:26 
									  shadowOffset:CGSizeMake(-1.5, -1.5) 
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,1);
	label.position = ccp(280/2,170);
	[background addChild:label];
	
	label = [CCLabelFX labelWithString:[foot objectForKey:@"info"]
							dimensions:CGSizeMake(260,100)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT 
							  fontSize:20 
						  shadowOffset:CGSizeMake(-1.5, -1.5) 
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,1);
	label.position = ccp(280/2,140);
	[background addChild:label];
	
	int c2 = [[foot objectForKey:@"coin2"] intValue];
	int c3 = [[foot objectForKey:@"coin3"] intValue];
//	label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"元宝:%d",(c2>c3?c2:c3)]
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT 
//							  fontSize:20 
//						  shadowOffset:CGSizeMake(-1.5, -1.5) 
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:[NSString stringWithFormat:NSLocalizedString(@"eatfood_yuanbao",nil),(c2>c3?c2:c3)]
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,1);
	label.position = ccp(280/2-60,30);
	[background addChild:label];
	
//	label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"食卷:%@",[foot objectForKey:@"cost"]]
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT 
//							  fontSize:20 
//						  shadowOffset:CGSizeMake(-1.5, -1.5) 
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:[NSString stringWithFormat:NSLocalizedString(@"eatfood_roll",nil),[foot objectForKey:@"cost"]]
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,1);
	label.position = ccp(280/2+60,30);
	[background addChild:label];
	
	footInfo = background;
	
}

-(void)scrollLayer:(CCScrollLayer*)sender scrolledToPageNumber:(int)page{
	if(selectIndex==page) return;
	selectIndex = page;
	[self showFootInfo];
}

@end
