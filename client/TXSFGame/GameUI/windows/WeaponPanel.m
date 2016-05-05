//
//  Weapon.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import "WeaponPanel.h"
#import "Config.h"
#import "RoleCard.h"
#import "GameConfigure.h"
#import "Window.h"
#import "GameDB.h"
#import "GameConnection.h"
#import "MessageBox.h"
#import "InfoAlert.h"
#import "ClickAnimation.h"
#import "intro.h"
#import "AlertManager.h"
#import "GameLayer.h"

#import "SpiritIconViewerContent.h"
#import "WeaponViewerContent.h"

#define RUNE_ACTIVE_1	3
#define RUNE_ACTIVE_2	6

// 元宝取回炼历打勾
#define SkillBack_Gold_Done_Tag			222
#define POS_SKILL_NAME   ccp(0.5,1)

//#if TARGET_IPHONE
//
//#define POS_TOUCH_ADD_Y    50/2
//#define POS_BT_UPGRADE   ccp(405/2,56/2)
//#define WIDTH_CARDS   5/2
//#define HEIGHT_CARDS   4/2
//#define POS_BT_SK1   ccp(300/2, 138/2)
//#define POS_BT_SK2   ccp(500/2, 138/2)
//#define POS__OBJ_ADD_Y 50/2
//#define POS__OBJ   ccp(0.5/2,0)
//#define POS_WEAPON_X 400/2
//#define POS_WEAPON_ADD_Y 210/2
//#define POS_MOVE2 ccp(0,5/2)
//#define POS_POS_X 400/2
//#define POS_POS_ADD_Y 100/2
//#define CGS_DRAW CGSizeMake(135/2,0)
//#define CGS_DRAW_SIZE 15/2
//#define CGS_DRAW_LINE_H 16/2
//#define CGS_DRAWSPRITE CGSizeMake(18/2,18/2)
//#define CGS_SKILLBACK  ccp(40/2, 137/2)
//#define CGS_COSTSPRITE  ccp(25/2, 0)
//#define CGS_SELECTBOX     ccp(6/2, 11/2)
//#define POS_SKILLBACK    ccp(40/2,137/2)
//#define VALUE_FONT_SIZE 16/2
//
//#else

#define POS_TOUCH_ADD_Y    cFixedScale(50)
#define POS_BT_UPGRADE   ccp(cFixedScale(405),cFixedScale(56))
#define WIDTH_CARDS   cFixedScale(5)
#define HEIGHT_CARDS   cFixedScale(4)
#define POS_BT_SK1   ccp(cFixedScale(300), cFixedScale(138))
#define POS_BT_SK2   ccp(cFixedScale(500), cFixedScale(138))
#define POS__OBJ_ADD_Y cFixedScale(50)
#define POS__OBJ   ccp(cFixedScale(0.5),0)
#define POS_WEAPON_X cFixedScale(400)
#define POS_WEAPON_ADD_Y cFixedScale(260)
#define POS_MOVE2 ccp(0,cFixedScale(5))
#define POS_POS_X cFixedScale(400)
#define POS_POS_ADD_Y cFixedScale(100)
#define CGS_DRAW CGSizeMake(cFixedScale(135),0)
#define CGS_DRAW_SIZE cFixedScale(15)
#define CGS_DRAW_LINE_H cFixedScale(16)
#define CGS_DRAWSPRITE CGSizeMake(cFixedScale(18),cFixedScale(18))
#define CGS_SKILLBACK  ccp(cFixedScale(40), cFixedScale(137))
#define CGS_COSTSPRITE  ccp(cFixedScale(25), 0)
#define CGS_SELECTBOX     ccp(cFixedScale(6), cFixedScale(11))
#define POS_SKILLBACK    ccp(cFixedScale(40),cFixedScale(137))
#define VALUE_FONT_SIZE cFixedScale(16)

//#endif
static int  s_weapon_id_select = 0;

static inline NSArray* getRune(int _sid)
{
	if (_sid == 0) {
		return nil;
	}
	
	CCSprite *spr1 = [SpiritIconViewerContent create:_sid index:1];
	CCSprite *spr2 = [SpiritIconViewerContent create:_sid index:2];
	
	if (spr1 && spr2) {
		NSMutableArray *array = [NSMutableArray array];
#ifdef GAME_DEBUGGER
		CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"id=%d",_sid] fontName:@"Verdana-Bold" fontSize:18];
        if (iPhoneRuningOnGame()) {
            label.scale = 0.5;
        }
		label.color = ccc3(255, 0, 0);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentCenter];
		label.position=ccp(spr1.contentSize.width/2, spr1.contentSize.height/2);
		[spr1 addChild:label];
#endif
		[array addObject:spr1];
		[array addObject:spr2];
		return array;
	}
     
	return nil;
}

@implementation Weapon
+(void)setRoleID:(int)rid{
    s_weapon_id_select = rid;
}

-(void)onEnter
{
	[super onEnter];
	m_arm_level = 0;
    
	MessageBox *box = [MessageBox create:CGPointZero color:ccc4(74, 51, 21,255)];
	[self addChild:box z:0];
    if (iPhoneRuningOnGame()) {
        box.contentSize=CGSizeMake(835/2.0f, 545/2.0f);
        box.position= ccp(117/2.0f+44, 35/2.0f);
    }else{
        box.contentSize=CGSizeMake(720, 490);
        box.position= ccp(129, 18);
	}
	
	CCSprite *background2 = [CCSprite spriteWithFile:@"images/ui/panel/p7.jpg"];
	[self addChild:background2 z:0];
	background2.anchorPoint=CGPointZero;
    if (iPhoneRuningOnGame()) {
        background2.position = ccp(119/2.0f + 44 ,37/2.0f);
        background2.scaleX =830/2.0f/background2.contentSize.width;
		background2.scaleY=540/2.0f/background2.contentSize.height;
    }else{
        background2.position = ccp(133,25);
	}
	
	NSArray * btns = getBtnSpriteWithStatus(@"images/ui/button/bts_get_exp");
	NSArray *disableArr = getDisableBtnSpriteWithStatus(@"images/ui/button/bts_get_exp");
	CCMenuItemSprite *bt_label2 = [CCMenuItemSprite itemWithNormalSprite:[btns objectAtIndex:0] selectedSprite:[btns objectAtIndex:1] disabledSprite:[disableArr objectAtIndex:0] target:self selector:@selector(menuCallbackBack:)];
	bt_label2.tag = BT_GET_TRACE_TAG;

	bt_label2.position=ccp(790, 50);
	//end

	
	
	//-----
	btns = nil;
	btns = getBtnSpriteWithStatus(@"images/ui/button/bt_upgrade");
	
	CCMenuItemImage *bt_upgrade = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
														 selectedSprite:[btns objectAtIndex:1]
														 disabledSprite:nil
																 target:self
															   selector:@selector(menuCallbackBack:)];
	bt_upgrade.tag = BT_ARM_UPGRADE_TAG;

	bt_upgrade.position=ccp(400, 56);
	
	menu = [CCMenu menuWithItems:bt_label2, bt_upgrade,nil];
	menu.ignoreAnchorPointForPosition = YES;
	menu.position = CGPointZero;
	[self addChild:menu z:10];
	
    if (iPhoneRuningOnGame()) {
        bt_label2.position=ccp(790/2 + 90, 50/2 + 10);
        bt_upgrade.position=ccp(400/2 + 70, 56/2 + 10);
		bt_upgrade.scale = 1.3f;							//kevin	fixed,	before 1.2f
		bt_label2.scale = 1.5f;							//kevin	fixed,	before 1.2f
    }
	
	//----------------------------------------------------------------------------------------------
	//NSString *txt[4] = {@"所属主人：",@"固有技能：",@"宝具属性：",@"下一阶效果："};
    NSString *txt[4] = {
        NSLocalizedString(@"weapon_host",nil),
        NSLocalizedString(@"weapon_skill",nil),
        NSLocalizedString(@"weapon_property",nil),
        NSLocalizedString(@"weapon_next_effect",nil)};

	CGPoint _pt[4] = {ccp(640, 415),ccp(640, 391),ccp(640, 367),ccp(640, 128)};
	if(iPhoneRuningOnGame()){
		_pt[0] = ccp(640/2 + 90, 415/2 + 30);
		_pt[1] = ccp(640/2 + 90, 391/2 + 30-1);
		_pt[2] = ccp(640/2 + 90, 367/2 + 30-2);
		_pt[3] = ccp(640/2 + 90, 128/2 + 30-3);
	}
	
	for (int i = 0; i < 4; i++) {
		CCLabelTTF *label = [CCLabelTTF labelWithString:txt[i] fontName:getCommonFontName(FONT_1) fontSize:16];
		label.anchorPoint = ccp(0, 0.5);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:label z:2];
		label.position=_pt[i];
		label.color = ccc3(238, 228, 206);
		
        if (iPhoneRuningOnGame()) {
            label.scale = 0.5;
        }
		
	}	
	
	
	arm_name = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:22];
	arm_name.color = ccc3(235, 180, 70);
	arm_name.anchorPoint=ccp(0.5, 0.5);
	[arm_name setVerticalAlignment:kCCVerticalTextAlignmentCenter];
	[arm_name setHorizontalAlignment:kCCTextAlignmentCenter];
	[self addChild:arm_name z:3];
	arm_name.position=ccp(730, 460);
	if (iPhoneRuningOnGame()) {
        arm_host = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:22];
        arm_host.scale = 0.4;
    }else{
        arm_host = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:18];
    }
	arm_host.color = ccc3(78, 142, 202);
	arm_host.anchorPoint=ccp(0, 0.5);
	[arm_host setVerticalAlignment:kCCVerticalTextAlignmentCenter];
	[arm_host setHorizontalAlignment:kCCTextAlignmentLeft];
	[self addChild:arm_host z:3];
	arm_host.position=ccp(720, _pt[0].y);
    
    if (iPhoneRuningOnGame()) {
        arm_host.scale = 0.5;
        arm_host.position = ccp(720/2 + 90,_pt[0].y);
        arm_name.scale = 0.5;
        arm_name.position =ccp(730/2 + 90, 460/2 + 40);
    }
	
	effects = [CCLabelTTF labelWithString:@"" 
								 fontName:getCommonFontName(FONT_1)
								 fontSize:15 dimensions:CGSizeMake(300, 300)
							   hAlignment:kCCTextAlignmentLeft 
							   vAlignment:kCCVerticalTextAlignmentTop];
	effects.color = ccc3(253, 238, 130);
	effects.anchorPoint=ccp(0, 1.0f);
	[self addChild:effects z:3];

	per_effects = [CCLabelTTF labelWithString:@""
								 fontName:getCommonFontName(FONT_1)
								 fontSize:15 dimensions:CGSizeMake(300, 300)
							   hAlignment:kCCTextAlignmentLeft
							   vAlignment:kCCVerticalTextAlignmentTop];
	per_effects.color = ccc3(253, 238, 130);
	per_effects.anchorPoint=ccp(0, 1.0f);
	[self addChild:per_effects z:3];
	
	next_effect = [CCLabelTTF labelWithString:@"" 
									 fontName:getCommonFontName(FONT_1) 
									 fontSize:15 dimensions:CGSizeMake(300, 100)
								   hAlignment:kCCTextAlignmentLeft 
								   vAlignment:kCCVerticalTextAlignmentTop];
	next_effect.color = ccc3(253, 238, 130);
	next_effect.anchorPoint=ccp(0, 1.0f);
	[self addChild:next_effect z:3];
	
	
	level_need = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
	level_need.color = ccc3(238, 228, 206);
	level_need.visible = NO;
	[self addChild:level_need z:3];
	
	train_need = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
	train_need.visible = NO;
	[self addChild:train_need z:3];
    
    if (iPhoneRuningOnGame()) {
        effects.position=ccp(640/2 +90, 352/2 + 25);
        effects.scale = 0.5;
        per_effects.position=ccp(750/2 +90, 352/2 + 25);
        per_effects.scale = 0.5;
        next_effect.position=ccp(680/2 +90, 115/2 + 25);
        next_effect.scale = 0.5;
        level_need.position = ccp(400/2 +70, 72/2 + 25);
        level_need.scale = 0.5;
        train_need.position = ccp(400/2 +65, 94/2 + 15);
        train_need.scale = 0.5;

    }else{
        effects.position=ccp(640, 352);
        per_effects.position=ccp(750, 352);
        next_effect.position=ccp(680, 115);
        level_need.position = ccp(400, 72);
        train_need.position = ccp(400, 94);
    }
	//----------------------------------------------------------------------------------------------
	[self reload];
	[self updateTrain];
	
	[self scheduleOnce:@selector(delayShowUPGRADEbtn)  delay:1];
		
}

-(void)delayShowUPGRADEbtn{
	CCNode *node = [menu getChildByTag:BT_ARM_UPGRADE_TAG];
	if(node){
		[[Intro share] runIntroTager:node step:INTRO_Weapon_Step_1];
	}
}

-(void)onExit
{
    s_weapon_id_select = 0;
	if (skillBack) {
		skillBack = nil;
	}

    [GameConnection freeRequest:self];
	[super onExit];
}
-(void)menuCallbackBack:(id)sender
{
	CCNode *_obj = (CCNode*)sender;
	if (_obj.tag == BT_GET_TRACE_TAG) {
		[self handleSkillBack];
	}
	else if (_obj.tag == BT_ACTIVATE_SKILL1_TAG) {
		
	}
	else if (_obj.tag == BT_ACTIVATE_SKILL2_TAG) {
		
	}else if (_obj.tag == BT_ARM_UPGRADE_TAG) {
		CCLOG(@"----");
		//fix chao
		CCMenuItem *item_obj = (CCMenuItem *)_obj;
		item_obj.isEnabled = NO;
//		[self scheduleOnce:@selector(isSendCall) delay:1.0];
		//end
		//fix chao
		//BOOL result = [self checkArmUpgrade:id_select];
		int result = [self checkArmUpgrade:id_select];
		//if (result) {
		if (result>0) {
		//end
			NSDictionary *uRole = [[GameConfigure shared] getPlayerRoleFromListById:id_select];
			if (uRole) {
				int _id = [[uRole objectForKey:@"id"] intValue];
				if (_id != 0) {
					[self armUpgrade:_id];
				}
				else {
					CCLOG(@"id = 0");
				}
			}
		}
		//fix chao
		else{
			//fix chao
			NSString *string = nil;
			if(result == -1){
				//string = @"等级不够#00ff00";
                string = NSLocalizedString(@"weapon_level_low",nil);
			}else if(result == -2){
				//string = @"所需炼历不足#00ff00";
                string = NSLocalizedString(@"weapon_train_low",nil);
			}else{
				//string = @"升阶失败";
                string = NSLocalizedString(@"weapon_upgrade_fail",nil);
			}
			if (string) {
				[ShowItem showItemAct:string];
			}
			item_obj.isEnabled = YES;
			//end
		}
		//end
	}
}
-(void)handleSkillBack
{
	if (id_select != 0) {
		NSDictionary *uRole = [[GameConfigure shared] getPlayerRoleFromListById:id_select];
		if (uRole) {
			int arm_level = [[uRole objectForKey:@"armLevel"] intValue];
			int arm_exp = 0;
			for (int i = 0 ; i <= arm_level; i++) {
				NSDictionary *dict_temp  = [[GameDB shared] getArmExpInfo:i];
				if (dict_temp) {
					int exp = [[dict_temp objectForKey:@"exp"] intValue];
					arm_exp += exp;
				}
			}
			//NSString *infoString = [NSString stringWithFormat:@"可取回 |%d#FF0000| 炼历 |(90%%)#FF0000|，取回后宝具阶数降至 |0#FF0000| 阶，是否继续？", arm_exp];
            NSString *infoString = [NSString stringWithFormat:NSLocalizedString(@"weapon_get_train",nil), arm_exp];
			GameAlert *getAlert = [[AlertManager shared] showMessage:infoString target:self confirm:@selector(doSkillBack) canel:nil father:self.parent];
			
			if (skillBack) {
				skillBack = nil;
			}
			
			// 是否选择元宝取回炼历
			if (arm_level > 4) {
				skillBack = [CCSimpleButton node];
				skillBack.target = self;
				skillBack.call = @selector(selectGoldSkillBack);
				skillBack.anchorPoint = ccp(0, 0.5);
				skillBack.priority = INT32_MIN;
                skillBack.position = POS_SKILLBACK;

				
				//NSString *costString = [NSString stringWithFormat:@"花费 |%d#FF0000| 元宝，取回100%%炼历", arm_level*5];
                NSString *costString = [NSString stringWithFormat:NSLocalizedString(@"weapon_spend_get",nil), arm_level*5];
				CCSprite *costSprite = drawString(costString, CGSizeMake(350, 100), getCommonFontName(FONT_1), 22, 30, getHexStringWithColor3B(ccc3(255, 241, 207)));
				costSprite.anchorPoint = ccp(0, 0);
                costSprite.position =CGS_COSTSPRITE;
				skillBack.contentSize = costSprite.contentSize;
				[getAlert addChild:skillBack];
				if (skillBackGoldTips) {
					skillBackGoldTips = nil;
				}
				skillBackGoldTips = [CCSprite node];
				skillBackGoldTips.anchorPoint = skillBack.anchorPoint;
				skillBackGoldTips.position = skillBack.position;
				[skillBackGoldTips addChild:costSprite];
                
				
				CCSprite *selectBox = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
                selectBox.position =CGS_SELECTBOX;
				selectBox.anchorPoint = ccp(0.5, 0.5);
				[skillBackGoldTips addChild:selectBox];
				
				CCSprite *selectDone = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
				selectDone.anchorPoint = ccp(0.5, 0.5);
				selectDone.visible = NO;
                selectDone.position =CGS_SELECTBOX;
				selectDone.tag = SkillBack_Gold_Done_Tag;
				[skillBackGoldTips addChild:selectDone];
                
				[getAlert addChild:skillBackGoldTips];
			}
		}
	}
}
-(void)selectGoldSkillBack
{
	if (skillBackGoldTips) {
		CCNode *done = [skillBackGoldTips getChildByTag:SkillBack_Gold_Done_Tag];
		if (done) {
			done.visible = !done.visible;
		}
	}
}

-(void)doSkillBack
{
	NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:id_select];
	if (role) {
		int _id = [[role objectForKey:@"id"] intValue];
		if (_id != 0) {
			int tempType = 1;
			if (skillBack) {
				CCNode *done = [skillBackGoldTips getChildByTag:SkillBack_Gold_Done_Tag];
				if (done && done.visible) {
					tempType = 2;
				}
			}
			[self armDegrade:_id type:tempType];//免费取回
		}
	}
}
-(CCMenuItemImage*)upgradeBt
{
	NSArray *btns = getBtnSpriteWithStatus(@"images/ui/button/bt_upgrade");
	CCMenuItemImage *bt_upgrade = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
														 selectedSprite:[btns objectAtIndex:1]
														 disabledSprite:nil
																 target:self
															   selector:@selector(menuCallbackBack:)];
	bt_upgrade.tag = BT_ARM_UPGRADE_TAG;
	bt_upgrade.position=POS_BT_UPGRADE;
	return bt_upgrade;
}
-(void)reload
{
	if (cards) {
		[cards removeFromParentAndCleanup:true];
		cards = nil;
	}
	cards = [CCLayerList listWith:LAYOUT_Y :ccp(0, 0) :WIDTH_CARDS :HEIGHT_CARDS];
	[cards setDelegate:self];
	cards.isDownward = YES;
    //fix chao
    BOOL isReset=NO;
    RoleCard *t_card = nil;
    //end
	NSArray *_roles = [[GameConfigure shared] getTeamMember];
	for (int i = 0; i < _roles.count; i++) {
		RoleCard *_card = [RoleCard create:CARD_WEAPON];
		int _rid = [[_roles objectAtIndex:i] intValue];
		[_card initFormID:_rid];
		[cards addChild:_card];
        if (NO == isReset) {
            if (s_weapon_id_select == _rid) {
                isReset = YES;
                [cards setSelected:_card];
            }
        }
		if (i == 0) {//玩家自己
            t_card = _card;
            if (s_weapon_id_select<=0 && NO==isReset) {
                [cards setSelected:_card];
                isReset = YES;
            }
			//[cards setSelected:_card];
		}

	}
    if (NO==isReset) {
        if (t_card) {
            [cards setSelected:t_card];
        }
    }
	if (iPhoneRuningOnGame()) {
        float _py = self.contentSize.height - 61.7/2.0f - cards.contentSize.height;
        cards.position = ccp(17/2.0f + 44, _py);
    }else{
        float _py = self.contentSize.height - 65 - cards.contentSize.height;
        cards.position = ccp(34, _py);
	}
    [self addChild:cards z:1];
}
-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
	RoleCard *card_ = (RoleCard*)_listItem;
	id_select = card_.RoleID;//记录选择的角色ID
	[self updatePanel:card_.RoleID];
}
//fix chao
-(void)resetMenu{
    if (menu) {
        [menu removeFromParentAndCleanup:YES];
        menu = nil;
        bt_sk1 = nil;
        bt_sk2 = nil;
        skill_name = nil;
    }
    
	NSArray * btns = getBtnSpriteWithStatus(@"images/ui/button/bts_get_exp");
	NSArray *disableArr = getDisableBtnSpriteWithStatus(@"images/ui/button/bts_get_exp");
	CCMenuItemSprite *bt_label2 = [CCMenuItemSprite itemWithNormalSprite:[btns objectAtIndex:0] selectedSprite:[btns objectAtIndex:1] disabledSprite:[disableArr objectAtIndex:0] target:self selector:@selector(menuCallbackBack:)];
	bt_label2.tag = BT_GET_TRACE_TAG;
    
	bt_label2.position=ccp(790, 50);
	//end
    
	
	
	//-----
	btns = nil;
	btns = getBtnSpriteWithStatus(@"images/ui/button/bt_upgrade");
	CCMenuItemImage *bt_upgrade = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
														 selectedSprite:[btns objectAtIndex:1]
														 disabledSprite:nil
																 target:self
															   selector:@selector(menuCallbackBack:)];
	bt_upgrade.tag = BT_ARM_UPGRADE_TAG;
    
	bt_upgrade.position=ccp(400, 56);
	
	menu = [CCMenu menuWithItems:bt_label2, bt_upgrade,nil];
	menu.ignoreAnchorPointForPosition = YES;
	menu.position = CGPointZero;
	[self addChild:menu z:10];
	
    if (iPhoneRuningOnGame()) {
        bt_label2.position=ccp(790/2 + 90, 50/2 + 10);
        bt_upgrade.position=ccp(400/2 + 70, 56/2 + 10);
		bt_upgrade.scale = 1.3f;							//kevin	fixed,	before 1.2f
		bt_label2.scale = 1.5f;							//kevin	fixed,	before 1.2f
    }

}
//end
-(void)updatePanel:(int)_rid
{
    //TODO
    //fix chao
    [self resetMenu];
    //end
	if (_rid != 0) {
		NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
		if (role) {
			int arm_level = [[role objectForKey:@"armLevel"] intValue];//武器等级
            m_arm_level =  arm_level;
			int arm_sk = [[role objectForKey:@"sk"] intValue];//激活的技能ID =0 代表没有激活
			int db_rid = [[role objectForKey:@"rid"] intValue];//基础角色ID
			if (db_rid != 0) {
				NSDictionary *db_role = [[GameDB shared] getRoleInfo:db_rid];
				if (db_role) {
					//TODO
					int arm_id = [[db_role objectForKey:@"armId"] intValue];//武器ID
					if (arm_id != 0) {
						//-------------------------------------------------
						NSDictionary *arm = [[GameDB shared] getArmInfo:arm_id];
						if (arm) {
							//TODO
							NSString *a_name = [arm objectForKey:@"name"];
							if (a_name) {
								if(arm_level>0){
									//arm_name.string = [NSString stringWithFormat:@"%@ %d阶", a_name, arm_level];
                                    arm_name.string = [NSString stringWithFormat:NSLocalizedString(@"weapon_rank",nil), a_name, arm_level];
								}else{
									arm_name.string = [NSString stringWithFormat:@"%@", a_name];
								}
								
							}
							
							int role_quality = [[db_role objectForKey:@"quality"] intValue];
							if ((role_quality == IQ_GREEN) && (arm_level > 10)) {//大于10
								[self updateEffects:arm_id level:10];//最大去到10级
							}
							else {
								[self updateEffects:arm_id level:arm_level];//属性
							}
							
							//TODO use arm id
							// 主角
							if (db_rid == [[GameConfigure shared] getPlayerRole]) {
								NSDictionary *hostDict = [[GameConfigure shared] getPlayerRoleFromListById:db_rid];
								if (hostDict) {
									int eq2 = [[hostDict objectForKey:@"eq2"] intValue];
									if (eq2 > 0) {
										NSDictionary* rEq = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
										int _eid_ = [[rEq objectForKey:@"eid"] intValue];
										NSDictionary* dEq = [[GameDB shared] getEquipmentInfo:_eid_];
										int _sid_ = [[dEq objectForKey:@"sid"] intValue];
										[self updateWeapon:_rid :_sid_];
									}else{
										[self updateWeapon:_rid :-1];
									}
									
									// debug, equipDict返回不为nil
//									NSDictionary *equipDict = [[GameDB shared] getEquipmentInfo:eq2];
//									if (equipDict) {
//										int sid = [[equipDict objectForKey:@"sid"] intValue];
//										//fix chao
//										//[self updateWeapon:arm_id :sid];
//										[self updateWeapon:_rid :sid];
//										//end
//									}
//									else {
//										//fix chao
//										//[self updateWeapon:arm_id :-1];	// 没有套装，显示默认武器
//										[self updateWeapon:_rid :-1];	// 没有套装，显示默认武器
//										//end
//									}
								}
							} else {
								//fix chao
								//[self updateWeapon:arm_id :-1];
								[self updateWeapon:_rid :-1];
								//end
							}
							//[self updateRune:arm_sk arm:arm_id];//符文
							
							// 满级了，不可以再升
							if (![[GameDB shared] getArmLevelInfo:arm_id level:(arm_level+1)]) {
								CCNode *bt_upgrade = [menu getChildByTag:BT_ARM_UPGRADE_TAG];
								bt_upgrade.visible = NO;
								train_need.visible = NO;
								level_need.visible = NO;
							} else {
								NSDictionary *uRole = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
								NSDictionary *dRole = [[GameDB shared] getRoleInfo:_rid];
								if (uRole && dRole) {
									int arm_level = [[uRole objectForKey:@"armLevel"] intValue];//武器等级
									int role_level = [[GameConfigure shared] getPlayerLevel];//角色等级
									int train = [[GameConfigure shared] getPlayerTrain];
									NSDictionary *expDict = [[GameDB shared] getArmExpInfo:(arm_level+1)];
									if (expDict) {
										int need_level = [[expDict objectForKey:@"limit"] intValue];
										int need_exp = [[expDict objectForKey:@"exp"] intValue];
										// 等级ok
										if (role_level >= need_level) {
											// 炼历ok
											if (train >= need_exp) {
												train_need.color = ccc3(238, 228, 206);
											}
											// 炼历不足
											else {
												train_need.color = ccc3(255, 0, 0);
											}
											CCNode *bt_upgrade = [menu getChildByTag:BT_ARM_UPGRADE_TAG];
											bt_upgrade.visible = YES;
											//train_need.string = [NSString stringWithFormat:@"需要炼历：%d", need_exp];
                                            train_need.string = [NSString stringWithFormat:NSLocalizedString(@"weapon_need_train",nil), need_exp];
											train_need.visible = YES;
											level_need.visible = NO;
										}
										// 等级不足
										else {
											CCNode *bt_upgrade = [menu getChildByTag:BT_ARM_UPGRADE_TAG];
											bt_upgrade.visible = NO;
											train_need.visible = NO;
											//level_need.string = [NSString stringWithFormat:@"等级达到%d级可升阶", need_level];
                                            level_need.string = [NSString stringWithFormat:NSLocalizedString(@"weapon_need_level",nil), need_level];
											level_need.visible = YES;
										}
									}
								}
							}
							
							//------------------------------------------------------------------
							//取回炼历
							CCMenuItemImage *bt_back = (CCMenuItemImage*)[menu getChildByTag:BT_GET_TRACE_TAG];
							bt_back.isEnabled = (arm_level > 0);
							//------------------------------------------------------------------
							//符文
							int arm_sk1 = [[arm objectForKey:@"sk1"] intValue];
							int arm_sk2 = [[arm objectForKey:@"sk2"] intValue];
							[self updateRune:arm_sk sk1:arm_sk1 sk2:arm_sk2 level:arm_level];
							//------------------------------------------------------------------
						}
						else {
							//TODO
							CCLOG(@"arm is null");
						}
						//-------------------------------------------------
						int quality = [[GameConfigure shared] getRoleQualityWithRid:db_rid ];
						arm_host.color = getColorByQuality(quality);
						
						if (db_rid == [[GameConfigure shared] getPlayerRole]) {
							//主角
							NSString *r_name = [[GameConfigure shared] getPlayerName];
							if (r_name) {
								arm_host.string=r_name;
																
							}
						}
						else {
							//配将
							NSString *r_name = [db_role objectForKey:@"name"];
							if (r_name) {
								arm_host.string=r_name;								
							}
						}
						//---------------------------------------------------
						int db_skid = [[db_role objectForKey:@"sk2"] intValue];
						if (db_skid != 0) {
							NSDictionary *db_skill = [[GameDB shared] getSkillInfo:db_skid];
							if (db_skill) {
								NSString *s_name = [db_skill objectForKey:@"name"];
								if (s_name) {
									//fix chao
									//skill_name.string=s_name;
									if (skill_name) {
										[skill_name removeFromParentAndCleanup:YES];
                                        skill_name = nil;
									}
                                    int f_size = 18;
                                    if (iPhoneRuningOnGame()) {
                                        f_size = 28;
                                    }
									NSArray *labelArray = getUnderlineSpriteArray(s_name,getCommonFontName(FONT_1), f_size, ccc4(78, 142, 202,255));
                                    /*
									CCSprite *nameSpr = getUnderlineSprite(s_name,getCommonFontName(FONT_1), 18, ccc4(78, 142, 202,255));
									CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:s_name fontName:getCommonFontName(FONT_1) fontSize:18];
									nameLabel.color = ccc3(78, 142, 202);
                                     */
									CCMenuItemFont *bt_nameItem = [CCMenuItemSprite itemWithNormalSprite:[labelArray objectAtIndex:0] selectedSprite:[labelArray objectAtIndex:1] target:self selector:@selector(skillNameBackCall)];
									skill_name = bt_nameItem;
                                    [menu addChild:skill_name z:3];
                                    /*
                                    skill_name = [labelArray objectAtIndex:0];
									[self addChild:skill_name z:3];
                                     */
                                    if (iPhoneRuningOnGame()) {
                                        skill_name.scale = 0.4;
                                        skill_name.contentSize = CGSizeMake(skill_name.contentSize.width, skill_name.contentSize.height*2);
                                        skill_name.position=ccp(720/2+skill_name.contentSize.width/4 + 86-2, 391/2 + 30+6);
                                    }else
                                        skill_name.position=ccp(720+skill_name.contentSize.width/2, 391);
									//end
								}
								//TODO
							}
						}
						else {
							CCLOG(@"id = 0!");
						}
						//----------------------------------------------------
					}
				}
				else {
					//todo
					CCLOG(@"updatePanel: db_role is null");
				}
			}
			else {
				CCLOG(@"role id can't = 0");
			}
		}
		else {
			CCLOG(@"updatePanel:can't find this role! rid=%d",_rid);
		}
	}
	else {
		CCLOG(@"updatePanel rid=0!");
	}
}
//fix chao
-(void)showSKWithPosint:(CGPoint)pos anPosition:(CGPoint)p type:(NSInteger)type{
	CCNode *node = [self getChildByTag:555];
	if (node) {
		[self removeChildByTag:555 cleanup:YES];
	}
	if (skill_name ) {
		NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:id_select];//list
		if (role) {			
			NSString *s_info = nil;
			NSDictionary *arm = nil;
			int arm_sk_1=0;
			int arm_sk_2=0;
			int arm_sk_t=0;
			int arm_id=0;//武器ID
			int arm_level=0;//武器等级
			
			//符文
			int db_rid = [[role objectForKey:@"rid"] intValue];//基础角色ID
			int arm_sk = [[role objectForKey:@"sk"] intValue];//激活的技能ID =0 代表没有激活
			if (db_rid != 0) {
				NSDictionary *db_role = [[GameDB shared] getRoleInfo:db_rid];
				if (db_role) {
					//TODO
					arm_id = [[db_role objectForKey:@"armId"] intValue];//武器ID
					arm_level = [[db_role objectForKey:@"armLevel"] intValue];//武器等级
					arm_sk_t = [[db_role objectForKey:@"sk2"] intValue];//人物 sk2					
					if (arm_id != 0) {
						//-------------------------------------------------
						arm = [[GameDB shared] getArmInfo:arm_id];
						arm_sk_1 = [[arm objectForKey:@"sk1"] intValue];
						arm_sk_2 = [[arm objectForKey:@"sk2"] intValue];
						
					}
				}
			}
			NSString *colStr = getHexStringWithColor3B(ccc3(235, 180, 70));
			NSDictionary *db_skill_1 = [[GameDB shared] getSkillInfo:arm_sk_1];//符印1
			NSDictionary *db_skill_2 = [[GameDB shared] getSkillInfo:arm_sk_2];//符印2
			NSDictionary *db_skill_t = [[GameDB shared] getSkillInfo:arm_sk_t];//特功
			int fontSize = 16;
            if (iPhoneRuningOnGame()) {
                fontSize = 20;     //kevin fixed ,before 18
            }
			if (type==0) {
				//s_info = [NSString stringWithFormat:@"固有技能:%@#%d#0*|%@*^10*",colStr,fontSize,[db_skill_t objectForKey:@"info"]];
                s_info = [NSString stringWithFormat:NSLocalizedString(@"weapon_fix_skill",nil),colStr,fontSize,[db_skill_t objectForKey:@"info"]];
				if (arm_sk == arm_sk_1) {
					//s_info = [s_info stringByAppendingFormat:@"%@",[NSString stringWithFormat:@"|技能变化:%@%@#%d#0*",[db_skill_1 objectForKey:@"name"],colStr,fontSize]];
                    s_info = [s_info stringByAppendingFormat:@"%@",[NSString stringWithFormat:@"|%@",[NSString stringWithFormat:NSLocalizedString(@"weapon_change_skill",nil),[db_skill_1 objectForKey:@"name"],colStr,fontSize]]];
					s_info = [s_info stringByAppendingFormat:@"|%@*^10*",[db_skill_1 objectForKey:@"info"]];					
//					NSNumber *hurt = [db_skill_2 objectForKey:@"rHurt1"];					
//					s_info = [s_info stringByAppendingFormat:@"伤害#ffff00#16#0*技能伤害提升%d#ffffff#16#0*",[hurt intValue]];					
				}else if(arm_sk == arm_sk_2){
					//s_info = [s_info stringByAppendingFormat:@"%@",[NSString stringWithFormat:@"|技能变化:%@%@#%d#0*",[db_skill_2 objectForKey:@"name"],colStr,fontSize]];
                    s_info = [s_info stringByAppendingFormat:@"%@",[NSString stringWithFormat:@"|%@",[NSString stringWithFormat:NSLocalizedString(@"weapon_change_skill",nil),[db_skill_2 objectForKey:@"name"],colStr,fontSize]]];
					s_info = [s_info stringByAppendingFormat:@"|%@*^10*",[db_skill_2 objectForKey:@"info"]];
					
//					NSNumber *hurt = [db_skill_2 objectForKey:@"rHurt1"];
//					s_info = [s_info stringByAppendingFormat:@"伤害#ffff00#16#0*技能伤害提升%d#ffffff#16#0*",[hurt intValue]];
				}
				NSDictionary *armDict = [[GameDB shared] getArmLevelInfo:arm_id level:arm_level];
				NSNumber *hurt = [armDict objectForKey:@"hurt_p"];
				if([hurt intValue]>0){
					//s_info = [s_info stringByAppendingFormat:@"|伤害:%@#16#0*|技能伤害提升|%d#00ff00#16#0*",colStr,[hurt intValue]];
                    s_info = [s_info stringByAppendingFormat:NSLocalizedString(@"weapon_skill_hurt",nil),colStr,[hurt intValue]];
				}
			}else if(type==1){
				
				//s_info = [NSString stringWithFormat:@"技能变化:%@%@#%d#0*",[db_skill_1 objectForKey:@"name"],colStr,fontSize];
                s_info = [NSString stringWithFormat:NSLocalizedString(@"weapon_change_skill",nil),[db_skill_1 objectForKey:@"name"],colStr,fontSize];
				s_info = [s_info stringByAppendingFormat:@"|%@*",[db_skill_1 objectForKey:@"info"]];
			}else if(type==2){
				//s_info = [NSString stringWithFormat:@"技能变化:%@%@#%d#0*",[db_skill_2 objectForKey:@"name"],colStr,fontSize];
                s_info = [NSString stringWithFormat:NSLocalizedString(@"weapon_change_skill",nil),[db_skill_2 objectForKey:@"name"],colStr,fontSize];
				s_info = [s_info stringByAppendingFormat:@"|%@*",[db_skill_2 objectForKey:@"info"]];
			}
            int info_w = 135;
            if (iPhoneRuningOnGame()) {
                info_w = 300;		//kevin fixed ,before	200
            }
			CCSprite *draw = drawString(s_info, CGSizeMake(info_w,0), getCommonFontName(FONT_1), fontSize, fontSize+4, @"#EBE2D0");
            if (iPhoneRuningOnGame()) {
                if (type==0) {
                    pos = ccpAdd(pos, ccp(-35,0));
                }else{
                    pos = ccpAdd(pos, ccp(-65/2,0));
                }
            }
			[InfoAlert show:self drawSprite:draw parent:self position:pos anchorPoint:p offset:CGS_DRAWSPRITE];
		}
	}
}
-(void)skillNameBackCall{
	CGPoint finalPosition =ccp(0, 0);
    if (skill_name) {
        finalPosition = ccpAdd(skill_name.position, ccp(0, cFixedScale(-20)));
    }
	[self showSKWithPosint:finalPosition anPosition:POS_SKILL_NAME type:0];
}
//end
/*
 * 激活的技能 武器带的技能1 武器带的技能2 武器等级
 */
-(void)updateRune:(int)_active sk1:(int)_sk1 sk2:(int)_sk2 level:(int)_level
{ 
	//----------------------------------------------------
	if ( _sk1 == 0 || _sk2 == 0 ) {
		CCLOG(@"_sk1 == 0 || _sk2 == 0");
		return ;
	}
	if (menu) {
       	if (bt_sk1) {
            [bt_sk1 removeFromParentAndCleanup:YES];
            bt_sk1 = nil;
        }
        if (bt_sk2) {
            [bt_sk2 removeFromParentAndCleanup:YES];
            bt_sk2 = nil;
        }
    }

    CCLOG(@"weapon----------1");
    
	if (_level >= 6) {
         CCLOG(@"weapon----------_level >= 6");
		if (_active == _sk1 || _active == _sk2) { //必须知道是激活技能之一
			BOOL _isSk1 = (_active == _sk1);
			NSArray *array = getRune(_sk1);
			//NSArray *array2 = getRune(_sk1);
			if (array) {
				if (_isSk1) {
					bt_sk1 = [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:0] selectedSprite:nil target:self selector:@selector(handleRune:)];
                    //bt_sk1 = [CCSimpleButton spriteWithFile:[array objectAtIndex:0] select:[array objectAtIndex:0] target:self call:@selector(handleRune:)];
				}else {
					bt_sk1 = [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:1] selectedSprite:nil target:self selector:@selector(handleRune:)];
                    //bt_sk1 = [CCSimpleButton spriteWithFile:[array objectAtIndex:1] select:[array objectAtIndex:1] target:self call:@selector(handleRune:)];
				}
				[menu addChild:bt_sk1 z:10 tag:BT_ACTIVATE_SKILL1_TAG];
                //[self addChild:bt_sk1 z:10 tag:BT_ACTIVATE_SKILL1_TAG];
                
                if (iPhoneRuningOnGame()) {
                    bt_sk1.position=ccp(200, 70);
                    bt_sk1.scale = 1.2;
                }else{
				bt_sk1.position=POS_BT_SK1;
				}
			}
			else {
				CCLOG(@"_level >= 3 image is null by sid=%d",_sk1);
			}
			 CCLOG(@"weapon----------2");
			array = nil;
			//array2 = nil;
			array = getRune(_sk2);
			//array2 = getRune(_sk2);
			if (array) {
                 CCLOG(@"weapon----------3");
				if (_isSk1) {
					bt_sk2 = [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:1] selectedSprite:nil target:self selector:@selector(handleRune:)];
                    //bt_sk2 = [CCSimpleButton spriteWithFile:[array objectAtIndex:1] select:[array2 objectAtIndex:1] target:self call:@selector(handleRune:)];
				}
				else {
					bt_sk2 = [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:0] selectedSprite:nil target:self selector:@selector(handleRune:)];
                    //bt_sk2 = [CCSimpleButton spriteWithFile:[array objectAtIndex:0] select:[array2 objectAtIndex:0] target:self call:@selector(handleRune:)];
				}
				[menu addChild:bt_sk2 z:10 tag:BT_ACTIVATE_SKILL2_TAG];
                //[self addChild:bt_sk2 z:10 tag:BT_ACTIVATE_SKILL2_TAG];
                
                if (iPhoneRuningOnGame()) {
                    bt_sk2.position=ccp(330, 70);
                    bt_sk2.scale = 1.2;
                }else{
				bt_sk2.position=POS_BT_SK2;
				}
			}
			else {
				CCLOG(@"_level >= 3 image is null by sid=%d",_sk2);
			}
		}
	}else if (_level >= 3) {
         CCLOG(@"weapon----------4");
		if (_active == _sk1) {
			NSArray *array = getRune(_sk1);
			if (array) {
				bt_sk1 = [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:0] selectedSprite:[array objectAtIndex:1] target:self selector:@selector(handleRune:)];
                //bt_sk1 = [CCSimpleButton spriteWithFile:[array objectAtIndex:0] select:[array objectAtIndex:1] target:self call:@selector(handleRune:)];
				[menu addChild:bt_sk1 z:10 tag:BT_ACTIVATE_SKILL1_TAG];
                //[self addChild:bt_sk1 z:10 tag:BT_ACTIVATE_SKILL1_TAG];
                
				//bt_sk1.isEnabled = NO;
                if (iPhoneRuningOnGame()) {
                    bt_sk1.position=ccp(200, 70);
                    bt_sk1.scale = 1.2;
                }else{
				bt_sk1.position=POS_BT_SK1;
				}
			}
			else {
				CCLOG(@"_level >= 3 image is null by sid=%d",_sk1);
			}
		}
		else {
			CCLOG(@"_active == _sk1 but _level >= 3");
		}
	}else {
		CCLOG(@"level too lower!");
		//fix chao
//		CGPoint pos = ccp(400, self.contentSize.height/2+100);
//		CCSprite* spr = [CCLabelTTF labelWithString:@"等级不够！" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
//		[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
		//end
	}
	//----------------------------------------------------
    CCLOG(@"weapon----------end");
}
-(void)handleRune:(id)sender
{
	CCLOG(@"handleRune");
    NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:id_select];
    int arm_level = [[role objectForKey:@"armLevel"] intValue];//武器等级
    
     CCMenuItemSprite *_obj = (CCMenuItemSprite*)sender;
    if (arm_level == m_arm_level ) {
        if (m_arm_level >= 6) {
            
            if (_obj.tag == BT_ACTIVATE_SKILL1_TAG) {
                CCLOG(@"handleRune1");
                [self active:id_select skill:1];
                //fix chao
                [self showSKWithPosint:ccp(_obj.position.x,_obj.position.y+POS__OBJ_ADD_Y) anPosition:POS__OBJ type:1];
                //end
            }
            else if (_obj.tag == BT_ACTIVATE_SKILL2_TAG) {
                CCLOG(@"handleRune2");
                [self active:id_select skill:2];
                //fix chao
                [self showSKWithPosint:ccp(_obj.position.x,_obj.position.y+POS__OBJ_ADD_Y) anPosition:POS__OBJ type:2];
                //end
            }
        }else if (m_arm_level >= 3){
            if (_obj.tag == BT_ACTIVATE_SKILL1_TAG) {
                //fix chao
                [self showSKWithPosint:ccp(_obj.position.x,_obj.position.y+POS__OBJ_ADD_Y) anPosition:POS__OBJ type:1];
                //end
            }//end
        }
    }else{
        CCLOG(@"arm level error!");
    }
}
-(void)active:(int)_rid skill:(int)_side
{
	if (_rid == 0) {
		CCLOG(@"_rid == 0");
		return ;
	}
	if (_side == 1 || _side == 2) {
		NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
		if (role) {
			int _id = [[role objectForKey:@"id"] intValue];
			int _sk = [[role objectForKey:@"sk"] intValue];
			int db_rid = [[role objectForKey:@"rid"] intValue];
			NSDictionary *db_role = [[GameDB shared] getRoleInfo:db_rid];
			int db_aid = [[db_role objectForKey:@"armId"] intValue];
			NSDictionary *db_arm = [[GameDB shared] getArmInfo:db_aid];
			int sk1 = [[db_arm objectForKey:@"sk1"] intValue];
			int sk2 = [[db_arm objectForKey:@"sk2"] intValue];
			if (_id != 0 && sk1 != 0 && sk2 != 0 && _sk != 0) {
				if (_side == 1) {
					if (_sk == sk1) {
						[self armSkill:_id skill:sk2];			//kevin	fixed,	before sk2
					}
					else if (_sk == sk2) {
						[self armSkill:_id skill:sk1];
					}
				}
				else if (_side == 2) {
					if (_sk == sk1) {
						[self armSkill:_id skill:sk2];
					}
					else if (_sk == sk2) {
						[self armSkill:_id skill:sk1];			//kevin	fixed,	before sk1
					}
				}
			}
		}
	}
	else {
		CCLOG(@"_side is error!");
	}
}
//fix chao
-(int)checkArmUpgrade:(int)_rid
{
	if (_rid != 0) {
		NSDictionary *uRole = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
		NSDictionary *dRole = [[GameDB shared] getRoleInfo:_rid];
		if (uRole && dRole) {
			int arm_level = [[uRole objectForKey:@"armLevel"] intValue];//武器等级
			int role_level = [[GameConfigure shared] getPlayerLevel];//角色等级
			int train = [[GameConfigure shared] getPlayerTrain];
			NSDictionary *expDict = [[GameDB shared] getArmExpInfo:(arm_level+1)];
			if (expDict) {
				int need_level = [[expDict objectForKey:@"limit"] intValue];
				int need_exp = [[expDict objectForKey:@"exp"] intValue];
				if((role_level >= need_level)&& (train >= need_exp)){
					return 1;
				}else if ((role_level < need_level)) {
					return -1;
				}else if(train < need_exp){
					return -2;
				}				
			}
			
		}
	}
	return 0;
}
/*
-(BOOL)checkArmUpgrade:(int)_rid
{
	if (_rid != 0) {
		NSDictionary *uRole = [[GameConfigure shared] getPlayerRoleFromListById:_rid];
		NSDictionary *dRole = [[GameDB shared] getRoleInfo:_rid];
		if (uRole && dRole) {
			int arm_level = [[uRole objectForKey:@"armLevel"] intValue];//武器等级
			int role_level = [[GameConfigure shared] getPlayerLevel];//角色等级
			int train = [[GameConfigure shared] getPlayerTrain];
			NSDictionary *expDict = [[GameDB shared] getArmExpInfo:(arm_level+1)];
			if (expDict) {
				int need_level = [[expDict objectForKey:@"limit"] intValue];
				int need_exp = [[expDict objectForKey:@"exp"] intValue];
				return (role_level >= need_level)&&(train >= need_exp);
			}
			
		}
	}
	return NO;
}
 */
//end
-(void)updateEffects:(int)a_id level:(int)_level
{
	if (a_id == 0) {
		CCLOG(@"updateEffects id == 0");
		return ;
	}
	NSMutableDictionary *record_info = [NSMutableDictionary dictionary];//用于处理2个等级之间的属性差异
	NSDictionary *l_arm = [[GameDB shared] getArmLevelInfo:a_id level:_level];//当前等级
	if (l_arm) {
		CCLOG([l_arm description]);
		NSString *temp = [NSString stringWithFormat:@""];
		NSString *per_temp = [NSString stringWithFormat:@""];	// 含百分号
				
		BaseAttribute attr = BaseAttributeFromDict(l_arm);
		NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
		
		NSArray *array = [string componentsSeparatedByString:@"|"];
		for (NSString *_string in array) {
			
			NSArray *_array = [_string componentsSeparatedByString:@":"];
			if (_array.count >= 2) {
				NSString *name = [_array objectAtIndex:0];
				NSString *value = [[_array objectAtIndex:1] stringByReplacingOccurrencesOfString:@"%" withString:@""];
				
				BOOL isPercent = NO;
				NSRange range = [_string rangeOfString:@"%"];
				if (range.length != 0) {
					isPercent = YES;
				}
				
				NSString *__string = [_string stringByReplacingOccurrencesOfString:NSLocalizedString(@"weapon_ratio",nil) withString:@""];
				if (isPercent) {
					per_temp = [per_temp stringByAppendingFormat:@"%@\n",__string];
				} else {
					temp = [temp stringByAppendingFormat:@"%@\n",__string];
				}
				
				[record_info setObject:[NSNumber numberWithFloat:[value floatValue]] forKey:name];
			}
		}
		 
		NSString *setting = [[GameDB shared] getGlobalSetting:@"display_now"];
		NSArray *settingArray = [setting componentsSeparatedByString:@"|"];
		for (NSString *settingStr in settingArray) {
			NSArray *__settingArray = [settingStr componentsSeparatedByString:@":"];
			if (__settingArray.count >= 2) {
				
				for (NSString *key in getOtherProperty()) {
					if ([key isEqualToString:[__settingArray objectAtIndex:0]]) {
						float __value = [[l_arm objectForKey:key] floatValue];
						if (__value > 0) {
							
							NSString *__settingName = [__settingArray objectAtIndex:1];
							NSString *__name = [__settingName stringByReplacingOccurrencesOfString:NSLocalizedString(@"weapon_ratio",nil) withString:@""];
							
							BOOL isPercent = (__settingArray.count >= 3);
							if (isPercent) {
								per_temp = [per_temp stringByAppendingFormat:@"%@:%.1f%%\n", __name, __value];
							} else {
								temp = [temp stringByAppendingFormat:@"%@:%.0f\n", __name, __value];
							}
							
							[record_info setObject:[NSNumber numberWithFloat:__value] forKey:__settingName];
						}
					}
				}
			}
		}
		
		/*
		for (int i = 0 ; i < 24 ; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value = [[l_arm objectForKey:[args objectAtIndex:0]] floatValue];
			if (_value > 0) {
				if (args.count == 3) {
                    
					//NSString *name = [[args objectAtIndex:1] stringByReplacingOccurrencesOfString:@"率" withString:@""];
                    NSString *name = [[args objectAtIndex:1] stringByReplacingOccurrencesOfString:NSLocalizedString(@"weapon_ratio",nil) withString:@""];
					NSString *str_temp = [NSString stringWithFormat:@"%@：%.1f%@",name,_value,@"%"];
					CCLOG(str_temp);
//					temp = [temp stringByAppendingFormat:@"%@\n",str_temp];//fuck
					per_temp = [per_temp stringByAppendingFormat:@"%@\n",str_temp];
					[record_info setObject:[NSNumber numberWithFloat:_value] forKey:[args objectAtIndex:1]];//存储
				}
				else {
					//NSString *name = [[args objectAtIndex:1] stringByReplacingOccurrencesOfString:@"率" withString:@""];
                    NSString *name = [[args objectAtIndex:1] stringByReplacingOccurrencesOfString:NSLocalizedString(@"weapon_ratio",nil) withString:@""];
					NSString *str_temp = [NSString stringWithFormat:@"%@：%.0f",name,_value];
					CCLOG(str_temp);
					temp = [temp stringByAppendingFormat:@"%@\n",str_temp];//fuck 
					[record_info setObject:[NSNumber numberWithFloat:_value] forKey:[args objectAtIndex:1]];//存储
				}
			}
		}
		 */
		 
		CCLOG(temp);
		if (temp.length > 0) {
			effects.string = temp;
			per_effects.string = per_temp;
		}
	}
	else {
		CCLOG(@"can't find arm");
	}
	NSDictionary *nl_arm = [[GameDB shared] getArmLevelInfo:a_id level:(_level+1)];//当前等级
	if (nl_arm) {
		NSString *str_effect = @"";
		
		BaseAttribute attr = BaseAttributeFromDict(nl_arm);
		NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
		
		NSArray *array = [string componentsSeparatedByString:@"|"];
		for (NSString *_string in array) {
			
			NSArray *_array = [_string componentsSeparatedByString:@":"];
			if (_array.count >= 2) {
				
				NSString *name = [_array objectAtIndex:0];
				NSString *value = [[_array objectAtIndex:1] stringByReplacingOccurrencesOfString:@"%" withString:@""];
				
				float record_value = [[record_info objectForKey:name] floatValue];
				if (record_value != 0) {//有这东西
					if ([value floatValue] > record_value) {
						
						[record_info setObject:[NSNumber numberWithFloat:[value floatValue]] forKey:name];//更新
						str_effect = [str_effect stringByAppendingFormat:@"%@:+%@\n",name,[_array objectAtIndex:1]];
					} else if ([value floatValue] == record_value) {
						[record_info removeObjectForKey:name];
					}
				} else {//没有直接添加
					
					[record_info setObject:[NSNumber numberWithFloat:[value floatValue]] forKey:name];//添加
					str_effect = [str_effect stringByAppendingFormat:@"%@:+%@\n",name,[_array objectAtIndex:1]];
				}
			}
		}
		
		NSString *setting = [[GameDB shared] getGlobalSetting:@"display_now"];
		NSArray *settingArray = [setting componentsSeparatedByString:@"|"];
		for (NSString *settingStr in settingArray) {
			NSArray *__settingArray = [settingStr componentsSeparatedByString:@":"];
			if (__settingArray.count >= 2) {
				
				for (NSString *key in getOtherProperty()) {
					if ([key isEqualToString:[__settingArray objectAtIndex:0]]) {
						float __value = [[nl_arm objectForKey:key] floatValue];
						if (__value > 0) {
							
							NSString *__settingName = [__settingArray objectAtIndex:1];
							
							BOOL isPercent = (__settingArray.count >= 3);
							NSString *valueString = nil;
							if (isPercent) {
								valueString = [NSString stringWithFormat:@"%@:+%.1f%%\n", __settingName, __value];
							} else {
								valueString = [NSString stringWithFormat:@"%@:+%.0f\n", __settingName, __value];
							}
							
							float record_value = [[record_info objectForKey:__settingName] floatValue];
							if (record_value != 0) {
								
								if (__value > record_value) {
									[record_info setObject:[NSNumber numberWithFloat:__value] forKey:__settingName];
									str_effect = [str_effect stringByAppendingFormat:@"%@\n",valueString];
								} else if (__value == record_value) {
									[record_info removeObjectForKey:__settingName];
								}
								
							} else {//没有直接添加
								
								[record_info setObject:[NSNumber numberWithFloat:__value] forKey:__settingName];
								str_effect = [str_effect stringByAppendingFormat:@"%@\n",valueString];
							}
						}
					}
				}
			}
		}
		
		/*
		for (int i = 0 ; i < 24 ; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value = [[nl_arm objectForKey:[args objectAtIndex:0]] floatValue];
			if (_value > 0) {
				float _temp_value = [[record_info objectForKey:[args objectAtIndex:1]] floatValue];
				if (_temp_value != 0) {//有这东西
					if (_value > _temp_value) {
						[record_info setObject:[NSNumber numberWithFloat:_value] forKey:[args objectAtIndex:1]];//更新
						if (args.count == 3) {
							NSString *str_temp = [NSString stringWithFormat:@"%@：+%.1f%@",[args objectAtIndex:1],_value,@"%"];
							str_effect = [str_effect stringByAppendingFormat:@"%@\n",str_temp];
						}
						else {
							NSString *str_temp = [NSString stringWithFormat:@"%@：+%.0f",[args objectAtIndex:1],_value];
							CCLOG(str_temp);
							str_effect = [str_effect stringByAppendingFormat:@"%@\n",str_temp];
						}
					}else if(_value == _temp_value){
						[record_info removeObjectForKey:[args objectAtIndex:1]];//删除
					}
				}
				else {//没有直接添加
					[record_info setObject:[NSNumber numberWithFloat:_value] forKey:[args objectAtIndex:1]];
					if (args.count == 3) {
						NSString *str_temp = [NSString stringWithFormat:@"%@：＋%.1f%@",[args objectAtIndex:1],_value,@"%"];
						str_effect = [str_effect stringByAppendingFormat:@"%@\n",str_temp];
					}
					else {
						NSString *str_temp = [NSString stringWithFormat:@"%@：＋%.0f",[args objectAtIndex:1],_value];
						CCLOG(str_temp);
						str_effect = [str_effect stringByAppendingFormat:@"%@\n",str_temp];
					}
				}
			}
		}
		 */
		 
		if (str_effect.length > 0) {
			next_effect.string = str_effect;
		}
		else {
			if ((_level+1)==3) {
				//next_effect.string = @"激活技能";
                next_effect.string = NSLocalizedString(@"weapon_activation_skill",nil);
			}
			else if ((_level+1) == 6) {
				//next_effect.string = @"激活技能";
                next_effect.string = NSLocalizedString(@"weapon_activation_skill",nil);
			}
			else {
				next_effect.string = @"";
			}
		}
//		[str_effect release];
	}
	else {
		CCLOG(@"can't find arm");
		if (next_effect) {
			//next_effect.string = @"已达上限";
            next_effect.string = NSLocalizedString(@"weapon_skill_top",nil);
		}
	}
}
/*
 根据武器id和套装id更新武器
 aid: 武器
 sid: 套装。非主角，sid为-1, 不根据套装获取
 */
-(void)updateWeapon:(int)_aid :(int)_sid
{
	//fix chao
	if (_aid==2) {
		_aid=1;
	}else if(_aid==4){
		_aid = 3;
	}else if(_aid==6){
		_aid = 5;
	}
	
	//end
	
	if (weapon) {
		[weapon removeFromParentAndCleanup:YES];
		weapon = nil;
	}
	
	/*
	if (_sid == -1) {
		if (_aid>=1&&_aid<=6) {
			weapon = getHostWeaponImage(_aid, 1);
		}else{
			weapon = getWeaponImage(_aid);
		}		
	} else {
		weapon = getHostWeaponImage(_aid, _sid);
	}
	*/
	
	weapon = [WeaponViewerContent create:_aid type:_sid];
	
	if(weapon){
		weapon.anchorPoint = ccp(0.5f,1);
        if (iPhoneRuningOnGame()) {
            weapon.position = ccp(POS_WEAPON_X +70, +POS_WEAPON_ADD_Y +25);
        }else{
		weapon.position = ccp(POS_WEAPON_X,+POS_WEAPON_ADD_Y);
		}
		[self addChild:weapon z:1];
	}
	
	//fix chao 加入动画
	id move1 = [CCMoveTo actionWithDuration:1.5f position:weapon.position];
	id move2 = [CCMoveTo actionWithDuration:1.5f position:ccpAdd(weapon.position, POS_MOVE2)];
	[weapon runAction:[CCRepeatForever actionWithAction:[CCSequence actions:move2,move1,nil]]];
	
	//end
}
-(void)updateTrain
{
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player) {
		int _value = [[player objectForKey:@"train"] intValue];
		[self updateTrain:_value];
	}
	else {
		CCLOG(@"updateTrain player is null");
	}
}
-(void)updateTrain:(int)_train
{
	if (trainInfo) {
		//NSString *str = [NSString stringWithFormat:@"炼历 %d",_train];
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"weapon_train",nil),_train];
		trainInfo.string = str;
	}
	else {
		//NSString *str = [NSString stringWithFormat:@"炼历 %d",_train];
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"weapon_train",nil),_train]; 
		trainInfo = [CCLabelTTF labelWithString:str fontName:getCommonFontName(FONT_1) fontSize:22];
		trainInfo.color = ccc3(235, 180, 70);
		trainInfo.anchorPoint=ccp(0, 1.0f);
		[trainInfo setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[trainInfo setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:trainInfo z:4];
		if (iPhoneRuningOnGame()) {
            trainInfo.position=ccp(142/2 + 50, 492/2 + 35);
            trainInfo.scale = 0.5;
        }else{
            trainInfo.position=ccp(142, 492);
		}
        
	}
}
-(void)closeWindow
{
	[super closeWindow];
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_Weapon_Step_1];
}
#pragma mark net
-(void)armUpgrade:(int)urid
{
	if (urid == 0) {
		CCLOG(@"arg is 0");
		return ;
	}
	NSString * str = [NSString stringWithFormat:@"rid::%d",urid];

	
	//fix chao
	[GameConnection request:@"armUpgrade" format:str target:self call:@selector(didArmUpgrade:)];
	//end
}
-(void)didArmUpgrade:(NSDictionary*)sender
{
	if(checkResponseStatus(sender)){
		CCLOG(@"didArmUpgrade is OK");
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			int _id = [[dict objectForKey:@"rid"] intValue];
			int _level = [[dict objectForKey:@"armLevel"] intValue];
			int _train = [[dict objectForKey:@"train"] intValue];
			[[GameConfigure shared] updatePlayerTrain:_train];
			[[GameConfigure shared] updateArmLevel:_id level:_level];
			if (_level == RUNE_ACTIVE_1) {
				//TODO
				//激活技能
				[[GameConfigure shared] activePlayerRoleSkillWithType:_id type:1];
			}
			[self updateTrain];//改历练
			[self updatePanel:id_select];
			
			//fix chao
			CGPoint pos;
			if (iPhoneRuningOnGame()) {
				pos= ccp(POS_POS_X+65, self.contentSize.height/2+POS_POS_ADD_Y+20);
			}else{
				pos= ccp(POS_POS_X, self.contentSize.height/2+POS_POS_ADD_Y);
			}
            [ClickAnimation showInLayer:self z:99 tag:909 call:nil point:pos path:@"images/animations/uiupsucces/" loop:NO];
			[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos path:@"images/ui/panel/weapon_ok.png" loop:NO];
			[[Intro share] removeCurrenTipsAndNextStep:INTRO_Weapon_Step_1];
		}
	}else{
		//[ShowItem showItemAct:@"升阶失败"];
        [ShowItem showItemAct:NSLocalizedString(@"weapon_upgrade_fail",nil)];
	}
	CCMenuItem *item_obj = (CCMenuItem *)[menu getChildByTag:BT_ARM_UPGRADE_TAG];
	item_obj.isEnabled = YES;
}
-(void)armDegrade:(int)urid type:(int)_type
{
	if (urid == 0) {
		CCLOG(@"arg is 0");
		return ;
	}
	if (_type == 2 || _type == 1) {
		NSString * str = [NSString stringWithFormat:@"rid::%d|type::%d",urid,_type];
		[GameConnection request:@"skillBack" format:str target:self call:@selector(didArmDegrade:)];
	}
	else {
		CCLOG(@"_type is error!");
	}
}
-(void)didArmDegrade:(NSDictionary*)sender
{
	if(checkResponseStatus(sender)){
		CCLOG(@"didArmUpgrade is OK");
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			int _id = [[dict objectForKey:@"rid"] intValue];
			[[GameConfigure shared] updateArmLevel:_id level:0];
			[[GameConfigure shared] activePlayerRoleSkillWithType:_id type:0];//取消激活技能
			
			[[GameConfigure shared] updatePackage:dict];
			
			[self updatePanel:id_select];
			[self updateTrain];//改炼历
		}
	}else{
		//
        [ShowItem showErrorAct:getResponseMessage(sender)];
	}
}
-(void)armSkill:(int)_urid skill:(int)_sk
{
	if (_urid == 0 || _sk == 0) {
		CCLOG(@"_ueid == 0 || _sk == 0");
		return ;
	}
	NSString * str = [NSString stringWithFormat:@"rid::%d|sid::%d",_urid,_sk];
	[GameConnection request:@"armSkill" format:str target:self call:@selector(didArmSkill:)];
}
-(void)didArmSkill:(NSDictionary*)sender
{
	if(checkResponseStatus(sender)){
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			CCLOG([dict description]);
			int _id = [[dict objectForKey:@"rid"] intValue];
			int _sk = [[dict objectForKey:@"sid"] intValue];
			[[GameConfigure shared] activePlayerRoleSkillWithId:_id sid:_sk];
			[self updatePanel:id_select];
			//fix chao
			if (_sk>0) {
				NSDictionary *db_skill = [[GameDB shared] getSkillInfo:_sk];//符印
				if(db_skill && [db_skill objectForKey:@"name"]){
                    CGPoint pos = CGPointZero;
                    if (iPhoneRuningOnGame()) {
                        pos = ccp(POS_POS_X + 71, self.contentSize.height/2+POS_POS_ADD_Y + 20);
                    }else{
                        pos = ccp(POS_POS_X, self.contentSize.height/2+POS_POS_ADD_Y);
					}
					//CCSprite* spr = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@ 激活",[db_skill objectForKey:@"name"]] fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
                    CCSprite* spr = [CCLabelTTF labelWithString:[NSString stringWithFormat:NSLocalizedString(@"weapon_activation_skill_2",nil),[db_skill objectForKey:@"name"]] fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
					[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
                    if (iPhoneRuningOnGame()) {
                        spr.scale = 0.5;
                    }
				}else{
					CCLOG(@"skill info is error");
				}
			}else{
				CCLOG(@"skill id is error");
			}
			//end
		}
	}else{
		//TODO
	}
}
#pragma mark --
@end