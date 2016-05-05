//
//  SettingPanel.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-12.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "SettingPanel.h"
#import "Config.h"
#import "MessageBox.h"
#import "Window.h"
#import "GameStart.h"
#import "GameSoundManager.h"
#import "SNSHelper.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "Task.h"
#import "TaskManager.h"
#import "SacrificePanel.h"
#import "CCSimpleButton.h"
#import "GameReporter.h"
#import "InAppBrowser.h"
#import "GameConnection.h"

#define PRIVATE_TAG		-100

//#define MAIL_STRING    @"efunzl@qq.com"
#define MAIL_STRING    @"zl@efun.com"

//#if TARGET_IPHONE
//
//#define POS_PLATELINE_LOAD1_ADD_X 5/2
//#define POS_PLATELINE_LOAD_X 5/2
//#define CGS_PLATELINE_LOAD_BODY_ADD_X 13/2
//#define CGS_SELF CGSizeMake(50/2, 50/2)
//#define POS_TXT_ADD_Y  15/2
//#define VALUE_OFFLEN 100/2
//#define POS_Title_height_offset			10/2
//#define CGS_BOX CGSizeMake(538/2, 370/2)
//#define POS_BOX ccp(26/2, 18/2)
//#define POS_TEXTSPR_ONE  ccp(50/2, 180/2)
//#define POS_TEXTSPR_TWO  ccp(50/2, 80/2)
//#define POS_TEXTSPR_THREE  ccp(280/2, 80/2)
//#define POS_CLOSE_ADD_X    43/2
//#define POS_CLOSE_ADD_Y    40/2
//#define POS_BT1_START_X   150/2
//#define POS_BT1_START_Y   340/2
//#define POS_BT1_ADD_X    150/2
//#define POS_BT1_ADD_Y    70/2
//#define POS_BTT_TOGGLE_ONE   ccp(450/2,140/2)
//#define POS_BTT_TOGGLE_TWO   ccp(450/2,100/2)
//#define WIDTH_PLATELINE_ADD   10/2
//#define CGS_BACKGROUND_X  360/2
//#define CGS_BACKGROUND_Y  240/2
//#define VALUE_CAPX   8/2
//#define VALUE_CAPY   8/2
//#define POS_LABEL_SERVICE_X  20/2
//#define POS_LABEL_QQ_ADD_Y   30/2
//#define POS_LABEL_QQ_GROUP_Y 80/2
//#define POS_LABEL_EMAIL_Y    15/2
//#define CGS_EMAIL_BUTTON_Y   30/2
//#define POS_EMAIL_BUTTON_ADD_X 23/2
//#define POS_EMAIL_BUTTON_Y   120/2
//#define POS_YES_BUTTON_ADD_Y   50/2
//#define SCALE_LINE    558.0f/2
//#define SIZE_SPRARR  22/2
//#else

#define POS_PLATELINE_LOAD1_ADD_X              cFixedScale(5)
#define POS_PLATELINE_LOAD_X cFixedScale(5)
#define CGS_PLATELINE_LOAD_BODY_ADD_X           cFixedScale(13)
#define CGS_SELF                CGSizeMake(cFixedScale(50), cFixedScale(50))
#define POS_TXT_ADD_Y           cFixedScale(15)
#define VALUE_OFFLEN            cFixedScale(100)
#define POS_Title_height_offset		        	cFixedScale(10)
#define CGS_BOX                 CGSizeMake(cFixedScale(538), cFixedScale(370))
#define POS_BOX                 ccp(cFixedScale(26), cFixedScale(18))
#define POS_TEXTSPR_ONE         ccp(cFixedScale(50), cFixedScale(180))
#define POS_TEXTSPR_TWO         ccp(cFixedScale(50), cFixedScale(80))
#define POS_TEXTSPR_THREE       ccp(cFixedScale(280), cFixedScale(80))
#define POS_CLOSE_ADD_X         cFixedScale(43)
#define POS_CLOSE_ADD_Y         cFixedScale(40)
#define POS_BT1_START_X         cFixedScale(150)
#define POS_BT1_START_Y         cFixedScale(340)
#define POS_BT1_ADD_X           cFixedScale(150)
#define POS_BT1_ADD_Y           cFixedScale(70)
#define POS_BTT_TOGGLE_ONE      ccp(cFixedScale(450),cFixedScale(140))
#define POS_BTT_TOGGLE_TWO      ccp(cFixedScale(450),cFixedScale(100))
#define WIDTH_PLATELINE_ADD     cFixedScale(10)
#define CGS_BACKGROUND_X        cFixedScale(360)
#define CGS_BACKGROUND_Y        cFixedScale(240)
#define VALUE_CAPX              cFixedScale(8)
#define VALUE_CAPY              cFixedScale(8)
#define POS_LABEL_SERVICE_X     cFixedScale(20)
#define POS_LABEL_QQ_ADD_Y      cFixedScale(30)
#define POS_LABEL_QQ_GROUP_Y    cFixedScale(80)
#define POS_LABEL_EMAIL_Y       cFixedScale(15)
#define CGS_EMAIL_BUTTON_Y      cFixedScale(30)
#define POS_EMAIL_BUTTON_ADD_X  cFixedScale(23)
#define POS_EMAIL_BUTTON_Y      cFixedScale(120)
#define POS_YES_BUTTON_ADD_Y    cFixedScale(50)
#define SCALE_LINE              cFixedScale(558.0f)
#define SIZE_SPRARR             cFixedScale(22)
//#endif


@interface SettingPanel(SettingPanelEX)
-(void)setPlayersWithValue:(NSInteger)value;
@end

//fix chao
@interface LoadSprite : CCSprite{
	NSInteger loadType;
	float loadFloatValue;
}
@property (nonatomic,assign) NSInteger loadType;
@property (nonatomic,assign) float loadFloatValue;
@end

@implementation LoadSprite
enum{
	LS_LOAD_BODY_TAG=12,
	LS_LOAD_END_TAG,
};
@synthesize loadType;
@synthesize loadFloatValue;

-(void)onEnter{
	loadType = 0;
	loadFloatValue = 0;
	[self setLoadType:loadType];
}
-(void)setLoadType:(NSInteger)_loadType{
	loadType = _loadType;
	[self removeAllChildrenWithCleanup:YES];
	//plate line bg
	CCSprite *plateLine_bg = [CCSprite spriteWithFile:@"images/ui/panel/p13.png"];
	if (!plateLine_bg) {
		CCLOG(@"get p13.png error");
		return;
	}
	self.contentSize = plateLine_bg.contentSize;
	[self addChild:plateLine_bg z:0];
	plateLine_bg.anchorPoint = ccp(0,0.5);
	plateLine_bg.position = ccp(0,self.contentSize.height/2);
	//
	CCSprite *plateLine_bf = [CCSprite spriteWithFile:@"images/ui/panel/setting_bf.png"];
	[self addChild:plateLine_bf z:3];
	plateLine_bf.anchorPoint = ccp(0,0.5);
	plateLine_bf.position = ccp(0,self.contentSize.height/2);
	
	if (_loadType==0) {
		//
		CCSprite *plateLine_load1 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_1.png"];
		[self addChild:plateLine_load1 z:0];
		plateLine_load1.anchorPoint = ccp(0,0.5);
		plateLine_load1.position = ccp(5,self.contentSize.height/2);
	}else if(_loadType==1){
		//
		CCSprite *plateLine_load1 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_1.png"];
		[self addChild:plateLine_load1 z:0];
		plateLine_load1.anchorPoint = ccp(1,0.5);
		plateLine_load1.position = ccp(self.contentSize.width-POS_PLATELINE_LOAD1_ADD_X,self.contentSize.height/2);
		plateLine_load1.scaleX = -1;
	}
	//
	[self setLoadFloatValue:loadFloatValue];
	
}
-(void)setLoadFloatValue:(float)val_f{
	loadFloatValue = val_f;
	if (loadFloatValue>1) {
		loadFloatValue = 1;
	}
	if (loadFloatValue<0) {
		loadFloatValue = 0;
	}
	CCSprite *plateLine_load_body = (CCSprite *)[self getChildByTag:LS_LOAD_BODY_TAG];
	CCSprite *plateLine_load_end = (CCSprite *)[self getChildByTag:LS_LOAD_END_TAG];
	if (loadType==0) {
		//
		if (!plateLine_load_end) {
			plateLine_load_end = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_3.png"];
			[self addChild:plateLine_load_end z:1 tag:LS_LOAD_END_TAG];
			plateLine_load_end.anchorPoint = ccp(0,0.5);
		}
		if (!plateLine_load_body) {
			plateLine_load_body = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_2.png"],CGSizeMake(self.contentSize.width-10-3,plateLine_load_end.contentSize.height));
			[self addChild:plateLine_load_body z:1 tag:LS_LOAD_BODY_TAG];
			plateLine_load_body.anchorPoint = ccp(0,0.5);
			plateLine_load_body.position = ccp(POS_PLATELINE_LOAD_X,self.contentSize.height/2);
			
		}
		//
		plateLine_load_body.scaleX = loadFloatValue;
		plateLine_load_end.position = ccp(plateLine_load_body.position.x+plateLine_load_body.scaleX*plateLine_load_body.contentSize.width,self.contentSize.height/2);
	}else if(loadType==1){
		//
		if (!plateLine_load_end) {
			plateLine_load_end = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_3.png"];
			[self addChild:plateLine_load_end z:1 tag:LS_LOAD_END_TAG];
			plateLine_load_end.anchorPoint = ccp(0,0.5);
			plateLine_load_end.scaleX = -1;
		}
		if (!plateLine_load_body) {
			plateLine_load_body = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_2.png"],CGSizeMake(self.contentSize.width-CGS_PLATELINE_LOAD_BODY_ADD_X,plateLine_load_end.contentSize.height));
			[self addChild:plateLine_load_body z:1 tag:LS_LOAD_BODY_TAG];
			plateLine_load_body.anchorPoint = ccp(1,0.5);
			plateLine_load_body.position = ccp(self.contentSize.width-POS_PLATELINE_LOAD1_ADD_X,self.contentSize.height/2);
		}			//
		plateLine_load_body.scaleX = loadFloatValue;
		plateLine_load_end.position = ccp(plateLine_load_body.position.x - plateLine_load_body.scaleX*plateLine_load_body.contentSize.width,self.contentSize.height/2);
	}
	
}
@end
@interface PlateSprite : CCSprite{
	CCLabelTTF *txt;
	CGPoint startPos;
	float	offLen;
	float	startValue;
	float	endValue;
	float	nowValue;
	//
	id		targer;
	
}
@property (nonatomic,assign) id targer;
@property (nonatomic,assign) float offLen;
@property (nonatomic,assign) float startValue;
@property (nonatomic,assign) float endValue;
-(float)getNowValue;
-(void)setValue:(NSInteger )value;
-(void)setMoveToPosition:(CGPoint)position;
@end

@implementation PlateSprite
@synthesize targer;
@synthesize offLen;
@synthesize startValue;
@synthesize endValue;

-(void)onEnter{
	[super onEnter];
	self.contentSize = CGSizeMake(50, 50);
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/setting_plate.png"];
	[self addChild:bg];
	bg.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	////txt
	txt = [CCLabelTTF labelWithString:@"0" fontName:getCommonFontName(FONT_1) fontSize:10];
	[self addChild:txt];
	txt.position = ccp(self.contentSize.width/2,self.contentSize.height/2+POS_TXT_ADD_Y);
    if (iPhoneRuningOnGame()) {
        txt.scale = 0.8;
    }
	//
	
	offLen = VALUE_OFFLEN;
	//startValue = 50;
	//endValue = 0;
	
}
-(float)getNowValue{
	return nowValue;
}
-(void)setValue:(NSInteger)value{
	nowValue = value;
	
	/*
	int max_val = 0;
	int min_val = 0;
	int len = abs(startValue-endValue);
	
	if (startValue>endValue) {
		max_val = startValue;
		min_val = endValue;
	}else{
		max_val = endValue;
		min_val = startValue;
	}
	
	int nowLen = nowValue - min_val;
	int dLen = nowLen;
	if (nowValue<min_val) {
		nowValue = min_val;
	}
	if (nowValue>max_val) {
		nowValue=max_val;
	}
	if (startValue>endValue) {
		dLen = len - nowValue;
	}
	 
	CGPoint dPos = ccp(1.0*dLen*offLen/len,0);
	
	if (startValue>endValue) {
		dPos.x = + dPos.x;
	}else if(startValue<endValue){
		dPos.x = offLen - dPos.x;
	}else{
		[self setTextWithValue:0];
		return;
	}
	
	[self setTextWithValue:nowValue];
	[super setPosition:ccpAdd(startPos,dPos)];
	*/
	
	[self setTextWithValue:nowValue];
	
	float val_percent = nowValue/(abs(startValue)+abs(endValue));
	CGPoint dPos = ccp(offLen*val_percent,0);
	if(startValue>endValue){
		dPos.x = offLen-dPos.x;
	}
	[super setPosition:ccpAdd(startPos,dPos)];
	
}
-(void)setTextWithValue:(NSInteger )value{
	if(txt){
		nowValue = value;
		[txt setString:[NSString stringWithFormat:@"%d",value]];
	}
	//TODO target fun
	[targer setPlayersWithValue:value];
}
-(void)setMoveToPosition:(CGPoint)position{
	CGPoint dPos = ccpSub(position, startPos);
	dPos.y = 0;
	if (dPos.x<0) {
		dPos.x = 0;
	}
	if (dPos.x>offLen) {
		dPos.x=offLen;
	}
	
	CGPoint dxPos = dPos;
	dPos.x = dPos.x*abs(startValue-endValue)/offLen;
	
	if (startValue>endValue) {
		dPos.x = startValue - dPos.x;
	}else if(startValue<endValue){
		dPos.x = startValue + dPos.x;
	}else{
		[self setTextWithValue:0];
		return;
	}
	[self setTextWithValue:dPos.x];
	[super setPosition:ccpAdd(startPos, dxPos)];
	
}

-(void)setPosition:(CGPoint)position{
	[super setPosition:position];
	startPos = position;
}
@end
//end


@implementation SettingPanel
enum {
	SettingPlateLoadTag = 105,
	SettingPlateTag,
	SettingMessageBoxTag,
};

-(void)onEnter
{
	[super onEnter];
	isTouch = NO;
    
	//mapRolesMax = [[GameDB shared] mapRolesMax];
	mapRolesMax = 50;//TODO
	
	MessageBox *box = [MessageBox create:CGPointZero color:ccc4(204, 125, 14,128)];
	[self addChild:box z:0];
    if (iPhoneRuningOnGame()) {
		box.contentSize=CGSizeMake(960/2,555/2);
		box.position = ccp(44, 13);
    }else{
        box.contentSize=CGS_BOX;
        box.position= POS_BOX;
	}
    
	////line
	CCSprite *line = [CCSprite spriteWithFile:@"images/ui/alert/line.png"];
	line.scale = SCALE_LINE/line.contentSize.width;
	[self addChild:line];
	line.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	
	////同屏玩家数量
	//CCLabelTTF *textSpr = [CCLabelTTF labelWithString:@"同屏玩家数量" fontName:getCommonFontName(FONT_1) fontSize:22];
    CCLabelTTF *textSpr = [CCLabelTTF labelWithString:NSLocalizedString(@"setting_players",nil) fontName:getCommonFontName(FONT_1) fontSize:22];
	textSpr.color = ccc3(250,170,20);
	textSpr.anchorPoint = ccp(0,0.5);
	[self addChild:textSpr];
    if (iPhoneRuningOnGame()) {
        textSpr.scale  = 0.6;
        textSpr.position=ccp(120, 130);
    }else{
        textSpr.position=POS_TEXTSPR_ONE;
	}
	
    NSString * maxString = [NSString stringWithFormat:NSLocalizedString(@"setting_show",nil),mapRolesMax];
	textSpr = [CCLabelTTF labelWithString:maxString fontName:getCommonFontName(FONT_1) fontSize:14];
	textSpr.anchorPoint = ccp(0,0.5);
	[self addChild:textSpr];
	
    if (iPhoneRuningOnGame()) {
        textSpr.scale  = 0.8;
        textSpr.position=ccp(280, 60);
    }else{
		textSpr.position=POS_TEXTSPR_THREE;
	}
	
    textSpr = [CCLabelTTF labelWithString:NSLocalizedString(@"setting_show_zero",nil) fontName:getCommonFontName(FONT_1) fontSize:14];
	textSpr.anchorPoint = ccp(0,0.5);
	[self addChild:textSpr];
	
    if (iPhoneRuningOnGame()) {
        textSpr.scale  = 0.8;
		textSpr.position=ccp(120, 60);
    }else{
        textSpr.position=POS_TEXTSPR_TWO;
	}
	
	//----------------------------------------------------------------------------

	menu = [CCMenu node];
	menu.ignoreAnchorPointForPosition = YES;
	menu.position = CGPointZero;
	[self addChild:menu z:1];
		
	//fix chao
	//	NSString *list[6]={@"绑定账号",@"常见问题",@"官 网",@"服务器列表",@"联系客服",@"论 坛","九游社区"};
	//
	//	float x_ = 150;
	//	float y_ = 340;
	//	for (int i = 0; i < 6 ; i++) {
	//		NSArray *array = getLabelSprites(@"images/ui/button/bt_background.png", @"images/ui/button/bt_background.png", list[i], 18, ccc4(65,197,186, 255), ccc4(65,197,186, 255));
	//        CCMenuItemImage *bt1 = [CCMenuItemImage itemWithNormalSprite:[array objectAtIndex:0]
	//                                                      selectedSprite:[array objectAtIndex:1]
	//                                                      disabledSprite:nil
	//                                                              target:self
	//                                                            selector:@selector(menuCallbackBack:)];
	//
	//		bt1.tag = PRIVATE_TAG + i;
	//		[menu addChild:bt1];
	//		bt1.position=ccp(x_ + 150*(i%3), y_ - 70*(i/3));
	//	}
	//{@"绑定账号",@"常见问题",@"官 网",@"服务器列表",@"联系客服",@"论 坛"};
	NSString *list[9]={
		@"btn_choose",//@"bt_bind",//切换角色 0
		@"bt_usual_question",//常见问题 1
		@"bt_official_net",//游戏专区(官网) 2
		@"bt_contact_serve",//联系客服 3
		@"bt_bbs",//游戏论坛 4
		@"btn_center",//91社区 5
		@"btn_uc",//九游社区 6
		@"btn_person_center",//个人中心 7		（7.13暂时pp，苹果园）
		@"btn_logout",//注销帐号 8
	};
	
	NSArray *listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"2",nil];
	
	//	float x_ = POS_BT1_START_X;
	//	float y_ = POS_BT1_START_Y;
	switch ([SNSHelper getHelperType]) {
		case 1:{
			listname=[NSArray arrayWithObjects:@"0",@"5",@"3",@"4",nil];
		};
			break;
		case 2:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"4",nil];
		};
			break;
			
		case 3:{
			
		}
			break;
			
		case 4:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"2",@"7",nil];
		}
			break;
		case 5:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"4",nil];
		}
			break;
		case 6:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"4",nil];
		}
			break;
		case 7:{
			listname=[NSArray arrayWithObjects:@"0",@"3",@"4",@"8",nil];
		}
			break;
		case 8:{
			listname=[NSArray arrayWithObjects:@"0",@"2",@"3",@"4",@"6",nil];
		}
			break;
		case 9:{
			listname=[NSArray arrayWithObjects:@"0",@"3",@"4",@"8",nil];
		}
			break;
		case 10:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"4",nil];
		}
			break;
		case 11:{
			listname=[NSArray arrayWithObjects:@"0",@"2",@"3",@"4",nil];
		}
			break;
		case 12:{
			listname=[NSArray arrayWithObjects:@"0",@"1",@"3",@"2",@"7",nil];
		}
			break;
		default:
			break;
	}
	
	for (int i = 0; i < listname.count ; i++) {
		NSString *btnName=list[[[listname objectAtIndex:i]intValue]];
		NSArray *array = getDisableBtnSpritesArrayWithStatus([NSString stringWithFormat:@"images/ui/button/%@",btnName]);
        CCMenuItemImage *bt1 = [CCMenuItemImage itemWithNormalSprite:[array objectAtIndex:0]
                                                      selectedSprite:[array objectAtIndex:1]
                                                      disabledSprite:[array objectAtIndex:2]
                                                              target:self
                                                            selector:@selector(menuCallbackBack:)];
		
		bt1.tag = PRIVATE_TAG + [[listname objectAtIndex:i]intValue];
		[menu addChild:bt1];
        if (iPhoneRuningOnGame()) {
            bt1.position=ccp(160 + 130*(i%3), 250 - 50*(i/3));
            bt1.scale = 1.3f;
        }else
            bt1.position=ccp(POS_BT1_START_X + POS_BT1_ADD_X*(i%3), POS_BT1_START_Y - POS_BT1_ADD_Y*(i/3));
	}
	/*
	//fix chao
	CCMenuItemImage *bt_usual_question = (CCMenuItemImage *)[menu getChildByTag:PRIVATE_TAG + 1];
	bt_usual_question.isEnabled = NO;
	CCMenuItemImage *bt_official_net = (CCMenuItemImage *)[menu getChildByTag:PRIVATE_TAG + 2];
	bt_official_net.isEnabled = NO;
	 */
	//end
	////游戏音效复选
	//NSArray *sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",@"游戏音效",SIZE_SPRARR,ccc4(255,255,255,255),ccc4(255,255,255,255) );
    NSArray *sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",NSLocalizedString(@"setting_sound",nil),SIZE_SPRARR,ccc4(255,255,255,255),ccc4(255,255,255,255) );
	CCMenuItemSprite *bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	CCMenuItemSprite *bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	CCMenuItemToggle * btt_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:bt_spr01,bt_spr02, nil];
	
	if([GameSoundManager shared].isPlayEffectMusic){
		btt_toggle.selectedIndex = 1;
	}else{
		btt_toggle.selectedIndex = 0;
	}
	
	[menu addChild:btt_toggle z:0 tag:BTT_NO_HIDE_GAMEMUSIC_TAG];
    if (iPhoneRuningOnGame()) {
        btt_toggle.position = ccp(410,120);
        btt_toggle.scale = 1.3f;
    }else
		btt_toggle.position = POS_BTT_TOGGLE_ONE;
	
	////游戏音效复选
	//sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",@"背景音乐",SIZE_SPRARR,ccc4(255,255,255,255),ccc4(255,255,255,255) );
    sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",NSLocalizedString(@"setting_music",nil),SIZE_SPRARR,ccc4(255,255,255,255),ccc4(255,255,255,255) );
	bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	
	btt_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:bt_spr01,bt_spr02, nil];
	
	if([GameSoundManager shared].isPlayBackgroundMusic){
		btt_toggle.selectedIndex = 1;
	}else{
		btt_toggle.selectedIndex = 0;
	}
	
	[menu addChild:btt_toggle z:0 tag:BTT_NO_HIDE_BG_GAMEMUSIC_TAG];
    if (iPhoneRuningOnGame()) {
        btt_toggle.position = ccp(410,60);
        btt_toggle.scale = 1.3f;
    }else
		btt_toggle.position = POS_BTT_TOGGLE_TWO;
	
	//plate line
	LoadSprite *plateLine = [LoadSprite node];
	[self addChild:plateLine z:1 tag:SettingPlateLoadTag];
	plateLine.anchorPoint = ccp(0,0.5);
    if (iPhoneRuningOnGame()) {
        plateLine.position =  ccp(120,85);
        plateLine.scale = 1.2;
    }else{
        plateLine.position = ccp(50,130);
	}
	[plateLine setLoadType:0];//
	
	//plate
	PlateSprite * plateSpr = [PlateSprite node];
	[self addChild:plateSpr z:1 tag:SettingPlateTag];
    if (iPhoneRuningOnGame()) {
        plateSpr.position = ccp(122,95);
        plateSpr.scale = 1.2;
    }else{
        plateSpr.position = ccp(55,138);
	}
	
	if (plateLine) {
		[plateSpr setTarger:self];
		[plateSpr setOffLen:plateLine.contentSize.width * plateLine.scale-WIDTH_PLATELINE_ADD];
		
		//[plateSpr setStartValue:mapRolesMax];//
		//[plateSpr setEndValue:0];//
		
		[plateSpr setStartValue:0];
		[plateSpr setEndValue:mapRolesMax];
		
		//[plateSpr setMoveToPosition:plateSpr.position];
		
	}
	[self setLoadWithValue:[RoleManager shared].maxPlayerCount];
	
	self.touchEnabled = YES;
	self.touchPriority = kCCMenuHandlerPriority-4;
	
	serviceTips = nil;
	//end
}
-(void)onExit{
	[super onExit];
}
-(void)setPlayersWithValue:(NSInteger)value{
	//TODO set players
	int val = value;
	val++;
}
////
-(void)setLoadWithValue:(NSInteger)value{
	LoadSprite *plateLine = (LoadSprite *)[self getChildByTag:SettingPlateLoadTag];
	PlateSprite *plateSpr = (PlateSprite *)[self getChildByTag:SettingPlateTag];
	[plateLine setLoadFloatValue:1.0*value/mapRolesMax];
	[plateSpr setValue:value];
	[self setPlayersWithValue:[plateSpr getNowValue]];
}

-(void)showServiceTips{
	
	if (serviceTips) {
		return;
	}
	serviceTips = [CCSprite node];
	
	//
	CCSprite *background = [StretchingImg stretchingImg:@"images/ui/bound.png" width:CGS_BACKGROUND_X height:CGS_BACKGROUND_Y capx:VALUE_CAPX capy:VALUE_CAPY];
	serviceTips.contentSize = background.contentSize;
	//
	[serviceTips addChild:background];
	background.position=ccp(serviceTips.contentSize.width/2, serviceTips.contentSize.height/2);
	//	int w = 20;
	//
//	CCLabelFX *label = [CCLabelFX labelWithString:@"客服QQ:2827896738"
//									   dimensions:CGSizeMake(0,0)
//										alignment:kCCTextAlignmentCenter
//										 fontName:getCommonFontName(FONT_1)
//										 fontSize:21
//									 shadowOffset:CGSizeMake(-1.5, -1.5)
//									   shadowBlur:1.0f
//									  shadowColor:ccc4(160,100,20, 128)
//										fillColor:ccc4(255, 255, 255, 255)];
    CCLabelFX *label = [CCLabelFX labelWithString:NSLocalizedString(@"setting_serve_qq",nil)
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(255, 255, 255, 255)];
	[serviceTips addChild:label];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(POS_LABEL_SERVICE_X,serviceTips.contentSize.height-POS_LABEL_QQ_ADD_Y);
	//
//	label = [CCLabelFX labelWithString:@"客服群号:295219450"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:getCommonFontName(FONT_1)
//							  fontSize:21
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f
//						   shadowColor:ccc4(160,100,20, 128)
//							 fillColor:ccc4(255, 255, 255, 255)];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"setting_serve_qq_bevy",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:getCommonFontName(FONT_1)
							  fontSize:21
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f
						   shadowColor:ccc4(160,100,20, 128)
							 fillColor:ccc4(255, 255, 255, 255)];
	[serviceTips addChild:label];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(POS_LABEL_SERVICE_X,serviceTips.contentSize.height-POS_LABEL_QQ_GROUP_Y);
	//
	//NSString *str = [NSString stringWithFormat:@"客服email:%@",MAIL_STRING];
    NSString *str = [NSString stringWithFormat:NSLocalizedString(@"setting_serve_email",nil),MAIL_STRING];
	label = [CCLabelFX labelWithString:str
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:getCommonFontName(FONT_1)
							  fontSize:21
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f
						   shadowColor:ccc4(160,100,20, 128)
							 fillColor:ccc4(255, 255, 255, 255)];
	//[serviceTips addChild:label];
	label.anchorPoint = ccp(0,0.5);
	//label.position = ccp(w,serviceTips.contentSize.height-130);
	label.position = ccp(0,POS_LABEL_EMAIL_Y);
	
	CCSimpleButton *email_button = [CCSimpleButton node];
	email_button.touchScale = 1.0f;
	email_button.anchorPoint = ccp(0.5,0.5);
	email_button.priority=-255;
	email_button.contentSize = CGSizeMake(label.contentSize.width, CGS_EMAIL_BUTTON_Y);
	email_button.position = ccp(serviceTips.contentSize.width/2-POS_EMAIL_BUTTON_ADD_X,POS_EMAIL_BUTTON_Y);
	email_button.target = self;
	email_button.call = @selector(sendEmail);
	[email_button addChild:label];
	[serviceTips addChild:email_button];
	
	CCSimpleButton *yes_button = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_ok_1.png"
														 select:@"images/ui/button/bt_ok_2.png"
														 target:self
														   call:@selector(servicTipsCall)];
	yes_button.priority=-255;
	yes_button.position=ccp(serviceTips.contentSize.width/2,POS_YES_BUTTON_ADD_Y);
	[serviceTips addChild:yes_button];
	//
	
	[self addChild:serviceTips z:INT32_MAX];
	serviceTips.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	
}
-(void)servicTipsCall{
	if (serviceTips) {
		[serviceTips removeFromParentAndCleanup:YES];
		serviceTips = nil;
	}
}
-(void)sendEmail{
	[self servicTipsCall];
	
	//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://efunzl@qq.com"]];
	NSString *str = [NSString stringWithFormat:@"mailto://%@",MAIL_STRING];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}

-(void)menuCallbackBack:(id)sender{
	
	CCLOG(@"SettingPanel:menuCallbackBack");
	CCNode *temp = (CCNode*)sender;
//	if (temp.tag == BT_CLOSE_WIN_TAG) {
//		[[Window shared] removeWindow:PANEL_SETTING];
//	}
	
	if(serviceTips) return;
	
	if (temp.tag == PRIVATE_TAG) {
		//绑定账号
		//fix chao
		//if ([[TaskManager shared] checkCanSwitchingAccounts]) {
		[[TaskManager shared] stopTask];
		[[Window shared] removeWindow:PANEL_SETTING];
		[GameStart list];
		//}
		//end
		CCLOG(@"绑定账号");
		
	}
	else if (temp.tag == (PRIVATE_TAG+1)) {
		//常见问题
		CCLOG(@"常见问题");
		bool isOk = NO;
		switch ([SNSHelper getHelperType]) {
			case 2:{
				isOk = YES;
                //[InAppBrowser show:@"http://zl.52yh.com/xszn.html" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			case 4:{
				isOk = YES; 
                //[InAppBrowser show:@"http://zl.52yh.com/xszn.html" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			case 5:{
				isOk = YES; 
                //[InAppBrowser show:@"http://zl.52yh.com/xszn.html" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			case 6:{
				isOk = YES; 
                //[InAppBrowser show:@"http://zl.52yh.com/xszn.html" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			case 10:{
				isOk = YES; 
                //[InAppBrowser show:@"http://bbs.tongbu.com/forum.php?mod=viewthread&tid=110051&extra=" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			case 12:{
				isOk = YES; 
                //[InAppBrowser show:@"http://zl.52yh.com/xszn.html" title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
				break;
			default:
				break;
		}
		
		if (isOk) {
			NSDictionary* uDict = [[GameConnection share].serverInfo objectForKey:@"cliUrls"];
			NSDictionary* mDict = [uDict objectForKey:[NSString stringWithFormat:@"%d",[SNSHelper getHelperType]]];
			NSString* mUrl = [mDict objectForKey:@"faq"];
			if (mUrl && mUrl.length > 0) {
				[InAppBrowser show:mUrl title:NSLocalizedString(@"setting_familiar_questions",nil)];
			}
		}
		
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:GAME_URL_HELP]];
	}
	else if (temp.tag == (PRIVATE_TAG+2)) {
		//游戏专区（官网）
		CCLOG(@"游戏专区（官网）");
		//[[SNSHelper shared] enterUserCenter];
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:GAME_URL_HOME]];
		//[[SNSHelper shared] purchase:nil info:nil];
		bool isOk = NO;
		switch ([SNSHelper getHelperType]) {
			case 2:{
				isOk = YES ;
                //[InAppBrowser show:@"http://zl.52yh.com/index.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			case 4:{
				isOk = YES ;
                //[InAppBrowser show:@"http://bbs.996.com/forum-zdzl-1.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			case 5:{
				isOk = YES ;
                //[InAppBrowser show:@"http://zl.52yh.com/index.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			case 8:{
				isOk = YES ;
                //[InAppBrowser show:@"http://i.9game.cn/game/detail_516088.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			case 11:{
				isOk = YES ;
				//[InAppBrowser show:@"http://ng.d.cn/game/detail_839.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			case 12:{
				isOk = YES ;
                //[InAppBrowser show:@"http://bbs.996.com/forum-zdzl-1.html" title:NSLocalizedString(@"setting_office_net",nil)];
			}
				break;
			default:
				break;
		}
		
		if (isOk) {
			NSDictionary* uDict = [[GameConnection share].serverInfo objectForKey:@"cliUrls"];
			NSDictionary* mDict = [uDict objectForKey:[NSString stringWithFormat:@"%d",[SNSHelper getHelperType]]];
			NSString* mUrl = [mDict objectForKey:@"web"];
			if (mUrl && mUrl.length > 0) {
				[InAppBrowser show:mUrl title:NSLocalizedString(@"setting_office_net",nil)];
			}
		}
		
	}
	else if (temp.tag == (PRIVATE_TAG+3)) {
		//联系客服
		CCLOG(@"联系客服");
		
		//[self showServiceTips];
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:GAME_URL_SERVICE]];
#if GAME_SNS_TYPE == 1
		[[SNSHelper shared] userFeedback];
#else
		//todo
		[[Window shared] removeWindow:PANEL_SETTING];
		[[GameReporter shared] show];
#endif
		
	}
	else if (temp.tag == (PRIVATE_TAG+4)) {
		//游戏论坛
		CCLOG(@"游戏论坛");
		//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:GAME_URL_BBS]];
		//[InAppBrowser show:GAME_URL_BBS title:@"论坛"];
        bool isOk = NO;
		switch ([SNSHelper getHelperType]) {
			case 1:{
				isOk = YES ;
				//[InAppBrowser show:GAME_URL_BBS title:NSLocalizedString(@"setting_bbs",nil)];
			};
				break;
			case 2:{
				isOk = YES ;
				//[InAppBrowser show:@"http://zl.52yh.com/" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 4:{
				isOk = YES ;
				//[InAppBrowser show:@"http://bbs.9game.cn/forum-1070-1.html" title:NSLocalizedString(@"setting_bbs",nil)];
			};
				break;
			case 5:{
				isOk = YES ;
				//[InAppBrowser show:@"http://zl.52yh.com/" title:NSLocalizedString(@"setting_bbs",nil)];
			};
				break;
			case 6:{
				isOk = YES ;
				//[InAppBrowser show:@"http://zl.52yh.com/" title:NSLocalizedString(@"setting_bbs",nil)];
			};
				break;
			case 7:{
				isOk = YES ;
				//[InAppBrowser show:@"http://mbbs.gao7.com/pingcelist.php?fid=201" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 8:{
				isOk = YES ;
                //[InAppBrowser show:@"http://bbs.9game.cn/forum-1070-1.html" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 9:{
				isOk = YES ;
				//[InAppBrowser show:@"http://http://mbbs.gao7.com/pingcelist.php?fid=201" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 10:{
				isOk = YES ;
                //[InAppBrowser show:@"http://bbs.tongbu.com/forum-65-1.html" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 11:{
				isOk = YES ;
				//[InAppBrowser show:@"http://bbs.d.cn/topic_list_all_9235.html" title:NSLocalizedString(@"setting_bbs",nil)];
			}
				break;
			case 12:{
				isOk = YES ;
				//[InAppBrowser show:@"http://bbs.9game.cn/forum-1070-1.html" title:NSLocalizedString(@"setting_bbs",nil)];
			};
				break;
			default:
				break;
		}
		
		if (isOk) {
			NSDictionary* uDict = [[GameConnection share].serverInfo objectForKey:@"cliUrls"];
			NSDictionary* mDict = [uDict objectForKey:[NSString stringWithFormat:@"%d",[SNSHelper getHelperType]]];
			NSString* mUrl = [mDict objectForKey:@"bbs"];
			if (mUrl && mUrl.length > 0) {
				[InAppBrowser show:mUrl title:NSLocalizedString(@"setting_bbs",nil)];
			}
		}
		
	}
	else if (temp.tag == (PRIVATE_TAG+5)) {
		//91社区
		CCLOG(@"91社区");
		[[SNSHelper shared] enterUserCenter];
	}
	else if (temp.tag == (PRIVATE_TAG+6)) {
		//九游社区
		CCLOG(@"九游社区");
		[[SNSHelper shared] enterUserCenter];
	}
	else if (temp.tag == (PRIVATE_TAG+7)) {
		//个人中心
		CCLOG(@"个人中心");
		[[SNSHelper shared] enterUserCenter];
	}
	else if (temp.tag == (PRIVATE_TAG+8)) {
		// 注销帐号
		CCLOG(@"注销帐号");
		[[AlertManager shared] showMessage:NSLocalizedString(@"setting_confirm_logout",nil) target:self confirm:@selector(logoutConfirm) canel:nil];
	}
	
	if(temp.tag==BTT_NO_HIDE_GAMEMUSIC_TAG){
		CCLOG(@"BTT_NO_HIDE_GAMEMUSIC_TAG");
		[GameSoundManager shared].isPlayEffectMusic = ![GameSoundManager shared].isPlayEffectMusic;
	}
	if(temp.tag==BTT_NO_HIDE_BG_GAMEMUSIC_TAG){
		CCLOG(@"BTT_NO_HIDE_BG_GAMEMUSIC_TAG");
		[GameSoundManager shared].isPlayBackgroundMusic = ![GameSoundManager shared].isPlayBackgroundMusic;
	}
	
}

-(void)logoutConfirm
{
	[[SNSHelper shared] logout];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	
    if (isTouch) {
        return NO;
    }
    isTouch = YES;
    
	if(serviceTips){
		return NO;
	}
	
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	isPlateTouch = NO;
	isMenuTouch = NO;
	
	CGRect r = CGRectMake( _position.x - _contentSize.width*_anchorPoint.x,
						  _position.y - _contentSize.height*_anchorPoint.y,
						  _contentSize.width, _contentSize.height);
	r.origin = CGPointZero;
	if( CGRectContainsPoint( r, touchLocation ) ){
		CCLOG(@"setting began");
		if ( [menu ccTouchBegan:touch withEvent:event] ) {
			CCLOG(@"setting menu ccTouchBegan");
			isMenuTouch = YES;
			return YES;
		}
		PlateSprite *spr = (PlateSprite *)[self getChildByTag:SettingPlateTag];
		if (spr) {
			CGPoint pos = [spr convertTouchToNodeSpace:touch];
			if (pos.x>=0 && pos.y>=0 && pos.x<spr.contentSize.width && pos.y<spr.contentSize.height) {
				isPlateTouch = YES;
				spr.scale = 1.2;
				return YES;
			}
		}
		return YES;
	}
	return NO;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	CCLOG(@"setting moveing");
	if ( isMenuTouch ) {
		[menu ccTouchMoved:touch withEvent:event];
		CCLOG(@"setting menu ccTouchMoved");
	}
	if (isPlateTouch) {
		PlateSprite *spr = (PlateSprite *)[self getChildByTag:SettingPlateTag];
		LoadSprite *plateLine = (LoadSprite *)[self getChildByTag:SettingPlateLoadTag];
		if (spr) {
			
			[spr setMoveToPosition:touchLocation];
			[plateLine setLoadFloatValue:1.0*[spr getNowValue]/mapRolesMax];
			
			// spr.position = touchLocation;
		}
	}
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ( isMenuTouch ) {
		[menu ccTouchEnded:touch withEvent:event];
		CCLOG(@"setting menu ccTouchEnded");
	}
	if (isPlateTouch) {
		PlateSprite *spr = (PlateSprite *)[self getChildByTag:SettingPlateTag];
		if (spr) {
			spr.scale = 1;
		}
		[RoleManager shared].maxPlayerCount = [spr getNowValue];
	}
	isTouch = NO;
	CCLOG(@"setting ccTouchEnded");
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isTouch) {
        if ( isMenuTouch ) {
            [menu ccTouchCancelled:touch withEvent:event];
            CCLOG(@"setting menu ccTouchEnded");
        }
        if (isPlateTouch) {
            PlateSprite *spr = (PlateSprite *)[self getChildByTag:SettingPlateTag];
            if (spr) {
                spr.scale = 1;
            }
            [RoleManager shared].maxPlayerCount = [spr getNowValue];
        }
        isTouch = NO;
    }
}
@end
