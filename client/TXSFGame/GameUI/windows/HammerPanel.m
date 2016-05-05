//
//  HammerPanel.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-1.
//  Copyright 2012年 chao chen. All rights reserved.
//

#import "HammerPanel.h"
#import "GameConfigure.h"
#import "RoleCard.h"
#import "Window.h"
#import "MessageBox.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "CCLabelFX.h"
#import "GameConnection.h"
#import "Window.h"
#import "MapManager.h"
#import "Game.h"
#import "ClickAnimation.h"
#import "MiningManager.h"
#import "intro.h"
#import "SacrificePanel.h"
#import "ShowItem.h"
#import "Config.h"
#import "Arena.h"

//iphone for chenjunming

//fix chao 改位置
//static const int inventoryX = 185 ;
//static const int inventoryY = 420 ;

//#if TARGET_IPHONE
//
//static const int inventoryX = 610/2 ;
//static const int inventoryY = 420/2 ;
////end
//static const int inventory = 84/2 ;
//static const int space = 10/2 ;
//
//
////fix chao
////static const int hammerX = 636;
////static const int hammerY = 300;
//
//static const int hammerX = 340/2;
//static const int hammerY = 300/2;
////end
//
//static const int row = 4 ;
//static const int col = 3 ;
//static const int eMark = -16789;//装备列表的tag
//static const int qMark = -1678;//品质列表的tag
//
//#else

static  int  inventoryX =(610);
static  int  inventoryY= (420);
static  int  inventory =(84);
static  int  space =(10);
static  int  hammerX= (345);
static  int  hammerY= (300);

static const int row = 4 ;
static const int col = 3 ;
static const int eMark = -16789;//装备列表的tag
static const int qMark = -1678;//品质列表的tag

//#endif

@implementation EquipmentIcon
@synthesize isMoving;
@synthesize isSelect;
@synthesize quality;
@synthesize level;
@synthesize eid;
@synthesize target;
@synthesize ueid;
-(void)updateLevel:(int)_level
{
	CCSprite *equipment = (CCSprite*)[self getChildByTag:-2323];
	if (!equipment) {
		CCLOG(@"have no equipment");
		return ;
	}
	if (_level > 0) {
		NSString *str = [NSString stringWithFormat:@"+%d",_level];
		//TODO select color
		CCLabelFX *label = (CCLabelFX *)[self getChildByTag:-2324];
		if (label) {
			label.string = str;
		}
		else {
			label = [CCLabelFX labelWithString:str
									  fontName:getCommonFontName(FONT_1)
									  fontSize:20
								  shadowOffset:CGSizeMake(cFixedScale(2), cFixedScale(2))
									shadowBlur:0.2
								   shadowColor:ccc4(0, 0, 0, 128)
									 fillColor:ccc4(0, 255, 0, 255)];
			[self addChild:label z:1 tag:-2324];
			
			if(iPhoneRuningOnGame()){
				//数字的位置
				label.position=ccp(0+2/2.0f, self.contentSize.height-6.0f);
			}else{
				label.position=ccp(0+10, self.contentSize.height-15);
			}
            
		}
	}
	else {
		CCLabelFX *label = (CCLabelFX *)[self getChildByTag:-2324];
		if (label) {
			[label removeFromParentAndCleanup:YES];
			label =nil;
		}
	}
}
-(void)updateEquipment:(int)_eid
{
	CCSprite *equipment = (CCSprite*)[self getChildByTag:-2323];
	if (equipment) {
		[equipment stopAllActions];
		[equipment removeFromParentAndCleanup:YES];
		equipment = nil;
	}
	equipment = getEquipmentIcon(_eid);
	if (equipment) {
		[self addChild:equipment z:0 tag:-2323];
		self.contentSize = equipment.contentSize;
		equipment.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}
-(void)showLevelSetting:(BOOL)_bool
{
	CCLabelFX *label = (CCLabelFX *)[self getChildByTag:-2324];
	if (label) {
		label.visible = _bool;
	}
}
-(CGRect)rect
{
	return CGRectMake( _position.x - _contentSize.width*_anchorPoint.x,
					  _position.y - _contentSize.height*_anchorPoint.y,
					  _contentSize.width, _contentSize.height);
}
@end

@implementation HammerPanel
enum{
	HP_HAMMER_BG_TAG,
    HP_HAMMER_HIDE_BG_TAG,
	HP_HAMMER_BUTTON_TAG,
	HP_HAMMER_CLOSE_TAG,
	HP_CARDS_LAYER_START_TAG = 123,
};
#pragma mark init
-(void)onExit
{
    [GameConnection freeRequest:self];
	[super onExit];
}
-(void)onEnter
{
	[super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -3;
	
	[self openWindow];
	[self reload];
	////------
	//fix chao
	CCNode *node = (CCSprite *)[self getChildByTag:HP_CARDS_LAYER_START_TAG];
	if (node) {
		[[Intro share] runIntroTager:node step:INTRO_Hammer_Step_1];
	}
	isDisplayEffect = NO;
	isMove = NO;
    isSende = NO;
	//end
}
-(void)openWindow
{
	MessageBox *box =nil;
	if (iPhoneRuningOnGame()) {
		box=[MessageBox create:CGPointZero color:ccc4(74, 51, 21,255)];
	}else{
		box=[MessageBox create:CGPointZero color:ccc4(204, 125, 14,128)];
	}
	[self addChild:box z:0];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            box.contentSize=CGSizeMake(835/2.0f, 550/2.0f);
            box.position=ccpIphone(ccp(116.7f/2.0f,30/2.0f));
        }else{
            box.contentSize=CGSizeMake(835/2.0f, 550/2.0f);
            box.position=ccpIphone(ccp(116.7f/2.0f,30/2.0f));
        }
    }else{
    	box.contentSize=CGSizeMake(720, 490);
        box.position= ccp(128, 18);
    }

	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	//CCLabelTTF *_label1 = [CCLabelTTF labelWithString:@"拖动以下装备到左框内可强化装备" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *_label1 = [CCLabelTTF labelWithString:NSLocalizedString(@"hammer_info",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    _label1.anchorPoint = ccp(1,0.5);
	[self addChild:_label1];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            _label1.position= ccp(cFixedScale(720+205+44), 550/2);
        }else{
            _label1.position= ccp(cFixedScale(720+205+44), 550/2);
        }
    }else{
        _label1.position=ccp(720+105, 490);
		
    }
    
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            inventoryX=670/2.0f;
            inventoryY=476/2.0f;
            space=20/2.0f;
            inventory=82/2.0f;
            hammerX=460/2.0f;
            hammerY=349/2.0f;
        }else{
            inventoryX=670/2.0f;
            inventoryY=476/2.0f;
            space=20/2.0f;
            inventory=82/2.0f;
            hammerX=460/2.0f;
            hammerY=349/2.0f;
        }
    }
	//右边装备的底图
	for (int i = 0; i < row; i++) {
		for (int j = 0 ; j < col; j++) {
			CCSprite *spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
			[self addChild:spr];
			spr.tag = HP_CARDS_LAYER_START_TAG+row*i+j*col;
            if (iPhoneRuningOnGame()) {
                if (isIphone5()) {
                    spr.scale=1.14f;
                    spr.position = ccp(inventoryX + (space + inventory)*j+44, inventoryY - (space + inventory)*i);
                }else{
                    spr.scale=1.14f;
                    spr.position = ccp(inventoryX + (space + inventory)*j+44, inventoryY - (space + inventory)*i);
                }
            }else{
                spr.position = ccp(inventoryX + (space + inventory)*j, inventoryY - (space + inventory)*i);
            }
		}
	}
	//中间放装备的图
	CCSprite *hemmer = nil;
	if (iPhoneRuningOnGame()) {
		hemmer=[CCSprite spriteWithFile:@"images/ui/wback/hammer_bg2.jpg"];
	}else{
		hemmer=[CCSprite spriteWithFile:@"images/ui/panel/p12.jpg"];
	}
	hemmer.anchorPoint = ccp(0.5, 0.5);
	[self addChild:hemmer z:0];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
			//            hemmer.scaleY=1.14f;
			//            hemmer.scaleX=1.40f;
			//            hemmer.position = ccp(box.position.x+hemmer.contentSize.width*hemmer.scaleX/2+10,box.position.y+box.contentSize.height-hemmer.contentSize.height*hemmer.scaleY/2-8);
            hemmer.position = ccp(box.position.x+hemmer.contentSize.width*hemmer.scaleX/2+10,box.position.y+box.contentSize.height-hemmer.contentSize.height*hemmer.scaleY/2-8);
        }else{
			//            hemmer.scale=1.14f;
            hemmer.position = ccp(box.position.x+hemmer.contentSize.width*hemmer.scaleX/2+10,box.position.y+box.contentSize.height-hemmer.contentSize.height*hemmer.scaleY/2-8);
        }
    }else{
        hemmer.position = ccp(134+hemmer.contentSize.width/2,498-hemmer.contentSize.height/2);
    }
	hemmer.tag = HP_HAMMER_BG_TAG;
    //
    [self removeChildByTag:HP_HAMMER_HIDE_BG_TAG cleanup:YES];
    CCSprite *hide_spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
    [self addChild:hide_spr z:0 tag:HP_HAMMER_HIDE_BG_TAG];
    hide_spr.position = hemmer.position;
    hide_spr.visible = NO;
    //
	windowMenu= [CCMenu menuWithItems:nil];
	windowMenu.ignoreAnchorPointForPosition = YES;
	windowMenu.position = CGPointZero;
	[self addChild:windowMenu z:4];
	
	if (windowMenu) {
		[self buttonSet];
	}
}
-(void)buttonSet
{
	NSArray *array = getBtnSpriteWithStatus(@"images/ui/button/bt_get_ore");
	CCMenuItemImage *bt1 = [CCMenuItemImage itemWithNormalSprite:[array objectAtIndex:0]
												  selectedSprite:[array objectAtIndex:1]
												  disabledSprite:nil
														  target:self
														selector:@selector(receiveOrg:)];
	
	array = getBtnSpriteWithStatus(@"images/ui/button/bt_strengthen");
	CCMenuItemImage *bt2 = [CCMenuItemImage itemWithNormalSprite:[array objectAtIndex:0]
												  selectedSprite:[array objectAtIndex:1]
												  disabledSprite:nil
														  target:self
														selector:@selector(strengthen:)];
	bt2.tag = HP_HAMMER_BUTTON_TAG;
	[windowMenu addChild:bt1];
	[windowMenu addChild:bt2 z:1 tag:874];
	//fix chao
    //获得玄铁按钮
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
			bt1.scale=1.2f;
			bt2.scale=1.2f;
            bt1.position=ccp(480.0f-276/2.0f+88, 65/2);
            bt2.position=ccp(hammerX, 65/2);
        }else{
			bt1.scale=1.2f;
			bt2.scale=1.2f;
            bt1.position=ccp(480.0f-276/2.0f+88, 65/2);
            bt2.position=ccp(hammerX, 65/2);
        }
    }else{
        bt1.position=ccp(610+10+84, 55);
        bt2.position=ccp(hammerX, 55);
    }
	if (bt1) {
		if ([Intro getCurrenStep]<=INTRO_ENTER_Mining) {
			bt1.visible = NO;
		}else {
			[[Intro share] runIntroTager:bt1 step:INTRO_Mining_Step_1];
		}
	}
	
}
-(void)closeWindow
{
	[super closeWindow];

	if([Intro getCurrenStep]<=INTRO_Mining_Step_1){
		[Intro stopAll];
	}
}

-(void)reload
{
    //左边的角色列表
	CCLayerList *cards = (CCLayerList*)[self getChildByTag:-777];
	if (cards) {
		[cards stopAllActions];
		[cards removeFromParentAndCleanup:YES];
		cards = nil;
	}
    if (iPhoneRuningOnGame()) {
		cards = [CCLayerList listWith:LAYOUT_Y :ccp(0, 0) :5 :3.5f];
	}else{
		cards = [CCLayerList listWith:LAYOUT_Y :ccp(0, 0) :5 :4];
	}
	[cards setDelegate:self];
	cards.isDownward = YES;
	cards.tag = -777 ;
	
	NSArray *_roles = [[GameConfigure shared] getTeamMember];
	for (int i = 0; i < _roles.count; i++) {
		RoleCard *_card = [RoleCard create:CARD_WEAPON];
		int _rid = [[_roles objectAtIndex:i] intValue];
		[_card initFormID:_rid];
		[cards addChild:_card];
		if (i == 0) {//玩家自己
			[cards setSelected:_card];
		}
	}
	float _py = self.contentSize.height - 66 - cards.contentSize.height;
    if (iPhoneRuningOnGame()) {
        _py = self.contentSize.height - 66/2 - cards.contentSize.height;
        if (isIphone5()) {
			//            cards.position = ccp(38/2+0.4, _py+2.55);
            cards.position = ccp(103.5f/2.0f, _py+2.05);
        }else{
            cards.position = ccp(103.5f/2.0f, _py+2.05);
        }
    }else{
        cards.position = ccp(33, _py);
    }
	[self addChild:cards];
}
#pragma mark logic
//-(void)receiveMinig:(NSDictionary*)_sender
//{
//	if (checkResponseStatus(_sender)) {
//		[[Game shared] trunToMap:1001];
//	}
//	else {
//		//
//		CCLOG(@"receiveMinig failed!");
//	}
//}
-(void)receiveOrg:(id)sender
{
	[[Intro share]removeCurrenTipsAndNextStep:INTRO_Mining_Step_1];
	if ([MapManager shared].mapType == Map_Type_Mining) {
		//[ShowItem showItemAct:@"你已经身处玄铁矿洞"];
        [ShowItem showItemAct:NSLocalizedString(@"hammer_in_hammer",nil)];
	} else {
		// 如果在竞技场，先退出
		//[Arena quitArena];
		
		[MiningManager enterMining];
	}
	
	//	NSDictionary *dict = [[GameDB shared] getGlobalConfig];
	//	if (dict) {
	//		int enterLevel = [[dict objectForKey:@"mineEnterLevel"] intValue];
	//		int playerLevel = [[GameConfigure shared] getPlayerLevel];
	//		if (playerLevel >= enterLevel) {
	//			[[Game shared] trunToMap:1001];
	//		}
	//		else {
	//			CCLOG(@"receiveOrg failed");
	//		}
	//	}
}
-(void)strengthen:(id)sender
{
	//TODO
	//fix chao
	if (isSende || isMove) {
		return;
	}
	//end
    //拖动到中间图时弹出的提示
	for (int i = 0; i<12; i++) {
		EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
		if (equipment) {
			//---------------------------------------------------------
			//			int result = equipment.isSelect?1:0;
			//			CCLOG(@"eid=%d |status=%d ueid=%d",equipment.eid,result,equipment.ueid);
			if (equipment.isSelect && !equipment.isMoving) {
				//TODO 强化
				NSDictionary *dict = [[GameDB shared] getEquipmentsStrengInfo:equipment.level+1];
				if (dict) {
					int useId = [[dict objectForKey:@"useId"] intValue];//使用的物品
					int useNum = [[dict objectForKey:@"count"] intValue];//使用数量
					int count = [self getItemCountWithIid:useId];//自己当前拥有多少数量
					if (count >= useNum) {
						CCLOG(@"wait for didStrengthen");
						NSString *str = [NSString stringWithFormat:@"eid::%d",equipment.ueid];
						[windowMenu getChildByTag:784].visible=NO;
						[GameConnection request:@"eqStr" format:str target:self call:@selector(didStrengthen:)];
                        isSende = YES;
					}
					else {
						//TODO
						//提示 没有足够材料
						
						//fix chao
						CGPoint pos = ccp(hammerX, self.contentSize.height/2+100);
						float fontSize=GAME_PROMPT_FONT_SIZE;
                        if(iPhoneRuningOnGame())
                        {
                            pos = ccp(hammerX, self.contentSize.height/2.0f+120/2.0f);
							fontSize=GAME_PROMPT_FONT_SIZE/2.0f+1;
                        }
						//CCSprite* spr = [CCLabelTTF labelWithString:@"没有足够材料" fontName:getCommonFontName(FONT_1) fontSize: fontSize];
                        CCSprite* spr = [CCLabelTTF labelWithString:NSLocalizedString(@"hammer_no_material",nil) fontName:getCommonFontName(FONT_1) fontSize: fontSize];
						[ClickAnimation showSpriteInLayer:self z:1099 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
						//end
						
					}
				}else{
					//TODO
					//提示 等级不能再升
					//fix chao
					CGPoint pos = ccp(hammerX, self.contentSize.height/2+100);
					float fontSize=GAME_PROMPT_FONT_SIZE;
                    if(iPhoneRuningOnGame())
                    {
                        pos = ccp(hammerX, self.contentSize.height/2.0f+120/2.0f);
						fontSize=GAME_PROMPT_FONT_SIZE/2.0f+1;
                    }
					//CCSprite* spr = [CCLabelTTF labelWithString:@"等级不可再升！" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                    CCSprite* spr = [CCLabelTTF labelWithString:NSLocalizedString(@"hammer_no_upgrade",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
					[ClickAnimation showSpriteInLayer:self z:1099 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
					//end
				}
			}
		}
	}
}
-(void)didStrengthen:(NSDictionary*)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			//TODO
			CCLOG([dict description]);
			//更新本地数据
			[[GameConfigure shared] updatePackage:dict];
			//更新界面
			//fix chao
			/*
			 CCLOG(@"to update panel");
			 for (int i = 0; i<12; i++) {
			 Equipment *equipment = (Equipment*)[self getChildByTag:eMark+i];
			 if (equipment) {
			 //---------------------------------------------------------
			 int result = equipment.isSelect?1:0;
			 CCLOG(@"eid=%d |status=%d ueid=%d",equipment.eid,result,equipment.ueid);
			 if (equipment.isSelect) {
			 //TODO 强化
			 equipment.level = equipment.level+1;
			 [equipment updateLevel:equipment.level];
			 [self showConsumables:equipment];
			 break;
			 }
			 }
			 }
			 */
			//end
		}
		//fix chao 加入特效
		isDisplayEffect = YES;
		[ClickAnimation showInLayer:self z:9 tag:999 call:[CCCallFuncN actionWithTarget:self selector:@selector(showClickBackCall)] point:ccp(hammerX,hammerY) path:@"images/animations/uiforging/" loop:NO];
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_Hammer_Step_3];
	}
	else {
		CCLOG(@"didStrengthen faild");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        isSende = NO;
	}
    //
	[windowMenu getChildByTag:784].visible=YES;
}

//fix chao
-(void)showClickBackCall{
	CCLOG(@"to update panel");
	for (int i = 0; i<12; i++) {
		EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
		if (equipment) {
			//---------------------------------------------------------
			//			int result = equipment.isSelect?1:0;
			//			CCLOG(@"eid=%d |status=%d ueid=%d",equipment.eid,result,equipment.ueid);
			if (equipment.isSelect) {
				//TODO 强化
				equipment.level = equipment.level+1;
				[equipment updateLevel:equipment.level];
				[self showConsumables:equipment];
				break;
			}
		}
	}
	//fix chao
	CGPoint pos = ccp(hammerX, self.contentSize.height/2+100);
    if (iPhoneRuningOnGame()) {
		pos = ccp(hammerX, self.contentSize.height/2+100/2);
    }
    [ClickAnimation showInLayer:self z:99 tag:909 call:nil point:pos path:@"images/animations/uiupsucces/" loop:NO];
	[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos path:@"images/ui/panel/hammer_ok.png" loop:NO];
	isDisplayEffect = NO;
	//end
    isSende = NO;
}
//end

-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
	CCLOG(@"HammerPanel:CCLayerList=%d",_list.tag);
	if (_list.tag == -777) {
		RoleCard *_card = (RoleCard*)_listItem;
		[self showEquipmentArray:_card.RoleID];
	}
}
//fix chao
-(void)clearInfo{
	CCNode *nodeSpr = [self getChildByTag:-900];
	if (nodeSpr) {
		[nodeSpr stopAllActions];
		[nodeSpr removeFromParentAndCleanup:YES];
		nodeSpr = nil;
	}
	CCNode *node = [self getChildByTag:-988];
	if (node) {
		[node stopAllActions];
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	CCNode *node1 = [self getChildByTag:-987];
	if (node1) {
		[node1 stopAllActions];
		[node1 removeFromParentAndCleanup:YES];
		node1 = nil;
	}
	CCNode *node2 = [self getChildByTag:-986];
	if (node2) {
		[node2 stopAllActions];
		[node2 removeFromParentAndCleanup:YES];
		node2 = nil;
	}
	
	CCNode *node3 = [self getChildByTag:-985];
	if (node3) {
		[node3 stopAllActions];
		[node3 removeFromParentAndCleanup:YES];
		node3 = nil;
	}
	CCNode *node4 = [self getChildByTag:-984];
	if (node4) {
		[node4 stopAllActions];
		[node4 removeFromParentAndCleanup:YES];
		node4 = nil;
	}
}
//end
-(void)clearAll
{
	for (int i = 0; i < 12; i++) {
		[self removeChildByTag:eMark+i cleanup:YES];//清除装备
		[self removeChildByTag:qMark+i cleanup:YES];//清除品质
	}
	//fix chao
	[self clearInfo];
	/*
	 CCNode *node1 = [self getChildByTag:-987];
	 if (node1) {
	 [node1 stopAllActions];
	 [node1 removeFromParentAndCleanup:YES];
	 node1 = nil;
	 }
	 CCNode *node2 = [self getChildByTag:-986];
	 if (node2) {
	 [node2 stopAllActions];
	 [node2 removeFromParentAndCleanup:YES];
	 node2 = nil;
	 }
	 //fix chao
	 CCNode *node3 = [self getChildByTag:-985];
	 if (node3) {
	 [node3 stopAllActions];
	 [node3 removeFromParentAndCleanup:YES];
	 node3 = nil;
	 }
	 //end
	 */
	//end
}
-(void)showEquipmentArray:(int)_rid
{
	//先清除
	[self clearAll];
	//在刷新
	if (_rid > 0) {
		NSDictionary *userRole = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
		if (userRole) {
			int equipmentTag = eMark;
			int qualityTag = qMark;
			for (int i = 1; i <= 6; i++) {
				NSString *key = [NSString stringWithFormat:@"eq%d",i];
				int ueid = [[userRole objectForKey:key] intValue];
				if (ueid > 0) {
					NSDictionary *userEquip = [[GameConfigure shared] getPlayerEquipInfoById:ueid];
					if (userEquip) {
						int eid = [[userEquip objectForKey:@"eid"] intValue];
						int level = [[userEquip objectForKey:@"level"] intValue];
						if (eid > 0) {
							NSDictionary *equipment = [[GameDB shared] getEquipmentInfo:eid];
							if (equipment) {
								int sid = [[equipment objectForKey:@"sid"] intValue];
								if (sid > 0) {
									NSDictionary *eqset = [[GameDB shared] getEquipmentSetInfo:sid];
									if (eqset) {
										int quality = [[eqset objectForKey:@"quality"] intValue];
										//TODO
										int row = (equipmentTag-eMark)/3;
										int col = (equipmentTag-eMark)%3;
										
										//------------------------------------------------
										EquipmentIcon *_object = [EquipmentIcon node];
										_object.isSelect = NO;
										_object.isMoving = NO;
										_object.eid = eid;
										_object.ueid = ueid;
										_object.level = level;
										_object.quality = quality;
                                        //右边的显示装备列表
                                        if (iPhoneRuningOnGame()) {
                                            if (isIphone5()) {
												//                                                _object.scale=1.2f;
												//                                                _object.target = _object.position = ccp(inventoryX + (space + inventory)*col+44, inventoryY - (space + inventory)*row);
                                                _object.target = _object.position = ccp(inventoryX + (space + inventory)*col+44, inventoryY - (space + inventory)*row);
                                            }else{
												//                                                _object.scale=1.2f;
                                                _object.target = _object.position = ccp(inventoryX + (space + inventory)*col+44, inventoryY - (space + inventory)*row);
                                            }
                                        }else{
                                            _object.target = _object.position = ccp(inventoryX + (space + inventory)*col, inventoryY - (space + inventory)*row);
                                        }
										_object.tag = equipmentTag;
										
										[_object updateEquipment:eid];
										[_object updateLevel:level];
										
										[self addChild:_object z:5];//
										//------------------------------------------------
										
										//------------------------------------------------
										//fix chao
										/*
										 NSString *path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
										 CCSprite *spr = [CCSprite spriteWithFile:path];
										 if (spr) {
										 [self addChild:spr z:3];
										 spr.position = _object.position;
										 spr.tag = qualityTag;
										 }
										 */
										[self showQualityWithTag:qualityTag position:_object.position quality:quality isShow:YES];
										//end
										//------------------------------------------------
										equipmentTag++;
										qualityTag++;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
//fix chao
-(void)showQualityWithTag:(NSInteger)tag position:(CGPoint)pos quality:(NSInteger)quality isShow:(BOOL)showed{
	CCSprite *node = (CCSprite *)[self getChildByTag:tag];
	if(node){
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	CCSprite *spr = nil;
	if (showed) {
		NSString *path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
		spr = [CCSprite spriteWithFile:path];
	}else{
		spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	}
	
	if (spr) {
		[self addChild:spr z:3];
		if (iPhoneRuningOnGame()) {
			spr.scale=1.02f;
		}
		spr.position = pos;
		spr.tag = tag;
	}
}
//end
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"ccTouchBegan");
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	//fix chao
	BOOL moved = NO;
	for (int i = 0 ; i < 12; i++) {
		EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
		if (equipment && equipment.isMoving == YES) {
			moved = YES;
		}
	}
	if (moved == NO) {
		isMove = NO;
	}
	if(!isDisplayEffect && isSende==NO && isMove==NO){
		//end
		for (int i = 0 ; i < 12; i++) {
			EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
			if (equipment) {
				CGPoint local = [equipment convertToNodeSpace:touchLocation];
				CGRect r = [equipment rect];
				r.origin = CGPointZero;
				//fix chao
				if( CGRectContainsPoint( r, local ) )
				{
					
					if (!equipment.isSelect) {
						if (ABS(equipment.position.x-hammerX)>50&&equipment.isMoving==NO) {
							[self showQualityWithTag:equipment.tag-eMark+qMark position:equipment.position quality:equipment.quality isShow:NO];
						}
					}
					equipment.isMoving = YES;
					equipment.isSelect = NO ;
					equipment.zOrder = INT_MAX;
					[equipment showLevelSetting:NO];
					//fix chao
					isMove = YES;
					//					equipment.scale = 1.5f;
					[[Intro share] removeCurrenTipsAndNextStep:INTRO_Hammer_Step_1];
					//CCNode *node = (CCNode *)[self getChildByTag:HP_HAMMER_BG_TAG];
                    CCNode *node = (CCNode *)[self getChildByTag:HP_HAMMER_HIDE_BG_TAG];
					if (node) {
						[[Intro share] runIntroTager:node step:INTRO_Hammer_Step_2];
					}
					//end
					return YES;
				}
			}
		}
	}
	//fix chao
	touchLocation = [self convertToNodeSpace:touchLocation];
	if (touchLocation.x>=0 && touchLocation.y>=0 && touchLocation.x<=self.contentSize.width&&touchLocation.y<=self.contentSize.height) {
		return YES;
	}
	//end
	return NO;
}
//fix chao
-(void)setIsActionStop{
	isMove = NO;
}
//end
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"ccTouchEnded");
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	if ([self checkCollide:touchLocation]) {
		for (int i = 0 ; i < 12; i++) {
			EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
			if (equipment) {
				if (!isDisplayEffect && isSende==NO && equipment.isSelect) {
                    isMove = YES;
					float distance = ccpDistance(equipment.position, equipment.target);
					distance = ABS(distance);
					id action = [CCSequence actions:
								 [CCJumpTo actionWithDuration:distance/1000 position:equipment.target height:abs(equipment.position.y-equipment.target.y)/2 jumps:1],
								 [CCCallFuncN actionWithTarget:self selector:@selector(equipmentForDefault:)],
								 [CCCallFuncN actionWithTarget:self selector:@selector(equipmentForShowDefault:)],
                                 [CCCallFuncN actionWithTarget:self selector:@selector(setIsActionStop)],
								 nil];
					//fix chao
					[equipment stopAllActions];
					//end
					[equipment runAction:action];
					//fix chao
					//equipment.isSelect = NO;
					[self clearInfo];
					//end
				}else if (equipment.isMoving) {
					id action = [CCSequence actions:
								 [CCJumpTo actionWithDuration:0.1 position:ccp(hammerX, hammerY) height:-abs(equipment.position.y-hammerY)/2 jumps:1],
								 [CCCallFuncN actionWithTarget:self selector:@selector(equipmentCallForHammer:)],
								 [CCCallFuncN actionWithTarget:self selector:@selector(setIsActionStop)],
								 nil];
					//fix chao
					[equipment stopAllActions];
					//end
					[equipment runAction:action];
				}
				//fix chao
				if (iPhoneRuningOnGame()) {
					//					equipment.scale = 1.2f;
				}else{
					equipment.scale = 1.0f;
				}
				//end
			}
		}
		//fix chao
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_Hammer_Step_2];
		CCNode *node = [windowMenu getChildByTag:HP_HAMMER_BUTTON_TAG];
		if (node) {
			[[Intro share] runIntroTager:node step:INTRO_Hammer_Step_3];
		}
		//end
	}
	else {
		BOOL result = true;
		for (int i = 0 ; i < 12; i++) {
			EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
			if (equipment) {
				if (equipment.isMoving) {
					float distance = ccpDistance(equipment.position, equipment.target);
					distance = ABS(distance);
					id action = [CCSequence actions:
								 [CCJumpTo actionWithDuration:distance/1000 position:equipment.target height:abs(equipment.position.y-equipment.target.y)/2 jumps:1],
								 [CCCallFuncN actionWithTarget:self selector:@selector(equipmentForDefault:)],
								 [CCCallFuncN actionWithTarget:self selector:@selector(equipmentForShowDefault:)],
								 [CCCallFuncN actionWithTarget:self selector:@selector(setIsActionStop)],
								 nil];
					[equipment runAction:action];
					//fix chao
					equipment.scale = 1.0f;
					//end
				}
				else if (equipment.isSelect) {
					result = NO;
				}
				else {
					[self equipmentForDefault:equipment];//恢复初始化
					//fix chao
					equipment.scale = 1.0f;
					//end
				}
			}
		}
		if (result) {
			//fix chao
			[self clearInfo];
			/*
			 CCNode *node1 = [self getChildByTag:-987];
			 if (node1) {
			 [node1 stopAllActions];
			 [node1 removeFromParentAndCleanup:YES];
			 node1 = nil;
			 }
			 CCNode *node2 = [self getChildByTag:-986];
			 if (node2) {
			 [node2 stopAllActions];
			 [node2 removeFromParentAndCleanup:YES];
			 node2 = nil;
			 }
			 //fix chao
			 CCNode *node3 = [self getChildByTag:-985];
			 if (node3) {
			 [node3 stopAllActions];
			 [node3 removeFromParentAndCleanup:YES];
			 node3 = nil;
			 }
			 //end
			 */
			//end
		}
	}
}
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"ccTouchMoved");
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	for (int i = 0 ; i < 12; i++) {
		EquipmentIcon *equipment = (EquipmentIcon*)[self getChildByTag:eMark+i];
		if (equipment && equipment.isMoving) {
			equipment.position=touchLocation;
		}
	}
}

-(BOOL)checkCollide:(CGPoint)_pt
{
	//fix chao
	_pt = [self convertToWorldSpace:_pt];
	CCNode *node = [self getChildByTag:HP_HAMMER_BG_TAG];
	CGPoint pos = [node convertToNodeSpace:_pt];
	return (pos.x>=0&&pos.y>=0&&pos.x<=node.contentSize.width&&pos.y<=node.contentSize.height);
	//return checkCollide(_pt, ccp(hammerX, hammerY), 120);
	//end
}

-(void)equipmentForShowDefault:(id)sender
{
	EquipmentIcon *equipment = (EquipmentIcon*)sender;
	if (equipment) {
		[self showQualityWithTag:equipment.tag-eMark+qMark position:equipment.position quality:equipment.quality isShow:YES];
	}
}

-(void)equipmentForDefault:(id)sender
{
	EquipmentIcon *equipment = (EquipmentIcon*)sender;
	if (equipment) {
		equipment.position = equipment.target;
		equipment.isMoving = NO;
		equipment.isSelect = NO;
		[equipment showLevelSetting:YES];
	}
}
-(void)equipmentCallForHammer:(id)sender
{
	EquipmentIcon *equipment = (EquipmentIcon*)sender;
	if (equipment) {
		equipment.position = ccp(hammerX, hammerY);
		equipment.isMoving = NO ;
		equipment.isSelect = YES ;
		[equipment showLevelSetting:YES];
		[self showConsumables:equipment];
	}
}
-(void)showConsumables:(EquipmentIcon*)equipment
{
	//fix chao
	[self clearInfo];
	/*
	 CCSprite *_object = (CCSprite*)[self getChildByTag:-987];
	 if (_object) {
	 [_object stopAllActions];
	 [_object removeFromParentAndCleanup:YES];
	 _object = nil;
	 }
	 CCLabelFX *label = (CCLabelFX*)[self getChildByTag:-986];
	 if (label) {
	 [label stopAllActions];
	 [label removeFromParentAndCleanup:YES];
	 label = nil;
	 }
	 //fix chao
	 CCLabelFX *namelabel = (CCLabelFX*)[self getChildByTag:-985];
	 if (namelabel) {
	 [namelabel stopAllActions];
	 [namelabel removeFromParentAndCleanup:YES];
	 namelabel = nil;
	 }
	 //end
	 */
	float fontSize=22;
	int alpha=128;
	if (iPhoneRuningOnGame()) {
		fontSize=22;
		alpha=255;
	}
	//end
	if (equipment) {
		NSDictionary *dict = [[GameDB shared] getEquipmentsStrengInfo:equipment.level+1];
		if (dict) {
			int useId = [[dict objectForKey:@"useId"] intValue];
			int useNum = [[dict objectForKey:@"count"] intValue];
			int count = [self getItemCountWithIid:useId];
			
			//fix chao
			NSDictionary *equipDict = [[GameDB shared] getEquipmentInfo:equipment.eid];
			ccColor3B color = getColorByQuality(equipment.quality);
			if (equipDict) {
				NSString *nameStr = [ equipDict objectForKey:@"name" ];
				CCLabelFX *namelabel = [CCLabelFX labelWithString:nameStr
														 fontName:getCommonFontName(FONT_1)
														 fontSize:fontSize
													 shadowOffset:CGSizeMake(cFixedScale(2), cFixedScale(2))
													   shadowBlur:0.2
													  shadowColor:ccc4(0,0,0, alpha)
														fillColor:ccc4(color.r, color.g, color.b, 255)];
				[self addChild:namelabel z:3 tag:-985];
				namelabel.anchorPoint=ccp(0.5, 0);
                if (iPhoneRuningOnGame()) {
                    namelabel.position=ccp(hammerX,hammerY+55/2.0f);
                }else{
                    namelabel.position=ccp(hammerX,hammerY+55);
                }
			}
			
			//end
			
			
			
			NSDictionary *item = [[GameDB shared] getItemInfo:useId];
			if (item) {
				//----------------------------------------------------------
				//拖动装备后的信息显示
				//----------------------------------------------------------
				
				//fix chao
				CCSprite *spr = [self getSpriteWithEquipID:equipment.eid level:equipment.level];
				if (spr) {
					[self addChild:spr z:9 tag:-900];
					//					showNode(spr);
					spr.anchorPoint = ccp(0.5,1);
					
					if(iPhoneRuningOnGame()){
						spr.position = ccp(hammerX,hammerY-53/2.0f);
					}else{
						spr.position = ccp(hammerX,hammerY-45);
					}
					
				}
				fontSize=18;
				if (iPhoneRuningOnGame()) {
					fontSize=18;
				}
				////
//				CCLabelFX *label_txt = [CCLabelFX labelWithString:@"所需材料:"
//														 fontName:getCommonFontName(FONT_1)
//                                                         fontSize:fontSize
//													 shadowOffset:CGSizeMake(cFixedScale(2), cFixedScale(2))
//													   shadowBlur:0.2
//													  shadowColor:ccc4(0, 0, 0, 128)
//														fillColor:ccc4(255, 255, 255, 255)];
                CCLabelFX *label_txt = [CCLabelFX labelWithString:NSLocalizedString(@"hammer_need_material",nil)
														 fontName:getCommonFontName(FONT_1)
                                                         fontSize:fontSize
													 shadowOffset:CGSizeMake(cFixedScale(2), cFixedScale(2))
													   shadowBlur:0.2
													  shadowColor:ccc4(0, 0, 0, 128)
														fillColor:ccc4(255, 255, 255, 255)];
				[self addChild:label_txt z:3 tag:-984];
				label_txt.anchorPoint=ccp(0.5, 0);
				
				if(iPhoneRuningOnGame()){
					label_txt.position=ccp(hammerX-120/2,113/2);
				}else{
					label_txt.position=ccp(hammerX-100,95);
				}
				
				NSString *name = [item objectForKey:@"name"];
				int quality = [[item objectForKey:@"quality"] intValue];
				name = [name stringByAppendingFormat:@"%@|",getHexColorByQuality(quality)];
				name = [name stringByAppendingFormat:@" x%d",useNum];
				CCSprite *label = nil;
				
				fontSize=16;
				float lineHeight=18;
				if (iPhoneRuningOnGame()) {
					fontSize=18;
					lineHeight=20;
				}
				label =  drawString(name, CGSizeMake(150,0), getCommonFontName(FONT_1), fontSize, lineHeight, getHexStringWithColor3B(ccWHITE));
				if(iPhoneRuningOnGame()){
                    if (isIphone5()) {
                        label.position=ccp(hammerX+10,113/2-2);
                    }else{
                        label.position=ccp(hammerX+10,113/2-2);
                    }
				}else{
					label.position=ccp(hammerX,95);
				}
				
				label.anchorPoint=ccp(0.5, 0);
				[self addChild:label z:3 tag:-986];
				
				
				/*
				 NSString *name = [item objectForKey:@"name"];
				 name = [name stringByAppendingFormat:@" x%d",useNum];
				 CCLabelFX *label = [CCLabelFX labelWithString:name
				 fontName:getCommonFontName(FONT_1)
				 fontSize:18
				 shadowOffset:CGSizeMake(2, 2)
				 shadowBlur:0.2
				 shadowColor:ccc4(0, 0, 0, 128)
				 fillColor:ccc4(255, 255, 255, 255)];
				 [self addChild:label z:3 tag:-986];
				 label.anchorPoint=ccp(0.5, 0);
				 label.position=ccp(hammerX,95);
				 */
				//end
				
				//------------------------------------------------------------
				//物料显示
				//------------------------------------------------------------
				CCSprite *_object = getItemIcon(useId);
				if (_object) {
					[self addChild:_object z:3 tag:-987];
					
					if(iPhoneRuningOnGame()){
                        if(isIphone5())
                        {
                            _object.position=ccp(hammerX, hammerY-160/2);
							//                            _object.position=ccp(hammerX, hammerY-170/2);
                        }else{
                            _object.position=ccp(hammerX, hammerY-160/2);
                        }
					}else{
						_object.position=ccp(hammerX, hammerY-140);
					}
					
					NSString *string = [NSString stringWithFormat:@"%d",count];
					label = nil;
					fontSize=16;
					if (iPhoneRuningOnGame()) {
						fontSize=18;
					}
					label = [CCLabelFX labelWithString:string
											  fontName:getCommonFontName(FONT_1)
											  fontSize:fontSize
										  shadowOffset:CGSizeMake(cFixedScale(2), cFixedScale(2))
											shadowBlur:0.2
										   shadowColor:ccc4(0, 0, 0, 128)
											 fillColor:ccc4(255, 255, 0, 255)];
					[_object addChild:label z:3 tag:-1314];
					label.anchorPoint=ccp(0.5, 0.5);
					
					if(iPhoneRuningOnGame()){
						label.position=ccp(_object.contentSize.width,_object.contentSize.height-label.contentSize.height/2.0f);
					}else{
						label.position=ccp(_object.contentSize.width,_object.contentSize.height);
					}
					
					//---
					_object.scale = 0 ;
					id action =nil;
					if (iPhoneRuningOnGame()) {
						action=[CCScaleTo actionWithDuration:0.2 scale:1.3f];
					}else{
						action=[CCScaleTo actionWithDuration:0.2 scale:1.0f];
					}
					id action_out = [CCEaseElasticInOut actionWithAction:[[action copy] autorelease] period:0.3f];
					[_object runAction:action_out];
				}
				else {
					CCLOG(@"getItemIcon is null!");
				}
				//------------------------------------------------------------
			}
		}
	}
}
//fix chao
-(CCSprite*)getSpriteWithEquipID:(NSInteger)eid level:(NSInteger)level{
	if (level<0) {
		level = 0;
	}
	CCSprite *spr = nil;
	NSDictionary *_dict = [[GameDB shared] getEquipmentInfo:eid];
	int _part = [[_dict objectForKey:@"part"] intValue];
	NSString *cmd = nil;
	int nextLevel = level+1;
	
	NSDictionary *dict_lv = [[GameDB shared] getEquipmentLevelInfo:_part level:level];
	NSDictionary *dict_next_lv = [[GameDB shared] getEquipmentLevelInfo:_part level:nextLevel];
	
	if (!dict_next_lv) {
		nextLevel = level;
	}
	
	//cmd = [NSString stringWithFormat:@"强化等级:#ffffff#16#0|"];
    cmd = [NSString stringWithFormat:NSLocalizedString(@"hammer_level",nil)];
	cmd = [cmd stringByAppendingFormat:@" %d #00ff00#16#0|",level];
	cmd = [cmd stringByAppendingFormat:@"->#ffffff#16#0|"];
	cmd = [cmd stringByAppendingFormat:@" %d #00ff00#16#0*",nextLevel];
	
	if (level >= 0	) { //>0才有强化数据
		
		NSString *str_name = nil;
		NSString *str_temp = nil;
		NSString *str_next_temp = nil;
		
		BaseAttribute attr = BaseAttributeFromDict(dict_lv);
		NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
		
		NSArray *array = [string componentsSeparatedByString:@"|"];
		if (array.count > 0) {
			NSArray *_array = [[array objectAtIndex:0] componentsSeparatedByString:@":"];
			if (_array.count >= 2) {
				str_name = [_array objectAtIndex:0];
				str_temp = [_array objectAtIndex:1];
			}
		}
		
		BaseAttribute nextAttr = BaseAttributeFromDict(dict_next_lv);
		NSString *nextString = BaseAttributeToDisplayStringWithOutZero(nextAttr);
		
		NSArray *nextArray = [nextString componentsSeparatedByString:@"|"];
		if (nextArray.count > 0) {
			NSArray *_array = [[nextArray objectAtIndex:0] componentsSeparatedByString:@":"];
			if (_array.count >= 2) {
				str_name = [_array objectAtIndex:0];
				str_next_temp = [_array objectAtIndex:1];
			}
		}
		
		if (str_temp || str_next_temp) {
			//缩进
			cmd = [cmd stringByAppendingFormat:@"　　%@:#ffffff#16#0|", str_name];
			if (str_temp) {
				
				if (str_next_temp) {
					cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0|",str_temp];
					cmd = [cmd stringByAppendingFormat:@"->#ffffff#16#0|"];
					cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_next_temp];
				}else{
					cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_temp];
				}
			}else{
				if (str_next_temp) {
					cmd = [cmd stringByAppendingFormat:@" 0 #00ff00#16#0|"];
					cmd = [cmd stringByAppendingFormat:@"->#ffffff#16#0|"];
					cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_next_temp];
				}
			}
		}
		/*
		
		for (int i = 0; i < 21; i++) {
			float _value = 0;
			float _next_value = 0;
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			NSString *str_temp = nil;
			NSString *str_next_temp = nil;
			
			if (dict_lv && level>0) {
				_value = [[dict_lv objectForKey:[args objectAtIndex:0]] floatValue];
				if (_value > 0 ) {
					str_temp = [NSString stringWithFormat:@"%.0f",_value];
				}
			}
			////
			if (dict_next_lv) {
				//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
                NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
				_next_value = [[dict_next_lv objectForKey:[args objectAtIndex:0]] floatValue];
				if (_next_value > 0 ) {
					str_next_temp = [NSString stringWithFormat:@"%.0f",_next_value];
				}
			}
			if (str_temp || str_next_temp) {
				//缩进
				cmd = [cmd stringByAppendingFormat:@"　　%@:#ffffff#16#0|",[args objectAtIndex:1]];
				//					cmd = [cmd stringByAppendingFormat:@"%@:#ffffff#16#0|",[args objectAtIndex:1]];
				if (str_temp) {
					
					if (str_next_temp) {
						cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0|",str_temp];
						cmd = [cmd stringByAppendingFormat:@"->#ffffff#16#0|"];
						cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_next_temp];
					}else{
						cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_temp];
					}
				}else{
					if (str_next_temp) {
						cmd = [cmd stringByAppendingFormat:@" 0 #00ff00#16#0|"];
						cmd = [cmd stringByAppendingFormat:@"->#ffffff#16#0|"];
						cmd = [cmd stringByAppendingFormat:@" %@ #00ff00#16#0*",str_next_temp];
					}
				}
			}
		}
		*/
		
		
		CCSprite *nodeSpr = [CCSprite node];
		if (iPhoneRuningOnGame()) {
			cmd=[cmd stringByReplacingOccurrencesOfString:@"16" withString:@"18"];
			spr = drawString(cmd, CGSizeMake(236,0), getCommonFontName(FONT_1), 18,20, getHexStringWithColor3B(ccWHITE));
		}else{
			spr = drawString(cmd, CGSizeMake(234,0), getCommonFontName(FONT_1), 16,17, getHexStringWithColor3B(ccWHITE));
		}
		CCSprite *bg=nil;
		if(iPhoneRuningOnGame()){
			bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:spr.contentSize.width+16/2 height:spr.contentSize.height+16/2 capx:8/2 capy:8/2];
		}else{
			bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:spr.contentSize.width+16 height:spr.contentSize.height+16 capx:8 capy:8];
		}
		nodeSpr.contentSize = bg.contentSize;
		[nodeSpr addChild:bg z:-1];
		[nodeSpr addChild:spr z:1];
		// 保持为整数
		bg.position = ccp(roundf(bg.contentSize.width/2), roundf(bg.contentSize.height/2));
		spr.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2);
		
		return nodeSpr;
	}
	return spr;
}
//end
-(int)getItemCountWithIid:(int)_iid
{
	NSArray *list = [[GameConfigure shared] getPlayerItemList];
	int count = 0;
	for (NSDictionary *_dict in list) {
		int tempID = [[_dict objectForKey:@"iid"] intValue];
		if (tempID == _iid) { //找到有这个物品
			int temp = [[_dict objectForKey:@"count"] intValue];//找到有几个
			count += temp;
		}
	}
	return count;
}
@end