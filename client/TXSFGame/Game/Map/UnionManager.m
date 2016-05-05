//
//  UnionManager.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-29.
//  Copyright (c) 2013年 eGame. All rights reserved.
//
//	这个是同盟领地

#import "UnionManager.h"
#import "Game.h"
#import "GameUI.h"
#import "MapManager.h"
//#import "CCSimpleButton.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "RoleManager.h"
#import "Window.h"
#import "AlertManager.h"
#import "NPCManager.h"
#import "GameNPC.h"
#import "UnionBossManager.h"
#import "Arena.h"

#import "RoleManager.h"
#import "RolePlayer.h"

@implementation UnionManager


//77	同盟童女

//78	同盟童男

static UNION_ACTION_TYPE targetType;
static UnionManager * unionManager;

+(UnionManager*)shared{
	if(!unionManager){
		unionManager = [UnionManager node];
		[unionManager retain];
	}
	return unionManager;
}

+(void)stopAll{
	
	//[UnionManager quitUnion];
	
	targetType = UNION_ACTION_TYPE_none;
	
	if(unionManager){
		[unionManager removeFromParentAndCleanup:YES];
		[unionManager release];
		unionManager = nil;
	}
	
}

+(void)enterUnion{
	
	if(unionManager) return;
	[[UnionManager shared] start];
	
}
+(void)quitUnion{
	
	targetType = UNION_ACTION_TYPE_none;
	
	if(unionManager){
		[unionManager removeFromParentAndCleanup:YES];
		[unionManager release];
		unionManager = nil;
		[[Game shared] backToMap:nil call:nil];
	}
	
}
//fix chao
+(void)kickUnion{
	targetType = UNION_ACTION_TYPE_none;
	if(unionManager){
        [[GameConfigure shared] removePlayerAlly];
        [[Window shared] removeWindow:PANEL_UNION];
        [unionManager removeFromParentAndCleanup:YES];
		[unionManager release];
		unionManager = nil;
		[[Game shared] backToMap:nil call:nil];
        //fix chao
        RolePlayer *player = [RoleManager shared].player;
        if (player) {
            player.allyName=@"";
            [player updateViewer];
        }
        //end
	}
}

+(BOOL)checkIsUnionMember{
    NSDictionary* dict = [[GameConfigure shared] getPlayerAlly];
    return (dict != nil);
}
//end
+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_Union){
		
        if ([UnionManager checkIsUnionMember]) {
            if(unionManager){
                [unionManager showInMap];
                if(targetType!=UNION_ACTION_TYPE_none){
                    [unionManager startAction];
                }
            }else{
                [UnionManager enterUnion];
            }
        }else{
            [[Game shared] backToMap:nil call:nil];
        }
	}else{
        [UnionManager stopAll];
    }
}

+(void)doUnionAction:(UNION_ACTION_TYPE)type{
	[self endCurrentAction];
	targetType = type;
	
	if (targetType==UNION_ACTION_TYPE_MainChallenge) {
		[UnionBossManager enterUnionBoss];
	}else{
		if(unionManager){
			[unionManager startAction];
		}else{
			[UnionManager enterUnion];
		}
	}
}

+(void)endCurrentAction{
	if(unionManager){
		[unionManager endAction];
	}
}
+(void)showButton{
   	if(unionManager){
		[unionManager showAllButton];
	}
}
+(void)hideButton{
    if(unionManager){
		[unionManager hideAllButton];
	}
}
-(void)showAllButton{
    [close setVisible:YES];
    [ruleButton setVisible:YES];
}
-(void)hideAllButton{
    [close setVisible:NO];
    [ruleButton setVisible:NO];
}
-(void)start{
	int union_map_id = 1004;
	if([MapManager shared].mapId==union_map_id){
		[self showInMap];
	}else{
		[[Game shared] trunToMap:union_map_id target:self call:nil];
	}
}
//chao
-(void)toDoDonate{
	[UnionManager doUnionAction:UNION_ACTION_TYPE_DragonDonate];
    //[[Window shared] showWindow:PANEL_UNION_Dragon_Donate];
}
//chao
-(void)toDoExchange{
	[UnionManager doUnionAction:UNION_ACTION_TYPE_DragonExchange];
    //[[Window shared] showWindow:PANEL_UNION_Dragon_Exchange];
}

-(void)toDoEngrave{
	[UnionManager doUnionAction:UNION_ACTION_TYPE_Engrave];
}

-(void)toDoMoneyCat{
	[UnionManager doUnionAction:UNION_ACTION_TYPE_Cat];
}

-(void)showInMap{
	if(self.parent) return;
	//[[GameUI shared] addChild:self z:INT_MAX];
	self.visible = YES ;
	[[GameUI shared] addChild:self z:INT_MAX tag:GameUi_SpecialSystem_unionManager];
}

-(void)onEnter{
	[super onEnter];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	//fix chao
	NSArray *btns = getBtnSpriteForScale(@"images/ui/button/bt_backmap.png",1.1f);
	CCSprite *spr1 = [btns objectAtIndex:0];
	CCSprite *spr2 = [btns objectAtIndex:1];
	NSString *name = [[MapManager shared] getMapName];
	CCLabelFX *name1 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
	
    //    if (iPhoneRuningOnGame()) {
    //        name1.scale=FONT_SIZE_SCALE;
    //    }
	CCLabelFX *name2 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
    //    if (iPhoneRuningOnGame()) {
    //        name2.scale=FONT_SIZE_SCALE;
    //    }
	[spr1 addChild:name1];
	name1.position = ccp(spr1.contentSize.width/2 - cFixedScale(10), (spr1.contentSize.height)*1.2/2);
	[spr2 addChild:name2];
	name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(10), (spr2.contentSize.height)*1.2/2);
	close = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_backmap.png"];
	[close setNormalSprite:spr1];
	[close setSelectSprite:spr2];
    close.anchorPoint=ccp(1, 1);
	if (iPhoneRuningOnGame()) {
		close.scale=1.13f;
		close.position=ccp(winSize.width, winSize.height);
	}else{
		close.position=ccp(winSize.width, winSize.height);
	}
	
    /*
	CCSimpleButton * close = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
            close.position = ccp(winSize.width - close.contentSize.width/2+2, winSize.height - close.contentSize.height/2+3);
        }else{
            close.position = ccp(winSize.width - close.contentSize.width/2+2, winSize.height - close.contentSize.height/2+3);
        }
	}else{
		close.position = ccp(winSize.width-cFixedScale(40),winSize.height-cFixedScale(40));
	}
     */
    //end
	close.target = self;
	close.call = @selector(doClose:);
	[self addChild:close z:1 tag:37875];
	
	[[[NPCManager shared]getNPCById:78]setCalltarget:self];
	[[[NPCManager shared]getNPCById:78]setCall:@selector(toDoEngrave)];
	
	[[[NPCManager shared]getNPCById:77]setCalltarget:self];
	[[[NPCManager shared]getNPCById:77]setCall:@selector(toDoMoneyCat)];
    /*
    //chao TODO
	[[[NPCManager shared]getNPCById:78]setCalltarget:self];
	[[[NPCManager shared]getNPCById:78]setCall:@selector(toDoDonate)];
    
	//chao TODO
	[[[NPCManager shared]getNPCById:77]setCalltarget:self];
	[[[NPCManager shared]getNPCById:77]setCall:@selector(toDoExchange)];
    */
     //chao TODO
     [[[NPCManager shared]getNPCById:166]setCalltarget:self];
     [[[NPCManager shared]getNPCById:166]setCall:@selector(toDoDonate)];
     
     //chao TODO
     [[[NPCManager shared]getNPCById:167]setCalltarget:self];
     [[[NPCManager shared]getNPCById:167]setCall:@selector(toDoExchange)];
     
     
    //fix chao
    // 规则
	ruleButton = [RuleButton node];
	ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y));
	ruleButton.type = RuleType_unionMap;
	ruleButton.priority = -129;
	[self addChild:ruleButton z:1 tag:37874];
    //end
    [GameConnection addPost:ConnPost_KickApply_success target:[UnionManager class] call:@selector(kickUnion)];
    //
    [GameConnection addPost:ConnPost_ally_map_crystal_enter target:self call:@selector(crystalEnter)];
    //[GameConnection request:@"allyCrystalEnter" data:[NSDictionary dictionary] target:self call:@selector(didGetDonate:)];
    [self crystalEnter];
}
//
-(void)crystalEnter{
    [GameConnection request:@"allyCrystalEnter" data:[NSDictionary dictionary] target:self call:@selector(didGetDonate:)];
}
-(void)didGetDonate:(id)sender{
    if (checkResponseStatus(sender)) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        //
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
            int donateValue = [[dict objectForKey:@"glory"] intValue];
            NSString *str_ = [NSString stringWithFormat:NSLocalizedString(@"union_map_donate",nil),donateValue];
            CCLabelFX *donate_text = (CCLabelFX *)[self getChildByTag:57870];
            if (!donate_text) {
                donate_text = [CCLabelFX labelWithString:str_
                                                     dimensions:CGSizeMake(0,0)
                                                      alignment:kCCTextAlignmentCenter
                                                       fontName:getCommonFontName(FONT_1)
                                                       fontSize:21
                                                   shadowOffset:CGSizeMake(-1.5, -1.5)
                                                     shadowBlur:1.0f
                                                    shadowColor:ccc4(160,100,20, 128)
                                                      fillColor:ccc4(230, 180, 60, 255)];
                [self addChild:donate_text z:1 tag:57870];
                donate_text.position = ccp(winSize.width/2, winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y));
            }
            [donate_text setString:str_];
        }
	} else {
		CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
	}
}
//
-(void)onExit{
    //fix chao
    [GameConnection removePostTarget:[UnionManager class]];
    [GameConnection removePostTarget:self];
	[self removeChildByTag:37875 cleanup:YES];
	[self removeChildByTag:37874 cleanup:YES];
    [self removeChildByTag:57870 cleanup:YES];
	close = nil ;
	ruleButton = nil;
    //end
	[super onExit];
	if(currentAction){
		//[currentAction stop];
		[currentAction release];
		currentAction = nil;
	}

}

-(void)doClose:(id)sender{
    if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	[UnionManager quitUnion];
}

-(void)startAction{
	
	if(targetType==UNION_ACTION_TYPE_none) return;
	if(currentAction && currentAction.isRuning){
		targetType = UNION_ACTION_TYPE_none;
		return;
	}
	
	if(targetType==UNION_ACTION_TYPE_Cat){
		currentAction = [[UnionActionCat alloc] init];
		[currentAction start];
	}
	if(targetType==UNION_ACTION_TYPE_Engrave){
		currentAction = [[UnionActionEngrave alloc] init];
		[currentAction start];
	}
    else if(targetType==UNION_ACTION_TYPE_DragonDonate){
		currentAction = [[UnionActionDragonDonate alloc] init];
		[currentAction start];
	}
	else if(targetType==UNION_ACTION_TYPE_DragonExchange){
		currentAction = [[UnionActionDragonExchange alloc] init];
		[currentAction start];
	}
	
	targetType = UNION_ACTION_TYPE_none;
}
-(void)endAction{
	if(currentAction){
		[currentAction release];
		currentAction = nil;
	}
}

@end

#pragma mark - UnionAction

@interface UnionAction (Private)
-(NSDictionary*)loadActionDataByType:(UNION_ACTION_TYPE)type;
-(CGPoint)getActionPointByType:(UNION_ACTION_TYPE)type;
@end

@implementation UnionAction
@synthesize isRuning;
-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
	CCLOG(@"UnionAction dealloc");
}
-(void)start{
	isRuning = YES;
	[NSTimer scheduledTimerWithTimeInterval:0.1
									 target:self
								   selector:@selector(action)
								   userInfo:nil
									repeats:NO];
}

-(void)action{
	//TODO nothing...
}

-(void)stop{
	isRuning = NO;
	if(unionManager) [unionManager endAction];
}
-(NSDictionary*)loadActionDataByType:(UNION_ACTION_TYPE)type{
	NSArray * actions = [[MapManager shared] getFunctionData:@"object" key:@"action"];
	for(NSDictionary * action in actions){
		if([[action objectForKey:@"type"] intValue] == type){
			return action;
		}
	}
	return nil;
}
-(CGPoint)getActionPointByType:(UNION_ACTION_TYPE)type{
	NSDictionary * action = [self loadActionDataByType:type];
	if(action){
		int x = [[action objectForKey:@"x"] intValue];
		int y = [[action objectForKey:@"y"] intValue];
		CGPoint point = ccp(x,y);
        if (iPhoneRuningOnGame()) {
            point = ccp(point.x/2, point.y/2);
        }
		return point;
	}
	return ccp(-1,-1);
}
@end

#pragma mark - UnionActionCat
@implementation UnionActionCat
-(void)action{
	[GameConnection request:@"allyCatEnter" format:@"" target:self call:@selector(didGetAllyCat:)];
}

-(void)didGetAllyCat:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		int count = [[data objectForKey:@"cn"] intValue];
		if(count>0){
			[self doAction];
		}else{
			//[ShowItem showItemAct:@"活动已经结束"];
            [ShowItem showItemAct:NSLocalizedString(@"union_manager_finish",nil)];
		}
	}else{
		CCLOG(@"error allyCatEnter");
		[self stop];
	}
}
-(void)doAction{
	CGPoint point = [self getActionPointByType:UNION_ACTION_TYPE_Cat];
	if(point.x>0 && point.y>0){
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(didMoveToTargetPoint)
		 ];
	}else{
		[self stop];
	}
}
-(void)didMoveToTargetPoint{
	
	/*
	[[AlertManager shared]showMessage:@"是否要招财?" 
							   target:self 
							  confirm:@selector(doActionCat)
								canel:@selector(stop)
							   father:unionManager];
	*/
	/*
	[[AlertManager shared] showUrgentMessage:@"是否要招财?" 
									  target:self
									 confirm:@selector(doActionCat)
									   canel:@selector(stop)
									  father:unionManager];
	
	 */
	[[Window shared]showWindow:PANEL_UNION_Cat];
}

-(void)doActionCat{
	
	[GameConnection request:@"allyCat" format:@"" target:self call:@selector(didAllyCat:)];
	
	//------------------------------------
	//TODO show effect in map by NPC [cat]
	//------------------------------------
	
	
}

-(void)didAllyCat:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		if(data){

			//NSString *mstr[3]={@"银币",@"元宝",@"绑元宝"};
            NSString *mstr[3]={
                NSLocalizedString(@"union_manager_coin1",nil),
                NSLocalizedString(@"union_manager_coin2",nil),
                NSLocalizedString(@"union_manager_coin3",nil)};
			for(int i=0;i<3;i++){
				int coin=[[data objectForKey:[NSString stringWithFormat:@"coin%i",(i+1)]]integerValue];
				int mecoin=[[[[GameConfigure shared]getPlayerInfo] objectForKey:[NSString stringWithFormat:@"coin%i",(i+1)]]integerValue];
				if((coin-mecoin)>1){
					//[ShowItem showItemAct:[NSString stringWithFormat:@"获得 %@ X %i",mstr[i],coin-mecoin]];
                    [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_manager_get",nil),mstr[i],coin-mecoin]];
				}
			}
			[[GameConfigure shared] updatePackage:data];
		}
	}else{
		CCLOG(@"error allyCat");
	}
	[self stop];
}
@end

#pragma mark - UnionActionEngrave
@implementation UnionActionEngrave

-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

-(void)action{
	[GameConnection request:@"allyGraveEnter" format:@"" target:self call:@selector(didGetAllyEngrave:)];
}
-(void)didGetAllyEngrave:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		int gn1 = [[data objectForKey:@"gn1"] intValue];
		int gn2 = [[data objectForKey:@"gn2"] intValue];
		if(gn1>0 || gn2>0){
			[self doAction];
		}else{
			//[ShowItem showItemAct:@"活动已经结束"];
            [ShowItem showItemAct:NSLocalizedString(@"union_manager_finish",nil)];
		}
	}else{
		CCLOG(@"error allyGraveEnter");
		[self stop];
	}
}
-(void)doAction{
	CGPoint point = [self getActionPointByType:UNION_ACTION_TYPE_Engrave];
	if(point.x>0 && point.y>0){
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(didMoveToTargetPoint)
		 ];
	}else{
		[self stop];
	}
}
-(void)didMoveToTargetPoint{
	
	if(!unionManager) return;
	
	[NSTimer scheduledTimerWithTimeInterval:0.01f
									 target:self 
								   selector:@selector(openWindow) 
								   userInfo:nil
									repeats:NO];
	
}

-(void)openWindow{
	[[Window shared] showWindow:PANEL_UNION_Engrave];
}
@end

#pragma mark - UnionActionDragonDonate
@implementation UnionActionDragonDonate

-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

-(void)action{
    //TODO
	//[GameConnection request:@"allyDonateEnter" format:@"" target:self call:@selector(didGetAllyDonate:)];
    [self doAction];
}
/*
-(void)didGetAllyDonate:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		int gn1 = [[data objectForKey:@"gn1"] intValue];
		int gn2 = [[data objectForKey:@"gn2"] intValue];
		if(gn1>0 || gn2>0){
			[self doAction];
		}else{
			//[ShowItem showItemAct:@"活动已经结束"];
            [ShowItem showItemAct:NSLocalizedString(@"union_manager_finish",nil)];
		}
	}else{
		CCLOG(@"error allyDonateEnter");
		[self stop];
	}
}
 */
-(void)doAction{
    //[self openWindow];
    //return;
    //
	CGPoint point = [self getActionPointByType:UNION_ACTION_TYPE_DragonDonate];
	if(point.x>0 && point.y>0){
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(didMoveToTargetPoint)
		 ];
	}else{
		[self stop];
	}
}
-(void)didMoveToTargetPoint{
	
	if(!unionManager) return;
	
	[NSTimer scheduledTimerWithTimeInterval:0.01f
									 target:self
								   selector:@selector(openWindow)
								   userInfo:nil
									repeats:NO];
	
}

-(void)openWindow{
	[[Window shared] showWindow:PANEL_UNION_Dragon_Donate];
}

@end

#pragma mark - UnionActionDragonExchange
@implementation UnionActionDragonExchange

-(void)dealloc{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

-(void)action{
    //TODO
	//[GameConnection request:@"allyExchangeEnter" format:@"" target:self call:@selector(didGetAllyExchange:)];
    [self doAction];
}
/*
-(void)didGetAllyExchange:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		int gn1 = [[data objectForKey:@"gn1"] intValue];
		int gn2 = [[data objectForKey:@"gn2"] intValue];
		if(gn1>0 || gn2>0){
			[self doAction];
		}else{
			//[ShowItem showItemAct:@"活动已经结束"];
            [ShowItem showItemAct:NSLocalizedString(@"union_manager_finish",nil)];
		}
	}else{
		CCLOG(@"error allyExchaegeEnter");
		[self stop];
	}
}
 */
-(void)doAction{
    //[self openWindow];
    //return;
    //
	CGPoint point = [self getActionPointByType:UNION_ACTION_TYPE_DragonExchange];
	if(point.x>0 && point.y>0){
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(didMoveToTargetPoint)
		 ];
	}else{
		[self stop];
	}
}
-(void)didMoveToTargetPoint{
	
	if(!unionManager) return;
	
	[NSTimer scheduledTimerWithTimeInterval:0.01f
									 target:self
								   selector:@selector(openWindow)
								   userInfo:nil
									repeats:NO];
	
}

-(void)openWindow{
	[[Window shared] showWindow:PANEL_UNION_Dragon_Exchange];
}

@end