//
//  OtherPlayerPanel.m
//  TXSFGame
//
//  Created by Soul on 13-3-17.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "OtherPlayerPanel.h"
#import "PlayerDataHelper.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "Config.h"
#import "GameDB.h"
#import "EquipmentTray.h"
#import "ButtonGroup.h"
#import "CCNode+AddHelper.h"
#import "MessageBox.h"

#import "RoleImageViewerContent.h"

#define CGS_self  CGSizeMake(cFixedScale(86), cFixedScale(86))

#define POS_title_offset			cFixedScale(10)
#define POS_close_offsetX			cFixedScale(44)
#define POS_close_offsetY			cFixedScale(42)


#define OFFSET_CBE_VALUE			cFixedScale(75)
#define OFFSET_CBE_POSITION			cFixedScale(185)
#define OFFSET_LEVEL_POSITION		cFixedScale(17)

#define OFFSET_BG_CHARACTER			cFixedScale(127)


#define OFFSET_CBE_SPRITE_X			cFixedScale(344)
#define OFFSET_CBE_SPRITE_Y			cFixedScale(50)

#define OFFSET_ROLE_TAB_1			cFixedScale(80)
#define OFFSET_ROLE_TAB_2			cFixedScale(66)
#define OFFSET_ROLE_TAB_3			cFixedScale(68)

#define OFFSET_WEAPON_PT			ccp(cFixedScale(230), cFixedScale(465))
#define OFFSET_WEAPON_LABEL			ccp(cFixedScale(200) , cFixedScale(465))

#define OFFSET_FATE_PT				ccp(cFixedScale(455), cFixedScale(465))
#define OFFSET_FATE_LABEL			ccp(cFixedScale(425), cFixedScale(465))

#define OFFSET_CHARACTER_IMAGE_PT	ccp(cFixedScale(344), cFixedScale(135))

#define OFFSET_DES					cFixedScale(50)



static inline NSArray* getRoleTab(int rid){
	
	if (rid <= 0) {
		CCLOG(@"PlayerPanel->getRoleTab:%d",rid);
		return nil;
	}
	
	CCSprite* bg1 = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
	CCSprite* bg2 = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
	CCSprite* i1  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	CCSprite* i2  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	[bg1 Category_AddChildToCenter:i1];
	[bg2 Category_AddChildToCenter:i2];
	
	NSArray* array = [NSArray arrayWithObjects:bg1,bg2,nil];
	
	return array;
}


static inline CGPoint getPartPositionBase(EquipmentPart _part){
	if (_part == EquipmentPart_head)		return ccp(180 ,380);
	if (_part == EquipmentPart_body)		return ccp(180 ,283);
	if (_part == EquipmentPart_foot)		return ccp(180 ,185);
	if (_part == EquipmentPart_necklace)	return ccp(505 ,380);
	if (_part == EquipmentPart_sash)		return ccp(505 ,283);
	if (_part == EquipmentPart_ring)		return ccp(505 ,185);
	
	return CGPointZero;
}

static inline CGPoint getPartPosition(EquipmentPart _part){
	
	CGPoint pt = getPartPositionBase(_part);
	
	return ccp(cFixedScale(pt.x), cFixedScale(pt.y));
}

static inline CGPoint getLabelPositionBase(int _part){
	
	if (_part == 0)		return ccp(185 ,105);
	if (_part == 1)		return ccp(320 ,105);
	if (_part == 2)		return ccp(455 ,105);
	if (_part == 3)		return ccp(185 ,85);
	if (_part == 4)		return ccp(320 ,85);
	if (_part == 5)		return ccp(455 ,85);
	
	return CGPointZero;
}


static inline CGPoint getLabelPosition(int _part){
	
	CGPoint pt = getLabelPositionBase(_part);
	
	return ccp(cFixedScale(pt.x), cFixedScale(pt.y));
	
}


@implementation Cbe

-(void)onEnter{
	[super onEnter];
	
	CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/power-bg.png"];
	self.contentSize = background.contentSize;
	[self Category_AddChildToCenter:background];
	
	CCSprite *title = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/power-title.png"];
	[self addChild:title];
	title.anchorPoint = ccp(0, 0.5);
	title.position=ccp(OFFSET_CBE_VALUE, self.contentSize.height/2);
}

-(void)onExit{
	[super onExit];
}

-(void)updatePower:(int)_power{
	CCLOG(@"PowerSprite->updatePower");
	
	[self removeChildByTag:676 cleanup:YES];
	
	NSString* path = [NSString stringWithFormat:@"images/ui/num/num-2.png"];
	CCSprite* ___sprite = getImageNumber(path, 15, 25, _power);
	___sprite.anchorPoint=ccp(0, 0.5);
	
	[self addChild:___sprite z:2 tag:676];
	
	___sprite.position=ccp(OFFSET_CBE_POSITION, self.contentSize.height/3);
	
}

@end


@implementation OtherEquipmentTray

@synthesize ueid  = _ueid;
@synthesize eid   = _eid;
@synthesize part  = _part;
@synthesize rid	  = _rid;
@synthesize level = _level;
@synthesize quality = _quality;

-(id)init{
	if (self = [super init]) {
		self.contentSize=CGS_self;
	}
	return self ;
}
-(void)dealloc{
	
	CCLOG(@"OtherEquipmentTray->dealloc");
	
	[super dealloc];
	
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-148 swallowsTouches:YES];
	
}

-(void)onExit{
	[self unscheduleAllSelectors];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
	
}

-(void)setPart:(int)part{
	_part = part ;
	
	[self removeChildByTag:2008 cleanup:YES];
	
	NSString* path = [NSString stringWithFormat:@"images/ui/panel/character_panel/eq%d.png",part];
	CCSprite* _sprite = [CCSprite spriteWithFile:path];
	[self Category_AddChildToCenter:_sprite z:0 tag:2008];
}

-(void)setEid:(int)eid{
	_eid = eid ;
	
	[self removeChildByTag:3008 cleanup:YES];
	
	if (eid <= 0) return ;
	
	CCSprite* __sprite = getEquipmentIcon(_eid);
	
	if (__sprite != nil) {
		__sprite.tag = 3008;
		[self Category_AddChildToCenter:__sprite z:4];
	}
	
}

-(void)setQuality:(ItemQuality)quality{
	_quality = quality;
	
	[self removeChildByTag:1007 cleanup:YES];
	[self removeChildByTag:1008 cleanup:YES];
	
	if (_quality < IQ_WHITE) return ;
	
	NSString* path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
	CCSprite* __sprite = [CCSprite spriteWithFile:path];
	__sprite.tag = 1007 ;
	__sprite.visible= YES;
	[self Category_AddChildToCenter:__sprite z:2];
	
	NSString* path2 = [NSString stringWithFormat:@"images/ui/common/quality%dSelect.png",quality];
	CCSprite* __sprite2 = [CCSprite spriteWithFile:path2];
	__sprite2.tag = 1008;
	__sprite2.visible= NO;
	[self Category_AddChildToCenter:__sprite2 z:2];
	
}

-(void)setLevel:(int)level{
	_level = level ;
	
	[self removeChildByTag:4009 cleanup:YES];
	[self removeChildByTag:4010 cleanup:YES];
	
	if (_level <= 0) return ;
	
	CGRect rect = CGRectMake(cFixedScale(150), 0, cFixedScale(15), cFixedScale(25));
	CCSprite *num_1 = [CCSprite spriteWithFile:@"images/ui/num/num-1.png" rect:rect];
	
	CCSprite *num_2 = getImageNumber(@"images/ui/num/num-1.png", 15, 20, _level);
	
	[self addChild:num_1 z:5];
	[self addChild:num_2 z:5];
	
	num_1.anchorPoint = num_2.anchorPoint = ccp(0, 1.0);
	
	num_1.tag = 4009 ;
	num_2.tag = 4010 ;
	
	num_1.position=ccp(0, self.contentSize.height);
	num_2.position=ccp(OFFSET_LEVEL_POSITION, self.contentSize.height);
	
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		CCLOG(@"OtherEquipmentTray->ccTouchBegan");
		return YES;
	}
	return NO ;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		CCLOG(@"OtherEquipmentTray->ccTouchEnded");
		OtherPlayerPanel* panel = (OtherPlayerPanel*)self.parent;
		if (panel != nil && _ueid > 0 && _part > 0) {
			[panel requestShowEquipmentDescribe:_ueid part:_part];
		}
	}
}

@end


@implementation OtherPlayerPanel

+(void)show:(NSDictionary *)_info{
	if (_info == nil) return ;
	
	[[Window shared] removeAllWindows];
	
	if (![[Window shared] isHasWindowByType:PANEL_OTHER_PLAYER_INFO]) {
		
		OtherPlayerPanel* _other = [OtherPlayerPanel node];
		
		[[Window shared] addChild:_other z:10 tag:PANEL_OTHER_PLAYER_INFO];
		
		[_other setInfo:_info];
		
	}
	
}

+(void)showOver:(NSDictionary *)_info{
	if (_info == nil) return ;
	
	
	if (![[Window shared] isHasWindowByType:PANEL_OTHER_PLAYER_INFO]) {
		
		OtherPlayerPanel* _other = [OtherPlayerPanel node];
		
		[[Window shared] addChild:_other z:10 tag:PANEL_OTHER_PLAYER_INFO];
		
		[_other setInfo:_info];
		
	}
	
}


-(void)onExit{
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-100 swallowsTouches:YES];
	
	CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/p1.png"];
	if (background != nil) {
		self.contentSize = background.contentSize;
	}
	[self addChild:background z:0];
	background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	
	
	CGSize size = [CCDirector sharedDirector].winSize;
	self.position = ccp(size.width/2 , size.height/2);
	
	
	CCSprite *title = [CCSprite spriteWithFile:@"images/ui/panel/t8.png"];
	title.position = ccp(self.contentSize.width/2,self.contentSize.height-POS_title_offset);
	[self addChild:title z:0];
	
	
	CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"
												  select:nil
												  target:self
													call:@selector(doExit:)
												priority:-110];
	
	
	bnt.position=ccp(self.contentSize.width  - POS_close_offsetX,
					 self.contentSize.height - POS_close_offsetY);
	
	
	[self addChild:bnt z:1];
	
	
	CCSprite *bg_character = [CCSprite spriteWithFile:@"images/ui/panel/p6.jpg"];
	bg_character.anchorPoint=ccp(0, 1.0);
	bg_character.position=ccp(OFFSET_BG_CHARACTER, self.contentSize.height-cFixedScale(66));
	
	[self addChild:bg_character z:1];
	
	
	for (int i = EquipmentPart_head; i <= EquipmentPart_ring; i++) {
		OtherEquipmentTray *mEq1 = [OtherEquipmentTray node];
		mEq1.position=getPartPosition(i);
		[self addChild:mEq1 z:5 tag:8000 + i];
		mEq1.part = i;
	}
	
	
	_msgMgr = [MessageBox create:ccp(cFixedScale(10), cFixedScale(20)) color:ccc4(128, 128, 128, 200)];
	if (iPhoneRuningOnGame()) {
		_msgMgr.scale = 0.5;
	}
	_msgMgr.visible = NO;
	_msgMgr.AdjustWidth = cFixedScale(30);
	[self addChild:_msgMgr z:INT16_MAX];
	
	
	_cbeMgr = [Cbe node];
	[self addChild:_cbeMgr z:10];
	
	_cbeMgr.position = ccp(OFFSET_CBE_SPRITE_X,OFFSET_CBE_SPRITE_Y);
	
	_cbeMgr.visible = NO;
	
	
	
	[self showLabels];
	[self showFunctions];
	
}

-(void)freeData{
	
	if (_info != nil) {
		[_info release];
		_info = nil ;
	}
	
	if (roleInfos != nil) {
		[roleInfos release];
		roleInfos = nil ;
	}
	
	if (equipInfos != nil) {
		[equipInfos release];
		equipInfos = nil ;
	}
	
	if (equipSetInfos != nil) {
		[equipSetInfos release];
		equipSetInfos = nil ;
	}
	
	if (fateInfos != nil) {
		[fateInfos release];
		fateInfos = nil ;
	}
	
	if (armInfos != nil) {
		[armInfos release];
		armInfos = nil ;
	}
	
	if (skillInfos != nil) {
		[skillInfos release];
		skillInfos = nil ;
	}
	
}

-(void)dealloc{
	CCLOG(@"OtherPlayerPanel - dealloc");
	[self freeData];
	[super dealloc];
}


-(void)doExit:(CCSimpleButton*)_sender{
	CCLOG(@"doExit");
	[[Window shared] removeWindow:PANEL_OTHER_PLAYER_INFO];
}

-(void)setInfo:(NSDictionary *)info{
	
	[self freeData];
	
	if (info == nil) return ;
	
	_info = [NSDictionary dictionaryWithDictionary:info];
	[_info retain];
	
	
	NSArray* roles = [NSMutableArray arrayWithArray:[_info objectForKey:@"roles"]];
	
	NSDictionary * infos = [[GameDB shared] getRoleInfosByIds:getArrayListDataByKey(roles,@"rid")];
	roleInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[roleInfos retain];
	
	NSDictionary* iDict = [_info objectForKey:@"ilist"];
	
	NSArray * ueqs = [NSMutableArray arrayWithArray:[iDict objectForKey:@"equip"]];
	infos = [[GameDB shared] getEquipmentInfoByIds:getArrayListDataByKey(ueqs,@"eid")];
	
	equipInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[equipInfos retain];
	
	
	infos = [[GameDB shared] getEquipmentSetInfoByIds:getArrayListDataByKey(infos,@"sid")];
	equipSetInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[equipSetInfos retain];
	
	NSArray * ufs = [NSMutableArray arrayWithArray:[iDict objectForKey:@"fate"]];
	infos = [[GameDB shared] getFateInfoByIds:getArrayListDataByKey(ufs,@"fid")];
	
	fateInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[fateInfos retain];
	
	NSArray * arms = getArrayListDataByKey(roleInfos,@"armId");
	armInfos = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getArmInfoByIds:arms]];
	[armInfos retain];
	
	NSArray * skills = getArrayListDataByKey(roleInfos,@"sk2");
	skillInfos = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getSkillInfoByIds:skills]];
	[skillInfos retain];
	
	//----------------------
	[self showRoleTabs];
	
}

//------------------------------------------------------------------------------------------------
//数据逻辑处理
//------------------------------------------------------------------------------------------------

-(NSArray*)getRoleWithStatus:(RoleStatus)_status{
	
	NSMutableArray* array = [NSMutableArray array];
	
	NSArray* roles = [NSArray arrayWithArray:[_info objectForKey:@"roles"]];
	
	for (NSDictionary* role in roles) {
		NSNumber* number = [role objectForKey:@"status"];
		if ([number intValue] == _status) {
			[array addObject:[role objectForKey:@"rid"]];
		}
	}
	
	[array sortUsingSelector:@selector(compare:)];
	
	return array;
	
}

-(void)adjustRoleTabsPosition{
	if (_buttons != nil) {
		CGSize size = _buttons.contentSize;
		CGSize __size = self.contentSize;
		/*
        float startX = 0;
        float startY = 0;
		startX = OFFSET_ROLE_TAB_1 ;
		startY = __size.height - OFFSET_ROLE_TAB_2;
		*/
        _buttons.position=ccp(OFFSET_ROLE_TAB_1, __size.height - OFFSET_ROLE_TAB_3  - size.height/2);
	}
}

-(void)showRoleTabs{
	
	if (_buttons != nil) {
		[_buttons removeFromParentAndCleanup:YES];
		_buttons = nil ;
	}
	
	_buttons =[ButtonGroup node];
	
	[_buttons setTouchPriority:-110];
	[self addChild:_buttons z:2];
	
	NSArray* array = [self getRoleWithStatus:RoleStatus_in];
	
	for (NSNumber *number in array) {
		NSArray* spr = getRoleTab([number intValue]);
		
		
		CCMenuItem *_item = [CCMenuItemImage itemWithNormalSprite:[spr objectAtIndex:0]
												   selectedSprite:[spr objectAtIndex:1]
														   target:self
														 selector:@selector(doSelectRole:)];
		
		
		
		[_buttons addChild:_item];
		_item.tag = [number intValue];
	}
	
	[_buttons alignItemsVerticallyWithPadding:4];
	
	[self adjustRoleTabsPosition];
	
	if (array.count > 0) {
		int ___rid = [[array objectAtIndex:0] intValue];
		CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
		[self activationTab:___item];
	}
	
}

-(void)activationTab:(CCMenuItem*)_item{
	if (_buttons == nil ) return ;
	if (_item == nil ) return ;
	CCLOG(@"OtherPlayerPanel->activationTab:%d",_item.tag);
	[_buttons setSelectedItem:_item];
}

-(void)doSelectRole:(CCMenuItem*)_sender{
	_roleId = _sender.tag;
	CCLOG(@"OtherPlayerPanel->Select role %d",_roleId);
	
	if (_msgMgr != nil) {
		_msgMgr.visible = NO;
	}
	
	[self showRoleEquipments:_roleId];
	[self updateCharacterInfo:_roleId];
	[self updateWeaponFunctions:_roleId];
	[self updateFateFunctions:_roleId];
	[self updateCharacterImage:_roleId];
	[self updatePowerSprite:_roleId];
	
}

-(void)updatePowerSprite:(int)_rid{
	if (_rid <= 0 || _rid > 10) {
		if (_cbeMgr != nil) {
			_cbeMgr.visible = NO ;
		}
		return ;
	}
	
	NSDictionary* power = [_info objectForKey:@"CBE"];//--------
	int _value = [[power objectForKey:@"CBE"] intValue];
	
	if (_cbeMgr != nil) {
		_cbeMgr.visible = YES ;
		[_cbeMgr updatePower:_value];
	}
	
}

-(void)showRoleEquipments:(int)_rid{
	
	for (int i = EquipmentPart_head; i <= EquipmentPart_ring; i++) {
		OtherEquipmentTray *mEq1 = (OtherEquipmentTray*)[self getChildByTag:8000+i];
		mEq1.rid = _rid;
		NSDictionary* eDict = [self getEquipForRole:_rid part:i-1];
		if (eDict != nil) {
			
			int eid = [[eDict objectForKey:@"eid"] intValue];
			int ueid = [[eDict objectForKey:@"id"] intValue];
			int _level = [[eDict objectForKey:@"level"] intValue];
			int _q = [self getEquipmentQuality:eid];
			
			mEq1.eid	 = eid;
			mEq1.ueid	 = ueid ;
			mEq1.level	 = _level ;
			mEq1.quality = _q ;
			
		}else{
			mEq1.eid	 = 0;
			mEq1.ueid	 = 0 ;
			mEq1.level	 = 0 ;
			mEq1.quality = 0 ;
		}
	}
}

-(NSDictionary*)getRole:(int)rid{
	NSArray* roles = [NSArray arrayWithArray:[_info objectForKey:@"roles"]];
	for(NSDictionary * role in roles){
		if([[role objectForKey:@"rid"] intValue] == rid){
			return role;
		}
	}
	return nil;
}

-(NSString*)getPart:(int)_p{
	return [NSString stringWithFormat:@"eq%d",(_p+1)];
}

-(NSDictionary*)getEquipForRole:(int)rid part:(int)part{
	if(part<0 || part>5) return nil;
	NSDictionary * role = [self getRole:rid];
	
	int ueid = [[role objectForKey:[self getPart:part]] intValue];
	
	if(ueid>0){
		
		NSDictionary* iDict = [_info objectForKey:@"ilist"];
		NSArray * equips = [NSMutableArray arrayWithArray:[iDict objectForKey:@"equip"]];
		
		for(NSDictionary * equip in equips){
			if([[equip objectForKey:@"id"] intValue]==ueid){
				return equip;
			}
		}
		
	}
	return nil;
}

-(int)getEquipmentQuality:(int)_eid{
	NSDictionary* e1 = [equipInfos objectForId:_eid];
	int _sid = [[e1 objectForKey:@"sid"] intValue];
	NSDictionary* e2 = [equipSetInfos objectForId:_sid];
	return [e2 intForKey:@"quality"];
}


-(void)showLabels{
	
	NSString* _string = [NSString stringWithFormat:@""];
	int  ____tag = 7000;
	
	for (int i = 0; i < 6; i++) {
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:_string
											   fontName:getCommonFontName(FONT_1)
											   fontSize:cFixedScale(16)];
		label.color = ccc3(204, 125, 14);
		label.anchorPoint = ccp(0, 0);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:label z:5 tag:____tag];
		label.position= getLabelPosition(i);
		____tag++;
		
	}
	
}

-(void)showFunctions{
	
	NSString* path = nil ;
	
	if (_armSpr == nil) {
		
		_armSpr = [CCSprite spriteWithFile:@"images/ui/panel/t30.png"];
		path = [NSString stringWithFormat:@"images/ui/panel/icon_weapon.png"];
		CCSprite* icon = [CCSprite spriteWithFile:path];
		[_armSpr addChild:icon z:1];
		icon.position = ccp(icon.contentSize.width/2, _armSpr.contentSize.height/2);
		
		[self addChild:_armSpr z:3];
		
		_armSpr.position = OFFSET_WEAPON_PT; //ccp(230, 465);
	}
	
	if (_fateSpr == nil) {
		
		_fateSpr = [CCSprite spriteWithFile:@"images/ui/panel/t30.png"];
		path = [NSString stringWithFormat:@"images/ui/panel/icon_guanxing.png"];
		CCSprite* icon = [CCSprite spriteWithFile:path];
		[_fateSpr addChild:icon z:1];
		icon.position = ccp(icon.contentSize.width/2, _fateSpr.contentSize.height/2);
		
		[self addChild:_fateSpr z:3];
		
		_fateSpr.position = OFFSET_FATE_PT ;//ccp(455, 465);
	}
	
	
	if (_armLabel == nil) {
		_armLabel = [CCLabelTTF labelWithString:@""
									   fontName:getCommonFontName(FONT_1)
									   fontSize:cFixedScale(16)];
		_armLabel.color = ccc3(220, 220, 220);
		_armLabel.anchorPoint = ccp(0, 0.5);
		[_armLabel setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[_armLabel setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:_armLabel z:4];
		_armLabel.position= OFFSET_WEAPON_LABEL ;//ccp(200 , 465);
	}
	
	if (_fateLabel == nil) {
		
		_fateLabel = [CCLabelTTF labelWithString:@""
										fontName:getCommonFontName(FONT_1)
										fontSize:cFixedScale(16)];
		_fateLabel.color = ccc3(220, 220, 220);
		_fateLabel.anchorPoint = ccp(0, 0.5);
		[_fateLabel setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[_fateLabel setHorizontalAlignment:kCCTextAlignmentLeft];
		[self addChild:_fateLabel z:4];
		_fateLabel.position= OFFSET_FATE_LABEL ;//ccp(425, 465);
		
	}
	
}

-(NSArray*)getRoleCaption:(int)_rid{
	
	NSDictionary* playerDict = [_info objectForKey:@"player"];
	NSDictionary* roleDict = [roleInfos objectForId:_rid];
	
	NSString* s0 = nil ;
	if (_rid < 10)
		s0 = [playerDict objectForKey:@"name"] ;
	else
		s0 = [roleDict objectForKey:@"name"];
	
	NSString* s1 = [NSString stringWithFormat:@"%d",[[playerDict objectForKey:@"level"] intValue]];
	
	int _skill = [[roleDict objectForKey:@"sk2"] intValue];
	NSString* s2 = [[skillInfos objectForId:_skill] objectForKey:@"name"];
	
	
	NSDictionary* power = [_info objectForKey:@"CBE"];//--------
	NSDictionary* rolePower = [power objectForKey:@"CBES"];//-------------
	
	NSString* _key = [NSString stringWithFormat:@"%d",_rid];
	int _value = [[rolePower objectForKey:_key] intValue];
	NSString* s3 = [NSString stringWithFormat:@"%d",_value] ;
	
	NSString* s4 = [roleDict objectForKey:@"job"];
	NSString* s5 = [roleDict objectForKey:@"office"];
	
	return [NSArray arrayWithObjects:s0,s1,s2,s3,s4,s5,nil];
	
	
}

-(void)updateCharacterInfo:(int)_rid {
	CCLOG(@"OtherEquipmentTray->updateCharacterInfo:%d",_rid);
	
	NSArray* _array = [self getRoleCaption:_rid];
	
	if (_array.count < 6) {
		return ;
	}
	
	for (int i = 0; i < 6; i++) {
		NSString* temp = [_array objectAtIndex:i];
		CCLabelTTF* label = (CCLabelTTF*)[self getChildByTag:7000+i];
		if (label != nil) {
			label.string = temp ;
		}
	}
	
}


-(NSDictionary*)getFate:(int)fid{
	NSDictionary* iDict = [_info objectForKey:@"ilist"];
	NSArray * fates = [NSMutableArray arrayWithArray:[iDict objectForKey:@"fate"]];
	
	for(NSDictionary * fate in fates){
		if([[fate objectForKey:@"id"] intValue] == fid){
			return fate;
		}
	}
	return nil;
}

-(int)getFateExperience:(int)_rid{
	NSDictionary* _role = [self getRole:_rid];
	if (_role == nil) return 0 ;
	
	int _total = 0 ;
	
	for (int i = 1 ; i <= 6; i++) {
		NSString* _key = [NSString stringWithFormat:@"fate%d",i];
		int _fid = [[_role objectForKey:_key] intValue];
		
		if (_fid <= 0) continue ;
		
		NSDictionary* fDict = [self getFate:_fid];
		
		int _exp = [[fDict objectForKey:@"exp"] intValue];
		_total += _exp ;
		
	}
	
	return _total/5 ;
}

-(NSString*)getWeaponName:(int)_rid{
	if (_rid <= 0) return nil ;
	
	NSDictionary* _role = [roleInfos objectForId:_rid];
	
	if (_role == nil) return nil ;
	
	int _aid = [[_role objectForKey:@"armId"] intValue];
	if (_aid <= 0) return nil ;
	
	NSDictionary* _arm = [armInfos objectForId:_aid];
	
	NSString* name = [_arm objectForKey:@"name"];
	
	return name ;
}


-(void)updateFateFunctions:(int)_rid{
	CCLOG(@"OtherPlayerPanel->updateFateFunctions:%d",_rid);
	int _exp = [self getFateExperience:_rid];
	
	if (_fateLabel) {
		NSString* msg = [NSString stringWithFormat:@"星力:%d",_exp];
		_fateLabel.string = msg;
	}
	
}

-(int)getWeaponLevel:(int)_rid{
	if (_rid <= 0) return nil ;
	
	NSDictionary* _urole = [self getRole:_rid];
	int _armLv = [[_urole objectForKey:@"armLevel"] intValue];
	return _armLv;
	
}

-(void)updateWeaponFunctions:(int)_rid{
	CCLOG(@"OtherPlayerPanel->updateWeaponFunctions:%d",_rid);
	
	NSString *_string = [self getWeaponName:_rid];
	
	int armLv = [self getWeaponLevel:_rid];
	
	if (_armLabel) {
		//NSString* msg = [NSString stringWithFormat:@"%@ %d阶",_string,armLv];
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"other_player_rank",nil),_string,armLv];
		_armLabel.string = msg;
	}
	
}


-(void)updateCharacterImage:(int)roleId{
	
	CCLOG(@"PlayerPanel->showCharacterImage:%d",roleId);
	[self removeChildByTag:4005 cleanup:YES];
	
	CCSprite * node = [RoleImageViewerContent create:roleId];
	node.anchorPoint=ccp(0.5, 0);
	node.position = OFFSET_CHARACTER_IMAGE_PT;//ccp(127 + 216, 135);
	[self addChild:node z:4 tag:4005];
	
}

-(NSDictionary*)getEquipmentById:(int)____id{
	NSDictionary* iDict = [_info objectForKey:@"ilist"];
	NSArray * equips = [NSMutableArray arrayWithArray:[iDict objectForKey:@"equip"]];
	
	for(NSDictionary * equip in equips){
		if([equip intForKey:@"id"] == ____id){
			return equip;
		}
	}
	return nil ;
}

-(NSDictionary*)getRoleSuit:(int)_rid{
	NSMutableDictionary* rDict = [NSMutableDictionary dictionary];
	if (_rid <= 0) return rDict;
	
	
	NSDictionary *userRole = [self getRole:_rid];
	
	for (int i = 1; i <= 6; i++) {
		
		NSString *_key = [NSString stringWithFormat:@"eq%d",i];
		
		int reid = [userRole intForKey:_key];
		
		NSDictionary *req = [self getEquipmentById:reid];
		
		int eid = [req intForKey:@"eid"];
		
		NSDictionary *eq = [equipInfos objectForId:eid];
		
		int sid = [eq intForKey:@"sid"];
		
		int num = [rDict intForKey:[NSString stringWithFormat:@"%d",sid]];
		
		if (num <= 0) {
			[rDict setObject:[NSNumber numberWithInt:1] forKey:[NSString stringWithFormat:@"%d",sid]];
		}else{
			num += 1;
			[rDict setObject:[NSNumber numberWithInt:num] forKey:[NSString stringWithFormat:@"%d",sid]];
		}
		
	}
	
	return rDict;
}

-(NSString*)getInfoWithString:(NSString*)_string
{
	if (!_string) return @"";
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	NSArray *_array = [_string componentsSeparatedByString:@"|"];
	for (NSString *__string in _array) {
		NSArray *__array = [__string componentsSeparatedByString:@":"];
		if (__array.count >= 2) {
			NSString *__key = [__array objectAtIndex:0];
			NSString *__value = [__array objectAtIndex:1];
			
			[dict setObject:__value forKey:__key];
		}
	}
	
	BaseAttribute attr = BaseAttributeFromDict(dict);
	NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
	
	string = [string stringByReplacingOccurrencesOfString:@"|" withString:@" "];
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@"+"];
	
	return string;
}

-(NSString*)getEquipDescribe:(int)_id role:(int)_rid{
	if (_id <= 0 ) {
		return nil;
	}
	
	NSDictionary *_dict = [self getEquipmentById:_id];
	
	int eid = [_dict intForKey:@"eid"];
	
	int e_level = [_dict intForKey:@"level"];
	
	NSDictionary *equip = [equipInfos objectForId:eid];
	
	int e_sid = [equip intForKey:@"sid"];
	
	NSDictionary *eset = [equipSetInfos objectForId:e_sid];
	
	int qa=[eset intForKey:@"quality"];
	
	NSString *name = [equip objectForKey:@"name"];
	
	NSString *cmd = [name stringByAppendingFormat:@"#%@#20#0*",getQualityColorStr(qa)];
	
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"other_player_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"other_player_no_trade",nil)];
	}
	
	int limit = [[equip objectForKey:@"limit"] intValue];
	//NSString *str_limit = [NSString stringWithFormat:@"使用等级: %d",limit];
    NSString *str_limit = [NSString stringWithFormat:NSLocalizedString(@"other_player_use_level",nil),limit];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_limit];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int _part = [[equip objectForKey:@"part"] intValue];
	
	//NSString *str_part = [NSString stringWithFormat:@"装备类型: %@",getPartName(_part)];
    NSString *str_part = [NSString stringWithFormat:NSLocalizedString(@"other_player_equip_type",nil),getPartName(_part)];
	
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_part];
	//---------------------------------------------------------------
	
	//-------------------------------
	if (equip != nil) {
		cmd = [cmd stringByAppendingString:getAttrDescribetionWithDict(equip)];
	}
	
	/*
	for (int i = 0; i < 21; i++) {
		//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
        NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
		float _value = [[equip objectForKey:[args objectAtIndex:0]] floatValue];
		if (_value > 0 ) {
			NSString *str_temp = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
			if (args.count == 3) {
				str_temp = [str_temp stringByAppendingFormat:@"|+%.1f%@#00ee00#16#0*",_value,@"%"];
			}
			else {
				str_temp = [str_temp stringByAppendingFormat:@"|+%.0f#00ee00#16#0*",_value];
			}
			cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
		}
	}
	 */
	//--------------------------------
	
	if (e_level > 0	) {
		
		NSDictionary *dict_lv = [[GameDB shared] getEquipmentLevelInfo:_part level:e_level];
		if (dict_lv) {
			NSString *string = [NSString stringWithFormat:NSLocalizedString(@"other_player_upgrade_2",nil),e_level,@"%@", @"%@"];
			cmd = [cmd stringByAppendingString:getAttrDescribetion(dict_lv, string)];
		}
		
		/*
		//这里暂时先读 IO
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value = [[dict_lv objectForKey:[args objectAtIndex:0]] floatValue];
			CCLOG(@"%@ | %.1f",[args objectAtIndex:1],_value);
			if (_value > 0 ) {
				//NSString *str_temp = [NSString stringWithFormat:@"%d级强化:%@ +%.0f#00ff00#16#0*",e_level,[args objectAtIndex:1],_value];
                NSString *str_temp = [NSString stringWithFormat:NSLocalizedString(@"other_player_upgrade",nil),e_level,[args objectAtIndex:1],_value];
				cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
			}
		}
		 */
	}
	
	NSDictionary *gem = [_dict objectForKey:@"gem"];
	if (gem && gem.allKeys.count > 0) {
		cmd = [cmd stringByAppendingFormat:@"^10*"];
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",NSLocalizedString(@"player_data_helper_jewel",nil)];
		
		NSArray *_array = [gem allKeys];
		for (int i = 0; i < _array.count; ) {
			if ((i+1)<_array.count) {
				cmd = [cmd stringByAppendingFormat:@"%@ %@#eeeeee#16#0*",
					   NSLocalizedString(@"player_data_helper_omit",nil),
					   NSLocalizedString(@"player_data_helper_omit",nil)];
				i += 2;
			} else {
				cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*", NSLocalizedString(@"player_data_helper_omit",nil)];
				break;
			}
		}
	}
	
	if (_rid > 0) {
		//---------------------------------
		cmd = [cmd stringByAppendingFormat:@"^10*"];
		//空
		
		NSString *_info2 = [eset objectForKey:@"effect2"];
		_info2 = [self getInfoWithString:_info2];
		/*
		_info2 = [_info2 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info2 = [_info2 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info2 = [_info2 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		 */
		NSString *_info4 = [eset objectForKey:@"effect4"];
		_info4 = [self getInfoWithString:_info4];
		/*
		_info4 = [_info4 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info4 = [_info4 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info4 = [_info4 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		 */
		NSString *_info6 = [eset objectForKey:@"effect6"];
		_info6 = [self getInfoWithString:_info6];
		/*
		_info6 = [_info6 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info6 = [_info6 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info6 = [_info6 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		 */
		
		NSDictionary *setInfo = [self getRoleSuit:_rid];
		
		int num = [[setInfo objectForKey:[NSString stringWithFormat:@"%d",e_sid]] intValue];
		
		//NSString *str_setInfo = [NSString stringWithFormat:@"套装属性(%d/6)#888888#14#0*",num];
		NSString *str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"other_player_set_info_1",nil),num];
		if (num >= 2) {
			str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"other_player_set_info_2",nil),num];
		}
		cmd = [cmd stringByAppendingFormat:@"%@",str_setInfo];
		
		if (num >= 6) {
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#ffffff#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_six_set",nil),_info6];
		}else if(num >= 4){
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_six_set",nil),_info6];
		}else if(num >= 2){
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"other_player_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_six_set",nil),_info6];
		}else {
//			_info2 = [NSString stringWithFormat:@"2件:%@#888888#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"other_player_six_set",nil),_info6];
		}
		
		cmd = [cmd stringByAppendingFormat:@"%@",_info2];
		cmd = [cmd stringByAppendingFormat:@"%@",_info4];
		cmd = [cmd stringByAppendingFormat:@"%@",_info6];
		
	}
	
	int price = [[equip objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"other_player_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	//---------------------------------------------------------------
	return cmd;
	
}

-(void)requestShowEquipmentDescribe:(int)_ueid part:(int)_prt{
	if (_ueid <= 0) return ;
	NSString* cmd = [self getEquipDescribe:_ueid role:_roleId];
	if (cmd != nil && _msgMgr != nil) {
		[_msgMgr message:cmd];
		CGPoint pt = getPartPosition(_prt);
		BOOL _isLeft = (_prt < 4) ? YES : NO;
		if (_isLeft) {
			pt = ccpAdd(pt, ccp(OFFSET_DES, -_msgMgr.contentSize.height/2));
		}
		else {
			pt = ccpAdd(pt, ccp(-OFFSET_DES-_msgMgr.contentSize.width, -_msgMgr.contentSize.height/2));
		}
		_msgMgr.position=pt;
		_msgMgr.position = getFinalPosition(_msgMgr);
		_msgMgr.visible = YES;
	}
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		
		return YES;
	}
	return NO ;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		if (_msgMgr != nil ) {
			_msgMgr.visible = NO ;
		}
	}
}

@end
























