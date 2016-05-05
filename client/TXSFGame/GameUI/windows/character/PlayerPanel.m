//
//  PlayerPanel.m
//  TXSFGame
//
//  Created by Soul on 13-1-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "PlayerPanel.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "ButtonGroup.h"
#import "Window.h"
#import "PlayerDataHelper.h"
#import "GameConfigure.h"
#import "CCNode+AddHelper.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "AlertManager.h"
#import "ItemManager.h"
#import "ItemSizer.h"
#import "ItemTray.h"
#import "EquipmentTray.h"
#import "ItemDescribetion.h"
#import "GameConnection.h"
#import "InfoAlert.h"

#import "RoleImageViewerContent.h"
#import "WeaponPanel.h"
#import "GuanXing.h"
#import "MemberSizer.h"
#import "RoleCultivate.h"
#import "RoleUp.h"

#if Window_debug == 1
#import "WindowComponent.h"
#endif

#define PLAYERPANEL_TOUCH_1		-150
#define PLAYERPANEL_TOUCH_2		-151
#define PLAYERPANEL_TOUCH_3		-152

//#define FUNC_NOT_OPEN							@"该功能尚未解锁...."
#define FUNC_NOT_OPEN	NSLocalizedString(@"player_no_open",nil)
#define LABEL_TAG				900
#define EQUIP_TAG				8000


//#if TARGET_IPHONE
//
//#define UI_OFFSET_HEIGHT		68/2
//#define UI_CHARACTER_STARTX		127/2
//#define UI_PACKAGE_OFFSETX		25/2
//#define UI_FUNCTION_MESSAGE		61/2
//
//
//#define POS_Foundation_close_bt_offsetX			44/2
//#define POS_Foundation_close_bt_offsetY			42/2
//#define POS_Foundation_fallout_bt_offsetX		216/2
//#define POS_Foundation_fallout_bt_offsetY		50/2
//#define POS_PackageBackground_offsetX			25/2
//#define POS_FunctionBnts_bt_arm_x				230/2
//#define POS_FunctionBnts_bt_arm_y				480/2
//#define POS_FunctionBnts_bt_start_x				455/2
//#define POS_FunctionBnts_bt_start_y				480/2
//#define POS_RoleTabs_offsetX					78/2
//#define POS_RoleImage_offsetX					216/2
//#define POS_RoleImage_offsetY					135/2
//#define POS_ItemSizer_posX						840/2
//#define POS_ItemSizer_posY						500/2
//#define POS_ItemMgr_posX						567/2
//#define POS_ItemMgr_posY						80/2
//#define POS_Functions_bt_left_offsetX			210/2
//#define POS_Functions_bt_left_offsetY			50/2
//#define POS_Functions_bt_right_offsetX			70/2
//#define POS_Functions_bt_right_offsetY			50/2
//
//#define POS_Package_Amount_startX				570/2
//#define POS_Package_Amount_startY				500/2
//
//#define POS_ShowAttribute_startX				230/2
//#define POS_ShowAttribute_startY				140/2
//#define POS_ShowAttribute_endX					450/2
//#define POS_ShowAttribute_endY					420/2
//
//#define POS_EquipmentPart_LEFT_X        180/2
//#define POS_EquipmentPar_RIGHT_X        505/2
//#define POS_EquipmentPart_HIGH_Y        380/2
//#define POS_EquipmentPart_MIDDLE_Y      283/2
//#define POS_EquipmentPart_SMALL_Y       185/2
//
//#define POS_LABEL_LEFT_X   185/2
//#define POS_LABEL_MIDDLE_X 320/2
//#define POS_LABEL_RIGHT_X  455/2
//#define POS_LABEL_HIGH_Y   110/2
//#define POS_LABEL_SMALL_Y  90/2
//
//#define POS_Title_x   75/2
//#define POS__Sprite_x  185/2
//#define CGS__itemMgr   CGSizeMake(276/2, 368/2)
//#define POS_pt_add_x 50/2
//#define VALUE__msgMgr_width 30/2
//#define POS__msgMgr  ccp(10/2,10/2)
//#define POS_TITLE_ADD_Y   10/2
//
//#else

#define UI_OFFSET_HEIGHT		cFixedScale(66)
#define UI_CHARACTER_STARTX		cFixedScale(127)
#define UI_PACKAGE_OFFSETX		cFixedScale(25)
#define UI_FUNCTION_MESSAGE		cFixedScale(61)

#define POS_Foundation_close_bt_offsetX			cFixedScale(44)
#define POS_Foundation_close_bt_offsetY			cFixedScale(42)
#define POS_Foundation_fallout_bt_offsetX		cFixedScale(216)
#define POS_Foundation_fallout_bt_offsetY		cFixedScale(50)
#define POS_PackageBackground_offsetX			cFixedScale(25)
#define POS_FunctionBnts_bt_arm_x				cFixedScale(230)
#define POS_FunctionBnts_bt_arm_y				cFixedScale(480)
#define POS_FunctionBnts_bt_start_x				cFixedScale(455)
#define POS_FunctionBnts_bt_start_y				cFixedScale(480)
#define POS_RoleTabs_offsetX					cFixedScale(100)
#define POS_RoleImage_offsetX					cFixedScale(216)
#define POS_RoleImage_offsetY					cFixedScale(135)
#define POS_ItemSizer_posX						cFixedScale(840)
#define POS_ItemSizer_posY						cFixedScale(500)
#define POS_ItemMgr_posX						cFixedScale(567)
#define POS_ItemMgr_posY						cFixedScale(80)
#define POS_Functions_bt_left_offsetX			cFixedScale(210)
#define POS_Functions_bt_left_offsetY			cFixedScale(50)
#define POS_Functions_bt_right_offsetX			cFixedScale(70)
#define POS_Functions_bt_right_offsetY			cFixedScale(50)

#define POS_Package_Amount_startX				cFixedScale(570)
#define POS_Package_Amount_startY				cFixedScale(500)

#define POS_ShowAttribute_startX				cFixedScale(230)
#define POS_ShowAttribute_startY				cFixedScale(140)
#define POS_ShowAttribute_endX					cFixedScale(450)
#define POS_ShowAttribute_endY					cFixedScale(420)



#define POS_EquipmentPart_LEFT_X        cFixedScale(180)
#define POS_EquipmentPar_RIGHT_X        cFixedScale(505)
#define POS_EquipmentPart_HIGH_Y        cFixedScale(380)
#define POS_EquipmentPart_MIDDLE_Y      cFixedScale(283)
#define POS_EquipmentPart_SMALL_Y       cFixedScale(185)

#define ItemManager_size						CGSizeMake(cFixedScale(276), cFixedScale(368))


#define POS_LABEL_LEFT_X   cFixedScale(185)
#define POS_LABEL_MIDDLE_X cFixedScale(320)
#define POS_LABEL_RIGHT_X  cFixedScale(455)
#define POS_LABEL_HIGH_Y   cFixedScale(110)
#define POS_LABEL_SMALL_Y  cFixedScale(90)

#define POS_Title_x   cFixedScale(75)
#define POS__Sprite_x  cFixedScale(185)
#define CGS__itemMgr   CGSizeMake(cFixedScale(276), cFixedScale(368))
#define POS_pt_add_x cFixedScale(50)
#define VALUE__msgMgr_width cFixedScale(30)
#define POS__msgMgr  ccp(10,15)
#define POS_TITLE_ADD_Y   cFixedScale(10)
//#endif



typedef enum{
	Image_bg = 1 ,
	Image_bg_package = 2 ,
	Image_bg_character = 3 ,
}UserImage_type;

static inline NSString* getUserSprite(UserImage_type type){
	if (type == Image_bg)       {
        if (iPhoneRuningOnGame()) {
        return @"images/ui/wback/fun_bg.jpg";
    }else
        return @"images/ui/panel/character_panel/bg.png";
    }
	if (type == Image_bg_package) return @"images/ui/panel/character_panel/bg-package.png";
	if (type == Image_bg_character) return @"images/ui/panel/character_panel/bg-character.png";
	return nil;
}
static inline CGPoint getPartPosition(EquipmentPart _part){
    if (iPhoneRuningOnGame()) {
        if (_part == EquipmentPart_head)		        return ccpIphone(ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_HIGH_Y + 25));
        if (_part == EquipmentPart_body)		    return ccpIphone(ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_MIDDLE_Y + 25));
        if (_part == EquipmentPart_foot)		    return ccpIphone(ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_SMALL_Y + 25));
        if (_part == EquipmentPart_necklace)	    return ccpIphone(ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_HIGH_Y + 25));
        if (_part == EquipmentPart_sash)		    return ccpIphone(ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_MIDDLE_Y + 25));
        if (_part == EquipmentPart_ring)		    return ccpIphone(ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_SMALL_Y + 25));
    }else{
	if (_part == EquipmentPart_head)		        return ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_HIGH_Y);
	if (_part == EquipmentPart_body)		    return ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_MIDDLE_Y);
	if (_part == EquipmentPart_foot)		    return ccp(POS_EquipmentPart_LEFT_X ,POS_EquipmentPart_SMALL_Y);
	if (_part == EquipmentPart_necklace)	    return ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_HIGH_Y);
	if (_part == EquipmentPart_sash)		    return ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_MIDDLE_Y);
	if (_part == EquipmentPart_ring)		    return ccp(POS_EquipmentPar_RIGHT_X ,POS_EquipmentPart_SMALL_Y);
	}
	return CGPointZero;
}
static inline CGPoint getLabelPosition(int _part){
	if (iPhoneRuningOnGame()) {
        if (_part == 0)		return ccpIphone(ccp(POS_LABEL_LEFT_X + 8, POS_LABEL_HIGH_Y + 11));
        if (_part == 1)		return ccpIphone(ccp(POS_LABEL_MIDDLE_X + 12, POS_LABEL_HIGH_Y+ 11));
        if (_part == 2)		return ccpIphone(ccp(POS_LABEL_RIGHT_X + 14, POS_LABEL_HIGH_Y+ 11));
        if (_part == 3)		return ccpIphone(ccp(POS_LABEL_LEFT_X  + 8, POS_LABEL_SMALL_Y+ 11));
        if (_part == 4)		return ccpIphone(ccp(POS_LABEL_MIDDLE_X + 12, POS_LABEL_SMALL_Y+ 11));
        if (_part == 5)		return ccpIphone(ccp(POS_LABEL_RIGHT_X + 14, POS_LABEL_SMALL_Y+ 11));

    }else{
	if (_part == 0)		return ccp(POS_LABEL_LEFT_X , POS_LABEL_HIGH_Y);
	if (_part == 1)		return ccp(POS_LABEL_MIDDLE_X , POS_LABEL_HIGH_Y);
	if (_part == 2)		return ccp(POS_LABEL_RIGHT_X , POS_LABEL_HIGH_Y);
	if (_part == 3)		return ccp(POS_LABEL_LEFT_X  , POS_LABEL_SMALL_Y);
	if (_part == 4)		return ccp(POS_LABEL_MIDDLE_X , POS_LABEL_SMALL_Y);
	if (_part == 5)		return ccp(POS_LABEL_RIGHT_X , POS_LABEL_SMALL_Y);
	}
	return CGPointZero;
}
static inline NSArray* getRoleTab(int rid){
	
	if (rid <= 0) {
		CCLOG(@"PlayerPanel->getRoleTab:%d",rid);
		return nil;
	}
	CCSprite* bg1;
	CCSprite* bg2;
	CCSprite* i1  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	CCSprite* i2  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	bg1 = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
	bg2 = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
	if (iPhoneRuningOnGame()) {
		[bg1 addChild:i1];
		[bg2 addChild:i2];
		i2.position=ccp(bg2.contentSize.width- bg2.contentSize.width/2.0f+0.75f,bg2.contentSize.height/2.0f);
		i1.position=i2.position;
	}else{
		[bg1 Category_AddChildToCenter:i1];
		[bg2 Category_AddChildToCenter:i2];
	}
	
	NSArray* array = [NSArray arrayWithObjects:bg1,bg2,nil];
	
	return array;
}

#pragma mark PowerSprite
@implementation PowerSprite

-(void)onEnter{
	[super onEnter];
	
	CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/power-bg.png"];
	self.contentSize = background.contentSize;
	[self Category_AddChildToCenter:background];
	
	CCSprite *title = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/power-title.png"];
	[self addChild:title];
	title.anchorPoint = ccp(0, 0.5);
	title.position=ccp(POS_Title_x, self.contentSize.height/2);
	
	[GameConnection addPost:PlayerDataHelper_Event_Update_Power 
					 target:self 
					   call:@selector(updatePower)];
}

-(void)onExit{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)updatePower{
	
	[self updatePower:[[PlayerDataHelper shared] getTotalPower]];
	
}

-(void)updatePower:(int)_power{
	CCLOG(@"PowerSprite->updatePower");
	[self removeChildByTag:676 cleanup:YES];
	
	NSString* path = [NSString stringWithFormat:@"images/ui/num/num-2.png"];
	CCSprite* ___sprite = getImageNumber(path, 15, 25, _power);
	___sprite.anchorPoint=ccp(0, 0.5);
	
	[self addChild:___sprite z:2 tag:676];
	
	___sprite.position=ccp(POS__Sprite_x, self.contentSize.height/3);
	
}

@end

#pragma mark FunctionButton
@implementation FunctionButton

@synthesize func = _func;

+(FunctionButton*)makeWeapon{
	FunctionButton *bts = [FunctionButton node];
	bts.func = 1 ;
	return bts;
}

+(FunctionButton*)makeFate{
	FunctionButton *bts = [FunctionButton node];
	bts.func = 2 ;
	return bts;
}

-(id)init{
	if (self = [super init]) {
		priority = -100;
		touchScale = 1.1;
		
		CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/t30.png"];
		self.contentSize = background.contentSize;
		[self addChild:background z:1];
		background.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
		
	}
	return self;
}

-(void)dealloc{
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	
	NSString* path = nil ;
	if (_func == 1) path = [NSString stringWithFormat:@"images/ui/panel/icon_weapon.png"];
	if (_func == 2)	path = [NSString stringWithFormat:@"images/ui/panel/icon_guanxing.png"];
	
	CCSprite* __sprite = [CCSprite spriteWithFile:path];
	if (__sprite != nil) {
		[self addChild:__sprite z:2];
		__sprite.position = ccp(__sprite.contentSize.width/2, self.contentSize.height/2);
	}
}

-(void)onExit{
	
	[super onExit];
}

-(void)setInfo:(NSString *)message{
	if (message == nil ) return ;
	
	CCLabelTTF* label = (CCLabelTTF*)[self getChildByTag:3100];
	if (label == nil) {
		label = [CCLabelTTF labelWithString:@""
								   fontName:getCommonFontName(FONT_1)
								   fontSize:16];
		label.color = ccc3(220, 220, 220);
		label.anchorPoint = ccp(0, 0.5);
		label.tag = 3100 ;
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:label z:3];
		label.position=ccp(UI_FUNCTION_MESSAGE, self.contentSize.height/2);
        if (iPhoneRuningOnGame()) {
            label.scale  = 0.5;
        }
	}
	
	label.string=message;
	
}
@end

static int s_rid = 0 ;

#pragma mark PlayerPanel

static PlayerPanel* s_PlayerPanel = nil ;

@implementation PlayerPanel
@synthesize roleId = _roleId ;

+(void)setShowRole:(int)_rid{
	if (s_rid < 0) {
		s_rid = 0 ;
	}
	s_rid = _rid ;
}

+(PlayerPanel*)shared{
	return s_PlayerPanel;
}

-(id)init{
	if (self=[super init]) {
		//开始检测数据
		[PlayerDataHelper start];
	}
	
//	[self setTouchEnabled:YES];
	s_PlayerPanel = self ;
	return self;
}

-(void)dealloc{
	CCLOG(@"PlayerPanel->dealloc");
	s_PlayerPanel = nil ;
	s_rid = 0 ;
	
	[self unschedule:@selector(checkLoad:)];
	
	[super dealloc];
}

-(void)checkLoad:(ccTime)_time{
	CCLOG(@"PlayerPanel->checkLoad");
	if ([PlayerDataHelper shared].isReady) {
		[self unschedule:@selector(checkLoad:)];
		[self start];
	}
}

-(void)onExit{
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[GameConnection removePostTarget:self];
    [GameConnection freeRequest:self];
	
	//发送战力
	//[[PlayerDataHelper shared] postBattlePower];
	
	[PlayerDataHelper stopAll];
	
	[[RoleManager shared].player updateSuit];
	
	[super onExit];
	CCLOG(@"PlayerPanel->onExit");
}

-(void)onEnter{
	[super onEnter];
	CCLOG(@"PlayerPanel->onEnter");
	
#if Window_debug == 1
	isSend = NO;
    isButtonTouch = NO;
    //
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-180 swallowsTouches:NO];
	
	
	[GameConnection addPost:ConnPost_request_showInfo target:self call:@selector(requestShowItemTrayDescribe:)];
	[GameConnection addPost:PlayerDataHelper_Event_Update_Power target:self call:@selector(updaterRoleMessage)];
	
	[self showFoundation];
	
	[self schedule:@selector(checkLoad:)];
	
#else
	isSend = NO;
    isButtonTouch = NO;
    //
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-180 swallowsTouches:NO];
	
	[GameConnection addPost:PlayerDataHelper_Event_Update_Power target:self call:@selector(updaterRoleMessage)];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	self.position = ccp(size.width/2,size.height/2);
	
	[self showFoundation];
	
	[self schedule:@selector(checkLoad:)];
	
#endif
	
    
}

-(void)setButtonEnabled:(BOOL)enabled{
    isButtonTouch = enabled;
    if (_memberSizer) {
        if (isButtonTouch) {
            _memberSizer.touchEnabled = NO;
        }else{
            _memberSizer.touchEnabled = YES;
        }
    }
}
-(void)doSynthesize:(CCSimpleButton*)_sender{
    //test
    /*
    if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->role_cultivate->isReady");
        [[Window shared] showWindow:PANEL_ROLE_UP];
        
//        RoleCultivate *node = [RoleCultivate node];
//        node.roleID = _roleId;
//        [self.parent addChild:node z:999];
//        node.position = self.position;
        
        return;
	}
*/
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	//TODO 跳去合成
	if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->doSynthesize->isReady");
		[[Window shared] showWindow:PANEL_ITEMSYNTHESIZE];
	}else{
        [self setButtonEnabled:NO];
    }
    //[self setButtonEnabled:NO];
}
-(void)doBatchSell:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	[[PlayerDataHelper shared] cleanupBatchData];//先清除数据
	
	if (_itemMgr != nil) {
		[_itemMgr openMarketModel:YES];
	}
	[self showFunctions_2];
    [self setButtonEnabled:NO];
}

-(void)doCanelBatchModel:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	[[PlayerDataHelper shared] cleanupBatchData];//先清除数据
	
	if (_itemMgr != nil) {
		[_itemMgr openMarketModel:NO];
	}
	[self showFunctions_1];
    [self setButtonEnabled:NO];
}

-(void)doConfirmBatchModel:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	int _result = [[PlayerDataHelper shared] checkBatchSell] ;
	if ( _result > 0) {
		//NSString* msg = [NSString stringWithFormat:@"确认出售选中的 %d 件物品！",_result];
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"player_select_sure",nil),_result];
		[[AlertManager shared] showMessage:msg
									target:self
								   confirm:@selector(batckSellItems)
									 canel:@selector(doCanelBatchs)];
	}else{
		//NSString* msg = [NSString stringWithFormat:@"请选择需要出售的物品！"];
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"player_select",nil)];
		[[AlertManager shared] showMessage:msg
									target:self
                                   confirm:@selector(doCanelBatchs)
									 canel:@selector(doCanelBatchs)];
        //[self setButtonEnabled:NO];
	}
    //[self setButtonEnabled:NO];
}

-(void)doCanelBatchs{
	[[PlayerDataHelper shared] cleanupBatchData];
	if (_itemMgr != nil) {
		[_itemMgr freeSelect];
	}
    [self setButtonEnabled:NO];
}

-(void)doFallOut:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	CCLOG(@"PlayerPanel->doFallOut");
	if ([PlayerDataHelper shared].isReady) {
		CCLOG(@"PlayerPanel->doFallOut->isReady");
		[self memberForLeave];
	}
    [self setButtonEnabled:NO];
}

#if Window_debug == 1
-(void)closeWindow{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	CCLOG(@"PlayerPanel->doExitPanel");
	if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->doExitPanel->isReady");
		[[Window shared] removeWindow:PANEL_CHARACTER];
	}else{
        [self setButtonEnabled:NO];
    }
}
#endif

-(void)doExitPanel:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	CCLOG(@"PlayerPanel->doExitPanel");
	if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->doExitPanel->isReady");
		[[Window shared] removeWindow:PANEL_CHARACTER];
	}
}
-(void)doFunctionWeapon:(FunctionButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	CCLOG(@"PlayerPanel->doFunctionWeapon");
	if ([PlayerDataHelper shared].isReady) {
		//TODO
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_weapon]) {
            //fix chao
            [Weapon setRoleID:_roleId];
            //end
			[[Window shared] showWindow:PANEL_WEAPON];
		}else{
			[[AlertManager shared]showMessage:FUNC_NOT_OPEN
									   target:self
									  confirm:nil
										canel:nil
									   father:self];
            [self setButtonEnabled:NO];
		}
	}
    //[self setButtonEnabled:NO];
}

-(void)doFunctionFate:(FunctionButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	CCLOG(@"PlayerPanel->doFunctionFate");
	if ([PlayerDataHelper shared].isReady) {
		//TODO
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_star]) {
            //fix chao
            [GuanXing setRoleID:_roleId];
            //end
			[[Window shared] showWindow:PANEL_FATE];
		}else{
			[[AlertManager shared]showMessage:FUNC_NOT_OPEN
									   target:self
									  confirm:nil
										canel:nil
									   father:self];
            [self setButtonEnabled:NO];
		}
	}
    //[self setButtonEnabled:NO];
}
-(void)start{
	[self showRoleTabs];
}

-(void)showFoundation{
	CCLOG(@"PlayerPanel->draw some common image!!");
	
#if Window_debug != 1
	CCSprite *background = [CCSprite spriteWithFile:getUserSprite(Image_bg)];
	
	if (background != nil) {
		self.contentSize = background.contentSize;
	}
	
//	background.position = background.anchorPoint = CGPointZero;
    background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	[self addChild:background z:0];

	CCSprite *title = [CCSprite spriteWithFile:@"images/ui/panel/t8.png"];
    if (iPhoneRuningOnGame()) {
        title.position = ccp(self.contentSize.width/2,self.contentSize.height-18);
        title.scale = 1.19f;
    }else{
        title.position = ccp(self.contentSize.width/2,self.contentSize.height-POS_TITLE_ADD_Y);
	}
	[self addChild:title z:10];
	
	CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"
												  select:nil
												  target:self
													call:@selector(doExitPanel:)
												priority:PLAYERPANEL_TOUCH_1];
	if (iPhoneRuningOnGame()) {
		bnt.scale = 1.19f;
		bnt.position =ccp(self.contentSize.width - bnt.contentSize.width/2  - ccpIphone4X(0)-2.0f, self.contentSize.height-bnt.contentSize.height/2-2.5f );
    }else{
        bnt.position=ccp(self.contentSize.width - POS_Foundation_close_bt_offsetX,
                         self.contentSize.height - POS_Foundation_close_bt_offsetY);
	}
	[self addChild:bnt z:10];
	
	
	// 规则
    //fix chao
	RuleButton *ruleButton = [RuleButton node];
   	if (iPhoneRuningOnGame()) {
		ruleButton.scale = 1.19f;
		ruleButton.position = ccp(bnt.position.x- cFixedScale(WINDOW_RULE_OFF_X * ruleButton.scale), bnt.position.y-cFixedScale(WINDOW_RULE_OFF_Y));
	}else{
		ruleButton.position = ccp(bnt.position.x- cFixedScale(WINDOW_RULE_OFF_X), bnt.position.y-cFixedScale(WINDOW_RULE_OFF_Y));
		
	}
	ruleButton.type = RuleType_roleSystem;
	ruleButton.priority = -129;
	[self addChild:ruleButton z:10];
    //end
	
	
#endif
	
	CCSimpleButton* ltb = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_fallout_1.png"
												  select:@"images/ui/button/bts_fallout_2.png"
												  target:self
													call:@selector(doFallOut:)
												priority:PLAYERPANEL_TOUCH_1];
    if (iPhoneRuningOnGame()) {
        ltb.position = ccpIphone(ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX + 5,
                                     POS_Foundation_fallout_bt_offsetY + 10));
        ltb.scale = 1.3f;
    }else{
        ltb.position = ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX,
                           POS_Foundation_fallout_bt_offsetY);
	}
	[self addChild:ltb z:10 tag:990];
	ltb.visible = NO ;

	PowerSprite* pSprite = [PowerSprite node];
	[self addChild:pSprite z:10 tag:991];
    if (iPhoneRuningOnGame()) {
        pSprite.position = ccpIphone(ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX ,
                               POS_Foundation_fallout_bt_offsetY + 10));
    }else{
	pSprite.position = ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX,
						   POS_Foundation_fallout_bt_offsetY);
	}
	pSprite.visible = NO;

	
	_msgMgr = [MessageBox create:POS__msgMgr color:ccc4(128, 128, 128, 200)];
	_msgMgr.visible = NO;
	_msgMgr.AdjustWidth = VALUE__msgMgr_width;
	[self addChild:_msgMgr z:INT16_MAX];
    if (iPhoneRuningOnGame()) {
        _msgMgr.scale =  0.5;
    }
    //升华 培养
    [self showRoleUpButton];
    // 右边背包
	[self showPackageBackground];
	
    //中间人物
	[self showCharacterBackground];
    // 中间2个宝具观星功能
	[self showFunctionBnts];
	[self showFunctions_1];
	[self showEquipmentTabs];
	[self showLabels];
	[self showPackage];
	
	_rDescribetion = [RoleDescribetion showDescribetion];
    
	if (iPhoneRuningOnGame()) {
		_rDescribetion.position = ccp(self.contentSize.width-5, 27/2.0f);
	}else{
		_rDescribetion.position = ccp(self.contentSize.width, 0);
	}
	[self addChild:_rDescribetion z:INT32_MAX];

	[_rDescribetion doExit];
    
}
//左边角色背景
-(void)showCharacterBackground{
	CCSprite *bg_character = [CCSprite spriteWithFile:getUserSprite(Image_bg_character)];
	bg_character.anchorPoint=ccp(0, 1.0);
    if (iPhoneRuningOnGame()) {
        bg_character.position=ccpIphone(ccp(UI_CHARACTER_STARTX, self.contentSize.height-UI_OFFSET_HEIGHT + 4));
        bg_character.scale = 550/bg_character.contentSize.height/2;
    }else{
        bg_character.position=ccp(UI_CHARACTER_STARTX, self.contentSize.height-UI_OFFSET_HEIGHT);
	}
	[self addChild:bg_character z:1];
}
//右边背包背景
-(void)showPackageBackground{
	CCSprite *bg_package = [CCSprite spriteWithFile:getUserSprite(Image_bg_package)];
	bg_package.anchorPoint=ccp(1.0, 1.0);
    if (iPhoneRuningOnGame()) {
		bg_package.position=ccpIphone(ccp(868/2 + 44,self.contentSize.height - UI_OFFSET_HEIGHT + 4));
		bg_package.scale = 550/bg_package.contentSize.height/2;
		bg_package.scaleX = 1.23f;
    }else{
		bg_package.position=ccp(848,self.contentSize.height - UI_OFFSET_HEIGHT);
	}
	[self addChild:bg_package z:1];
}

-(void)showFunctionBnts{
	FunctionButton* bnt1 = [FunctionButton makeWeapon];
	FunctionButton* bnt2 = [FunctionButton makeFate];
	[self addChild:bnt1 z:11];
	[self addChild:bnt2 z:12];
	
	bnt1.tag = 1988;
	bnt1.target = self ;
	bnt1.call = @selector(doFunctionWeapon:);
	bnt1.position = ccp(POS_FunctionBnts_bt_arm_x, POS_FunctionBnts_bt_arm_y);
	
	bnt2.tag = 1989;
	bnt2.target = self ;
	bnt2.call = @selector(doFunctionFate:);
	bnt2.position = ccp(POS_FunctionBnts_bt_start_x, POS_FunctionBnts_bt_start_y);
    if (iPhoneRuningOnGame()) {
        bnt1.position = ccpIphone(ccp(POS_FunctionBnts_bt_arm_x, POS_FunctionBnts_bt_arm_y + 30));
        bnt2.position = ccpIphone(ccp(POS_FunctionBnts_bt_start_x, POS_FunctionBnts_bt_start_y + 30));
        bnt1.scale = 1.1;
        bnt2.scale = 1.1;
    }
 
}

-(void)showEquipmentTabs{
	//6个部位的对象
	for (int i = EquipmentPart_head; i <= EquipmentPart_ring; i++) {
		EquipmentTray *mEq1 = [EquipmentTray node];
		mEq1.position=getPartPosition(i);
		[self addChild:mEq1 z:10 tag:EQUIP_TAG + i];
		mEq1.part = i;
        if (iPhoneRuningOnGame()) {
            mEq1.scale  = 1.1;
        }
	}
}

-(void)showLabels{
	NSString* _string = [NSString stringWithFormat:@""];
	int  ____tag = LABEL_TAG;
	for (int i = 0; i < 6; i++) {
		float fontSize=16;
		if (iPhoneRuningOnGame()) {
			fontSize=9;
		}
		CCLabelTTF *label = [CCLabelTTF labelWithString:_string
											   fontName:getCommonFontName(FONT_1)
											   fontSize:fontSize];
		label.color = ccc3(204, 125, 14);
		label.anchorPoint = ccp(0, 0);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:label z:5 tag:____tag];
		label.position= getLabelPosition(i);
//		if (iPhoneRuningOnGame()) {
//            label.scale = 0.5;
//        }

		____tag++;
	}
	
}

-(void)showRoleTabs{
	
	if (_memberSizer != nil) {
		[_memberSizer removeFromParentAndCleanup:YES];
		_memberSizer = nil ;
	}
	
	
//	if (_buttons != nil) {
//		[_buttons removeFromParentAndCleanup:YES];
//		_buttons = nil ;
//	}
//	
//	_buttons =[ButtonGroup node];
//
//	[_buttons setTouchPriority:0];
//	[self addChild:_buttons z:2];
	
	NSArray* array = [[PlayerDataHelper shared] getRoleWithStatus:RoleStatus_in];
	
	_memberSizer = [MemberSizer create:array
								target:self
								  call:@selector(doSelectRole:)
						  defaultIndex:s_rid];
	
	[self addChild:_memberSizer z:2];
    
    if (iPhoneRuningOnGame()) {
        CGPoint pt =ccpIphone(ccp(UI_CHARACTER_STARTX, self.contentSize.height-UI_OFFSET_HEIGHT + 3));
		_memberSizer.position = ccpAdd(pt, ccp(_memberSizer.contentSize.width*-1 - 2, _memberSizer.contentSize.height*-1));
    }else{
        _memberSizer.position=ccp(UI_CHARACTER_STARTX - _memberSizer.contentSize.width - cFixedScale(2),
								  self.contentSize.height- UI_OFFSET_HEIGHT - _memberSizer.contentSize.height- cFixedScale(2));
	}
	
	
	
//	if (iPhoneRuningOnGame()) {
//		_memberSizer.position=ccp(POS_RoleTabs_offsetX,POS_ItemMgr_posY);
//	}else{
//		_memberSizer.position=ccp(50,POS_ItemMgr_posY);
//	}
	
//	int num = 0;
//	for (NSNumber *number in array) {
//		NSArray* spr = getRoleTab([number intValue]);
//		/*
//		 //检查 block 嘎时候点解 会 retain!!!?????
//		 
//		 CCMenuItem *_item = [CCMenuItemImage itemWithNormalSprite:[spr objectAtIndex:0]
//		 selectedSprite:[spr objectAtIndex:1]
//		 block:^(id sender) {
//		 CCNode* ___tab = (CCNode*)sender;
//		 //self.roleId = ___tab.tag;
//		 _roleId = ___tab.tag;
//		 CCLOG(@"Select role %d",_roleId);
//		 //[self showCharacter:___tab.tag];
//		 }];*/
//		
//		CCMenuItem *_item = [CCMenuItemImage itemWithNormalSprite:[spr objectAtIndex:0]
//												   selectedSprite:[spr objectAtIndex:1]
//														   target:self
//														 selector:@selector(doSelectRole:)];
//		
//		if (iPhoneRuningOnGame()) {
//			_item.scale=1.1f;
//		}
//		
//		[_buttons addChild:_item];
//		
//		_item.tag = [number intValue];
//		
//		num++;
//		
//		if (num > 7) {
//			//不能多余8人
//			break ;
//		}
//		
//	}
//	
//	if (iPhoneRuningOnGame()) {
//		[_buttons alignItemsVerticallyWithPadding:2.51];
//	}else{
//		[_buttons alignItemsVerticallyWithPadding:4];
//	}
//	[self adjustRoleTabsPosition];
//	
//	//default open player
//	
//	if (s_rid == 0) {
//		if (array.count > 0) {
//			int ___rid = [[array objectAtIndex:0] intValue];
//			CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
//			[self activationTab:___item];
//		}
//	}else{
//		int ___rid = s_rid ;
//		s_rid = 0 ;
//		CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
//		
//		if (___item) {
//			
//			[self activationTab:___item];
//		
//		}else{
//			
//			if (array.count > 0) {
//				int ___rid = [[array objectAtIndex:0] intValue];
//				CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
//				[self activationTab:___item];
//			}
//		
//		}
//	}
	
}

-(void)showPackage{
	
	//显示背包内容
	if (_itemMgr == nil) {
		
		_itemMgr = [ItemManager initWithDimension:CGS__itemMgr];
		_itemMgr.shiftType = ItemTray_armor;
		_itemMgr.shiftTarget = self;
		_itemMgr.shiftCall = @selector(requestShiftWithDictionary:);

		//_itemMgr = [ItemManager initWithDimension:ItemManager_size];

        if (iPhoneRuningOnGame()) {
			_itemMgr.position =  ccp(POS_ItemMgr_posX + 80, POS_ItemMgr_posY + 16);
        }else{
		_itemMgr.position =  ccp(POS_ItemMgr_posX, POS_ItemMgr_posY);
		}
		[self addChild:_itemMgr z:10];
		
	}
	//显示选项框
	if (_sizerMgr == nil) {
		_sizerMgr = [ItemSizer node];
		_sizerMgr.anchorPoint = ccp(1.0, 0.5);
		[self addChild:_sizerMgr z:INT32_MAX];
        if (iPhoneRuningOnGame()) {
			_sizerMgr.position = ccp(POS_ItemSizer_posX + 86, POS_ItemSizer_posY + 20);
        }else{
            _sizerMgr.position = ccp(POS_ItemSizer_posX, POS_ItemSizer_posY);
		}
		_sizerMgr.target = self ;
		_sizerMgr.call = @selector(updatePackage:);
		_sizerMgr.selectIndex = 1 ;
	}
	
}

-(void)doRoleCultivate:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
    if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->role_cultivate->isReady");
        
        RoleCultivate *node = [RoleCultivate node];
        node.roleID = _roleId;
        [self.parent addChild:node z:999];
        node.position = self.position;
    }
    [self setButtonEnabled:NO];
}

-(void)doRoleUp:(CCSimpleButton*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
    if ([PlayerDataHelper shared].isReady && ![PlayerDataHelper shared].isChecking) {
		CCLOG(@"PlayerPanel->role_up->isReady");
        [RoleUp setRoleUpStaticRid:_roleId];
        [[Window shared] showWindow:PANEL_ROLE_UP];
    }else{
        [self setButtonEnabled:NO];
    }
    //[self setButtonEnabled:NO];
}

-(void)showRoleUpButton{
    [self removeChildByTag:1911 cleanup:YES];
	[self removeChildByTag:1912 cleanup:YES];
    int w_ = cFixedScale(170);
	//role cultivate
	CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_role_cultivate_1.png"
												   select:@"images/ui/button/bts_role_cultivate_2.png"
												   target:self
													 call:@selector(doRoleCultivate:)
												 priority:-100];
	[self addChild:bnt1 z:12 tag:1911];
    if (iPhoneRuningOnGame()) {
        bnt1.position = ccpIphone(ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX + 5 - w_,
                                      POS_Foundation_fallout_bt_offsetY + 10));
        bnt1.scale = 1.3f;
    }else{
        bnt1.position = ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX - w_,
                            POS_Foundation_fallout_bt_offsetY);
	}
    
	//role up
	CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_role_up_1.png"
												   select:@"images/ui/button/bts_role_up_2.png"
												   target:self
													 call:@selector(doRoleUp:)
												 priority:-100];
	[self addChild:bnt2 z:12 tag:1912];
    if (iPhoneRuningOnGame()) {
        bnt2.position = ccpIphone(ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX + 5 + w_,
                                     POS_Foundation_fallout_bt_offsetY + 10));
        bnt2.scale = 1.3f;
    }else{
        bnt2.position = ccp(UI_CHARACTER_STARTX + POS_Foundation_fallout_bt_offsetX + w_,
                           POS_Foundation_fallout_bt_offsetY);
	}
	
}
//右下出售
-(void)showFunctions_1{
	
	[self removeChildByTag:911 cleanup:YES];
	[self removeChildByTag:912 cleanup:YES];
	[self removeChildByTag:913 cleanup:YES];
	[self removeChildByTag:914 cleanup:YES];
	[self removeChildByTag:915 cleanup:YES];
	[self removeChildByTag:916 cleanup:YES];
	
	CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_item_synthesize_1.png"
												   select:@"images/ui/button/bt_item_synthesize_2.png"
												   target:self
													 call:@selector(doSynthesize:)
												 priority:-100];
	
	bnt1.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_left_offsetX,
						POS_Functions_bt_left_offsetY);
	[self addChild:bnt1 z:12 tag:911];
	
	CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_bat_sell_1.png"
												   select:@"images/ui/button/bt_bat_sell_2.png"
												   target:self
													 call:@selector(doBatchSell:)
												 priority:-100];
	
	bnt2.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_right_offsetX,
						POS_Functions_bt_right_offsetY);
	[self addChild:bnt2 z:12 tag:912];
    if (iPhoneRuningOnGame()) {
		bnt1.scale = 1.27f;
		bnt2.scale = 1.27f;
		bnt1.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_left_offsetX-60,
							POS_Functions_bt_left_offsetY+10);
		bnt2.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_right_offsetX-42,
							POS_Functions_bt_right_offsetY+10);
    }
	
}

-(void)showFunctions_2{
	[self removeChildByTag:911 cleanup:YES];
	[self removeChildByTag:912 cleanup:YES];
	[self removeChildByTag:913 cleanup:YES];
	[self removeChildByTag:914 cleanup:YES];
	[self removeChildByTag:915 cleanup:YES];
	[self removeChildByTag:916 cleanup:YES];
	
	CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_return_1.png"
												   select:@"images/ui/button/bt_return_2.png"
												   target:self
													 call:@selector(doCanelBatchModel:)
												 priority:-100];
	
	bnt1.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_left_offsetX,
						POS_Functions_bt_left_offsetY);
	[self addChild:bnt1 z:12 tag:913];
	
	CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_sell_select_1.png"
												   select:@"images/ui/button/bt_sell_select_2.png"
												   target:self
													 call:@selector(doConfirmBatchModel:)
												 priority:-100];
	
	bnt2.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_right_offsetX,
						POS_Functions_bt_right_offsetY);
	[self addChild:bnt2 z:12 tag:914];
	
	if (iPhoneRuningOnGame()) {
		bnt1.scale = 1.27f;
		bnt2.scale = 1.27f;
		bnt1.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_left_offsetX-60,
							POS_Functions_bt_left_offsetY+10);
		bnt2.position = ccp(self.contentSize.width - UI_PACKAGE_OFFSETX - POS_Functions_bt_right_offsetX-42,
							POS_Functions_bt_right_offsetY+10);
    }
}

-(void)doSelectRole:(NSNumber*)_sender{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	_roleId = [_sender intValue];
	CCLOG(@"Select role %d",_roleId);
	[self showCharacter:_roleId];
    [self setButtonEnabled:NO];
}

-(void)deleteRoleTab:(int)_rid{
//	if (_rid > 0 && _buttons != nil) {
//		
//		int prid = [[GameConfigure shared] getPlayerRole];
//		
//		if (prid == _rid) return ;
//		
//		[_buttons removeChildByTag:_rid cleanup:YES];
//		[_buttons alignItemsVerticallyWithPadding:4];
//		[self adjustRoleTabsPosition];
//		
//		//恢复第一个指向
//		CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:prid];
//		[self activationTab:___item];
//		
//		
//	}
	if (_rid > 0) {
		if (_memberSizer) {
			[_memberSizer removeMember:_rid];
		}
	}
}

//-(void)activationTab:(CCMenuItem*)_item{
//	if (_buttons == nil ) return ;
//	if (_item == nil ) return ;
//	CCLOG(@"PlayerPanel->activationTab:%d",_item.tag);
//	[_buttons setSelectedItem:_item];
//}

-(void)adjustRoleTabsPosition{
//	if (_buttons != nil) {
//		CGSize size = _buttons.contentSize;
//		CGSize __size = self.contentSize;
//        if (iPhoneRuningOnGame()) {
//			_buttons.position=ccp(POS_RoleTabs_offsetX + 44-3, __size.height - UI_OFFSET_HEIGHT-2  - size.height/2 + 4.5f);
//        }else{
//			_buttons.position=ccp(POS_RoleTabs_offsetX-0.55f, __size.height - UI_OFFSET_HEIGHT-2  - size.height/2-0.5f);
//		}
//	}
}

-(void)showCharacter:(int)_rid{
	
	CCLOG(@"PlayerPanel->showCharacter:%d",_rid);
	//绘制角色面板
	[self updateCharacterImage:_rid];
	[self updateFateFunctions:_rid];
	[self updateWeaponFunctions:_rid];
	[self updateCharacterInfo:_rid];
	[self updateOther:_rid];
	[self updateEquipments:_rid];
	
}

-(void)updateCharacterImage:(int)_rid{
	
	CCLOG(@"PlayerPanel->showCharacterImage:%d",_rid);
	[self removeChildByTag:4005 cleanup:YES];
	
	CCSprite * node = [RoleImageViewerContent create:_rid];
	node.anchorPoint=ccp(0.5, 0);
    if (iPhoneRuningOnGame()) {
       node.position = ccp(UI_CHARACTER_STARTX + POS_RoleImage_offsetX + 44 , POS_RoleImage_offsetY + 20);
    }else{
		node.position = ccp(UI_CHARACTER_STARTX + POS_RoleImage_offsetX, POS_RoleImage_offsetY);
	}
	[self addChild:node z:4 tag:4005];
}

-(void)updateFateFunctions:(int)_rid{
	CCLOG(@"PlayerPanel->updateFateFunctions:%d",_rid);
	int _exp = [[PlayerDataHelper shared] getFateExperience:_rid];
	//NSString* msg = [NSString stringWithFormat:@"星力:%d",_exp];
    NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"player_fate",nil),_exp];
	FunctionButton* fbnts = (FunctionButton*)[self getChildByTag:1989];
	if (fbnts != nil) {
		[fbnts setInfo:msg];
	}
}

-(void)updateWeaponFunctions:(int)_rid{
	CCLOG(@"PlayerPanel->updateWeaponFunctions:%d",_rid);
	NSString *_string = [[PlayerDataHelper shared] getWeaponName:_rid];
	int armLv = [[PlayerDataHelper shared] getWeaponLevel:_rid];
	
	FunctionButton* fbnts = (FunctionButton*)[self getChildByTag:1988];
	if (fbnts != nil) {
		//NSString* msg = [NSString stringWithFormat:@"%@ %d阶",_string,armLv];
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"player_rank",nil),_string,armLv];
		[fbnts setInfo:msg];
	}
}

-(void)updateCharacterInfo:(int)_rid {
	CCLOG(@"PlayerPanel->updateCharacterInfo:%d",_rid);
	
	NSArray* _array = [[PlayerDataHelper shared] getRoleCaption:_rid];
	
	if (_array.count < 6) {
		return ;
	}
	
	for (int i = 0; i < 6; i++) {
		NSString* temp = [_array objectAtIndex:i];
		CCLabelTTF* label = (CCLabelTTF*)[self getChildByTag:LABEL_TAG+i];
		if (label != nil) {
			label.string = temp ;
		}
	}
	
	if (_rDescribetion != nil) {
		NSDictionary* dict = [[PlayerDataHelper shared] getRoleDescribetion:_roleId];
		[_rDescribetion showAttribute:dict];
	}
	
}

-(void)updateOther:(int)_rid {
	CCLOG(@"PlayerPanel->updateOther:%d",_rid);
	CCNode* n1 = [self getChildByTag:990];
	CCNode* n2 = [self getChildByTag:991];
	
	if (_rid < 10) {
		
		PowerSprite* p1 = (PowerSprite*)n2;
		[p1 updatePower:[PlayerDataHelper shared].totalPower];
		
		n1.visible = NO ;
		n2.visible = YES ;
	}else{
		n1.visible = YES ;
		n2.visible = NO ;
	}
	
	//不显示
	if (![[GameConfigure shared] checkPlayerFunction:Unlock_recruit]) {
		n1.visible = NO ;
	}
}

-(void)updaterRoleMessage{
	
	[self updateOther:_roleId];
	[self updateCharacterInfo:_roleId];
	
}


-(void)updateEquipments:(int)_rid{
	
	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
		
		NSDictionary* dict = [[PlayerDataHelper shared] getEquipForRole:_rid part:i-1];
		EquipmentTray* mEq = (EquipmentTray*)[self getChildByTag:EQUIP_TAG + i];
		[mEq updateWithDictionary:_rid dict:dict];
		
	}
}

-(void)updateCharacterLevel{
	CCLOG(@"PlayerPanel->updateCharacterLevel");
}

-(void)updateCharacterPower{
	CCLOG(@"PlayerPanel->updateCharacterPower");
}

-(void)updatePackageAmount{	
	if (_sizerMgr == Nil) return ;
	
	int a1 = [[PlayerDataHelper shared] getTotalPackageAmount];
	int a2 = [[PlayerDataHelper shared] getPackageAmount:_sizerMgr.selectIndex];
	
	CCLOG(@"amount:a1 = %d | a2 = %d",a1,a2);
	
	//NSString* _msg = [NSString stringWithFormat:@"包裹容量:%d/%d",a2,a1];
	NSString* _msg = [NSString stringWithFormat:NSLocalizedString(@"player_capacity",nil),a2,a1];
    
	CCLabelTTF* _label = (CCLabelTTF*)[self getChildByTag:97442832];

	if (_label != nil) {
		_label.string = _msg;
	}else{
		float fontSize=16;
		if (iPhoneRuningOnGame()) {
			fontSize=9;
		}
		_label = [CCLabelTTF labelWithString:_msg
									fontName:@"Verdana-Bold" fontSize:fontSize];
		
		[self addChild: _label z: 10 tag: 97442832];
		_label.anchorPoint = ccp(0, 0.5f);
        if (iPhoneRuningOnGame()) {
			_label.position = ccp(POS_Package_Amount_startX + 70,POS_Package_Amount_startY + 20);						//Kevin modified. before 73
        }else{
		_label.position = ccp(POS_Package_Amount_startX,POS_Package_Amount_startY);
		}
	}
}

-(void)updatePackage:(NSNumber*)_sendr{
    if (isButtonTouch) {
        return;
    }
    [self setButtonEnabled:YES];
	int _value = [_sendr intValue];
	if (_itemMgr != nil) {
		ItemManager_show_type _temp = ItemManager_show_type_all;
		
		if (_value == 1) _temp = ItemManager_show_type_all;
		if (_value == 2) _temp = ItemManager_show_type_equipment;
		if (_value == 3) _temp = ItemManager_show_type_expendable;
		if (_value == 4) _temp = ItemManager_show_type_fate;
		if (_value == 5) _temp = ItemManager_show_type_fodder;
		if (_value == 6) _temp = ItemManager_show_type_jewel;
		
		[_itemMgr updateContainerWithType:_temp];
		[self showFunctions_1];
		
		if (_sizerMgr != nil ) {
			_sizerMgr.target = self ;
			_sizerMgr.call = @selector(updatePackage:);
		}
		
		[self updatePackageAmount];
	}
    [self setButtonEnabled:NO];
}

-(BOOL)isMarkModel{
	if (_itemMgr != nil) {
		return [_itemMgr isMarkModel];
	}
	return NO;
}

-(void)requestShiftWithDescribetion:(NSNumber*)ueid{
	int _ueid = [ueid intValue];
	if (_ueid <= 0) return ;
	
	NSMutableDictionary *rData = [NSMutableDictionary dictionary];
	
	int ____id2 = [[PlayerDataHelper shared] getUserRoleId:_roleId];
	
	[rData setObject:[NSNumber numberWithInt:_ueid] forKey:@"id"];
	[rData setObject:[NSNumber numberWithInt:____id2] forKey:@"rid"];
	
	[self wearEquipment:rData arg:nil];
	
}

-(void)requestShiftWithPart:(int)_part role:(int)_rid action:(NSDictionary *)_act{
	[self requestShiftWithPart:_part action:_act];
}

-(void)requestShiftWithPart:(int)_part action:(NSDictionary*)_act{
	
	EQUIPMENT_ACTION_TYPE temp = [[_act objectForKey:@"action"] intValue];
	
	if (temp == Equipment_action_none) return ;
	CCLOG(@"PlayerPanel->requestShiftWithPart:%d|%d",_part,_act);
	
	
	NSDictionary* dict = [_act objectForKey:@"data"];
	
	if (temp == Equipment_action_swap) {
		NSMutableDictionary *rData = [NSMutableDictionary dictionary];
		
		int ____id1 = [[dict objectForKey:@"id"] intValue];
		int ____id2 = [[PlayerDataHelper shared] getUserRoleId:_roleId];
		
		[rData setObject:[NSNumber numberWithInt:____id1] forKey:@"id"];
		[rData setObject:[NSNumber numberWithInt:____id2] forKey:@"rid"];
		
		[self wearEquipment:rData arg:nil];
		
	}
	
	if (temp == Equipment_action_convert) {
		//转移等级+强化
		NSMutableDictionary *rData = [NSMutableDictionary dictionary];
		
		int ____id1 = [[dict objectForKey:@"id"] intValue];//选中的装备
		int ____id2 = [[PlayerDataHelper shared] getUserRoleId:_roleId];//角色ID
		int ____id3 = [[PlayerDataHelper shared] getEquipIdForRole:_roleId part:_part-1];//身上的装备
		
		[rData setObject:[NSNumber numberWithInt:____id2] forKey:@"rid"];
		[rData setObject:[NSNumber numberWithInt:____id3] forKey:@"eid1"];
		[rData setObject:[NSNumber numberWithInt:____id1] forKey:@"eid2"];
		
		[self equipmentMove:rData];
		
	}
}

-(id)requestShiftWithDictionary:(NSDictionary *)_dict
{
	if (_dict == nil) return [NSNumber numberWithBool:NO];
	
	CGPoint _pt = [[_dict objectForKey:@"point"] CGPointValue];
	CCLOG(@"requestShiftWithDictionary->input:X=%f|Y=%f",_pt.x,_pt.y);
	
	int _ueid = [[_dict objectForKey:@"id"] intValue];
	if (_ueid <= 0) return [NSNumber numberWithBool:NO];
	
	if ([self isMarkModel]) {
		CCLOG(@"error! isMarkModel can't ware equipment");
		return [NSNumber numberWithBool:NO];
	}
	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
		EquipmentTray* mEq = (EquipmentTray*)[self getChildByTag:EQUIP_TAG + i];
		CGPoint pt = [mEq.parent convertToWorldSpace:mEq.position];
		CCLOG(@"requestShiftWithDictionary->target:X=%f|Y=%f",pt.x,pt.y);
		float _dis = ccpDistance(pt, _pt);
		if (_dis <= mEq.contentSize.width/2) {
			CCLOG(@"------------------------------------------");
			CCLOG(@"------------wearEquipment-----------------");
			BOOL canUse = [[PlayerDataHelper shared] checkEquipmentCanKitUp:_ueid];
			if (canUse == NO) {
				[ShowItem showItemAct:NSLocalizedString(@"error_level_reach",nil)];
				return [NSNumber numberWithBool:NO];
			}
			int ____part = [[PlayerDataHelper shared] getEquipmentPart:_ueid];
			if (mEq.part == ____part) {
				NSMutableDictionary *rData = [NSMutableDictionary dictionary];
				
				int ____id2 = [[PlayerDataHelper shared] getUserRoleId:_roleId];
				
				[rData setObject:[NSNumber numberWithInt:_ueid] forKey:@"id"];
				[rData setObject:[NSNumber numberWithInt:____id2] forKey:@"rid"];
				
				[self wearEquipment:rData arg:nil];
				
				return [NSNumber numberWithBool:YES];
			}
			
		}
	}
	
	return [NSNumber numberWithBool:NO];
}

//-(BOOL)requestShiftWithTouch:(CGPoint)_pt ueid:(int)_ueid {
//	CCLOG(@"requestShiftWithTouch->input:X=%f|Y=%f",_pt.x,_pt.y);
//	if (_ueid <= 0	) return NO;
//	if ([self isMarkModel]) {
//		CCLOG(@"error! isMarkModel can't ware equipment");
//		return NO;
//	}
//	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
//		EquipmentTray* mEq = (EquipmentTray*)[self getChildByTag:EQUIP_TAG + i];
//		CGPoint pt = [mEq.parent convertToWorldSpace:mEq.position];
//		CCLOG(@"requestShiftWithTouch->target:X=%f|Y=%f",pt.x,pt.y);
//		float _dis = ccpDistance(pt, _pt);
//		if (_dis <= mEq.contentSize.width/2) {
//			CCLOG(@"------------------------------------------");
//			CCLOG(@"------------wearEquipment-----------------");
//			BOOL canUse = [[PlayerDataHelper shared] checkEquipmentCanKitUp:_ueid];
//			if (canUse == NO) {
//				[ShowItem showItemAct:NSLocalizedString(@"error_level_reach",nil)];
//				return NO;
//			}
//			int ____part = [[PlayerDataHelper shared] getEquipmentPart:_ueid];
//			if (mEq.part == ____part) {
//				NSMutableDictionary *rData = [NSMutableDictionary dictionary];
//				
//				int ____id2 = [[PlayerDataHelper shared] getUserRoleId:_roleId];
//				
//				[rData setObject:[NSNumber numberWithInt:_ueid] forKey:@"id"];
//				[rData setObject:[NSNumber numberWithInt:____id2] forKey:@"rid"];
//				
//				[self wearEquipment:rData arg:nil];
//				
//				return YES;
//			}
//			
//		}
//	}
//	
//	return NO;
//}

-(void)requestShowEquipmentDescribe:(int)_ueid part:(int)_prt{
	if (_ueid <= 0) return ;
	NSString* cmd = [[PlayerDataHelper shared] getEquipDescribe:_ueid role:_roleId];
	if (cmd != nil && _msgMgr != nil) {
		[_msgMgr message:cmd];
		CGPoint pt = getPartPosition(_prt);
		BOOL _isLeft = (_prt < 4) ? YES : NO;
		if (iPhoneRuningOnGame()) {
			if (_isLeft) {
				pt = ccp(pt.x-_msgMgr.contentSize.width/4.0f+60/2.0f,pt.y-_msgMgr.contentSize.height/2);
			}
			else {
				pt = ccp(pt.x-_msgMgr.contentSize.width/4.0f-_msgMgr.contentSize.width/2.0f-60/2.0f,pt.y-_msgMgr.contentSize.height/2);
			}
		}else{
			if (_isLeft) {
				pt = ccpAdd(pt, ccp(POS_pt_add_x, -_msgMgr.contentSize.height/2));
			}
			else {
				pt = ccpAdd(pt, ccp(-POS_pt_add_x-_msgMgr.contentSize.width, -_msgMgr.contentSize.height/2));
			}

		}
		_msgMgr.position=pt;
		_msgMgr.position = getFinalPosition(_msgMgr);
		_msgMgr.visible = YES;
	}
}

-(void)requestShowItemTrayDescribe:(NSNotification*)arg{
	NSDictionary * dict = arg.object;
	if (dict) {
		int nid = [[dict objectForKey:@"id"] intValue];
		int typ = [[dict objectForKey:@"type"] intValue];
		[self requestShowItemTrayDescribe:nid type:typ];
	}
}

-(void)requestShowItemTrayDescribe:(int)_nid type:(ItemTray_type)_typ{
	ItemDescribetion* _info = [ItemDescribetion showDescribetion:_nid type:_typ];
	
	if (_info != nil) {
		
		[self addChild:_info z:INT32_MAX tag:2098];

		float __x = _panelPos.x - POS_ItemMgr_posX ;
		float __y = _panelPos.y - POS_ItemMgr_posY ;
		
		float __w = ITEMTRAY_SIZE.width;
		float __h = ITEMTRAY_SIZE.height;
		
		int _row = (int)(__y/__h);
		int _col = (int)(__x/__w);
		
		__x = POS_ItemMgr_posX + __w*_col;
		__y = POS_ItemMgr_posY + __h*_row;
		
		CGPoint pt = ccp(__x - _info.contentSize.width, __y - _info.contentSize.height/2);
		_info.position = pt ;
		_info.position = getFinalPosition(_info);
	}

}


-(void)requestSellWithDescribetion{
	int _result = [[PlayerDataHelper shared] checkBatchSell] ;
	if ( _result > 0) {
		//NSString* msg = [NSString stringWithFormat:@"确认出售选中的 %d 件物品！",_result];
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"player_select_sure",nil),_result];
		[[AlertManager shared] showMessage:msg
									target:self
								   confirm:@selector(batckSellItems)
									 canel:@selector(doCanelBatchs)];
	}else{
		[[PlayerDataHelper shared] cleanupBatchData];
	}
}

#pragma mark touch

-(BOOL)isInLayerWithTouch:(UITouch *)touch{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
    if (iPhoneRuningOnGame()) {
        if (touchLocation.x>= POS_ShowAttribute_startX + 44 &&
            touchLocation.y>= POS_ShowAttribute_startY + 44 &&
            touchLocation.x<= POS_ShowAttribute_endX +20
            && touchLocation.y<= POS_ShowAttribute_endY +20 ) {
            
            return YES;
        }
        return NO;

    }else{
	if (touchLocation.x>= POS_ShowAttribute_startX &&
		touchLocation.y>= POS_ShowAttribute_startY &&
		touchLocation.x<= POS_ShowAttribute_endX
		&& touchLocation.y<= POS_ShowAttribute_endY ) {
		
		return YES;
	}
	return NO;
    }
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	_panelPos = [self convertTouchToNodeSpace:touch];
	
	CCLOG(@"PlayerPanel->ccTouchBegan");
	
	if (_msgMgr && _msgMgr.visible) {
		_msgMgr.visible = NO ;
	}
	
	if ([self isInLayerWithTouch:touch]) {
		if (_rDescribetion != nil) {
			if (_rDescribetion.visible) {
				[_rDescribetion doExit];
			}else{
				[_rDescribetion doEnter];
			}
		}
		return NO ;
	}
	
	[self removeChildByTag:2098 cleanup:YES];
	
	return NO ;
}

#pragma mark net

-(void)batckSellItems{
	
	NSDictionary* eDict = [NSDictionary dictionaryWithDictionary:[PlayerDataHelper shared].batchs];
	if (isSend) {
        return;
    }
	[GameConnection request:@"sellAll"
					   data:eDict
					 target:self
					   call:@selector(didBatckSellItems:)];
	isSend = YES;
    [self setButtonEnabled:NO];
}

-(void)didBatckSellItems:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		
		NSDictionary* eDict = getResponseData(_sender);

		NSArray *array__ = [[GameConfigure shared] getPackageAddData:eDict type:PackageItem_all];
		[[AlertManager shared] showReceiveItemWithArray:array__];
		
		[[GameConfigure shared] updatePackage:eDict];
		
		[[PlayerDataHelper shared] updateDataByBatchEnd];
		
		if (_sizerMgr != nil) {
			NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
			[self updatePackage:_number];
		}
		
		
	}else{
		CCLOG(@"Error:%@",_sender);
	}
    isSend = NO;
}


-(void)memberForLeave{
    if (isSend) {
        return;
    }
	NSDictionary* roleInfo = [[PlayerDataHelper shared] getRole:_roleId];
	int _temp = [roleInfo intForKey:@"id"];
	NSString * str = [NSString stringWithFormat:@"rid::%d",_temp];
	
	[GameConnection request:@"roleLeave" format:str target:self call:@selector(didLeave:)];
	isSend = YES;
}

-(void)didLeave:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		
		NSDictionary* _date = getResponseData(_sender);
		int ___id = [_date intForKey:@"rid"];
		[[PlayerDataHelper shared] fallOut:___id];
		[[GameConfigure shared] removeTeamMember:___id];
		NSDictionary* _rRole = [[PlayerDataHelper shared] getRoleById:___id];
		int ___rid = [_rRole intForKey:@"rid"];
		
		[self deleteRoleTab:___rid];
		
		//[self showRoleTabs];
	}else{
		CCLOG(@"Error:%@",_sender);
	}
    isSend = NO;
}

-(void)equipmentMove:(NSDictionary*)data{
	CCLOG(@"\n\n start equipmentMove \n\n");
    if (isSend) {
        return;
    }
	[GameConnection request:@"eqMove"
					   data:data
					 target:self
					   call:@selector(didEquipmentMove::)
						arg:data];
    isSend = YES;
}

-(void)didEquipmentMove:(NSDictionary*)_sender :(NSDictionary*)_data{
	CCLOG(@"\n\n end equipmentMove \n\n");
	if (checkResponseStatus(_sender)) {
		NSDictionary* rData = getResponseData(_sender);
		
		int eid1 = [rData intForKey:@"eid1"];
		int eid2 = [rData intForKey:@"eid2"];
		int money = [rData intForKey:@"coin1"];
		int _role = [_data intForKey:@"rid"];
		
		[[GameConfigure shared] updatePlayerMoney:money];
		
		[[PlayerDataHelper shared] doEquipmentMoveLevel:eid1 with:eid2];
		[[PlayerDataHelper shared] doEquipmentAction:_role off:eid1 input:eid2];
		
		[self updateEquipments:_roleId];
		
		
		if (_itemMgr != nil) {
			ItemTray* _tray = [_itemMgr eventForDeleteItemTray:eid2 type:ItemTray_armor];
			
			NSDictionary* _eDict = [[PlayerDataHelper shared] getEquipmentById:eid1];
			
			if (_eDict != nil) {
				if (_tray != nil) {
					[_tray addItem:_eDict type:ItemTray_armor];
				}else{
					[_itemMgr eventForAddEquipment:_eDict];
				}
			}
			
		}
		
		[self updatePackageAmount];
		
//		if (_sizerMgr != nil) {
//			NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
//			[self updatePackage:_number];
//		}
		
	}else{
		CCLOG(@"Error:%@",_sender);
	}
    isSend = NO;
}

-(void)takeOffEquipment:(NSDictionary*)data{
	CCLOG(@"\n\n start takeOffEquipment \n\n");
    if (isSend) {
        return;
    }
	[GameConnection request:@"tackOffEq"
					   data:data
					 target:self
					   call:@selector(didTakeOffEquipment::)
						arg:data];
	
	isSend = YES;
}

-(void)didTakeOffEquipment:(NSDictionary*)_sender :(NSDictionary*)_pdata{
	CCLOG(@"\n\n end takeOffEquipment \n\n");
	if (checkResponseStatus(_sender)) {
		
		NSDictionary* __dict = getResponseData(_sender);
		
		if (__dict != nil) {
			if (YES) {
				int _role = [_pdata intForKey:@"rid"];
				int _ueid = [_pdata intForKey:@"id"];
				
				[[PlayerDataHelper shared] doEquipmentAction:_role off:_ueid input:0];
				
				//[self showCharacter:_roleId];
				[self updateEquipments:_roleId];
				
				[[PlayerDataHelper shared] updateAllPower];
				
				
				NSDictionary* _eDict = [[PlayerDataHelper shared] getEquipmentById:_ueid];
				if (_itemMgr != nil) {
					[_itemMgr eventForAddEquipment:_eDict];
				}
				
				
				
//				if (_sizerMgr != nil) {
//					NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
//					[self updatePackage:_number];
//				}
				
				[self updatePackageAmount];
				
				
			}
		}
		
	}else{
		//CCLOG(@"Error:%@",_sender);
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
    isSend = NO;
}

-(void)wearEquipment:(NSDictionary*)data arg:(id)arg{
	CCLOG(@"\n\n start wearEquipment \n\n");
    if (isSend) {
        return;
    }
	[GameConnection request:@"wearEq"
					   data:data
					 target:self
					   call:@selector(didEquipment::)
						arg:data];
	isSend = YES;
}

-(void)didEquipment:(NSDictionary*)sender :(NSDictionary*)_pdata{
	CCLOG(@"\n\n end wearEquipment \n\n");
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if (data) {
			
			int _id = [[data objectForKey:@"id"] intValue];//穿上的装备ID
			int _uid = [[data objectForKey:@"uid"] intValue];//脱下的装备ID
			int _rid = [[data objectForKey:@"rid"] intValue];//角色的ID
			
			[[PlayerDataHelper shared] doEquipmentAction:_rid off:_uid input:_id];
			
			//[self showCharacter:_roleId];
			[self updateEquipments:_roleId];
			
			[[PlayerDataHelper shared] updateAllPower];
			
			
			if (_itemMgr != nil) {
				ItemTray* _tray = [_itemMgr eventForDeleteItemTray:_id type:ItemTray_armor];
				
				NSDictionary* _eDict = [[PlayerDataHelper shared] getEquipmentById:_uid];
				if (_eDict != nil) {
					if (_tray != nil) {
						[_tray addItem:_eDict type:ItemTray_armor];
					}else{
						[_itemMgr eventForAddEquipment:_eDict];
					}
				}
				
			}
			
//			if (_sizerMgr != nil) {
//				NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
//				[self updatePackage:_number];
//			}
			[self updatePackageAmount];
		
		}
	}else{
		CCLOG(@"Error:%@",sender);
	}
	isSend = NO;
}

-(void)doUseItem:(int)_id type:(ItemTray_type)_type
{
	
	if (_type == ItemTray_item) {
		
		int ____type = [[PlayerDataHelper shared] getItemType:_id];
		
		if (____type == Item_splinter) {
			
			int count = [[PlayerDataHelper shared] getItemCountById:_id];
			if (count < 10) {
				//[ShowItem showItemAct:@"碎片数量不足"];
                [ShowItem showItemAct:NSLocalizedString(@"player_no_chip",nil)];
			} else {
                if (isSend) {
                    return;
                }
				NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_id] forKey:@"id"];
				[GameConnection request:@"useItem" data:dict target:self call:@selector(didUserItem:)];
                isSend = YES;
			}
			
		}else if (____type == Item_gift_bag){
			
			if ([[PlayerDataHelper shared] checkCanUseItem:_id]) {
                if (isSend) {
                    return;
                }
				NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_id] forKey:@"id"];
				[GameConnection request:@"useItem" data:dict target:self call:@selector(didReceiveAward:)];
                isSend = YES;
                
			} else {
				//[ShowItem showItemAct:@"等级不够"];
                [ShowItem showItemAct:NSLocalizedString(@"player_level_low",nil)];
			}
			
		}else if (____type == Item_fish_item){
			
			if (YES) {
                if (isSend) {
                    return;
                }
				NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_id] forKey:@"id"];
				[GameConnection request:@"useItem" data:dict target:self call:@selector(didReceiveAward:)];
                isSend = YES;
			}
			
		}
		
	}
}

-(void)didReceiveAward:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict type:PackageItem_all];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
		
		[[GameConfigure shared] updatePackage:dict];
		
		[[PlayerDataHelper shared] updateALL:dict];
		
		if (_sizerMgr != nil) {
			NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
			[self updatePackage:_number];
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
    isSend = NO;
}

-(void)didUserItem:(NSDictionary*)sender
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict type:PackageItem_equip];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			[[GameConfigure shared] updatePackage:dict];
			
			// 添加装备
			NSDictionary *equip = nil;
			NSArray *equips = [dict objectForKey:@"equip"];
			if (equips) {
				equip = [equips objectAtIndex:0];
			}
			if (equip) {
				[[PlayerDataHelper shared] addEquipmentWithData:equip];
			}
			
			// 删除物品
			NSMutableArray *delIds = [dict objectForKey:@"delIids"];
			if (delIds != nil) {
				[[PlayerDataHelper shared] removeItemsWithArray:delIds];
			}
			
			// 改变物品
			NSMutableArray *items = [dict objectForKey:@"item"];
			if (items != nil) {
				[[PlayerDataHelper shared] updateItemsWithArray:items];
			}
			
			if (_sizerMgr != nil) {
				NSNumber *_number = [NSNumber numberWithInt:_sizerMgr.selectIndex];
				[self updatePackage:_number];
			}
			
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
    isSend = NO;
}

@end











