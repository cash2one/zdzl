//
//  GameUIRoleHead.m
//  TXSFGame
//
//  Created by chao chen on 12-11-13.
//  Copyright 2012 eGame. All rights reserved.
//

#import "GameUIRoleHead.h"
#import "GameUI.h"
#import "GameMoney.h"
#import "CCLabelFX.h"
#import "Window.h"
#import "PlayerPanel.h"
#import "CCNode+AddHelper.h"
#import "GameSoundManager.h"

////============================
#pragma mark -
#pragma mark - GameUIRoleHead

#define UIROLEHEAD_PRIORITY (-2)
#define UIROLEHEAD_PEIJIANG_Y cFixedScale(-80)
#define UIROLEHEAD_PEIJIANG_X	cFixedScale(30)
#define UIROLEHEAD_HEAD_OFF_X cFixedScale(5)
#define UIROLEHEAD_HEAD_OFF_Y cFixedScale(5)

@implementation TransparentSprite

-(void)setOpacity:(GLubyte)opacity{
	[super setOpacity:opacity];
	CCNode * _iterator = nil;
	CCARRAY_FOREACH(_children, _iterator) {
		if ([_iterator isKindOfClass:[CCSprite class]]) {
			CCSprite* temp = (CCSprite*)_iterator;
			temp.opacity = opacity;
		}
	}
}

@end

////
@interface MyMenu:CCMenu
-(void) registerWithTouchDispatcher;
@end
@implementation MyMenu
-(void) registerWithTouchDispatcher{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:UIROLEHEAD_PRIORITY swallowsTouches:YES];
}
@end


typedef enum {
	//UI_LEFTUP_BACK,
	////z:1
	UI_LEFTUP_HEAD, //头像 按钮
	//fix chao 暂时取消
	//UI_LEFTUP_BIND, //绑定01 按钮
	UI_LEFTUP_DEPOSIT_TWO, //充值02 按钮
	//end
	UI_LEFTUP_UNCOIL, //展开 按钮
	UI_LEFTUP_UNCOIL_SPR, //展开 spr
	////z:2
	UI_LEFTUP_LEVEL, //等级 spr
	UI_LEFTUP_YUANBAO_ONE, //元宝1
	UI_LEFTUP_YUANBAO_TWO, //元宝2
	UI_LEFTUP_YINBI, //银币
	
	UI_LEFTUP_LEVELTXT,//等级文本
	UI_LEFTUP_NAMETXT,//名字文本
	UI_LEFTUP_VIPTXT,//vip文本
	
	UI_LEFTUP_P_ROLE01,//配将01
	UI_LEFTUP_P_ROLE02,//配将02
	UI_LEFTUP_P_ROLE03,//配将03
	UI_LEFTUP_P_ROLE04,//配将04
	UI_LEFTUP_P_ROLE05,//配将05
	
	UI_LEFTUP_END,
}LeftUpUITag;


@implementation GameUIRoleHead

-(void)onEnter{
	[super onEnter];
	
	//CGSize size = [[CCDirector sharedDirector] winSize];
	
	 self.touchEnabled = YES;
	isRoleHeadUIMenu = NO;
	isPeiJiangMenu = NO;
//	CCLabelTTF *chao = [CCLabelTTF labelWithString:@"fadfadfasdfaf" fontName:getCommonFontName(GAMEM_FONT) fontSize:GAMEM_FONT_SIZE];
//	chao.anchorPoint = ccp(0,0.5);
//	chao.position = ccp(30, 30);
//	[self addChild:chao z:10];
	
	////背景
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/bar.png"];
	[self addChild:bg z:0];
	bg.anchorPoint=ccp(0, 0);
	bg.position = ccp(0,0);
    
	////头像背景
	CCSprite *bt_headback = [CCSprite spriteWithFile:@"images/ui/common/headback.png"];
	//[self addChild:bt_headback z:0];
	//bt_headback.position = ccp(bt_headback.contentSize.width/2+UIROLEHEAD_HEAD_OFF_X,bt_headback.contentSize.height/2+UIROLEHEAD_HEAD_OFF_Y-3);
	//fix chao
	
	if(iPhoneRuningOnGame()){
		self.contentSize=CGSizeMake(bg.contentSize.width + 10, bg.contentSize.height);
	}else{
		self.contentSize=CGSizeMake(bg.contentSize.width + 20, bg.contentSize.height);
	}
	
	roleHeadUIMenu = [MyMenu node];
	[self addChild:roleHeadUIMenu z:1 ];
	roleHeadUIMenu.position = ccp(0, 0);//ccp(self.contentSize.width/2,self.contentSize.height/2);
	//end
	////绑定
	
	
	//fix chao
	/*
	//NSArray *sprArr = getBtnSprite(@"images/ui/button/bt_bind.png");
	NSArray *sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_main_ui_bind");
	CCMenuItem *bt_deposit01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	self.contentSize=CGSizeMake(bg.contentSize.width + 20, bg.contentSize.height);
	bt_deposit01.anchorPoint = ccp(0,0.5);
	bt_deposit01.position = ccp(self.contentSize.width/2,self.contentSize.height/4);
	 
	//
	[roleHeadUIMenu addChild:bt_deposit01 z:0 tag:UI_LEFTUP_BIND];		
	*/
	
	////充值2
	//fix chao

	////头像
	CCMenuItem *bt_head = [CCMenuItemSprite itemWithNormalSprite:bt_headback selectedSprite:nil target:self selector:@selector(menuCallbackBack:)];
	[roleHeadUIMenu addChild:bt_head z:0 tag:UI_LEFTUP_HEAD];
    bt_head.position = ccp(bt_head.contentSize.width/2, self.contentSize.height/2);
	//bt_head.position = ccp(-self.contentSize.width/2+bt_headback.contentSize.width/2+UIROLEHEAD_HEAD_OFF_X,-bt_headback.contentSize.height/2);
	
	////展开
	//CCMenuItem *bt_uncoil = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithFile:@"images/ui/button/bt_cri.png"] selectedSprite:nil target:self selector:@selector(menuCallbackBack:)];
    //[roleHeadUIMenu addChild:bt_uncoil z:0 tag:UI_LEFTUP_UNCOIL];
    CCSimpleButton *bt_uncoil = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_cri.png" select:@"images/ui/button/bt_cri.png" target:self call:@selector(menuCallbackBack:)];
    bt_uncoil.priority = UIROLEHEAD_PRIORITY;
	[self addChild:bt_uncoil z:0 tag:UI_LEFTUP_UNCOIL];
	bt_uncoil.position = ccp(-bt_uncoil.contentSize.width/3+bt_uncoil.contentSize.width/2,-bt_uncoil.contentSize.height/2);
	////展开spr
	CCMenuItem *bt_uncoil_spr = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithFile:@"images/ui/common/common1.png"] selectedSprite:nil target:self selector:@selector(menuCallbackBack:)];	
	[roleHeadUIMenu addChild:bt_uncoil_spr z:1 tag:UI_LEFTUP_UNCOIL_SPR];
	bt_uncoil_spr.position = ccp(-bt_uncoil.contentSize.width/3+bt_uncoil.contentSize.width/2,-bt_uncoil.contentSize.height/2);
	
	////配将
	peiJiangMenu = [MyMenu node];	
	peiJiangMenu.position = ccp(-UIROLEHEAD_PEIJIANG_X,UIROLEHEAD_PEIJIANG_Y);
	NSArray *peiJiangArr = [[GameConfigure shared] getFightTeamMember];//[NSArray arrayWithObjects:[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1], nil];
	NSMutableArray *array = [NSMutableArray arrayWithArray:peiJiangArr];
	[self addChild:peiJiangMenu z:1 ];
	[self updateTeamMember:array];
	
	////等级背景
	CCSprite *level_bg = [CCSprite spriteWithFile:@"images/ui/button/bt_levelbar.png"];
	[self addChild:level_bg z:1 tag:UI_LEFTUP_LEVEL];
	level_bg.position = ccp(bt_headback.contentSize.width/2+UIROLEHEAD_HEAD_OFF_X,level_bg.contentSize.height/2);
	
	////元宝1
	GameMoney *yuanBao01 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:0];
	yuanBao01.anchorPoint = ccp(0,0.5);
	[self addChild:yuanBao01 z:1 tag:UI_LEFTUP_YUANBAO_ONE];
	
	////元宝2
	GameMoney *yuanBao02 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO value:0];
	yuanBao02.anchorPoint = ccp(0,0.5);
	[self addChild:yuanBao02 z:1 tag:UI_LEFTUP_YUANBAO_TWO];
	
	////银币
	GameMoney *yinBi = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:0];
	yinBi.anchorPoint = ccp(0,0.5);
	[self addChild:yinBi z:1 tag:UI_LEFTUP_YINBI];
	
	if(iPhoneRuningOnGame()){
		yuanBao01.position = ccp(bt_headback.contentSize.width+5,self.contentSize.height/2-yuanBao01.contentSize.height/2+4);
		yuanBao02.position = ccp(bt_headback.contentSize.width+5+yuanBao01.contentSize.width+5,self.contentSize.height/2-yuanBao01.contentSize.height/2 + 4);
		yinBi.position = ccp(bt_headback.contentSize.width+5,self.contentSize.height/2-yuanBao01.contentSize.height/2 - yinBi.contentSize.height);	
	}else{
		yuanBao01.position = ccp(bt_headback.contentSize.width+10,self.contentSize.height/2-yuanBao01.contentSize.height/2+8);
		yuanBao02.position = ccp(bt_headback.contentSize.width+10+yuanBao01.contentSize.width+10,self.contentSize.height/2-yuanBao01.contentSize.height/2 + 8);
		yinBi.position = ccp(bt_headback.contentSize.width+10,self.contentSize.height/2-yuanBao01.contentSize.height/2 - yinBi.contentSize.height);	
	}
	
	////
	bt_uncoiledDir = -1;
	bt_uncoil_spr.scaleX = bt_uncoiledDir;
	
	//self.position = ccp(0, size.height - self.contentSize.height);
	
	[self updateAll];
	
	////
	[GameConnection addPost:ConnPost_updatePlayerInfo target:self call:@selector(updatePackage:)];
	[GameConnection addPost:ConnPost_updatePackage target:self call:@selector(updatePackage:)];
	[GameConnection addPost:ConnPost_updateRolelist target:self call:@selector(updatePackage:)];
	[GameConnection addPost:ConnPost_updatecbe target:self call:@selector(showCBE:)];
	
	[self updateStatus:[MapManager shared].mapType];
}


-(void)updateStatus:(Map_Type)_type{
	//todo
	if(YES){
		//if([MapManager shared].mapType==Map_Type_Standard){
		if (roleHeadUIMenu == nil) {
			return ;
		}
		[roleHeadUIMenu removeChildByTag:UI_LEFTUP_DEPOSIT_TWO cleanup:YES];
		
		if (![[GameConfigure shared]isPlayerOnChapter]) {
			// 现在显示充值按钮 2013.4.19
			if (YES) {
				NSArray *sprArr = getBtnSpriteWithStatus([self getChargePath]);
				if (sprArr && sprArr.count == 2) {
					CCMenuItem *bt_deposit02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
					//				bt_deposit02.anchorPoint = ccp(0,0.5);
					//				bt_deposit02.position = ccp(self.contentSize.width,self.contentSize.height*3/4);
					bt_deposit02.anchorPoint = ccp(0,1.0f);
					bt_deposit02.position = ccp(self.contentSize.width,self.contentSize.height - cFixedScale(10));
					[roleHeadUIMenu addChild:bt_deposit02 z:0 tag:UI_LEFTUP_DEPOSIT_TWO];
				}
				//end
			}
		}
	}
}

-(NSString*)getChargePath{
	if ([[GameConfigure shared] checkPlayerIsFirstRecharge]) {
//		if (iPhoneRuningOnGame()) {
//			return @"images/ui/button/bt_First_charge";
//		}else{
//			return @"images/ui/button/bt_First_charge";
//		}
		return @"images/ui/button/bt_First_charge";
	}else{
		if (iPhoneRuningOnGame()) {
			return @"images/ui/wback/bt_main_ui_deposit";
		}else{
			return @"images/ui/button/bt_main_ui_deposit";
		}
	}
}

-(void)updatePackage:(id)sender
{
	[self updateAll];
}
-(void)onExit
{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[GameConnection removePostTarget:self];
	[super onExit];
}

////参数：配将ＩＤ数组
-(void)updateTeamMember:(NSArray*)array{

	[peiJiangMenu removeAllChildrenWithCleanup:YES];
	
	////配将按钮
	CCMenuItemImage *button;
	CCSprite* spr=nil;
	float h=0;
	int i=0;
	int mainRoleID = [[GameConfigure shared] getPlayerRole];
	for (NSNumber *number in array )
	{		
		if ([number intValue]!=mainRoleID) {			
			
			spr = getCharacterIcon([number intValue], ICON_PLAYER_SMALL);
			
			button = [CCMenuItemSprite itemWithNormalSprite:spr selectedSprite:nil target:self selector:@selector(menuCallbackBack:)];
			//button.anchorPoint = ccp(0.5,1);
            button.anchorPoint = ccp(0,0.5);
			[peiJiangMenu addChild:button z:0 tag:UI_LEFTUP_P_ROLE01+i];
			//button.position = ccp(0,h);
            button.position = ccp(-UIROLEHEAD_PEIJIANG_X,h);
			h -= spr.contentSize.height-3;
			i++;
		}
	}
}
-(void)reSetOpen{
	bOpen = NO ;
}
-(void)menuCallbackBack: (id) sender{
	
	[[GameSoundManager shared] click];
	
    if (([[Window shared] isHasWindow])||(!self.visible)) {
        return;
    }
	//TODO
	CCNode *obj = sender;
	if (obj.tag == UI_LEFTUP_UNCOIL|| obj.tag ==UI_LEFTUP_UNCOIL_SPR) {
        if ([[GameConfigure shared] isPlayerOnChapter]) {
			return ;
		}
		[self moveUncoil:sender];
		CCLOG(@"UI_LEFTUP_UNCOIL");
	}else if(obj.tag == UI_LEFTUP_HEAD){
		CCLOG(@"UI_LEFTUP_HEAD");
		
		//TODO
		
		if ([[GameConfigure shared] isPlayerOnChapter]) {
			return ;
		}
		
		[PlayerPanel setShowRole:0];
		[[Window shared] showWindow:PANEL_CHARACTER];
		
		
		
	}else if(obj.tag == UI_LEFTUP_DEPOSIT_TWO){
		
		CCLOG(@"UI_LEFTUP_DEPOSIT_TWO");
        if ( ![[GameConfigure shared] isPlayerOnChapter ]){
			/*
            [[Window shared] showWindow:PANEL_EXCHANGE];
			 */
			if ([[GameConfigure shared] checkPlayerIsFirstRecharge]) {
				[[Window shared] showWindow:PANEL_EXCHANGE_ACTIVITY];
			}else{
				[[Window shared] showWindow:PANEL_EXCHANGE];
			}
        }
		
	}else if(obj.tag >= UI_LEFTUP_P_ROLE01 && obj.tag <= (UI_LEFTUP_P_ROLE01 + 6)){
		[self moveUncoil:sender];
		CCLOG(@"%d",(obj.tag-UI_LEFTUP_P_ROLE01));
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[GameConfigure shared] getFightTeamMember]];
		int mainRoleID = [[GameConfigure shared] getPlayerRole];
		 for (int i=0; i<[array count]; i++) {
			 if ([[array objectAtIndex:i] intValue]==mainRoleID) {
				 [array removeObjectAtIndex:i];
			 }
		 }		
		int index = obj.tag - UI_LEFTUP_P_ROLE01;
		index = [[array objectAtIndex:index] intValue];
		 
		if ([[GameConfigure shared] isPlayerOnChapter]) {
			return ;
		}
		 [PlayerPanel setShowRole:index];
		 [[Window shared] showWindow:PANEL_CHARACTER];
		 
		
	}
	CCLOG(@"role head ui tag");
	
}
-(void)moveUncoil:(id)sender{
	CGPoint pos = peiJiangMenu.position;
	[peiJiangMenu stopAllActions];
	if (bt_uncoiledDir==1){
		pos.x = -UIROLEHEAD_PEIJIANG_X;		
		[peiJiangMenu runAction:([CCSequence actions:[CCMoveTo actionWithDuration:0.1 position:pos],[CCCallFuncN actionWithTarget:self selector:@selector(uncoilBackCall:)], nil ])];
		
	}
	else{
		pos.x = UIROLEHEAD_PEIJIANG_X;		
		[peiJiangMenu runAction:([CCSequence actions:[CCMoveTo actionWithDuration:0.1 position:pos],[CCCallFuncN actionWithTarget:self selector:@selector(uncoilBackCall:)], nil ])];
	}
}
-(void)uncoilBackCall:(id)sender{
	bt_uncoiledDir = -bt_uncoiledDir;
	CCMenuItem *bt_uncoil_spr = (CCMenuItem *)[roleHeadUIMenu getChildByTag:UI_LEFTUP_UNCOIL_SPR];
	bt_uncoil_spr.scaleX = bt_uncoiledDir;
}
////===========================================
////对外方法
////===========================================
////更新头像区
-(void)updateAll{	
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	NSNumber *roleID = [dict objectForKey:@"rid"];
	NSNumber *vip= [dict objectForKey:@"vip"];
	NSString *name= [dict objectForKey:@"name"];
	NSNumber *level= [dict objectForKey:@"level"];
	NSNumber *coin1= [dict objectForKey:@"coin1"];//银币
	NSNumber *coin2= [dict objectForKey:@"coin2"];//元宝1
	NSNumber *coin3= [dict objectForKey:@"coin3"];//元宝2
	
	[self updateRoleHead:roleID.intValue];
	[self updateVIP:vip.intValue];
	//[self updateVIP:12];
	[self updateRoleName:name];
	[self updateLevel:level.intValue];
	[self updateMoneyWithYuanBao01:coin2.intValue yuanBao02:coin3.intValue yinBi:coin1.intValue];
	
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[GameConfigure shared] getFightTeamMember]];
	[self updateTeamMember:array];
	
}

-(void)updateMoneyWithYuanBao01:(NSInteger)value01 yuanBao02:(NSInteger)value02 yinBi:(NSInteger)value03{
	GameMoney* yuanBao01 = (GameMoney* )[self getChildByTag:UI_LEFTUP_YUANBAO_ONE];
	[yuanBao01 setMoneyValue:value01];
	GameMoney* yuanBao02 = (GameMoney* )[self getChildByTag:UI_LEFTUP_YUANBAO_TWO];
	[yuanBao02 setMoneyValue:value02];
	yuanBao02.position = ccp(yuanBao01.position.x+yuanBao01.contentSize.width+10,yuanBao02.position.y);
	GameMoney* yinBi = (GameMoney* )[self getChildByTag:UI_LEFTUP_YINBI];
	[yinBi setMoneyValue:value03];
}

-(void)updateLevel:(NSInteger)level{
	if (level>99) {
		level = 99;
	}
	
	CCLabelFX *label = (CCLabelFX *)[self getChildByTag:UI_LEFTUP_LEVELTXT];
	if (label) {
		[label setString:[NSString stringWithFormat:@"Lv%d",level]];
	}
	else {
		label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"Lv%d",level]
								  fontName:getCommonFontName(FONT_1)
								  fontSize:16
							  shadowOffset:CGSizeMake(1,-1)
								shadowBlur:0.2
							   shadowColor:ccc4(203, 127, 7, 255)
								 fillColor:ccc4(49,18,7, 255)];
		
		[self addChild:label z:3 tag:UI_LEFTUP_LEVELTXT];
		label.anchorPoint = ccp(0.5,0.5);
		CCSprite *level_bg = (CCSprite *)[self getChildByTag:UI_LEFTUP_LEVEL];
		label.position=level_bg.position;		
	}	
}
-(void)updateRoleName:(NSString*)name{
	CCLabelFX *label = (CCLabelFX *)[self getChildByTag:UI_LEFTUP_NAMETXT];
    int f_size = 18;
    if (iPhoneRuningOnGame()) {
        f_size = 20;
    }
	if (label) {
		[label setString:name];
	}
	else {
		label = [CCLabelFX labelWithString:name 
								  fontName:getCommonFontName(FONT_1) 
								  fontSize:f_size 
							  shadowOffset:CGSizeMake(1,-1)
								shadowBlur:0.2 
							   shadowColor:ccc4(203, 127, 7, 255)
								 fillColor:ccc4(49,18,7, 255)];
	
		[self addChild:label z:3 tag:UI_LEFTUP_NAMETXT];
		label.anchorPoint = ccp(0,0.5);
		if(iPhoneRuningOnGame()){
			label.position=ccp(65, self.contentSize.height*3/4);
		}else{
			label.position=ccp(130, self.contentSize.height*3/4);
		}
	}	
}
-(void)updateVIP:(NSInteger)vip{
	CCLabelFX *vip_label = (CCLabelFX *)[self getChildByTag:UI_LEFTUP_VIPTXT];
    int f_size = 12;
    if (iPhoneRuningOnGame()) {
        f_size = 14;
    }
	if (vip_label) {
		[vip_label setString:[NSString stringWithFormat:@"VIP%d",vip]];
	}else{
		vip_label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"VIP%d",vip]
								  fontName:getCommonFontName(FONT_1)
								  fontSize:f_size
							  shadowOffset:CGSizeMake(1,-1)
								shadowBlur:0.2
								   shadowColor:ccc4(203, 127, 7, 255)
									 fillColor:ccc4(49,18,7, 255)];
		
		[self addChild:vip_label z:3 tag:UI_LEFTUP_VIPTXT];
		vip_label.anchorPoint = ccp(1,0.5);
		
		if(iPhoneRuningOnGame()){
			vip_label.position=ccp(135,self.contentSize.height*3/4);
		}else{
			vip_label.position=ccp(270,self.contentSize.height*3/4);
		}
		
	}
	if (vip<=0) {
		[vip_label setVisible:NO];
		//fix chao
		/*
		[bt_deposit01 setVisible:YES];
		[bt_deposit02 setVisible:NO];
		 */
		//end
	}else{
		[vip_label setVisible:YES];
		//fix chao
		/*
		[bt_deposit01 setVisible:NO];
		[bt_deposit02 setVisible:YES];
		 */
	}
}

-(void)updateRoleHead:(NSInteger)headID{
    [self removeChildByTag:100089 cleanup:YES];
    
    CCSprite *bt_headback = [CCSprite spriteWithFile:@"images/ui/common/headback.png"];
    [self addChild:bt_headback z:0 tag:100089];
    bt_headback.position = ccp(bt_headback.contentSize.width/2, self.contentSize.height/2);
    
	CCMenuItemSprite *roleHead_spr = (CCMenuItemSprite *)[roleHeadUIMenu getChildByTag:UI_LEFTUP_HEAD];
    CCSprite* _node = getCharacterIcon(headID, ICON_PLAYER_BIG);
    _node.scaleX = -1 ;
    _node.anchorPoint = ccp(0.5, 0);
    _node.position = ccp(roleHead_spr.contentSize.width/2, 0);
	[roleHead_spr setNormalImage:_node];
}

#pragma mark ---
-(void)showCBE:(NSNotification*)notification{
	if ([self getChildByTag:8474743]) {
		return ;
	}
	CCSprite* zhanli = [CCSprite spriteWithFile:@"images/ui/cbe/zhanli.png"];
	if (zhanli) {
		[self addChild:zhanli z:99 tag:8474743];
		zhanli.anchorPoint = ccp(0, 1.0);
		zhanli.position = ccp(cFixedScale(50), 0);
		
		
		NSString* path = [NSString stringWithFormat:@"images/ui/cbe/num_4.png"];
		CCSprite* ___sprite = [self getImageNumberZoom:path :35 :47 :[notification.object intValue] :12];
		___sprite.anchorPoint=ccp(0, 0.5);
		
		[zhanli addChild:___sprite z:0 tag:0];
		___sprite.position = ccp(zhanli.contentSize.width,zhanli.contentSize.height/2);
		
		CCSprite* upSpr = [CCSprite spriteWithFile:@"images/ui/cbe/up.png"];
		upSpr.anchorPoint = ccp(0, 0.5);
		[zhanli addChild:upSpr z:0 tag:0];
		upSpr.position = ccp(zhanli.contentSize.width + ___sprite.contentSize.width,zhanli.contentSize.height/2);
		
		
		zhanli.scale = 0.8f;
		id act1 = [CCDelayTime actionWithDuration:3.0f];
		id act3 = [CCMoveTo	actionWithDuration:0.5f position:ccpAdd(zhanli.position, ccp(0, cFixedScale(50)))];
		id act5 = [CCCallFunc actionWithTarget:self selector:@selector(endShowCBE)];
		id act6 = [CCSequence actions:act1,act3,act5,nil];
		
		[zhanli runAction:act6];
	}
}

-(void)endShowCBE{
	[self removeChildByTag:8474743 cleanup:YES];
}

-(CCSprite*)getImageNumberZoom:(NSString*)path :(float)width :(float)height :(int)num :(int)zoom {
	CCSprite* ___sprite = [CCSprite node];
	CCSprite* ___result = [CCSprite node];
	float _x = 0 ;
	float _y = 0 ;
	int _total = 0 ;
	
	width = cFixedScale(width);
	height = cFixedScale(height);
    
	do {
		int d1 = num%10;
		num = num/10;
		CCSprite* temp = [CCSprite spriteWithFile:path rect:CGRectMake(width*d1, 0, width, height)];
		[___sprite addChild:temp z:0];
		temp.anchorPoint=ccp(1.0f, 0.5);
		temp.position=ccp(_x, _y);
		_x -= width ;
		_x += zoom ;
		_total++;
	} while (num > 0);
	
	
	___result.contentSize =CGSizeMake(_total*width - zoom* (_total - 1), height);
	[___result addChild:___sprite z:1];
	___sprite.position=ccp(___result.contentSize.width, height/2);
	
	return ___result;
}

@end






