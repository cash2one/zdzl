//
//  GameEffects.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-8.
//  Copyright (c) 2012 eGame. All rights reserved.
//`

#import "GameEffects.h"
#import "Game.h"
#import "GameLayer.h"
#import "GameUI.h"
#import "CCLabelFX.h"
#import "Window.h"
#import "GameDB.h"
#import "Config.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "GameNPC.h"
#import "NPCManager.h"
#import "CJSONDeserializer.h"
#import "RoleThumbViewerContent.h"
#import "Inbetweening.h"
#import "LowerLeftChat.h"

@implementation GameEffects

@synthesize targetEffectId;
@synthesize taskId;
@synthesize taskStep;
@synthesize otherMessage;

static GameEffects * gameEffects;

+(GameEffects*)share{
	if(!gameEffects){
		gameEffects = [[GameEffects alloc] init];
	}
	return gameEffects;
}
+(void)stopAll{
	[NSTimer cancelPreviousPerformRequestsWithTarget:[GameEffects class]];
	[[Intro share]showCurrenTips];
	[GameEffects remove];
}

+(BOOL)checkIsEffects{
	if (gameEffects != nil) {
		if (gameEffects.targetEffectId != EffectsAction_none) {
			
			CCLOG(@"checkIsEffects->(%d is doing!)",gameEffects.targetEffectId);
			return YES;
		}
	}
	return NO;
}

+(void)remove{
	if(gameEffects){
		[NSTimer cancelPreviousPerformRequestsWithTarget:gameEffects];
		[gameEffects release];
		gameEffects = nil;
	}
}
+(void)removeOtherEffect{
	CCNode * node = [[Game shared] getChildByTag:10091];
	if(node){
		[node removeFromParentAndCleanup:YES];
		[GameEffectsBlockTouck unlockScreen];
	}
}
+(BOOL)isShowEffect:(int)_tid taskStep:(int)_step{
	if (gameEffects != nil) {
		if (gameEffects.taskId == _tid && gameEffects.taskStep == _step) {
			CCLOG(@"showEffectsWithDict is double create 1");
			return YES;
		}
	}
	return NO;
}
-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if(otherMessage){
		[otherMessage release];
		otherMessage = nil;
	}
	[super dealloc];
}

//==============================================================================

-(void)showEffects{
	
	CCLOG(@"showEffect id: %d",targetEffectId);
	
	//[Window destroy];
	if (targetEffectId!=EffectsAction_loshingDirect) {
		[[Window shared] setVisible:NO];
	}
	[[Intro share] hideCurrenTips];
	[GameEffectsBlockTouck lockScreen];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	float time = 1.0f;
	
	/*
	if (targetEffectId == EffectsAction_hideUI) {
		targetEffectId = EffectsAction_showNpcEffect;
	}
	*/
	
	if(targetEffectId==EffectsAction_loshing){
		
		CGPoint p = [GameLayer shared].content.position;
		
		NSMutableArray * actions = [NSMutableArray array];
		for(int i=0;i<12;i++){
			int cut = (i%2==0?6:-6);
			if(iPhoneRuningOnGame()){
				cut = (i%2==0?3:-3);
			}
			id action = [CCMoveTo actionWithDuration:0.05f position:ccpAdd(p, ccp(cut,0))];
			time += 0.05f;
			[actions addObject:action];
		}
		
		id action = [CCMoveTo actionWithDuration:0.05f position:p];
		time += 0.1f;
		[actions addObject:action];
		
		[[GameLayer shared].content runAction:[CCSequence actionWithArray:actions]];
		
		/////////
		/*
		int cut = 10;
		CGPoint p = [GameLayer shared].content.position;
		if(p.x>-10) cut = -10;
		
		id m1 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m2 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m3 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m4 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m5 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m6 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m7 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m8 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m9 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m = [CCMoveTo actionWithDuration:0.1 position:p];
		
		[[GameLayer shared].content runAction:[CCSequence actions:m1,m2,m3,m4,m5,m6,m7,m8,m9,m,nil]];
		
		time = 1.2;
		*/
		
	}else if(targetEffectId==EffectsAction_loshingDirect){
		
		int cut = 10;
		if(iPhoneRuningOnGame()){
			cut = 5;
		}
		CGPoint p = [GameLayer shared].content.position;
		if(p.x>-10){
			cut = -10;
			if(iPhoneRuningOnGame()){
				cut = -5;
			}
		}
		
		id m1 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m2 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m3 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m4 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m5 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m6 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m7 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m8 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(0,0))];
		id m9 = [CCMoveTo actionWithDuration:0.1 position:ccpAdd(p, ccp(cut,0))];
		id m = [CCMoveTo actionWithDuration:0.1 position:p];
		
		[[GameLayer shared].content runAction:[CCSequence actions:m1,m2,m3,m4,m5,m6,m7,m8,m9,m,nil]];
		
		// 弹出窗口晃动
		id n1 = [CCMoveBy actionWithDuration:0.1 position:ccp(5,0)];
		id n2 = [CCMoveBy actionWithDuration:0.1 position:ccp(-10,0)];
		id n3 = [CCMoveBy actionWithDuration:0.1 position:ccp(10,0)];
		id n4 = [CCMoveBy actionWithDuration:0.1 position:ccp(-10,0)];
		id n5 = [CCMoveBy actionWithDuration:0.1 position:ccp(10,0)];
		id n6 = [CCMoveBy actionWithDuration:0.1 position:ccp(-10,0)];
		id n7 = [CCMoveBy actionWithDuration:0.1 position:ccp(10,0)];
		id n8 = [CCMoveBy actionWithDuration:0.1 position:ccp(-10,0)];
		id n9 = [CCMoveBy actionWithDuration:0.1 position:ccp(10,0)];
		id n = [CCMoveBy actionWithDuration:0.1 position:ccp(-5, 0)];
		Window *window = [Window shared];
		if (window) {
			window.position = CGPointZero;
			[window runAction:[CCSequence actions:n1,n2,n3,n4,n5,n6,n7,n8,n9,n,nil]];
		}
		
		time = 1.2;
		
	}else if(targetEffectId==EffectsAction_twinkle){
		
		CCSprite * twinkle = [CCSprite spriteWithFile:@"images/effects/mark.jpg"];
		twinkle.anchorPoint = ccp(0,0);
		twinkle.scaleX = winSize.width / twinkle.contentSize.width;
		twinkle.scaleY = winSize.height / twinkle.contentSize.height;
		
		[[Game shared] addChild:twinkle z:INT32_MAX tag:10089];
		
		id f1 = [CCFadeTo actionWithDuration:0.1 opacity:0];
		id f2 = [CCFadeTo actionWithDuration:0.1 opacity:255];
		id f3 = [CCFadeTo actionWithDuration:0.1 opacity:0];
		id f4 = [CCFadeTo actionWithDuration:0.1 opacity:255];
		id f5 = [CCFadeTo actionWithDuration:0.1 opacity:0];
		
		[twinkle runAction:[CCSequence actions:f1,f2,f3,f4,f5,nil]];
		
		time = 0.6;
		
	}else if(targetEffectId==EffectsAction_zoomIn){
		
		id scale = [CCScaleTo actionWithDuration:0.5 scale:1.2];
		[GameLayer shared].isAction = YES;
		[[GameLayer shared] runAction:scale];
		
		time = 0.6;
	}else if(targetEffectId==EffectsAction_zoomOut){
		
		id scale = [CCScaleTo actionWithDuration:0.5 scale:1.0];
		[GameLayer shared].isAction = YES;
		[[GameLayer shared] runAction:scale];
		
		time = 0.6;
	}else if(targetEffectId==EffectsAction_scrollMsg){
        
		[LowerLeftChat clearText];
        
		CCSprite * bg = [CCSprite spriteWithFile:@"images/effects/mark.jpg"];
		bg.anchorPoint = ccp(0,0);
		bg.scaleX = winSize.width / bg.contentSize.width;
		bg.scaleY = winSize.height / bg.contentSize.height;
		bg.color = ccBLACK;
		bg.opacity = 0;
		
		id f1 = [CCFadeTo actionWithDuration:0.5 opacity:255];
		id d = [CCDelayTime actionWithDuration:4.0f];
		id f2 = [CCFadeTo actionWithDuration:0.5 opacity:0];
		[bg runAction:[CCSequence actions:f1,d,f2,nil]];
		
		[[Game shared] addChild:bg z:INT32_MAX-1 tag:10089];
		
		int fontSize = 25;
		int width = winSize.width*0.8;
		int hight = ((int)[otherMessage length]/(width/fontSize)) * (fontSize+5)+fontSize;
		
		CCLabelFX * label = [CCLabelFX labelWithString:otherMessage
											dimensions:CGSizeMake(width,hight)
											 alignment:kCCTextAlignmentLeft 
											  fontName:GAME_DEF_CHINESE_FONT 
											  fontSize:fontSize
										  shadowOffset:CGSizeMake(0,0) 
											shadowBlur:2.0f];
		label.anchorPoint = ccp(0.5,1.0);
		label.position = ccp(winSize.width/2,0);
		[[Game shared] addChild:label z:INT32_MAX tag:10090];
		
		id d1 = [CCDelayTime actionWithDuration:0.5];
		id move = [CCMoveTo actionWithDuration:3.0 position:ccp(winSize.width/2, winSize.height/2+hight/2)];
		id d2 = [CCDelayTime actionWithDuration:1.0];
		id fade = [CCFadeTo actionWithDuration:0.5 opacity:0];
		
		[label runAction:[CCSequence actions:d1,move,d2,fade,nil]];
		
		time = 5.0f;
		
	}else if(targetEffectId==EffectsAction_sceeenMsg){
        
		[LowerLeftChat clearText];
        
		CCSprite * bg = [CCSprite spriteWithFile:@"images/effects/mark.jpg"];
		bg.anchorPoint = ccp(0,0);
		bg.scaleX = winSize.width / bg.contentSize.width;
		bg.scaleY = winSize.height / bg.contentSize.height;
		bg.color = ccBLACK;
		bg.opacity = 0;
		
		id f1 = [CCFadeTo actionWithDuration:0.5 opacity:255];
		id d = [CCDelayTime actionWithDuration:2.0f];
		id f2 = [CCFadeTo actionWithDuration:0.5 opacity:0];
		
		[bg runAction:[CCSequence actions:f1,d,f2,nil]];
		
		[[Game shared] addChild:bg z:INT32_MAX-1 tag:10089];
		
		int fontSize = 30;
		int width = winSize.width*0.8;
		if (iPhoneRuningOnGame()) {
			width *= 2;
		}
		int hight = ((int)[otherMessage length]/(width/fontSize)) * (fontSize+cFixedScale(6))+fontSize;
		CCTextAlignment alignment = kCCTextAlignmentCenter;
		float showDuration = 2.0f;
		if (iPhoneRuningOnGame()) {
			if (hight > 30) {
				showDuration = 3.0f;
				alignment = kCCTextAlignmentLeft;
			}
		} else {
			if (hight > 63) {
				showDuration = 3.0f;
				alignment = kCCTextAlignmentLeft;
			}
		}
		CCLabelFX * label = [CCLabelFX labelWithString:otherMessage
											dimensions:CGSizeMake(width,hight)
											 alignment:alignment 
											  fontName:GAME_DEF_CHINESE_FONT 
											  fontSize:fontSize
										  shadowOffset:CGSizeMake(0,0) 
											shadowBlur:2.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(winSize.width/2,winSize.height/2);
		label.opacity = 0;
		[[Game shared] addChild:label z:INT32_MAX tag:10090];
		
		f1 = [CCFadeTo actionWithDuration:0.5 opacity:255];
		d = [CCDelayTime actionWithDuration:showDuration];
		f2 = [CCFadeTo actionWithDuration:0.5 opacity:0];
		
		[label runAction:[CCSequence actions:f1,d,f2,nil]];
		
		time = 3.0f;
		
	}else if(targetEffectId==EffectsAction_loading){
		[[RoleManager shared].player startLoading:otherMessage];
		time = 2.6;
		
	}else if(targetEffectId==EffectsAction_showUI){
		[GameUI shared].visible = YES;
		time = 0.1f;
	}else if(targetEffectId==EffectsAction_hideUI){
		[GameUI shared].visible = NO;
		time = 0.1f;
	}else if(targetEffectId==EffectsAction_chapter){
		//关闭UI
		[[GameUI shared] closeUI];
		[[GameUI shared] closeOtherUI];
		
		CCSprite * bg = [CCSprite spriteWithFile:@"images/effects/mark.jpg"];
		bg.anchorPoint = ccp(0,0);
		bg.scaleX = winSize.width / bg.contentSize.width;
		bg.scaleY = winSize.height / bg.contentSize.height;
		bg.color = ccBLACK;
		bg.opacity = 0;
		[[Game shared] addChild:bg z:INT32_MAX-1 tag:10089];
		
		id a1 = [CCFadeTo actionWithDuration:0.5 opacity:128];
		id b1 = [CCDelayTime actionWithDuration:4.0];
		id c1 = [CCFadeTo actionWithDuration:0.5 opacity:0];
		[bg runAction:[CCSequence actions:a1,b1,c1,nil]];
		
		NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
		int cid = [[playerInfo objectForKey:@"chapter"] intValue];
		CCSprite * chapter = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/effects/chapters/chapter_%d.png",cid]];
		chapter.anchorPoint = ccp(0.5,0.5);
		//fix chao 改位置
		if(iPhoneRuningOnGame()){
			chapter.position = ccp(winSize.width/2,winSize.height/2+50);
		}else{
			chapter.position = ccp(winSize.width/2,winSize.height/2+100);
		}
		
		//end
		chapter.opacity = 0;
		[[Game shared] addChild:chapter z:INT32_MAX tag:10090];
		
		id a2 = [CCFadeTo actionWithDuration:0.5 opacity:255];
		//fix chao 改时间
		id b2 = [CCDelayTime actionWithDuration:1.8];
		//end
		id c2 = [CCFadeTo actionWithDuration:0.5 opacity:0];
		[chapter runAction:[CCSequence actions:a2,b2,c2,nil]];
		//time = 5.1f;
		time = 3.0f;
		//end
	}else if(targetEffectId==EffectsAction_joinPartner){
		//--------------------------------------------------------------------------------------------
		CCSprite * background = [CCSprite spriteWithFile:@"images/ui/alert/unlock_bg.png"];
		CCSprite *title = [CCSprite spriteWithFile:@"images/ui/alert/taskAlert_4.png"];
		[background addChild:title];
		
		if(iPhoneRuningOnGame()){
			background.position=ccp(winSize.width/2, winSize.height/2+60);
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 10);
		}else{
			background.position=ccp(winSize.width/2, winSize.height/2+120);
			title.position=ccp(background.contentSize.width/2, background.contentSize.height - 20);
		}
		CCLOG(@"%@",otherMessage);
		int _rid = [otherMessage intValue];
		CCSprite *role = [self getPartner:_rid];
		if (role) {
			[background addChild:role];
			if(iPhoneRuningOnGame()){
				role.position=ccp(background.contentSize.width/2, background.contentSize.height/2-10);
			}else{
				role.position=ccp(background.contentSize.width/2, background.contentSize.height/2-20);
			}
		}
		[[Game shared] addChild:background z:INT32_MAX tag:10089];
		
		time = 3.0;
	}else if (targetEffectId == EffectsAction_showNpcEffect){
		//TODO  show Npc effect
		//预定时间结束
		if (otherMessage) {
			NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:otherMessage];
			if (info) {
				CCLOG([info description]);
				int npcId = [[info objectForKey:@"npcid"] intValue];
				int ani1 = [[info objectForKey:@"effect1"] intValue];
				int _y = [[info objectForKey:@"offsety"] intValue];
				GameNPC *npc = [[NPCManager shared] getNPCById:npcId];
				if (npc) {
					
					if (ani1 > 0) {//如果有第一个动画，就由第一个动画的回调去完成
						[npc showEffect:ani1 target:self call:@selector(checkNextEffectAction) offset:_y];
						return ;
					}
					//如果没没有第一个动画,看第二个,然后结束
					int ani2 = [[info objectForKey:@"effect2"] intValue];
					if (ani2 > 0) {
						[npc showEffect:ani2 target:nil call:nil offset:_y];
					}
					
				}else{
					CCLOG(@"targetEffectId == EffectsAction_showNpcEffect -> npc is nil");
				}
			}
		}else{
			CCLOG(@"targetEffectId == EffectsAction_showNpcEffect -> otherMessage is nil");
		}
	}else if (targetEffectId == EffectsAction_whiteScreen){
        
		[LowerLeftChat clearText];
        
		CCSprite * bg = [CCSprite spriteWithFile:@"images/effects/mark.jpg"];
		bg.scaleX = winSize.width / bg.contentSize.width;
		bg.scaleY = winSize.height / bg.contentSize.height;
		bg.opacity = 0;
		[[Game shared] addChild:bg z:INT32_MAX-1 tag:10091];
		bg.position=ccp(winSize.width/2, winSize.height/2);
		
		id f1 = [CCFadeTo actionWithDuration:0.5 opacity:255];
		[bg runAction:[CCSequence actions:f1,nil]];
		
		time = 0.6;
		
	}else if (targetEffectId == EffectsAction_showPlayerEffect){
		//播放玩家效果
		if (otherMessage) {
			NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:otherMessage];
			if (info) {
				int ani1 = [[info objectForKey:@"effect1"] intValue];
				if (ani1 > 0) {
					[[RoleManager shared].player showEffect:ani1 target:self call:@selector(checkNextEffectAction)];
					return ;
				}
				int ani2 = [[info objectForKey:@"effect2"] intValue];
				[[RoleManager shared].player showEffect:ani2 target:nil call:nil];
			}
		}else{
			CCLOG(@"targetEffectId == EffectsAction_showPlayerEffect -> otherMessage is nil");
		}
	}else if (targetEffectId == EffectsAction_Inbetweening){
		if (otherMessage) {
			NSDictionary* __dict = [NSDictionary dictionaryWithObject:otherMessage
															   forKey:@"path"];
			Inbetweening * inbetweening = [Inbetweening createInbetweening:__dict
																	target:self
																	  call:@selector(endEffects)];
			if (inbetweening != nil) {
				[[Game shared] addChild:inbetweening z:INT32_MAX tag:10089];
			}
			
		}
		isEndEffects = NO;
		return ;
	}
	
	isEndEffects = NO;
	[NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(endEffects) userInfo:nil repeats:NO];
	
}
-(void)checkNextEffectAction{
	if (targetEffectId == EffectsAction_showNpcEffect) {
		//检察播放另外一个效果
		if (otherMessage) {
			NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:otherMessage];

			if (info) {
				CCLOG([info description]);
				int npcId = [[info objectForKey:@"npcid"] intValue];
				int ani1 = [[info objectForKey:@"effect2"] intValue];
				int _y = [[info objectForKey:@"offsety"] intValue];
				GameNPC *npc = [[NPCManager shared] getNPCById:npcId];
				if (npc) {
					if (ani1 > 0) {
						[npc showEffect:ani1 target:nil call:nil offset:_y];
					}
				}else{
					CCLOG(@"targetEffectId == EffectsAction_showNpcEffect -> npc is nil");
				}
			}
		}
	}else if (targetEffectId == EffectsAction_showPlayerEffect){
		if (otherMessage) {
			NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:otherMessage];
			if (info) {
				int ani2 = [[info objectForKey:@"effect2"] intValue];
				if (ani2 > 0 ) {
					[[RoleManager shared].player showEffect:ani2 target:nil call:nil];
				}
			}
		}
	}
	//结束效果
	isEndEffects = NO;
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(endEffects) userInfo:nil repeats:NO];
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
			officeIcon.position = ccp(15, 144);
			
			
			CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:11];
			nameLabel.color = ccc3(47, 19, 8);
			nameLabel.position = ccp(bg.contentSize.width / 2, 156);
			[bg addChild:nameLabel];
			
			CCSprite *join = [CCSprite spriteWithFile:@"images/ui/alert/join.png"];
			[bg addChild:join z:2];
			join.anchorPoint=ccp(1, 0);
			join.position=ccp(head.contentSize.width + 12, -12);

			return bg;
		}
	}
	return nil;
}
-(void)updateLoading:(ccTime)time{
	CCNode * node = [[Game shared] getChildByTag:10089];
	if(node){
		CCNode * p1 = [node getChildByTag:101];
		CCNode * p2 = [node getChildByTag:102];
		CCNode * p3 = [node getChildByTag:103];
		if(p2) p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		if(p3) p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
	}
}

-(void)showEffects:(EffectsAction)eid target:(id)t call:(SEL)c{
	
	target = t;
	call = c;
	targetEffectId = eid;
	[[RoleManager shared].player stopMove];
	
	//[self showEffects];
	[NSTimer scheduledTimerWithTimeInterval:0.1 
									 target:self 
								   selector:@selector(showEffects) 
								   userInfo:nil repeats:NO];
	
}

-(void)showEffectsWithDict:(NSDictionary *)dict target:(id)t call:(SEL)c taskId:(int)_tid taskStep:(int)_step{
	if (self.taskId == _tid && self.taskStep == _step) {
		CCLOG(@"showEffectsWithDict is double create 2");
		return ;
	}
	self.taskId=_tid;
	self.taskStep = _step;
	[self showEffectsWithDict:dict target:t call:c];
}

-(void)showEffectsWithDict:(NSDictionary*)dict target:(id)t call:(SEL)c{
	
	
	target = t;
	call = c;
	
	int eid = [[dict objectForKey:@"eid"] intValue];
	if(eid==EffectsAction_scrollMsg ||
	   eid==EffectsAction_sceeenMsg ||
	   eid==EffectsAction_loading	||
	   eid==EffectsAction_joinPartner ||
	   eid==EffectsAction_showNpcEffect ||
	   eid==EffectsAction_showPlayerEffect ||
	   eid==EffectsAction_Inbetweening){
		if(otherMessage) [otherMessage release];
		otherMessage = [dict objectForKey:@"other"];
		[otherMessage retain];
		
		targetEffectId = eid;
		[self showEffects];
		
	}else{
		
		targetEffectId = eid;
		[self showEffects];
	}
	
}

-(void)endEffects{
	
	CCLOG(@"nstimer do call endEffects");
	
	if(isEndEffects) return;
	isEndEffects = YES;
	
	CCLOG(@"endEffects");
	
	[[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];
	
	if (targetEffectId==EffectsAction_loading) {
		[[RoleManager shared].player closeLoading];
	}
	
	if (targetEffectId==EffectsAction_chapter) {
		[[GameUI shared] openUI];
		[[GameUI shared] openOtherUI];
	}
	
	CCNode * node;
	node = [[Game shared] getChildByTag:10088];
	if(node) [node removeFromParentAndCleanup:YES];
	node = [[Game shared] getChildByTag:10089];
	if(node) [node removeFromParentAndCleanup:YES];
	node = [[Game shared] getChildByTag:10090];
	if(node) [node removeFromParentAndCleanup:YES];
	
	node = [[Game shared] getChildByTag:10091];
	if(node){
		[NSTimer scheduledTimerWithTimeInterval:5.0
										 target:[GameEffects class] 
									   selector:@selector(removeOtherEffect) 
									   userInfo:nil repeats:NO];
	}else{
		[GameEffectsBlockTouck unlockScreen];
	}
	
	[[Window shared] setVisible:YES];
	[GameLayer shared].isAction = NO;
	[GameLayer shared].touchEnabled = YES;
	
	//清空记录，让下一个动作继续进行
	taskId = -1 ;
	taskStep = -1 ;
	
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	
	//清楚效果播放的ID
	targetEffectId = EffectsAction_none;
	target = nil;
	call = nil;
	

}


@end

@implementation GameEffectsBlockTouck

@synthesize target;
@synthesize call;

+(void)lockScreen:(id)_target call:(SEL)_call{
	CCLOG(@"lockScreen:target:call");
	[[Game shared] removeChildByTag:-97442832 cleanup:YES];
	
	GameEffectsBlockTouck * block = [GameEffectsBlockTouck node];
	block.target=_target;
	block.call=_call;
	[[Game shared] addChild:block z:INT32_MAX tag:-97442832];
}

+(void)lockScreen
{
	CCLOG(@"lockScreen");
	[[Game shared] removeChildByTag:-97442832 cleanup:YES];
	
	GameEffectsBlockTouck * block = [GameEffectsBlockTouck node];
	[[Game shared] addChild:block z:INT32_MAX-10 tag:-97442832];
}

+(void)unlockScreen
{
	CCLOG(@"unlockScreen");
	[[Game shared] removeChildByTag:-97442832 cleanup:YES];
}

-(void)onEnter{
	[super onEnter];
	self.touchEnabled = YES;
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)registerWithTouchDispatcher{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:YES];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	if (nil != target && nil != call) {
		[target performSelector:call];
		[GameEffectsBlockTouck unlockScreen];
	}
	
}

@end
