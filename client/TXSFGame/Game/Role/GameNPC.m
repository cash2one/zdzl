//
//  GameNPC.m
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "GameNPC.h"
#import "GameLayer.h"
#import "ActionMove.h"
#import "MapManager.h"
#import "GameConfigure.h"
#import "RoleManager.h"
#import "NPCManager.h"
#import "TaskManager.h"
#import "Config.h"

#import "Window.h"

#import "Game.h"
#import "Task.h"
#import "StageManager.h"
#import "FightManager.h"
#import "GameDB.h"
#import "CCLabelFX.h"
#import "EatFoot.h"
#import "AlertManager.h"
#import "RolePlayer.h"
#import "NpcEffects.h"

#import "RoleOption.h"
#import "DragonFightManager.h"
#import "DragonFightData.h"

@implementation GameNPC
@synthesize npcId;
@synthesize task;
@synthesize direction;
@synthesize call;
@synthesize calltarget;
@synthesize isHasFunc;
@synthesize dir;

@synthesize baseSize;

@synthesize isSelected = _isSelected;
@synthesize isFighting;
@synthesize isFire;

@synthesize isCopyPlayer;

-(void)onEnter{
	
	[super onEnter];
	//调整NPC 优先级
	//[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-56 swallowsTouches:YES];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1 swallowsTouches:YES];
	self.anchorPoint = ccp(0.5,0.5);
	viewer = [AnimationNPC node];
	viewer.anchorPoint = ccp(0.5,0);
	viewer.scaleX = direction;
	[self addChild:viewer z:1];
	
	NSDictionary * npcInfo = [[GameDB shared] getNpcInfo:npcId];
	offset = [[npcInfo objectForKey:@"offset"] intValue];
	if([Game iPhoneRuningOnGame]){
		offset = offset/2;
	}
	viewer.position = ccp(0,-offset);
	
	int res = [[npcInfo objectForKey:@"res"] intValue];
    if (!isCopyPlayer) {
        if(res>0){
            [viewer showAnimationByNPCId:res];
        }else{
            [viewer showAnimationByNPCId:npcId];
        }
    }
    /*
	if(res>0){
		[viewer showAnimationByNPCId:res];
	}else{
		[viewer showAnimationByNPCId:npcId];
	}
	*/
	baseSize = viewer.contentSize;
	
	isShowName = [[npcInfo objectForKey:@"isShowName"] boolValue];
	isDown = [[npcInfo objectForKey:@"isDown"] boolValue];
	isShadow = [[npcInfo objectForKey:@"isshadow"] boolValue];
	
	int tDir = [[npcInfo objectForKey:@"dir"] intValue];
	if(tDir>0 && tDir<10){
		dir = tDir;
	}else{
		dir = NPC_DIR_2;
	}
	
	if(isShadow){
		float scale = [[npcInfo objectForKey:@"body"] floatValue];
		if(scale<=0) scale = 1;
		shadowSpr = [CCSprite spriteWithFile:@"images/shadow.png"];
		shadowSpr.position = self.position;
		shadowSpr.scale = scale;
		[self.parent addChild:shadowSpr z:0 tag:555];
	}
	
	if(!isDown){
		baseSize.height = baseSize.height+viewer.position.y;
		if(self.parent){
			int zz = (GAME_MAP_MAX_Y-self.position.y);
			[self.parent reorderChild:self z:zz];
		}
	}else{
		if(self.parent){
			[self.parent reorderChild:self z:0];
		}
		viewer.anchorPoint = ccp(0.5,0.5);
		viewer.position = ccp(0,0);
	}
	
	if(isShowName){
		NSString * name = [npcInfo objectForKey:@"name"];
		[self showName:name];
	}
	
	isHasFunc = NO;
	if([[npcInfo objectForKey:@"func"] isKindOfClass:[NSString class]]){
		NSString * funcStr = [npcInfo objectForKey:@"func"];
		if([funcStr length]>0){
			NSArray * func = [funcStr componentsSeparatedByString:@":"];
			func_type = [[func objectAtIndex:0] intValue];
			if(func_type>0){
				funcString = [npcInfo objectForKey:@"func"];
				[funcString retain];
				isHasFunc = YES;
			}
		}
	}
	[self showFuncTips];
	bTouchDelay = NO ;
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	if(funcString){
		[funcString release];
		funcString = nil;
	}
	if(shadowSpr){
		[shadowSpr removeFromParentAndCleanup:YES];
		shadowSpr = nil;
	}
	[super onExit];
}
//chao
-(void)changeNPCWithDict:(NSDictionary*)dict{
    //
    if(!viewer){
        return;
    }
    [viewer removeAllChildrenWithCleanup:YES];
    //
	NSDictionary * role = [[GameDB shared] getRoleInfo:[[dict objectForKey:@"rid"] intValue]];
	offset = [[role objectForKey:@"offset"] intValue];
	if([Game iPhoneRuningOnGame]){
		viewer.position = ccp(0,-offset/2);
	}else{
		viewer.position = ccp(0,-offset);
	}
	//[self addChild:viewer z:1];
    //
    [viewer showAnimationByROLEId:[[dict objectForKey:@"rid"] intValue] suitId:[[dict objectForKey:@"eqid"] intValue] dir:dir];
    baseSize = viewer.contentSize;
    isShowName = YES;
    isDown = NO;
    isShadow = YES;

	if(isShadow){
		float scale = [[role objectForKey:@"body"] floatValue];
		if(scale<=0) scale = 1;
        if (!shadowSpr) {
            shadowSpr = [CCSprite spriteWithFile:@"images/shadow.png"];
            shadowSpr.position = self.position;
            [self.parent addChild:shadowSpr z:0 tag:555];
        }
        shadowSpr.scale = scale;
	}
	
	if(!isDown){
		baseSize.height = baseSize.height+viewer.position.y;
		if(self.parent){
			int zz = (GAME_MAP_MAX_Y-self.position.y);
			[self.parent reorderChild:self z:zz];
		}
	}else{
		if(self.parent){
			[self.parent reorderChild:self z:0];
		}
		viewer.anchorPoint = ccp(0.5,0.5);
		viewer.position = ccp(0,0);
	}
	
	if(isShowName){
        [self removeChildByTag:123 cleanup:YES];
        [self showName:[dict objectForKey:@"name"] color:getColorByQuality([[dict objectForKey:@"q"] intValue])];
        CCSprite *label_ = (CCSprite *)[self getChildByTag:123];
        if (label_) {
            int fontsize=16;
            if(iPhoneRuningOnGame()){
                fontsize=20;
            }
            CCSprite *aname_label = drawBoundString([NSString stringWithFormat:@"%@",[dict objectForKey:@"aname"]],
                                                    8,
                                                    GAME_DEF_CHINESE_FONT,
                                                    fontsize,
                                                    ccc3(255, 255, 255), ccBLACK);
            [label_ addChild:aname_label];
            aname_label.anchorPoint = ccp(0.5,0);
            aname_label.position = ccp(label_.contentSize.width/2,label_.contentSize.height);
        }
	}
    
    isHasFunc = NO;
	[self hideFuncTips];
	bTouchDelay = NO ;
}

-(void)setPosition:(CGPoint)position{
	[super setPosition:position];
	if(shadowSpr){
		shadowSpr.position = position;
	}
}

-(void)updateBaseSize{
	
	baseSize = viewer.contentSize;
	if(!isDown){
		baseSize.height = baseSize.height+viewer.position.y;
	}
	
	CCNode * node = [self getChildByTag:123];
	if(node){
		node.position = ccp(0,baseSize.height);
	}
	
	if(alert){
		[self hideAlert];
		[self showAlert];
	}
	
	if(funcTips){
		[self hideFuncTips];
		[self showFuncTips];
	}
	
	if(isBattle){
		[self showBattle];
	}
	if (isFighting) {
		[self showFighting];
	}
	if (isFire) {
		if (fireTotalTime > 0) {
			float percent = fireCurtTime*100.0f/fireTotalTime;
			[self setFirePercent:percent];
		}
	}
}
-(void)showName:(NSString*)name color:(ccColor3B)color{
	
	int fontsize=16;
	if(iPhoneRuningOnGame()){
		fontsize=20;
	}
	CCSprite *name_label = drawBoundString([NSString stringWithFormat:@"%@",name],
										   8,
										   GAME_DEF_CHINESE_FONT,
										   fontsize,
										   color, ccBLACK);
	name_label.anchorPoint = ccp(0.5,0.0);
	name_label.position = ccp(0,baseSize.height);
	[self addChild:name_label z:1 tag:123];
	
}
-(void)showName:(NSString*)name{
	
	int fontsize=16;
	if(iPhoneRuningOnGame()){
		fontsize=20;
	}
	CCSprite *name_label = drawBoundString([NSString stringWithFormat:@"%@",name],
										   8,
										   GAME_DEF_CHINESE_FONT,
										   fontsize,
										   ccc3(255, 250, 00), ccBLACK);
	name_label.anchorPoint = ccp(0.5,0.0);
	name_label.position = ccp(0,baseSize.height);
	[self addChild:name_label z:1 tag:123];
	
}

-(void)setTask:(Task*)target{
	task = target;
	if(task){
		[self showAlert];
	}else{
		[self hideAlert];
	}
}

-(void)setDirection:(int)_dir{
	direction = _dir;
	if(direction>=0) direction = 1;
	if(direction<0) direction = -1;
	if(viewer){
		viewer.scaleX = direction;
	}
}

-(void)showFuncTips{
	if(!isHasFunc) return;
	[self hideFuncTips];
	
	if(func_type==NPC_FUNC_MAP){
		funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/4.png"];
	}
	
	if(func_type==NPC_FUNC_OPEN_WIN){
		
		if (funcString != nil) {
			NSArray * func = [funcString componentsSeparatedByString:@":"];
			if (func.count > 1) {
				int ___type = [[func objectAtIndex:1] intValue];
				if (___type == PANEL_BUSINESSMAN) {
					funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/9.png"];
				}
				if (___type == PANEL_ARENA) {
					funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/11.png"];
				}
			}
		}
		
	}
	
	if(func_type==NPC_FUNC_STAGE){
		funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/7.png"];
	}
	
	if(func_type==NPC_FUNC_FIGHT){
		funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/7.png"];
	}
	
	if(func_type==NPC_FUNC_FOOT){
		funcTips = [CCSprite spriteWithFile:@"images/ui/npc_alert/10.png"];
	}
	
	if(func_type==NPC_FUNC_BLOCK){
		
	}
	
	if(!funcTips) return;
	
	[self addChild:funcTips z:999];
	funcTips.anchorPoint = ccp(0.5,0);
	
	if(!isDown){
		funcTips.position = ccp(0,baseSize.height+(isShowName?22:0)-5);
	}else{
		funcTips.position = ccp(0,baseSize.height-offset+(isShowName?22:0)-5);
	}
	
	id _up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 10)];
	id _dn = [_up reverse];
	id sequence = [CCSequence actions:_up,_dn,nil];
	id forever = [CCRepeatForever actionWithAction:sequence];
	[funcTips runAction:forever];
	
}
-(void)hideFuncTips{
	if(funcTips){
		[funcTips removeFromParentAndCleanup:YES];
		funcTips = nil;
	}
}

-(void)showAlert{
	
	CCLOG(@"SHOW NPC ALERT !!!");
	
	if(alert) return;
	
	[self hideFuncTips];
	
	//TODO make the icon file ...
	if (task) {
		//Task_Action t = [task getNextAction];
		if (task.type == Task_Type_main) {//主线
			Task_Action next = [task getNextAction];
			if (next == Task_Action_stage || next == Task_Action_fight || next == Task_Action_move) {
				alert = [CCSprite spriteWithFile:@"images/ui/npc_alert/7.png"];
			}
			else {
				alert = [CCSprite spriteWithFile:@"images/ui/npc_alert/1.png"];
			}
		}else if (task.type == Task_Type_offer) {//悬赏
			alert = [CCSprite spriteWithFile:@"images/ui/npc_alert/3.png"];
		}else if (task.type == Task_Type_vice) {//支线
			alert = [CCSprite spriteWithFile:@"images/ui/npc_alert/2.png"];
		}else if (task.type == Task_Type_hide) {//隐藏
			alert = [CCSprite spriteWithFile:@"images/ui/npc_alert/2.png"];
		}
		if (alert) {
			
			[self addChild:alert z:999];
			alert.anchorPoint = ccp(0.5,0);
			
			float ty = 5;
			if(iPhoneRuningOnGame()){
				ty = 2;
			}
			
			if(!isDown){
				alert.position = ccp(0,baseSize.height+(isShowName?22:0)-ty);
			}else{
				alert.position = ccp(0,baseSize.height-offset+(isShowName?22:0)-ty);
			}
			
			id _up = nil;
			if(iPhoneRuningOnGame()){
				_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 5)];
			}else{
				_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 10)];
			}
			id _dn = [_up reverse];
			id sequence = [CCSequence actions:_up,_dn,nil];
			id forever = [CCRepeatForever actionWithAction:sequence];
			[alert runAction:forever];
			
		}
	}
}

-(void)hideAlert{
	if(alert){
		CCLOG(@"HIDE NPC ALERT !!!");
		[alert stopAllActions];
		[alert removeFromParentAndCleanup:YES];
		alert = nil;
	}
	
	[self showFuncTips];
}

-(void)showNPCMessage{
	
	NSDictionary * npcInfo = [[GameDB shared] getNpcInfo:npcId];
	NSString * msg = [npcInfo objectForKey:@"msg"];
	
	if([msg isEqualToString:@"0"] || [msg length]==0){
		[self doNPCActionFunc];
		return;
	}
	
	NSArray * message = [msg componentsSeparatedByString:@"|"];
	if([message count]>0){
		int index = getRandomInt(0,[message count]-1);
		msg = [message objectAtIndex:index];
		
		[[AlertManager shared] showNPCMessage:msg 
										npcId:npcId 
									   target:self 
									  confirm:@selector(doNPCActionFunc) 
										canel:nil];
		
	}else{
		[self doNPCActionFunc];
	}
}

-(void)checkSelfTask{
	
	if(task){
		[task runStep];
	}
	
}

-(void)delayShowWindow
{
	[[Window shared] showWindow:_winType];
}

-(void)doNPCActionFunc{
	
	if(!isHasFunc) return;
	
	//NSString * funcStr = funcString;
	//if([funcStr length]>0){
		
		NSArray * func = [funcString componentsSeparatedByString:@":"];
		//if([func count]>0){
			//int func_type = [[func objectAtIndex:0] intValue];
			switch (func_type) {
				case NPC_FUNC_MAP:
					[[Game shared] trunToMap:[[func objectAtIndex:1] intValue]];
					break;
				case NPC_FUNC_OPEN_WIN:
					_winType = [[func objectAtIndex:1] intValue];
					[self unschedule:@selector(delayShowWindow)];
					[self scheduleOnce:@selector(delayShowWindow) delay:0.1];
					break;
				case NPC_FUNC_STAGE:
					[[StageManager shared] startStageById:[[func objectAtIndex:1] intValue]];
					break;
				case NPC_FUNC_FIGHT:
					[[FightManager shared] startFightById:[[func objectAtIndex:1] intValue] target:nil call:nil];
					break;
				case NPC_FUNC_FOOT:
					[EatFoot show];
					break;
				case NPC_FUNC_BLOCK:
					break;
				case NPC_FUNC_TURRET:
					[[DragonFightManager shared] doFireByTurret:self];
					break;
				default:
					break;
			}
		//}
	//}
	
}

-(CGPoint)getPlayerPoint{
	
	if(isDown || dir==NPC_DIR_9){
		return self.position;
	}
	
	CGPoint sp = [[MapManager shared] getPositionToTile:self.position];
	CGPoint tp = ccp(0,0);
	
	if(dir==NPC_DIR_1) tp = ccp(0,-5);
	if(dir==NPC_DIR_2) tp = ccp(0,5);
	
	if(direction>0){
		if(dir==NPC_DIR_3) tp = ccp(-4,0);
		if(dir==NPC_DIR_4) tp = ccp(4,0);
		
		if(dir==NPC_DIR_5) tp = ccp(-3,-5);
		if(dir==NPC_DIR_6) tp = ccp(-3,5);
		
		if(dir==NPC_DIR_7) tp = ccp(3,-5);
		if(dir==NPC_DIR_8) tp = ccp(3,5);
	}else{
		if(dir==NPC_DIR_3) tp = ccp(4,0);
		if(dir==NPC_DIR_4) tp = ccp(-4,0);
		
		if(dir==NPC_DIR_5) tp = ccp(3,-5);
		if(dir==NPC_DIR_6) tp = ccp(3,5);
		
		if(dir==NPC_DIR_7) tp = ccp(-3,-5);
		if(dir==NPC_DIR_8) tp = ccp(-3,5);
	}
	
	CGPoint rp = ccpAdd(sp, tp);
	if([[MapManager shared] tiledPointIsOpen:rp]){
		return [[MapManager shared] getTileToPosition:rp];
	}else{
		
		if(dir==NPC_DIR_1) tp = ccp(0,-1);
		if(dir==NPC_DIR_2) tp = ccp(0,1);
		
		if(direction>0){
			if(dir==NPC_DIR_3) tp = ccp(-1,0);
			if(dir==NPC_DIR_4) tp = ccp(1,0);
			
			if(dir==NPC_DIR_5) tp = ccp(-1,-1);
			if(dir==NPC_DIR_6) tp = ccp(-1,1);
			
			if(dir==NPC_DIR_7) tp = ccp(1,-1);
			if(dir==NPC_DIR_8) tp = ccp(1,1);
		}else{
			if(dir==NPC_DIR_3) tp = ccp(1,0);
			if(dir==NPC_DIR_4) tp = ccp(-1,0);
			
			if(dir==NPC_DIR_5) tp = ccp(1,-1);
			if(dir==NPC_DIR_6) tp = ccp(1,1);
			
			if(dir==NPC_DIR_7) tp = ccp(-1,-1);
			if(dir==NPC_DIR_8) tp = ccp(-1,1);
		}
		
		for(int i=2;i<5;i++){
			CGPoint rp = ccpAdd(sp, tp);
			if([[MapManager shared] tiledPointIsOpen:rp]){
				return [[MapManager shared] getTileToPosition:rp];
			}
			tp = ccp(tp.x*i,tp.y*i);
		}
		
	}
	
	return [RoleManager shared].player.position;
}


//==============================================================================

-(BOOL)isTouchInSite:(UITouch*)touch{
	
	if(![GameLayer shared].touchEnabled) return NO;
	
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	CGSize size = baseSize;
	
	if(iPhoneRuningOnGame()){
		if(size.width<50) size.width = 50;
		if(size.height<40) size.height = 40;
		if (isBattle) size.height += 30;
	}else{
		if(size.width<100) size.width = 100;
		if(size.height<80) size.height = 80;
		if (isBattle) size.height += 65;
	}
	
	if(isDown){
		if(p.x<-size.width/2)	return NO;
		if(p.x>size.width/2)	return NO;
		if(p.y<-size.height/2)	return NO;
		if(p.y>size.height/2)	return NO;
	}else{
		if(p.x<-size.width/2)	return NO;
		if(p.x>size.width/2)	return NO;
		
		if(iPhoneRuningOnGame()){
			if(p.y<10)			return NO;
		}else{
			if(p.y<20)			return NO;
		}
		
		if(p.y>size.height)		return NO;
	}
	
	return YES;
}

-(void)updateTouchDelay{
	bTouchDelay = NO;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if (![[Window shared] checkCanTouchNpc]) {
		return NO;
	}
	BOOL b = [self isTouchInSite:touch];
	
	if (!b) {
		self.isSelected = NO ;
	}
	
	return b;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	//如果有窗口打开，不给点击NPC
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	
	if([self isTouchInSite:touch] && self.visible){
		
		[[RoleOption shared] binding:Nil];
		[[NPCManager shared] unSelectNPC];
		self.isSelected = YES;
		
		//add block Func action
		if(isHasFunc){
			NSString * funcStr = funcString;
			if([funcStr length]>0){
				NSArray * func = [funcStr componentsSeparatedByString:@":"];
				if([func count]>0){
					int _temp = [[func objectAtIndex:0] intValue];
					if (_temp == NPC_FUNC_BLOCK) {
						return ;
					}
				}
			}
		}
		
		if (bTouchDelay) {
			return ;
		}
		bTouchDelay = YES;
		
		if(calltarget!=nil && call!=nil){
			[RoleManager shared].player.targetPoint = self.position;
			[calltarget performSelector:call  withObject:self];
			[self scheduleOnce:@selector(updateTouchDelay) delay:1.0];
			return;
		}
		
		if(task){
			[self checkSelfTask];
		}else{
			[RoleManager shared].player.targetPoint = self.position;
			[[RoleManager shared] movePlayerTo:[self getPlayerPoint]
										target:self
										  call:@selector(showNPCMessage)
			 ];
		}
		[self unschedule:@selector(updateTouchDelay)];
		[self scheduleOnce:@selector(updateTouchDelay) delay:1.0];
		
	}
}

-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call offset:(float)_off{
	NpcEffects *effects = (NpcEffects*)[self getChildByTag:-7676];
	if (effects) {
		[effects stopAllActions];
		[effects removeFromParentAndCleanup:YES];
		effects = nil;
	}
	effects = [NpcEffects node];
	[self addChild:effects z:INT16_MAX tag:-7676];
	effects.anchorPoint=ccp(0.5, 0.5);
	
	if(iPhoneRuningOnGame()){
		effects.position=ccp(self.contentSize.width/2, _off/2);
	}else{
		effects.position=ccp(self.contentSize.width/2, _off);
	}
	
	[effects showEffect:_eid target:_target call:_call];
}

-(int)getNpcHeight{
	return baseSize.height ;
}

-(void)showBattle{
	
	isBattle = YES;
	
	[self removeChildByTag:125 cleanup:YES];
	
	CCSprite *battle = [CCSprite spriteWithFile:@"images/ui/common/battle.png"];
	[self addChild:battle z:999 tag:125];
	battle.anchorPoint = ccp(0.5,0);
	
	float ty = 5;
	if(iPhoneRuningOnGame()){
		ty = 2;
	}
	if(!isDown){
		battle.position = ccp(0,baseSize.height+(isShowName?22:0)-ty);
	}else{
		battle.position = ccp(0,baseSize.height-offset+(isShowName?22:0)-ty);
	}
	
	id _up = nil;
	if(iPhoneRuningOnGame()){
		_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 5)];
	}else{
		_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 10)];
	}
	
	id _dn = [_up reverse];
	id sequence = [CCSequence actions:_up,_dn,nil];
	id forever = [CCRepeatForever actionWithAction:sequence];
	[battle runAction:forever];
}

-(void)showFighting
{
	isFighting = YES;
	
	[self removeChildByTag:126];
	
	int fontsize=16;
	if(iPhoneRuningOnGame()){
		fontsize=20;
	}
	
	CCSprite *battleSprite = [CCSprite node];
	
	CCSprite *battle = [CCSprite spriteWithFile:@"images/ui/dragon/icon_fight.png"];
	battle.anchorPoint = ccp(0.5, 1);
	[battleSprite addChild:battle];
	
	CCSprite *fightLabel = drawBoundString(NSLocalizedString(@"dragon_fight_now",nil),
										   8,
										   GAME_DEF_CHINESE_FONT,
										   fontsize,
										   ccc3(255, 0, 0), ccBLACK);
	fightLabel.anchorPoint = ccp(0.5, 0.0);
	[battleSprite addChild:fightLabel];
	
	float offsetHeight = 10;
	if (iPhoneRuningOnGame()) {
		offsetHeight = 12;
	}
	battleSprite.contentSize = CGSizeMake(battle.contentSize.width,
										  battle.contentSize.height+fontsize-offsetHeight);
	battleSprite.anchorPoint = ccp(0.5f, 0);
	[self addChild:battleSprite z:999 tag:126];
	
	battle.position = ccp(battleSprite.contentSize.width/2,
						  battleSprite.contentSize.height);
	fightLabel.position = ccp(battleSprite.contentSize.width/2, 0);
	
	float ty = 5;
	if(iPhoneRuningOnGame()){
		ty = 2;
	}
	if(!isDown){
		battleSprite.position = ccp(0,baseSize.height+(isShowName?cFixedScale(30):0)-ty);
	}else{
		battleSprite.position = ccp(0,baseSize.height-offset+(isShowName?cFixedScale(30):0)-ty);
	}
	
	id _up = nil;
	if(iPhoneRuningOnGame()){
		_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 5)];
	}else{
		_up = [CCMoveBy actionWithDuration:0.5 position:ccp(0, 10)];
	}
	
	id _dn = [_up reverse];
	id sequence = [CCSequence actions:_up,_dn,nil];
	id forever = [CCRepeatForever actionWithAction:sequence];
	[battleSprite runAction:forever];
}

-(void)removeFighting
{
	[self removeChildByTag:126];
	
	isFighting = NO;
}

-(void)showFire:(float)percent
{
	isFire = YES;
	
	[self removeChildByTag:127];
	
	CCSprite *scrollBg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_2.png"];
	[self addChild:scrollBg z:999 tag:127];
	scrollBg.anchorPoint = ccp(0.5f,0);
	
	CCSprite *scroll1 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_2_1.png"];
	scroll1.anchorPoint = ccp(0, 0.5f);
	scroll1.position = ccp(cFixedScale(1.0f), scrollBg.contentSize.height/2);
	scroll1.tag = 101;
	[scrollBg addChild:scroll1];
	
	CCSprite *scroll2 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_2_2.png"];
	scroll2.anchorPoint = ccp(0, 0.5f);
	scroll2.position = ccp(scroll1.position.x+scroll1.contentSize.width,
						   scroll1.position.y);
	scroll2.tag = 102;
	[scrollBg addChild:scroll2];
	
	CCSprite *scroll3 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_2_3.png"];
	scroll3.anchorPoint = ccp(0, 0.5f);
	scroll3.tag = 103;
	[scrollBg addChild:scroll3];
	
	fireTotalTime = [DragonFightData shared].installTime;
	fireCurtTime = fireTotalTime * percent / 100.0f;
	
	[self setFirePercent:percent];
	
	[self unschedule:@selector(updateFireTime:)];
	[self schedule:@selector(updateFireTime:)];
	
	float ty = 5;
	if(iPhoneRuningOnGame()){
		ty = 2;
	}
	if(!isDown){
		scrollBg.position = ccp(0,baseSize.height+(isShowName?cFixedScale(30):0)-ty);
	}else{
		scrollBg.position = ccp(0,baseSize.height-offset+(isShowName?cFixedScale(30):0)-ty);
	}
}

-(void)setFirePercent:(float)percent
{
	CCNode *node = [self getChildByTag:127];
	if (node != nil) {
		CCSprite *scroll1 = (CCSprite*)[node getChildByTag:101];
		CCSprite *scroll2 = (CCSprite*)[node getChildByTag:102];
		CCSprite *scroll3 = (CCSprite*)[node getChildByTag:103];
		
		if (percent <= 0) {
			scroll1.visible = NO;
			scroll2.visible = NO;
			scroll3.visible = NO;
		} else {
			scroll1.visible = YES;
			scroll2.visible = YES;
			scroll3.visible = YES;
			
			float width = node.contentSize.width-scroll1.contentSize.width-scroll3.contentSize.width-cFixedScale(1.0f)*2;
			float finalWidth = width*percent/100.0f;
			
			scroll2.scaleX = finalWidth/scroll2.contentSize.width;
			scroll3.position = ccpAdd(scroll2.position, ccp(finalWidth, 0));
		}
	}
}

-(void)updateFireTime:(ccTime)time
{
	fireCurtTime -= time;
	if (fireCurtTime <= 0) {
		[self unschedule:@selector(updateFireTime:)];
		[self removeFire];
		[self showFireEffect];
	}
	float percent = fireCurtTime*100.0f/fireTotalTime;
	[self setFirePercent:percent];
}

-(void)removeFire
{
	[self unschedule:@selector(updateFireTime:)];
	[self removeChildByTag:127];
	
	isFire = NO;
}

// 狩龙炮塔开炮实际效果
-(void)showFireEffect
{
	[self removeChildByTag:128];
	
	NSArray *fireArray=[AnimationViewer loadFileByFileFullPath:@"images/ui/dragon/cannon/" name:@"%d.png"];
	id fireCall = [CCCallFunc actionWithTarget:self selector:@selector(removeFireEffect)];
	
	AnimationViewer *fire = [AnimationViewer node];
	fire.tag = 128;
	fire.anchorPoint = ccp(0.5f, 0);
	fire.position = ccp(0, cFixedScale(-55.0f));
	[fire playAnimation:fireArray delay:0.15f call:fireCall];
	
	if (direction < 0) {
		fire.flipX = YES;
	}
	
	[self addChild:fire z:-1];
}

-(void)removeFireEffect
{
	[self removeChildByTag:128];
}

-(void)setIsSelected:(BOOL)isSelected{
	_isSelected = isSelected;
	
	[self removeChildByTag:97442823 cleanup:YES];
	
//	CCLOG(@"GameNpc start unSelectNPC");
//	[[NPCManager shared] unSelectNPC];
//	CCLOG(@"GameNpc end unSelectNPC");
	
	if (_isSelected) {
		
		AnimationViewer* _ani =[AnimationViewer node];
		
		NSString* path = [NSString stringWithFormat:@"images/animations/sociality/"];
		[_ani showAnimationByPathForever:[path stringByAppendingString:@"%d.png"]];
		
		if (shadowSpr != nil) {
			_ani.scale = shadowSpr.scale;
		}
		
		[self addChild:_ani z:0 tag:97442823];
		
	}
}

@end

