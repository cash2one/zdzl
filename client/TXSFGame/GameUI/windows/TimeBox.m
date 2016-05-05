//
//  TimeBox.m
//  TXSFGame
//
//  Created by Max on 12-12-28.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "TimeBox.h"
#import "CJSONDeserializer.h"
#import "Game.h"
#import "GameDB.h"
#import "GameConfigure.h"
#import "Window.h"
#import "GameNPC.h"
#import "GameConnection.h"
#import "MapManager.h"
#import "NPCManager.h"
#import "GameLayer.h"
#import "PageConsole.h"
#import "FightManager.h"
#import "CJSONDeserializer.h"
#import "MessageBox.h"
#import "CFDialog.h"
#import "MapManager.h"
#import "Game.h"
#import "MovingAlert.h"
#import "GameLoading.h"
#import "RolePlayer.h"
#import "TaskManager.h"
#import "InfoAlert.h"
#import "Arena.h"

#define PosX self.contentSize.width
#define PosY self.contentSize.height
#define FONTNAME @"Verdana-Bold"
#define BT_CHANGLEFT_CHAPTER 1
#define BT_CHANGRIGHT_CHAPTER 2

#define BT_RESET 3
#define BT_SECKILL 4
#define BT_SECKILL_DIS 13
#define BG_TITLE 5
#define BG_MOMEY 6
#define NPC_MIDLLE 7
#define BG_PACKUP 8
#define BG_PACKUP_IN 9
#define BT_PACKUP 10
#define BG_RANK 11
#define BG_REWARDTIPS 12
#define BTN_ITEMBOX 9000
#define NPC_BOSS 100



#define CGS_LAYER_WIDTH   cFixedScale(350)
#define CGS_LAYER_HEIGHT  cFixedScale(63)
#define POS_LAYER    ccp(cFixedScale(600),cFixedScale(370))
#define POS_P1_ADD_X cFixedScale(10)
#define POS_P1_ADD_Y cFixedScale(30)
#define POS_CURRENBOX_ADD_Y cFixedScale(800)
#define POS_PACKUP_BTN_Y  cFixedScale(-50)
#define POS_ITEMSP_Y   cFixedScale(20)
#define CGS_ITEMPACKBG_ADD_X  cFixedScale(100)
#define CGS_ITEMPACKBG_Y   cFixedScale(40)
#define CGS_RANK_BG_WIDTH  cFixedScale(220)
#define CGS_RANK_BG_HEIGHT  cFixedScale(150)
#define POS_RANK_BG_ADD_X  cFixedScale(100)
#define POS_RANK_BG_ADD_Y  cFixedScale(50)
#define VALUE_RANK_BG_HEIGHT  cFixedScale(60)
#define POS_P  ccp(0, cFixedScale(170))
#define POS_TARGET  ccp(cFixedScale(-50), cFixedScale(50))
#define POS_PP_ADD ccp(0, cFixedScale(150))
#define POS_BASEX_X_WIDTH cFixedScale(30)
#define POS_STAR_ADD_Y  cFixedScale(10)


#define TimeBox_shineOver_tag		10228
#define TimeBox_shineUnder_tag		10229


@implementation TimeBox

static TimeBox* s_TimeBox;

@synthesize isOpened;

+(TimeBox*)share{
	if (nil == s_TimeBox){
        s_TimeBox = [TimeBox node];
		[s_TimeBox retain];
    }
    return s_TimeBox;
}

+(void)stopAll{
	if(s_TimeBox){
		if(s_TimeBox.parent){
			[s_TimeBox removeFromParentAndCleanup:YES];
		}
		[s_TimeBox release];
		s_TimeBox = nil;
	}
}

+(void)visibleTimeBox:(BOOL)_visable{
	if (s_TimeBox != nil){
		s_TimeBox.visible = _visable ;
	}
}

+(void)enterTimeBox{
	CCLOG(@"TimeBox enterTimeBox------");
	if([MapManager shared].mapId==1002)return;
	
	[GameConfigure shared].isCanSendMove = NO;
	
	[MovingAlert remove];
	[TimeBox share];
	[[Game shared] trunToMap:1002];
}

+(void)quitTimeBox{
	if(s_TimeBox){
		if(s_TimeBox.parent){
			[s_TimeBox removeFromParentAndCleanup:YES];
		}
		[s_TimeBox release];
		s_TimeBox = nil;
		int mid = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"preMId"] intValue];
		if (mid > 0) {
			[[Game shared] trunToMap:mid target:nil call:nil];
		}else{
			NSDictionary* dict = [[GameConfigure shared] getChooseChapter];
			mid = [[dict objectForKey:@"mid"] intValue];
			[[Game shared] trunToMap:mid target:nil call:nil];
		}
	}
	
	//关闭时光盒的时候检查任务
	[[TaskManager shared] checkStepStatusByCloseTimeBox];
	
	[GameConfigure shared].isCanSendMove = YES;
}

+(void)checkStatus{
	if ([MapManager shared].mapType == Map_Type_TimeBox) {
		CCLOG(@"TimeBox checkStatus------");
		if(s_TimeBox){
			//[[Game shared] addChild:s_TimeBox z:INT32_MAX-100];
            [[Game shared] addChild:s_TimeBox z:0];
		}else{
			//[[Game shared] backToMap:nil call:nil];
			//todo
			//检查会不会出现其他跳转地图的问题
			[GameConfigure shared].isCanSendMove = NO;
			[MovingAlert remove];
			[[Game shared] addChild:[TimeBox share] z:0];
			
		}
	}else{
		[TimeBox stopAll];
	}
}

-(void)onEnter{
    [super onEnter];
	CCLOG(@"TimeBox onEnter------");
    isSend = NO;
	currenChapter=0;
	isOpenedGetItem=true;
	isFightBack=false;
	maxChapter=[[[[GameConfigure shared]getPlayerInfo] objectForKey:@"chapter"] integerValue];
	currenChapter=maxChapter;
	if(!isOpened){
		//添加场景重所有按钮
		{
			menu = [CCMenu node];
			CCSprite *button_bg=[CCSprite spriteWithFile:@"images/ui/timebox/button_bg.png"];
			CCMenuItemImage *close = makeMenuItemImageBtn(@"images/ui/button/bt_back.png", 1.1f, self, @selector(menuCallbackBack:));
			
			CCMenuItemImage *reset_bt=makeMenuItemImageBtn(@"images/ui/timebox/bt_reset.png", 1.1f, self, @selector(menuCallbackBack:));
			CCMenuItemImage *skill_bt=makeMenuItemImageBtn(@"images/ui/timebox/bt_skill.png", 1.1f, self, @selector(menuCallbackBack:));
			
			CCSprite *skill_bt_dis=[CCSprite spriteWithFile:@"images/ui/timebox/bt_skill2.png"];
			CCMenuItemImage *changeleft= makeMenuItemImageBtn(@"images/ui/timebox/bt_change_chapter.png", 1.1f, self, @selector(menuCallbackBack:));
			CCMenuItemImage *changeright= makeMenuItemImageBtn(@"images/ui/timebox/bt_change_chapter.png", 1.1f, self, @selector(menuCallbackBack:));
			
			
			
			menu.ignoreAnchorPointForPosition = YES;
			menu.position = CGPointZero;
            [button_bg setPosition:ccp(cFixedScale(880), cFixedScale(730))];
            if (iPhoneRuningOnGame()) {
                close.anchorPoint = ccp(0.5,0.25);
                close.contentSize = CGSizeMake(close.contentSize.width, close.contentSize.height*2);
            }
            close.position = ccp(PosX-cFixedScale(52), PosY-cFixedScale(35));
            reset_bt.position=ccp(PosX-cFixedScale(143+FULL_WINDOW_RULE_OFF_X2), PosY-cFixedScale(35));
            skill_bt.position=ccp(PosX-cFixedScale(235+FULL_WINDOW_RULE_OFF_X2), PosY-cFixedScale(35));
            skill_bt_dis.position=ccp(PosX-cFixedScale(235+FULL_WINDOW_RULE_OFF_X2),PosY-cFixedScale(35));
            
            [changeleft setPosition:ccp(changeleft.contentSize.width/2, PosY-cFixedScale(200))];
            [changeright setPosition:ccp(PosX-changeleft.contentSize.width/2,PosY-cFixedScale(200))];
			
			close.tag = BT_CLOSE_WIN_TAG;
			reset_bt.tag=BT_RESET;
			skill_bt.tag=BT_SECKILL;
			changeleft.tag=BT_CHANGLEFT_CHAPTER;
			changeright.tag=BT_CHANGRIGHT_CHAPTER;
			skill_bt_dis.tag=BT_SECKILL_DIS;
			
			[self addChild:button_bg];
			[self addChild:skill_bt_dis];
			[menu addChild:close];
			[menu addChild:reset_bt];
			[menu addChild:skill_bt];
			
			[changeleft setScaleX:-1];
			[menu addChild:changeleft];
			[menu addChild:changeright];
			[self addChild:menu];
			[menu setHandlerPriority:-57];
            // 规则
            //fix chao
			ruleButton = [RuleButton node];
            ruleButton.position = ccp(close.position.x- cFixedScale(FULL_WINDOW_RULE_OFF_X2), close.position.y-cFixedScale(WINDOW_RULE_OFF_Y));
            ruleButton.type = RuleType_timeBox;
            ruleButton.priority = -57;
            [self addChild:ruleButton];
            //end
		}
		//小型金钱窗口 及标题
		{
			moneyBox=[GameMoneyMini node];
			[moneyBox setAnchorPoint:ccp(0,1)];
			[moneyBox setPosition:ccp(0, PosY)];
			[self addChild:moneyBox];
		}
		isOpened=true;
		
	}
	[[RoleManager shared] otherPlayerVisible:NO];
	[self getTheMapPoint];
	[self requestEnterTimeBox];
    
	
}

-(void)onExit
{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	[[[GameLayer shared] content] removeChildByTag:TimeBox_shineOver_tag cleanup:YES];
	[[[GameLayer shared] content] removeChildByTag:TimeBox_shineUnder_tag cleanup:YES];
    
    CCNode *node_ = [[[GameLayer shared]content ] getChildByTag:BTN_ITEMBOX];
    if (node_) {
        [node_ removeFromParentAndCleanup:true];
        currenBox=nil;
    }
	
	[GameConnection freeRequest:self];
	
	[super onExit];
}

-(void)hideTopMenu:(bool)n{
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
	
	if(n){
		[menu setVisible:NO];
		[[self getChildByTag:BG_MOMEY]setVisible:NO];
		[[self getChildByTag:BG_TITLE]setVisible:NO];
		ruleButton.visible=NO;
		
	}else{
		[menu setVisible:YES];
		[[self getChildByTag:BG_MOMEY]setVisible:YES];
		[[self getChildByTag:BG_TITLE]setVisible:YES];
		ruleButton.visible=YES;
	}
}



#pragma mark 按钮回调函数
-(void)menuCallbackBack:(id)sender
{
    if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	
	CCLOG(@"timeBox:menuCallbackBack");
	if(isclickMnpc){
		return;
	}

	CCNode *temp = (CCNode*)sender;
    if (isSend) {
        if (temp.tag == BT_CLOSE_WIN_TAG) {
            [TimeBox quitTimeBox];
        }
        return;
    }
	switch (temp.tag) {
		case BT_CLOSE_WIN_TAG:{
			[TimeBox quitTimeBox];
		}
			break;
		case BT_CHANGLEFT_CHAPTER:{
			if(isOpenedGetItem){
				return;
			}
			
			if(currenChapter>2){
				currenChapter--;
				isPlaySendEf=false;
				[GameConnection request:@"tBoxEnter" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
                isSend = YES;
			}
		}
			break;
		case BT_CHANGRIGHT_CHAPTER:{
			if(isOpenedGetItem){
				return;
			}
			if(currenChapter<currenMaxChapter){
				currenChapter++;
				isPlaySendEf=false;
				[GameConnection request:@"tBoxEnter" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
                isSend = YES;
			}
		}
			break;
		case BT_RESET:{
			if(isOpenedGetItem){
				return;
			}
			if(dieCount==0){
				//[ShowItem showItemAct:@"无需重置"];
                [ShowItem showItemAct:NSLocalizedString(@"time_box_without_reset",nil)];
				return;
			}
			
			if(freeResetTime==0 && resetTime==0){
				//[ShowItem showItemAct:@"无重置次数"];
                [ShowItem showItemAct:NSLocalizedString(@"time_box_no_reset_count",nil)];
				return;
			}
			if(freeResetTime==0 && resetTime>0){
				NSArray *arrayTime=[[[[GameDB shared]getGlobalConfig]objectForKey:@"tboxCoins"]componentsSeparatedByString:@"|"];
				//				if(resetTime>3){
				//					resetTime=3;
				//				}
				needmoney=[[arrayTime objectAtIndex:0]integerValue] * dieCount;
				//NSString *strtips=[NSString stringWithFormat:@"重置时光盒需要扣取 %i 元宝",needmoney];
				NSString *strtips=[NSString stringWithFormat:NSLocalizedString(@"time_box_reset_spend",nil),needmoney];
                
				[[AlertManager shared] showMessageWithSetting:strtips target:self confirm:@selector(doBuyTimeboxReset) key:@"timebox.isbuyopen"];
				return;
			}
			if(freeResetTime>=1){
				[GameConnection request:@"tBoxReset" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
				isPlaySendEf=true;
				isBuyResetBack=true;
                isSend = YES;
				return;
			}
			
			
			[self doBuyTimeboxReset];
		}
			break;
		case BT_SECKILL:{
			if(isOpenedGetItem || !hasBoss){
				return;
			}
			[GameConnection request:@"tBoxKill" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
            isSend = YES;
		}
			break;
		default:
			break;
	}
}



#pragma mark 买重置次数
-(void)doBuyTimeboxReset{
	
	if([moneyBox getCoin:3]<needmoney && [moneyBox getCoin:2]<needmoney){
		//[ShowItem showItemAct:@"没有足够元宝"];
        [ShowItem showItemAct:NSLocalizedString(@"time_box_no_yuanbao",nil)];
		return;
	}
	[GameConnection request:@"tBoxReset" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
	isPlaySendEf=true;
	isBuyResetBack=true;
    isSend = YES;
}



#pragma mark 获取地图信息
-(void)getTheMapPoint{
	if(point6){
		[point6 release];
	}
	point6=[[NSMutableArray alloc]init];
	NSArray *npcar1=[[MapManager shared]getFunctionRect:@"animation" key:@"chest"];
	[point6 addObject:[npcar1 objectAtIndex:0]];
	m=[npcar1 objectAtIndex:0];
	for(int i=1;i<6;i++){
		NSArray *npcar=[[MapManager shared]getFunctionRect:@"animation" key:[NSString stringWithFormat:@"enemy%i",i]];
		[point6	addObject:[npcar objectAtIndex:0]];
	}
	
}



#pragma mark 时光盒配置表信息
-(NSDictionary*)getTimeBox:(int)n{
	return [[GameDB shared]getTimeBoxInfo:n];
}


#pragma mark 点击NPC回调
-(void)eventClickNPC:(id)sender{
	if(isOpenedGetItem){
		return;
	}
    if (isSend) {
        return;
    }
	GameNPC * node=(GameNPC*)sender;
	if(node.tag==NPC_MIDLLE ){
		node.visible=false;
		if(isclickMnpc){
			return;
		}
		isclickMnpc=true;
		for(int i=0;i<boss_npc.count;i++){
			NSDictionary *npc=[boss_npc objectAtIndex:i];
			NSString *strlive=[NSString stringWithFormat:@"%@",[npc objectForKey:@"isLives"]] ;
			if([strlive isEqualToString:@"1"]){
				[GameEffectsBlockTouck lockScreen];
				[[Intro share]removeInCurrenTipsAndNextStep:INTRO_TimeBox_Step_1];
				int	mid=[[npc objectForKey:@"mid"]integerValue];
				currenNPCid=i;
				boxzOrder=[[NPCManager shared] getNPCById:mid].zOrder;
				
				[[[NPCManager shared]getNPCById:mid]setVisible:NO];
				CGPoint srcp = [[MapManager shared]getPositionToTile:getTiledRectCenterPoint(m.CGRectValue)];
				//NSArray *actar=[AnimationViewer loadFileByFileFullPath:@"images/effects/npc-effect/4/" name:@"%d.png"];
				
				srcp = [[MapManager shared] getTileToPosition:srcp];
				
				[[RoleManager shared]movePlayerTo:ccp(srcp.x,srcp.y-cFixedScale(100))];
				srcp =ccpAdd(srcp, ccp(0, cFixedScale(380)));
				AnimationViewer *spriteLigth=[AnimationViewer node];
				[spriteLigth showAnimationByPathOne:@"images/effects/npc-effect/4/%d.png"];
				//NSArray actar1=[ AnimationViewer ]
				CCSprite *sprite=spriteLigth;
				[sprite setPosition:srcp];
				//id anim=[CCAnimation animationWithSpriteFrames:actar delay:0.1];
				//id animt=[CCAnimate actionWithAnimation:anim];
				id delay=[CCDelayTime actionWithDuration:0.6];
				id callback=[CCCallBlock actionWithBlock:^{
					[[NPCManager shared]addNPCById:mid tilePoint:[[MapManager shared]getPositionToTile:getTiledRectCenterPoint(m.CGRectValue)] direction:1];
				}];
				id seq=[CCSequence actions:delay,callback, nil];
				[self runAction:seq];
				[[[GameLayer shared]content]addChild:sprite z:boxzOrder];
				[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(startFigth) userInfo:nil repeats:NO];
				//				{
				//					NSString *str=[NSString stringWithFormat:@"chapter::%i",currenChapter];
				//					[GameConnection request:@"tBoxHitEnd" format:str target:self call:@selector(didrequest:)];
				//				}
				int boxid=[[npc objectForKey:@"id"]integerValue];
				NSString *str=[NSString stringWithFormat:@"chapter::%i|tbid::%i",currenChapter,boxid];
				[GameConnection request:@"tBoxRank" format:str target:self call:@selector(didrequest:)];
				currenOtherNPCid=i;
                isSend = YES;
				break;
			}
		}
	}else{
		[self removeChildByTag:BG_RANK cleanup:YES];
		[self removeChildByTag:BG_REWARDTIPS cleanup:YES];
		NSDictionary *npc=[boss_npc objectAtIndex:node.tag-100];
		int boxid=[[npc objectForKey:@"id"]integerValue];
		int rid=[[npc objectForKey:@"rid"]integerValue];
		NSString *str=[NSString stringWithFormat:@"chapter::%i|tbid::%i",currenChapter,boxid];
		[GameConnection request:@"tBoxRank" format:str target:self call:@selector(didrequest:)];
		currenOtherNPCid=node.tag-100;
		[self showRewardTips:rid];
        isSend = YES;
	}
}

#pragma mark 奖励提示
-(void)showRewardTips:(int)rewardid{
	CCLOG(@"%@",[[GameDB shared]getRewardInfo:rewardid]);
	[self removeChildByTag:BG_REWARDTIPS cleanup:YES];
	CCLayerColor *layer=[CCLayerColor layerWithColor:ccc4(20, 20, 20, 200) width:CGS_LAYER_WIDTH height:CGS_LAYER_HEIGHT];
    if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			[layer setPosition:ccp(600/2 + 44, 370/2)];
		}else{
			[layer setPosition:ccp(600/2, 370/2)];
		}
    }else{
       	[layer setPosition:ccp(600, 500)];
	}
	[self addChild:layer z:-1 tag:BG_REWARDTIPS];
	NSDictionary *npc=[boss_npc objectAtIndex:currenOtherNPCid];
	int mid=[[npc objectForKey:@"mid"]integerValue];
	NSString *mosnamestr=[[[GameDB shared]getNpcInfo:mid]objectForKey:@"name"];
	CCLabelTTF *mosname=[CCLabelTTF labelWithString:mosnamestr fontName:getCommonFontName(FONT_1) fontSize:16];
	[mosname setAnchorPoint:ccp(0,0)];
    mosname.scale = cFixedScale(1);
    [mosname setPosition:ccp(cFixedScale(10),layer.contentSize.height- cFixedScale(mosname.contentSize.height) -cFixedScale(10))];			//Kevin Fixed, before cFixeScale(3)
	[layer addChild:mosname];
	int level=[[npc objectForKey:@"level"]integerValue];
	int basex=mosname.contentSize.width+POS_BASEX_X_WIDTH;
	for(int i=0;i<5;i++){
		CCSprite *star=[CCSprite spriteWithFile:@"images/ui/timebox/star.png"];
		[star setPosition:ccp(basex+i*POS_BASEX_X_WIDTH,mosname.position.y+POS_STAR_ADD_Y)];
		[layer addChild:star];
		if(level>i){
			CCSprite *star_select=[CCSprite spriteWithFile:@"images/ui/timebox/star_select.png"];
			[star_select setPosition:ccp(basex+i*POS_BASEX_X_WIDTH,mosname.position.y+POS_STAR_ADD_Y)];
			[layer addChild:star_select];
		}
	}
	NSString *rewardstr= [[[GameDB shared]getRewardInfo:rewardid]objectForKey:@"info"];
	
	//Kevin added and modified
	//	rewardstr=[NSString stringWithFormat:@"掉落物品:#ffffff#16#0|%@",rewardstr];
	//	CCNode *font=[MessageBox create:rewardstr target:self sel:nil];
	//    font.scale = cFixedScale(1);
	//    [font setPosition:ccp(cFixedScale(48), layer.contentSize.height- cFixedScale(mosname.contentSize.height) - cFixedScale(3) - cFixedScale(font.contentSize.height))];
	//	[font setIgnoreAnchorPointForPosition:NO];
	//	[font setAnchorPoint:ccp(0, 0)];
	//	[layer addChild:font];
	//NSString *dropStr = [NSString stringWithFormat:@"掉落物品#ffffff#16#2|"];
    NSString *dropStr = [NSString stringWithFormat:NSLocalizedString(@"time_box_drop",nil)];
	rewardstr = [NSString stringWithFormat:@"#ffffff#16#0|%@",rewardstr];
	CCNode *dropNode = [MessageBox create:dropStr target:self sel:nil];
	CCNode *rewardNode = [MessageBox create:rewardstr target:self sel:nil];
	dropNode.scale = rewardNode.scale = cFixedScale(1);
	[dropNode setPosition:ccp(cFixedScale(42), layer.contentSize.height- cFixedScale(mosname.contentSize.height) - cFixedScale(22) - cFixedScale(dropNode.contentSize.height))];
	[dropNode setIgnoreAnchorPointForPosition:NO];
	[dropNode setAnchorPoint:ccp(0, 0)];
	rewardNode.position = ccp(dropNode.position.x + cFixedScale(80), dropNode.position.y+1);
	if (iPhoneRuningOnGame()) {
		rewardNode.position = ccpAdd(rewardNode.position, ccp(0, -1));
	}
	[layer addChild:dropNode];
	[layer addChild:rewardNode];
	//--------------------------//
}


#pragma mark 开始战斗
-(void)startFigth{
	[GameEffectsBlockTouck unlockScreen];
	[self setVisible:NO];
	CCLOG(@"open figth");
	[self removeChildByTag:BG_RANK cleanup:YES];
	[self removeChildByTag:BG_REWARDTIPS cleanup:YES];
	[self hideTopMenu:YES];
	
	NSDictionary *dict=[boss_npc objectAtIndex:currenNPCid];
	int fid = [[dict objectForKey:@"fid"]integerValue];
	[[FightManager shared] startFightById:fid target:self call:@selector(didFigth)];
}

//完成战斗回调
-(void)didFigth{
	CCLOG(@"figthcallback");
	
	[self setVisible:YES];
	[self hideTopMenu:NO];
	NSDictionary *dict=[boss_npc objectAtIndex:currenNPCid];
	int level=[[dict objectForKey:@"level"] integerValue];
	if([[FightManager shared]isWin]){
		figthSub=[[NSString alloc]initWithString:[[FightManager shared]getFigthSub]];
		int rid=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"rid"]integerValue];
		BaseAttribute attr=[[GameConfigure shared]getRoleAttribute:rid isLoadOtherBuff:YES];
		int figthpower=getBattlePower(attr);
		int die_left_kind=[FightManager shared].dieLeftkindCount;
		NSString *str;
		str=[NSString stringWithFormat:@"chapter::%i",currenChapter];
		if(level<die_left_kind){
			str=[NSString stringWithFormat:@"%@|level::%i",str,die_left_kind];
		}
		if(level==0){
			str=[NSString stringWithFormat:@"%@|fight::%i",str,figthpower];
		}
		[GameConnection request:@"tBoxHitEnd" format:str target:self call:@selector(didrequest:)];
        isSend = YES;
	}else{
		[self getTheMapPoint];
		[self requestEnterTimeBox];
	}
}





-(void)requestEnterTimeBox{
	[GameConnection request:@"tBoxEnter" format:[NSString stringWithFormat:@"chapter::%i",currenChapter] target:self call:@selector(didrequest:)];
    isSend = YES;
}

#pragma  mark 网络回调
-(void)didrequest:(NSDictionary*)data{
    
	int reponsest=[[data objectForKey:@"s"]intValue];
	if(reponsest==0 ){
		if([[data objectForKey:@"m"]integerValue] !=125){
			[ShowItem showErrorAct:[data objectForKey:@"m"]];
		}
        isSend = NO;
		return;
	}
	if ([[data objectForKey:@"f"] isEqual:@"tBoxEnter"]) {
		[self handlertBoxEnter:[data objectForKey:@"d"]];
	}
	if ([[data objectForKey:@"f"] isEqual:@"tBoxReset"]) {
		[self handlertBoxEnter:[data objectForKey:@"d"]];
	}
	if ([[data objectForKey:@"f"] isEqual:@"tBoxHitEnd"]){
		[self handlertFightDone:[data objectForKey:@"d"]];
	}
	if([[data objectForKey:@"f"] isEqual:@"tBoxRank"]){
		[self handlerRank:[data objectForKey:@"d"]];
	}
	if([[data objectForKey:@"f"] isEqual:@"tBoxKill"]){
		[self handlerSkill:[data objectForKey:@"d"]];
	}
	isSend = NO;
}


#pragma mark 宝箱震屏
-(void)boxActionDone
{
	[[GameEffects share] showEffects:EffectsAction_loshing target:nil call:nil];
}

#pragma mark 创建宝箱
-(void)creatbox:(bool)isOpen items:(NSArray*)_items isMove:(bool)_isMove{
	isOpenedGetItem=true;
	currenBox=[CCSimpleButton spriteWithFile:@"images/ui/timebox/box_close.png" select:@"images/ui/timebox/box_close.png"];
	[currenBox setTarget:self];
	[currenBox setCall:@selector(openbox:)];
	[currenBox setUserObject:_items];
	CGPoint p1 = [[MapManager shared]getPositionToTile:getTiledRectCenterPoint(m.CGRectValue)];
	p1= [[MapManager shared] getTileToPosition:p1];
	p1=ccp(p1.x-POS_P1_ADD_X, p1.y+POS_P1_ADD_Y);
	[currenBox setPosition:p1];
	currenBox.priority = -1;
	if(_isMove){
		[currenBox setPosition:ccp(p1.x, p1.y+POS_CURRENBOX_ADD_Y)];
		id act=[CCMoveTo actionWithDuration:1 position:p1];
		[currenBox runAction:[CCSequence actions:act, [CCCallFunc actionWithTarget:self selector:@selector(boxActionDone)], nil]];
	}
	[[[GameLayer shared]content ]addChild:currenBox z:999 tag:BTN_ITEMBOX];
	isPlaySendEf=false;
	
	// 宝箱闪烁
	AnimationViewer *shineOver = (AnimationViewer *)[[[GameLayer shared] content] getChildByTag:TimeBox_shineOver_tag];
	if (!shineOver) {
		NSString *fullPath1 = @"images/animations/boxopen/1/";
		NSArray *roleFrames1 = [AnimationViewer loadFileByFileFullPath:fullPath1 name:@"%d.png"];
		shineOver = [AnimationViewer node];
		shineOver.position = p1;
		shineOver.scale = 0.7;
		shineOver.visible = NO;
		[shineOver playAnimation:roleFrames1];
		[[[GameLayer shared] content] addChild:shineOver z:10 tag:TimeBox_shineOver_tag];
	}
	AnimationViewer *shineUnder = (AnimationViewer *)[[[GameLayer shared] content] getChildByTag:TimeBox_shineUnder_tag];
	if (!shineUnder) {
		NSString *fullPath2 = @"images/animations/boxopen/2/";
		NSArray *roleFrames2 = [AnimationViewer loadFileByFileFullPath:fullPath2 name:@"%d.png"];
		shineUnder = [AnimationViewer node];
		shineUnder.position = p1;
		shineUnder.scale = 0.7;
		shineUnder.visible = NO;
		[shineUnder playAnimation:roleFrames2];
		[[[GameLayer shared] content] addChild:shineUnder z:-1 tag:TimeBox_shineUnder_tag];
	}
}

#pragma mark 打开宝箱
-(void)openbox:(CCSimpleButton*)n
{
	/*
    if ([[Window shared] isHasWindow]) {
        return ;
    }*/
	
	if (![[Window shared] checkCanTouchNpc]) {
        return ;
    }
	
    if (isSend) {
        return;
    }
	NSArray *array=[n userObject];
	[n setCall:nil];
	[self creatItemList:array];
	CCSimpleButton *sp=[CCSimpleButton spriteWithFile:@"images/ui/timebox/box_open.png"];
	CGPoint p=[n position];
	[sp setPosition:p];
    CCNode* parent_node =  n.parent;
    [n removeFromParentAndCleanup:true];
	[parent_node addChild:sp z:999 tag:BTN_ITEMBOX];
	currenBox=sp;
	
	CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:TimeBox_shineOver_tag];
	if (shineOver) {
		shineOver.visible = YES;
	}
	CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:TimeBox_shineUnder_tag];
	if (shineUnder) {
		shineUnder.visible = YES;
	}
}

#pragma mark 拾取宝箱物品
-(void)packupbox:(id)n{
    
	/*if ([[Window shared] isHasWindow]) {
        return ;
    }*/
	
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	 
    if (isSend) {
        return;
    }
	[GameConnection request:@"waitFetch" format:@"type::2" target:self call:@selector(packupBoxSuss:)];
    isSend = YES;
}


#pragma mark 拾取物品成功
-(void)packupBoxSuss:(id)n{
	NSDictionary *dict=n;
	int su=[[dict objectForKey:@"s"]integerValue];
	NSString *key=[NSString stringWithFormat:@"%@",[dict objectForKey:@"m"]];
	if(su==1){
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:[dict objectForKey:@"d"]];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
        CCNode *node_ = [[[GameLayer shared]content ] getChildByTag:BTN_ITEMBOX];
        if (node_) {
            [node_ removeFromParentAndCleanup:true];
            currenBox=nil;
        }

		[[GameConfigure shared]updatePackage:[dict objectForKey:@"d"]];
		CCSprite *sprite=(CCSprite*)[self getChildByTag:BG_PACKUP];
		[sprite removeFromParentAndCleanup:YES];
		isOpenedGetItem=false;
		if(hasBoss){
			[[[NPCManager shared]getNPCById:62] setVisible:YES];
		}
		
		CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:TimeBox_shineOver_tag];
		if (shineOver) {
			shineOver.visible = NO;
		}
		CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:TimeBox_shineUnder_tag];
		if (shineUnder) {
			shineUnder.visible = NO;
		}
	}else{
		[ShowItem showErrorAct:key];
	}
    isSend = NO;
}

#pragma mark 生成宝物列表显示
-(void)creatItemList:(NSArray*)n {
	//return;
	isOpenedGetItem=true;
	NSArray *itemdict=n;
	CCSprite *packupbg=[CCSprite spriteWithFile:@"images/ui/timebox/packup_bg_.png"];
	boxmenu=[CCMenu node];
	//[boxmenu setHandlerPriority:-58];
	CCMenuItemImage *packup_btn=makeMenuItemImageBtn(@"images/ui/timebox/bt_packup.png", 1.1f, self, @selector(packupbox:));
	[boxmenu setPosition:ccp(packupbg.contentSize.width/2, packupbg.contentSize.height/2)];
	[packup_btn setPosition:ccp(packup_btn.position.x,POS_PACKUP_BTN_Y)];
	[boxmenu addChild:packup_btn z:-1 tag:BT_PACKUP];
	[packup_btn setVisible:YES];
	[packupbg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	[packupbg addChild:boxmenu];
	[self addChild:packupbg z:-1 tag:BG_PACKUP];
	[boxmenu setHandlerPriority:-58];
	CCNode *itempackbg=[CCLayer node];
	int  posx=0;
	for(NSDictionary *item in itemdict){
		int wid;
		@try {
			wid=[[item objectForKey:@"i"]intValue];
		}
		@catch (NSException *exception) {
			continue;
		}
		NSString *type=[NSString stringWithFormat:@"%@",[item objectForKey:@"t"]];
		CCSprite *itemsp;
		if([type isEqualToString:@"i"]){
			itemsp=getItemIcon(wid);
		}
		if([type isEqualToString:@"e"]){
			itemsp=getEquipmentIcon(wid);
		}
		if([type isEqualToString:@"f"]){
			itemsp=getFateIcon(wid);
		}
		if([type isEqualToString:@"c"]){
			itemsp=getCarIcon(wid);
		}
		if([type isEqualToString:@"r"]){
			itemsp=getTMemberIcon(wid);
		}
		
        [itemsp setPosition:ccp(posx, cFixedScale(20))];
		int qa=getAllItemQuality(wid, type);
		NSString *path=[NSString stringWithFormat:@"images/ui/common/quality%i.png",qa];
		CCSprite *qabg=[CCSprite spriteWithFile:path];
		[qabg setPosition:ccp(posx, POS_ITEMSP_Y)];
		posx=posx+ cFixedScale(1*100) ;
		[itempackbg addChild:qabg z:-1];
		[itempackbg addChild:itemsp z:-1 tag:BG_PACKUP_IN];
		
	}
	[itempackbg setIgnoreAnchorPointForPosition:NO];
	[itempackbg setContentSize:CGSizeMake(posx-CGS_ITEMPACKBG_ADD_X, CGS_ITEMPACKBG_Y)];
	[itempackbg setAnchorPoint:ccp(0.5, 0.5)];
	[itempackbg setPosition:ccp(packupbg.contentSize.width/2, packupbg.contentSize.height/1.5)];
	[packupbg addChild:itempackbg];
}



#pragma mark 以下处理网络返回函数
-(void)didSendFightData:(NSDictionary*)data{
	if(!checkResponseStatus(data) ){
		[ShowItem showErrorAct:getResponseMessage(data)];
	}
    isSend = NO;
}
//战斗胜利后获取物品
-(void)handlertFightDone:(NSDictionary*)data{
	NSDictionary *npc=[boss_npc objectAtIndex:currenOtherNPCid];
	int isNeedFigthSub=[[data objectForKey:@"sub"]integerValue];
	[[GameConfigure shared]updatePackage:data];
	if(isNeedFigthSub==1){
		
		if([figthSub length]>1){
			int boxid=[[npc objectForKey:@"id"]integerValue];
			NSString *str=[NSString stringWithFormat:@"chapter::%i|tbid::%i|news:%@",currenChapter,boxid,figthSub];
			//[GameConnection request:@"tBoxSub" format:str target:self call:nil];
            [GameConnection request:@"tBoxSub" format:str target:self call:@selector(didSendFightData:)];
			[figthSub release];
			figthSub =nil;
            isSend = YES;
		}
	}
	isFightBack=true;
	[self handlertBoxEnter:data];
}


//处理秒杀
-(void)handlerSkill:(NSDictionary*)data{
	isPlayDieEf=true;
	CCLOG(@"%@",boss_npc);
	[self playDieAct];
	[self handlertFightDone:data];
}


//处理排行
-(void)handlerRank:(NSDictionary*)data{
	if([FightManager isFighting]){
		return;
	}
	
	[self removeChildByTag:BG_RANK cleanup:YES];
	CCLayerColor *rank_bg=[CCLayerColor layerWithColor:ccc4(20, 20, 20, 200) width:CGS_RANK_BG_WIDTH height:CGS_RANK_BG_HEIGHT];
	[rank_bg setPosition:ccp(PosX-rank_bg.contentSize.width-POS_RANK_BG_ADD_X, PosY-rank_bg.contentSize.height-POS_RANK_BG_ADD_Y)];
	[self addChild:rank_bg z:-1 tag:BG_RANK];
	int mid=[[[boss_npc objectAtIndex:currenOtherNPCid] objectForKey:@"mid"]integerValue];
	
	NSDictionary *mosinfo=[[GameDB shared]getNpcInfo:mid];
	
	
	CCLabelTTF *rankMosname=[CCLabelTTF labelWithString:[mosinfo objectForKey:@"name"] fontName:FONTNAME fontSize:18];
	[rankMosname setColor:ccc3(66, 124, 177)];
	[rank_bg addChild:rankMosname];
	
    rankMosname.scale = cFixedScale(1);
    [rankMosname setPosition:ccp(rank_bg.contentSize.width/2,rank_bg.contentSize.height-cFixedScale(rankMosname.contentSize.height) )];
	
	NSSortDescriptor *_sorter  = [[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] autorelease];
	NSArray *ranks=[data objectForKey:@"ranks"];
	NSArray *rankar=[ranks sortedArrayUsingDescriptors:[NSArray arrayWithObject:_sorter]];
	
	int index=0;
	int hight=rank_bg.contentSize.height-VALUE_RANK_BG_HEIGHT;
	
	//Kevin added and modified
	int increaseY = 20;
	if (iPhoneRuningOnGame()) {
		increaseY = 30;
	}
	for(NSDictionary *dic in rankar){
		NSString *name=[dic objectForKey:@"name"];
		NSString *rank=[dic objectForKey:@"rank"];
		NSString *fid=[dic objectForKey:@"fid"];
		//NSString *rankStr=[NSString stringWithFormat:@"第%@名:#ffffff#16#2|",rank];
        NSString *rankStr=[NSString stringWithFormat:NSLocalizedString(@"time_box_rank",nil),rank];
		NSString *nameStr=[NSString stringWithFormat:@"%@#ffeb7b#16#2|",name];
		//NSString *fidStr=[NSString stringWithFormat:@"###|战报#f6931c#16#2#%@",fid];
        NSString *fidStr=[NSString stringWithFormat:NSLocalizedString(@"time_box_fight_list",nil),fid];
		CCNode *rankNode=[MessageBox create:rankStr target:self sel:@selector(rankopenfight:)];
		CCNode *nameNode=[MessageBox create:nameStr target:self sel:@selector(rankopenfight:)];
		CCNode *fidNode=[MessageBox create:fidStr target:self sel:@selector(rankopenfight:)];
		[rankNode setPosition:ccp(cFixedScale(30), hight-index*cFixedScale(increaseY))];
		[nameNode setPosition:ccp(rankNode.position.x+cFixedScale(80), rankNode.position.y)];
		[fidNode setPosition:ccp(nameNode.position.x+cFixedScale(80), rankNode.position.y)];
		rankNode.scale = nameNode.scale = fidNode.scale = cFixedScale(1.0f);
		[rank_bg addChild:rankNode];
		[rank_bg addChild:nameNode];
		[rank_bg addChild:fidNode];
		index++;
	}
	//	for(NSDictionary *dic in rankar){
	//		NSString *name=[dic objectForKey:@"name"];
	//		NSString *rank=[dic objectForKey:@"rank"];
	//		NSString *fid=[dic objectForKey:@"fid"];
	//		NSString *linestr=[NSString stringWithFormat:@"第%@名:#ffffff#15#2|    %@#ffeb7b#15#2|    ###|战报#f6931c#15#2#%@",rank,name,fid];			//Kevin fixed
	//		CCNode *fontsrt=[MessageBox create:linestr target:self sel:@selector(rankopenfight:)];
	//		[fontsrt setPosition:ccp(cFixedScale(40), hight-index*cFixedScale(increaseY))];																//Kevin fixed
	//		fontsrt.scale  = cFixedScale(1);
	//		[rank_bg addChild:fontsrt];
	//		index++;
	//	}
	//-----------------------------//
}



-(void)rankopenfight:(id)n{
	[self removeChildByTag:BG_RANK cleanup:YES];
	[self removeChildByTag:BG_REWARDTIPS cleanup:YES];
	CCNode *node=(CCNode*)n;
	int fid=[[node userObject]integerValue] ;
	[[FightManager shared]playFightRecord:fid target:self call:@selector(didPlayRecode)];
	[self hideTopMenu:YES];
}


//播放战报完成回调
-(void)didPlayRecode{
	[self hideTopMenu:NO];
	[self requestEnterTimeBox];
}


//重置，转换章节，进入时光盒
-(void) handlertBoxEnter:(NSDictionary*)data{
	if(isBuyResetBack){
		int money=[moneyBox getCoin:3];
		[moneyBox setCoin:(money-needmoney) count:3];
	}
	hasBoss=false;
	dieCount=0;
	[[GameConfigure shared]updatePackage:data];
	//监测是否有待收物品
	NSArray *waitPackup=[[GameConfigure shared]getPlayerWaitItemListByType:2];
	
	if(waitPackup.count>0){
		
		NSMutableArray *tatol=[NSMutableArray array];
		
		CJSONDeserializer *json=[CJSONDeserializer deserializer];
		for(NSDictionary *dictjson in waitPackup){
			NSString *jsonstr=[dictjson objectForKey:@"items"];
			NSData *jsondata=[jsonstr dataUsingEncoding:NSUTF8StringEncoding];
			NSArray *itemdict=[json deserialize:jsondata error:nil];
			for(NSDictionary *item in itemdict){
				[tatol addObject:item];
			}
		}
		[self creatbox:NO items:tatol isMove:isFightBack];
	}else{
		isOpenedGetItem=false;
	}
	//服务器返回最大章节数
	if(!currenMaxChapter){
		currenMaxChapter=[[data objectForKey:@"maxc"]integerValue];
	}
	data=[data objectForKey:@"tbox"];
	isclickMnpc=false;
	
	//返回当前章节数
	currenChapter=[[data objectForKey:@"chapter"]integerValue];
	[self removeChildByTag:BG_REWARDTIPS cleanup:YES];
	[self removeChildByTag:BG_RANK cleanup:YES];
	[[menu getChildByTag:BT_CHANGLEFT_CHAPTER]removeChildByTag:20001 cleanup:true];
	[[menu getChildByTag:BT_CHANGRIGHT_CHAPTER]removeChildByTag:20000 cleanup:true];
	
	[[menu getChildByTag:BT_CHANGLEFT_CHAPTER]removeChild:cityNameLeft];
	[[menu getChildByTag:BT_CHANGRIGHT_CHAPTER]removeChild:cityNameRight];
	//章节跳转按钮
	if(currenChapter==2){
		[[menu getChildByTag:BT_CHANGLEFT_CHAPTER] setVisible:NO];
	}else{
		NSString *path=[NSString stringWithFormat:@"images/ui/timebox/cn_str%i.png",currenChapter-2];
		cityNameLeft=[CCMenuItemImage itemWithNormalImage:path selectedImage:path];
		[cityNameLeft setScaleX:-1];
		CCMenuItemImage *temp=(CCMenuItemImage*)[menu getChildByTag:BT_CHANGLEFT_CHAPTER];
		[temp setVisible:YES];
		[cityNameLeft setPosition:ccp(temp.contentSize.width/2, temp.contentSize.height/2)];
		[temp addChild:cityNameLeft];
		AnimationViewer *flash=[AnimationViewer node];
		[flash showAnimationByPathForever:@"images/ui/intro/fire/%d.png"];
		[flash setPosition:ccp(temp.contentSize.width/2, temp.contentSize.height/2)];
		flash.tag=20001;
		[temp addChild:flash];
	}
	if(currenChapter==6 || currenChapter+1>currenMaxChapter){
		[[menu getChildByTag:BT_CHANGRIGHT_CHAPTER] setVisible:NO];
	}else{
		NSString *path=[NSString stringWithFormat:@"images/ui/timebox/cn_str%i.png",currenChapter];
		cityNameRight=[CCMenuItemImage itemWithNormalImage:path selectedImage:path];
		CCMenuItemImage *temp=(CCMenuItemImage*)[menu getChildByTag:BT_CHANGRIGHT_CHAPTER];
		[temp setVisible:YES];
		[cityNameRight setPosition:ccp(temp.contentSize.width/2, temp.contentSize.height/2)];
		[temp addChild:cityNameRight];
		AnimationViewer *flash=[AnimationViewer node];
		flash.tag=20000;
		[flash showAnimationByPathForever:@"images/ui/intro/fire/%d.png"];
		[flash setPosition:ccp(temp.contentSize.width/2, temp.contentSize.height/2)];
		[temp addChild:flash];
		
	}
	if(boss_npc){
		[boss_npc release];
	}
	
	boss_npc=[[NSMutableArray alloc]init];
	//获取时光盒星级列表
	NSArray *levels_array=[data objectForKey:@"levels"];
	//获取时光盒类表
	NSArray *tbids_array=[data objectForKey:@"tbids"];
	//获取与时光盒对应是否存活
	NSArray *isLives_array=[data objectForKey:@"isLives"];
	//设置章节标题
	{
		CCSprite *bg=(CCSprite*)[self getChildByTag:BG_TITLE];
		[bg removeAllChildren];
		NSString *chapterstr=[[[GameDB shared]getChapterInfo:currenChapter] objectForKey:@"name"];
		CCLabelFX *label=[CCLabelFX labelWithString:chapterstr fontName:FONTNAME fontSize:16 shadowOffset:CGSizeMake(2,2)  shadowBlur:2.0f shadowColor:ccc4(0, 0, 0, 255) fillColor:ccc4(239, 146, 41, 255)];
		[label setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height/2)];
		
		label.scale = cFixedScale(1);
        
		[bg addChild:label];
		
	}
	//设置重置次数
	{
		//fix chao
		[menu removeChildByTag:BT_RESET cleanup:YES];
		freeResetTime=[[data objectForKey:@"re1"]integerValue];
		resetTime=[[data objectForKey:@"re2"]integerValue];
		NSString *path = nil;
		if(freeResetTime==0 && resetTime>0){
			path = @"images/ui/timebox/bt_reset2.png";
		}else{
			path = @"images/ui/timebox/bt_reset.png";
		}
		CCMenuItemImage *reset_bt=makeMenuItemImageBtn(path, 1.1f, self, @selector(menuCallbackBack:));
		reset_bt.position=ccp(PosX-cFixedScale(143+FULL_WINDOW_RULE_OFF_X2), PosY-cFixedScale(35));
		reset_bt.tag=BT_RESET;
		[menu addChild:reset_bt];
		//end
		CCNode *p=[menu getChildByTag:BT_RESET];
		if([p children].count>2){
			[[p children]removeLastObject];
		}
		CCSprite *freebg=[CCSprite spriteWithFile:@"images/ui/timebox/freetime_bg.png"];
		[freebg setPosition:ccp(p.contentSize.width-cFixedScale(10),p.contentSize.height-cFixedScale(10))];
		[p addChild:freebg];
        int time_ = 0;
        if(freeResetTime>0){
            time_ = freeResetTime;
        }else if(resetTime>0){
            time_ = resetTime;
        }else{
            time_ = 0;
        }
		//CCLabelTTF *free_time_str=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@",[data objectForKey:@"re1"]]  fontName:FONTNAME fontSize:9];
        CCLabelTTF *free_time_str=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",time_]  fontName:FONTNAME fontSize:9];
		[free_time_str setPosition:ccp(freebg.contentSize.width/2,freebg.contentSize.height/2)];
		[freebg addChild:free_time_str];
        
		
		//freeResetTime=[[data objectForKey:@"re1"]integerValue];
		//resetTime=[[data objectForKey:@"re2"]integerValue];
		CCLOG(@"%i",freeResetTime);
	}
	//bossNPC 的摆位以及组建数据
	{
		[[NPCManager shared]clearAllNPC];
		for(int i=0;i<tbids_array.count;i++){
			
			int boxid=[[tbids_array objectAtIndex:i]intValue];
			int level=[[levels_array objectAtIndex:i]intValue];
			NSMutableDictionary *npc=[NSMutableDictionary  dictionaryWithDictionary:[self getTimeBox:boxid]];
			
			//CCLOG(@"个人等级:%@",[[GameConfigure shared] getPlayerInfo]);
			[npc setValue:[NSString stringWithFormat:@"%i",level] forKey:@"level"];
			[npc setValue:[isLives_array objectAtIndex:i] forKey:@"isLives"];
			int mid=[[npc objectForKey:@"mid"]intValue] ;
			int playerlevel=[[[[GameConfigure shared] getPlayerInfo] objectForKey:@"level"]intValue];
			
			//获取战斗id
			NSArray *fstrar=[[npc objectForKey:@"fids"] componentsSeparatedByString:@"|"];
			for(int i=0;i<fstrar.count;i++){
				NSArray *onefstart=[[fstrar objectAtIndex:i] componentsSeparatedByString:@":"];
				int reqlevel=[[onefstart objectAtIndex:0]intValue];
				if(playerlevel>=reqlevel){
					[npc setValue:[onefstart objectAtIndex:1] forKey:@"fid"];
				}
			}
			NSValue *xy=[point6 objectAtIndex:i+1];
			int dir=i%2==0?1:-1;
			[boss_npc addObject:npc];
			NSString *strlive=[NSString stringWithFormat:@"%@",[isLives_array objectAtIndex:i]];
			if([strlive isEqualToString:@"1"]){
				[[NPCManager shared]addNPCById:mid tilePoint:[[MapManager shared]getPositionToTile:getTiledRectCenterPoint(xy.CGRectValue)] direction:dir target:self select:@selector(eventClickNPC:) tag:NPC_BOSS+i];
				if(isPlaySendEf){
					NSArray *array=[AnimationViewer loadFileByFileFullPath:@"images/effects/npc-effect/3/" name:@"%d.png"];
					AnimationViewer *p=[AnimationViewer node];
					[p setAnchorPoint:ccp(0.5, 0.5)];
					CCCallBlock *bfun=[CCCallBlock actionWithBlock:^{
						[p removeFromParentAndCleanup:true];
					}];
					[p  playAnimation:array delay:0.1 call:bfun];
					[p setPosition:getTiledRectCenterPoint(xy.CGRectValue)];
					[p setPosition:ccpAdd(p.position, POS_P)];
					[[[GameLayer shared]content]addChild:p z:9999];
				}
				hasBoss=true;
			}else{
				dieCount++;
			}
		}
		//添加中间的NPC
		[[NPCManager shared]addNPCById:62 tilePoint:[[MapManager shared]getPositionToTile:getTiledRectCenterPoint(m.CGRectValue)]
							 direction:1 target:self select:@selector(eventClickNPC:) tag:NPC_MIDLLE];
		CCNode *target=[CCNode node];
        CGPoint pos_ = POS_TARGET;
		//[target setPosition:POS_TARGET];
        if (iPhoneRuningOnGame()) {
            pos_.x -= cFixedScale(20);
        }
        [target setPosition:pos_];
		[[[NPCManager shared]getNPCById:62] addChild:target z:INT32_MAX];
		
		[[Intro share]runIntroInTager:target step:INTRO_TimeBox_Step_1];
		if(isOpenedGetItem || !hasBoss){
			[[[NPCManager shared]getNPCById:62] setVisible:NO];
		}
		if(hasBoss){
			[[menu getChildByTag:BT_SECKILL] setVisible:YES];
			[[self getChildByTag:BT_SECKILL_DIS] setVisible:NO];
		}else{
			[[menu getChildByTag:BT_SECKILL] setVisible:NO];
			[[self getChildByTag:BT_SECKILL_DIS] setVisible:YES];
		}
		isPlaySendEf=false;
		isBuyResetBack=false;
	}
}


#pragma mark 播放消失动画
-(void)playDieAct{
	
	for(int i=0;i<boss_npc.count;i++){
		NSDictionary *dict=[boss_npc objectAtIndex:i];
		if([[dict objectForKey:@"isLives"]integerValue]==1){
			NSValue *xy=[point6 objectAtIndex:i+1];
			NSArray *array=[AnimationViewer loadFileByFileFullPath:@"images/fight/eff/die_d/" name:@"%d.png"];
			AnimationViewer *p=[AnimationViewer node];
			[p setAnchorPoint:ccp(0.5, 0.5)];
			CCCallBlock *bfun=[CCCallBlock actionWithBlock:^{
				[p removeFromParentAndCleanup:true];
			}];
			[p  playAnimation:array delay:0.1 call:bfun];
			[p setPosition:getTiledRectCenterPoint(xy.CGRectValue)];
			[p setPosition:ccpAdd(p.position, ccp(0, 0))];
			[[[GameLayer shared]content]addChild:p z:9999];
			
			NSArray *parray=[AnimationViewer loadFileByFileFullPath:@"images/fight/eff/die_u/" name:@"%d.png"];
			AnimationViewer *pp=[AnimationViewer node];
			[pp setAnchorPoint:ccp(0.5, 0.5)];
			CCCallBlock *pbfun=[CCCallBlock actionWithBlock:^{
				[pp removeFromParentAndCleanup:true];
			}];
			[pp  playAnimation:parray delay:0.1 call:pbfun];
			[pp setPosition:getTiledRectCenterPoint(xy.CGRectValue)];
			[pp setPosition:ccpAdd(pp.position, POS_PP_ADD)];
			[[[GameLayer shared]content]addChild:pp z:9999];
		}
	}
	
}

#pragma mark
- (void) dealloc
{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	self.isOpened=false;
	s_TimeBox=nil;
    CCNode *node_ = [[[GameLayer shared]content ] getChildByTag:BTN_ITEMBOX];
    if (node_) {
        [node_ removeFromParentAndCleanup:true];
        currenBox=nil;
    }
	[[RoleManager shared]otherPlayerVisible:YES];
	[point6 release];
	[boss_npc release];
	
	[super dealloc];
	
	
	CCLOG(@"TimeBox dealloc");
}


@end
