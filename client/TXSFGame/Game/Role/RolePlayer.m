//
//  RolePlayer.m
//  TXSFGame
//
//  Created by chao chen on 12-10-16.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "RolePlayer.h"

#import "MapManager.h"
#import "RoleManager.h"
#import "GameLayer.h"

#import "GameConfigure.h"
#import "ActionMove.h"
#import "AnimationRole.h"

#import "CCLabelFX.h"
#import "GameDB.h"
#import "NpcEffects.h"

#import "Task.h"
#import "TaskManager.h"
#import "MovingAlert.h"
#import "RoleOption.h"
#import "Window.h"

#import "CarViewerContent.h"

#define ROLE_PLAYER_SPEED 350.0f
#define TAG_MAP_POINTER 10008

static RoleDir pRoleDir;
static float pScaleX;

RolePlayer * s_RolePlayer = nil;

@implementation RolePlayer

@synthesize quality;
@synthesize player_id;
@synthesize role_id;
@synthesize suit_id;
@synthesize car_id;
@synthesize level;
@synthesize state;
@synthesize name;

@synthesize actionMove;
@synthesize roleDir;

@synthesize target;
@synthesize moveEndCall;

@synthesize targetPoint;

@synthesize isShow;

@synthesize isSelected = _isSelected;

@synthesize allyName;

@synthesize followTarget;

+(void)reset{
	pRoleDir = RoleDir_none;
}
-(void)setQuality:(int)quality_{
    quality = quality_;
}
-(void)start{
	
	self.anchorPoint = ccp(0.5,0.0);
	
	NSDictionary * role = [[GameDB shared] getRoleInfo:role_id];
	
	offset = [[role objectForKey:@"offset"] intValue];
	
	if(isShow) [self doShowPlayer];
	
}
-(void)startDelay:(float)time{
	
	/*
	[NSTimer scheduledTimerWithTimeInterval:time
									 target:self
								   selector:@selector(start)
								   userInfo:nil
									repeats:NO];
	*/
	[self scheduleOnce:@selector(start) delay:time];
	
}

-(void)showPlayer{
	
	if(isShow) return;
	isShow = YES;
	self.visible = YES;
	
	[self doShowPlayer];
}

-(void)hidePlayer{
	
	if(!isShow) return;
	isShow = NO;
	self.visible = NO;
	
	[self unschedule:@selector(updateTimer)];
	[self removeAll];
	
}

-(void)doShowPlayer{
	
	viewer = [AnimationRole node];
	viewer.anchorPoint = ccp(0.5,0);
	if([Game iPhoneRuningOnGame]){
		viewer.position = ccp(0,-offset/2);
	}else{
		viewer.position = ccp(0,-offset);
	}
	[self addChild:viewer z:1];
	
	if([RoleManager shared].player==self){
		viewer.roleDir = pRoleDir;
		viewer.scaleX = pScaleX;
        //
        NSDictionary *role_info = [[GameConfigure shared] getPlayerRoleFromListById:role_id];
        if (role_info && [role_info objectForKey:@"q"] ) {
            quality = [[role_info objectForKey:@"q"] intValue];
        }
        //
	}
	
	viewer.roleId = role_id;
	viewer.suitId = suit_id;
	
	//[viewer loadRole:role_id];
	//[self updateSuit:suit_id];
	//viewer.roleAction = state;
	/*
	 if(state==Player_state_sit){
	 viewer.roleAction = RoleAction_siting;
	
	 }
	 */
	[viewer showRole];
	
	//CCLOG(@"%@ suit:%i",name,suit_id);
	
	actionMove = [[ActionMove alloc] init];
	actionMove.viewer = self;
	if(iPhoneRuningOnGame()){
		actionMove.speed = ROLE_PLAYER_SPEED/2;
	}else{
		actionMove.speed = ROLE_PLAYER_SPEED;
	}
	
	shadowSpr = [CCSprite spriteWithFile:@"images/shadow.png"];
	shadowSpr.position = self.position;
 
	[self.parent addChild:shadowSpr z:0 tag:555];
	[self showName];
	[self schedule:@selector(updateTimer:) interval:1/60.0f];
	if(car_id>0){
		[self updateCar:car_id];
	}
	if(state==Player_state_sit){
		[viewer showSit];
		[self showSitEffect];
	}
	
	[self showMapPointer];
	
}

-(void)setScaleX:(float)scaleX{
	if(viewer){
		if(scaleX!=viewer.scaleX){
			viewer.scaleX = scaleX;
			[self showCarEffect:car_id];
			pScaleX = viewer.scaleX;
		}
	}
}
-(void)setRoleDir:(RoleDir)dir{
	
	if(viewer){
		if(dir!=viewer.roleDir){
			viewer.roleDir = dir;
			[self showCarEffect:car_id];
		}
		viewer.roleDir = dir;
		
		if([RoleManager shared].player==self){
			pRoleDir = dir;
		}
	}
}

-(void)setVisible:(BOOL)visible{
	if(!isShow) return;
	
	[super setVisible:visible];
	if(shadowSpr){
		shadowSpr.visible = visible;
	}
}

-(void)updateTimer:(ccTime)time{
	
	if(self.parent){
		int zz = (GAME_MAP_MAX_Y-self.position.y);
		[self.parent reorderChild:self z:zz];
	}
	
	[actionMove update:time];
	
	[self updateMapPointer];
	
}
//fix chao 加入阴影
-(void)onEnter{
	[super onEnter];
	//调整 调整优先级
	//[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-4 swallowsTouches:YES];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	//	[self showUplevel];
	//	[self showEffect:3 target:nil call:nil];
}

-(void)setPosition:(CGPoint)position{
	[super setPosition:position];
	
	if(mapPointer){
		mapPointer.position = ccpAdd(position, ccp(0,[self getRolePlayerSize].height/2));
	}
	
	if(shadowSpr){
		shadowSpr.position = position;
	}
	if (loading) {
		if(iPhoneRuningOnGame()){
			loading.position = ccpAdd(position, ccp(0, 90));
		}else{
			loading.position = ccpAdd(position, ccp(0, 180));
		}
	}
}

-(void)removeAll{
	
	if(viewer){
		[viewer removeFromParentAndCleanup:YES];
		viewer = nil;
	}
	
	if(shadowSpr){
		[self.parent removeChild:shadowSpr cleanup:YES];
		shadowSpr = nil;
	}
	
	[self closeLoading];
	[self removeSitEffect];
	[self removeCarEffect];
	
	if(nameLabel){
		[nameLabel removeFromParentAndCleanup:YES];
		nameLabel = nil;
	}
	
	[self removeAllChildrenWithCleanup:YES];
	
}

//end
-(void)onExit{
	
	self.followTarget = nil;
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[self removeAll];
	
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)dealloc{
	[super dealloc];
	if(actionMove){
		[actionMove release];
		actionMove = nil;
	}
}

-(void)showName{
	
	[self removeChildByTag:123 cleanup:YES];
	
	//ccColor3B cc3 = ccc3(38, 198, 255);
    ccColor3B cc3 = getColorByQuality(quality);
//    NSDictionary *role_info = [[GameConfigure shared] getPlayerRoleFromListById:role_id];
//    if (role_info && [role_info objectForKey:@"q"] ) {
//        cc3 = getColorByQuality(quality);
//    }
    
	NSString *allyColor=@"fff8e1";
	if([RoleManager shared].player==self){
		allyColor=@"ff7c24";
	}
	
	//NSString* _name = [NSString stringWithFormat:@"%@ , %d",name,player_id] ;
	NSString* _name = [NSString stringWithFormat:@"%@",name] ;
	int f_size = 16;
    if (iPhoneRuningOnGame()) {
        f_size = 20;
    }
	nameLabel = drawBoundString(_name, f_size/2, GAME_DEF_CHINESE_FONT, f_size, cc3, ccBLACK);
	nameLabel.anchorPoint = ccp(0.5,0.0);
	nameLabel.position = ccp(0,viewer.contentSize.height+viewer.position.y);
	if(nameLabel.position.y<0){
		nameLabel.position = ccp(0,130);
	}
	
	if(allyName.length>0){
		
		CCSprite *allynamesp=nil;
		if(iPhoneRuningOnGame()){
			 allynamesp=drawString([NSString stringWithFormat:@"<%@>",allyName], CGSizeMake(500, 30), GAME_DEF_CHINESE_FONT, 20*2, 24*2,allyColor);
		}else{
			 allynamesp=drawString([NSString stringWithFormat:@"<%@>",allyName], CGSizeMake(500, 30), GAME_DEF_CHINESE_FONT, 16, 18,allyColor);
		}
		[allynamesp setAnchorPoint:ccp(0.5, 0.5)];
		[allynamesp setPosition:ccp(nameLabel.contentSize.width/2, nameLabel.contentSize.height+allynamesp.contentSize.height/2)];
		[nameLabel addChild:allynamesp];
		
	}
	
	[self addChild:nameLabel z:100 tag:123];
	
}
////移动到玩家主角色

/*
 -(void)moveToStartPoint{
 CGPoint point = [MapManager shared].startPoint;
 self.position = [[MapManager shared] getTileToPosition:point];
 [[GameLayer shared] updatePlayerView];
 }
 */
#pragma mark 更新套装
-(void)updateSuit{
	if([RoleManager shared].player==self){
		NSDictionary * roleInfo = [[GameConfigure shared] getPlayerRoleFromListById:role_id];
		int eq2 = [[roleInfo objectForKey:@"eq2"] intValue];
		if(eq2>0){
			NSDictionary * equip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
			int eqid = [[equip objectForKey:@"eid"] intValue];
			[self updateSuit:eqid];
			return;
		}
		[self updateSuit:0];
	}
}
-(void)updateSuit:(int)suitId{
	if(viewer){
		[viewer showSuit:suitId];
	}
}

#pragma mark 更新坐骑
-(void)updateCar:(int)carId{
	if(carId>0){
		car_id=carId;
		float speed=[[[[GameDB shared] getCarInfo:carId] objectForKey:@"speed"] floatValue];
		
		if(iPhoneRuningOnGame()){
			actionMove.speed=speed*ROLE_PLAYER_SPEED/2;
		}else{
			actionMove.speed=speed*ROLE_PLAYER_SPEED;
		}
		
		//暂时先保护
		if (speed <= 0) {
			if(iPhoneRuningOnGame()){
				actionMove.speed=ROLE_PLAYER_SPEED/2;
			}else{
				actionMove.speed=ROLE_PLAYER_SPEED;
			}
		}
		if(cvc){
			[self removeCarEffect];
			//[cvc removeFromParentAndCleanup:true];
		}
		[self showCarEffect:carId];
		[viewer setOnCar:YES];

	}else{
		if(iPhoneRuningOnGame()){
			actionMove.speed=ROLE_PLAYER_SPEED/2;
		}else{
			actionMove.speed=ROLE_PLAYER_SPEED;
		}
		car_id=-1;
		[viewer setOnCar:NO];
		[self removeCarEffect];
		
	}
}

-(void)moveTo:(CGPoint)pos{
	if(!isShow){
		self.position = pos;
		return;
	}
	
	dispatch_queue_t find_queue = dispatch_queue_create("mapfinder", NULL);
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	dispatch_async(find_queue, ^{
		NSArray * points = [[MapManager shared] startRun:self.position moveTo:pos block:(player_id == [[GameConfigure shared] getPlayerId])];
		if([points count]>0){
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[viewer showRuning];
				actionMove.call = @selector(moveEnd);
				[actionMove moveTo:points];
				
			});
		}
	});
	dispatch_release(find_queue);
}
-(void)moveTo:(CGPoint)pos target:(id)t call:(SEL)c{
	
	if(!isShow){
		self.position = pos;
		[NSTimer scheduledTimerWithTimeInterval:0.002f
										 target:t
									   selector:c
									   userInfo:nil
										repeats:NO];
		return;
	}
	
	dispatch_queue_t find_queue = dispatch_queue_create("mapfinder", NULL);
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	dispatch_async(find_queue, ^{
		
        NSArray * points = [[MapManager shared] startRun:self.position moveTo:pos];
		
		if([points count]>0){
			dispatch_async(dispatch_get_main_queue(), ^{
				
				self.target = t;
				self.moveEndCall = c;
				
				CGPoint tPoint = [[MapManager shared] getPositionToTile:pos];
				
				[[MapManager shared] setPlayerLocation:tPoint];
				
				if (![[TaskManager shared] checkMoveToNpc:tPoint]) {
					if (nil != [TaskManager shared].runingTask) {
						//重置任务的执行状态
						if ([TaskManager shared].runingTask.currentAction == Task_Action_move ||
							[TaskManager shared].runingTask.currentAction == Task_Action_moveToNPC) {
							[TaskManager shared].runingTask.isDoingStep = NO;
						}
						[MovingAlert remove];
					}
					
				}
				
				actionMove.call = @selector(moveEnd);
				[actionMove moveTo:points];
				[viewer showRuning];
			});
		}
	});
	dispatch_release(find_queue);
}

-(void)stopMove{
	
	if(actionMove.isMove && [RoleManager shared].player == self){
		CCLOG(@"actionMove.isMove && [RoleManager shared].player == self");
		CGPoint tPoint = [[MapManager shared] getPositionToTile:self.position];
		[[MapManager shared] setPlayerLocation:tPoint];
	}
	
	actionMove.isMove = NO;
	if([self state]!=Player_state_sit){
		[viewer showStand];
	}
	
	
}

-(void)stopMoveAndTask{
	
	/*
	 if ([TaskManager shared].runingTask.currentAction == Task_Action_move ||
	 [TaskManager shared].runingTask.currentAction == Task_Action_moveToNPC) {
	 [TaskManager shared].runingTask.isDoingStep = NO;
	 [MovingAlert remove];
	 }
	 */
	
	if(actionMove.isMove){
		[MovingAlert remove];
		[self stopMove];
	}
	
}


-(void)moveEnd{
	
	switch (state) {
		case Player_state_normal:
		{
			[viewer showStand];
		}
			break;
		case Player_state_sit:
		{
			[viewer showSit];
		}
			break;
		default:
			break;
	}
		
	if(target!=nil && moveEndCall!=nil){
		[target performSelector:moveEndCall];
		target = nil;
		moveEndCall = nil;
	}
	
	[self updateDir:targetPoint];
	
	targetPoint = ccp(-1,-1);
	
}

-(void)showMessage:(NSString *)str{
	//TODO
}

-(void)updateDir:(CGPoint)_target{
	
	if(_target.x<=0 || _target.y<=0) return;
	
	CCLOG(@"self.position = %f|%f",self.position.x ,self.position.y);
	RoleDir _dir = getDirByPoints(self.position, _target);
	if(self.position.x > _target.x){
		if (_dir == RoleDir_up_flat || _dir == RoleDir_down_flat || _dir == RoleDir_flat) {
			if(viewer) viewer.scaleX=-1;
		}
	}else{
		if(viewer) viewer.scaleX=1;
	}
	self.roleDir=_dir;
	
}

-(void)setState:(Player_state)_state{
	
	[self removeSitEffect];
	if(state==_state) return;
	state = _state;
	
	if([RoleManager shared].player==self){
		[[GameConfigure shared] updatePlayerState:state];
	}
	//TDOO show player viewer by status
	if(!isShow) return;
	if(state==Player_state_sit){
		if(viewer) [viewer showSit];
		[self showSitEffect];
	}else{
		[self removeSitEffect];
	}
	
	
}

#pragma mark 展示打坐效果
-(void)showSitEffect{
	
	if(!isShow) return;
	
	if(sitEffect1==nil){
		sitEffect1 = [AnimationViewer node];
		if(iPhoneRuningOnGame()){
			sitEffect1.position =ccp(0,15+cvc.inSkyHigh/2);
		}else{
			sitEffect1.position =ccp(0,30+cvc.inSkyHigh);
		}
		[sitEffect1 showAnimationByPathForever:@"images/animations/sit/1/%d.png"];
		[self addChild:sitEffect1 z:viewer.zOrder-1 tag:7001];
	}
	
	if(sitEffect2==nil){
		sitEffect2 = [AnimationViewer node];
		if(iPhoneRuningOnGame()){
			sitEffect2.position =ccp(0,35+cvc.inSkyHigh/2);
		}else{
			sitEffect2.position =ccp(0,70+cvc.inSkyHigh);
		}
		[sitEffect2 showAnimationByPathForever:@"images/animations/sit/2/%d.png"];
		[self addChild:sitEffect2 z:INT16_MAX tag:7002];
	}
	
}

-(void)removeSitEffect{
	
	[self removeChildByTag:7001 cleanup:YES];
	[self removeChildByTag:7002 cleanup:YES];
	if(sitEffect1){
		//[sitEffect1 removeFromParentAndCleanup:YES];
		sitEffect1 = nil;
	}
	if(sitEffect2){
		//[sitEffect2 removeFromParentAndCleanup:YES];
		sitEffect2 = nil;
	}
}


#pragma mark 展示坐骑效果
-(void)showCarEffect:(int)cint{
	if(car_id<1)return;
	if(!isShow) return;
	int csl= viewer.scaleX<0?-1:1;
	if(!cvc){
		cvc = [CarViewerContent node];
		[cvc setScaleX:csl];
		[self addChild:cvc];
		[cvc loadTargetCar:cint dir:viewer.roleDir scaleX:viewer.scaleX];
	}else{
		[cvc setScaleX:csl];
		[cvc updateDir:viewer.roleDir scaleX:viewer.scaleX];
	}
	
	if(sitEffect1){
		[cvc setZOrder:sitEffect1.zOrder-1];
		sitEffect1.position =ccp(0,cFixedScale(30)+cFixedScale(cvc.inSkyHigh));
	}
	if(sitEffect2){
		sitEffect2.position =ccp(0,cFixedScale(70)+cFixedScale(cvc.inSkyHigh));
	}
	
	[viewer setPosition:ccp(0,-cFixedScale(offset)+ cFixedScale(cvc.inSkyHigh))];
	[nameLabel setPosition:ccp(nameLabel.position.x, viewer.contentSize.height+viewer.position.y)];
	[shadowSpr setScale:cvc.shadowSize];
	
}

-(void)removeCarEffect{
	if(cvc){
		[viewer setPosition:ccp(0,-cFixedScale(offset))];
		[nameLabel setPosition:ccp(nameLabel.position.x, viewer.contentSize.height+viewer.position.y)];
		[shadowSpr setScale:1];
		[cvc removeFromParentAndCleanup:true];
		cvc=nil;
	}
	
	if(sitEffect1){
		sitEffect1.position =ccp(0,cFixedScale(30));
	}
	if(sitEffect2){
		sitEffect2.position =ccp(0,cFixedScale(70));
	}
	
}


-(BOOL)isCanRun{
	//if(state==Player_state_sit) return NO;
	if(state==Player_state_action) return NO;
	
	//TODO change soul
	//暂时处理 人物界面事件穿透到地图的BUG
	//人物背包界面重整之后移走，这个方法需要遍历窗口，效率比较低
	if (![Window checkPlayerCanRun])  return NO;
	
	return YES;
}
-(BOOL)isRunning{
	//CCLOG(@"role dir:%i",self.roleDir);
	if(viewer.roleAction==RoleAction_runing){
		//CCLOG(@"update dir:%i",self.roleDir);
		return YES;
	}
	return NO;
}

-(void)updateLoading:(ccTime)time{
	if(loading){
		CCLOG(@"Player:updateLoading");
		CCNode * p1 = [loading getChildByTag:101];
		CCNode * p2 = [loading getChildByTag:102];
		CCNode * p3 = [loading getChildByTag:103];
		if(p2) p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		if(p3) p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
	}
}
-(void)closeLoading{
	[self unschedule:@selector(updateLoading:)];
	if (loading) {
		[loading removeFromParentAndCleanup:YES];
		loading = nil;
	}
}
-(void)startLoading:(NSString*)_string{
	
	if(!isShow) return;
	
	[self closeLoading];
	
	loading = [CCSprite spriteWithFile:@"images/effects/loading/bg-m.png"];
	if(iPhoneRuningOnGame()){
		loading.position = ccpAdd(self.position, ccp(0, 90));
	}else{
		loading.position = ccpAdd(self.position, ccp(0, 180));
	}
	[self.parent addChild:loading z:INT32_MAX];
	
	CCSprite * p1 = [CCSprite spriteWithFile:@"images/effects/loading/p-1-m.png"];
	CCSprite * p2 = [CCSprite spriteWithFile:@"images/effects/loading/p-2-m.png"];
	CCSprite * p3 = [CCSprite spriteWithFile:@"images/effects/loading/p-3-m.png"];
	
	p1.anchorPoint = ccp(0,0.5);
	p2.anchorPoint = ccp(0,0.5);
	p3.anchorPoint = ccp(0,0.5);
	
	[loading addChild:p1 z:1 tag:101];
	[loading addChild:p2 z:0 tag:102];
	[loading addChild:p3 z:1 tag:103];
	
	if(iPhoneRuningOnGame()){
		p1.position = ccp(15,loading.contentSize.height/2);
	}else{
		p1.position = ccp(30,loading.contentSize.height/2);
	}
	
	p2.scaleX = 0;
	
	[self updateLoading:0];
	
	[self schedule:@selector(updateLoading:) interval:1/30.0f];
	
	id scale = [CCScaleTo actionWithDuration:2.5f scaleX:1.0 scaleY:1];
	[p2 runAction:scale];
	
	CCLabelFX * label = [CCLabelFX labelWithString:_string
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:25
									  shadowOffset:CGSizeMake(0,0)
										shadowBlur:2.0f];
	label.anchorPoint = ccp(0.5,0.0);
	if(iPhoneRuningOnGame()){
		label.position = ccp(loading.contentSize.width/2,22);
	}else{
		label.position = ccp(loading.contentSize.width/2,44);
	}
	
	[loading addChild:label z:10 tag:200];
}
-(void)showUplevel{
	
	if(!isShow) return;
	
	[self closeUplevel];
	
	AnimationViewer *effect1 = [AnimationViewer node];
	[self addChild:effect1 z:-1 tag:-36278];
	effect1.anchorPoint=ccp(0.5, 0.5);
	if(iPhoneRuningOnGame()){
		effect1.position=ccp(0, 15); //viewer.position;
	}else{
		effect1.position=ccp(0, 30); //viewer.position;
	}
	
	/*
	 NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	 [effect1 playAnimation:frames delay:0.1];
	 */
	[effect1 showAnimationByPathOne:@"images/animations/uplevel/1/%d.png"];
	
	AnimationViewer *effect2 = [AnimationViewer node];
	[self addChild:effect2 z:INT16_MAX tag:-36279];
	effect2.anchorPoint=ccp(0.5, 0);
	effect2.position= ccp(0, 0);//viewer.position;
	
	/*
	 NSString * path2 = [NSString stringWithFormat:@"images/animations/uplevel/2/"];
	 NSArray * frames2 = [AnimationViewer loadFileByFileFullPath:path2 name:@"%d.png"];
	 id action = [CCCallFunc actionWithTarget:self selector:@selector(closeUplevel)];
	 [effect2 playAnimation:frames2 delay:0.1 call:action];
	 */
	[effect2 showAnimationByPathOne:@"images/animations/uplevel/2/%d.png"];
	
}
-(void)closeUplevel{
	CCNode* _object = [self getChildByTag:-36278];//下面
	if (_object){
		[_object stopAllActions];
		[_object removeFromParentAndCleanup:YES];
		_object = nil;
	}
	_object = [self getChildByTag:-36279];//上面
	if (_object){
		[_object stopAllActions];
		[_object removeFromParentAndCleanup:YES];
		_object = nil;
	}
}

-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call{
	
	NpcEffects *effects = (NpcEffects*)[self getChildByTag:-7676];
	if (effects) {
		[effects stopAllActions];
		[effects removeFromParentAndCleanup:YES];
		effects = nil;
	}
	effects = [NpcEffects node];
	[self addChild:effects z:0 tag:-7676];
	effects.anchorPoint=ccp(0.5, 0);
	if(iPhoneRuningOnGame()){
		effects.position= ccp(0, -25);//viewer.position;
	}else{
		effects.position= ccp(0, -50);//viewer.position;
	}
	[effects showEffect:_eid target:_target call:_call];
}

-(void)updateViewer{
	
	[self showName];
	
}

-(void)setIsSelected:(BOOL)isSelected{
	_isSelected = isSelected ;
	
	[self removeChildByTag:97442823 cleanup:YES];
	
	//兰兰说 角色不需要显示
	/*
	 if (_isSelected) {
	 
	 AnimationViewer* _ani =[AnimationViewer node];
	 
	 NSString* path = [NSString stringWithFormat:@"images/animations/sociality/"];
	 [_ani showAnimationByPathForever:[path stringByAppendingString:@"%d.png"]];
	 
	 [self addChild:_ani z:0 tag:97442823];
	 
	 }
	 */
}

-(CGSize)getRolePlayerSize{
	if (viewer) {
		float ____w = viewer.contentSize.width;
		float ____h = viewer.contentSize.height;
		return CGSizeMake(____w, ____h-cFixedScale(offset));
	}
    return CGSizeMake(0, 0) ;
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	
	if(![GameLayer shared].touchEnabled) return NO;
	
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = [self getRolePlayerSize];
	
	if(iPhoneRuningOnGame()){
		if(size.width<50) size.width = 50;
		if(size.height<40) size.height = 40;
	}else{
		if(size.width<100) size.width = 100;
		if(size.height<80) size.height = 80;
	}
	
	if(p.x<-size.width/2)	return NO;
	if(p.x>size.width/2)	return NO;
	if(p.y < 0)				return NO;
	if(p.y>size.height)		return NO;
	
	return YES;
}

/*
 -(void)draw{
 [super draw];
 CGSize size = [self getRolePlayerSize];
 ccDrawColor4B(255, 0, 0, 255);
 ccDrawRect(ccp(-size.width/2, 0), ccp(size.width/2, size.height));
 }*/

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	if ([RoleManager shared].player == self) {
		return NO ;
	}
	
	if (![[Window shared] checkCanTouchNpc]) {
		return NO;
	}
	
	if ([self isTouchInSite:touch] && isShow) {
		CCLOG(@"RolePlayer  isTouchInSite!!!!");
		return YES;
	}
	
	return NO;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	if ([RoleManager shared].player == self) {
		return ;
	}
	
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	
	if ([self isTouchInSite:touch] && isShow) {
		//todo
		//do some sociality function
		
		if ([RoleOption shared].role != self) {
			[[RoleOption shared] binding:self];
		}
		
	}
}

-(void)showTaskStatus:(BOOL)isStart{
	NSString* path = nil ;
	if (isStart) {
		path = [NSString stringWithFormat:@"images/ui/alert/task_begin.png"];
	}else{
		path = [NSString stringWithFormat:@"images/ui/alert/task_end.png"];
	}
	
	if ([self getChildByTag:5642]) {
		return ;
	}
	
	if (path != nil) {
		CCSprite* eft = [CCSprite spriteWithFile:path];
		[self addChild:eft z:INT_MAX tag:5642];
		eft.anchorPoint = ccp(0.5,0.0);
		CGPoint pt = ccp(0,viewer.contentSize.height+viewer.position.y + cFixedScale(20));
		eft.position = pt ;
		if(eft.position.y<0){
			eft.position = ccp(0,cFixedScale(150));
		}
		id act1 = [CCDelayTime actionWithDuration:0.5f];
		id act2 = [CCFadeTo actionWithDuration:0.5f opacity:0];
		id act3 = [CCMoveTo actionWithDuration:0.5f position:ccpAdd(pt, ccp(0, cFixedScale(50)))];
		id act4 = [CCSpawn actionOne:act2 two:act3];
		id act5 = [CCCallBlockN actionWithBlock:^(CCNode *node) {
			[node removeFromParentAndCleanup:YES];
		}];
		id act = [CCSequence actions:act1,act4,act5,nil];
		[eft runAction:act];
	}
}

-(void)showMapPointer{
	
	if([RoleManager shared].player!=self) return;
	if([MapManager shared].mapType!=Map_Type_Stage) return;
	
	[self hideMapPointer];
	
	mapPointer = [CCSprite spriteWithFile:@"images/map-pointer.png"];
	[self.parent addChild:mapPointer z:10008 tag:TAG_MAP_POINTER];
	mapPointer.anchorPoint = ccp(0,0.5);
	mapPointer.scale = 0.5;
	mapPointer.position = ccpAdd(self.position, ccp(0,[self getRolePlayerSize].height/2));
	mapPointer.visible = NO;
	
}

-(void)setFollowTarget:(CCNode*)_target{
	if([RoleManager shared].player!=self) return;
	followTarget = _target;
	
	if(!mapPointer){
		[self showMapPointer];
	}
	
	if(mapPointer){
		if(followTarget){
			mapPointer.visible = YES;
		}else{
			mapPointer.visible = NO;
		}
	}
}

-(void)updateMapPointer{
	if(mapPointer && followTarget){
		
		if(ccpDistance(self.position, followTarget.position)<cFixedScale(180)){
			mapPointer.visible = NO;
			return;
		}
		mapPointer.visible = YES;
		
		CGPoint followPoint = followTarget.position;
		CGPoint point = ccp((followPoint.x-self.position.x), followPoint.y-self.position.y);
		if(abs(point.x)>[MapManager shared].tileSize.width/2	&& 
		   abs(point.x)>[MapManager shared].tileSize.height/2	){
			float ang = 360-atan2(point.y,point.x)*180/M_PI;
			mapPointer.rotation = ang;
		}
		
	}
}

-(void)hideMapPointer{
	if(mapPointer){
		[self.parent removeChildByTag:TAG_MAP_POINTER];
		mapPointer = nil;
	}
}

-(void)checkFollowTarget:(CCNode*)followed{
	if(followTarget==followed){
		followTarget = nil;
		[self hideMapPointer];
	}
}

-(BOOL)isPrepareMoveEnd{
	if([RoleManager shared].player == self){
		return [actionMove isPrepareMoveEnd];
	}
	return NO;
}

@end
