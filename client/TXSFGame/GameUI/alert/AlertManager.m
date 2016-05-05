//
//  AlertManager.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-4.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AlertManager.h"
#import "Game.h"
#import "MovingAlert.h"
#import "TaskAlert.h"
#import "Task.h"
#import "MessageAlert.h"
#import "GameDB.h"
#import "LowerLeftChat.h"
#import "GameConfigure.h"
#import "MessageNPCAlert.h"
#import "MapManager.h"
#import "FightManager.h"
#import "TaskTalk.h"
#import "AlertActivity.h"
#import "GoodAlert.h"

static AlertManager* s_AlertManager = nil;

@implementation AlertManager

+(AlertManager*)shared{
	if(!s_AlertManager){
		s_AlertManager = [[AlertManager alloc] init];
	}
	return s_AlertManager;
}

+(void)stopAll{
	if(s_AlertManager){
		[s_AlertManager release];
		s_AlertManager = nil;
	}
}
+(BOOL)hasAlert{
	if(s_AlertManager){
		return [s_AlertManager hasAlert];
	}
	return NO;
}
-(BOOL)hasAlert{
	if([alerts count]>0){
		return YES;
	}
	if(runningAlert){
		return YES;
	}
	return NO;
}

-(id)init{
	if(self=[super init]){
		alerts = [[NSMutableArray alloc] init];
	}
	return self;
}
-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if (alerts) {
		[alerts release];
		alerts = nil;
	}
	
	//TODO
	
	if(runningAlert){
		[runningAlert removeFromParentAndCleanup:YES];
		runningAlert = nil;
	}
	
	[super dealloc];
	CCLOG(@"AlertManager dealloc");
}

-(void)showReceiveItem:(NSDictionary*)ItemTips {
	NSDictionary *dict=ItemTips;
	for(NSNumber *i in dict.allKeys){
		NSInteger itemid= [i integerValue];
		NSInteger itemcount=[[dict objectForKey:i]integerValue];
		NSDictionary *itemdata=[[GameDB shared]getItemInfo:itemid];
		NSString *name=[itemdata objectForKey:@"name"];
		if([name length]<1){
			return;
		}
		NSInteger quality=[[itemdata objectForKey:@"quality"]integerValue];
		NSArray *colorar=[NSArray arrayWithObjects:@"ffffff",@"00ff00",@"0000ff",@"b469ab",@"f7941d",@"ff0000",nil];
		NSString *qastr=[colorar objectAtIndex:quality];
		//NSString *tips=[NSString stringWithFormat:@"获得#ffffff#18#0|%@#%@#18#0|X %i#ffffff#18#0",name,qastr,itemcount];
        NSString *tips=[NSString stringWithFormat:NSLocalizedString(@"alert_get_info",nil),name,qastr,itemcount];
		//[[LowerLeftChat share]AddChatContent:tips];
		/*
		 <__NSArrayI 0xb3d8180>(
		 <__NSArrayI 0x1bc7ef70>(
		 1,
		 bac,
		 皇甫敏
		 )
		 
		 )
		 */
		NSMutableArray *__g=[NSMutableArray array];
		NSMutableArray *___g=[NSMutableArray arrayWithObjects:@"6",tips,nil];
		[__g addObject:___g];
		[GameConnection post:ConnPost_ChatPush object:__g];
		[ShowItem showItemAct:tips];
	}
}

-(void)showReceiveItemWithArray:(NSArray *)itemTips
{
	if (!itemTips || itemTips.count == 0) return;
	for (NSDictionary *dict in itemTips) {
		NSArray *keys = [dict allKeys];
		NSString *name = [dict objectForKey:@"name"];
		int count = [[dict objectForKey:@"count"] intValue];
		int quality = -1;
		if ([keys containsObject:@"quality"]) {
			quality = [[dict objectForKey:@"quality"] intValue];
		}
		NSString *colorString = quality == -1 ? @"" : getHexStringWithColor3B(getColorByQuality(quality));
		//NSString *getString = (quality == -1 && count < 0) ? @"消耗" : @"获得";
        NSString *getString = (quality == -1 && count < 0) ? NSLocalizedString(@"alert_expend_text",nil) : NSLocalizedString(@"alert_get_text",nil);
		count = ABS(count);
		NSString *tips = [NSString stringWithFormat:@"%@#ede430| %@%@ |%@%d#ede430", getString, name, colorString, (quality==-1?@"":@"x"), count];
		NSMutableArray *__g=[NSMutableArray array];
		NSMutableArray *___g=[NSMutableArray arrayWithObjects:@"6",tips,@"",nil];
		[__g addObject:___g];
		[GameConnection post:ConnPost_ChatPush object:__g];
		[ShowItem showItemAct:tips];
	}
}

-(void)showMessage:(NSString *)_content target:(id)_target call:(SEL)_call delay:(float)_time{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_call;
	alert.delay=_time;
	alert.type=MessageAlert_none;
	[self addAlert:alert];
}

-(GameAlert*)showMessage:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel father:(CCNode *)_father{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.canel=_canel;
	alert.father=_father;
	alert.type=MessageAlert_all;
	[self addAlert:alert];
	return alert;
}

-(GameAlert*)showUrgentMessage:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel father:(CCNode *)_father{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.canel=_canel;
	alert.father=_father;
	alert.type=MessageAlert_all;
	alert.isUrgent = YES ;
	[alert show];
	return alert;
}

-(void)showUrgentMessage:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.canel=_canel;
	alert.isUrgent = YES ;
	alert.type=MessageAlert_all;
	[alert show];
}

-(void)showMessage:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.canel=_canel;
	alert.type=MessageAlert_all;
	[self addAlert:alert];
}

-(void)showMessageWithCanel:(NSString *)_content target:(id)_target call:(SEL)_call{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.canel=_call;
	alert.type=MessageAlert_no;
	[self addAlert:alert];
}

-(void)showMessageWithConfirm:(NSString *)_content target:(id)_target call:(SEL)_call{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_call;
	alert.type=MessageAlert_ok;
	[self addAlert:alert];
}

-(GameAlert*)showMessageWithSettingFormFather:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key tips:(NSString *)_tips father:(CCNode *)_father{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.type=MessageAlert_setting;
	alert.recordKey=_key;
	alert.recordTips=_tips;
	alert.father=_father;
	[self addAlert:alert];
	return alert;
}
-(GameAlert*)showMessageWithSettingFormFather:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)canel key:(NSString *)_key tips:(NSString *)_tips father:(CCNode *)_father{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
    alert.canel=canel;
	alert.type=MessageAlert_setting;
	alert.recordKey=_key;
	alert.recordTips=_tips;
	alert.father=_father;
	[self addAlert:alert];
	return alert;
}
-(GameAlert*)showMessageWithSettingFormFather:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key father:(CCNode *)_gvs{
	//return [self showMessageWithSettingFormFather:_content target:_target confirm:_confirm key:_key tips:@"不再提醒" father:_gvs];
    return [self showMessageWithSettingFormFather:_content target:_target confirm:_confirm key:_key tips:NSLocalizedString(@"alert_no_awake",nil) father:_gvs];
}
-(GameAlert*)showMessageWithSettingFormFather:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)canel key:(NSString *)_key father:(CCNode *)_gvs{
	//return [self showMessageWithSettingFormFather:_content target:_target confirm:_confirm key:_key tips:@"不再提醒" father:_gvs];
    return [self showMessageWithSettingFormFather:_content target:_target confirm:_confirm canel:canel key:_key tips:NSLocalizedString(@"alert_no_awake",nil) father:_gvs];
}

-(GameAlert*)showMessageWithSetting:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel key:(NSString *)_key
{
	if (!_key || _key.length <= 0){
		CCLOG(@"showMessageWithSetting->error->key");
		return nil;
	}
	MessageAlert *alert = nil;
	BOOL result = [[[GameConfigure shared] getPlayerRecord:_key] boolValue];
	if (!result) {
		alert = [MessageAlert node];
		alert.message=_content;
		alert.target=_target;
		alert.call=_confirm;
		alert.canel=_canel;
		alert.type=MessageAlert_setting;
		alert.recordKey=_key;
		alert.recordTips=NSLocalizedString(@"alert_no_awake",nil);
		[self addAlert:alert];
	}else{
		if (_target && _confirm) {
			[_target performSelector:_confirm];
		}
	}
	return alert;
}

-(GameAlert*)showMessageWithSetting:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key{
	//return [self showMessageWithSetting:_content target:_target confirm:_confirm key:_key tips:@"不再提醒"];
    return [self showMessageWithSetting:_content target:_target confirm:_confirm key:_key tips:NSLocalizedString(@"alert_no_awake",nil)];
}

-(GameAlert*)showMessageWithSetting:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key tips:(NSString *)_tips{
	if (!_key || _key.length <= 0){
		CCLOG(@"showMessageWithSetting->error->key");
		return nil;
	}
	MessageAlert *alert = nil;
	BOOL result = [[[GameConfigure shared] getPlayerRecord:_key] boolValue];
	if (!result) {
		alert = [MessageAlert node];
		alert.message=_content;
		alert.target=_target;
		alert.call=_confirm;
		alert.type=MessageAlert_setting;
		alert.recordKey=_key;
		alert.recordTips=_tips;
		[self addAlert:alert];
	}else{
		if (_target && _confirm) {
			[_target performSelector:_confirm];
		}
	}
	return alert;
}

-(GameAlert*)showUrgentMessageWithSetting:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key{
	//return [self showUrgentMessageWithSetting:_content target:_target confirm:_confirm key:_key tips:@"不再提醒"];
    return [self showUrgentMessageWithSetting:_content target:_target confirm:_confirm key:_key tips:NSLocalizedString(@"alert_no_awake",nil)];
}

-(GameAlert*)showUrgentMessageWithSetting:(NSString *)_content target:(id)_target confirm:(SEL)_confirm key:(NSString *)_key tips:(NSString *)_tips{
	if (!_key || _key.length <= 0){
		CCLOG(@"showMessageWithSetting->error->key");
		return nil;
	}
	MessageAlert *alert = nil;
	BOOL result = [[[GameConfigure shared] getPlayerRecord:_key] boolValue];
	if (!result) {
		alert = [MessageAlert node];
		alert.message=_content;
		alert.target=_target;
		alert.call=_confirm;
		alert.isUrgent = YES ;
		alert.type=MessageAlert_setting;
		alert.recordKey=_key;
		alert.recordTips=_tips;
		[alert show];
	}else{
		if (_target && _confirm) {
			[_target performSelector:_confirm];
		}
	}
	return alert;
}

-(void)showNPCMessage:(NSString*)_content npcId:(int)npcId target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel{
	
	MessageNPCAlert *alert = [MessageNPCAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.canel=_canel;
	alert.npcId = npcId;
	[self addAlert:alert];
	
}


-(void)showGoodMessage:(NSString *)_content type:(int)_type good:(int)_good
				target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel
				   key:(NSString *)_key tips:(NSString *)_tips father:(CCNode *)_father{
	BOOL result = [[[GameConfigure shared] getPlayerRecord:_key] boolValue];
	if (!result) {
		GoodAlert *alert = [GoodAlert node];
		alert.message=_content;
		alert.target=_target;
		alert.call=_confirm;
		alert.canel=_canel;
		alert.goodId=_good;
		alert.goodType = _type;
		alert.recordKey = _key;
		alert.recordTips = _tips;
		alert.father = _father;
		[self addAlert:alert];
	}else{
		if (_target && _confirm) {
			[_target performSelector:_confirm];
		}
	}
}

-(void)showActivity:(NSDictionary*)activity{
//	AlertActivity * alert = [AlertActivity node];
//	alert.activity = activity;
//	[self addAlert:alert];
}

-(GameAlert*)showError:(NSString*)_content target:(id)_target confirm:(SEL)_confirm father:(CCNode*)_father{
	MessageAlert *alert = [MessageAlert node];
	alert.message=_content;
	alert.target=_target;
	alert.call=_confirm;
	alert.father=_father;
	alert.type=MessageAlert_error;
	[self addAlert:alert];
	return alert;
}

-(void)showTaskAlert:(id)_task target:(id)_target call:(SEL)_call{
	CCLOG(@"showTaskAlert:add!!!");
	TaskAlert *alert = [TaskAlert node];
	alert.target = _target;
	alert.call = _call;
	alert.task = _task;
	[self addAlert:alert];
}
-(void)showTaskAlert:(Task *)_task target:(id)_target call:(SEL)_call useInfo:(BOOL)_info{
	TaskAlert *alert = [TaskAlert node];
	alert.target = _target;
	alert.call = _call;
	alert.task = _task;
	alert.bNeedInfo = _info;
	[self addAlert:alert];
}
-(void)addAlert:(id)target{
	
	[alerts addObject:target];
	CCLOG(@"AlertManager->addAlert: %d",[alerts count]);
	if (!runningAlert && [alerts count] > 0) {
		/*
		 runningAlert = [alerts objectAtIndex:0];
		 [runningAlert retain];
		 [alerts removeObjectAtIndex:0];
		 [runningAlert show];
		 */
		//		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
		//									   selector:@selector(checkAlert)
		//									   userInfo:nil
		//										repeats:NO];
		
		[self checkAlert];
	}
}

-(void)remove{
	if (runningAlert){
		[runningAlert removeFromParentAndCleanup:YES];
		[runningAlert release];
		runningAlert = nil;
	}
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
								   selector:@selector(checkAlert)
								   userInfo:nil
									repeats:NO];
}
-(void)closeAlert{
	if (runningAlert){
		[runningAlert removeFromParentAndCleanup:YES];
		[runningAlert removeAllChildrenWithCleanup:YES];
		[alerts insertObject:runningAlert atIndex:0];
		runningAlert = nil;
	}
}
-(void)checkStatus{
	CCLOG(@"AlertManager checkStatus");
	if(runningAlert){
		[runningAlert show];
	}else{
		[self checkAlert];
	}
}

-(void)checkAlert{
	
	CCLOG(@"AlertManager checkAlert");
	if (runningAlert) return ;
	
	if([alerts count]>0){
		runningAlert = [alerts objectAtIndex:0];
		[runningAlert retain];
		[alerts removeObjectAtIndex:0];
		[runningAlert show];
		
	}
}
-(BOOL)alertEnter:(CCNode *)_object{
	if (!inLayer) {
		if (_object) {
			CGSize size = _object.contentSize;
			inLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:size.width	height:size.height];
			CCRenderTexture *inTexture = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
			inTexture.sprite.anchorPoint = ccp(0.5f,0.5f);
			inTexture.position = ccp(size.width/2, size.height/2);
			inTexture.anchorPoint = ccp(0.5f,0.5f);
			
			[inTexture begin];
			[_object visit];
			[inTexture end];
			
			_object.visible=NO;
			
			ccBlendFunc fFunc = {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA};
			[inTexture.sprite setBlendFunc:fFunc];
			[inTexture.sprite setOpacity:0];
			[inTexture.sprite runAction:[CCFadeTo actionWithDuration:2.0 opacity:255] ];
			[inLayer addChild:inTexture];
			[_object.parent addChild:inLayer];
			[NSTimer scheduledTimerWithTimeInterval:1.0f
											 target:self
										   selector:@selector(endEnter:)
										   userInfo:_object
											repeats:NO];
			
			return YES;
		}
	}
	return NO;
}

-(void)endEnter:(NSTimer*)_timer{
	if (inLayer) {
		[inLayer removeFromParentAndCleanup:YES];
		inLayer = nil;
	}
	GameAlert *tex = (GameAlert*)[_timer userInfo];
	if (tex) {
		tex.visible = YES;
	}
}
@end
