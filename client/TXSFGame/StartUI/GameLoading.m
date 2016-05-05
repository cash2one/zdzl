//
//  GameLoading.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-13.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "GameLoading.h"
#import "Game.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "AnimationViewer.h"
#import "GameConnection.h"
#import "GameEffects.h"
#import "GameDB.h"
#import "LowerLeftChat.h"

@implementation GameLoading

static GameLoading * gameLoading;
static BOOL isInGameing;

+(GameLoading*)share{
	if(!gameLoading) [GameLoading show];
	return gameLoading;
}
+(void)stopAll{
	if(gameLoading){
		[GameLoading delayHide];
	}
}
+(BOOL)isShowing{
	if(gameLoading){
		return YES;
	}
	return NO;
}

+(void)isInGameing:(BOOL)isInGame{
	isInGameing = isInGame;
}

+(void)show{
	if(!gameLoading){
		//gameLoading = [GameLoading layerWithColor:ccc4(0,0,0,0)];
		gameLoading = [GameLoading node];
		[[Game shared] addChild:gameLoading z:INT32_MAX tag:9876];
	}
}

+(void)urgentHide{
	if(gameLoading){
		[[Game shared] removeChildByTag:9876 cleanup:YES];
		gameLoading = nil;
	}
}

+(void)hide{
	if(gameLoading){
		[NSTimer scheduledTimerWithTimeInterval:0.8f target:[GameLoading class] selector:@selector(delayHide) userInfo:nil repeats:NO];
	}
}

+(void)delayHide{
	if(gameLoading){
		[[Game shared] removeChildByTag:9876 cleanup:YES];
		gameLoading = nil;
	}
	[NSTimer scheduledTimerWithTimeInterval:1.5f target:[GameLoading class] selector:@selector(freeMemory) userInfo:nil repeats:NO];
}

+(void)freeMemory{
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	//[[CCDirector sharedDirector] purgeCachedData];
}

+(void)showFight:(NSString*)msg loading:(BOOL)loading{
	[GameLoading showFight:msg target:nil call:nil loading:loading];
}

+(void)showFight:(NSString*)msg target:(id)target call:(SEL)call loading:(BOOL)loading{
	
	[GameLoading show];
	//[gameLoading loadFightBackground];
	[gameLoading showMessage:msg];
	
	if(loading){
		[gameLoading showPercent:1];
	}
	
	[gameLoading showFightLoadingStep1Target:target call:call];
	
}

+(void)showMessage:(NSString*)msg loading:(BOOL)loading{
	[GameLoading showMessage:msg target:nil call:nil loading:loading];
}

+(void)showMessage:(NSString*)msg target:(id)target call:(SEL)call loading:(BOOL)loading{
    
	[LowerLeftChat clearText];
    
	[GameLoading show];
	[gameLoading loadBackground];
	[gameLoading showTips];
	[gameLoading showMessage:msg];
	
	if(loading){
		[gameLoading showPercent:1];
	}
	
	if(target!=nil && call!=nil){
		//[target performSelector:call withObject:self];
		[NSTimer scheduledTimerWithTimeInterval:0.1f
										 target:target
									   selector:call
									   userInfo:nil repeats:NO];
		
	}
}

+(void)showError:(NSString*)error{
	[GameLoading show];
	[gameLoading showMessage:error];
}

+(void)downloadPercent:(NSNumber*)percent{
	if(gameLoading){
		[gameLoading updateDownPercent:[percent floatValue]];
	}
}

-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	if(last3Frame){
		[last3Frame release];
		last3Frame=nil;
	}
	
	//[[CCDirector sharedDirector] purgeCachedData];
	[super dealloc];
	//[[CCDirector sharedDirector] purgeCachedData];
}

-(void)registerWithTouchDispatcher{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:INT32_MIN swallowsTouches:YES];
}

-(void)loadFightBackground{
	
	/*
	if(isInGameing){
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		CCSprite * bg = [CCSprite spriteWithFile:@"images/start/loading/bg-fight.jpg"];
		bg.anchorPoint = ccp(0.5,0.5);
		bg.position = ccp(winSize.width/2, winSize.height/2);
		if(iPhoneRuningOnGame() && ![Game supportRetinaDisplay]){
			bg.scale = 0.5;
		}
		[self addChild:bg z:0 tag:555];
	}else{
		[self loadBackground];
	}
	return;
	*/
	
}
-(void)showFightLoadingStep1Target:(id)target call:(SEL)call{
	
	isShowFight = YES;
    [LowerLeftChat clearText];
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:@"images/loading/towhite/" name:@"%d.png"];
	
	if([frames count]>0){
		NSMutableArray *revframes=[NSMutableArray arrayWithArray:frames];
		frames=[[revframes reverseObjectEnumerator]allObjects];
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		AnimationViewer * toblack = [AnimationViewer node];
		[toblack playAnimation:frames call:[CCCallBlock actionWithBlock:^(void){
			
			if(target!=nil && call!=nil){
				[NSTimer scheduledTimerWithTimeInterval:0.3f
												 target:target 
											   selector:call 
											   userInfo:nil repeats:NO];
				
			}
			
		}]];
		
		toblack.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
		toblack.scaleX = winSize.width / toblack.contentSize.width;
		toblack.scaleY = winSize.height / toblack.contentSize.height;
		[self addChild:toblack z:-1 tag:1010];
		
	}
	
	[self scheduleOnce:@selector(showTurn) delay:0.5f];
	
}

-(void)showTurn{;
	
	runSpwRoot=[CCSprite node];
	[runSpwRoot setContentSize:self.contentSize];
	
	runSpw1=[CCSprite spriteWithFile:@"images/loading/10.png"];
	runSpw2=[CCSprite spriteWithFile:@"images/loading/11.png"];
	strSpw=[CCSprite spriteWithFile:@"images/loading/0.png"];
	
	runSpwRoot.scale=3.8f;
	strSpw.opacity=0;
	runSpw1.opacity=0;
	runSpw2.opacity=0;
	
	[runSpwRoot setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	[runSpw1 setPosition:ccp(runSpwRoot.contentSize.width/2, runSpwRoot.contentSize.height/2)];
	[runSpw2 setPosition:ccp(runSpwRoot.contentSize.width/2, runSpwRoot.contentSize.height/2)];
	
	[strSpw setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	
	CCScaleTo *runSpwRoot_ScaleBy=[CCScaleTo actionWithDuration:0.35f scale:1];
	CCRotateBy *runSpw1_RotateTo=[CCRotateBy actionWithDuration:10 angle:360];
	CCRotateBy *runSpw2_RotateTo=[CCRotateBy actionWithDuration:10 angle:360];
	
	CCFadeIn *runSpw1_FadeIn=[CCFadeIn actionWithDuration:0.25f];
	CCFadeIn *runSpw2_FadeIn=[CCFadeIn actionWithDuration:0.25f];
	CCFadeIn *str_FadeIn=[CCFadeIn actionWithDuration:0.25f];
	
	CCSpawn *runSpw1_spaws=[CCSpawn actions:runSpw1_RotateTo,runSpw1_FadeIn, nil];
	CCSpawn *runSpw2_spaws=[CCSpawn actions:runSpw2_RotateTo,runSpw2_FadeIn, nil];
	CCCallBlock *bfun=[CCCallBlock actionWithBlock:^{
		[runSpw1 stopAllActions];
		[runSpw2 stopAllActions];
		CCRotateBy *r1=[CCRotateBy actionWithDuration:2 angle:360];
		CCRotateBy *r2=[CCRotateBy actionWithDuration:2 angle:-360];
		CCRepeatForever *rt1=[CCRepeatForever actionWithAction:r1];
		CCRepeatForever *rt2=[CCRepeatForever actionWithAction:r2];
		[runSpw1 runAction:rt1];
		[runSpw2 runAction:rt2];
	}];
	
	CCSequence *seq=[CCSequence actions:runSpwRoot_ScaleBy,bfun, nil];
	
	[runSpw1 runAction:runSpw1_spaws];
	[runSpw2 runAction:runSpw2_spaws];
	[strSpw runAction:str_FadeIn];
	[runSpwRoot runAction:seq];
	
	[runSpwRoot addChild:runSpw1];
	[runSpwRoot addChild:runSpw2];
	[runSpwRoot addChild:strSpw];
	
	[self addChild:runSpwRoot];
	
}

-(void)showFightLoadingStep2Target:(id)target call:(SEL)call{
	
	CCFadeOut *f1=[CCFadeOut actionWithDuration:0.28f];
	CCFadeOut *f2=[CCFadeOut actionWithDuration:0.28f];
	CCFadeOut *f3=[CCFadeOut actionWithDuration:0.28f];
	[runSpw1 runAction:f1];
	[runSpw2 runAction:f2];
	[strSpw runAction:f3];
	
	CCScaleTo * scaleTo = [CCScaleTo actionWithDuration:0.33f scale:3.8f];
	[runSpwRoot runAction:scaleTo];
	
	//clean other 
	[self removeChildByTag:1010 cleanup:YES];
	
	[self removeChildByTag:100 cleanup:YES];
	[self removeChildByTag:101 cleanup:YES];
	[self removeChildByTag:102 cleanup:YES];
	[self removeChildByTag:103 cleanup:YES];
	[self removeChildByTag:104 cleanup:YES];
	[self removeChildByTag:105 cleanup:YES];
	[self removeChildByTag:123 cleanup:YES];
	[self removeChildByTag:125 cleanup:YES];
	[self removeChildByTag:201 cleanup:YES];
	[self removeChildByTag:555 cleanup:YES];
	[LowerLeftChat clearText];
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:@"images/loading/towhite/" name:@"%d.png"];
	if([frames count]>0){
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		AnimationViewer * towhite = [AnimationViewer node];
		[towhite playAnimation:frames call:[CCCallBlock actionWithBlock:^(void){
			if(target!=nil && call!=nil){
				[NSTimer scheduledTimerWithTimeInterval:0.001f
												 target:target 
											   selector:call 
											   userInfo:nil repeats:NO];
				
			}
			[GameLoading delayHide];
		}]];
		
		towhite.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
		towhite.scaleX = winSize.width / towhite.contentSize.width;
		towhite.scaleY = winSize.height / towhite.contentSize.height;
		[self addChild:towhite z:-1 tag:1011];
	}
	
}

-(void)loadBackground{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CCSprite * bg = nil;
	if(isInGameing){
		//游戏中加载的
		bg = [CCSprite spriteWithFile:@"images/start/loading/bg-loading.jpg"];
		if(iPhoneRuningOnGame()){
			NSString* path_ = [NSString stringWithFormat:@"logo.png"];
			if (path_) {
				CCSprite * logo = [CCSprite spriteWithFile:path_];
				logo.position = ccp(810.0f/2,560/2.0f);
				logo.scale=0.5f;
				[bg addChild:logo];
			}
		}
	}else{
		bg = [CCSprite spriteWithFile:@"images/start/start-bg.jpg"];
		
		NSString* path_ = [NSString stringWithFormat:@"logo.png"];
		if (path_) {
			CCSprite * logo = [CCSprite spriteWithFile:path_];
			if (iPhoneRuningOnGame()) {
				logo.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2+80/2.0f);
			}else{
				logo.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2+50);
			}
			[bg addChild:logo];
		}
	}
	
	bg.anchorPoint = ccp(0.5,0.5);
	bg.position = ccp(winSize.width/2, winSize.height/2);
	if(iPhoneRuningOnGame() && ![Game supportRetinaDisplay]){
		bg.scale = 0.5;
	}
	[self addChild:bg z:0 tag:555];
}

-(void)onEnter{
	
	
	[GameEffects removeOtherEffect];
	[super onEnter];
	
	self.touchEnabled = YES;
	
	CCSprite * p0 = [CCSprite spriteWithFile:@"images/start/loading/p.png"];
	CCSprite * p1 = [CCSprite spriteWithFile:@"images/start/loading/p-1.png"];
	CCSprite * p2 = [CCSprite spriteWithFile:@"images/start/loading/p-2.png"];
	CCSprite * p3 = [CCSprite spriteWithFile:@"images/start/loading/p-3.png"];
	CCSprite * p4 = [CCSprite spriteWithFile:@"images/start/loading/p-4.png"];
	p0.anchorPoint = ccp(0.5,0.5);
	p1.anchorPoint = ccp(0,0.5);
	p2.anchorPoint = ccp(0,0.5);
	p3.anchorPoint = ccp(0,0.5);
	p4.anchorPoint = ccp(0.5,0.5);
	
	p2.scaleX = 0;
	
	[self addChild:p0 z:100 tag:100];
	[self addChild:p1 z:102 tag:101];
	[self addChild:p2 z:101 tag:102];
	[self addChild:p3 z:103 tag:103];
	[self addChild:p4 z:104 tag:104];
	
	p5isMove=NO;
	
	[self isShowPercent:NO];
	[self schedule:@selector(checkTimer:)];
	[self updatePercent];
	
}

-(void)showTips{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	float blur = 2.0f;
	CGSize offset = CGSizeMake(-1.5, -1.5);
	if(iPhoneRuningOnGame()){
		blur = 1.0f;
		offset = CGSizeMake(-0.7, -0.7);
	}
	
#if GAME_SNS_TYPE!=6
	CCLabelFX * label_1 = [CCLabelFX labelWithString:NSLocalizedString(@"LOADING_TIPS", nil)
										  dimensions:CGSizeMake(0,0)
										   alignment:kCCTextAlignmentCenter
											fontName:GAME_DEF_CHINESE_FONT
											fontSize:15
										shadowOffset:offset
										  shadowBlur:blur
										 shadowColor:ccc4(0,0,0, 255)
										   fillColor:ccc4(180,180,180, 255)
						   ];
	label_1.anchorPoint = ccp(0.5,0.0);
	label_1.position = ccp(winSize.width/2,5);
	[self addChild:label_1 z:1 tag:201];
	if(iPhoneRuningOnGame() && ![Game supportRetinaDisplay]){
		label_1.scale = 0.5;
	}
	
#endif
	
	if(isInGameing){
		NSDictionary * tipsInfo = [[GameDB shared] getLoadingTips:getRandomInt(1,46)];
		if(tipsInfo){
			[self removeChildByTag:202 cleanup:YES];
			
			NSString * tips = [NSString stringWithFormat:@"%@",NSLocalizedString(@"loading_start_simple_tips",nil)];
			tips = [tips stringByAppendingFormat:[tipsInfo objectForKey:@"info"]];
			
			CCSprite * label = drawBoundString(tips, 8, GAME_DEF_CHINESE_FONT, 18, ccc3(223, 168, 41), ccBLACK);
			[self addChild:label z:1 tag:202];
			
			if(label.contentSize.width>(winSize.width-30)){
				label.scale = (winSize.width-30)/label.contentSize.width;
			}
			
			if(iPhoneRuningOnGame()){
				label.position = ccp(winSize.width/2,36);
			}else{
				label.position = ccp(winSize.width/2,100);
			}
			
		}
	}
	
}

-(void)checkTimer:(ccTime)time{
	[self updatePercent];
}

-(void)showMessage:(NSString*)msg{
    
	[LowerLeftChat clearText];
    
	//CCLabelFX * label = (CCLabelFX*)[self getChildByTag:123];
	//[label setString:msg];
	
	CCNode * node = [self getChildByTag:123];
	if(node) [node removeFromParentAndCleanup:YES];
	
	//if([msg length]==0) return;
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * label = nil;
	
	if(iPhoneRuningOnGame() && ![Game supportRetinaDisplay]){
		label = drawBoundString(msg, 8, GAME_DEF_CHINESE_FONT, 18, ccWHITE, ccBLACK);
		label.scale = 1.0f;
	}else{
		label = drawBoundString(msg, 10, GAME_DEF_CHINESE_FONT, 25, ccWHITE, ccBLACK);
	}
	label.anchorPoint = ccp(0.5,0.0);
	
	if(iPhoneRuningOnGame()){
		label.position = ccp(winSize.width/2,56);
	}else{
		label.position = ccp(winSize.width/2,150);
	}
	
	[self addChild:label z:100 tag:123];
	
}

-(void)showPercent:(float)percent{
	
	if(percent>1) percent = 1;
	
	[self isShowPercent:YES];
	
	CCNode * p2 = [self getChildByTag:102];
	[p2 stopAllActions];
	
	if(t_percent>percent){
		t_percent = percent;
		p2.scaleX = 2.04*t_percent;
		return;
	}
	
	if(t_percent<percent){
		t_percent = percent;
		id action = [CCScaleTo actionWithDuration:0.125f scaleX:2.04*t_percent scaleY:1.0f];
		[p2 runAction:action];
	}else{
		t_percent = percent;
		p2.scaleX = 2.04*t_percent;
	}
	
}

-(void)isShowPercent:(BOOL)isShow{
	CCNode * p0 = [self getChildByTag:100];
	CCNode * p1 = [self getChildByTag:101];
	CCNode * p2 = [self getChildByTag:102];
	CCNode * p3 = [self getChildByTag:103];
	CCNode * p4 = [self getChildByTag:104];
	CCNode * p5 = [self getChildByTag:105];
	
	p0.visible = isShow;
	p1.visible = isShow;
	p2.visible = isShow;
	p3.visible = isShow;
	p4.visible = isShow;
	p5.visible = isShow;
	
}

-(void)updatePercent{
	
	CCNode * p0 = [self getChildByTag:100];
	CCNode * p1 = [self getChildByTag:101];
	CCNode * p2 = [self getChildByTag:102];
	CCNode * p3 = [self getChildByTag:103];
	CCNode * p4 = [self getChildByTag:104];
	CCNode * p5 = [self getChildByTag:105];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	if(iPhoneRuningOnGame()){
		
		p0.position = ccp(winSize.width/2, 161/2.0f);
		p1.position = ccp(p0.position.x-p0.contentSize.width/2+40,160/2.0f);
		p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
		p4.position = ccp(p3.position.x+p3.contentSize.width/2-1.5,p3.position.y);
		p5.position = ccpAdd(p4.position, ccp(10,0));
		
	}else{
		
		p0.position = ccp(winSize.width/2, 211);
		p1.position = ccp(p0.position.x-p0.contentSize.width/2+80,210);
		p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
		p4.position = ccp(p3.position.x+p3.contentSize.width/2-3,p3.position.y);
		p5.position = ccpAdd(p4.position, ccp(20,0));
		
	}
	
	int t_w = 320;
	if(iPhoneRuningOnGame()) t_w /= 2;
	
	if(p5.position.x>t_w && !p5isMove){
		CCAnimation *anmis=[CCAnimation animationWithSpriteFrames:last3Frame delay:0.1];
		CCAnimate *anmi=[CCAnimate actionWithAnimation:anmis];
		CCRepeatForever *crf=[CCRepeatForever actionWithAction:anmi];
		CCSprite *sprite=(CCSprite*)[self getChildByTag:105];
		[sprite runAction:crf];
		p5isMove=true;
	}
}

-(void)updateDownPercent:(float)percent{
	
	if(isShowFight){
		return;
	}
	
	[self removeDownPercent];
	if(percent<=0.0f) return;
	if(percent>1.0f) percent = 1.0f;
	
	[self showPercent:percent];
	
	//NSString * msg = [NSString stringWithFormat:@"正在加载游戏资源 : %.1f%@",(percent*100),@"%"];
    NSString * msg = [NSString stringWithFormat:NSLocalizedString(@"loading_data",nil),(percent*100),@"%"];
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * label = drawBoundString(msg, 10, GAME_DEF_CHINESE_FONT, 22, ccWHITE, ccBLACK);
	label.anchorPoint = ccp(0.5,0.0);
	
	if(iPhoneRuningOnGame()){
		label.position = ccp(winSize.width/2,16);
	}else{
		label.position = ccp(winSize.width/2,115);
	}
	[self addChild:label z:100 tag:125];
	
	
}
-(void)removeDownPercent{
	CCNode * node = [self getChildByTag:125];
	if(node) [node removeFromParentAndCleanup:YES];
}
/*
-(void)showEffect:(NSString*)path target:(id)_t call:(SEL)_c{
	
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	
	if([frames count]>0){
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		AnimationViewer * into = [AnimationViewer node];
		[into playAnimation:frames call:[CCCallBlock actionWithBlock:^(void){
			
			[self removeChildByTag:100 cleanup:YES];
			[self removeChildByTag:101 cleanup:YES];
			[self removeChildByTag:102 cleanup:YES];
			[self removeChildByTag:103 cleanup:YES];
			[self removeChildByTag:104 cleanup:YES];
			[self removeChildByTag:105 cleanup:YES];
			[self removeChildByTag:123 cleanup:YES];
			[self removeChildByTag:201 cleanup:YES];
			[self removeChildByTag:555 cleanup:YES];
			
			CCFadeOut * fade = [CCFadeOut actionWithDuration:0.05f];
			CCCallBlock * end = [CCCallBlock actionWithBlock:^(void){
				if(_t!=nil && _c!=nil){
					[NSTimer scheduledTimerWithTimeInterval:0.01f
													 target:_t
												   selector:_c
												   userInfo:nil repeats:NO];
				}
				[GameLoading delayHide];
			}];
			[into runAction:[CCSequence actions:fade,end,nil]];
		}]];
		
		into.anchorPoint = ccp(0,0);
		into.scaleX = winSize.width / into.contentSize.width;
		into.scaleY = winSize.height / into.contentSize.height;
		
		[self addChild:into z:INT32_MAX tag:10001];
		
	}else{
		[GameLoading hide];
	}
	
}
*/

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	CCLOG(@"Touch GameLoading layer");
	return YES;
}

@end
