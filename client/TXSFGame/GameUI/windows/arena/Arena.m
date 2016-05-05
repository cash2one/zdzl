//
//  Arena.m
//  TXSFGame
//
//  Created by Max on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Arena.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "GameMoneyMini.h"
#import "RoleThumbViewerContent.h"
#import "InfoAlert.h"
#import "RolePlayer.h"
#import "UnionManager.h"
#import "MapManager.h"
#import "PlayerSit.h"

//fix chao
@interface CCPanel(CCPanelPrivate)
-(void)addContent:(CCNode*)_layer;
-(void)setView:(CGPoint)_vPotion :(CGSize)_vSize;
@end

@interface CCPanelEx:CCPanel
+(CCPanelEx*)panelWithContent:(CCNode *)_content viewSize:(CGSize)_vSize;
+(CCPanelEx*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize;
@end

@implementation CCPanelEx
+(CCPanelEx*)panelWithContent:(CCNode *)_content viewSize:(CGSize)_vSize{
	return [CCPanelEx panelWithContent:_content viewPosition:CGPointZero viewSize:_vSize];
}

+(CCPanelEx*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize{
	CCPanelEx *m_Panel = [CCPanelEx node];
	[m_Panel setView:_vPotion :_vSize];
	[m_Panel addContent:_content];
	return m_Panel;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
//    if ([[Window shared] isHasWindow]) {
//        return NO;
//    }
    return [super ccTouchBegan:touch withEvent:event];
}
@end
//end






@implementation Arena

#define PosX self.contentSize.width
#define PosY self.contentSize.height
#define COLORYELLOW1 ccc3(255 ,235 ,123)
#define COLORYELLOW1XF @"FFEB7B"
#define COLORYELLOW2 ccc3(234, 178, 59)
#define ARENEBASECONTENTHIGHT 175
#define BG_MOMEY 0
#define BTN_BACK 1
#define BTN_BUY 2
#define BG_REWARKTIPS 3



#define  VALUE_FONT_SIZE  16
#define VALUE_FONT_SIZE_curRank  20


static Arena* arena;
static int currenFid;
static NSString *fightSub;
static bool fightisWin;
static bool isOpen;

+(Arena*)share{
	if(!arena){
		arena=[Arena node];
	}
	return arena;
}

+(BOOL)arenaIsOpen{
	return isOpen;
}

/*
+(void)quitArena{
	[[TaskPattern shared] setVisible:YES];
	if(!arena){
		return;
	}
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
	[arena removeFromParentAndCleanup:true];
	arena = nil ;
	isOpen=false;
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:[Arena class]];
	
}
*/

+(void)enterArena{
	if([MapManager shared].mapId!=1007){
		[[Game shared]trunToMap:1007];
		return;
	}
}

-(void)onEnter{
	[super onEnter];
    isSend = NO;
	arena=self;
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];
	[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:NO];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];
	{
//		if ([fightSub length]>1) {
//			if (fightisWin) {
//				NSString *var=[NSString stringWithFormat:@"isOK::1|rid::%i|fp:%@",currenFid,fightSub];
//				[GameConnection request:@"arenaEnd" format:var target:[Arena share] call:@selector(requestConnection:)];
//			}else{
//				NSString *var=[NSString stringWithFormat:@"isOK::0|rid::%i|fp:%@",currenFid,fightSub];
//				[GameConnection request:@"arenaEnd" format:var target:[Arena share] call:@selector(requestConnection:)];
//			}
//			[fightSub release];
//			fightSub=nil;
//		}
		
		[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-1 swallowsTouches:YES];
		CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/arena/bg.jpg" ];
		CCSimpleButton *btn_back=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_back.png"];
		[btn_back setPriority:-128];
		CCSimpleButton *btn_buyPractice=[CCSimpleButton spriteWithFile:@"images/ui/arena/btn_buy1.png" select:@"images/ui/arena/btn_buy2.png" target:self call:@selector(btnCallBack:)];
		[btn_buyPractice setTag:BTN_BUY];
		
		CCSimpleButton *btn_openreward=[CCSimpleButton spriteWithFile:@"images/ui/arena/btn_openreward.png"];
        [btn_openreward setPriority:-128];
		CCSimpleButton *btn_openrank=[CCSimpleButton spriteWithFile:@"images/ui/arena/btn_openrank.png"];
		[btn_openrank setPriority:-128];
        
		playerListBg=[CCSprite spriteWithFile:@"images/ui/arena/playerlist.png"];
		CCSprite *titlebg=[StretchingImg stretchingImg:@"images/ui/arena/titlebg.png" width:cFixedScale(680) height: 1 capx: cFixedScale(108) capy:cFixedScale(1)];
		CCSprite *figthsubbg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(500) height:cFixedScale(230) capx:cFixedScale(8) capy:cFixedScale(8)];
		CCSprite *line=[CCSprite spriteWithFile:@"images/ui/common/line.png"];
		//CCLabelTTF *figthsubtitle=[CCLabelTTF labelWithString:@"战报列表" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
        CCLabelTTF *figthsubtitle=[CCLabelTTF labelWithString:NSLocalizedString(@"arena_fight_list",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
		labelRank=[CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(14)];
		labelgetPractice=[CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(14)];
		labelmoney=[CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(15)];
		labelPractice=[CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(15)];
		labelPlayTime=[CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(15)];
		//战报输出窗口
		content=[CCLayerColor layerWithColor:ccc4(100, 33, 33, 100) width:cFixedScale(470) height:cFixedScale(ARENEBASECONTENTHIGHT)];
		subPanel=[CCPanel panelWithContent:content viewSize:CGSizeMake(cFixedScale(470), cFixedScale(ARENEBASECONTENTHIGHT))];
		[labelRank setColor:COLORYELLOW1];
		[labelgetPractice setColor:COLORYELLOW1];
		[figthsubtitle setColor:COLORYELLOW2];
		[labelmoney setColor:ccWHITE];
		[labelPractice setColor:ccWHITE];
		[labelPlayTime setColor:ccWHITE];
		
		[btn_back setTag:BTN_BACK];
		[btn_back setTarget:self];
		[btn_openreward setTarget:self];
		[btn_openrank setTarget:self];
		
		[btn_back setCall:@selector(btnCallBack:)];
		[btn_openreward setCall:@selector(openReward)];
		[btn_openrank setCall:@selector(openRank)];
		
		
		[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
        if (iPhoneRuningOnGame()) {
            btn_back.anchorPoint = ccp(0.5,0.25);
            btn_back.contentSize = CGSizeMake(btn_back.contentSize.width, btn_back.contentSize.height*2);
        }
		[btn_back setPosition:ccp(self.contentSize.width-cFixedScale(50), self.contentSize.height-cFixedScale(30))];
		[btn_openreward setPosition:ccp(self.contentSize.width-cFixedScale(130+FULL_WINDOW_RULE_OFF_X2), self.contentSize.height-cFixedScale(30))];
		[btn_openrank setPosition:ccp(self.contentSize.width-cFixedScale(220+FULL_WINDOW_RULE_OFF_X2), self.contentSize.height-cFixedScale(30))];
		[playerListBg setPosition:ccp(self.contentSize.width/2, cFixedScale(480))];
		[titlebg setPosition:ccp(playerListBg.contentSize.width/2, playerListBg.contentSize.height)];
		[figthsubbg setPosition:ccp(cFixedScale(680), cFixedScale(210))];
		[line setPosition:ccp(figthsubbg.contentSize.width/2, cFixedScale(190))];
		[figthsubtitle setPosition:ccp(figthsubbg.contentSize.width/2, cFixedScale(210))];
		[labelRank setPosition:ccp(titlebg.contentSize.width/2, titlebg.contentSize.height/2)];
		
		
		[labelgetPractice setPosition:ccp(cFixedScale(420), titlebg.contentSize.height/2)];
		[labelmoney setPosition:ccp(cFixedScale(220), cFixedScale(40))];
		[labelPractice setPosition:ccp(cFixedScale(400), cFixedScale(40))];
		[labelPlayTime setPosition:ccp(cFixedScale(720), cFixedScale(40))];
		[subPanel setPosition:ccp(cFixedScale(15), cFixedScale(10))];
		[btn_buyPractice setPosition:ccp(cFixedScale(870), cFixedScale(40))];
		
		
		[line setScaleX:0.5];
		
		//Kevin added
		if (iPhoneRuningOnGame()) {
			btn_buyPractice.scale = 1.3f;
			playerListBg.scale=1.08f;
		}
		//-----------------------//
		
		[btn_back setTarget:self];
		[btn_back setCall:@selector(btnCallBack:)];

		[self addChild:bg];
		[self addChild:btn_back];
		[self addChild:btn_openreward];
		[self addChild:btn_openrank];
		[self addChild:playerListBg];
		[self addChild:figthsubbg];
		[figthsubbg addChild:line];
		[figthsubbg addChild:figthsubtitle];
		[figthsubbg addChild:subPanel];
		[titlebg addChild:labelRank];
		[titlebg addChild:labelgetPractice];
		[playerListBg addChild:titlebg];
		[playerListBg addChild:labelmoney];
		[playerListBg addChild:labelPractice];
		[playerListBg addChild:labelPlayTime];
		[playerListBg addChild:btn_buyPractice];
		subPanel.stealTouches=YES;
		[GameConnection addPost:@"OPF" target:self call:@selector(openFightRecord:)];
        // 规则
        //fix chao
        RuleButton *ruleButton = [RuleButton node];
        ruleButton.position = ccp(btn_back.position.x- cFixedScale(FULL_WINDOW_RULE_OFF_X2), btn_back.position.y-cFixedScale(WINDOW_RULE_OFF_Y));
        ruleButton.type = RuleType_fight;
        ruleButton.priority = -128;
        [self addChild:ruleButton];
        //end
		
		//Kevin added, adjust to iphone
		if (iPhoneRuningOnGame()) {
			labelRank.fontSize = 10;
			labelmoney.fontSize = 9;
			labelPractice.fontSize = 9;
			labelPractice.position = ccpAdd(labelPractice.position, ccp(20, 0));
			labelPlayTime.fontSize = 9;
			playerListBg.position = ccpAdd(playerListBg.position, ccp(0,-40));
			figthsubbg.position = ccpAdd(figthsubbg.position, ccp(0,-45));
		}
		//---------------------------------//
	}
	//小型金钱窗口 及标题
	{
		//fix chao
		GameMoneyMini *moneyBox=[GameMoneyMini node];
		[moneyBox setAnchorPoint:ccp(0,1)];
		[moneyBox setPosition:ccp(0, self.contentSize.height)];
		[self addChild:moneyBox];
	}
    NSDictionary *dict=	[[GameDB shared] getGlobalConfig];
	NSArray *mp=[[dict objectForKey:@"arenaMaxReward"]componentsSeparatedByString:@"|"];
	canGetmoney=[[mp objectAtIndex:0]integerValue];
	canPractice=[[mp objectAtIndex:1]integerValue];
	arenaYB=[[dict objectForKey:@"arenaYB"]integerValue];
	[GameConnection request:@"arenaEnter" format:@"" target:self call:@selector(requestConnection:)];
	[subPanel updateContentToTop];
    
    //end
}

-(void)onExit{
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
	[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
	[GameConnection removePostTarget:self];
	//fix chao
	[NSTimer cancelPreviousPerformRequestsWithTarget:[Arena class]];
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];

	[GameConnection freeRequest:self];
	
    //end
	[super onExit];
}

-(void)dealloc{
	CCLOG(@"Arena dealloc!!!!!");
	[arena release];
	arena=nil;
	[super dealloc];
}


#pragma mark 网络请求回调
-(void)requestConnection:(NSDictionary*)dict{
	CCLOG(@"%@",dict);

	//进入竞技场
	if([[dict objectForKey:@"s"]integerValue]==1 && [[dict objectForKey:@"f"]isEqual:@"arenaEnter"]){ 
		//CCLOG(@"%@",dict);
		NSDictionary *data=[dict objectForKey:@"d"];
		currenRank=[[data objectForKey:@"rk"]integerValue];
		todayCanPlayTime=[[data objectForKey:@"c"]integerValue];
		
		//NSArray *money=[[data objectForKey:@"coin1"] objectAtIndex:0];
		canGetmoney=[[[data objectForKey:@"coin1"] objectAtIndex:0]integerValue];
		todayCanGetmoney=[[[data objectForKey:@"coin1"] objectAtIndex:1]integerValue];
		
		//NSArray *practice=[[data objectForKey:@"train"] componentsSeparatedByString:@"|"];
		canPractice=[[[data objectForKey:@"train"] objectAtIndex:0]integerValue];
		todayCanGetPractice=[[[data objectForKey:@"train"] objectAtIndex:1]integerValue];
		
		//labelRank.string=[NSString stringWithFormat:@"当前排名%i",currenRank];
        labelRank.string=[NSString stringWithFormat:NSLocalizedString(@"arena_rank_list",nil),currenRank];
		labelgetPractice.string=[NSString stringWithFormat:@"",getPracticeTime];
		//labelmoney.string=[NSString stringWithFormat:@"今日可得银币:%i/%i",canGetmoney,todayCanGetmoney];
        labelmoney.string=[NSString stringWithFormat:NSLocalizedString(@"arena_get_money",nil),canGetmoney,todayCanGetmoney];
		//labelPractice.string=[NSString stringWithFormat:@"炼历:%i/%i",canPractice,todayCanGetPractice];
        labelPractice.string=[NSString stringWithFormat:NSLocalizedString(@"arena_practice",nil),canPractice,todayCanGetPractice];
		//labelPlayTime.string=[NSString stringWithFormat:@"剩余挑战次数%i",todayCanPlayTime];
		labelPlayTime.string=[NSString stringWithFormat:NSLocalizedString(@"arena_dare_time",nil),todayCanPlayTime];
        
		int selfplayid=[[[[GameConfigure shared]getPlayerInfo] objectForKey:@"id"]integerValue];
		NSArray *rolearray=[data objectForKey:@"rivals"];
		for(int i=0;i<rolearray.count; i++) {
			NSDictionary *role=[rolearray objectAtIndex:i];
			int rid=[[role objectForKey:@"rid"]integerValue];
			int playid=[[role objectForKey:@"pid"]integerValue];
			NSString *rank=[NSString stringWithFormat:@"%@",[role objectForKey:@"rk"]];
			NSString *name=[role objectForKey:@"n"];
			CCLabelTTF *namelabel=[CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(12)];
			
			//Kevin added
			int frontSize = 18;
			if (iPhoneRuningOnGame()) {
				frontSize = 20;
			}
			//-------------------------//
			
			CCSprite *ranklabel=drawString(rank, CGSizeMake(100,1), getCommonFontName(FONT_2), frontSize, frontSize +2, @"ffffff");
			if (playid==selfplayid) {
				ranklabel=drawString(rank, CGSizeMake(100, 1), getCommonFontName(FONT_2), frontSize, frontSize +2, @"ffeb7b");
			}
			
			//CCSprite *rolebg=[CCSprite spriteWithFile:path];
			CCSprite *rolebg=[RoleThumbViewerContent create:rid];
			
			CCSimpleButton *b=[CCSimpleButton spriteWithFile:@"images/ui/arena/role_btn1.png" select:@"images/ui/arena/role_btn2.png"];
			NSString *playidobj=[NSString stringWithFormat:@"%i",playid];
			[b setUserObject:playidobj];
			
			[b setPosition:ccp(cFixedScale(i*130+200), cFixedScale(150))];
			[rolebg setPosition:ccp(cFixedScale(i*130+200), cFixedScale(140))];
			[ranklabel setPosition:ccp(rolebg.contentSize.width/2, rolebg.contentSize.height+cFixedScale(30))];
			[namelabel setPosition:ccp(rolebg.contentSize.width/2, rolebg.contentSize.height+cFixedScale(10))];
			[namelabel setColor:ccc3(49, 17, 7)];
			[rolebg addChild:ranklabel];
			[rolebg addChild:namelabel];
			[playerListBg addChild:b];
			[playerListBg addChild:rolebg z:INT32_MAX];
			int meid=[[[[GameConfigure shared]getPlayerInfo ]objectForKey:@"id"]integerValue];
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				namelabel.fontSize = 9;
				//ranklabel.scale = 1.2f;
			}
			//--------------------------//
			
			if(playid!=meid){
				
				int CBE=0;
				if(![[role objectForKey:@"CBE"] isKindOfClass:[NSNull class]]){
					CBE=[[role objectForKey:@"CBE"]integerValue];
				}
				
				[b setTarget:self];
				[b setCall:@selector(btnCallBackFigth:)];
				CCSprite *fp=[CCSprite spriteWithFile:@"images/ui/arena/label_fpower.png"];
				[fp setAnchorPoint:ccp(0, 0)];
				
				//Kevin added
				int fontSize = 14;
				if (iPhoneRuningOnGame()) {
					fontSize = 18;
				}
				//-------------------------------//
				
				CCSprite *label_fpower=drawString([NSString stringWithFormat:@"%i",CBE], CGSizeMake(200, 30), getCommonFontName(FONT_1), fontSize,fontSize+2, @"ffffff");
				[label_fpower setAnchorPoint:ccp(0.5, 0)];
				[label_fpower setPosition:ccp(rolebg.contentSize.width/2, 0)];
				
				int level=[[role objectForKey:@"level"]integerValue];
				CCLabelAtlas *level_label= [CCLabelAtlas labelWithString:[NSString stringWithFormat:@"%i",level] charMapFile:@"images/ui/arena/level_images.png" itemWidth:cFixedScale(12) itemHeight:cFixedScale(16) startCharMap:'0'];
				[level_label setPosition:ccp(cFixedScale(23), rolebg.contentSize.height)];
				[level_label setAnchorPoint:ccp(0, 1)];
				
				[rolebg addChild:fp];
				[rolebg addChild:label_fpower z:INT32_MAX];
				[rolebg addChild:level_label z:INT32_MAX];
				
				//Kevin added
				if (iPhoneRuningOnGame()) {
					//label_fpower.scale = 1.2f;
					level_label.scale = 1.2f;
					label_fpower.position = ccpAdd(label_fpower.position, ccp(0, -2));
				}
				//--------------------------//
				
			}else{
				CCSprite *fp=[CCSprite spriteWithFile:@"images/ui/arena/label_fpower.png"];
				[fp setAnchorPoint:ccp(0, 0)];
				
				//Kevin added
				int frontSize = 14;
				if (iPhoneRuningOnGame()) {
					frontSize = 18;
				}
				//-----------------------------//
								
				int __value = [[GameConfigure shared] getTotalPowerResult];
				CCSprite *label_fpower=drawString([NSString stringWithFormat:@"%i",__value], CGSizeMake(200, 30), getCommonFontName(FONT_1),frontSize, frontSize+2, @"ffffff");
				[label_fpower setAnchorPoint:ccp(0.5, 0)];
				[label_fpower setPosition:ccp(rolebg.contentSize.width/2, 0)];
				
				int level=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"level"]integerValue];
				CCLabelAtlas *level_label= [CCLabelAtlas labelWithString:[NSString stringWithFormat:@"%i",level] charMapFile:@"images/ui/arena/level_images.png" itemWidth:cFixedScale(12)  itemHeight:cFixedScale(16)  startCharMap:'0'];
				
				[level_label setPosition:ccp(cFixedScale(23), rolebg.contentSize.height)];
				
				[level_label setAnchorPoint:ccp(0, 1)];
				
				[rolebg addChild:fp];
				[rolebg addChild:label_fpower z:INT32_MAX];
				[rolebg addChild:level_label z:INT32_MAX];
				
				//Kevin added
				if (iPhoneRuningOnGame()) {
					//label_fpower.scale = 1.2f;
					level_label.scale = 1.2f;
					label_fpower.position = ccpAdd(label_fpower.position, ccp(0, -2));
				}
				//--------------------------//
			}
			
		}
		NSArray *logs=[data objectForKey:@"logs"];
		int h=0;
        int fontSize = VALUE_FONT_SIZE;
		int rectH=1;
		float lineH=18;
		//Kevin added
		if (iPhoneRuningOnGame()) {
			fontSize = 18;
			rectH=5;
			lineH=20;
		}
		//---------------------------------//
		int reportCount = 0;														//Kevin added
		for(NSDictionary *dict in logs){
			//NSString *time=timestmpToTime([dict objectForKey:@"ct"], @"MM月dd日 HH:mm");
            NSString *time=timestmpToTime([dict objectForKey:@"ct"], NSLocalizedString(@"arena_time_format",nil));
			NSString *rival=[NSString stringWithFormat:@"%@#4a8eca#%d#2#PEP%@",[dict objectForKey:@"n"],fontSize,[dict objectForKey:@"n"]];
			int t=[[NSString stringWithFormat:@"%@",[dict objectForKey:@"t"]]integerValue];
			int fid=[[dict objectForKey:@"fid"]integerValue];
			int rank=[[dict objectForKey:@"rk"]integerValue];
			//NSString *fidstr=[NSString stringWithFormat:@"战报#4a8eca#%d#2#OPF%i",fontSize,fid];
            NSString *fidstr=[NSString stringWithFormat:NSLocalizedString(@"arena_dispatches",nil),fontSize,fid];
			NSString *to=@"";
			NSString *tost=@"";
			if(t<3){
				//to=[NSString stringWithFormat:@"你挑战|%@",rival];
                to=[NSString stringWithFormat:NSLocalizedString(@"arena_dare_to",nil),rival];
				//tost=t==1?[NSString stringWithFormat:@" 你胜利了 排名升至%i ",rank]:[NSString stringWithFormat:@"你失败了 排名降至%i ",rank];
                tost=t==1?[NSString stringWithFormat:NSLocalizedString(@"arena_win",nil),rank]:[NSString stringWithFormat:NSLocalizedString(@"arena_lose",nil),rank];
			}else{
				//to=[NSString stringWithFormat:@"你被|%@|挑战 ",rival];
                to=[NSString stringWithFormat:NSLocalizedString(@"arena_dared",nil),rival];
				//tost=t==3?[NSString stringWithFormat:@"你胜利了 排名升至%i ",rank]:[NSString stringWithFormat:@"你失败了 排名降至%i ",rank];
                tost=t==3?[NSString stringWithFormat:NSLocalizedString(@"arena_win",nil),rank]:[NSString stringWithFormat:NSLocalizedString(@"arena_lose",nil),rank];
			}
			NSString *msg=[NSString stringWithFormat:@"%@ |%@|%@|%@",time,to,tost,fidstr];
			CCSprite *l=drawString(msg, CGSizeMake(450, rectH), getCommonFontName(FONT_1), fontSize, lineH, @"ffffff");
			[l setAnchorPoint:ccp(0, 0)];
			[l setPosition:ccp(0, h-cFixedScale(2))];											//Kevin fixed,	before [l setPosition:ccp(0, h)];
			h+= l.contentSize.height;
			[content setContentSize:CGSizeMake(content.contentSize.width,h<cFixedScale(ARENEBASECONTENTHIGHT)?ARENEBASECONTENTHIGHT:h)];
			[content addChild:l];
			reportCount++;														//Kevin added
		}
		
		//Kevin added
		if (iPhoneRuningOnGame()) {
			if (reportCount <= 4) {
				[subPanel updateContentToBottom];
			}
			else
			{
				[subPanel updateContentToTop];
			}
		}
		//Kevin modified
		else
			[subPanel updateContentToTop];

	}
	//买挑战次数返回
	if([[dict objectForKey:@"s"]integerValue]==1 && [[dict objectForKey:@"f"]isEqual:@"arenaBuy"]){
		CCLOG(@"%@",[dict objectForKey:@"d"]);
		NSDictionary *money=[dict objectForKey:@"d"];
        //fix chao
        [[GameConfigure shared] updatePackage:money];
        if ([money objectForKey:@"coin1"]) {
            [coin1spr setMoneyValue:[[money objectForKey:@"coin1"]integerValue]];
        }
        if ([money objectForKey:@"coin2"]) {
            [coin2spr setMoneyValue:[[money objectForKey:@"coin2"]integerValue]];
        }
        if ([money objectForKey:@"coin3"]) {
            [coin3spr setMoneyValue:[[money objectForKey:@"coin3"]integerValue]];
        }
		//[coin3spr setMoneyValue:[[money objectForKey:@"coin3"]integerValue]];
        //end
		//labelPlayTime.string=[NSString stringWithFormat:@"剩余挑战次数%i",[[money objectForKey:@"c"]integerValue]];
        labelPlayTime.string=[NSString stringWithFormat:NSLocalizedString(@"arena_dare_time",nil),[[money objectForKey:@"c"]integerValue]];
        
		todayCanPlayTime=[[money objectForKey:@"c"]integerValue];
	}
	//获取自身排行奖励
	if([[dict objectForKey:@"s"]integerValue]==1 && [[dict objectForKey:@"f"]isEqual:@"arenaReward"]){
        
        CCSimpleButton *btn_reward_bg_ = (CCSimpleButton *)[self getChildByTag:12380];
        if (!btn_reward_bg_) {
            return;
        }
        
		NSString *outstr=@"";
		NSString *re=@"";
		NSArray *array=[dict objectForKey:@"d"];
		for(NSDictionary *dict in array){
			int i=[[dict objectForKey:@"i"]integerValue];
			NSString *t=[dict objectForKey:@"t"];
			int c=[[dict objectForKey:@"c"]integerValue];
			NSString *color=getQualityColorStr(getAllItemQuality(i, t));
			NSString *name=getAllItemName(i, t);
			outstr=	[NSString stringWithFormat:@"%ix#FFEB7B#20#2|%@#%@#20#2|   ",c,name,color];
			re =[re stringByAppendingFormat:@"%@",outstr];
		}
		CCSprite *myre=drawString(re, CGSizeMake(300, 1), getCommonFontName(FONT_1),20,22, @"ffffff");
		[myre setAnchorPoint:ccp(0, 0)];
		if(myre.contentSize.height>22){
			[myre setPosition:ccp(cFixedScale(150),0-myre.contentSize.height/2+cFixedScale(5))];
		}else{
			[myre setPosition:ccp(cFixedScale(150), cFixedScale(5.0f))];						//Kevin fixed
		}
        
		
		[label7 addChild:myre];
		
	}
	//返回失败提示
	if([[dict objectForKey:@"s"]integerValue]==0){
		[ShowItem showItemAct:[[GameConfigure shared] getErrorMessage:[dict objectForKey:@"m"]]];
	}
    //
    isSend = NO;
}
#pragma mark 静态方法网络回调(因为战斗结束时窗口已经关闭)
+(void)staticDidrequestConnection:(NSDictionary*)dict{
	//获取战斗完成后返回
	if([[dict objectForKey:@"s"]integerValue]==1 && [[dict objectForKey:@"f"]isEqual:@"arenaEnd"]){
		[[GameConfigure shared]updatePackage:[dict objectForKey:@"d"]];
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
//	if(rewardBg){
//		[rewardBg removeFromParentAndCleanup:true];
//		rewardBg=nil;
//	}
	return YES;
	
}


#pragma mark 按下战斗
-(void)btnCallBackSelf:(CCSimpleButton*)n{
    CCSimpleButton *btn_reward_bg_ = (CCSimpleButton *)[self getChildByTag:12380];
    if (btn_reward_bg_) {
        if (rewardBg) {
            [rewardBg removeFromParentAndCleanup:YES];
            rewardBg = nil;
            label3 = nil;
            label4 = nil;
            label5 = nil;
            label6 = nil;
            label7 = nil;
        }
        [self removeChildByTag:12380 cleanup:YES];
        return;
    }
}
-(void)btnCallBackFigth:(CCSimpleButton*)n{
	/*
	if ([[Window shared] isHasWindow]) {
		CCLOG(@"Arena has Window!");
		return ;
	}
	 */
    if (isSend) {
        return;
    }
	if ([FightManager isFighting]) {
		CCLOG(@"FightManager is running!");
		return ;
	}
    //
	isSend = YES;
	//
	if(todayCanPlayTime<1){
		//[[AlertManager shared] showMessageWithSetting:@"是否花费5元宝购买1次挑战" target:self confirm:@selector(doBuy) key:@"arena.isbuyopen"];
        //[[AlertManager shared] showMessageWithSetting:NSLocalizedString(@"arena_buy_dare",nil) target:self confirm:@selector(doBuy) key:@"arena.isbuyopen"];
        BOOL isRecordFusion = [[[GameConfigure shared] getPlayerRecord:NO_ARENA_BUY_OPEN] boolValue];
		if (isRecordFusion) {
			[self doBuy];
		} else {
        [[AlertManager shared] showMessageWithSettingFormFather:NSLocalizedString(@"arena_buy_dare",nil)
                                                         target:self
                                                        confirm:@selector(doBuy)
                                                          canel:@selector(doCanelBuy)
                                                            key:NO_ARENA_BUY_OPEN
                                                         father:self.parent];
        }
		return;
	}
	
	int playerfid=[[n userObject]integerValue];
	currenFid=playerfid;
	[[FightManager shared]startFightPlayerByOrder:playerfid target:[Arena class] call:@selector(didFigth)];
	isToFigth=true;
    
}


#pragma mark 完成战斗回调
+(void)didFigth{
	fightSub=[[NSString alloc]initWithString:[[FightManager shared]getFigthSub]];
	fightisWin=[[FightManager shared]isWin];
	
	if ([fightSub length]>1) {
		if (fightisWin) {
			NSString *var=[NSString stringWithFormat:@"isOK::1|rid::%i|fp:%@",currenFid,fightSub];
			[GameConnection request:@"arenaEnd" format:var target:[Arena class] call:@selector(staticDidrequestConnection:)];
		}else{
			NSString *var=[NSString stringWithFormat:@"isOK::0|rid::%i|fp:%@",currenFid,fightSub];
			[GameConnection request:@"arenaEnd" format:var target:[Arena class] call:@selector(staticDidrequestConnection:)];
		}
		[fightSub release];
		fightSub=nil;
	}
	[NSTimer scheduledTimerWithTimeInterval:0.8 target:[Arena class] selector:@selector(showWindowAgain) userInfo:nil repeats:NO];
}

#pragma mark 完成战报回调
+(void)didRecordFigth{
	[NSTimer scheduledTimerWithTimeInterval:0.8 target:[Arena class] selector:@selector(showWindowAgain) userInfo:nil repeats:NO];
}

+(void)showWindowAgain{
    [PlayerSit show];
	[[Window shared]showWindow:PANEL_ARENA];
}



#pragma mark 打开排行榜
-(void)openRank{
//    if(iPhoneRuningOnGame() && [[Window shared] isHasWindow]){
//        return;
//    }
    if (isSend) {
        return;
    }
	[[Window shared] showWindow:PANEL_RANK_arena];
}

-(void)openFightRecord:(NSNotification*)nof{
	CCLOG(@"%@",nof);
    if (isSend) {
        return;
    }
	if (subPanel != nil) {
		if (!subPanel.isTouchValid) {
			CCLOG(@"Oh no! you touch too bad!!!");
			return ;
		}
	}
	
	int fid=[nof.object integerValue];
	[[FightManager shared]playFightRecord:fid target:[Arena class] call:@selector(didRecordFigth)];
    isSend = YES;
}



#pragma mark 打开奖励说明
-(void)openReward{
//    if(iPhoneRuningOnGame() && [[Window shared] isHasWindow]){
//        return;
//    }
//	if(rewardBg){
//		return;
//	}
    if (isSend) {
        return;
    }
	CCSimpleButton *btn_reward_bg = (CCSimpleButton *)[self getChildByTag:12380];
    if (btn_reward_bg) {
        return;
    }
    //
    int fontCurRankSize = cFixedScale(VALUE_FONT_SIZE_curRank);
    
	//NSString *curRank=[NSString stringWithFormat:@"我的当前排名:   |%i#FFEB7B#20#2",currenRank,fontCurRankSize];
	NSString *curRank=[NSString stringWithFormat:NSLocalizedString(@"arena_my_rank",nil),currenRank,fontCurRankSize];
    
	rewardBg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(550) height:cFixedScale(500) capx:cFixedScale(8) capy:cFixedScale(8)];		//Kevin fixed
	//CCSprite *label1=drawString(@"竞技场排名奖励",CGSizeMake(500,0),getCommonFontName(FONT_1),20,22,COLORYELLOW1XF);
    CCSprite *label1=drawString(NSLocalizedString(@"arena_rank_hortation",nil),CGSizeMake(500,0),getCommonFontName(FONT_1),20,22,COLORYELLOW1XF);
    
   // NSString  *fontLabel2 = [NSString stringWithFormat:@"周三，周日#FFEB7B#20#2|发放排名奖励，排名越靠前，奖励越丰厚",fontCurRankSize];
     NSString  *fontLabel2 = [NSString stringWithFormat:NSLocalizedString(@"arena_rank_hortation_info",nil),fontCurRankSize];
	CCSprite *label2=drawString(fontLabel2,CGSizeMake(500,0),getCommonFontName(FONT_1), 20, 22, @"ffffff");													//Kevin fixed
	//	CCSprite *label2=drawString(@"周三，周日#FFEB7B#%d#2|发放排名奖励，排名越靠前，奖励越丰厚",CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(20), @"ffffff");
	//    if (iPhoneRuningOnGame()) {
	//        label3=drawString(@"第|一#FFEB7B#10#2|名奖励:",CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(21), @"ffffff");
	//        label4=drawString(@"第|二#FFEB7B#10#2|名奖励:",CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(21), @"ffffff");
	//        label5=drawString(@"第|三#FFEB7B#10#2|名奖励:",CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(21), @"ffffff");
	//        label6=drawString(curRank,CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(20), @"ffffff");
	//        label7=drawString(@"可获得奖励：",CGSizeMake(cFixedScale(450),0),getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(20), @"ffffff");
	//    }else{
	//label3=drawString(@"第|一#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 21, @"ffffff");
    label3=drawString(NSLocalizedString(@"arena_rank_first_hortation",nil),CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 21, @"ffffff");
	//label4=drawString(@"第|二#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20,21, @"ffffff");
    label4=drawString(NSLocalizedString(@"arena_rank_second_hortation",nil),CGSizeMake(450,0),getCommonFontName(FONT_1), 20,21, @"ffffff");
	//label5=drawString(@"第|三#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20,21, @"ffffff");
    label5=drawString(NSLocalizedString(@"arena_rank_third_hortation",nil),CGSizeMake(450,0),getCommonFontName(FONT_1), 20,21, @"ffffff");
	label6=drawString(curRank,CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 20, @"ffffff");
	//label7=drawString(@"可获得奖励：",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 20, @"ffffff");
    label7=drawString(NSLocalizedString(@"arena_get_hortation",nil),CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 20, @"ffffff");
	// }
	
	//=======
	//	label3=drawString(@"第|一#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 21, @"ffffff");
	//	label4=drawString(@"第|二#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 21, @"ffffff");
	//	label5=drawString(@"第|三#FFEB7B#20#2|名奖励:",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 21, @"ffffff");
	//	label6=drawString(curRank,CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 20, @"ffffff");
	//	label7=drawString(@"可获得奖励：",CGSizeMake(450,0),getCommonFontName(FONT_1), 20, 20, @"ffffff");
	
	[label1 setAnchorPoint:ccp(0, 0)];
	[label2 setAnchorPoint:ccp(0, 0)];
	[label3 setAnchorPoint:ccp(0, 0)];
	[label4 setAnchorPoint:ccp(0, 0)];
	[label5 setAnchorPoint:ccp(0, 0)];
	[label6 setAnchorPoint:ccp(0, 0)];
	[label7 setAnchorPoint:ccp(0, 0)];
	
	[label1 setPosition:ccp(cFixedScale(10), cFixedScale(460))];
	[label2 setPosition:ccp(cFixedScale(10), cFixedScale(420))];					//Kevin fixed
	[label3 setPosition:ccp(cFixedScale(10), cFixedScale(360))];
	[label4 setPosition:ccp(cFixedScale(10), cFixedScale(340))];
	[label5 setPosition:ccp(cFixedScale(10), cFixedScale(320))];
	[label6 setPosition:ccp(cFixedScale(10), cFixedScale(300))];
	[label7 setPosition:ccp(cFixedScale(10), cFixedScale(280))];
	
	
	[rewardBg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
    //
	CCSimpleButton *btn_reward_bg_ = [CCSimpleButton node];
    btn_reward_bg_.contentSize = self.contentSize;
    btn_reward_bg_.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
    btn_reward_bg_.target = self;
    btn_reward_bg_.call = @selector(btnCallBackSelf:);
    [btn_reward_bg_ setPriority:-265];
    btn_reward_bg_.touchScale = 1.0f;
    [self addChild:btn_reward_bg_];
    btn_reward_bg_.tag = 12380;
    [btn_reward_bg_ addChild:rewardBg];
    //
	//[self addChild:rewardBg];
	[rewardBg addChild:label1];
	[rewardBg addChild:label2];
	[rewardBg addChild:label3];
	[rewardBg addChild:label4];
	[rewardBg addChild:label5];
	[rewardBg addChild:label6];
	[rewardBg addChild:label7];
	
	NSArray *labelarray=[NSArray arrayWithObjects:label3,label4,label5, nil];
	NSString *rewardstr=[[[GameDB shared]getGlobalConfig]objectForKey:@"arenaRewards"];
	CCLOG(@"%@",rewardstr);
	NSArray *reward=[rewardstr componentsSeparatedByString:@"|"];
	int h=cFixedScale(360);
	for(int i=0;i<3;i++){
		int rewardid=[[[[reward objectAtIndex:i]componentsSeparatedByString:@":"]objectAtIndex:1]integerValue];
		NSString *string=[[[GameDB shared]getRewardInfo:rewardid]objectForKey:@"info"];
		CCSprite *rstr=drawString(string, CGSizeMake(200,1), getCommonFontName(FONT_2), 20, 22, @"ffffff");
		[rstr setAnchorPoint:ccp(0, 0)];
		[rewardBg addChild:rstr];
		if(rstr.contentSize.height/2>cFixedScale(22)){
			[rstr setPosition:ccp(cFixedScale(150), h- rstr.contentSize.height/2 +cFixedScale(5))];
		}else{
			[rstr setPosition:ccp(cFixedScale(150), h)];
		}
		[[labelarray objectAtIndex:i] setPosition:ccp(cFixedScale(10), h)];
		h-= rstr.contentSize.height+cFixedScale(20);
		//		rstr.scale = cFixedScale(1);
		
	}
	[label6 setPosition:ccp(cFixedScale(10), h-cFixedScale(20))];
	[label7 setPosition:ccp(cFixedScale(10), h-cFixedScale(60))];
	NSString *var=[NSString stringWithFormat:@"rk::%i",currenRank];
	[GameConnection request:@"arenaReward" format:var target:self call:@selector(requestConnection:)];
    isSend = YES;
}



-(void)btnCallBack:(CCSimpleButton*)n{
//    if(iPhoneRuningOnGame() && [[Window shared] isHasWindow]){
//        return;
//    }
    if (isSend) {
        return;
    }
    isSend = YES;
    //
	CCSimpleButton *btn=n;
	switch (btn.tag) {
		case BTN_BACK:{
			[[Window shared]removeWindow:PANEL_ARENA];
		}
			break;
		case BTN_BUY:{
			//[[AlertManager shared] showMessageWithSetting:@"是否花费5元宝购买1次挑战" target:self confirm:@selector(doBuy) key:@"arena.isbuyopen"];
            //[[AlertManager shared] showMessageWithSetting:NSLocalizedString(@"arena_buy_dare",nil) target:self confirm:@selector(doBuy) key:@"arena.isbuyopen"];
            BOOL isRecordFusion = [[[GameConfigure shared] getPlayerRecord:NO_ARENA_BUY_OPEN] boolValue];
            if (isRecordFusion) {
                [self doBuy];
            } else {
                [[AlertManager shared] showMessageWithSettingFormFather:NSLocalizedString(@"arena_buy_dare",nil)
															 target:self
															confirm:@selector(doBuy)
                                                              canel:@selector(doCanelBuy)
																key:NO_ARENA_BUY_OPEN
															 father:self.parent];
            }
		}
			break;
		default:
			break;
	}
}
-(void)doCanelBuy{
    isSend = NO;
}
-(void)doBuy{
	[GameConnection request:@"arenaBuy" format:@"" target:self call:@selector(requestConnection:)];
}

@end
