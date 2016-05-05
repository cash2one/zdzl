//
//  CFPage.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-20.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "CFPage.h"
#import "Window.h"
#import "GameConfigure.h"
#import "RoleCard.h"
#import "GameDB.h"
#import "ClickAnimation.h"
#import "FateIconViewerContent.h"

#pragma mark -
#pragma mark - GXPageDot
////
@implementation PageDot
//TODO change by TigerLeung
@synthesize dotCount;
enum{
	PD_BACK_TAG=111,
	PD_NOW_DOT_TAG,
	PD_DOT_INDEX_START_TAG,
};
-(void)setDotCount:(NSUInteger)count{
	CCLOG(@"PageDot->setDotCount->count = %d",count);
	if (dotCount>0) {
		for (int i=0; i<dotCount; i++) {
			[self removeChildByTag:PD_DOT_INDEX_START_TAG+i cleanup:YES];
		}
	}
	dotCount = count;
	CCSprite *dotSpr = [CCSprite spriteWithFile:@"images/ui/panel/pagePos01.png"];
	//CGPoint pos = ccp(self.contentSize.width/2,self.contentSize.height/2);
	CGPoint pos = CGPointZero;
	NSInteger w = dotSpr.contentSize.width*2;
	if (dotCount%2 == 0) {
		pos.x = pos.x - dotCount/2*w +w/2;
	}else{
		pos.x = pos.x - dotCount/2*w;
	}
	////
	CCSprite *nowDotSpr = (CCSprite *)[self getChildByTag:PD_NOW_DOT_TAG];
	[nowDotSpr setPosition:pos];
	
	for (int i=0; ; ) {
		[self addChild:dotSpr z:1 tag:PD_DOT_INDEX_START_TAG+i];
		dotSpr.position = ccp(pos.x+i*w,pos.y);
		i++;
		if(i<dotCount){
			dotSpr = [CCSprite spriteWithFile:@"images/ui/panel/pagePos01.png"];
		}else{
			break;
		}
	}
	
}
-(void)onEnter{
	////
	[super onEnter];
    m_index = 0;
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/pageBack.png"];
	//self.contentSize = bg.contentSize;
	[self addChild:bg z:0 tag:PD_BACK_TAG];	 
	CCSprite *nowDotSpr = [CCSprite spriteWithFile:@"images/ui/panel/pagePos02.png"];
	[self addChild:nowDotSpr z:2 tag:PD_NOW_DOT_TAG];
}

-(void)setIndex:(NSUInteger)index{
	CCSprite *dotSpr = (CCSprite *)[self getChildByTag:PD_DOT_INDEX_START_TAG+index];
	CCSprite *nowDotSpr = (CCSprite *)[self getChildByTag:PD_NOW_DOT_TAG];
	if (dotSpr) {
		[nowDotSpr setPosition:[dotSpr position]];
	}
	m_index = index;
}
-(int)index{
    return m_index;
}
-(void)setSize:(CGSize)size{	
	[self removeChildByTag:PD_BACK_TAG cleanup:YES];
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/pageBack.png"];	
	[self addChild:bg z:0 tag:PD_BACK_TAG];
	float scale_x = size.width/bg.contentSize.width;
	float scale_y = size.height/bg.contentSize.height;
	bg.scaleX = scale_x;
	bg.scaleY = scale_y;
	bg.contentSize = size;	
	bg.position = ccp(-bg.contentSize.width*(1-bg.scaleX)/2,-bg.contentSize.height*((1-bg.scaleY)/2));
	
}
-(void)setSizeWithScale:(CGSize)scaleSize{
	[self removeChildByTag:PD_BACK_TAG cleanup:YES];	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/pageBack.png"];
	[self addChild:bg z:0 tag:PD_BACK_TAG];
	bg.scaleX = scaleSize.width;
	bg.scaleY = scaleSize.height;
	bg.contentSize = CGSizeMake(bg.contentSize.width*scaleSize.width, bg.contentSize.height*scaleSize.height);
	bg.position = ccp(-bg.contentSize.width*(1-bg.scaleX)/2,-bg.contentSize.height*((1-bg.scaleY)/2));
	
	
}
-(CGSize)contentSize{
	CCSprite* bg = (CCSprite*)[self getChildByTag:PD_BACK_TAG];
	if (bg) {
		return bg.contentSize;
	}
	return self.contentSize;
	
}
@end

#pragma mark -
#pragma mark - GXCard
@implementation Card
enum CardTags{

kCardBG = 256,//背景
kCardQuality,//品质
kCardQualitySelect,//选择	
kCardItem ,//物品
kCardCount,//数量/
kCardLevel,//等级
kCardSelect ,//选择/

};
////
@synthesize isTrade;
@synthesize itemExp;
@synthesize itemLevel;
@synthesize	itemQuality;
///////
@synthesize itemCount;
@synthesize itemSelected;
@synthesize itemUsed;
@synthesize itemClose;

-(void)dealloc{
	[super dealloc];
}

-(void)onExit{
	
	CCLOG(@"GXCard onExit");
	[self removeAllChildrenWithCleanup:YES];
	[super onExit];
}

-(void)onEnter{
	////
	[super onEnter];
	////
	[self setItemIsNull];
	//[self setIsTouchEnabled:YES];
	
}
-(void)draw{
	[super draw];
	////
	CCSprite *spr = (CCSprite *)[self getChildByTag:kCardQualitySelect];
	[spr setVisible:isSelected_];
}

//是否有物品
-(BOOL)isOwnItem{
	if (cardItemID <=0) {
		return NO;
	}
	return YES;
}

//类型
-(ItemSystemType)getItemType{
	return cardType;
}

-(NSInteger)getBaseID{
	return cardBaseID;
}
//取物品ID
-(NSInteger)getItemID{
	return cardItemID;
}
//取物品dict
-(NSDictionary*)getCardDict{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:cardType] forKey:@"itemSystemType"];
	[dict setObject:[NSNumber numberWithInt:cardItemID] forKey:@"id"];
	[dict setObject:[NSNumber numberWithInt:cardBaseID] forKey:@"bid"];
	[dict setObject:[NSNumber numberWithInt:itemLevel] forKey:@"level"];
	[dict setObject:[NSNumber numberWithInt:itemExp] forKey:@"exp"];
	[dict setObject:[NSNumber numberWithInt:isTrade] forKey:@"isTrade"];
	[dict setObject:[NSNumber numberWithInt:itemCount] forKey:@"count"];
	[dict setObject:[NSNumber numberWithInt:itemQuality] forKey:@"quality"];
	[dict setObject:[NSNumber numberWithInt:itemUsed] forKey:@"used"];
	return dict;
}
-(CCSprite*)getIconWithType:(NSInteger)type bID:(NSInteger)bid{
	CCSprite *spr=nil;
	if (IST_EQUIP == type) {
		spr = getEquipmentIcon(bid);
	}else if (IST_ITEM == type) {
		spr = getItemIcon(bid);
	}else if (IST_FATE == type) {
		spr = getFateIcon(bid);
	}
	if (!spr) {
		CCLOG(@"card get icon error");
		//fix chao		
		//spr = [CCSprite spriteWithFile:@"images/ui/panel/t31.png"];
		//end
	}
	return spr;
}

-(void)showItem{
	
	CCNode * viewer = [self getChildByTag:kCardItem];
	if(viewer){
		viewer.visible = YES;
	}
	
}
-(void)hideItem{
	
	CCNode * viewer = [self getChildByTag:kCardItem];
	if(viewer){
		viewer.visible = NO;
	}
	
}

//改变物品
-(void)changeItemWithOther:(Card*)other{	
	cardType = [other getItemType];
	cardItemID = [other getItemID];
	cardBaseID = [other getBaseID];
	itemUsed = [other itemUsed];
	
	if ( cardItemID<=0 ) {
		return;
	}	
	////
	[self removeChildByTag:kCardItem cleanup:YES];
	CCSprite *spr = [self getIconWithType:cardType bID:cardBaseID];
	[self addChild:spr z:kCardItem tag:kCardItem];
	spr.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	////
	[self setItemLevel:[other itemLevel]];
	[self setIsTrade:[other isTrade] ];
	[self setItemExp:[other itemExp]];
	[self setItemQuality:[other itemQuality]];
	[self setItemCount:[other itemCount]];
	itemClose = NO;
}

//改变物品
-(void)changeItemWithDict:(NSDictionary*)dict{
	
	NSNumber *itemTypeNumber = [dict objectForKey:@"itemSystemType"];
	NSNumber *itemIDNumber = [dict objectForKey:@"id"];
	NSNumber *itemBIDNumber = [dict objectForKey:@"bid"];
	NSNumber *levelNumber = [dict objectForKey:@"level"];
	NSNumber *expNumber = [dict objectForKey:@"exp"];
	NSNumber *isTradeNumber = [dict objectForKey:@"isTrade"];
	NSNumber *countNumber = [dict objectForKey:@"count"];
	NSNumber *qualityNumber = [dict objectForKey:@"quality"];
	NSNumber *usedNumber = [dict objectForKey:@"used"];
	
	if ([countNumber intValue]<=0) {
		return;
	}	
	if ([itemIDNumber intValue]<=0) {
		return;
	}	
	////
	cardType = [itemTypeNumber intValue];
	cardBaseID = [itemBIDNumber intValue];
	cardItemID = [itemIDNumber intValue];
	itemUsed = [usedNumber intValue];	
	////
	[self removeChildByTag:kCardItem cleanup:YES];
	CCSprite *spr = [self getIconWithType:cardType bID:cardBaseID];
	//if (spr)
	{
		[self addChild:spr z:kCardItem tag:kCardItem];
		spr.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	}
	////
	[self setItemLevel:[levelNumber intValue]];
	[self setIsTrade:[isTradeNumber intValue]];
	[self setItemExp:[expNumber intValue]];
	[self setItemQuality:[qualityNumber intValue]];
	[self setItemCount:[countNumber intValue]];
	itemClose = NO;
}
-(void)setItemVisible:(BOOL)visibled{
	CCSprite *spr = (CCSprite *)[self getChildByTag:kCardItem];
    CCSprite *sprLevel = (CCSprite *)[self getChildByTag:kCardLevel];
    CCSprite *sprCount = (CCSprite *)[self getChildByTag:kCardCount];
    
	[spr setVisible:visibled];
    [sprLevel setVisible:visibled];
    [sprCount setVisible:visibled];
}
-(void)setItemExp:(NSInteger)_itemExp{
	itemExp = _itemExp;	
	////
	if (cardType == IST_FATE && cardBaseID!=37) {
		NSDictionary *nextLevelDict;
		NSNumber *nextExpNumber;
		int level=1;
		int i;
		for (i=2; i<11; i++) {
			//soul
			nextLevelDict = [[GameDB shared] getFateLevelInfo:cardBaseID level:i];
			nextExpNumber = [nextLevelDict objectForKey:@"exp"];			
			if ([nextExpNumber intValue] >itemExp) {
				level = i-1;
				break;
			}			
		}
		if (i > 10) {
			i = 10;
			level = i;
		}		
		[self setItemLevel:level];
	}
	
}
-(void)setItemLevel:(NSInteger)_itemLevel{
	itemLevel = _itemLevel;
	if ( !(cardType == IST_EQUIP || cardType == IST_FATE) ) {
		return;
	}
	if (itemLevel<1) {
		[self removeChildByTag:kCardLevel cleanup:YES];
		
		if (itemLevel<0) {
			CCLOG(@"item level < 0");
		}
		return;
	}
	////
	CCLabelTTF *label;
	label = (CCLabelTTF *)[self getChildByTag:kCardLevel];
	if (!label) {
		label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%d",itemLevel] fontName:@"Marker Felt" fontSize:21];
		if (iPhoneRuningOnGame()) {
			label.scale=0.5f;
		}
		label.color = ccc3(0, 255, 0);
		[self addChild:label z:kCardLevel tag:kCardLevel];
		label.anchorPoint = ccp(0,1);
		label.position = ccp(0,self.contentSize.height);
	}else{
		[label setString:[NSString stringWithFormat:@"+%d",itemLevel]];
	}	
}
-(void)setItemCount:(NSInteger)_itemCount{
	itemCount = _itemCount;
	if (itemCount<=1) {
		[self removeChildByTag:kCardCount cleanup:YES];
		
		if (itemCount<0) {
			CCLOG(@"item count < 0");
		}
		return;
	}
	////
	CCLabelTTF *label;
	label = (CCLabelTTF *)[self getChildByTag:kCardCount];
	if (!label) {
		label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",itemCount] fontName:@"Verdana-Bold" fontSize:21];
		[self addChild:label z:kCardCount tag:kCardCount];
		label.anchorPoint = ccp(1,1);
		label.position = ccp(self.contentSize.width,self.contentSize.height);
	}else{
		[label setString:[NSString stringWithFormat:@"%d",itemCount]];
	}
	
}
-(void)setItemQuality:(ItemQuality)_itemQuality{
	itemQuality = _itemQuality;	
	[self removeChildByTag:kCardQuality cleanup:YES];
	
	CCSprite *spr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png",itemQuality]];
	if (!spr) {
		CCLOG(@"set quality error");
		spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	}
	//fix chao
	
	/*
	CCSprite *t_spr = (CCSprite *)[self getChildByTag:kCardItem];
	if (t_spr) {
		if (cardType == IST_FATE) {
			NSString *str_ = nil;
			if (itemQuality == IQ_BLUE) {
				str_ = @"images/animations/fate/blue/";
			}else if(itemQuality == IQ_PURPLE) {
				str_ = @"images/animations/fate/purple/";
			}else{
				str_ = @"images/animations/fate/green/";
			}
			if (str_) {
				[ClickAnimation showInLayer:t_spr z:-1 tag:kCardItem call:nil point:ccp(t_spr.contentSize.width/2, t_spr.contentSize.height/2) path:str_ loop:YES];
			}
		}
	}
	*/
	
	if(cardType == IST_FATE){
		CCNode * node = [self getChildByTag:kCardItem];
		if([node isKindOfClass:[FateIconViewerContent class]]){
			FateIconViewerContent * fivc = (FateIconViewerContent*)node;
			fivc.quality = itemQuality;
		}
	}
	
	//end
	//[self addChild:spr z:kCardQuality tag:kCardQuality];

	spr.position = ccp(self.contentSize.width /2,self.contentSize.height /2);

	////
	[self setItemQualitySelect:itemQuality];
}
-(void)setItemQualitySelect:(ItemQuality)_itemQuality{	
	[self removeChildByTag:kCardQualitySelect cleanup:YES];
	CCSprite *spr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%dSelect.png",itemQuality]];
	if (!spr) {
		CCLOG(@"set quality error");
#ifdef GAME_DEBUGGER
		spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
#endif
	}
	//[self addChild:spr z:kCardQualitySelect tag:kCardQualitySelect];
	
	spr.position = ccp(self.contentSize.width /2,self.contentSize.height /2);
}
//删除
-(void)removeItem{
	[self removeChildByTag:kCardSelect cleanup:YES];
	[self removeChildByTag:kCardQuality cleanup:YES];
	[self removeChildByTag:kCardQualitySelect cleanup:YES];
	[self removeChildByTag:kCardItem cleanup:YES];
	[self removeChildByTag:kCardCount cleanup:YES];
	[self removeChildByTag:kCardLevel cleanup:YES];
	[self removeChildByTag:kCardSelect cleanup:YES];
	itemSelected = NO;
	cardItemID = -1;
	[self setItemIsNull];
}

//设置物品为空
-(void)setItemIsNull{
	[self removeChildByTag:kCardBG cleanup:YES];
	CCSprite	*bg = [CCSprite spriteWithFile:@"images/ui/common/quatily0.png"];
	self.contentSize = bg.contentSize;
	bg.tag = kCardBG;
	[self addChild:bg];
	bg.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	itemClose = NO;
}
//设置物品为关闭
-(void)setItemClose:(BOOL)_itemClose{
	itemClose = _itemClose;
	[self removeChildByTag:kCardBG cleanup:YES];
	if (itemClose) {
		/*
		 CCSprite	*closeSpr = [CCSprite spriteWithFile:@"images/ui/common/qualityClose.png"];
		 CCSprite	*bg = [CCSprite spriteWithFile:@"images/ui/common/quatily0.png"];
		 [bg addChild:closeSpr];
		 closeSpr.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2);
		 */
		CCSprite	*bg =nil;
		if (iPhoneRuningOnGame()) {
			bg=[CCSprite spriteWithFile:@"images/ui/wback/qualityClose.png"];			
		}else{
			bg=[CCSprite spriteWithFile:@"images/ui/common/qualityClose.png"];
		}
		self.contentSize = bg.contentSize;
		bg.tag = kCardBG;
		[self addChild:bg];
		bg.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	}else{
		[self setItemIsNull];
	}	
}
//删除物品(数量)
-(void)removeItemWithValue:(NSInteger)value{
	
	value = itemCount - value;
	[self setItemCount:value];
	if (value<=0) {
		[self removeItem];
	}
	
}
//增加物品(数量)
-(void)addItemWithValue:(NSUInteger)value{
	value = itemCount + value;
	[self setItemCount:value];
}

-(void)setItemSelected:(BOOL)_itemSelected{
	
	if ( itemSelected != _itemSelected ) {
		itemSelected = _itemSelected;
		CCSprite *spr;
		spr = (CCSprite *)[self getChildByTag:kCardSelect];
		CCTexture2D *text;
		if (itemSelected) {
			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/pageItemSelect02.png"];
		}else{
			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/pageItemSelect01.png"];
		}
		[spr setTexture:text];
	}
}
//显示选择操作
-(void)showItemSelected{
	itemSelected = NO;//标志选中=NO
	CCSprite *spr = (CCSprite *)[self getChildByTag:kCardSelect];
	if (!spr) {
		spr = [CCSprite spriteWithFile:@"images/ui/panel/pageItemSelect02.png"];
		[self addChild:spr z:kCardSelect tag:kCardSelect];
		CCTexture2D *text;
		if (itemSelected) {
			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/pageItemSelect02.png"];
		}else{
			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/pageItemSelect01.png"];
		}
		[spr setTexture:text];
		spr.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	}
	
}
//不显示选择操作
-(void)hideItemSelected{
	itemSelected = NO;//标志选中=NO
	[self removeChildByTag:kCardSelect cleanup:YES];
}
@end

#pragma mark -
#pragma mark text Box
#define TEXTBOX_LINE_W (10)
@implementation TextBox
@synthesize isShowButton;
-(void)onEnter{
	////
	[super onEnter];
	self.contentSize = CGSizeMake(TEXTBOX_LINE_W*20, TEXTBOX_LINE_W*30);
	messageBox = [MessageBox create:CGPointZero color:ccc4(0, 0, 0, 0) background:ccc4(0, 0, 0, 0)];
	messageBox.position=ccp(TEXTBOX_LINE_W,TEXTBOX_LINE_W);
	[self addChild:messageBox];
	////
	
	self.touchEnabled = YES;
	isShowButton = NO;
}

-(void)addMenuItem:(CCMenuItem*)menuItem z:(NSInteger)z tag:(NSInteger)tag{
	if (!menu) {
		menu = [CCMenu node];
		[self addChild:menu z:1];
		menu.position = CGPointZero;
	}
	[menu addChild:menuItem z:z tag:tag];
	isShowButton = YES;
	[self updateButtonPos];
}
-(void)updateButtonPos{
	CCArray *menuArr = [menu children];
	if ([menuArr count]>0) {
		int w = self.contentSize.width/(menuArr.count*2);
		int i=0;
		for (CCMenuItem* button in menuArr) {			
			button.position = ccp(w*(i*2+1),TEXTBOX_LINE_W+button.contentSize.height/2);
			i++;
		}
	}
}
-(void)setMessageBoxWith:(ItemSystemType)type itemID:(NSInteger)itemID count:(NSInteger)count{
	
	if (IST_EQUIP == type) {
		[messageBox message:[self getEquipMessageWithItemID:itemID]];
	}else if(IST_ITEM == type){
		[messageBox message:[self getItemMessageWithItemID:itemID]];
	}else if(IST_FATE == type){
		[messageBox message:[self getFateMessageWithItemID:itemID]];
	}
	////
	cardItemID = itemID;
	cardItemSysType = type;
	cardCount = count;
	self.contentSize = CGSizeMake(messageBox.contentSize.width+TEXTBOX_LINE_W*2,messageBox.contentSize.height+TEXTBOX_LINE_W*2);	
	////
	[self updateButtonPos];
}
-(void)setMessageBoxWith:(NSString*)str{
	[messageBox message:str];
	self.contentSize = CGSizeMake(messageBox.contentSize.width+TEXTBOX_LINE_W*2,messageBox.contentSize.height+TEXTBOX_LINE_W*2);
	////
	[self updateButtonPos];
}
-(void)draw{
	[super draw];
	ccDrawSolidRect( CGPointZero, ccp(self.contentSize.width, self.contentSize.height ), ccc4FFromccc4B(ccc4(0, 0, 0, 180)));
	ccDrawColor4B(204, 125, 14, 168);
	ccDrawRect(ccp(0,0), ccp(self.contentSize.width, self.contentSize.height));
}
-(NSString*)getItemMessageWithItemID:(int)_id{
	NSDictionary *_dict = [[GameConfigure shared] getPlayerItemInfoById:_id];
	if (!_dict) {
		CCLOG(@"message box item dict is nil");
		return nil;
	}
	int iid = [[_dict objectForKey:@"iid"] intValue];
	NSDictionary *itemDict = [[GameDB shared] getItemInfo:iid];
	if (!itemDict) {
		CCLOG(@"message box itemDict dict is nil");
		return nil;
	}
	int qu=[[itemDict objectForKey:@"quality"]integerValue];
	NSString *name = [NSString stringWithFormat:@"%@",[itemDict objectForKey:@"name"]];
	NSString *cmd = [name stringByAppendingFormat:@"#%@%@",getQualityColorStr(qu),@"#20#0*"];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_no_trade",nil)];
	}
	////
	cmd = [cmd stringByAppendingFormat:@"^20*"];
	//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"效果:"]];
    cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"cfpage_effect",nil)]];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[itemDict objectForKey:@"info"] ];
	////
	cmd = [cmd stringByAppendingFormat:@"^20*"];
	int price = [[itemDict objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d银币#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"cfpage_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^20*"];
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	//---------------------------------------------------------------
	if (isShowButton) {
		cmd = [cmd stringByAppendingFormat:@"^30*"];
	}
	return cmd;
}
-(NSString*)getFateMessageWithItemID:(int)_id{
	NSDictionary *_dict = [[GameConfigure shared] getPlayerFateInfoById:_id];
	if (!_dict) {
		CCLOG(@"message box fate dict is nil");
		return nil;
	}
	int fid = [[_dict objectForKey:@"fid"] intValue];
	int f_level = [[_dict objectForKey:@"level"] intValue] ;
	if (f_level <= 0 || f_level > 10) {
		CCLOG(@" getFateMessageWithItemID f_level = 0");
		return nil;
	}
	NSDictionary *fateDict = [[GameDB shared] getFateInfo:fid];
	if (!fateDict) {
		CCLOG(@"message box fateDict dict is nil");
		return nil;
	}
	int qu=[[fateDict objectForKey:@"quality"]integerValue];	
	//NSString *name = [NSString stringWithFormat:@"%@ %d级",[fateDict objectForKey:@"name"],f_level];
    NSString *name = [NSString stringWithFormat:NSLocalizedString(@"cfpage_level",nil),[fateDict objectForKey:@"name"],f_level];
	NSString *cmd = [name stringByAppendingFormat:@"#%@%@",getQualityColorStr(qu),@"#20#0*"];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_no_trade",nil)];
	}
	////
	//NSString *str_exp = [NSString stringWithFormat:@"经验: "];
    NSString *str_exp = [NSString stringWithFormat:NSLocalizedString(@"cfpage_exp",nil)];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0|",str_exp];
	////now level
	NSDictionary *nowFateLevelDict = [[GameDB shared] getFateLevelInfo:fid level:f_level];
	NSString *t_str = [NSString stringWithFormat:@""];
	if (nowFateLevelDict) {
		/*
		for (int i = 0; i<24; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value =[[nowFateLevelDict objectForKey:[args objectAtIndex:0]] floatValue];
			if (_value >0 ) {
				if (args.count == 3) {
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.1f%@#00ee00#16#0",_value,@"%"];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}else{
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.0f#00ee00#16#0",_value];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}
			}
		}
		 */
		t_str = [t_str stringByAppendingString:getAttrDescribetionWithDict(nowFateLevelDict)];
	}
	//
	NSDictionary *nextFateLevelDict = [[GameDB shared] getFateLevelInfo:fid level:f_level+1];			
	if (nextFateLevelDict) {
		NSString *t_str_exp = [NSString stringWithFormat:@"%d/%d",[[_dict objectForKey:@"exp"] intValue],[[nextFateLevelDict objectForKey:@"exp"] intValue] ] ;
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",t_str_exp];
	}else{
		cmd = [cmd stringByAppendingFormat:@"%d#eeeeee#16#0*",[[_dict objectForKey:@"exp"] intValue]];
	}
	////
	//cmd = [cmd stringByAppendingFormat:@"^5*"];
	//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"效果:"]];
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"效果:"]];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"cfpage_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	////next level
	t_str = [NSString stringWithFormat:@""];
	if (nextFateLevelDict) {
		t_str = [t_str stringByAppendingString:getAttrDescribetionWithDict(nextFateLevelDict)];
		/*
		for (int i = 0; i<24; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value =[[nextFateLevelDict objectForKey:[args objectAtIndex:0]] floatValue];
			if (_value >0 ) {
				if (args.count == 3) {
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.1f%@#00ee00#16#0",_value,@"%"];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}else{
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.0f#00ee00#16#0",_value];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}
			}
		}
		 */
	}	
	////
	//cmd = [cmd stringByAppendingFormat:@"^20*"];
	//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"下一级效果:"]];
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^20*"];
		//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"下一级效果:"]];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"cfpage_next_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	//fix chao
	if (fid==37) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"描述:"]];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"cfpage_info",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[fateDict objectForKey:@"info"] ];
	}
	//end
	int price = [[fateDict objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d银币#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"cfpage_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^20*"];
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	
	//---------------------------------------------------------------
	if (isShowButton) {
		cmd = [cmd stringByAppendingFormat:@"^30*"];
	}
	
	return cmd;
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

-(NSString*)getEquipMessageWithItemID:(int)_id{
	NSDictionary *_dict = [[GameConfigure shared] getPlayerEquipInfoById:_id];
	if (!_dict) {
		CCLOG(@"message box equip dict is nil");
		return nil;
	}
	
	int eid = [[_dict objectForKey:@"eid"] intValue];
	int e_level = [[_dict objectForKey:@"level"] intValue] ;
	NSDictionary *equip = [[GameDB shared] getEquipmentInfo:eid];
	if (!equip) {
		CCLOG(@"message box equipDict dict is nil");
		return nil;
	}
	
	int equsetqa=[[[[GameDB shared]getEquipmentSetInfo:eid]objectForKey:@"quality"]integerValue];	
	NSString *name = [equip objectForKey:@"name"];
	NSString *cmd = [name stringByAppendingFormat:@"#%@%@",getQualityColorStr(equsetqa),@"#20#0*"];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"cfpage_no_trade",nil)];
	}
	
	int limit = [[equip objectForKey:@"limit"] intValue];
	//NSString *str_limit = [NSString stringWithFormat:@"使用等级: %d",limit];
    NSString *str_limit = [NSString stringWithFormat:NSLocalizedString(@"cfpage_use_level",nil),limit];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_limit];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int _part = [[equip objectForKey:@"part"] intValue];
	//NSString *str_part = [NSString stringWithFormat:@"装备类型: %@",getPartName(_part)];
    NSString *str_part = [NSString stringWithFormat:NSLocalizedString(@"cfpage_equip_type",nil),getPartName(_part)];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_part];
	//---------------------------------------------------------------
	if (equip) {
		cmd = [cmd stringByAppendingString:getAttrDescribetionWithDict(equip)];
	}
	
	//-------------------------------
	/*
	for (int i = 0; i < 21; i++) {
		//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
        NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
		float _value = [[equip objectForKey:[args objectAtIndex:0]] floatValue];
		CCLOG(@"%@ | %.1f",[args objectAtIndex:1],_value);
		if (_value > 0 ) {
			NSString *str_temp = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
			str_temp = [str_temp stringByAppendingFormat:@"|+%.0f#00ee00#16#0*",_value];
			cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
		}
	}
	 */
	//--------------------------------
	
	if (e_level > 0	) { //>0才有强化数据
		NSDictionary *dict_lv = [[GameDB shared] getEquipmentLevelInfo:_part level:e_level];
		if (dict_lv) {
			BaseAttribute attr = BaseAttributeFromDict(dict_lv);
			NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
			
			NSArray *array = [string componentsSeparatedByString:@"|"];
			for (NSString *_string in array) {
				NSArray *_array = [_string componentsSeparatedByString:@":"];
				if (_array.count >= 2) {
					NSString *_name = [_array objectAtIndex:0];
					NSString *_addValue = [_array objectAtIndex:1];
					
					NSString *str_temp = [NSString stringWithFormat:NSLocalizedString(@"cfpage_upgrade",nil),e_level,_name,_addValue];
					cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
				}
			}
		}
		
		/*
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value = [[dict_lv objectForKey:[args objectAtIndex:0]] floatValue];
			CCLOG(@"%@ | %.1f",[args objectAtIndex:1],_value);
			if (_value > 0 ) {
				//NSString *str_temp = [NSString stringWithFormat:@"%d级强化:%@ +%.0f#00ff00#16#0*",e_level,[args objectAtIndex:1],_value];
                NSString *str_temp = [NSString stringWithFormat:NSLocalizedString(@"cfpage_upgrade",nil),e_level,[args objectAtIndex:1],_value];
				cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
			}
		}
		 */
	}
	
	//---------------------------------
	cmd = [cmd stringByAppendingFormat:@"^10*"];
	//空
	int e_sid = [[equip objectForKey:@"sid"] intValue];
	
	NSDictionary *eset = [[GameDB shared] getEquipmentSetInfo:e_sid];
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
	
	int num = 0;
	//NSString *str_setInfo = [NSString stringWithFormat:@"套装属性(%d/6)#888888#14#0*",num];
    NSString *str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"cfpage_set_info_1",nil),num];
	if (num >= 2) {
		//str_setInfo = [NSString stringWithFormat:@"套装属性(%d/6)#ffffff#14#0*",num];
        str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"cfpage_set_info_2",nil),num];
	}
	cmd = [cmd stringByAppendingFormat:@"%@",str_setInfo];
	
	if (num >= 6) {
//		_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//		_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//		_info6 = [NSString stringWithFormat:@"6件:%@#ffffff#14#0*",_info6];
        _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_two_set",nil),_info2];
		_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_four_set",nil),_info4];
		_info6 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_six_set",nil),_info6];
	}else if(num >= 4){
//		_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//		_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//		_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
        _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_two_set",nil),_info2];
		_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_four_set",nil),_info4];
		_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_six_set",nil),_info6];
	}else if(num >= 2){
//		_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//		_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//		_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
        _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"cfpage_two_set",nil),_info2];
		_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_four_set",nil),_info4];
		_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_six_set",nil),_info6];
	}else {
//		_info2 = [NSString stringWithFormat:@"2件:%@#888888#14#0*",_info2];
//		_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//		_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
        _info2 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_two_set",nil),_info2];
		_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_four_set",nil),_info4];
		_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"cfpage_six_set",nil),_info6];
	}
	
	cmd = [cmd stringByAppendingFormat:@"%@",_info2];
	cmd = [cmd stringByAppendingFormat:@"%@",_info4];
	cmd = [cmd stringByAppendingFormat:@"%@",_info6];
	
	int price = [[equip objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d银币#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"cfpage_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	//---------------------------------------------------------------
	if (isShowButton) {
		cmd = [cmd stringByAppendingFormat:@"^30*"];
	}
	return cmd;
}
-(void) registerWithTouchDispatcher{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority-99 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	CGRect r = CGRectMake( _position.x - _contentSize.width*_anchorPoint.x,
						  _position.y - _contentSize.height*_anchorPoint.y,
						  _contentSize.width, _contentSize.height);
	r.origin = CGPointZero;
	isMenuTouch = NO;
	
	if(CGRectContainsPoint( r, touchLocation ) ){
		if ( [menu ccTouchBegan:touch withEvent:event] ) {
			CCLOG(@"Package box menu ccTouchBegan");
			isMenuTouch = YES;
		}
		//return YES;
	}
	return YES;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CCLOG(@"Package box moveing");
	
	if ( isMenuTouch ) {
		[menu ccTouchMoved:touch withEvent:event];
		CCLOG(@"Package box menu ccTouchMoved");
	}
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	/*
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	*/
	
	CGRect r = CGRectMake( _position.x - _contentSize.width*_anchorPoint.x,
						  _position.y - _contentSize.height*_anchorPoint.y,
						  _contentSize.width, _contentSize.height);
	r.origin = CGPointZero;
	
	if ( isMenuTouch ) {
		[menu ccTouchEnded:touch withEvent:event];
		CCLOG(@"Package box menu ccTouchEnded");
	}
	
	[self removeFromParentAndCleanup:YES];
	CCLOG(@"Package box ccTouchEnded");
}

@end

#pragma mark -
#pragma mark - CardLayer

@implementation CardLayer
enum{
	GXCL_PageDot_Tag=88,
};
@synthesize row;
@synthesize column;
@synthesize capacity;
@synthesize capacityMax;
@synthesize cutRect;
@synthesize pageIndex;
@synthesize target;

+(CardLayer*)create{
	CGSize size = [CCDirector sharedDirector].winSize;
	return [[[CardLayer alloc] initWithColor:ccc4(0, 0, 0, 0) width:size.width height:size.height] autorelease];
}
-(void)reload{
	[self initPage];
}
-(void)onEnter{
	[super onEnter];
	row = 4;//行
	column = 3;//列
	touchStartTime = -1;
	capacity = 12;
	pagesCount = 1;
	cutRect = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
	//[self setIsTouchEnabled:YES];
	self.touchEnabled = YES;
}
-(void)onExit
{
	[self removeAllChildrenWithCleanup:YES];
	[super onExit];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}
-(void)setCardsIsNil{
	cards = nil;
}
-(NSInteger)getPagesCount{
	return pagesCount;
}
-(void)startPageIndex:(int)page{
	pageIndex = page;
	if (pageIndex<0) {
		pageIndex = 0;
	}else if(pageIndex>=pagesCount){
		pageIndex = pagesCount-1;
	}
	
	PageDot *pageDot = (PageDot * )[self getChildByTag:GXCL_PageDot_Tag];
	[pageDot setIndex:pageIndex];
	
	cards.position = ccp(-(pageIndex)*cutRect.size.width,cards.position.y);
	//[self hideOtherPage];
	
}
-(void)setPageIndex:(NSInteger)_pageIndex{	
	pageIndex = _pageIndex;
	if (pageIndex<0) {
		pageIndex = 0;
	}else if(pageIndex>=pagesCount){
		pageIndex = pagesCount-1;
	}
	PageDot *pageDot = (PageDot * )[self getChildByTag:GXCL_PageDot_Tag];
	[pageDot setIndex:pageIndex];
	
	id move = [CCMoveTo actionWithDuration:0.5 position:ccp(-(pageIndex)*cutRect.size.width,cards.position.y)];
	id call = [CCCallBlock actionWithBlock:^(void){
		//[self hideOtherPage];
	}];
    [cards stopAllActions];
	[cards runAction:[CCSequence actions:move,call,nil]];
	
}

-(void)showNeighPage{
	
	CCLOG(@"showNeighPage");
	CCArray *array = [cards children];
	Card *card = nil;
	for (int p =0; p<pagesCount; p++) {
		for (int r = 0; r<row; r++) {
			for (int c=0; c<column; c++) {
				card = [array objectAtIndex:( column*pagesCount*r + p*column + c )];				
				if( card ){
					
					if(p==pageIndex || p==pageIndex-1 || p==pageIndex+1){
						card.visible = YES;
					}else{
						card.visible = NO;
					}
					
				}
			}
		}
	}
}

-(void)hideOtherPage{
	CCArray *array = [cards children];
	Card *card = nil;
	for (int p =0; p<pagesCount; p++) {
		for (int r = 0; r<row; r++) {
			for (int c=0; c<column; c++) {
				card = [array objectAtIndex:( column*pagesCount*r + p*column + c )];				
				if( card ){
					if(p==pageIndex){
						card.visible = YES;
					}else{
						card.visible = NO;
					}
				}
			}
		}
	}
}

-(BOOL)checkPosIsInNowPage:(CGPoint)pos{
	pos = [self convertToNodeSpace:pos];
	if (pos.x>=cutRect.origin.x && pos.x<=cutRect.origin.x+cutRect.size.width && pos.y>=cutRect.origin.y && pos.y<=cutRect.origin.y+cutRect.size.height) {
		return YES;
	}
	return NO;
}
-(BOOL)checkIsInNowPage:(Card*)_card{
	CGPoint pos = ccp(cards.position.x+_card.position.x,cards.position.y+_card.position.y);
	if (pos.x>=cutRect.origin.x && pos.x<=cutRect.origin.x+cutRect.size.width && pos.y>=cutRect.origin.y && pos.y<=cutRect.origin.y+cutRect.size.height) {
		return YES;
	}	
	return NO;
}
-(NSArray*)getLayerItemArray{
	CCArray *arr = [cards children];
	return [arr getNSArray];
}
-(void)initPage{
	////创建 背包层	
	pagesCount = capacity/(row*column);
	if (capacity%(row*column)) {
		pagesCount += 1;
	}
	if (pagesCount<=0) {
		pagesCount = 1;
	}
	capacity = pagesCount*(row*column);
	
	if(iPhoneRuningOnGame()){
		cards = [CCLayerList meshlist:row :pagesCount*column :ccp(4, 4) :4 :4];
	}else{
		cards = [CCLayerList meshlist:row :pagesCount*column :ccp(8, 8) :8 :8];
	}
	
	//[cards setIsForce:NO];
	[cards setIsDownward:YES];
	[cards setDelegate:self];
	[cards setIsForce:NO];
	
	for (int i = 0; i < pagesCount*(row*column); i++) {
		Card *card_ = [Card node];
		[cards addChild:card_];
	}
	
	[self addChild:cards];	
	cards.position = ccp(0,0);
	////
	self.contentSize = cards.contentSize;
	cutRect = CGRectMake(0, 0, self.contentSize.width/pagesCount, self.contentSize.height);
	
	////页面
	PageDot * pageBack = [PageDot node];
	[self addChild:pageBack z:3 tag:GXCL_PageDot_Tag];
	[pageBack setDotCount:pagesCount];
	
	if(iPhoneRuningOnGame()){
		[pageBack setSize:CGSizeMake(cutRect.size.width/2,26/2)];
	}else{
		[pageBack setSize:CGSizeMake(cutRect.size.width,26)];
	}
	[pageBack setIndex:0];
	
	if(iPhoneRuningOnGame()){
		pageBack.position = ccp(cutRect.size.width/2,-13/2);
	}else{
		pageBack.position = ccp(cutRect.size.width/2,-13);
	}
	
	cutRect = CGRectMake(0, -pageBack.contentSize.height, cutRect.size.width, cutRect.size.height+pageBack.contentSize.height);
	////
	
	[self startPageIndex:0];
	
}
-(void)initPageWithCount:(NSInteger)count{
	
	[self removeAllChildrenWithCleanup:YES];
	
	////创建 背包层
	pagesCount = count;
	capacity = pagesCount*(row*column);
	if(iPhoneRuningOnGame()){
		cards = [CCLayerList meshlist:row :pagesCount*column :ccp(4, 4) :4 :4];
	}else{
		cards = [CCLayerList meshlist:row :pagesCount*column :ccp(8, 8) :8 :8];
	}
	//[cards setIsForce:NO];
	[cards setIsDownward:YES];
	[cards setDelegate:self];
	[cards setIsForce:NO];
	
	for (int i = 0; i < pagesCount*(row*column); i++) {
		Card *card_ = [Card node];
		[cards addChild:card_];
	}
	[self addChild:cards];
	cards.position = ccp(0,0);
	////
	self.contentSize = cards.contentSize;
	cutRect = CGRectMake(0, 0, self.contentSize.width/pagesCount, self.contentSize.height);
	
	////页面
	PageDot * pageBack = [PageDot node];
	[self addChild:pageBack z:3 tag:GXCL_PageDot_Tag];
	[pageBack setDotCount:pagesCount];
	
	if(iPhoneRuningOnGame()){
		[pageBack setSize:CGSizeMake(cutRect.size.width,26/2)];
	}else{
		[pageBack setSize:CGSizeMake(cutRect.size.width/2,26)];
	}
	
	[pageBack setIndex:0];
	
	if(iPhoneRuningOnGame()){
		pageBack.position = ccp(cutRect.size.width/2,-13/2);
	}else{
		pageBack.position = ccp(cutRect.size.width/2,-13);
	}
	
	cutRect = CGRectMake(0, -pageBack.contentSize.height, cutRect.size.width, cutRect.size.height+pageBack.contentSize.height);
	////
	[self setPageIndex:0];
}
////增加物品(ID,value)
-(BOOL)addItemWithDict:(NSDictionary*)dict{
	CCArray *array = [cards children];
	Card *card = nil;
	for (int p =0; p<pagesCount; p++) {
		for (int r = 0; r<row; r++) {
			for (int c=0; c<column; c++) {
				card = [array objectAtIndex:( column*pagesCount*r + p*column + c )];				
				if( card && NO == [card isOwnItem]){
					[card changeItemWithDict:dict];
					return YES;
				}
			}
		}
	}
//	for(Card *card in array) {
//		if( NO == [card isOwnItem]){
//			[card changeItemWithDict:dict];
//			return YES;
//		}
//	}
	return NO;
}
-(void)removeItemWithID:(NSInteger)itemID{
	CCArray *array = [cards children];
	for(Card *card in array) {
		if( YES == [card isOwnItem] && itemID == [card getItemID]){
			[card removeItem];
		}
	}	
}
-(void)removeAllItem{
	CCArray *array = [cards children];
	for(Card *card in array) {
		if( YES == [card isOwnItem]){
			[card removeItem];			
		}
	}
}
-(void)setBatSale:(BOOL)isSale{
	CCArray *array = [cards children];	
	for(Card *card in array) {
		if( YES == [card isOwnItem]){
			if (isSale) {
				[card showItemSelected];
			}else{
				[card hideItemSelected];
			}			
		}
	}
}

-(void)visit{
	CGPoint pt = [self.parent convertToWorldSpace:self.position];
	int clipX = pt.x+cutRect.origin.x;
	int clipY = pt.y+cutRect.origin.y;
	int clipW = self.cutRect.size.width;
	int clipH = self.cutRect.size.height;
	float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
	glScissor(clipX*zoom,
			  clipY*zoom,
			  clipW*zoom,
			  clipH*zoom);
    glEnable(GL_SCISSOR_TEST);
    [super visit];
    glDisable(GL_SCISSOR_TEST);
}

-(void)callbackTouch:(CCLayerList *)_list :(CCListItem *)_listItem :(UITouch *)touch
{
	CCLOG(@"callbackTouch");
	//TODO
}
-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority+1 swallowsTouches:YES];
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	CCLOG(@"card layer touch bagan");
	
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	if (CGRectContainsPoint(cutRect, touchLocation)) {
		touchStartTime = [NSDate timeIntervalSinceReferenceDate];
		CCLOG(@"touchTime:%f",touchStartTime);
		
		startMovePos = touchLocation;
		pageStartMovePos = touchLocation;
		
		[self showNeighPage];
		
		return YES;
	}
	
    return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"moveing");
	touchStartTime = -1;
	
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];   
	
	if (CGRectContainsPoint(cutRect, [self convertToNodeSpace:touchLocation])) {
		touchLocation = [self convertToNodeSpace:touchLocation];
		CGPoint dPos = ccpSub(touchLocation, startMovePos);
		if (abs(dPos.x)>30) {
			isMovePage = YES;
		}
		CCLOG(@"dPos.x:%f",dPos.x);
		
		cards.position = ccp(cards.position.x+dPos.x,cards.position.y);		
		startMovePos = touchLocation;
	}
	
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	////
	touchLocation = ccpSub(touchLocation,pageStartMovePos );
	[self updatePageWithMovePos:touchLocation];
}

-(void)updatePageWithMovePos:(CGPoint)pos{
	if (pos.x < 0  && (abs(pos.x)>cutRect.size.width/2 || isMovePage) ) {		
		[self setPageIndex:pageIndex+1];
	}else if(pos.x > 0 && (abs(pos.x)>cutRect.size.width/2 || isMovePage)){
		[self setPageIndex:pageIndex-1];
	}
	else{
		[self setPageIndex:pageIndex];
	}
	isMovePage = NO;
}
-(void)selectedEvent:(CCLayerList*)_list :(CCListItem*)_listItem{
	CCLOG(@"selectedEvent!");
	//Card *card_ = (Card*)_listItem;
}
@end