//
//  WorldMap.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WorldMap.h"
#import "Game.h"
#import "GameConfigure.h"
#import "CCSimpleButton.h"
#import "AnimationRole.h"
#import "RoleManager.h"
#import "NpcEffects.h"
#import "GameDB.h"
#import "RolePlayer.h"
#import "TaskManager.h"
#import "MapManager.h"
#import "LowerLeftChat.h"


#define EFFECT_OFFSET_PT_1      ccp(0, -50)
#define EFFECT_OFFSET_PT_2      ccp(0, 50)

//____________________________
static NSString * Maps_1[] = {
	@"{4000,4000}",
	@"{245,0}",
	@"{-120,-10}",
	@"{-310,30}",
	@"{290,-130}",
	@"{-220,-182}",
};
static NSString * Maps_2[] = {
	@"{100,20}",
};
static NSString * Anis_1[] = {
	@"{0,0}",
	@"{220,-10}",
	@"{-145,-20}",
	@"{-335,20}",
	@"{275,-140}",
	@"{-132,-195}",
};
//____________________________
static NSString * Anis_2[] = {
	@"{80,20}",
};
//____________________________

static WorldMap* s_WorldMap = nil;

@implementation WorldMap

@synthesize bBack;
@synthesize nextMap;
@synthesize target;
@synthesize call;
@synthesize bAuto;

+(BOOL)isShow{
	if(s_WorldMap){
		return YES;
	}
	return NO;
}

+(void)show{
	[[RoleManager shared].player stopMoveAndTask];
	if (!s_WorldMap) {
		s_WorldMap = [WorldMap node];
		s_WorldMap.bBack=YES;
		[[Game shared] addChild:s_WorldMap z:INT32_MAX];
	}
}

+(void)show:(int)mid target:(id)target call:(SEL)call{
	if (!s_WorldMap) {
		s_WorldMap = [WorldMap node];
		s_WorldMap.target=target;
		s_WorldMap.call=call;
		s_WorldMap.nextMap=mid;
		s_WorldMap.bAuto=YES;
		[[Game shared] addChild:s_WorldMap z:INT32_MAX];
	}
}

+(void)stopAll{
	if (s_WorldMap) {
		[s_WorldMap removeFromParentAndCleanup:YES];
		s_WorldMap = nil;
	}
}

+(void)updateChapterMap:(int)_cid map:(int)_mid{
	//todo 更新章节地图ID
	CCLOG(@"WorldMap -> updateChapterMap:%d--%d",_cid,_mid);
	if (_cid > 0 && _mid > 0) {		
		CCLOG(@"WorldMap->_cid-_mid");
		[[GameConfigure shared] updateUserWorldMap:_cid map:_mid];
	}
}

+(BOOL)checkShowWorldMap:(int)_next now:(int)_now{
	//---------------------
	
	//检测自身地图
	BOOL isOk = YES ;
	
//	NSMutableDictionary* _dict = [NSMutableDictionary dictionary];
//	[_dict setObject:[NSNumber numberWithInt:6] forKey:@"5"];
//	[_dict setObject:[NSNumber numberWithInt:1] forKey:@"2"];
//	[_dict setObject:[NSNumber numberWithInt:0] forKey:@"1"];
//	[_dict setObject:[NSNumber numberWithInt:5] forKey:@"4"];
//	[_dict setObject:[NSNumber numberWithInt:2] forKey:@"3"];
//	
//	[_dict setObject:[NSNumber numberWithInt:4] forKey:@"101"];
	
	NSDictionary* _dict = [[GameConfigure shared] getUserWorldMap];
	
	if (_dict != nil) {
		NSArray* array = [_dict allValues];
		
		isOk &= ([array containsObject:[NSNumber numberWithInt:_next]]&&
				 [array containsObject:[NSNumber numberWithInt:_now]]);
		
		isOk &= (_next > 0 && _now > 0);
		
	}else{
		return NO ;
	}
	
	return isOk;
	
}

-(void)doExit:(id)sender{
	[WorldMap stopAll];
}

-(void)dealloc{
	nextMap=0;
	[super dealloc];
}

-(id)init{
	if ((self=[super init])) {
		
		NSDictionary* dict = [[GameConfigure shared] getPlayerInfo];
		roleId = [[dict objectForKey:@"rid"] intValue];
		
		NSDictionary * db = [[GameDB shared] getRoleInfo:roleId];
		offset = [[db objectForKey:@"offset"] intValue];
		
		nextMap = 0;
		
	}
	return self;
}


-(void)onEnter{
	[super onEnter];
	[[LowerLeftChat share]EventCloseChat:nil];
	[[Window shared]removeAllWindows];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:INT16_MIN swallowsTouches:YES];
	CGSize size = [CCDirector sharedDirector].winSize;
	
	background = [CCSprite spriteWithFile:@"images/ui/world/world.jpg"];
	[self addChild:background];
	background.position=ccp(size.width/2, size.height/2);
	//background.scale = size.height/background.contentSize.height;
	
	if (bBack) {
		CCSimpleButton *back = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_back.png"];
		back.anchorPoint=ccp(1, 1);
		back.tag=200;
		back.target=self;
		back.call=@selector(doExit:);
		back.priority=INT16_MIN;
		
		if(iPhoneRuningOnGame()){
            back.anchorPoint=ccp(1, 0.5);
            back.contentSize = CGSizeMake(back.contentSize.width, back.contentSize.height*2);
			back.position=ccp(size.width - 10, size.height-10);
		}else{
			back.position=ccp(size.width - 20, size.height-10);
		}
		
		[self addChild:back];
	}
	
	if (!role) {
		
		role = [AnimationRole node];
		role.anchorPoint = ccp(0.5,0);
		[self addChild:role z:INT16_MAX];
		
		role.roleId = [RoleManager shared].player.role_id;
		role.suitId = [RoleManager shared].player.suit_id;
		role.roleDir = RoleDir_down;
		role.roleAction = RoleAction_stand;
		[role showRole];
		
		role.visible=NO;
	}
	
	[self showMaps];
	
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)showMaps{
	
	NSDictionary* _mDict = [[GameConfigure shared] getUserWorldMap];
	

	NSArray* keys = [_mDict allKeys];
	
	_curMapIndex = 0 ;
	_nextMapIndex = 0 ;
	_towardIndex = 0 ;
	CGSize screenSize=[CCDirector sharedDirector].winSize;
	for (NSString* _key in keys) {
		int i = [_key intValue];
		
		NSString *path = [NSString stringWithFormat:@"images/ui/world/%d.png",i];
		CCSimpleButton *scenes = [CCSimpleButton spriteWithFile:path];
		scenes.priority=INT16_MIN;
		scenes.tag = i ;
		[scenes setAnchorPoint:ccp(0, 0)];
		scenes.target = self;
		scenes.call = @selector(doTurnMap:);
		
		if (i < 100) {
			//主线章节地图
			CGSize offsize=CGSizeFromString(Maps_1[i-1]);
			scenes.position= ccp(screenSize.width/2+cFixedScale(offsize.width),screenSize.height/2+cFixedScale(offsize.height));
		}else{
			//外传章节地图
			int _r = i%100;
			CGSize offsize=CGSizeFromString(Maps_2[_r-1]);
			scenes.position= ccp(screenSize.width/2+cFixedScale(offsize.width),screenSize.height/2+cFixedScale(offsize.height));
		}
		
		int _mid = [[_mDict objectForKey:_key] intValue];
		
		//获得当前的地图ID
		if ([MapManager shared].mapId == _mid) {
			_curMapIndex = i ;
		}
		
		//用于下一个地图的跳转
		if (nextMap == _mid && _mid != 0) {
			_nextMapIndex = i;
		}
		
		[self addChild:scenes];
	}
	
	if (_curMapIndex > 0) {
		
		CGSize pt = CGSizeZero;
		if (_curMapIndex < 100) {
			pt = CGSizeFromString(Anis_1[_curMapIndex - 1]);
			
		}else{
			int _r = _curMapIndex%100;
			pt = CGSizeFromString(Anis_2[_r - 1]);
		}
		
		[self showPlayerArise:pt];
	}
	
	if (bAuto) {
		[self setButs:NO];
	}
	
}

-(void)setButs:(BOOL)_isOpen{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[CCSimpleButton class]]) {
				CCSimpleButton* _tray = (CCSimpleButton*)____node;
				_tray.isEnabled = _isOpen ;
			}
		}
	}
}

-(void)showPlayerArise:(CGSize)_pt{
	NpcEffects *effect = (NpcEffects*)[self getChildByTag:-7677];
	if (effect) {
		[effect stopAllActions];
		[effect removeFromParentAndCleanup:YES];
		effect = nil;
	}
	
	if (role != nil) {
		role.visible= NO;
	}
	
	effect = [NpcEffects node];
	
	[self addChild:effect z:INT16_MAX tag:-7677];
	
	effect.anchorPoint=ccp(0.5, 0);
	CGSize screenSize=[CCDirector sharedDirector].winSize;
	
	effect.position=  ccp(screenSize.width/2+cFixedScale(_pt.width),screenSize.height/2+cFixedScale(_pt.height));
    
	[effect showEffect:3 target:self call:@selector(endArise)];
	if (role != nil) {
		CGPoint pt = CGPointZero ;
		if (effect) {
			pt = effect.position;
		}
		role.visible=YES;
		pt=ccp(pt.x,pt.y-cFixedScale(offset)+cFixedScale(30));
		role.position =ccpAdd(pt, ccp(0, 100));
		role.opacity=0;
		id delay=[CCDelayTime actionWithDuration:0.5];
		id fain=[CCFadeIn actionWithDuration:0.5];
		id moveDown=[CCMoveTo actionWithDuration:0.5 position:pt];
		id feinEs=[CCEaseBackIn actionWithAction:moveDown];
		id swq=[CCSpawn actions:fain,feinEs,nil];
		id seq=[CCSequence actions:delay,swq,nil];
		[role runAction:seq];
	}
}

-(void)endArise{
	CCLOG(@"endArise");
//	NpcEffects *effect = (NpcEffects*)[self getChildByTag:-7677];
	
//	CGPoint pt = CGPointZero ;
//	if (effect) {
//		pt = effect.position;
//	}
	
	

	if (bAuto && _nextMapIndex > 0) {
		CGSize pt = [self getPositonWithIndex:_nextMapIndex];
		bAuto = NO ;
		[self showPlayerArise:pt];
	}else if (_nextMapIndex > 0){
		
		[Game setMapId:nextMap];
		[[Game shared] doTrunToMap];
		
	}else if (_towardIndex > 0){
		NSDictionary* dict = [[GameConfigure shared] getUserWorldMap];
		
		NSString* _key = [NSString stringWithFormat:@"%d",_towardIndex];
		
		int _mid = [[dict objectForKey:_key] intValue];
		if (_mid > 0) {
			[Game setMapId:_mid];
			[[Game shared] doTrunToMap];
		}
		[self setButs:YES];
	}
}

-(CGSize)getPositonWithIndex:(int)_index{
	CGSize pt = CGSizeZero;
	if (_index < 100) {
		pt = CGSizeFromString(Anis_1[_index - 1]);
	}else{
		_index %= 100;
		pt = CGSizeFromString(Anis_2[_index - 1]);
	}
	return pt;
}

-(void)doTurnMap:(CCSimpleButton*)sender{
	CCLOG(@"map->%d",sender.tag);
	int _index = sender.tag;
	
	if (_curMapIndex == _index) {
		CCLOG(@"same map!!");
		return ;
	}
	
	_towardIndex = _index ;
	
	[self setButs:NO];
	
	CGSize pt = [self getPositonWithIndex:_index];
	[self showPlayerArise:pt];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	CCLOG(@"world map");
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
}

@end














