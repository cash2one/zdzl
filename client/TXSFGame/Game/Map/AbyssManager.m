//
//  AbyssManager.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-30.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "AbyssManager.h"
#import "cocos2d.h"
#import "Game.h"
#import "MapManager.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "GameConnection.h"
#import "NPCManager.h"
#import "GameNPC.h"
#import "FightManager.h"
#import "GameUI.h"
#import "CCLabelFX.h"
#import "GameLayer.h"
#import "InfoAlert.h"
#import "NpcEffects.h"
#import "GameEffects.h"
#import "Arena.h"
#import "Window.h"

#define Abyss_shineOver_tag		20228
#define Abyss_shineUnder_tag	20229

#define Abyss_boxSprite_tag		20230
#define Abyss_boxButton_tag		20231
#define Abyss_buffAnimation_tag 20232

static int abyss_door_npc_ids[] = {
	0,
	1005,
	1003,
	1004,
};
static NSString * abyss_door_map_keys[] = {
	@"",
	@"door_1",
	@"door_2",
	@"door_back",
};



static int s_SelectNpc = 0 ;

static int getDoorNpcIdByType(Abyss_Door_type type){ return abyss_door_npc_ids[type]; }
static NSString * getDoorMapKeyByType(Abyss_Door_type type){ return abyss_door_map_keys[type]; }

static Abyss_Door_type getDoorTypeByNpcId(int nid){
	if(nid==abyss_door_npc_ids[1]) return Abyss_Door_type_general;
	if(nid==abyss_door_npc_ids[2]) return Abyss_Door_type_high;
	if(nid==abyss_door_npc_ids[3]) return Abyss_Door_type_back;
	return 0;
}

static AbyssManager * abyssManager;
//fix chao
@interface AbyssBuffButton:CCSprite<CCTouchOneByOneDelegate>{
	NSInteger abyssLayer;
	BOOL isTouch;
}
@property (nonatomic,assign) NSInteger abyssLayer;
-(void)addBuffWithPoint:(CGPoint)pos;
@end
@implementation AbyssBuffButton
@synthesize abyssLayer;
-(void)onEnter{
	[super onEnter];
	isTouch = NO;
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1 swallowsTouches:YES];
}
-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}
-(void)addBuffWithPoint:(CGPoint)pos{
    CCSprite *spr= (CCSprite *)[[[GameLayer shared] content] getChildByTag:230855];
	if (!spr) {
		spr = [CCSprite spriteWithFile:@"images/animations/abyssbuff/0.png"];
	}else{
		[spr stopAllActions];
	}
	if (spr) {
		spr.position = pos;		
		//id move = [CCMoveTo actionWithDuration:1.0 position:self.position];
		CGSize size = [CCDirector sharedDirector].winSize;
		id move = [CCJumpTo actionWithDuration:1.0 position:self.position height:size.height/3 jumps:1];
		id remove = [CCCallFuncN actionWithTarget:self selector:@selector(removeBuffSpriteCall)];
		id add = [CCCallFunc actionWithTarget:self selector:@selector(addBuffLayer)];
		[spr runAction:[CCSequence actions:move,remove,add,nil]];
		[[[GameLayer shared] content] addChild:spr z:INT32_MAX tag:230855];
	}	
}
-(void)removeBuffSpriteCall{
    [[[GameLayer shared] content] removeChildByTag:230855 cleanup:YES];
}
-(void)addBuffLayer{
	[self setAbyssLayer:(abyssLayer+1)];
	//
	//[ShowItem showItemAct:[NSString stringWithFormat:@"遇强越强状态叠加至%d层",abyssLayer]];
    [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"abyss_buff_des",nil),abyssLayer]];
}
-(void)setAbyssLayer:(NSInteger)layer_{
	abyssLayer = layer_;
	//CCLabelFX *label = (CCLabelFX *)[self getChildByTag:101];
    CCLabelFX *label= (CCLabelFX *)[[[GameLayer shared] content] getChildByTag:230856];
	if (!label) {
		label = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:getCommonFontName(FONT_1)
								  fontSize:18
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:2.0f];		
		label.position = ccpAdd(self.position, ccp(0,cFixedScale(68)));
		[[[GameLayer shared] content] addChild:label z:INT32_MAX tag:230856];
		label.color = ccc3(0, 255, 0);
	}
	[label setString:[NSString stringWithFormat:@"%d",abyssLayer]];
}
-(void)showMessageBox{
	if ([[Window shared] isHasWindow]) {
        return;
    }
    if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
	NSDictionary * info = [AbyssManager shared].info;
	NSDictionary * buff = [info objectForKey:@"buff"];
	
	NSArray * keys = [buff allKeys];
	
	//NSDictionary *globalDict = [[GameDB shared] getGlobalConfig];
	//if (globalDict) {
	
	if ([keys count]>0) {
		
		NSString *cmd = [NSMutableString string];
		//cmd = [cmd stringByAppendingFormat:@"^1*遇强越强#ffff00#20#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_title",nil)];
		cmd = [cmd stringByAppendingFormat:@"^1*"];
		//cmd = [cmd stringByAppendingFormat:@"源自天界降魔使者百折不挠的勇气，全体"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_title_2",nil)];
		
		BOOL isFirst = YES;
		for(NSString * key in buff){
			
			int value = [[buff objectForKey:key] intValue];
			
			if(!isFirst){
				cmd = [cmd stringByAppendingFormat:@"，"];
			}
			
			if(isEqualToKey(key, @"atk")){
				//cmd = [cmd stringByAppendingFormat:@"攻击#ffffff#18#0|"];
                cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_attack",nil)];
				cmd = [cmd stringByAppendingFormat:@"+%d#00ff00#18#0|",value];
			}
			if(isEqualToKey(key, @"atk_p")){
				//cmd = [cmd stringByAppendingFormat:@"攻击#ffffff#18#0|"];
                cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_attack",nil)];
				cmd = [cmd stringByAppendingFormat:@"+%d%%#00ff00#18#0|",value];
			}
			if(isEqualToKey(key, @"hp")){
				//cmd = [cmd stringByAppendingFormat:@"生命#ffffff#18#0|"];
                cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_hemo",nil)];
				cmd = [cmd stringByAppendingFormat:@"+%d#00ff00#18#0|",value];
			}
			if(isEqualToKey(key, @"hp_p")){
				//cmd = [cmd stringByAppendingFormat:@"生命#ffffff#18#0|"];
                cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_hemo",nil)];
				cmd = [cmd stringByAppendingFormat:@"+%d%%#00ff00#18#0|",value];
			}
			
			isFirst = NO;
		}
		
		//cmd = [cmd stringByAppendingFormat:@"，已叠加#ffffff#18#0|"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info1",nil)];
		cmd = [cmd stringByAppendingFormat:@"%d#00ff00#20#0|",abyssLayer];
		
		//cmd = [cmd stringByAppendingFormat:@"层，仅在无尽深渊中起效。#ffffff#18#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info2",nil)];
		cmd = [cmd stringByAppendingFormat:@"^2*"];
		//cmd = [cmd stringByAppendingFormat:@"每击败一次深渊守卫或魔物幻化的同伴可叠加一层。#888888#18#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info3",nil)];
		cmd = [cmd stringByAppendingFormat:@"^8*"];

		CCSprite *draw = drawString(cmd, CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
  		
        if (iPhoneRuningOnGame()) {
//            CCSprite *draw = drawString(cmd, CGSizeMake(200/2,0), getCommonFontName(FONT_1), 15/2, 16/2, @"#EBE2D0");
            [InfoAlert show:[GameLayer shared] drawSprite:draw parent:self.parent position:self.position anchorPoint:ccp(0.5, 1.0) offset:CGSizeMake(18/2, 18/2)];
        }else{
            [InfoAlert show:[GameLayer shared] drawSprite:draw parent:self.parent position:self.position anchorPoint:ccp(0.5, 1.0) offset:CGSizeMake(18, 18)];
		}
		//int hp = [[[info objectForKey:@"buff"] objectForKey:@"hp"] intValue];
		//NSString *deepBuff = [globalDict objectForKey:@"deepBuff"];
		//NSArray *bagsStrArr =[deepBuff componentsSeparatedByString:@"|"];
		/*
		NSString *atkStr = [bagsStrArr objectAtIndex:0];
		NSString *hpStr = [bagsStrArr objectAtIndex:1];
		NSArray *atkArr = [atkStr componentsSeparatedByString:@":"];
		NSArray *hpArr = [hpStr componentsSeparatedByString:@":"];
		
		int atkBase = 0;
		int hpBase = 0;
		
		if ([atkArr count]>1) {
			atkBase = [[atkArr objectAtIndex:1] intValue];
		}
		if ([hpArr count]>1) {
			hpBase = [[hpArr objectAtIndex:1] intValue];
		}
		
		NSString *cmd = [NSMutableString string];
		cmd = [cmd stringByAppendingFormat:@"^1*愈战愈勇#ffff00#20#0*"];
		cmd = [cmd stringByAppendingFormat:@"^1*"];
		
		cmd = [cmd stringByAppendingFormat:@"挑战无底深渊对生命加#ffffff#18#0|"];
		cmd = [cmd stringByAppendingFormat:@"%d%%#00ff00#18#0|",hpBase*abyssLayer];
		
		//cmd = [cmd stringByAppendingFormat:@"%d%%#00ff00#18#0|",300];
		cmd = [cmd stringByAppendingFormat:@",攻击力加#ffffff#18#0|"];
		cmd = [cmd stringByAppendingFormat:@"%d%%#00ff00#18#0|",atkBase*abyssLayer];
		//cmd = [cmd stringByAppendingFormat:@"%d%%#00ff00#18#0|",300];
		 
		cmd = [cmd stringByAppendingFormat:@",已叠加#ffffff#18#0|"];
		cmd = [cmd stringByAppendingFormat:@"%d#00ff00#20#0|",abyssLayer];
		
		cmd = [cmd stringByAppendingFormat:@"层#ffffff#18#0*"];
		cmd = [cmd stringByAppendingFormat:@"^2*"];
		cmd = [cmd stringByAppendingFormat:@"每击败1次守卫人可增加1层状态#888888#18#0*"];
		cmd = [cmd stringByAppendingFormat:@"^8*"];
		CCSprite *draw = drawString(cmd, CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
		[InfoAlert show:self drawSprite:draw parent:self.parent position:self.position anchorPoint:ccp(0.5, 1.0) offset:CGSizeMake(18, 18)];
		*/
		
	}else{
		NSString *cmd = [NSMutableString string];
		//cmd = [cmd stringByAppendingFormat:@"^1*遇强越强#ffff00#20#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_title",nil)];
		cmd = [cmd stringByAppendingFormat:@"^1*"];
		//cmd = [cmd stringByAppendingFormat:@"源自天界降魔使者百折不挠的勇气，全体"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_title_2",nil)];
		cmd = [cmd stringByAppendingFormat:@"，"];
		//cmd = [cmd stringByAppendingFormat:@"攻击#ffffff#18#0|"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_attack",nil)];
		cmd = [cmd stringByAppendingFormat:@"+%d%%#00ff00#18#0|",0];
		
		//cmd = [cmd stringByAppendingFormat:@"生命#ffffff#18#0|"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_hemo",nil)];
		cmd = [cmd stringByAppendingFormat:@"+%d%%#00ff00#18#0|",0];
				
		//cmd = [cmd stringByAppendingFormat:@"，已叠加#ffffff#18#0|"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info1",nil)];
		cmd = [cmd stringByAppendingFormat:@"%d#00ff00#20#0|",abyssLayer];
		
		//cmd = [cmd stringByAppendingFormat:@"层，仅在无尽深渊中起效。#ffffff#18#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info2",nil)];
		cmd = [cmd stringByAppendingFormat:@"^2*"];
		//cmd = [cmd stringByAppendingFormat:@"每击败一次深渊守卫或魔物幻化的同伴可叠加一层。#888888#18#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"abyss_buff_des_info3",nil)];
		cmd = [cmd stringByAppendingFormat:@"^8*"];
		CCSprite *draw = drawString(cmd, CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
		
        if (iPhoneRuningOnGame()) {
//            CCSprite *draw = drawString(cmd, CGSizeMake(200/2,0), getCommonFontName(FONT_1), 15/2, 16/2, @"#EBE2D0");
            [InfoAlert show:self drawSprite:draw parent:self.parent position:self.position anchorPoint:ccp(0.5, 1.0) offset:CGSizeMake(18/2, 18/2)];
        }else{
            [InfoAlert show:self drawSprite:draw parent:self.parent position:self.position anchorPoint:ccp(0.5, 1.0) offset:CGSizeMake(18, 18)];
        }
	}
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{	
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];	
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (touchLocation.x>0&&touchLocation.y>0 && touchLocation.x<self.contentSize.width&& touchLocation.y<self.contentSize.height) {		
		CCLOG(@"abyss layer ccTouchBegan");
		isTouch = YES;
		self.scale = 1.2f;
		return YES;
	}else{
		isTouch = NO;
		self.scale = 1.0f;
	}
	return NO;
}
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (!(touchLocation.x>0&&touchLocation.y>0 && touchLocation.x<self.contentSize.width&& touchLocation.y<self.contentSize.height)) {
		isTouch = NO;
		self.scale = 1.0f;
	}
}
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (isTouch && touchLocation.x>0&&touchLocation.y>0 && touchLocation.x<self.contentSize.width&& touchLocation.y<self.contentSize.height) {
		//TODO show message box
		CCLOG(@"abyss layer ccTouchBegan");
		isTouch = NO;
		self.scale = 1.0f;
		//
		[self showMessageBox];
	}
}
@end
//end
@implementation AbyssManager

@synthesize info;

+(AbyssManager*)shared{
	if(abyssManager==nil){
		abyssManager = [AbyssManager node];
		[abyssManager retain];
	}
	return abyssManager;
}
+(void)stopAll{
	if(abyssManager){
		[AbyssManager cleanAbyss];
	}
}

+(void)enterAbyss{
	[[AbyssManager shared] start];
}

+(void)cleanAbyss{
	if(abyssManager){
		// 删除传送点
		[abyssManager removeTransports];
		
		[abyssManager removeFromParentAndCleanup:YES];
		[abyssManager release];
		abyssManager = nil;
	}
}

+(void)quitAbyss{
	[AbyssManager cleanAbyss];
	[GameLayer shared].touchEnabled = YES;
	[[Game shared] backToMap:nil call:nil];
}
+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_Abyss){
		if(abyssManager){
			[abyssManager checkRestart];
		}else{
			[AbyssManager enterAbyss];
		}
	}else{
		[AbyssManager stopAll];
	}
}

-(id)init{
	if(self=[super init]){
		floorIndex = -1;
		chooseNpcId = -1;
		isEndFight = NO;
		isEndOpen = NO;
		transportArray = [NSMutableArray array];
		[transportArray retain];
		npcInfoArray = [NSMutableArray array];
		[npcInfoArray retain];
		
		NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
		deepBossStart = [[globalConfig objectForKey:@"deepBossStart"] intValue];
		deepAutoFloor = [[globalConfig objectForKey:@"deepAutoFloor"] intValue];
	}
	return self;
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if (transportArray) {
		[transportArray release];
		transportArray = nil;
	}
	if (npcInfoArray) {
		[npcInfoArray release];
		npcInfoArray = nil;
	}
	if(info){
		[info release];
		info = nil;
	}
	floorIndex = -1;
	chooseNpcId = -1;
	isEndFight = NO;
	isEndOpen = NO;
	[super dealloc];
	CCLOG(@"AbyssManager dealloc");
}
-(CCSprite *)getLabelBGWithIconPath:(NSString*)path labelString:(NSString*)str fontSize:(NSInteger)f_size{
	CCSprite *spr_bg = nil;
	CCSprite *spr_bf = nil;
	CCLabelFX *label_str = nil;

	spr_bg = [CCSprite spriteWithFile:@"images/ui/abyss/label-bg.png"];
	
	if (spr_bg) {
		spr_bf = [CCSprite spriteWithFile:path];
		if (spr_bf) {
			[spr_bg addChild:spr_bf];
			spr_bf.position = ccp(spr_bg.contentSize.width, spr_bg.contentSize.height/2);
		}
		if ( str && str.length>0 ) {
			label_str = [CCLabelFX labelWithString:str
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:getCommonFontName(FONT_1)
										  fontSize:f_size
									  shadowOffset:CGSizeMake(-1.5, -1.5)
										shadowBlur:2.0f];
			if (label_str) {
				[spr_bg addChild:label_str];
                if (iPhoneRuningOnGame()) {
                    label_str.position = ccp(20/2+label_str.contentSize.width/2, spr_bg.contentSize.height/2);
                }else{
                    label_str.position = ccp(20+label_str.contentSize.width/2, spr_bg.contentSize.height/2);
                }
			}
		}
        
		spr_bg.contentSize = CGSizeMake(spr_bg.contentSize.width + spr_bf.contentSize.width/2, spr_bg.contentSize.height);
	}
	

	return spr_bg;
}

//fix chao	
-(void)showBack{
	
	[menu removeChildByTag:555 cleanup:YES];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	NSArray * btns;
	CCMenuItemImage * item;
	btns = getBtnSpriteForScale(@"images/ui/button/bt_backmap.png",1.1f);
	
	CCSprite *spr1 = [btns objectAtIndex:0];
	CCSprite *spr2 = [btns objectAtIndex:1];
	
	NSDictionary *dictionary = [[GameDB shared] getMapInfo:[MapManager shared].mapId];
	NSString *name = nil;
	if (dictionary) {
		name = [dictionary objectForKey:@"name"];
	}else{
		name = @"";
	}
	CCLabelFX *name1 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
	
	CCLabelFX *name2 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
	[spr1 addChild:name1];
    if (iPhoneRuningOnGame()) {
        name1.position = ccp(spr1.contentSize.width/2 - 10/2, (spr1.contentSize.height)*1.2/2);
    }else{
        name1.position = ccp(spr1.contentSize.width/2 - 10, (spr1.contentSize.height)*1.2/2);
    }
	[spr2 addChild:name2];
	name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(10), (spr2.contentSize.height)*1.2/2);
	item = [CCMenuItemImage itemWithNormalSprite:spr1
								  selectedSprite:spr2
										  target:self
										selector:@selector(doClose)];
    
    if(iPhoneRuningOnGame())
    {
		item.scale=1.13f;
        item.position = ccp(winSize.width/2.0f-item.contentSize.width*item.scale/2.0f+5.5f,winSize.height/2.0f-item.contentSize.height*item.scale/2.0f+2);
    }else{
        item.position = ccp(winSize.width/2-item.contentSize.width/2+9.0f,winSize.height/2-35+9.0f);
    }
	item.tag = 555;
	
	[menu addChild:item ];
	
}
//end

-(void)addAboutBox
{
	// 宝箱相关
	NSString *fullPath1 = @"images/animations/boxopen/1/";
	NSString *fullPath2 = @"images/animations/boxopen/2/";
	NSArray *roleFrames1 = [AnimationViewer loadFileByFileFullPath:fullPath1 name:@"%d.png"];
	NSArray *roleFrames2 = [AnimationViewer loadFileByFileFullPath:fullPath2 name:@"%d.png"];
	
	// 宝箱闪烁
	AnimationViewer *shineOver = (AnimationViewer *)[[[GameLayer shared] content] getChildByTag:Abyss_shineOver_tag];
	if (!shineOver) {
		shineOver = [AnimationViewer node];
		shineOver.scale = 0.7;
		shineOver.visible = NO;
		[shineOver playAnimation:roleFrames1];
		[[[GameLayer shared] content] addChild:shineOver z:10 tag:Abyss_shineOver_tag];
	}
	AnimationViewer *shineUnder = (AnimationViewer *)[[[GameLayer shared] content] getChildByTag:Abyss_shineUnder_tag];
	if (!shineUnder) {
		shineUnder = [AnimationViewer node];
		shineUnder.scale = 0.7;
		shineUnder.visible = NO;
		[shineUnder playAnimation:roleFrames2];
		[[[GameLayer shared] content] addChild:shineUnder z:-1 tag:Abyss_shineUnder_tag];
	}
	
	CCSimpleButton *boxButton = (CCSimpleButton *)[[[GameLayer shared] content] getChildByTag:Abyss_boxButton_tag];
	if (!boxButton) {
		boxButton = [CCSimpleButton spriteWithFile:@"images/ui/timebox/box_close.png"
											select:@"images/ui/timebox/box_close.png"
											target:self
											  call:@selector(openBox)
										  priority:-1];
		boxButton.visible = NO;
		boxButton.tag = Abyss_boxButton_tag;
		[[[GameLayer shared] content] addChild:boxButton];
	}
	
	CCSprite *boxSprite = (CCSprite *)[[[GameLayer shared] content] getChildByTag:Abyss_boxSprite_tag];
	if (!boxSprite) {
		boxSprite = [CCSprite spriteWithFile:@"images/ui/timebox/box_open.png"];
		boxSprite.visible = NO;
		boxSprite.tag = Abyss_boxSprite_tag;
		[[[GameLayer shared] content] addChild:boxSprite];
	}
}

-(void)onEnter{
	[super onEnter];
	
	menu = [CCMenu menuWithItems:nil];
	[self addChild:menu];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	// 添加宝箱相关
	[self addAboutBox];
	
	// 规则
	RuleButton *ruleButton = [RuleButton node];
	if (iPhoneRuningOnGame()) {
		ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y)+5.0f);
	}else{
		ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y));
	}
    ruleButton.type = RuleType_abyss;
	[self addChild:ruleButton];
	
	int font_size = 14;
	int side_off_W = 10;
    if (iPhoneRuningOnGame()) {
//        font_size/=2;
        side_off_W/=2;
    }
	//CCSprite *label_bg1 = [self getLabelBGWithIconPath:@"images/ui/abyss/layer-icon.png" labelString:@"目前位于" fontSize:font_size];
    CCSprite *label_bg1 = [self getLabelBGWithIconPath:@"images/ui/abyss/layer-icon.png" labelString:NSLocalizedString(@"abyss_in_point",nil) fontSize:font_size];
	[self addChild:label_bg1];
	label_bg1.anchorPoint = ccp(1,0.5);
	
	//CCSprite *label_bg2 = [self getLabelBGWithIconPath:@"images/ui/abyss/boss-icon.png" labelString:@"打败" fontSize:font_size];
	CCSprite *label_bg2 = [self getLabelBGWithIconPath:@"images/ui/abyss/boss-icon.png" labelString:NSLocalizedString(@"abyss_clobber",nil) fontSize:font_size];
    [self addChild:label_bg2];
	label_bg2.anchorPoint = ccp(1,0.5);
	
	//CCSprite *label_bg3 = [self getLabelBGWithIconPath:@"images/ui/abyss/box-icon.png" labelString:@"寻得宝箱" fontSize:font_size];
	CCSprite *label_bg3 = [self getLabelBGWithIconPath:@"images/ui/abyss/box-icon.png" labelString:NSLocalizedString(@"abyss_find_box",nil) fontSize:font_size];
    [self addChild:label_bg3];
	label_bg3.anchorPoint = ccp(1,0.5);
    //右边的提示框
    if (iPhoneRuningOnGame()) {
        label_bg1.position = ccp(winSize.width-side_off_W,winSize.height-90/2);
        label_bg2.position = ccp(winSize.width-side_off_W,winSize.height-140/2);
        label_bg3.position = ccp(winSize.width-side_off_W,winSize.height-190/2);
    }else{
        label_bg1.position = ccp(winSize.width-side_off_W,winSize.height-90);
        label_bg2.position = ccp(winSize.width-side_off_W,winSize.height-140);
        label_bg3.position = ccp(winSize.width-side_off_W,winSize.height-190);
    }
    //也提示框上的内容相对

	CCLabelFX * label;
	label = [CCLabelFX labelWithString:@""
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter 
							  fontName:getCommonFontName(FONT_1) 
							  fontSize:font_size 
						  shadowOffset:CGSizeMake(-1.5, -1.5) 
							shadowBlur:2.0f];
	label.anchorPoint = ccp(0,0.5);

    if (iPhoneRuningOnGame()) {
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20/2+4*font_size/2,winSize.height-90/2);
    }else{
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20+4*font_size,winSize.height-90);
    }
	[self addChild:label z:0 tag:10001];
	label.color = ccc3(0, 255, 0);
	
	label = [CCLabelFX labelWithString:@""
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter 
							  fontName:getCommonFontName(FONT_1) 
							  fontSize:font_size 
						  shadowOffset:CGSizeMake(-1.5, -1.5) 
							shadowBlur:2.0f];
	label.anchorPoint = ccp(0,0.5);
    if (iPhoneRuningOnGame()) {
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20/2+2*font_size/2 + 1,winSize.height-140/2);				//Kevin fixed
    }else{
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20+2*font_size,winSize.height-140);
    }
	[self addChild:label z:0 tag:10002];
	label.color = ccc3(250,170,20);
	
	label = [CCLabelFX labelWithString:@""
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter 
							  fontName:getCommonFontName(FONT_1) 
							  fontSize:font_size 
						  shadowOffset:CGSizeMake(-1.5, -1.5) 
							shadowBlur:2.0f];
	label.anchorPoint = ccp(0,0.5);
    if (iPhoneRuningOnGame()) {
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20/2+4*font_size/2,winSize.height-190/2);
    }else{
        label.position = ccp(winSize.width-side_off_W-label_bg1.contentSize.width+20+4*font_size,winSize.height-190);
    }
	[self addChild:label z:0 tag:10003];
	label.color = ccc3(0, 255, 0);
	
	[self showBack];
	//fix chao
	[self showBuff];
	[self showEnterFloor];
	//end
}

-(void)onExit{

	//buff
	[[[GameLayer shared] content] removeChildByTag:20099 cleanup:YES];

	[[[GameLayer shared] content] removeChildByTag:Abyss_shineOver_tag cleanup:YES];
	[[[GameLayer shared] content] removeChildByTag:Abyss_shineUnder_tag cleanup:YES];
	[[[GameLayer shared] content] removeChildByTag:Abyss_boxButton_tag cleanup:YES];
	[[[GameLayer shared] content] removeChildByTag:Abyss_boxSprite_tag cleanup:YES];
    
    [[[GameLayer shared] content] removeChildByTag:Abyss_buffAnimation_tag cleanup:YES];

	[self removeAllChildrenWithCleanup:YES];
	menu = nil;
    [GameConnection freeRequest:self];
	[super onExit];
}

-(void)doClose{
    if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	[AbyssManager quitAbyss];
}
-(void)doAuto{
	if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	
	NSString *errorTips = NSLocalizedString(@"abyss_no_auto",nil);
	
	if(isAutoFight) {
		[ShowItem showItemAct:errorTips];
		return;
	}
	
	BOOL isCanAuto = NO;
	if (floorIndex < deepAutoFloor) {
		isCanAuto = YES;
	} else if (floorIndex == deepAutoFloor) {
		if (deepAutoFloor >= deepBossStart) {
			if ([info objectForKey:@"bid"]) {
				isCanAuto = YES;
			}
		} else {
			if ([info objectForKey:@"gd1"] && [info objectForKey:@"gd2"]) {
				isCanAuto = YES;
			}
		}
	}
	// 当前状态不可挂机
	if (!isCanAuto) {
		[ShowItem showItemAct:errorTips];
		return;
	}
	
	int cost = [[[[GameDB shared] getGlobalConfig] objectForKey:@"deepAutoCost"] intValue];
	// 判断是否要扣当前层的元宝
	int curLevel = 1;
	if (![info objectForKey:@"gd1"]) {
		curLevel = 0;
	} else if (floorIndex != 0 && ![info objectForKey:@"gd2"]) {
		curLevel = 0;
	}
	int levelCount = deepAutoFloor - floorIndex + curLevel;
	int allCost = cost * levelCount;
	
	int playerIngot = [[GameConfigure shared] getPlayerIngot];
	if (playerIngot >= allCost) {
		BOOL isRecordGold = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_DEEP_AUTO] boolValue];
		if (isRecordGold) {
			[self doAutoFinal];
		} else {
			
			[[RoleManager shared] stopMovePlayer];
			
			[[AlertManager shared] showMessageWithSetting:[NSString stringWithFormat:NSLocalizedString(@"abyss_auto_need_yuanbao",nil), allCost] target:self confirm:@selector(doAutoFinal) key:NO_REMIND_DEEP_AUTO];
			
		}
	} else {
		[ShowItem showItemAct:NSLocalizedString(@"abyss_no_yuanbao",nil)];
	}
}

-(void)doAutoFinal{
	[GameConnection request:@"deepAuto" format:@"" target:self call:@selector(didAbyssAuto:)];
}

-(void)didAbyssAuto:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		[self removeBox];
		
		NSDictionary * data = getResponseData(response);
		
		status = Abyss_Status_auto;
		isAutoFight = YES;
		autoTimes = [[data objectForKey:@"wasteTimes"] intValue];
		
		[self showInfo];
		
		//update player info
		[[GameConfigure shared] updatePackage:[data objectForKey:@"data"]];
		
	}else{
		//todo
		//增加错误嘛
		NSString* temp = getResponseMessage(response);
		if (temp) {
			[ShowItem showErrorAct:temp];
		}
	}
}

#pragma mark-

-(void)start{
	[GameConnection request:@"deepEnter" format:@"type::0" target:self call:@selector(didGetAbyssData:)];
}

-(void)restart{
	[self removeCountdown];
	[GameLayer shared].touchEnabled = YES;
	[[NPCManager shared] clearAllNPC];
	[self start];
}

-(void)checkRestart{
	
	if(!self.parent){
		//[[GameUI shared] addChild:self z:-1];
		self.visible = YES ;
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_abyssManager];
	}
	
	[self showInfo];
	
	/*
	if(isAutoFight){
		[self showInfo];
		return;
	}
	*/
	
	// 移除npc传送点
	[self removeTransports];
	
	[self checkDoor];
	[self checkAutoButton];
	
//	if(floorIndex==100){
	if (floorIndex >= deepBossStart) {
		[self showBoss];
		return;
	}
	
	if(![self showBox]){
		[self showMonster];
	}
	
}

-(void)didGetAbyssData:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		NSDictionary * enter = getResponseData(response);
		if(enter){
			[self updateInfo:enter];
			[self enterTargetMap];
		}
		
		//if(!self.parent){
		//	[[GameUI shared] addChild:self z:INT_MAX];
		//}
		
	}
}

-(void)enterTargetMap{
	int mid = [[info objectForKey:@"mid"] intValue];
	if([MapManager shared].mapId==mid){
		[self checkRestart];
	}else{
		[[Game shared] trunToMap:mid target:self call:@selector(showBack)];
	}
}

-(void)updateInfo:(NSDictionary*)enter{
	
	isFirstEnter = [[enter objectForKey:@"fsi"] intValue];
	status = [[enter objectForKey:@"s"] intValue];
	isAutoFight = (status==Abyss_Status_auto);
	
	autoTimes = [[enter objectForKey:@"autoTimes"] intValue];
	floorIndex = [[enter objectForKey:@"floor"] intValue];
	
	if(info) [info release];
	info = [[NSMutableDictionary alloc] initWithDictionary:enter];
	[self showInfo];
	
}

-(void)removeNpcInfos
{
	[npcInfoArray removeAllObjects];
}

-(void)removeTransports
{
	for (CCNode *node in transportArray) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	[transportArray removeAllObjects];
}

-(void)addTransports
{
	[self removeTransports];
	
	for (NSDictionary *dict in npcInfoArray) {
		CGPoint point = [[dict objectForKey:@"point"] CGPointValue];
		
		NpcEffects *effect = [NpcEffects node];
		effect.anchorPoint = ccp(0.5, 0);
        if (iPhoneRuningOnGame()) {
            effect.position = ccpAdd(point, ccp(0, -50/2));
        }else{
            effect.position = ccpAdd(point, ccp(0, -50));
        }
        [effect showEffect:3 target:self call:@selector(addNpc)];
		[[[GameLayer shared] content] addChild:effect z:INT16_MAX];
		
		[transportArray addObject:effect];
	}
}

-(void)addNpc
{
	[self removeTransports];
	
	for (NSDictionary *dict in npcInfoArray) {

		int npcId = [[dict objectForKey:@"npcId"] intValue];
		
		if (s_SelectNpc == npcId &&
			[FightManager isWinFight]) {
			continue ;
		}
		
		CGPoint point = [[dict objectForKey:@"point"] CGPointValue];
		int direction = [[dict objectForKey:@"direction"] intValue];
		
		point = [[MapManager shared] getPositionToTile:point];
		
		[[NPCManager shared] addNPCById:npcId
							  tilePoint:point
							  direction:direction
								 target:self
								 select:@selector(moveToNpc:)
									tag:0
		 ];
		GameNPC *gameNpc = [[NPCManager shared] getNPCById:npcId];
		if (gameNpc) {
			[gameNpc showBattle];
		}
		
	}
	
	[self removeNpcInfos];
}

-(void)boxActionDone
{
	[[GameEffects share] showEffects:EffectsAction_loshing target:nil call:nil];
}

-(BOOL)showBox{
	
	// 添加宝箱相关
	[self addAboutBox];
	
	NSDictionary * box = [info objectForKey:@"box"];
	BOOL isHasBox = [[box objectForKey:@"box"] boolValue];
	
	if (status == Abyss_Status_auto) {
		isHasBox = NO;
	}
	
	if(isHasBox){
		NSArray * boxs = [[MapManager shared] getFunctionRect:@"object" key:@"box"];
		if([boxs count]>0){
			
			CGPoint point = getTiledRectCenterPoint([[boxs objectAtIndex:0] CGRectValue]);
			
			int z = (GAME_MAP_MAX_Y - point.y);
			
			CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Abyss_boxSprite_tag];
			if (boxSprite) {
				if (boxSprite.parent) {
					[boxSprite.parent reorderChild:boxSprite z:z];
				}
				
				boxSprite.visible = NO;
				boxSprite.position = point;
			}
			
			CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Abyss_boxButton_tag];
			if (boxButton) {
				if (boxButton.parent) {
					[boxButton.parent reorderChild:boxButton z:z];
				}
				
				[boxButton stopAllActions];
				if (isEndFight) {
					if (iPhoneRuningOnGame()) {
						boxButton.position = ccp(point.x, point.y + 800/2);
					}else{
						boxButton.position = ccp(point.x, point.y + 800);
					}
					id moveAction = [CCMoveTo actionWithDuration:1 position:point];
					[boxButton runAction:[CCSequence actions:moveAction, [CCCallFunc actionWithTarget:self selector:@selector(boxActionDone)], nil]];
				} else {
					boxButton.position = point;
				}
				
				boxButton.visible = YES;
			}
			
			CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:Abyss_shineOver_tag];
			if (shineOver) {
				shineOver.position = point;
			}
			CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:Abyss_shineUnder_tag];
			if (shineUnder) {
				shineUnder.position = point;
			}
			
			isEndFight = NO;
		}
		return YES;
	}
	else {
		
		CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Abyss_boxSprite_tag];
		if (boxSprite) {
			boxSprite.visible = NO;
		}
		
		CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Abyss_boxButton_tag];
		if (boxButton) {
			boxButton.visible = NO;
		}
		
		CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:Abyss_shineOver_tag];
		if (shineOver) {
			shineOver.visible = NO;
		}
		CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:Abyss_shineUnder_tag];
		if (shineUnder) {
			shineUnder.visible = NO;
		}
	}
	return NO;
}

-(void)openBox
{
	/*
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	 */
	if (![[Window shared] checkCanTouchNpc]) {
		return ;
	}
    
	[[GameConfigure shared] markPlayerProperty];
	
	[GameConnection request:@"deepBox" format:@"" target:self call:@selector(didGetBox:)];
}

-(void)removeBox
{
	CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Abyss_boxSprite_tag];
	if (boxSprite) {
		boxSprite.visible = NO;
	}
	
	CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Abyss_boxButton_tag];
	if (boxButton) {
		boxButton.visible = NO;
	}
	
	CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:Abyss_shineOver_tag];
	if (shineOver) {
		shineOver.visible = NO;
	}
	CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:Abyss_shineUnder_tag];
	if (shineUnder) {
		shineUnder.visible = NO;
	}
}

-(void)didGetBox:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Abyss_boxSprite_tag];
		if (boxSprite) {
			boxSprite.visible = YES;
		}
		
		CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Abyss_boxButton_tag];
		if (boxButton) {
			boxButton.visible = NO;
		}
		
		CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:Abyss_shineOver_tag];
		if (shineOver) {
			shineOver.visible = YES;
		}
		CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:Abyss_shineUnder_tag];
		if (shineUnder) {
			shineUnder.visible = YES;
		}
		
		isEndOpen = YES;
		
		[self scheduleOnce:@selector(removeBox) delay:1.5f];
		
		NSDictionary * data = getResponseData(response);
		
		// 显示更新的物品
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:[data objectForKey:@"data"]];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
		
		[info setObject:[data objectForKey:@"box"] forKey:@"box"];
		[[GameConfigure shared] updatePackage:[data objectForKey:@"data"]];
		
		[self showInfo];
		
		if(floorIndex<100){
			[self showMonster];
		}else{
			//[AbyssManager quitAbyss];
			
			status = Abyss_Status_complete;
			[self showInfo];
			
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(response)];
	}
}

-(void)showMonster{
	
//	if(floorIndex==100){
	if (floorIndex >= deepBossStart) {
		[self showBoss];
		return;
	}
	
	[self removeNpcInfos];
	
	NSDictionary * npcs = [info objectForKey:@"npc"];
	for(NSString * key in npcs){
		
		if(![key isEqualToString:@"bid"] && 
		   ![key isEqualToString:@"box"] && 
		   floorIndex<deepBossStart){
			
			NSArray * objects = [[MapManager shared] getFunctionRect:@"object" key:key];
			if([objects count]>0){
				
				CGPoint point = getTiledRectCenterPoint([[objects objectAtIndex:0] CGRectValue]);
				
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				int npcId = [[npcs objectForKey:key] intValue];
				[dict setValue:[NSNumber numberWithInt:npcId] forKey:@"npcId"];
				[dict setValue:[NSValue valueWithCGPoint:point] forKey:@"point"];
				
				[dict setValue:[NSNumber numberWithInt:1] forKey:@"direction"];
				
				if(isEqualToKey(key,@"gd2")){
					NSDictionary * nInfo = [[GameDB shared] getNpcInfo:npcId];
					if(nInfo){
						int dir = [[nInfo objectForKey:@"dir"] intValue];
						if(dir==4||dir==7||dir==8){
							[dict setValue:[NSNumber numberWithInt:-1] forKey:@"direction"];
						}
					}
				}
				
				[npcInfoArray addObject:dict];
				
			}
		}
	}
	
	if (isEndOpen || isFirstEnter) {
		[self addTransports];
	} else {
		[self addNpc];
	}
	isEndOpen = NO;
}

-(void)showBoss{
	
	[self removeNpcInfos];
	
	if([info objectForKey:@"bid"]){
		int bid = [[[info objectForKey:@"npc"] objectForKey:@"bid"] intValue];
		if(bid>0){
			NSArray * objects = [[MapManager shared] getFunctionRect:@"object" key:@"boss"];
			if([objects count]>0){
				CGPoint point = getTiledRectCenterPoint([[objects objectAtIndex:0] CGRectValue]);
				
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				[dict setValue:[NSNumber numberWithInt:bid] forKey:@"npcId"];
				[dict setValue:[NSValue valueWithCGPoint:point] forKey:@"point"];
				[dict setValue:[NSNumber numberWithInt:1] forKey:@"direction"];
				[npcInfoArray addObject:dict];
				
			}
		}
		
		if (isEndOpen || isFirstEnter) {
			[self addTransports];
		} else {
			[self addNpc];
		}
		isEndOpen = NO;
		
	}else{
		[self showBox];
	}
	
}

-(void)moveToNpc:(GameNPC*)npc{
	// 挂机的时候点击无效
	if (status == Abyss_Status_auto) return;
	
	chooseNpcId = npc.npcId;
	s_SelectNpc = chooseNpcId;
	
	CGPoint point = npc.position;
	//CGPoint point = [npc getPlayerPoint];
	if (iPhoneRuningOnGame()) {
        if(chooseNpcId==1001){
            point = ccpAdd(point, ccp(0,-50/2));
        }else if(chooseNpcId==1002){
            point = ccpAdd(point, ccp(50,-50/2));
        }else{
            point = ccpAdd(point, ccp(-50,-50/2));
        }
        
    }else{
        if(chooseNpcId==1001){
            point = ccpAdd(point, ccp(0,-50));
        }else if(chooseNpcId==1002){
            point = ccpAdd(point, ccp(50,-50));
        }else{
            point = ccpAdd(point, ccp(-50,-50));
        }
    }
	npcPoint = point;
	[[RoleManager shared] movePlayerTo:point target:self call:@selector(doFightNpc)];
}

-(void)doFightNpc{
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	
	Abyss_Target_Type type = [self getChooseNpcType];
	int level = [[player objectForKey:@"level"] intValue];
	
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	[data setObject:@"fabyss" forKey:@"BG"];
	[data setObject:[NSNumber numberWithInt:chooseNpcId] forKey:@"targetId"];
	[data setObject:[NSNumber numberWithInt:type] forKey:@"type"];
	[data setObject:[NSNumber numberWithInt:level] forKey:@"level"];
	[data setObject:[NSNumber numberWithInt:floorIndex] forKey:@"floorIndex"];
	
	//player abyss buff
	[data setObject:[info objectForKey:@"buff"] forKey:@"buff"];
	if([info objectForKey:@"gbuff"]){
		[data setObject:[info objectForKey:@"gbuff"] forKey:@"gbuff"];
	}
	
	if(type==Abyss_Target_Type_boss){
		[data setObject:[info objectForKey:@"bid"] forKey:@"bid"];
	}else{
		NSDictionary * fight = [info objectForKey:[self getKeyByChooseNpcId]];
		if(fight){
			[data setObject:[fight objectForKey:@"pid"] forKey:@"pid"];
			[data setObject:[fight objectForKey:@"rids"] forKey:@"rids"];
		}else{
			//TDOO error
			return;
		}
	}
	
	self.visible = NO;
	[[FightManager shared] startFightAbyss:data target:self call:@selector(endFightNpc)];
	
}

-(void)endFightNpc{
	
	self.visible = YES;
	
	if([FightManager isFighting]){
		if([FightManager isWinFight]){
			Abyss_Target_Type type = [self getChooseNpcType];
			
			if(type>0){
				
				NSString * d = [NSString stringWithFormat:@"type::%d",type];
				[GameConnection request:@"deepFight" format:d target:self call:@selector(didDeepFight:)];
				/*
				//fix chao
				[self showBuff];
				AbyssBuffButton *abButton = (AbyssBuffButton *)[[[GameLayer shared] content] getChildByTag:20099];
				if (abButton) {
					[abButton addBuffWithPoint:npcPoint];
				}
				//end
				 */
				[self removeFightData];
				[self checkDoor];
				
				[[NPCManager shared] removeNPCById:chooseNpcId];
				chooseNpcId = -1;
				
				isEndFight = YES;
				
				/*
				if(floorIndex==100){
					[self showBox];
					status = Abyss_Status_complete;
					[self showInfo];
				}
				 */
				
				if (floorIndex >= deepBossStart) {
					[self showBox];
					[self showInfo];
				}
				if (floorIndex == 100) {
					status = Abyss_Status_complete;
				}
				
			}
			
		}
	}
}

-(void)didDeepFight:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		//TODO		
		NSDictionary *buffDict = getResponseData(response);
		[info removeObjectForKey:@"buff"];
		[info setObject:[buffDict objectForKey:@"buff"] forKey:@"buff"];
		//fix chao
		[self showBuff];
		AbyssBuffButton *abButton = (AbyssBuffButton *)[[[GameLayer shared] content] getChildByTag:20099];
		if (abButton) {
			int i=[abButton abyssLayer]-1;
			if(i<0){
				i = 0;
			}
			[abButton setAbyssLayer:i];
			[abButton addBuffWithPoint:npcPoint];
		}
		//end
		/*
		[self removeFightData];
		[self checkDoor];
		
		[[NPCManager shared] removeNPCById:chooseNpcId];
		chooseNpcId = -1;
		
		isEndFight = YES;
		
		if(floorIndex==100){
			[self showBox];
			status = Abyss_Status_complete;
			[self showInfo];
		}
		 */
	}
}

-(void)removeFightData{
	NSString * target = [self getKeyByChooseNpcId];
	NSMutableDictionary * npcs = [NSMutableDictionary dictionaryWithDictionary:[info objectForKey:@"npc"]];
	[npcs removeObjectForKey:target];
	[info removeObjectForKey:target];
	[info setObject:npcs forKey:@"npc"];
	
	if (npcInfoArray != nil) {
		for (NSDictionary* temNpc in  npcInfoArray) {
			int ___nid = [[temNpc objectForKey:@"npcId"] intValue];
			if (___nid == chooseNpcId) {
				[npcInfoArray removeObject:temNpc];
				break ;
			}
		}
	}
	
}

// 判断是否显示挂机按钮
-(void)checkAutoButton
{
	[menu removeChildByTag:123];
	
	BOOL isCanAuto = NO;
	if (floorIndex < deepAutoFloor) {
		isCanAuto = YES;
	} else if (floorIndex == deepAutoFloor) {
		if (deepAutoFloor >= deepBossStart) {
			if ([info objectForKey:@"bid"]) {
				isCanAuto = YES;
			}
		} else {
			if ([info objectForKey:@"gd1"] && [info objectForKey:@"gd2"]) {
				isCanAuto = YES;
			}
		}
	}
	if (isCanAuto) {
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		NSArray * btns;
		CCMenuItemImage * item;
		
		btns = getBtnSprite(@"images/ui/abyss/btn-auto.png");
		item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
									  selectedSprite:[btns objectAtIndex:1]
											  target:self
											selector:@selector(doAuto)];
		if (iPhoneRuningOnGame()) {
			item.position = ccp(winSize.width/2-cFixedScale(350), winSize.height/2-cFixedScale(30)+5.0f);
		}else{
			item.position = ccp(winSize.width/2-cFixedScale(350), winSize.height/2-cFixedScale(30));
		}
		
		[menu addChild:item z:0 tag:123];
	}
}

-(void)checkDoor{
	if(floorIndex>0) [self showDoor:Abyss_Door_type_back];
	
	if(floorIndex==0){
		if(![info objectForKey:@"gd1"]){
			[self showDoor:Abyss_Door_type_general];
		}
	}
//	if(floorIndex>0 && floorIndex<100){
	if(floorIndex>0 && floorIndex<deepBossStart){
		if(![info objectForKey:@"gd1"]){
			[self showDoor:Abyss_Door_type_general];
		}
		if(![info objectForKey:@"gd2"]){
			[self showDoor:Abyss_Door_type_high];
		}
	}
	if (floorIndex<100 && floorIndex>=deepBossStart) {
		if (![info objectForKey:@"bid"]) {
			[self showDoor:Abyss_Door_type_general];
		}
	}
}

-(void)showDoor:(Abyss_Door_type)type{
	int tid = getDoorNpcIdByType(type);
	GameNPC * door = [[NPCManager shared] getNPCById:tid];
	if(!door){
		
		NSString * key = getDoorMapKeyByType(type);
		NSArray * objects = [[MapManager shared] getFunctionRect:@"object" key:key];
		if([objects count]>0){
			
			CGPoint point = getTiledRectCenterPoint([[objects objectAtIndex:0] CGRectValue]);
			point = [[MapManager shared] getPositionToTile:point];
			
			[[NPCManager shared] addNPCById:tid
								  tilePoint:point
								  direction:1
									 target:self 
									 select:@selector(enterDoor:) 
										tag:0
			 ];
			
		}
		
	}
}

-(void)enterDoor:(GameNPC*)npc{
	// 挂机的时候点击无效
	if (status == Abyss_Status_auto) return;
	
	chooseNpcId = npc.npcId;
	[[RoleManager shared] movePlayerTo:npc.position
								target:self
								  call:@selector(didEnterDoor)
	 ];
}
-(void)didEnterDoor{
	
	//TODO show loading...
	
	int type = getDoorTypeByNpcId(chooseNpcId);
	NSString * d = [NSString stringWithFormat:@"type::%d",type];
	chooseNpcId = -1;
	[GameConnection request:@"deepEnter" format:d target:self call:@selector(didGetAbyssData:)];
	
}

-(NSString*)getKeyByChooseNpcId{
	NSString * target = nil;
	NSDictionary * npcs = [info objectForKey:@"npc"];
	for(NSString * key in npcs){
		if([[npcs objectForKey:key] intValue]==chooseNpcId){
			target = key;
			break;
		}
	}
	return target;
}

-(Abyss_Target_Type)getChooseNpcType{
	Abyss_Target_Type type = Abyss_Target_Type_none;
	NSString * target = [self getKeyByChooseNpcId];
	if([target isEqualToString:@"gd1"]) type = Abyss_Target_Type_monster;
	if([target isEqualToString:@"gd2"]) type = Abyss_Target_Type_role;
	if([target isEqualToString:@"bid"]) type = Abyss_Target_Type_boss;
	return type;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)showInfo{
	//show abyss info

	CCLabelFX * label;
	
	label = (CCLabelFX*)[self getChildByTag:10001];
	//label.string = [NSString stringWithFormat:@"深渊%d层",floorIndex];
    label.string = [NSString stringWithFormat:NSLocalizedString(@"abyss_floor",nil),floorIndex];
	
	label = (CCLabelFX*)[self getChildByTag:10002];
	int bid = [[[info objectForKey:@"npc"] objectForKey:@"bid"] intValue];
	if(bid>0){
		NSDictionary * boss = [[GameDB shared] getMonsterInfo:bid];
		label.string = [NSString stringWithFormat:@"%@",[boss objectForKey:@"name"]];
	}else{
		//label.string = [NSString stringWithFormat:@"深渊领主"];
        label.string = [NSString stringWithFormat:NSLocalizedString(@"abyss_boss",nil)];
	}
	
	int remainBox = [[[info objectForKey:@"box"] objectForKey:@"remain"] intValue];
	int totalBox = [[[info objectForKey:@"box"] objectForKey:@"total"] intValue];
	label = (CCLabelFX*)[self getChildByTag:10003];
	label.string = [NSString stringWithFormat:@"%d/%d",(totalBox-remainBox),totalBox];
	//buff
	//fix chao
	[self showBuff];
	[self showEnterFloor];
	//end
	//[info objectForKey:@"box"];
	
	//TODO show object list

	if(status!=Abyss_Status_normal){
		[menu removeChildByTag:123 cleanup:YES];
	}
	if(status==Abyss_Status_auto){
		[GameLayer shared].touchEnabled = NO;
		[self showCountdown];
	}
	
}
//fix chao
-(void)removeNode:(id)sender{
	CCNode *node = sender;
	[node removeFromParentAndCleanup:YES];
}

-(NSString*)getText:(NSInteger)_value{
	//----
	//NSString *textArr[9] = {@"一",@"二",@"三",@"四",@"五",@"六",@"七",@"八",@"九"};
    NSString *textArr[9] = {
        NSLocalizedString(@"abyss_one",nil),
        NSLocalizedString(@"abyss_two",nil),
        NSLocalizedString(@"abyss_three",nil),
        NSLocalizedString(@"abyss_four",nil),
        NSLocalizedString(@"abyss_five",nil),
        NSLocalizedString(@"abyss_six",nil),
        NSLocalizedString(@"abyss_seven",nil),
        NSLocalizedString(@"abyss_eight",nil),
        NSLocalizedString(@"abyss_nine",nil)};
	//NSString *bitArr[4] = {@"千",@"百",@"十",@""};
    NSString *bitArr[4] = {
        NSLocalizedString(@"abyss_thousand",nil),
        NSLocalizedString(@"abyss_hundred",nil),
        NSLocalizedString(@"abyss_ten",nil),
        @""};
	//
	NSString *re_str = [NSString stringWithFormat:@""];
	int t_val = 0;
	int temp = 1000;
	//NSString *strArr[4] = {@"零",@"零",@"零",@"零"};
    NSString *strArr[4] = {
        NSLocalizedString(@"abyss_zero",nil),
        NSLocalizedString(@"abyss_zero",nil),
        NSLocalizedString(@"abyss_zero",nil),
        NSLocalizedString(@"abyss_zero",nil)};
	for (int i=0; i<4;i++) {
		t_val = _value/temp;
		_value = _value%temp;
		if (t_val>0 && t_val<10) {
			strArr[i] = textArr[t_val-1];
		}
		temp /=10;
	}
	BOOL isCanAddZero = NO;
	BOOL isAddZero = NO;
	for (int i=0;i<4;i++) {
		//if (!([strArr[i] isEqualToString:@"零"])) {
        if (!([strArr[i] isEqualToString:NSLocalizedString(@"abyss_zero",nil)])) {
			if(isCanAddZero && isAddZero){
				//re_str = [ re_str stringByAppendingFormat:@"零"];
                re_str = [ re_str stringByAppendingFormat:NSLocalizedString(@"abyss_zero",nil)];
				isAddZero = NO;				
			}
			re_str = [ re_str stringByAppendingFormat:@"%@%@",strArr[i],bitArr[i]];
			isCanAddZero = YES;
		}else{
			if (isCanAddZero) {
				isAddZero = YES;
			}
		}
	}
	return re_str;
}
-(NSString*)getFloorStringWith:(int)floorIndex_{
	if (floorIndex_ == 0) {
		//return @"零";
        return NSLocalizedString(@"abyss_zero",nil);
	}
	//NSString *unitArr[] = {@"",@"万",@"亿",@"万亿"};
    NSString *unitArr[] = {
        @"",
        NSLocalizedString(@"abyss_myriad",nil),
        NSLocalizedString(@"abyss_hundred_million",nil),
        NSLocalizedString(@"abyss_tril",nil)};
	int temp = floorIndex_;
	temp = abs(temp);
	int temp_val_L = 0;
	int temp_val_H = 0;
	NSString *re_str = [NSString stringWithFormat:@""];
	BOOL isAddZero = NO;
	for (int i=0; i<sizeof(unitArr)/sizeof(unitArr[0]); i++) {
		temp_val_L = temp%10000;
		temp_val_H = temp/10000;
		
		if (temp_val_L>0) {
			isAddZero = YES;
		}
		if (temp_val_H>0) {
			if (temp_val_L>0) {
				if (isAddZero) {
					if ((temp_val_L/1000)==0) {
						//re_str = [ re_str stringByAppendingFormat:@"零"];
                        re_str = [ re_str stringByAppendingFormat:NSLocalizedString(@"abyss_zero",nil)];
					}
					re_str = [ re_str stringByAppendingFormat:@"%@",[self getText:temp_val_L] ];
					re_str = [ re_str stringByAppendingFormat:@"%@",unitArr[i] ];
				}else{
					re_str = [ re_str stringByAppendingFormat:@"%@",[self getText:temp_val_L] ];
					re_str = [ re_str stringByAppendingFormat:@"%@",unitArr[i] ];					
				}
			}else{
				//re_str = [ re_str stringByAppendingFormat:@"零"];
                re_str = [ re_str stringByAppendingFormat:NSLocalizedString(@"abyss_zero",nil)];
			}
		}else{
			if(temp_val_L<20 && temp_val_L>=10){
				//re_str = [ re_str stringByAppendingFormat:@"十"];
                re_str = [ re_str stringByAppendingFormat:NSLocalizedString(@"abyss_ten",nil)];
				re_str = [ re_str stringByAppendingFormat:@"%@",[self getText:temp_val_L%10] ];
			}else{
				re_str = [ re_str stringByAppendingFormat:@"%@",[self getText:temp_val_L] ];
				re_str = [ re_str stringByAppendingFormat:@"%@",unitArr[i] ];
			}
		}
		temp /= 10000;
		if (temp==0) {
			break;
		}
	}	
		
	return re_str;
}
-(void)showEnterFloor{
	CCSprite *text = (CCSprite*)[self getChildByTag:10004];
	id wait = [CCDelayTime actionWithDuration:3.0f];
	id remove = [CCCallFuncN actionWithTarget:self selector:@selector(removeNode:)];
	if(text){
		[text stopAllActions];
		[self removeChildByTag:10004 cleanup:YES];
	}
	//if (!text) {
    text = [CCSprite spriteWithFile:@"images/ui/timebox/packup_bg_.png"];
    text = getSpriteWithSpriteAndNewSize(text, CGSizeMake(250, 100));
    NSString *reStr = [self getFloorStringWith: floorIndex];
    //if ([reStr isEqualToString:@"零"]) {
    if ([reStr isEqualToString:NSLocalizedString(@"abyss_zero",nil)]) {
        //reStr = @"大厅";
        reStr = NSLocalizedString(@"abyss_hall",nil);
    }else{
        //reStr = [NSString stringWithFormat:@"第 %@ 层",reStr];
        reStr = [NSString stringWithFormat:NSLocalizedString(@"abyss_in_floor",nil),reStr];
    }
    NSString *cmd = [NSString stringWithFormat:@"^1*%@#ffff00#20#0*^5*",reStr];
    CCSprite *spr_top =nil; 
    CCSprite *spr =nil;
	//spr_top=drawString(@"^1*无尽深渊#ffff00#23#0*^5*", CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
    spr_top=drawString(NSLocalizedString(@"abyss_title",nil), CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
  
//	if (iPhoneRuningOnGame()) {
//        spr_top=drawString(iPhoneRuningOnGame()?@"^1*无尽深渊#ffff00#12#0*^5*":@"^1*无尽深渊#ffff00#23#0*^5*", CGSizeMake(200/2,0), getCommonFontName(FONT_1), 15/2, 16/2, @"#EBE2D0");
//        spr=drawString(cmd, CGSizeMake(200/2,0), getCommonFontName(FONT_1), 15/2, 16/2, @"#EBE2D0");
//    }else{
        spr=drawString(cmd, CGSizeMake(200,0), getCommonFontName(FONT_1), 15, 16, @"#EBE2D0");
//    }
    spr_top.anchorPoint = ccp(0.5,0);
    spr_top.position = ccp(text.contentSize.width/2,text.contentSize.height/2);
    [text addChild:spr_top];
    spr.anchorPoint = ccp(0.5,1);
    spr.position = ccp(text.contentSize.width/2,text.contentSize.height/2);
    [text addChild:spr];
//    if (iPhoneRuningOnGame()) {
//        [text setPosition:ccp(self.contentSize.width/2, self.contentSize.height*3/4)];
//    }else{
        [text setPosition:ccp(self.contentSize.width/2, self.contentSize.height*3/4)];
//    }
    [self addChild:text z:INTMAX_MAX tag:10004];
    [text runAction:[CCSequence actions:wait,remove, nil]];
    //	}else{
    //		[text stopAllActions];
    //		[text runAction:[CCSequence actions:wait,remove, nil]];
    //		CCLOG(@"stopAll-----------------------------------------------");
    //	}
}
-(void)showBuff{
	AbyssBuffButton *abButton = (AbyssBuffButton *)[[[GameLayer shared] content] getChildByTag:20099];
	if (!abButton) {
		abButton = [AbyssBuffButton spriteWithFile:@"images/animations/abyssbuff/0.png"];
		abButton.position = [self getBuffPoint];
		[[[GameLayer shared] content] addChild:abButton z:0 tag:20099];
		
		//加入动画
		abButton.visible = NO;
        ClickAnimation* buffAnimation= (ClickAnimation *)[[[GameLayer shared] content] getChildByTag:Abyss_buffAnimation_tag];
		if (buffAnimation==nil) {
			//buffAnimation = [ClickAnimation showInLayer:[GameLayer shared].content point:abButton.position path:@"images/animations/abyssbuff/" loop:YES];
			[ClickAnimation showInLayer:[GameLayer shared].content point:abButton.position path:@"images/animations/abyssbuff/" loop:YES];
		}
		
	}
	//TODO
	NSDictionary *globalDict = [[GameDB shared] getGlobalConfig];
	if (info && globalDict) {
		NSNumber *atkNumber = nil;
		atkNumber =[[info objectForKey:@"buff"] objectForKey:@"ATK"];
		int atk = 0;
		if (atkNumber) {
			atk = [atkNumber intValue];
		}else{
			atkNumber =[[info objectForKey:@"buff"] objectForKey:@"ATK_P"];
			if (atkNumber) {
				atk = [atkNumber intValue];
			}
		}
		
		//int hp = [[[info objectForKey:@"buff"] objectForKey:@"hp"] intValue];
		
		NSString *deepBuff = [globalDict objectForKey:@"deepBuff"];
		NSArray *bagsStrArr =[deepBuff componentsSeparatedByString:@"|"];
		NSString *atkStr = [bagsStrArr objectAtIndex:0];
		NSArray *atkArr = [atkStr componentsSeparatedByString:@":"];
		int atkBase = 1;
		if ([atkArr count]>1) {
			atkBase = [[atkArr objectAtIndex:1] intValue];
		}
		if (atkBase==0) {
			atkBase = 1;
		}
		
		int buffLayerCount = atk/atkBase;
		[abButton setAbyssLayer:buffLayerCount];
	}else{
		[abButton setAbyssLayer:0];
	}
		

}
//end
-(void)showCountdown{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCNode * node = [self getChildByTag:9001];
	if(node==nil){
		CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/abyss/bg-window.png"];
		bg.anchorPoint = ccp(0.5,0.5);
		bg.position = ccp(winSize.width/2,winSize.height/2);
		[self addChild:bg z:INT16_MAX-1 tag:9001];
	}
	
	CCLabelFX * label = (CCLabelFX*)[self getChildByTag:9002];
	if(!label){
		label = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter 
								  fontName:GAME_DEF_CHINESE_FONT 
								  fontSize:30
							  shadowOffset:CGSizeMake(-1.5, -1.5) 
								shadowBlur:2.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(winSize.width/2,winSize.height/2);
		label.color = ccRED;
		[self addChild:label z:INT16_MAX tag:9002];
	}
	
	[self unschedule:_cmd];
	if(autoTimes>=0){
		int s = autoTimes%60;
		int m = autoTimes/60%60;
		int h = autoTimes/(60*60);
		
//		label.string = [NSString stringWithFormat:@"结束挂机:%@%@%@",
//						(h>0?[NSString stringWithFormat:@"%d小时",h]:@""),
//						((h>0||m>0)?[NSString stringWithFormat:@"%d分",m]:@""),
//						[NSString stringWithFormat:@"%@秒",
//						 (s<10?[NSString stringWithFormat:@"0%d",s]:
//						  [NSString stringWithFormat:@"%d",s])]];
        label.string = [NSString stringWithFormat:NSLocalizedString(@"abyss_hang_up",nil),
						(h>0?[NSString stringWithFormat:NSLocalizedString(@"abyss_hour",nil),h]:@""),
						((h>0||m>0)?[NSString stringWithFormat:NSLocalizedString(@"abyss_minute",nil),m]:@""),
						[NSString stringWithFormat:NSLocalizedString(@"abyss_second",nil),
						 (s<10?[NSString stringWithFormat:@"0%d",s]:
						  [NSString stringWithFormat:@"%d",s])]];
		
		[self schedule:_cmd interval:1.0f];
	}else{
		
		[self removeCountdown];
		[NSTimer scheduledTimerWithTimeInterval:2.0f 
										 target:self 
									   selector:@selector(restart) 
									   userInfo:nil 
										repeats:NO];
		
		return;
	}
	autoTimes--;
	
}

-(void)removeCountdown{
	CCNode * node = [self getChildByTag:9001];
	if(node){
		[node removeFromParentAndCleanup:NO];
	}
	CCLabelFX * label = (CCLabelFX*)[self getChildByTag:9002];
	if(label){
		[label removeFromParentAndCleanup:NO];
	}
}

//get buff point
-(CGPoint)getBuffPoint{	
	//CGPoint target = CGPointZero;
	CGPoint target = ccp(750,625);
    if (iPhoneRuningOnGame()) {
        target=ccpHalf(target);
    }
//	NSArray *array = [[MapManager shared] getFunctionRect:@"animation" key:@"minig"];
//	if ([array count]>0) {
//		target = [[array objectAtIndex:0] CGPointValue];
//	}
	return target;
}

@end


