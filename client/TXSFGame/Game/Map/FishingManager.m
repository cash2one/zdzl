//
//  FishingManager.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "FishingManager.h"
#import "MapManager.h"
#import "Game.h"
#import "GameUI.h"
#import "CCSimpleButton.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "intro.h"
#import "ButtonGroup.h"
#import "NPCManager.h"
#import "GameNPC.h"
#import "GameLayer.h"
#import "Window.h"
#import "AnimationViewer.h"
#import "GameEffects.h"
#import "InfoAlert.h"
#import "Arena.h"
#import "CJSONDeserializer.h"

#define BG_PACKUP 8
#define BG_PACKUP_IN 9
#define BT_PACKUP 10
#define POS_ITEMSP_Y   cFixedScale(20)
#define POS_PACKUP_BTN_Y  cFixedScale(-50)
#define CGS_ITEMPACKBG_ADD_X  cFixedScale(100)
#define CGS_ITEMPACKBG_Y   cFixedScale(40)

#define FISH_MAP_ID	1003

#define Fish_Gear_First		100

static FishingManager* s_FishingManager = nil;
static bool s_isfish=NO;

static int sortPoints(NSValue *_value1, NSValue *_value2, void*pt){
	
	CGPoint pt1 = getTiledRectCenterPoint([_value1 CGRectValue]);
	CGPoint pt2 = getTiledRectCenterPoint([_value2 CGRectValue]);
	CGPoint target = CGPointFromString(pt);
	
	if(ccpDistance(pt1, target) < ccpDistance(pt2, target)) return NSOrderedAscending;
	if(ccpDistance(pt1, target) > ccpDistance(pt2, target)) return NSOrderedDescending;
	
	return NSOrderedSame;
}

@implementation FishingManager
@synthesize baitQuality;
@synthesize fishCount;
//check is fishing
+(BOOL)checkIsFishing{
    return s_isfish;
}

+(FishingManager*)shared{
	if (!s_FishingManager) {
		s_FishingManager = [FishingManager node];
		[s_FishingManager retain];
	}
	return s_FishingManager;
}

+(void)stopAll{
	
	if (s_FishingManager) {
		[s_FishingManager removeButton];
		[s_FishingManager removeGear];
		
		[s_FishingManager removeFromParentAndCleanup:YES];
		[s_FishingManager release];
		s_FishingManager = nil ;
	}
}

+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_Fish){
		if(s_FishingManager){
			[s_FishingManager checkRestart];
		}else{
			[FishingManager enterFishing];
		}
	}else{
		[FishingManager stopAll];
	}
}
+(void)enterFishing{
	if ([[GameConfigure shared] checkPlayerFunction:Unlock_fish]) {
		[[FishingManager shared] start];
	}else{
		//[ShowItem showItemAct:@"尚未开启钓鱼功能"];
	}
}
+(void)exitFishing{
//	if(s_FishingManager.parent){
		[FishingManager stopAll];//
		[RoleManager shared].player.state = Player_state_normal ;
		[[Game shared] backToMap:nil call:nil];//
//	}
}

-(void)start{
	[GameConnection request:@"fishEnter" data:[NSDictionary dictionary] target:self call:@selector(didGetFishData:)];
}

-(void)checkRestart{
	if(!self.parent){
		//[[GameUI shared] addChild:self z:-1];
		self.visible = YES ;
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_fishing];
	}
	
	//绘制按钮
	[self showButton];
	[self showBack];
	
	fishGearPoints = [NSMutableArray arrayWithArray:[[MapManager shared] getFunctionRect:@"fish" key:@"fish"]];
	[fishGearPoints retain];
	
	fishGear = [FishGear node];
	[fishGear retain];
	fishGear.points = fishGearPoints;
	fishGear.target = self;
}

-(void)didGetFishData:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		if (!self.parent) {
			//[[GameUI shared] addChild:self z:-1];
			self.visible = YES ;
			[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_fishing];
		}
		NSDictionary* data = getResponseData(sender);
		if (data) {
			[self loadFishData:data];
			[self showFishMap];
		}
		
	}
}
-(void)showFishMap{
	if([MapManager shared].mapId==FISH_MAP_ID){
		[self checkRestart];
	}
	else{
		[[Game shared] trunToMap:FISH_MAP_ID target:nil call:nil];
	}
}
-(void)loadFishData:(NSDictionary*)dict{
	times = [[dict objectForKey:@"n"] intValue];
}
// 显示最新渔获待收
-(void)showFishObtain
{
	[self removeChildByTag:BG_PACKUP];
	
	NSArray *waitPackup=[[GameConfigure shared]getPlayerWaitItemListByType:PlayerWaitItemType_3];
	if(waitPackup.count>0){
		
		NSMutableArray *total=[NSMutableArray array];
		
		CJSONDeserializer *json=[CJSONDeserializer deserializer];
		for(NSDictionary *dictjson in waitPackup){
			NSString *jsonstr=[dictjson objectForKey:@"items"];
			NSData *jsondata=[jsonstr dataUsingEncoding:NSUTF8StringEncoding];
			NSArray *itemdict=[json deserialize:jsondata error:nil];
			for(NSDictionary *item in itemdict){
				[total addObject:item];
			}
		}
		
		[self creatItemList:total];
	} else {
		CCLOG(@"没有渔获待收");
		
		[self removeChildByTag:BG_PACKUP];
	}
}
-(void)onEnter{
	[super onEnter];
	s_isfish = NO;
    
	menu = [CCMenu menuWithItems:nil];
	[self addChild:menu];
	
	[[Intro share] hideCurrenTips];
	if (!catchs) {
		catchs = [NSMutableArray array];
		[catchs retain];
	}
	//[self showBack];
    // 规则
    //fix chao
    CGSize winSize = [[CCDirector sharedDirector] winSize];
	RuleButton *ruleButton = [RuleButton node];
	ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y));
	ruleButton.type = RuleType_fishing;
	ruleButton.priority = -129;
	[self addChild:ruleButton];
    //end
	
	[self showFishObtain];
}
-(void)showBack{
	
	[menu removeChildByTag:555 cleanup:YES];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	NSArray * btns;
	CCMenuItemImage * item;
	btns = getBtnSpriteForScale(@"images/ui/button/bt_backmap.png",1.1f);
	CCSprite *spr1 = [btns objectAtIndex:0];
	CCSprite *spr2 = [btns objectAtIndex:1];
	
	//NSDictionary *dictionary = [[GameDB shared] getMapInfo:[MapManager shared].mapId];
	NSString *name = [[MapManager shared] getMapName];
	//	if (dictionary) {
	//		name = [dictionary objectForKey:@"name"];
	//	}else{
	//		name = @"";
	//	}
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
    
    name1.position = ccp(spr1.contentSize.width/2 - cFixedScale(10), (spr1.contentSize.height)*1.2/2);
    name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(10), (spr2.contentSize.height)*1.2/2);
    
	[spr2 addChild:name2];
	item = [CCMenuItemImage itemWithNormalSprite:spr1
								  selectedSprite:spr2
										  target:self
										selector:@selector(doExit:)];
	if (iPhoneRuningOnGame()) {
		item.scale=1.13f;
        item.position = ccp(winSize.width/2.0f-item.contentSize.width*item.scale/2.0f+5.5f,winSize.height/2.0f-item.contentSize.height*item.scale/2.0f+2);
	}else{
		item.position = ccp(winSize.width/2-item.contentSize.width/2+9.0f,winSize.height/2-cFixedScale(35)+9.0f);
	}
	item.tag = 555;
	
	[menu addChild:item ];
	
}
-(int)getPointIndex:(CGPoint)point
{
	for (int i = 0; i < fishGearPoints.count; i++) {
		NSValue *value = [fishGearPoints objectAtIndex:i];
		CGPoint pt = getTiledRectCenterPoint([value CGRectValue]);
		if (CGPointEqualToPoint(pt, point)) {
			return i;
		}
	}
	return 0;
}
-(void)onExit{
	// 去除渔具
    s_isfish = NO;
	if (fishGearPoints) {
		[fishGearPoints release];
		fishGearPoints = nil;
	}
	
	[self removeGear];
	
	menu = nil;
	
	if (catchs) {
		[catchs release];
		catchs = nil;
	}
	
	[self removeButton];
	[[Intro share] showCurrenTips];
    [GameConnection freeRequest:self];
	[super onExit];
}
-(void)doExit:(id)sender{
    if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	[FishingManager exitFishing];
}
-(void)showButton{
	[self removeButton];
	
	// npc1
	GameNPC* pNpc1 = [[NPCManager shared] getNPCById:66];
	if (pNpc1) {
		CGPoint pt = pNpc1.position;
        pt = ccpAdd(pt, ccp(0, [pNpc1 getNpcHeight]));
		
		/*
		if (iPhoneRuningOnGame()) {
            pt = ccpAdd(pt, ccp(0, 250/2));
        }else{
            pt = ccpAdd(pt, ccp(0, 250));
        }
		 */
		
		CCSimpleButton *bt1 = [CCSimpleButton spriteWithFile:@"images/ui/fish/bt_begin_1.png"
													  select:@"images/ui/fish/bt_begin_2.png"];
		bt1.target=self;
		bt1.anchorPoint = ccp(0.5, 0);
		bt1.call=@selector(doFishing:);
		bt1.position=pt;
		bt1.priority=-1;
		[[GameLayer shared].content addChild:bt1 z:INT32_MAX tag:GameLayer_Fish_Button_Begin];
	}
	
	// npc2
	GameNPC* pNpc2 = [[NPCManager shared] getNPCById:21];
	if (pNpc2) {
		CGPoint pt = pNpc2.position;
		pt = ccpAdd(pt, ccp(0, [pNpc2 getNpcHeight]));
		
        /*
		if (iPhoneRuningOnGame()) {
            pt = ccpAdd(pt, ccp(-58/2, 171/2));
            
        }else{
            pt = ccpAdd(pt, ccp(-58, 171));
        }
		*/
		
		CCSimpleButton *bt2 = [CCSimpleButton spriteWithFile:@"images/ui/fish/bt_convert_1.png"
													  select:@"images/ui/fish/bt_convert_2.png"];
		bt2.target=self;
		bt2.call=@selector(doConvert:);
		bt2.anchorPoint = ccp(0.5, 0);
		bt2.position=pt;
		bt2.priority=-1;
		[[GameLayer shared].content addChild:bt2 z:INT32_MAX tag:GameLayer_Fish_Button_Convert];
	}
}
-(void)removeButton
{
	CCNode *node1 = [[GameLayer shared].content getChildByTag:GameLayer_Fish_Button_Begin];
	if (node1) {
		[node1 removeFromParentAndCleanup:YES];
		node1 = nil;
	}
	CCNode *node2 = [[GameLayer shared].content getChildByTag:GameLayer_Fish_Button_Convert];
	if (node2) {
		[node2 removeFromParentAndCleanup:YES];
		node2 = nil;
	}
}
-(void)removeGear
{
	if (fishGear) {
		[fishGear removeAll];
		[fishGear release];
		fishGear = nil;
	}
}
-(void)doFishing:(id)sender{
    if([[Window shared] isHasWindow] || [Arena arenaIsOpen] ){
        return;
    }
	CGPoint pt = [self getFishPoint];
	[[RoleManager shared].player moveTo:pt target:self call:@selector(showBait)];
	fishGearIndex = [self getPointIndex:pt];
}
-(void)doConvert:(id)sender{
    if([[Window shared] isHasWindow] || [Arena arenaIsOpen] ){
        return;
    }
	[[Window shared] showWindow:PANEL_FISH_Box];
}
-(CGPoint)getFishPoint{
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[MapManager shared] getFunctionRect:@"fish" key:@"fish"]];
	if ([array count] > 0) {
		[array sortUsingFunction:sortPoints context:NSStringFromCGPoint([RoleManager shared].player.position)];
		NSMutableArray *points = [NSMutableArray array];
		for (NSValue *value in array) {
			CGPoint pt = getTiledRectCenterPoint([value CGRectValue]);
			[points addObject:[NSValue valueWithCGPoint:pt]];
		}
		CGPoint target = [[RoleManager shared] getFreePoint:points];
		if (target.x == -1 && target.y == -1) {
			int index = getRandomInt(0, points.count - 1);
			target = [[points objectAtIndex:index] CGPointValue];
		}
		return target;
	}
	return CGPointZero;
}
-(void)showBait{
	CGPoint pt = [RoleManager shared].player.position;
	pt = ccpAdd(pt, ccp(200, 0));
    if (iPhoneRuningOnGame()) {
        pt = ccpAdd(pt, ccp(200/2, 0));
    }
	[[RoleManager shared].player updateDir:pt];
	[FishBait show:self call:@selector(beginFishing:)];
}
-(void)beginFishing:(NSDictionary*)data{
	baitQuality = [[data objectForKey:@"baitType"] intValue];
	fishCount = [[data objectForKey:@"upCount"] intValue];
	fishGear.call = @selector(beginFishingCallbackDelay);
	[fishGear showStart:fishGearIndex];
    //
    s_isfish = YES;
}
-(void)beginFishingCallbackDelay
{
	[GameEffectsBlockTouck lockScreen];
	[self scheduleOnce:@selector(beginFishingCallback) delay:0.2];
}
-(void)beginFishingCallback
{
	FishAction *fishAction = [FishAction show:self call:@selector(endFishing:)];
	fishAction.iid = baitQuality;
	[GameEffectsBlockTouck unlockScreen];
}
-(void)endFishing:(NSString*)data
{
	fishUpType = [data intValue];
	fishGear.call = @selector(endFishingCallback);
	[fishGear showStop:fishGearIndex];
}
-(void)endFishingCallback
{
	NSMutableDictionary *fishDict = [NSMutableDictionary dictionary];
	[fishDict setObject:[NSNumber numberWithInt:fishCount] forKey:@"num"];
	[fishDict setObject:[NSNumber numberWithInt:baitQuality] forKey:@"iid"];
	[fishDict setObject:[NSNumber numberWithInt:fishUpType] forKey:@"qt"];
	[GameConnection request:@"fishUp" data:fishDict target:self call:@selector(didEndFishing:)];
}
// 起杆返回
-(void)didEndFishing:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			/*
			NSArray *items =  [dict objectForKey:@"item"];
			if ([items count] > 0) {
				NSDictionary *gets = [[GameConfigure shared] handleItemsInfo:items];
				NSArray *keys =[gets allKeys];
				[catchs removeAllObjects];
				for (NSString *_key in keys) {
					int count = [[gets objectForKey:_key] intValue];
					for (int i = 0; i < count; i++) {
						[catchs addObject:_key];
					}
				}
				if (catchs && [catchs count] > 0) {
					[self showObtain];
				}
			}
			 */
			
			[[GameConfigure shared] updatePackage:dict];
			
			[self showFishObtain];
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
    //
    s_isfish = NO;
}

#pragma mark 拾取渔获
-(void)packupbox:(id)n{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	[GameConnection request:@"waitFetch" format:@"type::3" target:self call:@selector(packupBoxSuss:)];
}

#pragma mark 拾取物品成功
-(void)packupBoxSuss:(id)n{
	NSDictionary *dict=n;
	int su=[[dict objectForKey:@"s"]integerValue];
	NSString *key=[NSString stringWithFormat:@"%@",[dict objectForKey:@"m"]];
	if(su==1){
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:[dict objectForKey:@"d"]];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
		[[GameConfigure shared]updatePackage:[dict objectForKey:@"d"]];
		CCSprite *sprite=(CCSprite*)[self getChildByTag:BG_PACKUP];
		[sprite removeFromParentAndCleanup:YES];
	}else{
		[ShowItem showErrorAct:key];
	}
}

-(void)creatItemList:(NSArray*)n {
	//return;
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

-(CCSprite*)catchSprite:(int)_iid count:(int)_count quality:(int)_quality{
	NSString *path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",_quality];
	CCSprite *result = [CCSprite spriteWithFile:path];
	CCSprite *item = getItemIcon(_iid);
	NSString *string = [NSString stringWithFormat:@"%d",_count];
	CCLabelFX *label = [CCLabelFX labelWithString:string
										 fontName:getCommonFontName(FONT_1)
										 fontSize:20
									 shadowOffset:CGSizeMake(2, 2)
									   shadowBlur:0.2
									  shadowColor:ccc4(0, 0, 0, 128)
										fillColor:ccc4(255, 255, 0, 255)];
	label.anchorPoint=ccp(0.5, 0.5);
	[item addChild:label];
	label.position=ccp(item.contentSize.width,item.contentSize.height);
	[result addChild:item];
	item.position=ccp(result.contentSize.width/2, result.contentSize.height/2);
	NSDictionary *dict =[[GameDB shared] getItemInfo:_iid];
	if (dict) {
		NSString *name = [dict objectForKey:@"name"];
		ccColor3B cl = getColorByQuality(_quality);
		CCLabelFX *_name = [CCLabelFX labelWithString:name
											 fontName:getCommonFontName(FONT_1)
											 fontSize:20
										 shadowOffset:CGSizeMake(2, 2)
										   shadowBlur:0.2
										  shadowColor:ccc4(0, 0, 0, 128)
											fillColor:ccc4BFromccc4F(ccc4FFromccc3B(cl))];
		[result addChild:_name];
        if (iPhoneRuningOnGame()) {
            _name.position=ccp(result.contentSize.width/2, -16/2);
        }else{
            _name.position=ccp(result.contentSize.width/2, -16);
        }
	}
	return result;
}
-(void)showObtain{
	[self removeObtain];
	CCSprite *obtain = [CCSprite spriteWithFile:@"images/ui/panel/obtain.png"];
	[self addChild:obtain z:10 tag:8779];
	obtain.anchorPoint=ccp(0.5, 0.5);
	CGSize winSize = [CCDirector sharedDirector].winSize;
    if (iPhoneRuningOnGame()) {
        obtain.position=ccp(winSize.width/2, winSize.height/2 - 150/2);
    }else{
        obtain.position=ccp(winSize.width/2, winSize.height/2 - 150);
    }
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (catchs && catchs.count > 0) {
		for (NSString *key in catchs) {
			int _num = [[dict objectForKey:key] intValue];
			_num += 1;
			[dict setObject:[NSNumber numberWithInt:_num] forKey:key];
		}
		//-----------------------------------------------------------
		NSArray *keys = [dict allKeys];
		//
		float _w = 84 * keys.count + 10*(keys.count-1);
		float startX = (obtain.contentSize.width-_w)/2;
		float _y = obtain.contentSize.height/2+16;
		
		for (NSString *iid in keys) {
			int _iid = [iid intValue];
			int count = [[dict objectForKey:iid] intValue];
			NSDictionary *item = [[GameDB shared] getItemInfo:_iid];
			int quality = [[item objectForKey:@"quality"] intValue];
			CCSprite *sprite = [self catchSprite:_iid count:count quality:quality];
			[obtain addChild:sprite];
			sprite.anchorPoint=ccp(0, 0.5);
			sprite.position=ccp(startX, _y);
			startX += 94 ;
		}
	}
	
	id act1 = [CCDelayTime actionWithDuration:2.5];
	id act2 = [CCCallFunc actionWithTarget:self selector:@selector(removeObtain)];
	
	[obtain runAction:[CCSequence actions:act1,act2,nil]];
	
}
-(void)removeObtain{
	CCSprite *obtain = (CCSprite*)[self getChildByTag:8779];
	if (obtain) {
		[obtain removeFromParentAndCleanup:YES];
		obtain=nil;
	}
}

@end
