//
//  FightPlayer.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-3.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "FightPlayer.h"
#import "GameLayer.h"
#import "Game.h"
#import "CJSONDeserializer.h"
#import "GameConfigure.h"
#import "FightGroup.h"
#import "FightCharacter.h"
#import "FightManager.h"
#import "FightAction.h"
#import "GameSoundManager.h"
#import "GameLoading.h"
#import "FightManager.h"
#import "FightMember.h"

#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "CCSimpleButton.h"
#import "InfoAlert.h"

static FightPlayer * fightPlayer;
static float fight_speed = 1.0f;

@implementation FightPlayer

+(FightPlayer*)shared{
	return fightPlayer;
}
+(void)stopAll{
	if(fightPlayer){
		[FightPlayer hide];
	}
}

+(void)show:(NSString*)str{
	NSData * data = getDataFromString(str);
	NSDictionary * info = [[CJSONDeserializer deserializer] deserializeAsDictionary:data error:nil];
	[FightPlayer showByDict:info];
}

+(void)showByDict:(NSDictionary*)info{
	
	[FightManager cleanMemory];
	
	fightPlayer = [FightPlayer node];
	[[Game shared] addChild:fightPlayer];
	[fightPlayer play:info];
	
}

+(void)hide{
	if(fightPlayer){
		[fightPlayer removeAllChildrenWithCleanup:YES];
		[fightPlayer removeFromParentAndCleanup:YES];
		fightPlayer = nil;
	}
}

+(float)checkSpeed:(float)speed{
	speed = speed*(fight_speed);
	return speed;
}
+(float)checkTime:(float)time{
	time = time*(1/fight_speed);
	return time;
}

-(void)dealloc{
	
	[self cleanFightData];
	
	if(original){
		[original release];
		original = nil;
	}
	
	[super dealloc];
	CCLOG(@"FightPlayer dealloc");
}

-(void)onEnter{
	
	self.touchEnabled = YES;
	self.touchMode = kCCTouchesAllAtOnce;
	self.touchPriority = 0;
	
	todoTimers = [[NSMutableArray alloc] init];
	overTimers = [[NSMutableArray alloc] init];
	
	[self loadPlayerSpeedLevel];
	
	[self schedule:@selector(checkTimer:)];
	[super onEnter];
	
	
#ifdef GAME_DEBUGGER________
#if GAME_DEBUGGER________ == 1
	
	if([FightManager getFightType]==Fight_Type_normal ||
	   [FightManager getFightType]==Fight_Type_abyss ||
	   [FightManager getFightType]==Fight_Type_pk ||
	   NO){
		//绘制按钮
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		CCSimpleButton* bt_skip = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_skip_1.png"
														  select:@"images/ui/button/bts_skip_2.png"
														  target:self
															call:@selector(debug_endActionFight:)
														priority:-125];
		
		[self addChild:bt_skip z:INT16_MAX];
		if (iPhoneRuningOnGame()) {
			bt_skip.scale=1.3f;
		}
		bt_skip.delayTime = 1.0f;
		bt_skip.position = ccp(winSize.width/2, cFixedScale(100));
	}
	
#endif
#endif
	
}

-(void)showSpeedBtns{
	
	[self hideSpeedBtns];
	
	CGSize size = [CCDirector sharedDirector].winSize;
	
	CCSimpleButton * s1 = [CCSimpleButton spriteWithFile:@"images/fight/speed/speed_1.png"];
	CCSimpleButton * s2 = [CCSimpleButton spriteWithFile:@"images/fight/speed/speed_2.png"];
	CCSimpleButton * s3 = [CCSimpleButton spriteWithFile:@"images/fight/speed/speed_3.png"];
	
	s1.target = self;
	s2.target = self;
	s3.target = self;
	
	s1.call = @selector(doSpeed:);
	s2.call = @selector(doSpeed:);
	s3.call = @selector(doSpeed:);
	
	s1.visible = NO;
	s2.visible = NO;
	s3.visible = NO;
	
	s1.priority = -60;
	s2.priority = -60;
	s3.priority = -60;
	
	s1.anchorPoint = ccp(1.0,1.0);
	s2.anchorPoint = ccp(1.0,1.0);
	s3.anchorPoint = ccp(1.0,1.0);
	s1.position = ccp(size.width-cFixedScale(15),size.height-cFixedScale(10));
	s2.position = ccp(size.width-cFixedScale(15),size.height-cFixedScale(10));
	s3.position = ccp(size.width-cFixedScale(15),size.height-cFixedScale(10));
	
	[self addChild:s1 z:5000 tag:5001];
	[self addChild:s2 z:5000 tag:5002];
	[self addChild:s3 z:5000 tag:5003];
	
	[self updateSpeedBtns];
	
}

-(void)hideSpeedBtns{
	[self removeChildByTag:5001 cleanup:YES];
	[self removeChildByTag:5002 cleanup:YES];
	[self removeChildByTag:5003 cleanup:YES];
}

-(void)loadPlayerSpeedLevel{
	
	for(int i=0;i<FIGHT_SPEED_MAX_COUNT;i++){
		speed_settings[i] = 0.8f;
	}
	
	NSDictionary * config = [[GameDB shared] getGlobalConfig];
	if([config objectForKey:@"fightSpeeds"]){
		
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
		int playerId = [[playerInfo objectForKey:@"id"] intValue];
		int vipLevel = [[playerInfo objectForKey:@"vip"] intValue];
		int total = 0;
		
		NSDictionary * speeds = getFormatToDict([config objectForKey:@"fightSpeeds"]);
		for(NSString * key in speeds){
			float speed = [[speeds objectForKey:key] floatValue];
			speed_settings[total] = speed;
			if(vipLevel>=[key intValue]) speed_max_index = total;
			total++;
			if(total>=FIGHT_SPEED_MAX_COUNT) break;
		}
		speed_index = [defaults integerForKey:[NSString stringWithFormat:@"fight_speed_%d",playerId]];
		if(speed_index>speed_max_index) speed_index = speed_max_index;
		fight_speed = speed_settings[speed_index];
	}
	
}
//fix chao
-(BOOL)isEndPlay{
    return isEndPlay;
}
-(void)showSpeedTextWithPosition:(CGPoint)pos{
    int fontSize = 20;
    int lineHeight = 22;
    int width = 230;
    if (iPhoneRuningOnGame()) {
        fontSize = 18;
        lineHeight = 20;
        width = 200;
    }
    CCSprite * draw = drawString(NSLocalizedString(@"fight_add_speed",nil),
                                 CGSizeMake(width, 0),
                                 getCommonFontName(FONT_1),
                                 fontSize, lineHeight, @"#EBE2D0");
    [InfoAlert show:self
         drawSprite:draw
             parent:self
           position:pos
        anchorPoint:ccp(1.0f, 1.0f)
             offset:CGSizeMake(cFixedScale(15), cFixedScale(15))
     ];
}
-(void)didGetNotVIPSpeed:(NSDictionary*)sender :(NSDictionary*)_data{
    if (checkResponseStatus(sender)) {
        NSDictionary *data = getResponseData(sender);
        int count = 0;
        int showCout = 0;
		if ([data objectForKey:@"FSpeedNum"]) {
			count = [[data objectForKey:@"FSpeedNum"] intValue];
            NSDictionary *vip_dict = [[GameConfigure shared] getVipConfig];
            showCout = [[vip_dict objectForKey:@"FSpeedNum"] intValue];
            NSMutableDictionary *vip_mut_dict = [NSMutableDictionary dictionaryWithDictionary:vip_dict];
            [vip_mut_dict setObject:[NSNumber numberWithInt:count] forKey:@"FSpeedNum"];
            [[GameConfigure shared] updateVipConfig:vip_mut_dict];
		}
        int x_ = [[_data objectForKey:@"x"] intValue];
        int y_ = [[_data objectForKey:@"y"] intValue];
        //int w_ = [[_data objectForKey:@"w"] intValue];
        int h_ = [[_data objectForKey:@"h"] intValue];
        
        if (count>=0 && showCout>0) {
            if ([_data objectForKey:@"speed"]) {
                BOOL isSetSpeed = NO;
                for (int i = 0 ;i<FIGHT_SPEED_MAX_COUNT; i++) {
                    if (speed_settings[i] == [[_data objectForKey:@"speed"] floatValue]) {
                        speed_index = i;
                        //
                        //[self addTimesSprite:ccp(x_,y_) times:count+1];
                        [self addTimesSprite:ccp(x_,y_) times:showCout];
                        isSetSpeed = YES;
                    }
                }
                if (isSetSpeed == NO) {
                    speed_index=0;
                }
            }else{
                speed_index=0;
            }
            
            fight_speed = speed_settings[speed_index];
            
            NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            int playerId = [[playerInfo objectForKey:@"id"] intValue];
            [defaults setInteger:speed_index forKey:[NSString stringWithFormat:@"fight_speed_%d",playerId]];
            [defaults synchronize];
            
            [self updateSpeedBtns];
            
            [group1 updateSpeed];
            [group2 updateSpeed];
        }else{
            [self showSpeedTextWithPosition:ccp(x_, y_-h_-cFixedScale(10))];
        }
    }else {
		CCLOG(@"get not vip speed faild");
        [ShowItem showErrorAct:getResponseMessage(sender)];
	}
}
-(void)doFreeSpeed:(CCNode*)sender speed:(float)speed_{
    if (speed_index>speed_max_index) {
        speed_index = 0;
        fight_speed = speed_settings[speed_index];
        
        NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        int playerId = [[playerInfo objectForKey:@"id"] intValue];
        [defaults setInteger:speed_index forKey:[NSString stringWithFormat:@"fight_speed_%d",playerId]];
        [defaults synchronize];
        
        [self updateSpeedBtns];
        
        [group1 updateSpeed];
        [group2 updateSpeed];
    }else{
        if (speed_>0) {
            NSMutableDictionary *s_dict = [NSMutableDictionary dictionary];
            [s_dict setObject:[NSNumber numberWithFloat:speed_] forKey:@"mul"];
            //
            NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
            [data_dict setObject:[NSNumber numberWithInt:sender.position.x] forKey:@"x"];
            [data_dict setObject:[NSNumber numberWithInt:sender.position.y] forKey:@"y"];
            [data_dict setObject:[NSNumber numberWithInt:sender.contentSize.width] forKey:@"w"];
            [data_dict setObject:[NSNumber numberWithInt:sender.contentSize.height] forKey:@"h"];
            [data_dict setObject:[NSNumber numberWithFloat:speed_] forKey:@"speed"];
            [GameConnection request:@"speedUp" data:s_dict target:self call:@selector(didGetNotVIPSpeed::) arg:data_dict];
        }
    }
}
-(void)addTimesSprite:(CGPoint)pos times:(int)times_{
    [self hideTimesSprite];
    //
    CCSprite *freebg=[CCSprite spriteWithFile:@"images/ui/timebox/freetime_bg.png"];
    [freebg setPosition:pos];
    [self addChild:freebg];
    freebg.tag = 6003;
    CCLabelTTF *free_time_str=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",times_]  fontName:getCommonFontName(FONT_1) fontSize:9];
    [free_time_str setPosition:ccp(freebg.contentSize.width/2,freebg.contentSize.height/2)];
    [freebg addChild:free_time_str];
}
-(void)hideTimesSprite{
    [self removeChildByTag:6003 cleanup:YES];
}
//end
-(void)doSpeed:(CCNode*)sender{
    //
	[self hideTimesSprite];
    //
    NSDictionary *dict = [[GameConfigure shared] getVipConfig];
    //if(speed_max_index==0){
	if(dict && [[dict objectForKey:@"FSpeedNum"] intValue]>0 && speed_max_index==speed_index){
		//fix chao
        /*
		int fontSize = 20;
		int lineHeight = 22;
		int width = 230;
		if (iPhoneRuningOnGame()) {
			fontSize = 18;
			lineHeight = 20;
			width = 200;
		}

		CCSprite * draw = drawString(@"1.|vip1#ff0000#20#0|开启加速功能|*|2.|vip4#ffff00#20#0|开启2x加速",
									 CGSizeMake(width, 0),
									 getCommonFontName(FONT_1),
									 fontSize, lineHeight, @"#EBE2D0");
		[InfoAlert show:self
			 drawSprite:draw
				 parent:self
			   position:ccp(sender.position.x, sender.position.y-sender.contentSize.height-cFixedScale(10))
			anchorPoint:ccp(1.0f, 1.0f)
				 offset:CGSizeMake(cFixedScale(15), cFixedScale(15))
		 ];
         */
        
        if (speed_index>speed_max_index) {
            speed_index = 0;
            fight_speed = speed_settings[speed_index];
            
            NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            int playerId = [[playerInfo objectForKey:@"id"] intValue];
            [defaults setInteger:speed_index forKey:[NSString stringWithFormat:@"fight_speed_%d",playerId]];
            [defaults synchronize];
            
            [self updateSpeedBtns];
            
            [group1 updateSpeed];
            [group2 updateSpeed];
        }else{
            int index_ = 0;
            index_ = speed_max_index+1;
            if (index_ < FIGHT_SPEED_MAX_COUNT ) {
                [self doFreeSpeed:sender speed:speed_settings[index_]];
            }else{
                CCLOG(@"speed array error");
            }
        }
        //end
		return;
	}else if(speed_max_index==0 ){
        [self showSpeedTextWithPosition:ccp(sender.position.x, sender.position.y-sender.contentSize.height-cFixedScale(10))];
    }
    
	speed_index++;
	if(speed_index>speed_max_index){
		speed_index = 0;
	}
	
	fight_speed = speed_settings[speed_index];
	
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	int playerId = [[playerInfo objectForKey:@"id"] intValue];
	[defaults setInteger:speed_index forKey:[NSString stringWithFormat:@"fight_speed_%d",playerId]];
	[defaults synchronize];
	
	[self updateSpeedBtns];
	
	[group1 updateSpeed];
	[group2 updateSpeed];
	
}

-(void)updateSpeedBtns{
	CCNode * s1 = [self getChildByTag:5001];
	CCNode * s2 = [self getChildByTag:5002];
	CCNode * s3 = [self getChildByTag:5003];
	s1.visible = NO;
	s2.visible = NO;
	s3.visible = NO;
	if(fight_speed==speed_settings[0]) s1.visible = YES;
	if(fight_speed==speed_settings[1]) s2.visible = YES;
	if(fight_speed==speed_settings[2]) s3.visible = YES;
}

-(void)setTimer:(float)time action:(SEL)action{
	FightTimer * timer = [FightTimer timer:time target:self action:action];
	[todoTimers addObject:timer];
	[timer release];
}

-(void)setTimer:(float)time target:(id)target action:(SEL)action{
	FightTimer * timer = [FightTimer timer:time target:target action:action];
	[todoTimers addObject:timer];
	[timer release];
}

-(void)checkTimer:(ccTime)time{
	
	for(FightTimer * timer in todoTimers){
		[timer check:time];
		if(timer.isFire){
			if(overTimers) [overTimers addObject:timer];
		}
	}
	
	if(overTimers){
		if([overTimers count]>0){
			[todoTimers removeObjectsInArray:overTimers];
			[overTimers removeAllObjects];
		}
	}
	//fix chao
	//[self updateTargetCharacterInfo];
    //end
}

-(void)onExit{
	
	CCLOG(@"FightPlayer onExit");
	
	[self unschedule:@selector(checkTimer:)];
	
	if(todoTimers){
		[todoTimers release];
		todoTimers = nil;
	}
	if(overTimers){
		[overTimers release];
		overTimers = nil;
	}
	
	if(original){
		[original release];
		original = nil;
	}
	if(endString){
		[endString release];
		endString = nil;
	}
	
	[self cleanFightData];
	
	[self removeAllChildrenWithCleanup:YES];
    [GameConnection freeRequest:self];
	[super onExit];
}

-(void)cleanFightData{
	
	if(fightAry){
		[fightAry release];
		fightAry = nil;
	}
	
	if(group1){
		[group1 release];
		group1 = nil;
	}
	if(group2){
		[group2 release];
		group2 = nil;
	}
	
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)showBG:(NSString*)file{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CCSprite * bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/fight/fbg/%@.png",file]];
	bg.anchorPoint = ccp(0.5,0.5);
	bg.position = ccp(winSize.width/2,winSize.height/2);
	bg.scale = (winSize.width/bg.contentSize.width);
	
	[self addChild:bg z:-100];
}

-(void)showParticle:(NSString*)parname{
	
	if(!parname) return;
	
	//NSString *parpath=[NSString stringWithFormat:@"images/fight/fbg/%@",parname];
	NSString *parpath=[NSString stringWithFormat:@"images/fight/particles/%@",parname];
	
	if(checkHasFile([[CCFileUtils sharedFileUtils]fullPathFromRelativePath:parpath])){
		CCParticleSystem *par=[CCParticleSystemQuad particleWithFile:parpath];
		if(iPhoneRuningOnGame()){
			par.speed=cFixedScale(par.speed);
			[par setPosition:ccp(cFixedScale(par.position.x),cFixedScale(par.position.y))];
			[par setPosVar:ccp(cFixedScale(par.position.x), 0)];
			
			par.startSize=cFixedScale(par.startSize);
			par.endSize=cFixedScale(par.endSize);
			
			par.totalParticles=cFixedScale(par.totalParticles);
			
		}
		[self addChild:par z:10000];
		
	}
}


-(void)showMusic:(int)m{
	if(m==Fight_member_type_boss){
		[[GameSoundManager shared] playFightBossBackgroundMusic];
	}else{
		[[GameSoundManager shared] playFightBackgroundMusic];
	}
}

-(void)showFid:(int)fid{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CCLabelTTF * label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"FID:%d",fid]
											fontName:getCommonFontName(FONT_1)
											fontSize:20];
	label.anchorPoint = ccp(1,1);
	label.position = ccp(size.width-20,size.height-10);
	label.color = ccYELLOW;
	[self addChild:label z:INT32_MAX];
}

-(void)play:(NSDictionary*)info{
	
	original = [[NSDictionary alloc] initWithDictionary:info];
	
	//TODO check download resources
	GameLoaderHelper * helper = nil;
	NSMutableArray * helpers = [NSMutableArray array];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_fight_bg
													 target:[original objectForKey:@"a"]];
	path = [NSString stringWithFormat:@"%@.png",path];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		[helpers addObject:helper];
	}
	
	NSString * t1 = [original objectForKey:@"1"];
	NSString * t2 = [original objectForKey:@"2"];
	NSArray * ary1 = [t1 componentsSeparatedByString:@"="];
	NSArray * ary2 = [t2 componentsSeparatedByString:@"="];
	
	NSMutableArray * rs = [NSMutableArray array];
	[rs addObjectsFromArray:[[ary1 objectAtIndex:1] componentsSeparatedByString:@"|"]];
	[rs addObjectsFromArray:[[ary2 objectAtIndex:1] componentsSeparatedByString:@"|"]];
	
	for(NSString * r in rs){
		NSArray * t = [r componentsSeparatedByString:@":"];
		
		int target_id = [[t objectAtIndex:8] intValue];
		NSString * name = [t objectAtIndex:1];
		
		//load role ani
		path = [GameResourceLoader getFilePathByType:PathType_fight_role target:name];
		int suit_id = [[t objectAtIndex:15] intValue];
		if(suit_id>0 && target_id<=6){
			name = [NSString stringWithFormat:@"%@_%d",name,suit_id];
			path = [GameResourceLoader getFilePathByType:PathType_fight_role target:name];
		}
		if(![CCFileUtils hasFilePathByTarget:path]){
			path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
			helper = [GameLoaderHelper create:path isUnzip:YES];
			helper.type = PathType_fight_role;
			[helpers addObject:helper];
		}
		
		
		//load role skill effects
		int show_skl_id = [[t objectAtIndex:12] intValue];
		int eff_atk_id = 0;
		int eff_skl_id = 0;
		
		if([t count]>17){
			eff_atk_id = [[t objectAtIndex:16] intValue];
			eff_skl_id = [[t objectAtIndex:17] intValue];
		}
	
		if(show_skl_id){
			name = [NSString stringWithFormat:@"skilltxt%d.png",show_skl_id];
			path = [GameResourceLoader getFilePathByType:PathType_fight_sname target:name];
			if(![CCFileUtils hasFilePathByTarget:path]){
				helper = [GameLoaderHelper create:path];
				helper.type = PathType_fight_sname;
				[helpers addObject:helper];
			}
		}
		
		if(eff_atk_id>0){
			name = [NSString stringWithFormat:@"%d",eff_atk_id];
			path = [GameResourceLoader getFilePathByType:PathType_fight_effects target:name];
			if(![CCFileUtils hasFilePathByTarget:path]){
				path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
				helper = [GameLoaderHelper create:path isUnzip:YES];
				helper.type = PathType_fight_effects;
				[helpers addObject:helper];
			}
		}
		if(eff_skl_id>0){
			name = [NSString stringWithFormat:@"%d",eff_skl_id];
			path = [GameResourceLoader getFilePathByType:PathType_fight_effects target:name];
			if(![CCFileUtils hasFilePathByTarget:path]){
				path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
				helper = [GameLoaderHelper create:path isUnzip:YES];
				helper.type = PathType_fight_effects;
				[helpers addObject:helper];
			}
		}
		
	}
	
	if([helpers count]==0){
		//[self play];
		[self scheduleOnce:@selector(play) delay:0.1f];
	}else{
		for(GameLoaderHelper * helper in helpers){
			helper.target = self;
			helper.call = @selector(play);
			helper.isPostLoading = YES;
			[helper bondOthers:helpers];
		}
		
		[[GameResourceLoader shared] syncDownloadHelpers:helpers];
	}
	
}

-(void)play{
	
	isEndPlay = NO;
	
	[self showSpeedBtns];
	
	[self showBG:[original objectForKey:@"a"]];
	[self showParticle:[original objectForKey:@"p"]];
	
	CCLOG(@"%@",[original objectForKey:@"a"]);
	[self showMusic:[[original objectForKey:@"c"] intValue]];
	//[self showFid:[[original objectForKey:@"b"] intValue]];
	
	group1 = [[FightGroup alloc] init];
	group2 = [[FightGroup alloc] init];
	group1.player = self;
	group2.player = self;
	group1.targetGroup = group2;
	group2.targetGroup = group1;
	
	[group1 setGroupInfo:[original objectForKey:@"1"]];
	[group2 setGroupInfo:[original objectForKey:@"2"]];
	[group1 setGroupTeam:[original objectForKey:@"1"]];
	[group2 setGroupTeam:[original objectForKey:@"2"]];
	
	if([group1 isCurrentUser]){
		CCLOG(@"sdfsf");
	}
	if([group2 isCurrentUser]){
		CCLOG(@"sdfsf");
	}
	
	NSString * str = [original objectForKey:@"f"];
	NSArray * ary = [str componentsSeparatedByString:@"|"];
	fightAry = [[NSMutableArray alloc] initWithArray:ary];
	
	[self scheduleOnce:@selector(doPlayEffect) delay:0.15f];
	
}

-(void)doPlayEffect{
	
	[[GameLoading share]showFightLoadingStep2Target:[FightPlayer shared]
											   call:@selector(startPlayFight)];
	/*
	 [[GameLoading share] showEffect:@"images/fight/into/"
	 target:[FightPlayer shared]
	 call:@selector(startPlayFight)];
	 */
}

-(void)startPlayFight{
	[self scheduleOnce:@selector(doStartPlayerFight) delay:0.01f];
}

-(void)doStartPlayerFight{
	
	[FightManager cleanMemory];
	
	[self scheduleOnce:@selector(actionFight) delay:0.02f];
	//[self setTimer:1.5f action:@selector(endActionFight)];
	
}

-(void)actionFight{
	
	if(![FightManager shared].isPlay){
		//TODO block play by other event
		return;
	}
	
	if(parentAction==Fight_Action_Log_Type_hp			||
	   parentAction==Fight_Action_Log_Type_power		||
	   //parentAction==Fight_Action_Log_Type_die			||
	   parentAction==Fight_Action_Log_Type_ready_skill	||
	   parentAction==Fight_Action_Log_Type_remove_skill	||
	   
	   parentAction==Fight_Action_Log_Type_atk	||
	   parentAction==Fight_Action_Log_Type_skl	||
	   
	   parentAction==Fight_Action_Log_Type_add	||
	   parentAction==Fight_Action_Log_Type_bok	||
	   parentAction==Fight_Action_Log_Type_cob	||
	   parentAction==Fight_Action_Log_Type_cot	||
	   parentAction==Fight_Action_Log_Type_cpr	||
	   parentAction==Fight_Action_Log_Type_mis	||
	   parentAction==Fight_Action_Log_Type_pen	||
	   
	   parentAction==Fight_Action_Log_Type_addStatus	||
	   parentAction==Fight_Action_Log_Type_removeStatus ||
	   
	   //parentAction==Fight_Action_Log_Type_move ||
	   //parentAction==Fight_Action_Log_Type_back ||
	   
	   parentAction==Fight_Action_Log_Type_effect_single	||
	   parentAction==Fight_Action_Log_Type_effect_all		||
	   
	   parentAction==Fight_Action_Log_Type_round ||
	   
	   NO){
		
		[self setTimer:0.002f action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:0.002f
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}else if (parentAction==Fight_Action_Log_Type_move	||
			  parentAction==Fight_Action_Log_Type_back	||
			  parentAction==Fight_Action_Log_Type_die	||
			  NO ){
		
		[self setTimer:[FightPlayer checkTime:0.1f] action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:0.1f
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}else if (parentAction==Fight_Action_Log_Type_end){
		
		[self setTimer:[FightPlayer checkTime:1.0f] action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:1.0f
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}else{
		[self setTimer:[FightPlayer checkTime:0.5f] action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:0.5f
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}
	
	
}

-(void)doActionFight{
	
	if([fightAry count]<=0) return;
	
	NSString * str = [NSString stringWithString:[fightAry objectAtIndex:0]];
	[fightAry removeObjectAtIndex:0];
	
	CCLOG(@" doActionFight -> %@",str);
	
	parentAction = [valueFromSort(str,0) intValue];
	
	/*
	 FightCharacter * actioner = [self getTargetCharacter:valueFromSort(str,1)];
	 if(parentAction==Fight_Action_Log_Type_hp){
	 int cut = [valueFromSort(str,2) intValue];
	 int chp = [valueFromSort(str,3) intValue];
	 BOOL isBok = [valueFromSort(str,4) boolValue];
	 BOOL isCpr = [valueFromSort(str,5) boolValue];
	 [actioner cutHP:cut currentHP:chp isBok:isBok isCpr:isCpr];
	 }else if(parentAction==Fight_Action_Log_Type_power){
	 int pwoer = [valueFromSort(str,2) intValue];
	 [actioner showPower:pwoer];
	 }else if(parentAction==Fight_Action_Log_Type_die){
	 [actioner showDie];
	 }else if(parentAction==Fight_Action_Log_Type_ready_skill){
	 [actioner showReadySkill];
	 }
	 
	 if(parentAction==Fight_Action_Log_Type_move){
	 FightCharacter * target = [self getTargetCharacter:valueFromSort(str,2)];
	 [actioner moveTo:target];
	 }else if(parentAction==Fight_Action_Log_Type_back){
	 [actioner goBack];
	 }
	 
	 if(parentAction==Fight_Action_Log_Type_atk){
	 [actioner showAttack];
	 }else if(parentAction==Fight_Action_Log_Type_skl){
	 [actioner showSkill];
	 }
	 
	 if(parentAction==Fight_Action_Log_Type_add) [actioner showEffectAdd];
	 if(parentAction==Fight_Action_Log_Type_bok) [actioner showEffectBok];
	 if(parentAction==Fight_Action_Log_Type_cob) [actioner showEffectCob];
	 if(parentAction==Fight_Action_Log_Type_cot) [actioner showEffectCot];
	 if(parentAction==Fight_Action_Log_Type_cpr) [actioner showEffectCpr];
	 if(parentAction==Fight_Action_Log_Type_mis) [actioner showEffectMis];
	 if(parentAction==Fight_Action_Log_Type_pen) [actioner showEffectPen];
	 
	 if(parentAction==Fight_Action_Log_Type_addStatus){
	 [actioner addStatus:[valueFromSort(str,2) intValue]
	 index:[valueFromSort(str,3) intValue]
	 effect:valueFromSort(str,4)
	 ];
	 }else if(parentAction==Fight_Action_Log_Type_updateStatus){
	 [actioner updateStatus:[valueFromSort(str,2) intValue]
	 index:[valueFromSort(str,3) intValue]];
	 }else if(parentAction==Fight_Action_Log_Type_removeStatus){
	 [actioner removeStatus:[valueFromSort(str,2) intValue]
	 index:[valueFromSort(str,3) intValue]];
	 }
	 
	 if(parentAction==Fight_Action_Log_Type_effect_single){
	 [actioner showEffect:[valueFromSort(str,2) intValue]];
	 }
	 */
	
	if(parentAction==Fight_Action_Log_Type_effect_all){
		FightGroup * group = [self getFightGroupById:[valueFromSort(str,1) intValue]];
		[group showEffect:[valueFromSort(str,2) intValue]
				   offset:[valueFromSort(str,3) intValue]
		 ];
		return;
	}
	
	if(parentAction==Fight_Action_Log_Type_round){
		[self setTimer:0.5f action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:0.5f
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}
	
	if(parentAction==Fight_Action_Log_Type_delay){
		float time = [valueFromSort(str,1) floatValue];
		
		[self setTimer:time action:@selector(doActionFight)];
		/*
		 [NSTimer scheduledTimerWithTimeInterval:time
		 target:self
		 selector:@selector(doActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		return;
	}
	
	if(parentAction==Fight_Action_Log_Type_end){
		
		endString = [NSString stringWithString:str];
		[endString retain];
		
		[self setTimer:1.5f action:@selector(endActionFight)];
		
		/*
		 [NSTimer scheduledTimerWithTimeInterval:1.5
		 target:self
		 selector:@selector(endActionFight)
		 userInfo:nil
		 repeats:NO];
		 */
		
		return;
	}
	
	FightCharacter * actioner = [self getTargetCharacter:valueFromSort(str,1)];
	if(!actioner.isDie){
		[actioner action:str];
	}else{
		[self actionFight];
	}
	
}

-(void)endActionFight{
	
	int windGid = 1;
	BOOL isShow = 1;
	
	if(endString){
		NSString * str = [NSString stringWithString:endString];
		[endString release];
		endString = nil;
		
		windGid = [valueFromSort(str,1) intValue];
		isShow = [valueFromSort(str,2) boolValue];
	}
	
	[self endActionFight:windGid isShow:isShow];
	
	isEndPlay = YES;
    //fix chao
	//[self hideInfo];
    if (group1) {
        [group1 hideInfo];
    }
    if (group2) {
        [group2 hideInfo];
    }
    //end
}

-(void)endActionFight:(int)winGroupId isShow:(BOOL)isShow{
	
	[FightManager cleanMemory];
	
	[[GameSoundManager shared] stopBackgroundMusic];
	
	BOOL userIsWin = NO;
	if(group1.groupId==winGroupId && group1.isCurrentUser){
		userIsWin = NO;
	}
	if(group2.groupId==winGroupId && group2.isCurrentUser){
		userIsWin = YES;
	}
	
	//TODO
	//userIsWin = YES;
	
	if(userIsWin){
		//TODO show winer message
		
		[FightManager shared].isWin = YES;
		[[GameSoundManager shared] playWiner];
		
	}else{
		//TODO show loseer message
		
		[FightManager shared].isWin = NO;
	}
	
	if ([FightManager shared].fightId == 3) {
        if (!([FightManager getFightType]==Fight_Type_dragon_npc ||
              [FightManager getFightType]==Fight_Type_dragon_player)) {
            [FightManager shared].isWin = YES;
        }
		
	}
	
	if(isShow){
		
		//show result win...
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/fight/fightBg.png"];
		bg.anchorPoint = ccp(0.5f,0.5f);
		[self addChild:bg z:10001 tag:10001];
		
		CCMenu * menu = [CCMenu node];
		[self addChild:menu z:10002 tag:10002];
		
		if(iPhoneRuningOnGame()){
			bg.position = ccp(size.width/2,size.height/2+25);
			menu.position = ccp(size.width/2,size.height/2+25);
		}else{
			bg.position = ccp(size.width/2,size.height/2+50);
			menu.position = ccp(size.width/2,size.height/2+50);
		}
		
		
		//end
		if (userIsWin) {
			//-----------------------------------------------------------------------
			CCSprite *spr1 = [CCSprite spriteWithFile:@"images/ui/fight/winner.png"];
			spr1.anchorPoint=ccp(0.5, 1.0);
			[bg addChild:spr1];
			spr1.position=ccp(bg.contentSize.width/2, bg.contentSize.height);
			
			//-----------------------------------------------------------------------
			//fix chao
			//NSArray * btns = getBtnSprite(@"images/ui/fight/bt_sure.png");
			NSArray * btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_ok");
			//end
			CCMenuItemImage * item1 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doBack)];
			
			btns = getBtnSprite(@"images/ui/fight/bt_view.png");
			CCMenuItemImage * item2 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doReplay)];
			
			/*
			 btns = getBtnSprite(@"images/ui/fight/bt_send.png");
			 CCMenuItemImage * item3 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
			 selectedSprite:[btns objectAtIndex:1]
			 target:self
			 selector:@selector(doSend)];
			 */
			
			if(iPhoneRuningOnGame()){
				item1.scale=1.3f;
				item2.scale=1.3f;
				item1.position = ccp(0,-40);
				item2.position = ccp(120,-40);
				//item3.position = ccp(110, -40);
			}else{
				item1.position = ccp(0,-80);
				item2.position = ccp(160,-80);
				//item3.position = ccp(220, -80);
			}
			
			[menu addChild:item1];
			[menu addChild:item2 z:1 tag:10001];
			//[menu addChild:item3];
			
			//fix chao 初,1序章不显示
			if ( [[GameConfigure shared] isPlayerOnOneOrChapter] ||
                [FightManager getFightType]==Fight_Type_dragon_npc ||
                [FightManager getFightType]==Fight_Type_dragon_player) {
				item2.visible = NO;
				//item3.visible = NO;
			}
			//end
			
			if ([FightManager getFightType] == Fight_Type_pve) {
				item2.visible = NO;
				//item3.visible = NO;
			}
			if([FightManager getFightType]==Fight_Type_normal){
				//to do 服务器分支没有接口
				[GameConnection request:@"fightWin" format:[NSString stringWithFormat:@"fid::%i",[FightManager shared].fightId] target:self call:@selector(didFigthReward:)];
				item2.visible=NO;
			}
			//CCLOG(@"reward :%@",[[GameDB shared]getRewardInfo:rid]);
			/*
			 NSDictionary *dict = [[GameDB shared] getRewardInfo:rid];
			 if(dict){
			 CCLOG([dict description]);
			 NSError * error = nil;
			 NSData * data = getDataFromString([dict objectForKey:@"reward"]);
			 NSDictionary * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
			 if(!error){
			 for(NSDictionary * reward in rewards){
			 NSString * t = [reward objectForKey:@"t"];
			 int i = [[reward objectForKey:@"i"] intValue];
			 int c = [[reward objectForKey:@"c"] intValue];
			 if(t != nil && [t isEqualToString:@"i"] && i<=6){
			 //经验
			 if (i == 4) {
			 //exp = c ;
			 }
			 }
			 }
			 }
			 }
			 */
			
			
		}
		else {
			/*
			 Fight_Type_normal	= 1,
			 Fight_Type_abyss	= 2,
			 Fight_Type_custom	= 3,
			 Fight_Type_pk		= 4,
			 Fight_Type_record	= 5,
			 */
			CCLOG(@"%i",[FightManager getFightType]);
			//-----------------------------------------------------------------------
			CCSprite *spr1 = [CCSprite spriteWithFile:@"images/ui/fight/defeated.png"];
			spr1.anchorPoint=ccp(0.5, 1);
			[bg addChild:spr1];
			spr1.position=ccp(bg.contentSize.width/2, bg.contentSize.height);
			//-----------------------------------------------------------------------
			//fix chao
			//NSArray * btns = getBtnSprite(@"images/ui/fight/bt_again.png");
			NSArray * btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_again");
			//end
			CCMenuItemImage * item1 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doFightAgain)];
			//fix chao
			//btns = getBtnSprite(@"images/ui/fight/bt_exit.png");
			if ( [FightManager getFightType]==Fight_Type_dragon_npc ||
                [FightManager getFightType]==Fight_Type_dragon_player ) {
                btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_ok");
            }else{
                btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_exit");
            }
			//end
			CCMenuItemImage * item2 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doBack)];
			//fix chao
			//btns = getBtnSprite(@"images/ui/fight/bt_send.png");
			btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_send");
			//end
			CCMenuItemImage * item3 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doSend)];
			//fix chao
			//btns = getBtnSprite(@"images/ui/fight/bt_view.png");
			btns = getBtnSpriteWithStatus(@"images/ui/fight/bt_view");
			//end
			CCMenuItemImage * item4 = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(doReplay)];
			
			item1.anchorPoint = ccp(1.0, 0.5);
			item2.anchorPoint = ccp(0, 0.5);
			item4.anchorPoint = ccp(0, 0.5);
			item3.anchorPoint = ccp(0, 0.5);
			
			if(iPhoneRuningOnGame()){
				item1.scale=1.3f;
				item2.scale=1.3f;
				item3.scale=1.3f;
				item4.scale=1.3f;
//				item1.position = ccp(-30,-40);
//				item2.position = ccp(-30,-40);
//				item4.position = ccp(10+item2.contentSize.width -5, -40);
//				item3.position =ccp(10*3+item2.contentSize.width + item4.contentSize.width,  -40);
				item1.position = ccp(-15,-40);
				item2.position = ccp(5,-40);
				item4.position = ccp(10+item2.contentSize.width + 45, -40);
				item3.position =ccp(5*3+item2.contentSize.width + item4.contentSize.width,  -40);
			}else{
				item1.position = ccp(-10,-80);
				item2.position = ccp(10,-80);
				item4.position = ccp(10+item2.contentSize.width + 10, -80);
				item3.position =ccp(10*3+item2.contentSize.width + item4.contentSize.width,  -80);
			}
			//TODO 功能暂时还未实现，先隐藏
			item3.visible=NO;
			
			[menu addChild:item1];
			[menu addChild:item2];
			[menu addChild:item3];
			[menu addChild:item4];
			//fix chao 初,1序章不显示
			if ( [[GameConfigure shared] isPlayerOnOneOrChapter]) {
				item3.visible = NO;
				item4.visible = NO;
			}
			//end
			
			if ([FightManager getFightType] == Fight_Type_pve) {
				item3.visible = NO;
				item4.visible = NO;
			}
			if([FightManager getFightType]==Fight_Type_pk ||
			   [FightManager getFightType]==Fight_Type_bossFight ||
               [FightManager getFightType]==Fight_Type_team ||
               [FightManager getFightType]==Fight_Type_record ||
               [FightManager getFightType]==Fight_Type_dragon_npc ||
               [FightManager getFightType]==Fight_Type_dragon_player){
				item1.visible=NO;
				item3.visible=NO;
				
				[item2 setPosition:ccp(cFixedScale(-60), item2.position.y)];
				
				//Kevin added
				if (iPhoneRuningOnGame()) {
					item2.position = ccpAdd(item2.position, ccp(-20, 0));
				}
				//-------------------------------//
				
				item4.visible=NO;
			}
			int indextips=[[NSString stringWithFormat:@"%0f",CCRANDOM_0_1()*21] integerValue] ;
			NSDictionary *figthtips=[[GameDB shared] getFightTips:indextips];
			NSString *tipsstr=[figthtips objectForKey:@"info"];
			float fontSize=16;
			float lineHeight=20;
			if (iPhoneRuningOnGame()) {
				fontSize=20;
				lineHeight=24;
			}
			CCSprite *tips=drawString(tipsstr, CGSizeMake(600, 30), getCommonFontName(FONT_1), fontSize, lineHeight, @"ffff00");
			[tips setPosition:ccp(bg.contentSize.width/2, cFixedScale(90))];
			[bg addChild:tips];
		}
	}else{
		[self scheduleOnce:@selector(doBack) delay:0.2f];
		//[self doBack];
	}
	
}

-(void)didFigthReward:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		//NSString *rewardstr=@"获得";
		NSString *rewardstr=NSLocalizedString(@"fight_get",nil);
		NSDictionary *data=getResponseData(response);
		
		if(data){
			//NSString *mstr[5]={@"银币",@"元宝",@"绑元宝",@"炼历",@"经验"};
			NSString *mstr[5]={
				NSLocalizedString(@"fight_coin1",nil),
				NSLocalizedString(@"fight_coin2",nil),
				NSLocalizedString(@"fight_coin3",nil),
				NSLocalizedString(@"fight_train",nil),
				NSLocalizedString(@"fight_exp",nil)};
			NSString *mkey[5]={@"coin1",@"coin2",@"coin3",@"train",@"exp"};
			for(int i=0;i<5;i++){
				int coin=[[data objectForKey:mkey[i]]integerValue];
				int mecoin=[[[[GameConfigure shared]getPlayerInfo] objectForKey:mkey[i]]integerValue];
				if((coin-mecoin)>1){
					rewardstr=[rewardstr stringByAppendingFormat:@"%@",[NSString stringWithFormat:@" %@X%i",mstr[i],coin-mecoin]];
				}
			}
		}
		
		//if(![rewardstr isEqualToString:@"获得"]){
		if(![rewardstr isEqualToString:NSLocalizedString(@"fight_get",nil)]){
			CCSprite *spstr=drawStringForEvent(rewardstr, CGSizeMake(1000, 1), getCommonFontName(FONT_1), 18, 24, @"ffff00");
			[spstr setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2+ cFixedScale(10))];
			[self addChild:spstr z:20000 tag:10003];
			[[GameConfigure shared]updatePackage:data];
		}
		
		//[[self getChildByTag:10002]getChildByTag:10001].visible=YES;
		//fix chao
		CCMenu *menu = (CCMenu *)[self getChildByTag:10002];
		if (menu) {
			CCMenuItem *item2 = (CCMenuItem *)[menu getChildByTag:10001];
			//序章不显示
			if (item2) {
				if ( [[GameConfigure shared] isPlayerOnChapter]) {
					item2.visible=NO;
				}else{
					item2.visible=YES;
				}
			}else{
				CCLOG(@"no bt_view item error");
			}
		}else{
			CCLOG(@"no menu error");
		}
		//end
		CCLOG(@"%@",rewardstr);
		
	}
	
}

-(void)doBack{
	
	[self removeChildByTag:10001 cleanup:YES];
	[self removeChildByTag:10002 cleanup:YES];
	[self removeChildByTag:10003 cleanup:YES];
	[self removeAllChildrenWithCleanup:YES];
	
	[self cleanFightData];
	
	[[FightManager shared] endFight];
	
}
-(void)doReplay{
	
	[self removeChildByTag:10001 cleanup:YES];
	[self removeChildByTag:10002 cleanup:YES];
	[self removeChildByTag:10003 cleanup:YES];
	
	[self cleanFightData];
	
	[GameLoading showFight:@"" target:self call:@selector(play) loading:NO];
	
	//[self play];
	//TDOO
	/*
	 //[self startPlayFight];
	 [[GameLoading share] showEffect:@"images/fight/into/"
	 target:self
	 call:@selector(startPlayFight)];
	 */
	
}

-(void)doSend{
	//TODO tiger
	//发送战斗数据
	
	NSString * fight = [[FightManager shared] getFigthSub];
	CCLOG(@"fight data length : %d",[fight length]);
	CCLOG(fight);
	
}

-(void)doFightAgain{
	[[FightManager shared] fightAgain];
}
//==============================================================================
#pragma mark-
//==============================================================================

-(FightGroup*)getFightGroupById:(int)gid{
	FightGroup * group = group1;
	if(group2.groupId==gid) group = group2;
	return group;
}

-(FightCharacter*)getTargetCharacter:(NSString*)str{
	if([str length]==0) return nil;
	NSArray * ary = [str componentsSeparatedByString:@"."];
	if([ary count]>=2){
		int gid = [[ary objectAtIndex:0] intValue];
		int cid = [[ary objectAtIndex:1] intValue];
		
		FightGroup * group = [self getFightGroupById:gid];
		return [group getCharacterByIndex:cid];
	}
	return nil;
}

-(void)shake{
	
	float time = [FightPlayer checkTime:0.05f];
	NSMutableArray * actions = [NSMutableArray array];
	for(int i=0;i<12;i++){
		int cut = (i%2==0?cFixedScale(6):cFixedScale(-6));
		id action = [CCMoveTo actionWithDuration:time position:ccpAdd(self.position, ccp(cut,0))];
		[actions addObject:action];
	}
	
	id action = [CCMoveTo actionWithDuration:time position:self.position];
	[actions addObject:action];
	
	[self stopAllActions];
	[self runAction:[CCSequence actionWithArray:actions]];
	
}

-(void)showInfo:(FightCharacter*)target{
	//fix chao
    /*
	//if(isEndPlay) return;
	if(target.isDie) return;
	if(targetCharacter==target){
		[self hideInfo];
		return;
	}
	
	if(!characterInfo){
		characterInfo = [CCSprite spriteWithFile:@"images/fight/info/bg.png"];
		characterInfo.anchorPoint = ccp(0.5,1);
		[self addChild:characterInfo z:INT32_MAX];
		
		CCSprite * c1 = [CCSprite spriteWithFile:@"images/fight/info/c1.png"];
		CCSprite * c2 = [CCSprite spriteWithFile:@"images/fight/info/c2.png"];
		
		c1.anchorPoint = ccp(0,0);
		c2.anchorPoint = ccp(0,0);
		
		c1.position = ccp(cFixedScale(58), cFixedScale(56));
		c2.position = ccp(cFixedScale(58), cFixedScale(10));
		
		[characterInfo addChild:c1 z:1];
		[characterInfo addChild:c2 z:1];
		
	}
	
	targetCharacter = target;
	[self updateTargetCharacterInfo];
     */
    [target showInfo];
    //end
	
}
//fix chao
/*
-(void)unboundCharacter:(FightCharacter*)target{
	if(targetCharacter==target){
		[self hideInfo];
	}
}

-(void)updateTargetCharacterInfo{
	if(characterInfo && targetCharacter){
		
		[characterInfo removeChildByTag:1001 cleanup:YES];
		[characterInfo removeChildByTag:1002 cleanup:YES];
		
		characterInfo.position = targetCharacter.position;
		
		float cut_y = (characterInfo.position.y-characterInfo.contentSize.height);
		if(cut_y<0){
			characterInfo.position = ccp(characterInfo.position.x, characterInfo.position.y-cut_y);
		}
		
		float cut_x = (characterInfo.position.x-characterInfo.contentSize.width/2);
		if(cut_x<0){
			characterInfo.position = ccp(characterInfo.position.x-cut_x, characterInfo.position.y);
		}
		
		CGSize winSize = [CCDirector sharedDirector].winSize;
		cut_x = (characterInfo.position.x+characterInfo.contentSize.width/2);
		if(cut_x>winSize.width){
			characterInfo.position = ccp(characterInfo.position.x-(cut_x-winSize.width), characterInfo.position.y);
		}
		
		NSString * s1 = [NSString stringWithFormat:@"%d/%d",targetCharacter.currentHP,targetCharacter.totalHP];
		NSString * s2 = [NSString stringWithFormat:@"%d/%d",targetCharacter.currentPower,targetCharacter.totalPower];
		
		CCSprite * d1 = drawBoundString(s1, 20, GAME_DEF_CHINESE_FONT, 22, ccc3(0, 255, 0), ccWHITE);
		CCSprite * d2 = drawBoundString(s2, 20, GAME_DEF_CHINESE_FONT, 22, ccc3(0, 255, 255), ccWHITE);
		
		d1.position = ccp(cFixedScale(168+d1.contentSize.width/2), cFixedScale(72));
		d2.position = ccp(cFixedScale(168+d2.contentSize.width/2), cFixedScale(26));
		
		[characterInfo addChild:d1 z:2 tag:1001];
		[characterInfo addChild:d2 z:2 tag:1002];
		
	}
}

-(void)hideInfo{
	if(characterInfo){
		[characterInfo removeFromParentAndCleanup:YES];
		characterInfo = nil;
	}
	targetCharacter = nil;
}
 */
//end
#ifdef GAME_DEBUGGER________
#if GAME_DEBUGGER________ == 1

-(BOOL)debug_endActionFight:(id)sender{
	if (group2 && fightAry) {
		//清所有数据
		[fightAry removeAllObjects];
		//必须赢
		[self endActionFight:group2.groupId isShow:YES];
		return YES;
	}
	return NO;
}

#endif
#endif


#pragma mark -

-(void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	touch_distance = 0;
	CCLOG(@"%@",touches);
}
-(void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	if([touches count]>=2){
		isMultiTouch=YES;
		touchCount = [touches count];
		if(touch_distance==0){
			touch_distance = getDistanceByTouchs(touches);
		}
		end_touch_distance=getDistanceByTouchs(touches);
	}
	
}


-(void)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
	
	if(isMultiTouch){
		touchCount -= [touches count];
		if(touchCount==0 && abs(touch_distance-end_touch_distance)>cFixedScale(100)){
			
			CGSize size = [CCDirector sharedDirector].winSize;
			CCNode * s1 = [self getChildByTag:5001];
			CCNode * s2 = [self getChildByTag:5002];
			CCNode * s3 = [self getChildByTag:5003];
			
			//CGPoint point = ccp(s1.position.x, s1.position.y);
			CGPoint point;
			
			if(touch_distance<end_touch_distance){
				//[[GameUI shared] closeUI];
				
				[group1 closeHeadIcon];
				[group2 closeHeadIcon];
				
				point = ccp(size.width+cFixedScale(50),size.height+cFixedScale(50));
				
			}else{
				//[[GameUI shared] openUI];
				[group1 openHeadIcon];
				[group2 openHeadIcon];
				
				point = ccp(size.width-cFixedScale(15),size.height-cFixedScale(10));
				
			}
			
			[s1 stopAllActions];
			[s2 stopAllActions];
			[s3 stopAllActions];
			[s1 runAction:[CCMoveTo actionWithDuration:0.5f position:point]];
			[s2 runAction:[CCMoveTo actionWithDuration:0.5f position:point]];
			[s3 runAction:[CCMoveTo actionWithDuration:0.5f position:point]];
			
			isMultiTouch=NO;
		}
		return;
	}
	
	isMultiTouch=NO;
	touch_distance=0;
	end_touch_distance = 0;
	
}
@end

#pragma mark-
#pragma mark FightTimer

@implementation FightTimer
@synthesize time;
@synthesize target;
@synthesize action;
@synthesize isFire;

+(FightTimer*)timer:(float)time target:(id)target action:(SEL)action{
	FightTimer * timer = [[FightTimer alloc] init];
	timer.time = time;
	timer.target = target;
	timer.action = action;
	return timer;
}

-(id)init{
	if(self=[super init]){
		time = 0;
		atime = 0;
		target = nil;
		action = nil;
		isFire = NO;
	}
	return self;
}

-(void)dealloc{
	//CCLOG(@"FightTimer dealloc");
	[super dealloc];
}

-(void)check:(float)ctime{
	if(!isFire){
		atime += ctime;
		if(atime>=time){
			[self fire];
		}
	}
}

-(void)fire{
	isFire = YES;
	if(target!=nil && action!=nil){
		[target performSelector:action];
		target = nil;
		action = nil;
	}
}

@end