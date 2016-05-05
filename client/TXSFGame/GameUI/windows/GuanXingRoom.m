//
//  GuanXingRoom.m
//  TXSFGame
//
//  Created by chao chen on 12-12-4.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "GuanXingRoom.h"
#import "GameMoney.h"
#import "AnimationViewer.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "Window.h"
#import "GameConnection.h"
#import "CJSONDeserializer.h"
#import "CFPage.h"
#import "CFDialog.h"
#import "ClickAnimation.h"
#import "GameLoading.h"
#import "InfoAlert.h"
#import "ShowItem.h"
#import "FateIconViewerContent.h"

//Iphone for chenjunming

//#if TARGET_IPHONE
//#define GXR_MONEY_DW (15)/2
//#define GXR_MONEY_DH (5)/2
//#define GXR_BUTTON_Y （70)/2
////卡片的高度，如果获得的物品显示不完整，可改这里
//#define GXR_CARD_W (63)/2
//#else
//IPAD
#define GXR_MONEY_DW (cFixedScale(15))
#define GXR_MONEY_DH (cFixedScale(14))
#define GXR_MONEY_DH2 (cFixedScale(7))
#define GXR_BUTTON_Y (cFixedScale(70))
#define GXR_CARD_W (cFixedScale(63))
//#endif

NSDictionary* s_fateDict = nil;

//#define GXR_CARD_X (200)
#define YUANBAO_GUANXING @"yuanBaoGuanXing"
#pragma mark -
#pragma mark - GXRCard

enum GXRCardTags{
	kGXRCardQuality,// 品质
	kGXRCardName ,// 名字
	kGXRCardTrade ,// 交易
	kGXRCardCount,// 数量
};

typedef enum {
	GXRWIT_i,//物品
	GXRWIT_e,//装备
	GXRWIT_f,//命格
	GXRWIT_c,//坐骑
	GXRWIT_m,//钱
}GXRWaitItemType;

@interface GXRCard:AnimationViewer{	
	GXRWaitItemType type;
	NSInteger	itemID;
	NSInteger	cardID;
	NSInteger   count;
	NSInteger	isTrade;
}
@property (nonatomic,assign) GXRWaitItemType type;
@property (nonatomic,assign) NSInteger cardID;
@property (nonatomic,assign) NSInteger count;
@property (nonatomic,assign) NSInteger isTarde;
////
-(NSInteger)getItemID;
-(void)changeItemWithDict:(NSDictionary*)dict;//改变物品
-(void)changeItemWithOther:(GXRCard*)other;
-(void)setNameVisible:(BOOL)visible;
-(CGRect)rect;
@end

@implementation GXRCard
@synthesize type;
@synthesize cardID;
@synthesize count;
@synthesize isTarde;

-(void)onEnter{
	////
	[super onEnter];	
	[self setNull];
}
-(void)setNull{
	type = GXRWIT_f;
	////
	[self setCardID:1];
	[self setCount:1];
	[self setIsTrade:NO];
}
-(CGRect)rect
{
//	return CGRectMake( position_.x - contentSize_.width*anchorPoint_.x,
//					  position_.y - contentSize_.height*anchorPoint_.y,
//					  contentSize_.width, contentSize_.height);
//
    int w = cFixedScale(48);
    return CGRectMake( _position.x - w*_anchorPoint.x,
					  _position.y - w*_anchorPoint.y,
					  w, w);
}
-(NSInteger)getItemID{
	return itemID;
}
-(void)setNameVisible:(BOOL)visible{
	CCLabelTTF *nameLabel = (CCLabelTTF *)[self getChildByTag:kGXRCardName];
	[nameLabel setVisible:visible];
}
-(void)setCount:(NSInteger)_count{
	if (_count<=0) {
		CCLOG(@"count is <=0 ");
		return;
	}
	count = _count;
	if (type == GXRWIT_m || type == GXRWIT_i ) {
		[self setName:[NSString stringWithFormat:@"%d",count]];
	}else if(type == GXRWIT_f){
		if (count>1) {
			NSDictionary *fidDict;
			NSString *name = nil;
			fidDict = [[GameDB shared] getFateInfo:cardID];
			name = [fidDict objectForKey:@"name"];
			[self setName:[NSString stringWithFormat:@"%@x%d",name,count]];
		}
	}
}
-(void)setIsTrade:(NSInteger)_isTraded{
	
	if ( _isTraded == TradeStatus_yes) {
		CCSprite *nameTrade = (CCSprite *)[self getChildByTag:kGXRCardTrade];
		if (nil == nameTrade) {
			nameTrade = [CCSprite spriteWithFile:@"images/ui/common/yuanbao.png"];
			[self addChild:nameTrade z:0 tag:kGXRCardTrade];
			nameTrade.anchorPoint = ccp(1,1);
			nameTrade.position = ccp(self.contentSize.width,self.contentSize.height);
		}else{
			nameTrade.visible = YES;
		}

	}
}
-(void)setName:(NSString *)name{

	if (!name) {
		CCLOG(@"name error");
		return ;
	}

	CCLabelTTF *nameLabel = (CCLabelTTF *)[self getChildByTag:kGXRCardName];
	if (nil == nameLabel) {
        float fontSize=16;
        //名字的大小，如果觉得字体太大，可修改这里
        if (iPhoneRuningOnGame()) {
            fontSize=9;
        }
        //
		nameLabel = [CCLabelTTF labelWithString:name fontName: @"Verdana-Bold" fontSize:fontSize];
		[self addChild:nameLabel z:0 tag:kGXRCardName];
		nameLabel.visible = YES;
	}else{
		[nameLabel setString:name];
	}
	if (iPhoneRuningOnGame()) {
		nameLabel.position = ccp(self.contentSize.width/2,-cFixedScale(45));
	}else{
		nameLabel.position = ccp(self.contentSize.width/2,-cFixedScale(50));
	}
}

-(NSArray*)getFramesWithPath:(NSString*)path{
	NSMutableArray *arr = [NSMutableArray array];
	CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:path];
	
	if(frame){
		[arr addObject:frame];
	}else{
		if(checkHasFile([[CCFileUtils sharedFileUtils] fullPathFromRelativePath:path])){
			CCTexture2D * texture = [[CCTextureCache sharedTextureCache] addImage:path];
			frame = [CCSpriteFrame frameWithTexture:texture rect:
					 CGRectMake(0,0,texture.contentSize.width,texture.contentSize.height)];
			[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:path];
			[arr addObject:frame];
		}else{
			return nil;
		}
	}
	return arr;
}

-(void)setCardID:(NSInteger)_ufid{
	
	cardID = _ufid;
	//NSDictionary *fidDict;
	NSString *name = nil;
	//NSString *act;
	[self removeChildByTag:kGXRCardQuality cleanup:YES];
	
	if (type == GXRWIT_f) {
		
		/*
		//fidDict = [[GameConfigure shared] getFateById:cardFid];
		//soul
		fidDict = [[GameDB shared] getFateInfo:cardID];
		name = [fidDict objectForKey:@"name"];
		
		NSArray * frames = [self getFramesWithPath:[NSString stringWithFormat:@"images/ui/fate/soul%d.png",[[fidDict objectForKey:@"id"] intValue]]];
		[self playAnimation:frames];
		
		//fix chao
		int quality = 0;
		NSDictionary * t_Dict = [s_fateDict objectForKey:[NSString stringWithFormat:@"%d",_ufid]];
		if (t_Dict) {
			quality = [[t_Dict objectForKey:@"quality"] intValue];
		}		
		NSString *str_ = nil;
		if (quality == IQ_BLUE) {
			str_ = @"images/animations/fate/blue/";
		}else if(quality == IQ_PURPLE) {
			str_ = @"images/animations/fate/purple/";
		}else{
			str_ = @"images/animations/fate/green/";
		}
		if (str_) {
			[ClickAnimation showInLayer:self z:-1 tag:kGXRCardQuality call:nil point:ccp(self.contentSize.width/2, self.contentSize.height/2) path:str_ loop:YES];
		}
		*/
		
		NSDictionary * info = [s_fateDict objectForKey:[NSString stringWithFormat:@"%d",cardID]];
		name = [info objectForKey:@"name"];
		
		FateIconViewerContent * icon = [FateIconViewerContent create:cardID];
		icon.quality = [[info objectForKey:@"quality"] intValue];
		[self addChild:icon z:-1 tag:kGXRCardQuality];
		
	}else if(type == GXRWIT_m){		
		//NSArray * frames = [self getFramesWithPath:@"images/ui/object-icon/1.png"];
		//[self playAnimation:frames];
		
		CCSprite * icon = [CCSprite spriteWithFile:@"images/ui/object-icon/1.png"];
		[self addChild:icon z:-1 tag:kGXRCardQuality];
		
	}else if(type == GXRWIT_i){
		/*
		NSArray * frames = nil;
		if (cardID >= 1 && cardID <= 6) {
			frames = [self getFramesWithPath:[NSString stringWithFormat:@"images/ui/object-icon/%d.png",cardID]];
			[self playAnimation:frames];
		}
		*/
		
		NSString * path = [NSString stringWithFormat:@"images/ui/object-icon/%d.png",cardID];
		CCSprite * icon = [CCSprite spriteWithFile:path];
		[self addChild:icon z:-1 tag:kGXRCardQuality];
		
	}

	[self setName:name];
}
-(void)changeItemWithOther:(GXRCard*)other{
	type = [other type];
	itemID = [other getItemID];
	[self setCardID:[other cardID]];
	[self setCount:[other count]];
	[self setIsTrade:[other isTarde]];
}
//改变物品
-(void)changeItemWithDict:(NSDictionary*)dict{
	//dict = _dict;
	NSNumber *itemIDNumber = [dict objectForKey:@"id"];
	NSNumber *bidNumber = [dict objectForKey:@"bid"];
	NSNumber *typeNumber = [dict objectForKey:@"type"];//GXRWaitItemType
	NSNumber *countNumber = [dict objectForKey:@"count"];
	NSNumber *tradeNumber = [dict objectForKey:@"isTrade"];
	
	if ([bidNumber intValue]<=0 && ([typeNumber intValue]<GXRWIT_i || [typeNumber intValue]>GXRWIT_m )) {
		return;
	}
	////	
	type = [typeNumber intValue];
	itemID = [itemIDNumber intValue];
	////
	[self setCardID:[bidNumber intValue]];
	[self setCount:[countNumber intValue]];
	[self setIsTrade:[tradeNumber intValue]];
}

@end

#pragma mark -
#pragma mark - GXRCardLayer

#define GXCL_SHOW_LEN (10)
#define GXCL_CARD_MOVETO_X	(s_gxcl_card_startpos_x)
#define GXCL_CARD_MOVETO_Y	(s_gxcl_card_startpos_y + GXR_CARD_W)

//#define  s_gxcl_card_startpos_x (cFixedScale(230))
//#define  s_gxcl_card_startpos_y (cFixedScale(145))
static float s_gxcl_card_startpos_x = 0;
static float s_gxcl_card_startpos_y = 0;

@interface GXRCardLayer : CCLayerColor{
	NSMutableArray				*cards;
	CGRect cutRect;	
	//
	CGPoint startPos;
	id target;
	//
	BOOL isTouchMove;
	CGPoint startMovePos;
	CGPoint layerStartMovePos;
}
@property (nonatomic,assign) id target;
@property (nonatomic,assign) CGRect cutRect;
-(NSInteger)getFateCount;
-(NSInteger)getCardsCount;
-(void)updateItemWithDictArr:(NSArray*)dictArr;
-(BOOL)addItemWithDict:(NSDictionary*)dict;
-(BOOL)addItem:(GXRCard*)card;
-(void)removeItemWithIndex:(NSInteger)index;
-(void)removeItem:(GXRCard*)item;
-(void)removeItemWithArray:(NSArray*)itemArr;
-(void)removeAllItem;
-(void)leftMoveStep;
-(void)rightMoveStep;
-(NSArray*)getShowCards;
-(NSArray*)getCardsWithItemID:(NSInteger)itemID;
-(void)moveCardByPos:(CGPoint)pos;
@end

@implementation GXRCardLayer
@synthesize target;
@synthesize cutRect;

-(void)onEnter{
	[super onEnter];
	
	self.touchEnabled = YES;
	////
	cards = [NSMutableArray array];
	[cards retain];
	startPos.x = s_gxcl_card_startpos_x;
	startPos.y = s_gxcl_card_startpos_y;
    /*
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            startPos.x += cFixedScale(60);
        }else{
            startPos.y += cFixedScale(40);
        }
    }
     */
    //TODO 调整卡片图层的位置和宽高
    cutRect = CGRectMake(startPos.x-GXR_CARD_W/2, startPos.y-GXR_CARD_W+cFixedScale(5), GXR_CARD_W*GXCL_SHOW_LEN, GXR_CARD_W*2);

	////
	//[self setIsTouchEnabled:YES];
	self.touchEnabled = YES;
	
}
-(void)onExit{
	[cards release];
	cards = nil;
	////
	[super onExit];
}
-(NSArray*)getCardsWithItemID:(NSInteger)itemID{
	if (itemID<=0) {
		CCLOG(@"item id error");
		return nil;
	}
	NSMutableArray *arr;
	arr = [NSMutableArray array];
	for (GXRCard *card in cards) {
		if ([card getItemID] == itemID) {
			[arr addObject:card];
		}
	}
	return arr;
}
-(NSArray*)getShowCards{
	NSMutableArray *arr;
	arr = [NSMutableArray array];
	for (GXRCard *card in cards) {
		if ((self.position.x+card.position.x)>=startPos.x && (self.position.x+card.position.x)<=(startPos.x+GXR_CARD_W*GXCL_SHOW_LEN) ) {
			[arr addObject:card];
		}
	}
	return arr;
}
-(NSInteger)getFateCount{
	int c = 0;
	for (GXRCard *card in cards) {
		if ([card type]==GXRWIT_f) {
			if ([card count]>1) {
				c += [card count];
			}else{
				c++;
			}
		}
	}
	return c;
}

-(NSInteger)getCardsCount{
	return [cards count];
}
-(void)leftMoveStep{
	//TODO
	CGPoint pos = ccp(self.position.x-GXR_CARD_W,self.position.y);
	if ([cards count]>0) {		
		GXRCard *card = [cards objectAtIndex:0];		
		if ((self.position.x+card.position.x)<(startPos.x+GXR_CARD_W*GXCL_SHOW_LEN)) {
			pos.x = self.position.x;
		}
		[self stopAllActions];
		[self runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:pos], [CCCallFuncN actionWithTarget:self selector:@selector(moveStepBackCall:)], nil ]];
	}
	
}
-(void)rightMoveStep{
	//TODO
	CGPoint pos = ccp(self.position.x+GXR_CARD_W,self.position.y);	
	
	if (pos.x>0) {
		pos.x = 0;			
	}
	[self stopAllActions];	
	[self runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:pos], [CCCallFuncN actionWithTarget:self selector:@selector(moveStepBackCall:)],nil]];
	//[self runAction:[CCMoveTo actionWithDuration:0.5 position:pos]];
}
-(void)moveStepBackCall:(id)sender{
	[self checkPoint];
}
-(void)updateItemWithDictArr:(NSArray*)dictArr{
	for (NSDictionary *dict in dictArr) {		
		GXRCard *tCard = [GXRCard node];

		
		if (tCard) {
			[self addChild:tCard];
			[tCard changeItemWithDict:dict];
			tCard.position = startPos;
			int i = [cards count];
			for (GXRCard* card in cards) {
				//[card runAction:([CCMoveBy actionWithDuration:0.5 position:ccp(GXR_CARD_W, 0)])];
                [card stopAllActions];
                if (iPhoneRuningOnGame()) {
                    //GXR_CARD_W/2为修改物品的间距
                    [card runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x + GXR_CARD_W*i, startPos.y) ])];
                }else{
                    [card runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x + GXR_CARD_W*i, startPos.y) ])];
                }
				i--;
			}
			[cards addObject:tCard];
		}
		
	}	
}
-(void)moveCardByPos:(CGPoint)pos{
	GXRCard *card;
	for (int i=([cards count]-1);i>=0;i--) {
		card = [cards objectAtIndex:i];
		if ((card.position.x+self.position.x-s_gxcl_card_startpos_x)>=0) {
			card.position = ccp(startPos.x + GXR_CARD_W*([cards count] - i - 1)+pos.x, startPos.y+pos.y);
		}
		
		//[card runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x + GXR_CARD_W*([cards count] - i - 1)+pos.x, startPos.y+pos.y)])];
	}
}
-(void)addCardToZero:(GXRCard*)card{
	GXRCard *t_Card;
	
	if ([cards count]<=0) {
		card.position = ccp(card.position.x-self.position.x,card.position.y);
		[cards addObject:card];
	}else{
		for (int i=[cards count]-1;i>=0;i--) {
			t_Card = [cards objectAtIndex:i];
			if ((t_Card.position.x+self.position.x-s_gxcl_card_startpos_x)>=0) {
				[cards insertObject:card  atIndex:i+1];
				return;
			}
		}
		[cards insertObject:card  atIndex:0];
	}
}
-(BOOL)addItem:(GXRCard*)card{
	if (card) {		
		GXRCard *tCard = [GXRCard node];		
		if (tCard) {
			[self addChild:tCard];
			[tCard changeItemWithOther:card];
			CGPoint pos;
			if([cards count]<=0||YES){
				pos.x = s_gxcl_card_startpos_x-self.position.x;
				pos.y = s_gxcl_card_startpos_y;
			}else{
				pos.x = GXCL_CARD_MOVETO_X-self.position.x;
				pos.y = GXCL_CARD_MOVETO_Y;
			}			
			tCard.position = pos;
			[self addCardToZero:tCard];
			[self resetCardPos];
			[tCard setNameVisible:YES];
			//[tCard runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x , startPos.y)])];
			[tCard stopAllActions];
			[tCard runAction:([CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x-self.position.x, startPos.y)],[CCCallFuncN actionWithTarget:self selector:@selector(addItemCall:)], nil ])];
			return YES;
		}
	}
	return NO;
}
-(void)addItemCall:(id) sender{
	GXRCard *tCard = sender;
	[tCard setNameVisible:YES];
	//fix chao
	[self resetCardPos];
	//end
}

////增加物品(ID,value)
-(BOOL)addItemWithDict:(NSDictionary*)dict{
	GXRCard *tCard = [GXRCard node];
	[tCard changeItemWithDict:dict];
	CGPoint pos;
	if([cards count]<=0||YES){
		pos.x = s_gxcl_card_startpos_x-self.position.x;
		pos.y = s_gxcl_card_startpos_y;
	}else{
		pos.x = GXCL_CARD_MOVETO_X-self.position.x;
		pos.y = GXCL_CARD_MOVETO_Y;
	}
    if (iPhoneRuningOnGame()) {
        tCard.position = ccp(pos.x/2,pos.y/2);
    }else{
        tCard.position = pos;
    }
	
	if (tCard) {
		[self addCardToZero:tCard];
		[self resetCardPos];
		[self addChild:tCard];
		[tCard stopAllActions];
		//[tCard runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x-self.position.x , startPos.y)])];		
		[tCard runAction:([CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x-self.position.x, startPos.y)],[CCCallFuncN actionWithTarget:self selector:@selector(addItemCall:)], nil ])];
		
		return YES;
	}
	return NO;
}
-(void)removeItemWithIndex:(NSInteger)index{
	if ([cards count]>0) {	
		GXRCard *card = [cards objectAtIndex:([cards count]-index-1)];
		if (card) {
			[self removeItem:card];
		}
	}
}
-(void)removeItem:(GXRCard*)item{
	if (item) {
		BOOL isMove=NO;
		GXRCard *card;
		for (int i=([cards count]-1);i>=0;i--) {
			card = [cards objectAtIndex:i];
			if (isMove) {
				//[card runAction:([CCMoveBy actionWithDuration:0.5 position:ccp(-GXR_CARD_W, 0)])];
				[card runAction:([CCMoveTo actionWithDuration:0.5 position:ccp(startPos.x + GXR_CARD_W*([cards count] - i - 2), startPos.y)])];
			}
			if (item == card) {
				isMove = YES;
			}			
		}		
		
		[cards removeObject:item];
		[self removeChild:item cleanup:YES];
		[self checkPoint];
//		[item runAction:([CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(800,600)],[CCCallFuncN actionWithTarget:self selector:@selector(removeItemCall:)], nil ])];
	}
}
-(void)resetCardPos{
	GXRCard *card;
	float len = 1.0f;
	for (int i=([cards count]-1);i>=0;i--) {
		card = [cards objectAtIndex:i];
		[card stopAllActions];
		len = abs(startPos.x + GXR_CARD_W*([cards count] - i - 1)-card.position.x);
		[card runAction:([CCMoveTo actionWithDuration:0.001*len position:ccp(startPos.x + GXR_CARD_W*([cards count] - i - 1), startPos.y)])];
	}
}
-(void)removeItemWithArray:(NSArray*)itemArr{
	for (GXRCard *item in itemArr) {
		[cards removeObject:item];
		[self removeChild:item cleanup:YES];
	}	
	[self resetCardPos];
	[self checkPoint];
}
//-(void)removeItemCall:(id) sender{
//	[self removeChild:sender cleanup:YES];
//}

-(void)removeAllItem{
	for (GXRCard *card in cards) {
        [card stopAllActions];
		[card removeFromParentAndCleanup:YES];		
	}
	[cards removeAllObjects];
}
-(void)visit{
    float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
	glScissor(cutRect.origin.x*zoom,cutRect.origin.y*zoom, cutRect.size.width*zoom, (cutRect.size.height+GXR_CARD_W)*zoom);
	//glScissor((GLsizei)(startPos.x-GXR_CARD_W/2),(GLsizei)(startPos.y-GXR_CARD_W), (GLsizei)(GXR_CARD_W*GXCL_SHOW_LEN), (GLsizei)(GXR_CARD_W*3));
	//CGRectMake(startPos.x-GXR_CARD_W/2, startPos.y-GXR_CARD_W, GXR_CARD_W*GXCL_SHOW_LEN, GXR_CARD_W*2);
	glEnable(GL_SCISSOR_TEST);
	[super visit];
	glDisable(GL_SCISSOR_TEST);
}
//-(void)draw
//{	
//	[super draw];	
//	//cutRect.origin.x = -self.position.x + startPos.x-GXR_CARD_W/2;
//	ccDrawSolidRect( ccp(cutRect.origin.x , cutRect.origin.y), ccp(cutRect.origin.x+cutRect.size.width, cutRect.origin.y+cutRect.size.height ), ccc4FFromccc4B(ccc4(255, 0, 0, 128)));	
//	ccDrawColor4B(150, 100, 20, 255);
////	ccDrawRect(ccp(cutRect.origin.x , cutRect.origin.y), ccp(cutRect.origin.x+cutRect.size.width, cutRect.origin.y+cutRect.size.height));
//}
-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority-180 swallowsTouches:YES];
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	CCLOG(@"GXR card layer touch bagan");
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	startMovePos = touchLocation;
	
    touchLocation = [self convertToNodeSpace:touchLocation];
    CGRect rect;
//    if (iPhoneRuningOnGame()) {
//        rect = CGRectMake(cutRect.origin.x/2, cutRect.origin.y, cutRect.size.width/2, cutRect.size.height/2);
//        
//    }else{
        rect = CGRectMake(cutRect.origin.x-self.position.x, cutRect.origin.y, cutRect.size.width, cutRect.size.height);
   // }
	if(YES == CGRectContainsPoint(rect,touchLocation)){
		CCLOG(@"GXR card layer touch bagan YES");
		
		layerStartMovePos = self.position;
		return YES;
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"moveing");	
	isTouchMove = YES;
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	CGPoint dPos = ccpSub(touchLocation, startMovePos);	
	dPos.y = 0;
	self.position = ccpAdd(layerStartMovePos,dPos);
}

-(void)checkPoint{
	CGPoint pos = ccp(self.position.x,self.position.y);
    
	[self stopAllActions];
    
	if (pos.x>0 || [cards count]<=GXCL_SHOW_LEN) {
		pos.x = 0;
		[self runAction:[CCMoveTo actionWithDuration:0.5 position:pos]];
	}else{
		GXRCard *card = [cards objectAtIndex:0];
		if ((self.position.x+card.position.x)<(startPos.x+GXR_CARD_W*GXCL_SHOW_LEN)) {
			pos.x = -1.0*GXR_CARD_W*([cards count]-GXCL_SHOW_LEN);
			[self runAction:[CCMoveTo actionWithDuration:0.5 position:pos]];
		}else{
			pos.x = (int)(abs(self.position.x)/GXR_CARD_W+0.5);
			pos.x = -1.0*GXR_CARD_W*abs(pos.x);
			[self runAction:[CCMoveTo actionWithDuration:0.5 position:pos]];
		}
		
	}

}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	if ( NO == isTouchMove ) {
		for (GXRCard *card in cards) {
			
			if ( CGRectContainsPoint(card.rect,touchLocation)) {
				NSArray *arr = [NSArray arrayWithObject:card];
				[target removeCard:arr];
				break;
			}
		}
		
	}else{
		[self checkPoint];
	}
	
	////
	isTouchMove = NO;
	CCLOG(@"GXR Layer ccTouchEnded");
}

@end

#pragma mark -
#pragma mark - GXRRole
@interface GXRRole : AnimationViewer{
	NSString * path;
}
-(void)setRoleWithPID:(NSInteger)rolePID;
@end
@implementation GXRRole
-(void)setRoleWithPID:(NSInteger)rolePID{
	NSDictionary* d1 = [[GameConfigure shared] getPlayerRoleFromListById:rolePID];
	int eq2 =0;
	int eid =0;
	if (d1) {
		eq2 = [[d1 objectForKey:@"eq2"] intValue];
		NSDictionary* d2 = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
		if (d2) {
			eid = [[d2 objectForKey:@"eid"] intValue];
		}		
	}
	if (eid>0) {
		path = [NSString stringWithFormat:@"images/animations/role/r%d_%d/%d/%d/",rolePID,eid,RoleAction_stand,RoleDir_up_flat];
	}else{
		path = [NSString stringWithFormat:@"images/animations/role/r%d/%d/%d/",rolePID,RoleAction_stand,RoleDir_up_flat];
	}
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	[self playAnimation:frames];
	[self setScaleX:-1];
}

@end

#pragma mark -
#pragma mark - GuanXingRoom
//#if TARGET_IPHONE
//static int s_gxr_card_pos_x= (266/2);
//static int s_gxr_card_pos_y= (445/2);
//CGPoint g_gxr_posArray[5] =
//{
//	{(512+150+75)/2,(25+23)/2},
//	{(512+150)/2,(25+23)/2},
//	{512/2,(25+23)/2},
//	{(512-150)/2,(25+23)/2},
//	{(512-150-75)/2,(25+23)/2},
//};
//#else
//#define s_gxr_card_pos_x cFixedScale(266)
//#define s_gxr_card_pos_y cFixedScale(445)
static float s_gxr_card_pos_x = 0;
static float s_gxr_card_pos_y = 0;

CGPoint g_gxr_posArray[5] =
{
	{512+150+75,25+23},
	{512+150,25+23},
	{512,25+23},
	{512-150,25+23},
	{512-150-75,25+23},
};
//#endif


@implementation GuanXingRoom
enum{
	GXR_YUANBAO_ONE_TAG,
	GXR_YUANBAO_TWO_TAG,
	GXR_YINBI_TAG,
	GXR_ROLE_TAG,
	GXR_CARD_TAG,
	GXR_CARDLAYER_TAG,
	GXR_MESSAGE_BOX_TAG,
	GXR_BUTTON_YES_TAG,
	GXR_BUTTON_NO_TAG,
	//
	GXR_YIBI_INFO_TAG,
	GXR_YUANBAO_INFO_TAG,
    GXR_RANDOM_INFO_TXT_TAG,
	GXR_HIT_INFO_TXT_TAG,
	GXR_RANDOM_INFO_TAG,
	GXR_HIT_INFO_TAG,
};
typedef enum{
	GXRMT_random = 1,
	GXRMT_randomBat,
	GXRMT_hit,
	GXRMT_hitBat,
	GXRMT_fateYiBiUp,
	GXRMT_fateYuanBaoUp,
	GXRMT_packageFull,
}GuanXingRoomMessageType;

typedef enum{
	GXRS_Stop = 1,
	GXRS_GuanXingSend,
	GXRS_GuanXing,
	GXRS_ShowFate,
	GXRS_GetFate,
}GuanXingRoomState;

@synthesize isOpenHeight;
@synthesize isOpenBat;
-(void)reSetPosArrayWithY:(int)y width:(int)w{
	CGSize winsize = [[CCDirector sharedDirector] winSize];

	int x = winsize.width/2;
	int d = w/2;
	x -= d*3;
	
	for (int i=0; i<sizeof(g_gxr_posArray)/sizeof(g_gxr_posArray[0]); i++) {
		g_gxr_posArray[i].x = x+i*d+d;
		g_gxr_posArray[i].y = y;
	}
}
-(void)updateFateMaxCount{
	
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	int vip= [[dict objectForKey:@"vip"] intValue];
	NSDictionary *globalDict = [[GameDB shared] getGlobalConfig];
	NSString *coin1Str = [globalDict objectForKey:@"hitFateCoin1Max"];
	NSString *coin2Str = [globalDict objectForKey:@"hitFateCoin2Max"];
	hitFateCoin1Max = 0;
	hitFateCoin2Max = 0;
	int zeroCoin1Max = 0;
	int zeroCoin2Max = 0;
	BOOL isHaveCoin1Max = NO;
	BOOL isHaveCoin2Max = NO;
	///
	NSArray *bagsStrArr =[coin1Str componentsSeparatedByString:@"|"];
	NSArray *capacityArr=nil;	
	for (NSString *str in bagsStrArr) {
		if (str) {
			capacityArr = [str componentsSeparatedByString:@":"];
			if ([capacityArr count]>1) {				
				if (vip == [[capacityArr objectAtIndex:0] intValue]) {
					hitFateCoin1Max = [[capacityArr objectAtIndex:1] intValue];
					isHaveCoin1Max = YES;
					break;
				}
				if (0==[[capacityArr objectAtIndex:0] intValue]) {
					zeroCoin1Max = [[capacityArr objectAtIndex:1] intValue];
				}
			}
		}
	}
	///
	bagsStrArr =[coin2Str componentsSeparatedByString:@"|"];
	capacityArr=nil;
	for (NSString *str in bagsStrArr) {
		if (str) {
			capacityArr = [str componentsSeparatedByString:@":"];
			if ([capacityArr count]>1) {
				if (vip == [[capacityArr objectAtIndex:0] intValue]) {
					hitFateCoin2Max = [[capacityArr objectAtIndex:1] intValue];
					isHaveCoin2Max = YES;
					break;
				}
				if (0==[[capacityArr objectAtIndex:0] intValue]) {
					zeroCoin2Max = [[capacityArr objectAtIndex:1] intValue];
				}
			}
		}
	}
	if (isHaveCoin1Max == NO) {
		hitFateCoin1Max = zeroCoin1Max;
	}
	if (isHaveCoin2Max == NO) {
		hitFateCoin2Max = zeroCoin2Max;
	}
}
-(void)loadFactDict{
	if (!s_fateDict) {
		s_fateDict = [[GameDB shared] readDB:@"fate"];
		[s_fateDict retain];		
	}
}
-(void)onEnter{
	[super onEnter];
    
	isSend = NO;
    isBeganTouch = NO;
	[self loadFactDict];
    s_gxcl_card_startpos_x = cFixedScale(230);
    s_gxcl_card_startpos_y = cFixedScale(145);
    s_gxr_card_pos_x = cFixedScale(266);
    s_gxr_card_pos_y = cFixedScale(445);
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            s_gxcl_card_startpos_x += cFixedScale(60);
            s_gxr_card_pos_x += cFixedScale(60);
        }else{
            s_gxcl_card_startpos_x += cFixedScale(-30);
            s_gxr_card_pos_x += cFixedScale(-30);
        }
    }
	CGSize size;
	size = [[CCDirector sharedDirector] winSize];	
	
	isFinished = YES;
	isDisplay = NO;
	isOpenHeight = YES;
	yinBiCount=0;
	yuanBaoCount = 0;
	//
	[self updateFateMaxCount];
	//
	//NSDictionary *gl_dict = [[GameDB shared] getGlobalConfig];
	//int hitFateBatchNum = [[gl_dict objectForKey:@"hitFateBatchNum"] intValue];
	
    CCSprite* upBg=nil;
    if (iPhoneRuningOnGame()) {
        upBg=[CCSprite spriteWithFile:@"images/ui/wback/GXRBack2.jpg"];
        //        upBg.anchorPoint = ccp(0.5,0.5);
        upBg.position = ccp(size.width/2,self.contentSize.height-upBg.contentSize.height/2);
        
        [self addChild:upBg];
    }

	////
	CCSprite *down_bg = [CCSprite spriteWithFile:@"images/ui/panel/GXRDownImage.png"];
	down_bg.anchorPoint = ccp(0.5,0);
	down_bg.position = ccp(size.width/2,0);
	[self addChild:down_bg];
	
	menu = [CCMenu menuWithItems:nil];
	menu.position = CGPointZero;
	[self addChild:menu z:3];
	
	////钱
	CCSprite *moneyBack = [CCSprite spriteWithFile:@"images/ui/panel/GXRMoneyBack.png"];
	moneyBack.anchorPoint = ccp(0,1);
	[self addChild:moneyBack];
	////元宝1
	GameMoney *yuanbao01 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:0];
	[self addChild:yuanbao01 z:3 tag:GXR_YUANBAO_ONE_TAG];
	yuanbao01.tag = GXR_YUANBAO_ONE_TAG;
	yuanbao01.anchorPoint = ccp(0,0.5);
	
	////元宝2
	GameMoney *yuanbao02 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO value:0];
	[self addChild:yuanbao02 z:3 tag:GXR_YUANBAO_TWO_TAG];
	yuanbao02.tag = GXR_YUANBAO_TWO_TAG;
	yuanbao02.anchorPoint = ccp(0,0.5);
	
	////银币
	GameMoney *yinbi = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:0];
	[self addChild:yinbi z:3 tag:GXR_YINBI_TAG];
	yinbi.tag = GXR_YINBI_TAG;
	yinbi.anchorPoint = ccp(0,0.5);
	
    //左上角的模块位置
    if (iPhoneRuningOnGame()) {
        yuanbao01.position =ccp(GXR_MONEY_DW,size.height-_closeBnt.contentSize.height-yuanbao01.contentSize.height/2-GXR_MONEY_DH);
        moneyBack.position = ccp(0,size.height-upBg.contentSize.height);
        yuanbao02.position = ccp(GXR_MONEY_DW+5+yuanbao01.contentSize.width,size.height-_closeBnt.contentSize.height-yuanbao01.contentSize.height/2-GXR_MONEY_DH);
        yinbi.position = ccp(GXR_MONEY_DW,size.height-_closeBnt.contentSize.height-moneyBack.contentSize.height/2-yinbi.contentSize.height/2-GXR_MONEY_DH2);
        
    }else{
        yuanbao01.position = ccp(GXR_MONEY_DW,size.height-_closeBnt.contentSize.height-yuanbao01.contentSize.height/2-GXR_MONEY_DH);
        moneyBack.position = ccp(0,size.height-_closeBnt.contentSize.height);
        yuanbao02.position = ccp(GXR_MONEY_DW+5+yuanbao01.contentSize.width,size.height-_closeBnt.contentSize.height-yuanbao01.contentSize.height/2-GXR_MONEY_DH);
        yinbi.position = ccp(GXR_MONEY_DW,size.height-_closeBnt.contentSize.height-moneyBack.contentSize.height/2-yinbi.contentSize.height/2-GXR_MONEY_DH2);
    }
	
	////批量观星复选
	//NSArray *sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",@"批量观星",cFixedScale(14),ccc4(255,255,255,255),ccc4(255,255,255,255) );
    NSArray *sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",NSLocalizedString(@"guanxingroom_batch_fate",nil),cFixedScale(14),ccc4(255,255,255,255),ccc4(255,255,255,255) );
	CCMenuItemSprite *bt_bat_guanxing_spr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	CCMenuItemSprite *bt_bat_guanxing_spr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	CCMenuItem *btt_bat_guanxing_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:bt_bat_guanxing_spr01,bt_bat_guanxing_spr02, nil];
	[menu addChild:btt_bat_guanxing_toggle z:0 tag:BTT_GX_NO_HIDE_DEAL_TAG];
	btt_bat_guanxing_toggle.position = ccp(size.width/2+cFixedScale(320),bt_bat_guanxing_spr01.contentSize.height);
    if (iPhoneRuningOnGame()) {
        btt_bat_guanxing_toggle.scale = 1.3f;
    }
	////高级观星
	//fix chao
	//sprArr = getLabelSprites(@"images/ui/button/bt_background_2.png",@"images/ui/button/bt_background_2.png",@"高级观星",18,ccc4(252,86,131,255),ccc4(252,86,131,255) );
	sprArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_height_guanxing");
	//end
	CCMenuItem *bt_height_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] disabledSprite:[sprArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
	////
    int bt_w = 150;
    if (iPhoneRuningOnGame()) {
        bt_height_get.scale = 1.3f;
        bt_w = 150*1.3f;
    }
	//[self reSetPosArrayWithY:(btt_bat_guanxing_toggle.position.y+bt_height_get.contentSize.height/2) width:bt_height_get.contentSize.width ];
	[self reSetPosArrayWithY:btt_bat_guanxing_toggle.position.y+bt_height_get.contentSize.height/2 width:cFixedScale(bt_w)];
	//
	bt_height_get.position = g_gxr_posArray[0];
	[menu addChild:bt_height_get z:0 tag:BT_GXR_HEIGHT_GET_TAG];

    
	////批量高级观星
	//fix chao
	//sprArr = getLabelSprites(@"images/ui/button/bt_background_2.png",@"images/ui/button/bt_background_2.png",[NSString stringWithFormat:@"高级%d次",hitFateBatchNum],18,ccc4(252,86,131,255),ccc4(252,86,131,255) );
	sprArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_bat_height_guanxing");
	//end
	CCMenuItem *bt_bat_height_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] disabledSprite:[sprArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
    bt_bat_height_get.position = g_gxr_posArray[0];
	[menu addChild:bt_bat_height_get z:0 tag:BT_GXR_BAT_HEIGHT_GET_TAG];
    if (iPhoneRuningOnGame()) {
        bt_bat_height_get.scale = 1.3f;
    }
    
	////随机观星
	//fix chao
	//sprArr = getLabelSprites(@"images/ui/button/bt_background.png",@"images/ui/button/bt_background.png",@"随机观星",18,ccc4(65,197,186,255),ccc4(65,197,186,255) );
	sprArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_random_guanxing");
	//end
	CCMenuItem *bt_random_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] disabledSprite:[sprArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
	bt_random_get.position = g_gxr_posArray[2];
	[menu addChild:bt_random_get z:0 tag:BT_GXR_RANDOM_GET_TAG];
    if (iPhoneRuningOnGame()) {
        bt_random_get.scale = 1.3f;
    }
    
	////批量随机观星
	//fix chao
	//sprArr = getLabelSprites(@"images/ui/button/bt_background.png",@"images/ui/button/bt_background.png",[NSString stringWithFormat:@"随机%d次",hitFateBatchNum],18,ccc4(65,197,186,255),ccc4(65,197,186,255) );
	sprArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_bat_random_guanxing");
	//end
	CCMenuItem *bt_bat_random_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] disabledSprite:[sprArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
	bt_bat_random_get.position = g_gxr_posArray[2];
	[menu addChild:bt_bat_random_get z:0 tag:BT_GXR_BAT_RANDOM_GET_TAG];
    if (iPhoneRuningOnGame()) {
        bt_bat_random_get.scale = 1.3f;
    }
    
	////vip free 观星
	sprArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_random_guanxing");	
	CCMenuItem *bt_vip_free_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] disabledSprite:[sprArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
	bt_vip_free_get.position = bt_random_get.position;
	[menu addChild:bt_vip_free_get z:0 tag:BT_GXR_VIP_FREE_GET_TAG];
    if (iPhoneRuningOnGame()) {
        bt_vip_free_get.scale = 1.3f;
    }

	//fix chao
    ////全部收取
	NSArray *btnsArr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_gxr_all_get");
	/*
	label01 = [CCLabelTTF labelWithString:@"全部拾取" fontName: @"Verdana-Bold" fontSize:18];
	label02 = [CCLabelTTF labelWithString:@"全部拾取" fontName: @"Verdana-Bold" fontSize:18];
	spriteChangScale(label02,1.1);
	CCMenuItemSprite *bt_guanxing_get_all = [CCMenuItemSprite itemWithNormalSprite:label01 selectedSprite:label02 target:self selector:@selector(menuCallbackBack:)];
	 */
	CCMenuItemSprite *bt_guanxing_get_all = [CCMenuItemSprite itemWithNormalSprite:[btnsArr objectAtIndex:0] selectedSprite:[btnsArr objectAtIndex:1] disabledSprite:[btnsArr objectAtIndex:2] target:self selector:@selector(menuCallbackBack:)];
	//end
	[menu addChild:bt_guanxing_get_all z:0	tag:BT_GXR_GET_ALL_TAG];
	bt_guanxing_get_all.position = g_gxr_posArray[4];
    if (iPhoneRuningOnGame()) {
        bt_guanxing_get_all.scale = 1.3f;
    }
    
	////左按钮
	sprArr = getBtnSprite(@"images/ui/button/bt_GXRDir.png");
	CCMenuItemSprite *bt_left_dir = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	[menu addChild:bt_left_dir z:0 tag:BT_GXR_LEFT_DIR_TAG];
	bt_left_dir.position = ccp(size.width/2-(down_bg.contentSize.width/2-cFixedScale(52)),down_bg.contentSize.height-cFixedScale(35));
	
	////右按钮
	sprArr = getBtnSprite(@"images/ui/button/bt_GXRDir.png");	
	CCMenuItemSprite *bt_right_dir = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	[menu addChild:bt_right_dir z:0 tag:BT_GXR_RIGHT_DIR_TAG];
	bt_right_dir.position = ccp(size.width/2+(down_bg.contentSize.width/2-cFixedScale(52)),down_bg.contentSize.height-cFixedScale(35));
	bt_right_dir.scaleX = -1;
    
    float fontSize=18;
    if (iPhoneRuningOnGame()) {
        fontSize=16;
    }
	/////
//	CCLabelFX *randomInfo = [CCLabelFX labelWithString:@"今日剩余随机观星次数:"
//									 dimensions:CGSizeMake(0,0)
//									  alignment:kCCTextAlignmentCenter
//									   fontName:getCommonFontName(FONT_1)
//									   fontSize:fontSize
//								   shadowOffset:CGSizeMake(-1.5, -1.5)
//									 shadowBlur:2.0f];
    CCLabelFX *randomInfo = [CCLabelFX labelWithString:NSLocalizedString(@"guanxingroom_random_count",nil)
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentCenter
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:fontSize
                                          shadowOffset:CGSizeMake(-1.5, -1.5)
                                            shadowBlur:2.0f];
	[self addChild:randomInfo z:999 tag:GXR_RANDOM_INFO_TXT_TAG];
	randomInfo.anchorPoint = ccp(0,0.5);
    //
    int w_ = 730;
    int h_ = 660;
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
             w_ += 120;
        }else{
             w_ -= 50;
        }
        h_ -= 100;
    }
    randomInfo.position = ccp(cFixedScale(w_),cFixedScale(h_));
    //
//	CCLabelFX *hitInfo = [CCLabelFX labelWithString:@"今日剩余元宝观星次数:"
//								  dimensions:CGSizeMake(0,0)
//								   alignment:kCCTextAlignmentCenter
//									fontName:getCommonFontName(FONT_1)
//									fontSize:fontSize
//								shadowOffset:CGSizeMake(-1.5, -1.5)
//								  shadowBlur:2.0f];
    CCLabelFX *hitInfo = [CCLabelFX labelWithString:NSLocalizedString(@"guanxingroom_height_count",nil)
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentCenter
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:fontSize
                                       shadowOffset:CGSizeMake(-1.5, -1.5)
                                         shadowBlur:2.0f];
		[self addChild:hitInfo z:999 tag:GXR_HIT_INFO_TXT_TAG];
		hitInfo.anchorPoint = ccp(0,0.5);
		hitInfo.position = ccpAdd(randomInfo.position, ccp(0,-randomInfo.contentSize.height)) ;
	//
//	vipFreeInfo = [CCLabelFX labelWithString:@"今日剩余VIP免费观星次数:"
//										 dimensions:CGSizeMake(0,0)
//										  alignment:kCCTextAlignmentCenter
//										   fontName:getCommonFontName(FONT_1)
//										   fontSize:fontSize
//									   shadowOffset:CGSizeMake(-1.5, -1.5)
//										 shadowBlur:2.0f];
    vipFreeInfo = [CCLabelFX labelWithString:NSLocalizedString(@"guanxingroom_free_count",nil)
                                  dimensions:CGSizeMake(0,0)
                                   alignment:kCCTextAlignmentCenter
                                    fontName:getCommonFontName(FONT_1)
                                    fontSize:fontSize
                                shadowOffset:CGSizeMake(-1.5, -1.5)
                                  shadowBlur:2.0f];
	[self addChild:vipFreeInfo z:999 ];
	vipFreeInfo.anchorPoint = ccp(0,0.5);

    vipFreeInfo.position = ccpAdd(hitInfo.position, ccp(0,-hitInfo.contentSize.height));
    
	////
	vipFreeCountInfo = [CCLabelFX labelWithString:@""
								fontName:getCommonFontName(FONT_1)
								fontSize:18
							shadowOffset:CGSizeMake(-1.5, -1.5)
							  shadowBlur:2.0f
							 shadowColor:ccc4(0, 0, 0, 128)
							   fillColor:ccc4(254,237,131, 255)];
	[self addChild:vipFreeCountInfo z:999 ];
	vipFreeCountInfo.anchorPoint = ccp(0,0.5);
 
    vipFreeCountInfo.position = ccpAdd(vipFreeInfo.position, ccp(vipFreeInfo.contentSize.width,0));
    
	vipFreeCountInfo.color = ccYELLOW;

	////角色
	GXRRole *roleSpr = [GXRRole node];
    roleSpr.anchorPoint = ccp(0.5,0);
	[self addChild:roleSpr z:0	tag:GXR_ROLE_TAG];
	[self updateRoleID];
   
	////卡片层
    
	GXRCardLayer *cardLayer = [GXRCardLayer node];
	[self addChild:cardLayer z:4 tag:GXR_CARDLAYER_TAG];
    if (iPhoneRuningOnGame()) {
        //调物品坐标
        cardLayer.position =(ccp(0,0));
    }else{
        cardLayer.position = ccp(0,0);
    }
    cardLayer.target = self;
	
	////卡片
	GXRCard *card= [GXRCard node];
	[self addChild:card z:5 tag:GXR_CARD_TAG];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            card.position =ccp(s_gxr_card_pos_x,s_gxr_card_pos_y);
        }else{
            card.position =(ccp(s_gxr_card_pos_x,s_gxr_card_pos_y));
        }
    }else{
     card.position = ccp(s_gxr_card_pos_x,s_gxr_card_pos_y);
    }
	card.visible = NO;
	////
	[self updateButtonInfo];
	////
	state = GXRS_Stop;
	[self schedule:@selector(update:) interval:1/60.0f];
	////加入待收物品
	[self reload];

	////
	self.touchEnabled = YES;
	self.touchPriority = kCCMenuHandlerPriority;
	
	isMenuTouch = NO;
	[self enterHitFate];
	////--------
	//[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_GuangXingRoom];
	//[[Intro share] runIntroTager:bt_random_get step:29];
	[self scheduleOnce:@selector(runIntro) delay:0.5f];
}
-(void)runIntro{
	CCNode *bt_random_get = [menu getChildByTag:BT_GXR_RANDOM_GET_TAG];
	[[Intro share] runIntroTager:bt_random_get step:INTRO_GuangXingRoom_Step_1];
}
-(void)onExit{
	if (s_fateDict) {
		[s_fateDict release];
		s_fateDict = nil;
	}
	[backFateArray release];
	backFateArray = nil;
    [GameConnection freeRequest:self];
	[super onExit];
}

-(CCSprite*)getBackground:(NSString *)path
{
	CCSprite *sprite = [super getBackground:path];
	CGSize s1 = sprite.contentSize;
	CGSize s2 = [CCDirector sharedDirector].winSize;
	if (s1.width > s2.width || s1.height > s2.height) {
		float startX = (s1.width-s2.width)/2;
		float startY = (s1.height-s2.height)/2;
		return [CCSprite spriteWithFile:path rect:CGRectMake(startX, startY, s2.width, s2.height)];
	} else {
		return sprite;
	}
}

-(CGPoint)getCaptionPosition{
	CGPoint pt = [super getCaptionPosition];
	if (!iPhoneRuningOnGame()) {
		return ccpAdd(pt, ccp(0, -45));
	}
	return pt;
}

-(CGPoint)getClosePosition
{
	CGPoint pt = [super getClosePosition];
	if (iPhoneRuningOnGame()) {
		return ccpAdd(pt, ccp(ccpIphone4X(0), 0));
	} else {
		return ccpAdd(pt, ccp(12, 14));
	}
	return pt;
}

-(void)closeWindow
{
	[super closeWindow];
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXingRoom_Step_2];
}

-(float)getRoleOffset{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	float offset = 0;
	if (dict) {
		NSNumber *rid = [dict objectForKey:@"rid"];
		// 角色
		NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:[rid intValue]];		
		if (roleInfo) {
			offset = [[roleInfo objectForKey:@"offset"] intValue];
		}else{
			CCLOG(@"rid is error");
		}
	}else{
		CCLOG(@"get player info error");
	}
	return cFixedScale(offset);
}

-(void)updateRoleID{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	
	if (dict) {
		NSNumber *rid = [dict objectForKey:@"rid"];
		if(rid){
			GXRRole *roleSpr = (GXRRole *)[self getChildByTag:GXR_ROLE_TAG ];
			if (roleSpr) {
				[roleSpr setRoleWithPID:[rid intValue]];
				//roleSpr.position = ccp(735,155-[self getRoleOffset]);
                int off_x = 0;
                int off_y = 0;
                if (iPhoneRuningOnGame()) {
                    if (isIphone5()) {
                        off_x += 40;
                        off_y += 60;
                    }else{
                        off_x -= 40;
                        off_y += 60;
                    }
                }else{
                    off_y += 45;
                }
                roleSpr.position = ccp(cFixedScale(735+off_x),cFixedScale(155+off_y)-[self getRoleOffset]);
			}else{
				CCLOG(@"role is nil");
			}			
		}else{
			CCLOG(@"rid is nil");
		}		
	}else{
		CCLOG(@"get player info error");
	}
}
-(void)updateVipData{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	NSNumber *vip= [dict objectForKey:@"vip"];
	
	NSDictionary *s_dict = [[GameDB shared] getGlobalConfig];
	//TODO get gameDB setting;
	int hitFateCoin2Vip = [[s_dict objectForKey:@"hitFateCoin2Vip"] intValue];
	int hitFateBatchVip = [[s_dict objectForKey:@"hitFateBatchVip"] intValue];
    /*
    if ([vip intValue] >0) {
		vipFreeInfo.visible = YES;
		vipFreeCountInfo.visible = YES;
	}else{
		vipFreeInfo.visible = NO;
		vipFreeCountInfo.visible = NO;
	}
     */
	if (yuanBaoFreeCount >0) {
		vipFreeInfo.visible = YES;
		vipFreeCountInfo.visible = YES;
	}else{
		vipFreeInfo.visible = NO;
		vipFreeCountInfo.visible = NO;
	}
	if ([vip intValue] >= hitFateCoin2Vip) {
		[self setIsOpenHeight:YES];
	}else{
		[self setIsOpenHeight:NO];
	}
	if ([vip intValue] >= hitFateBatchVip) {
		[self setIsOpenBat:YES];
	}else{
		[self setIsOpenBat:NO];
	}
	[self setButtoPos];
}
-(void)updateMoneyData{
	//
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	NSNumber *coin1 = [dict objectForKey:@"coin1"];
	NSNumber *coin2 = [dict objectForKey:@"coin2"];
	NSNumber *coin3 = [dict objectForKey:@"coin3"];
	[self updateMoneyWithYuanBao01:[coin2 intValue] yuanBao02:[coin3 intValue] yinBi:[coin1 intValue]];
}
-(void)setBatGetFateWithHeightValue:(NSInteger)hValue randomValue:(NSInteger)rValue{
	//TODO
	NSDictionary *dict = [[GameDB shared] getGlobalConfig];	
	//int hitFateCoin1Max= [[dict objectForKey:@"hitFateCoin1Max"] intValue];
	//int hitFateCoin2Max =[[dict objectForKey:@"hitFateCoin2Max"] intValue];
	int hitFateBatchNum = [[dict objectForKey:@"hitFateBatchNum"] intValue];
	//hValue = hitFateCoin2Max - hValue;
	//rValue = hitFateCoin1Max - rValue;
	
	hValue = hitFateBatchNum;
	rValue = hitFateBatchNum;

	if (hValue<hitFateBatchNum && hValue>=0) {
		[menu removeChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG cleanup:YES];
		//TODO
		CCMenuItem *bt_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_HEIGHT_GET_TAG];		
		////批量高级观星
		//fix chao
		//NSArray *sprArr = getLabelSprites(@"images/ui/button/bt_background_2.png",@"images/ui/button/bt_background_2.png",[NSString stringWithFormat:@"高级%d次",hValue],18,ccc4(252,86,131,255),ccc4(252,86,131,255) );
		NSArray *sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_bat_height_guanxing");
		//end
		CCMenuItem *bt_bat_height_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
		bt_bat_height_get.position = bt_height_get.position;
		[menu addChild:bt_bat_height_get z:0 tag:BT_GXR_BAT_HEIGHT_GET_TAG];
	}
	if (rValue<hitFateBatchNum && rValue>=0) {
		[menu removeChildByTag:BT_GXR_BAT_RANDOM_GET_TAG cleanup:YES];		
		CCMenuItem *bt_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_RANDOM_GET_TAG];
		////批量随机观星
		//fix chao
		//NSArray *sprArr = getLabelSprites(@"images/ui/button/bt_background.png",@"images/ui/button/bt_background.png",[NSString stringWithFormat:@"随机%d次",rValue],18,ccc4(65,197,186,255),ccc4(65,197,186,255) );
		NSArray *sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_bat_random_guanxing");
		//end
		CCMenuItem *bt_bat_random_get = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
		bt_bat_random_get.position = bt_random_get.position;
		[menu addChild:bt_bat_random_get z:0 tag:BT_GXR_BAT_RANDOM_GET_TAG];
	}
	//[self updateVipData];
	//[self updateButtonInfo];
}
-(void)setIsOpenHeight:(BOOL)_isOpenHeight{
	isOpenHeight = _isOpenHeight;
	CCMenuItem *heightGet = (CCMenuItem *)[menu getChildByTag:BT_GXR_HEIGHT_GET_TAG];
	CCMenuItem *heightBatGet = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG];
	[heightGet setVisible:isOpenHeight];
	[heightBatGet setVisible:isOpenHeight];
}
-(void)setIsOpenBat:(BOOL)_isOpenBat{
	isOpenBat = _isOpenBat;
	CCMenuItem *heightBatGet = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG];
	CCMenuItem *randomBatGet = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_RANDOM_GET_TAG];
	CCMenuItem *btt_bat_guanxing_toggle = (CCMenuItem *)[menu getChildByTag:BTT_GX_NO_HIDE_DEAL_TAG];
	[heightBatGet setVisible:isOpenBat];
	[randomBatGet setVisible:isOpenBat];		
	[btt_bat_guanxing_toggle setVisible:isOpenBat];
}
-(void)setIsOpenDirButton:(BOOL)_isOpen{
	CCMenuItem *bt_left_dir = (CCMenuItem *)[menu getChildByTag:BT_GXR_LEFT_DIR_TAG];
	CCMenuItem *bt_right_dir = (CCMenuItem *)[menu getChildByTag:BT_GXR_RIGHT_DIR_TAG];
	[bt_left_dir setVisible:_isOpen];
	[bt_right_dir setVisible:_isOpen];
}
-(void)enterHitFate{	
	[GameConnection request:@"enterHitFate" data:[NSDictionary dictionary] target:self call:@selector(enterHitFateBackCall:)];
}
-(void)enterHitFateBackCall:(id)sender{
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if ([data objectForKey:@"num1"]) {
			yinBiCount = [[data objectForKey:@"num1"] intValue];
		}
		if ([data objectForKey:@"num2"]) {
			yuanBaoCount = [[data objectForKey:@"num2"] intValue];
		}
		if ([data objectForKey:@"num3"]) {
			yuanBaoFreeCount = [[data objectForKey:@"num3"] intValue];			
		}		
		if([data objectForKey:@"delWids"]){
			[[GameConfigure shared] updatePackage:data];
		}
	}else{
		CCLOG(@"enter HitFate error");
		//CCLOG(getResponseMessage(sender));
#ifdef GAME_DEBUGGER
		CGPoint pos = ccp(400, self.contentSize.height/2+100);
		CCSprite* spr = [CCLabelTTF labelWithString:@"enter HitFate error" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
		[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
#endif
	}
	//TODO
	////加入待收物品
	[self reload];
    [self updateButtonInfo];
	//[self updateButtonInfo];
	//[self setBatGetFateWithHeightValue:yuanBaoCount randomValue:yinBiCount];
}
-(void)setButtoPos{
	CCMenuItem *bt_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_HEIGHT_GET_TAG];
	CCMenuItem *bt_bat_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG];
	CCMenuItem *bt_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_RANDOM_GET_TAG];
	CCMenuItem *bt_bat_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_RANDOM_GET_TAG];
	CCMenuItem *bt_vip_free_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_VIP_FREE_GET_TAG];
	
	CCMenuItem *bt_all_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_GET_ALL_TAG];
	
	if (bt_all_get) {
		if ( ([bt_height_get visible]||[bt_bat_height_get visible]) && ([bt_random_get visible]||[bt_bat_random_get visible])) {			
			[bt_height_get setPosition:g_gxr_posArray[0]];
			[bt_bat_height_get setPosition:g_gxr_posArray[0]];			
			[bt_random_get setPosition:g_gxr_posArray[2]];
			[bt_bat_random_get setPosition: g_gxr_posArray[2]];
			[bt_all_get setPosition:g_gxr_posArray[4]];
		}else if(([bt_height_get visible]||[bt_bat_height_get visible]) && [bt_vip_free_get visible]){
			[bt_height_get setPosition:g_gxr_posArray[0]];
			[bt_bat_height_get setPosition:g_gxr_posArray[0]];
			[bt_random_get setPosition:g_gxr_posArray[2]];
			[bt_bat_random_get setPosition: g_gxr_posArray[2]];
			[bt_all_get setPosition:g_gxr_posArray[4]];
		}else{
			[bt_height_get setPosition:g_gxr_posArray[1]];
			[bt_all_get setPosition:g_gxr_posArray[3]];
			[bt_bat_height_get setPosition:[bt_height_get position]];
			[bt_random_get setPosition:[bt_height_get position]];
			[bt_bat_random_get setPosition:[bt_height_get position]];
		}
	}else{
		if ( ([bt_height_get visible]||[bt_bat_height_get visible]) && ([bt_random_get visible]||[bt_bat_random_get visible])) {
			[bt_height_get setPosition:g_gxr_posArray[0]];
			[bt_bat_height_get setPosition:g_gxr_posArray[0]];
			[bt_random_get setPosition:g_gxr_posArray[2]];
			[bt_bat_random_get setPosition: g_gxr_posArray[2]];
			[bt_all_get setPosition:g_gxr_posArray[4]];
		}else if(([bt_height_get visible]||[bt_bat_height_get visible]) && [bt_vip_free_get visible]){
			[bt_height_get setPosition:g_gxr_posArray[0]];
			[bt_bat_height_get setPosition:g_gxr_posArray[0]];
			[bt_random_get setPosition:g_gxr_posArray[2]];
			[bt_bat_random_get setPosition: g_gxr_posArray[2]];
			[bt_all_get setPosition:g_gxr_posArray[4]];
		}else{
			[bt_height_get setPosition:g_gxr_posArray[1]];
			[bt_all_get setPosition:g_gxr_posArray[3]];
			[bt_bat_height_get setPosition:[bt_height_get position]];
			[bt_random_get setPosition:[bt_height_get position]];
			[bt_bat_random_get setPosition:[bt_height_get position]];
		}
	}

}
-(void)updateButtonInfo{
	
	//[self setBatGetFateWithHeightValue:yuanBaoCount randomValue:yinBiCount];
	[self updateVipData];
	NSInteger index;
	CCMenuItemToggle *btt_bat_guanxing_toggle = (CCMenuItemToggle *)[menu getChildByTag:BTT_GX_NO_HIDE_DEAL_TAG];
	CCMenuItem *bt_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_HEIGHT_GET_TAG];
	CCMenuItem *bt_bat_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG];
	CCMenuItem *bt_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_RANDOM_GET_TAG];
	CCMenuItem *bt_bat_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_RANDOM_GET_TAG];
	CCMenuItem *bt_vip_free_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_VIP_FREE_GET_TAG];
	
	if([btt_bat_guanxing_toggle visible])
	{
		index = [btt_bat_guanxing_toggle selectedIndex];		
		
		if (YES == isOpenHeight) {
			if (index == 1) {
				bt_bat_height_get.visible = YES;
				bt_height_get.visible = NO;
			}else{
				bt_bat_height_get.visible = NO;
				bt_height_get.visible = YES;
			}
		}else{
			bt_bat_height_get.visible = NO;
			bt_height_get.visible = NO;
		}

		if (index == 1) {
			bt_random_get.visible = NO;
			bt_vip_free_get.visible = NO;
			bt_bat_random_get.visible = YES;
		}else{
			//bt_random_get.visible = YES;
			bt_bat_random_get.visible = NO;
			//NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
			//NSNumber *vip= [dict objectForKey:@"vip"];
			if (/*vipFreeCountInfo.visible &&*/ yuanBaoFreeCount>0 /*&& [vip intValue]>0*/) {
				bt_vip_free_get.visible = YES;
				bt_random_get.visible = NO;
			}else{
				bt_vip_free_get.visible = NO;
				bt_random_get.visible = YES;
			}
		}
	}else{
		//
		//NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
		//NSNumber *vip= [dict objectForKey:@"vip"];
		if (yuanBaoFreeCount>0 /*&& [vip intValue]>0*/) {
			bt_random_get.visible = NO;
			bt_vip_free_get.visible = YES;
		}else{
			bt_random_get.visible = YES;
			bt_vip_free_get.visible = NO;
		}
	}
	
	[self setButtoPos];
	////
	[self updateForInfo];
}
-(void)updateMoneyWithYuanBao01:(NSInteger)value01 yuanBao02:(NSInteger)value02 yinBi:(NSInteger)value03{
	GameMoney* yuanBao01 = (GameMoney* )[self getChildByTag:GXR_YUANBAO_ONE_TAG];
	[yuanBao01 setMoneyValue:value01];
	GameMoney* yuanBao02 = (GameMoney* )[self getChildByTag:GXR_YUANBAO_TWO_TAG];
	[yuanBao02 setMoneyValue:value02];
	yuanBao02.position = ccp(yuanBao01.position.x+yuanBao01.contentSize.width,yuanBao02.position.y);
	GameMoney* yinBi = (GameMoney* )[self getChildByTag:GXR_YINBI_TAG];
	[yinBi setMoneyValue:value03];
}

+(void)create{
	[GameLoading showMessage:@"" target:[GuanXingRoom class] call:@selector(showViwer) loading:YES];
}

+(void)showViwer{
	GuanXingRoom * guanxingroom = [GuanXingRoom node];
	guanxingroom.windowType = PANEL_FATEROOM;
	[[Window shared] addChild:guanxingroom z:10 tag:PANEL_FATEROOM];
	[GameLoading hide];
}

-(NSInteger)getTypeWithString:(NSString*)str{
	int re = -1;
	if ([str isEqualToString:@"i"]) {
		re = GXRWIT_i;
	}else if ([str isEqualToString:@"e"]) {
		re = GXRWIT_e;
	}else if ([str isEqualToString:@"f"]) {
		re = GXRWIT_f;
	}else if ([str isEqualToString:@"c"]) {
		re = GXRWIT_c;
	}else if ([str isEqualToString:@"m"]) {
		re = GXRWIT_m;
	}
	return re;
}
-(NSArray*)getItemsDictArrayWithString:(NSString*)_str{
	
	if (!_str) {
		return nil;
	}	
	NSData *data = [_str dataUsingEncoding:NSUTF8StringEncoding];
	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];	
	NSArray *array = [deserializer deserializeAsArray:data error:nil];

	return array;
}
-(NSArray*)getItemDictArrayWithArray:(NSArray*)array{
	if (!array) {
		CCLOG(@"array is nil");
		return nil;
	}
	NSMutableArray *arr= [NSMutableArray array];
	for (NSDictionary *dict in array) {
		NSMutableDictionary *t_dict = [NSMutableDictionary dictionary];
		NSArray *itemsDictArr = [self getItemsDictArrayWithString:[dict objectForKey:@"items"]];
		
		for (NSDictionary *itemsDict in itemsDictArr) {
			[t_dict setObject:[NSNumber numberWithInt:[self getTypeWithString:[itemsDict objectForKey:@"t"]]] forKey:@"type"];//GXRWaitItemType
			[t_dict setObject:[dict objectForKey:@"id"]  forKey:@"id"];
			[t_dict setObject:[itemsDict objectForKey:@"i"] forKey:@"bid"];
			[t_dict setObject:[itemsDict objectForKey:@"c"] forKey:@"count"];
			[t_dict setObject:[itemsDict objectForKey:@"tr"] forKey:@"isTrade"];
			[arr addObject:t_dict];
		}
	}
	return arr;
}
-(void)reload{
	//TODO 
	GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
	if (cardLayer) {
		[cardLayer removeAllItem];
		[cardLayer updateItemWithDictArr:[self getItemDictArrayWithArray:[[GameConfigure shared] getPlayerWaitItemListByType:PlayerWaitItemType_1]]];
		if ([cardLayer getCardsCount]>GXCL_SHOW_LEN) {
			[self setIsOpenDirButton:YES];
		}else{
			[self setIsOpenDirButton:NO];
		}
	}
	////
	//[self updateVipData];
	[self updateButtonInfo];
	[self updateMoneyData];
	
}
//fix chao
-(void)showGuanXingBlackCall{
	if (backFateArray) {
		//fix chao
		NSDictionary *t_dict = [backFateArray objectAtIndex:([backFateArray count]-guanXingCount)];
		GXRCard *card = (GXRCard *)[self getChildByTag:GXR_CARD_TAG];
		[card changeItemWithDict:t_dict];
		[card setNameVisible:NO];
		GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
        card.position = ccp(s_gxr_card_pos_x,s_gxr_card_pos_y);
		card.visible = YES;
        if ([cardLayer getCardsCount]<=0||YES) {
            [card runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.5 position:ccp(s_gxcl_card_startpos_x,s_gxcl_card_startpos_y)] rate:0.5 ] ];
        }else{
            [card runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.5 position:ccp(GXCL_CARD_MOVETO_X,GXCL_CARD_MOVETO_Y)] rate:0.5 ] ];
        }
		//end
		//[card runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.5 position:ccp(GXCL_CARD_MOVETO_X,GXCL_CARD_MOVETO_Y)] rate:0.5 ] ];
		state = GXRS_ShowFate;
	}else{
		state = GXRS_Stop;		
	}
	isFinished = YES;
}
//end

//fix chao
-(ItemQuality)getMaxQualityWithArray:(NSArray*)array{
	ItemQuality max = IQ_WHITE;
	if (array) {
		for (NSDictionary *t_dict in array) {
			if (GXRWIT_f == [[t_dict objectForKey:@"type"] intValue]) {
				NSDictionary *fate_dict = [[GameDB shared] getFateInfo:[[t_dict objectForKey:@"bid"] intValue]];
				if (fate_dict && max < [[fate_dict objectForKey:@"quality"] intValue]){
					max = [[fate_dict objectForKey:@"quality"] intValue];
				}
			}else if(max<IQ_GREEN){
				max = IQ_GREEN;
			}
		}
	}
	return max;
}
//end

-(void)updateGuanXing:(ccTime)delta{
	//TODO
	//CCNode *re = [self getChildByTag:555];
	//播放动画结束
	//fix chao	
	if (isFinished) {
		//fix chao
		NSString *path=nil;
		if(backFateArray){
			if (isDisplay == NO) {				
				int quality = [self getMaxQualityWithArray:backFateArray];
				if (IQ_GREEN == quality){
					path = @"images/ui/panel/uiguanxing-g/";
				}else if (IQ_BLUE == quality){
					path = @"images/ui/panel/uiguanxing-b/";
				}else{
					path = @"images/ui/panel/uiguanxing-r/";
				}
				id call = [CCCallFuncN actionWithTarget:self selector:@selector(showGuanXingBlackCall)];
                CGPoint pos=ccp(s_gxr_card_pos_x, s_gxr_card_pos_y);
//                if (iPhoneRuningOnGame()) {
//                    pos.x-=20;
//                    pos.y-=20;
//                    pos=ccpIphone(pos);
//                }
				[ClickAnimation showInLayer:self tag:555 call:call point:pos path:path loop:NO];
				isFinished = NO;
				isDisplay = YES;
			}else{
				[self showGuanXingBlackCall];
			}
		}else{
			state = GXRS_Stop;
			CCLOG(@"backFateArray is null");
		}
		//end		

		//end
		CCLOG(@"state = GXRS_GuanXing");
	}

}
-(void)setBackFateArray:(NSArray*)arr{
	if (arr!=backFateArray) {
		[backFateArray release];
		backFateArray = arr;
		[arr retain];
	}
}
-(void)updateShowFate:(ccTime)delta{
	//TODO backFateFRID
	GXRCard *card = (GXRCard *)[self getChildByTag:GXR_CARD_TAG];
	GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
	CGPoint pos;
    int abs_x = (s_gxcl_card_startpos_x-card.position.x);
    int abs_y = (s_gxcl_card_startpos_y-card.position.y);
	pos.x = GXR_CARD_W - (ABS(abs_x)+ABS(abs_y));
	if (pos.x<0) {
		pos.x = 0;
	}
	pos.y = 0;
	//moveCardByPos
	[cardLayer moveCardByPos:pos];
	if (([cardLayer getCardsCount]<=0||YES) && card.position.x == s_gxcl_card_startpos_x && card.position.y == s_gxcl_card_startpos_y ) {
		[cardLayer addItem:card];		
		////
		card.visible = NO;
		if (guanXingCount>1) {
			guanXingCount--;
			state = GXRS_GuanXing;
		}else{
			state = GXRS_Stop;			
			//[self setGetAllButtonVisible:YES];
			[self setGetAllButtonDisabled:NO];
			isDisplay = NO;
		}
		if ([cardLayer getCardsCount]>GXCL_SHOW_LEN) {
			[self setIsOpenDirButton:YES];
		}else{
			[self setIsOpenDirButton:NO];
		}
	}else if ( card.position.x == GXCL_CARD_MOVETO_X && card.position.y == GXCL_CARD_MOVETO_Y ) {
		if (cardLayer) {
			[cardLayer addItem:card];
		}
		////
		card.visible = NO;
		if (guanXingCount>1) {
			guanXingCount--;
			state = GXRS_GuanXing;
		}else{
			state = GXRS_Stop;
			//[self setGetAllButtonVisible:YES];
			[self setGetAllButtonDisabled:NO];
			isDisplay = NO;
		}
		if ([cardLayer getCardsCount]>GXCL_SHOW_LEN) {
			[self setIsOpenDirButton:YES];
		}else{
			[self setIsOpenDirButton:NO];
		}
	}
}
-(void)updateGuanXingSend:(ccTime)delta{
	//TODO
	if (YES) {
		state = GXRS_GuanXing;
	}
}
-(void)updateGetFate:(ccTime)delta{
	//TODO
	state = GXRS_Stop;
}

-(void)update:(ccTime)delta{
	switch (state) {
		case GXRS_Stop:{
		}
			break;
		case GXRS_GuanXingSend:{
			[self updateGuanXingSend:delta];
		}
			break;
		case GXRS_GuanXing:{
			[self updateGuanXing:delta];
		}
			break;
		case GXRS_ShowFate:{
			[self updateShowFate:delta];
		}
			break;
		case GXRS_GetFate:{
			[self updateGetFate:delta];
		}
			break;
		default:
			break;
	}
}
-(void)buttonGetAllTapped{
	if (state == GXRS_Stop){
		////
		GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
		if ([self checkPackageFullWithAdd:[cardLayer getFateCount]]) {
			[self showMessageWithType:GXRMT_packageFull];
			return;
		}
		NSArray *arr = [cardLayer getShowCards];
		if ([arr count]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setObject:[NSNumber numberWithInt:PlayerWaitItemType_1] forKey:@"type"];		
			//fix chao
			CCMenuItem *item_obj = (CCMenuItem *)[menu getChildByTag:BT_GXR_GET_ALL_TAG];
			[item_obj setIsEnabled:NO];
			//end
            isSend = YES;
			[GameConnection request:@"waitFetch" data:dict target:self call:@selector(batAllWaitFetchBackCall:)];
		}
		
	}
}
-(void)removeCard:(NSArray*)cardArray{
	int c = 0;
	for (GXRCard *_card in cardArray) {
		if ([_card type]==GXRWIT_f) {
			if ([_card count]>1) {
				c += [_card count];
			}else{
				c++;
			}			
		}
	}
	if ([self checkPackageFullWithAdd:c]) {
		[self showMessageWithType:GXRMT_packageFull];
		return;
	}
	waitFetchID=0;
	for (GXRCard *card in cardArray) {
		if (waitFetchID==0) {
			waitFetchID = [card getItemID];
		}else if( waitFetchID != [card getItemID] ){
			CCLOG(@"wait fetch id error");
			state = GXRS_Stop;
			return;
		}		
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:PlayerWaitItemType_1] forKey:@"type"];
	[dict setObject:[NSNumber numberWithInt:waitFetchID] forKey:@"id"];//
	[GameConnection request:@"waitFetch" data:dict target:self call:@selector(waitFetchBackCall:)];
}
-(void)removeItemCall:(id) sender{
	[self removeChild:sender cleanup:YES];
}
-(void)setGetAllButtonDisabled:(BOOL)isDisabled{
	CCMenuItemSprite *bt_guanxing_get_all = (CCMenuItemSprite *)[menu getChildByTag:BT_GXR_GET_ALL_TAG];
	[bt_guanxing_get_all setIsEnabled:(!isDisabled)];
}
-(void)setGetAllButtonVisible:(BOOL)isShow{
	CCMenuItemSprite *bt_guanxing_get_all = (CCMenuItemSprite *)[menu getChildByTag:BT_GXR_GET_ALL_TAG];
	[bt_guanxing_get_all setVisible:isShow];	
}
-(BOOL)checkYiBiUpWithAdd:(NSInteger)addCount{	
	if ((yinBiCount-addCount)<0) {
		return YES;
	};
	return NO;
}
-(BOOL)checkYuanBaoUpWithAdd:(NSInteger)addCount{	
	if ((yuanBaoCount-addCount)<0) {
		return YES;
	};
	return NO;
}
-(BOOL)checkPackageFullWithAdd:(NSInteger)addCount{
	//TODO get max capacity
	int max = [[GameConfigure shared] getPlayerPackageMaxCapacity];
	if (max < (addCount+[[GameConfigure shared] getPlayerPackageItemCount]) ) {
		return YES;
	};
	return NO;
}
-(void)sendButtonBatHeight{
	state = GXRS_GuanXingSend;
	[self setBackFateArray:nil];
	backFateID = 0;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:2] forKey:@"type"];// 1=银币猎命 2＝元宝猎命
	[dict setObject:[NSNumber numberWithInt:1] forKey:@"isBatch"];//
	NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
	[data_dict setObject:[NSNumber numberWithInt:2] forKey:@"type"];
	//fix chao
	[data_dict setObject:[NSNumber numberWithInt:10] forKey:@"count"];
	//end
    isSend = YES;
	[GameConnection request:@"hitFate" data:dict target:self call:@selector(randomGetBackCall::) arg:data_dict];
    
}
-(void)buttonBatHeightGetTapped{
	//TODO
	if (state == GXRS_Stop) {
		//NSDictionary *dict = [[GameDB shared] getGlobalConfig];
		//int hitFateCoin1Max= [[dict objectForKey:@"hitFateCoin1Max"] intValue];
		//int hitFateCoin2Max =[[dict objectForKey:@"hitFateCoin2Max"] intValue];
		
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin2Max - yuanBaoCount +1];
		NSDictionary *player_dict =[[GameConfigure shared] getPlayerInfo];
		NSDictionary *gl_dict = [[GameDB shared] getGlobalConfig];
		int num = [[gl_dict objectForKey:@"hitFateBatchNum"]intValue];
		if([self checkYuanBaoUpWithAdd:10]){
			[self showMessageWithType:GXRMT_fateYuanBaoUp];
		}else if (
			t_dict &&
			player_dict &&
			gl_dict &&
			([[t_dict objectForKey:@"coin2"] intValue]*num+[[t_dict objectForKey:@"coin3"] intValue]*num)<=([[player_dict objectForKey:@"coin2"] intValue] +[[player_dict objectForKey:@"coin3"] intValue])) {
			////
			BOOL isRecordYuanBaoGuanxing = [[[GameConfigure shared] getPlayerRecord:YUANBAO_GUANXING] boolValue];
			if (isRecordYuanBaoGuanxing) {
				[self sendButtonBatHeight];
			}else{
				//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝进行观星",([[t_dict objectForKey:@"coin2"] intValue]*num+[[t_dict objectForKey:@"coin3"] intValue]*num)];
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"guanxingroom_spend",nil),([[t_dict objectForKey:@"coin2"] intValue]*num+[[t_dict objectForKey:@"coin3"] intValue]*num)];
				[[AlertManager shared] showMessageWithSettingFormFather:message target:self confirm:@selector(sendButtonBatHeight) key:YUANBAO_GUANXING father:self];
			}
		}else{
			[self showMessageWithType:GXRMT_hitBat];
		}
	}
}
-(void)sendButtonHeight{
	state = GXRS_GuanXingSend;
	[self setBackFateArray:nil];
	backFateID = 0;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:2] forKey:@"type"];// 1=银币猎命 2＝元宝猎命
	[dict setObject:[NSNumber numberWithInt:0] forKey:@"isBatch"];//
	NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
	[data_dict setObject:[NSNumber numberWithInt:2] forKey:@"type"];
	//fix chao
	[data_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
	//end
    isSend = YES;
	[GameConnection request:@"hitFate" data:dict target:self call:@selector(randomGetBackCall::) arg:data_dict];
    
}
-(void)buttonHeightGetTapped{
	//TODO
	if (state == GXRS_Stop) {		
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin2Max-yuanBaoCount+1];
		NSDictionary *player_dict =[[GameConfigure shared] getPlayerInfo];		
		if([self checkYuanBaoUpWithAdd:1]){
			[self showMessageWithType:GXRMT_fateYuanBaoUp];
		}else if ( t_dict && player_dict && ([[t_dict objectForKey:@"coin2"] intValue]+[[t_dict objectForKey:@"coin3"] intValue])<=([[player_dict objectForKey:@"coin2"] intValue]+[[player_dict objectForKey:@"coin3"] intValue])) {
			////
			BOOL isRecordYuanBaoGuanxing = [[[GameConfigure shared] getPlayerRecord:YUANBAO_GUANXING] boolValue];
			if (isRecordYuanBaoGuanxing) {
				[self sendButtonHeight];
			}else{
				//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝进行观星",[[t_dict objectForKey:@"coin2"] intValue]+[[t_dict objectForKey:@"coin3"] intValue]];
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"guanxingroom_spend",nil),[[t_dict objectForKey:@"coin2"] intValue]+[[t_dict objectForKey:@"coin3"] intValue]];
				[[AlertManager shared] showMessageWithSettingFormFather:message target:self confirm:@selector(sendButtonHeight) key:YUANBAO_GUANXING father:self];
			}
		}else{
			[self showMessageWithType:GXRMT_hit];
		}
	}
}
-(void)buttonBatRandomGetTapped{
	//TODO
	if (state == GXRS_Stop) {
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin1Max-yinBiCount+1];
		NSDictionary *player_dict =[[GameConfigure shared] getPlayerInfo];
		NSDictionary *gl_dict = [[GameDB shared] getGlobalConfig];
		if([self checkYiBiUpWithAdd:10]){
			[self showMessageWithType:GXRMT_fateYiBiUp];
		}else if ( t_dict && player_dict && gl_dict && [[t_dict objectForKey:@"coin1"] intValue]*[[gl_dict objectForKey:@"hitFateBatchNum"] intValue]<=[[player_dict objectForKey:@"coin1"] intValue]) {
			////
			state = GXRS_GuanXingSend;
			[self setBackFateArray:nil];
			backFateID = 0;
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setObject:[NSNumber numberWithInt:1] forKey:@"type"];// 1=银币猎命 2＝元宝猎命
			[dict setObject:[NSNumber numberWithInt:1] forKey:@"isBatch"];//
			NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
			[data_dict setObject:[NSNumber numberWithInt:1] forKey:@"type"];
			//fix chao
			[data_dict setObject:[NSNumber numberWithInt:10] forKey:@"count"];
			//end
            isSend = YES;
			[GameConnection request:@"hitFate" data:dict target:self call:@selector(randomGetBackCall::) arg:data_dict];
		}else{
			[self showMessageWithType:GXRMT_randomBat];
		}
	}
}
-(void)buttonVipFreeGetTapped{
	//TODO
	//GXRS_GuanXingSend;
	if (state == GXRS_Stop) {
		state = GXRS_GuanXingSend;
		[self setBackFateArray:nil];
		backFateID = 0;
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:3] forKey:@"type"];// 1=银币猎命 2＝元宝猎命 3 = vip free
		[dict setObject:[NSNumber numberWithInt:0] forKey:@"isBatch"];//
		NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
		[data_dict setObject:[NSNumber numberWithInt:3] forKey:@"type"];
		//fix chao
		[data_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
		//end
        isSend = YES;
		[GameConnection request:@"hitFate" data:dict target:self call:@selector(randomGetBackCall::) arg:data_dict];
		////----
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXingRoom_Step_1];
		CCNode *node = [menu getChildByTag:BT_GXR_GET_ALL_TAG];
		[[Intro share] runIntroTager:node step:INTRO_GuangXingRoom_Step_2];
	}
}
-(void)buttonRandomGetTapped{
	//TODO
	//GXRS_GuanXingSend;
	if (state == GXRS_Stop) {
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin1Max - yinBiCount+1];
		NSDictionary *player_dict =[[GameConfigure shared] getPlayerInfo];
		if([self checkYiBiUpWithAdd:1]){
			[self showMessageWithType:GXRMT_fateYiBiUp];
		}else if ( t_dict && player_dict && [[t_dict objectForKey:@"coin1"] intValue]<=[[player_dict objectForKey:@"coin1"] intValue]) {
			////
			state = GXRS_GuanXingSend;
			[self setBackFateArray:nil];
			backFateID = 0;
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setObject:[NSNumber numberWithInt:1] forKey:@"type"];// 1=银币猎命 2＝元宝猎命
			[dict setObject:[NSNumber numberWithInt:0] forKey:@"isBatch"];//
			NSMutableDictionary *data_dict = [NSMutableDictionary dictionary];
			[data_dict setObject:[NSNumber numberWithInt:1] forKey:@"type"];
			//fix chao
			[data_dict setObject:[NSNumber numberWithInt:1] forKey:@"count"];
			//end
            isSend = YES;
			[GameConnection request:@"hitFate" data:dict target:self call:@selector(randomGetBackCall::) arg:data_dict];
			////----
			[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXingRoom_Step_1];
			CCNode *node = [menu getChildByTag:BT_GXR_GET_ALL_TAG];
			[[Intro share] runIntroTager:node step:INTRO_GuangXingRoom_Step_2];
			
		}else{
			[self showMessageWithType:GXRMT_random];
		}
	}
}

-(void)updateMoneyWithDict:(NSDictionary*)dict{
		backFateID = [[dict objectForKey:@"id"] intValue];
		backFateFRID = [[dict objectForKey:@"frid"] intValue];
		int coin1;
		int coin2;
		int coin3;
		coin1 = [[dict objectForKey:@"coin1"] intValue];
		coin2 = [[dict objectForKey:@"coin2"] intValue];
		coin3 = [[dict objectForKey:@"coin3"] intValue];
		[self updateMoneyWithYuanBao01:coin2 yuanBao02:coin3 yinBi:coin1];
}
-(void)buttonLeftDirTapped{
	GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
	[cardLayer leftMoveStep];
}
-(void)buttonRightDirTapped{
	GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
	[cardLayer rightMoveStep];
}
-(void)showMessageWithType:(GuanXingRoomMessageType)type{
	NSString *str=nil;
	if (type == GXRMT_random) {
		//str =@"^8*银币不足#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yinbi",nil);
	}else if(type == GXRMT_randomBat){
		//str = @"^8*银币不足#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yinbi",nil);
	}else if(type == GXRMT_hit){
		//str =@"^8*元宝不足,请充值#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yuanbao",nil);
	}else if(type == GXRMT_hitBat){
		//str =@"^8*元宝不足,请充值#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yuanbao",nil);
	}else if(type == GXRMT_fateYiBiUp){
		//str =@"^8*银币观星次数不足#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yinbi_count",nil);
	}else if(type == GXRMT_fateYuanBaoUp){
		//str =@"^8*元宝观星次数不足#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_yuanbao_count",nil);
	}else if(type == GXRMT_packageFull){
		//str =@"^8*行囊已满，请整理行囊#ffff00*^68*";
        str =NSLocalizedString(@"guanxingroom_no_package",nil);
	}
	
	if (str) {
		//fix chao
		[ShowItem showItemAct:str];		
	}else{
		CCLOG(@"dialog string is nil");
	}
	
	
}
-(void)messageButtonBackCall:(id)sender{
	CCNode *obj = sender;
	if (obj.tag == GXR_BUTTON_YES_TAG) {
		CCLOG(@"button GXR_BUTTON_YES_TAG");
	}else if (obj.tag == GXR_BUTTON_NO_TAG) {		
		[self removeChildByTag:GXR_MESSAGE_BOX_TAG cleanup:YES];
		CCLOG(@"button GXR_BUTTON_NO_TAG");
	}
}
//BT_GXR_LEFT_DIR_TAG,//左方向
//BT_GXR_RIGHT_DIR_TAG,//右方向
-(void)menuCallbackBack: (id) sender{
    if (isSend) {
        return;
    }
	CCNode *obj = sender;
	if( obj.tag == BTT_GX_NO_HIDE_DEAL_TAG){
		[self updateButtonInfo];
		CCLOG(@"BTT_GX_NO_HIDE_DEAL_TAG");
	}else if( obj.tag == BT_GXR_HEIGHT_GET_TAG){
		[self buttonHeightGetTapped];//高级
		CCLOG(@"BT_GXR_HEIGHT_GET_TAG");
	}else if( obj.tag == BT_GXR_BAT_HEIGHT_GET_TAG){
		[self buttonBatHeightGetTapped];//批量高级
		CCLOG(@"BT_GXR_BAT_HEIGHT_GET_TAG");
	}else if( obj.tag == BT_GXR_VIP_FREE_GET_TAG){
		[self buttonVipFreeGetTapped];//vip_free
		CCLOG(@"BT_GXR_RANDOM_GET_TAG");
	}else if( obj.tag == BT_GXR_RANDOM_GET_TAG){
		[self buttonRandomGetTapped];//随机
		CCLOG(@"BT_GXR_RANDOM_GET_TAG");
	}else if( obj.tag == BT_GXR_BAT_RANDOM_GET_TAG){
		[self buttonBatRandomGetTapped];//随机批量
		CCLOG(@"BT_GXR_BAT_RANDOM_GET_TAG");
	}else if(obj.tag == BT_GXR_GET_ALL_TAG){
		[self buttonGetAllTapped];//全部拾取
		CCLOG(@"BT_GXR_GET_ALL_TAG");
	}else if(obj.tag == BT_GXR_LEFT_DIR_TAG){
		[self buttonLeftDirTapped];
		CCLOG(@"BT_GXR_LEFT_DIR_TAG");
	}else if(obj.tag == BT_GXR_RIGHT_DIR_TAG){
		[self buttonRightDirTapped];
		CCLOG(@"BT_GXR_RIGHT_DIR_TAG");
	}
	CCLOG(@"GuanXingRoom tag");
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"GuanXingRoom ccTouchBegan");
	
	if(isBeganTouch){
        return YES;
    }
    isBeganTouch = YES;
	isMenuTouch = NO;
	isLayerTouch = NO;
	GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
	
	if ( [menu ccTouchBegan:touch withEvent:event] ) {
		CCLOG(@"GuanXingRoom menu ccTouchBegan");
		isMenuTouch = YES;		
	}else if([cardLayer ccTouchBegan:touch withEvent:event]){
		CCLOG(@"GuanXingRoom layer ccTouchBegan ...");			
		isLayerTouch = YES;		
	}
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!isBeganTouch) {
        return;
    }
	CCLOG(@"GuanXingRoom moveing");	
	if ( isMenuTouch ) {
		[menu ccTouchMoved:touch withEvent:event];
		CCLOG(@"GuanXingRoom menu ccTouchMoved");
	}
	if (isLayerTouch) {
		GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
		[cardLayer ccTouchMoved:touch withEvent:event];	
	}
	
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!isBeganTouch) {
        return;
    }
	if ( isMenuTouch ) {
		[menu ccTouchEnded:touch withEvent:event];
		CCLOG(@"GuanXingRoom menu ccTouchEnded");		
	}
	if (isLayerTouch) {
		GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
		[cardLayer ccTouchEnded:touch withEvent:event];
	}
	CCLOG(@"GuanXingRoom ccTouchEnded");
    isBeganTouch = NO;
}
-(void)updateForInfo{

	CCMenuItem *bt_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_HEIGHT_GET_TAG];
	CCMenuItem *bt_bat_height_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_HEIGHT_GET_TAG];
	CCMenuItem *bt_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_RANDOM_GET_TAG];
	CCMenuItem *bt_bat_random_get = (CCMenuItem *)[menu getChildByTag:BT_GXR_BAT_RANDOM_GET_TAG];
	CCMenuItemToggle *btt_bat_guanxing_toggle = (CCMenuItemToggle *)[menu getChildByTag:BTT_GX_NO_HIDE_DEAL_TAG];
	
	if (0>=yinBiCount) {
		[bt_random_get setIsEnabled:NO];
		[bt_bat_random_get setIsEnabled:NO];
	}else{
		if (bt_random_get.visible) {
			[bt_random_get setIsEnabled:YES];
		}
		if (bt_bat_random_get.visible) {
			[bt_bat_random_get setIsEnabled:YES];
		}		
	}
	if (0>=yuanBaoCount) {
		[bt_height_get setIsEnabled:NO];
		[bt_bat_height_get setIsEnabled:NO];
	}else{
		if (bt_height_get.visible) {
			[bt_height_get setIsEnabled:YES];
		}
		if(bt_bat_height_get.visible){
			[bt_bat_height_get setIsEnabled:YES];
		}		
	}
	//NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	//NSNumber *vip= [dict objectForKey:@"vip"];

	if (bt_random_get) {
		GameMoney *yibiSpr = (GameMoney *)[self getChildByTag:GXR_YIBI_INFO_TAG];
		if (!yibiSpr) {
			yibiSpr = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:0];
			[self addChild:yibiSpr z:999 tag:GXR_YIBI_INFO_TAG];
			yibiSpr.position = ccpAdd(bt_random_get.position,ccp(0, -bt_random_get.contentSize.height/2-yibiSpr.contentSize.height/2));
		}
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin1Max - yinBiCount+1];
		if (t_dict && yinBiCount>0 ) {
			if (yuanBaoFreeCount>0 /*&& [vip intValue]>0*/ ) {
				if([btt_bat_guanxing_toggle visible] && [btt_bat_guanxing_toggle selectedIndex]==1){
					int yibi = [[t_dict objectForKey:@"coin1"] intValue];
					[yibiSpr setMoneyValue:yibi];
				}else{
                    [yibiSpr setMoneyValue:0];
                }
			}else{
				int yibi = [[t_dict objectForKey:@"coin1"] intValue];
				[yibiSpr setMoneyValue:yibi];
			}
		}else{
			[yibiSpr setMoneyValue:0];
		}
	}
    
    float fontSize=18;
    if (iPhoneRuningOnGame()) {
        fontSize=16;
    }
	if ((bt_height_get && bt_height_get.visible==YES)|| (bt_bat_height_get && bt_bat_height_get.visible==YES)) {
		GameMoney *yuanbaoSpr = (GameMoney *)[self getChildByTag:GXR_YUANBAO_INFO_TAG];
		if (!yuanbaoSpr) {
			yuanbaoSpr = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:0];
			[self addChild:yuanbaoSpr z:999 tag:GXR_YUANBAO_INFO_TAG];
			yuanbaoSpr.position = ccpAdd(bt_height_get.position,ccp(0, -bt_height_get.contentSize.height/2-yuanbaoSpr.contentSize.height/2));
		}
		NSDictionary *t_dict = [[GameDB shared] getFateCostInfo:hitFateCoin2Max - yuanBaoCount+1];
		if (t_dict && yuanBaoCount > 0) {
			int yuanbao = [[t_dict objectForKey:@"coin2"] intValue]+[[t_dict objectForKey:@"coin3"] intValue];
			[yuanbaoSpr setMoneyValue:yuanbao];
		}else{
			[yuanbaoSpr setMoneyValue:0];
		}
	}
	////
	CCLabelFX *randomInfo_txt = (CCLabelFX *)[self getChildByTag:GXR_RANDOM_INFO_TXT_TAG];
	CCLabelFX *hitInfo_txt = (CCLabelFX *)[self getChildByTag:GXR_HIT_INFO_TXT_TAG];
	CCLabelFX *randomInfo = (CCLabelFX *)[self getChildByTag:GXR_RANDOM_INFO_TAG];
	CCLabelFX *hitInfo = (CCLabelFX *)[self getChildByTag:GXR_HIT_INFO_TAG];
    
	if ((!randomInfo) && randomInfo_txt) {
		randomInfo = [CCLabelFX labelWithString:@""
									   fontName:getCommonFontName(FONT_1)
									   fontSize:fontSize
								   shadowOffset:CGSizeMake(-1.5, -1.5)
									 shadowBlur:2.0f
									shadowColor:ccc4(0, 0, 0, 128)
					  fillColor:ccc4(254,237,131, 255)];
		[self addChild:randomInfo z:999 tag:GXR_RANDOM_INFO_TAG];
		randomInfo.anchorPoint = ccp(0,0.5);
    
        randomInfo.position = ccpAdd(randomInfo_txt.position, ccp(randomInfo_txt.contentSize.width,0));
        
	}
	if ((!hitInfo) && hitInfo_txt) {
		hitInfo = [CCLabelFX labelWithString:@""
									fontName:getCommonFontName(FONT_1)
									fontSize:fontSize
								shadowOffset:CGSizeMake(-1.5, -1.5)
								  shadowBlur:2.0f
								 shadowColor:ccc4(0, 0, 0, 128)
								   fillColor:ccc4(254,237,131, 255)];
		[self addChild:hitInfo z:999 tag:GXR_HIT_INFO_TAG];
		hitInfo.anchorPoint = ccp(0,0.5);
     
        hitInfo.position = ccpAdd(hitInfo_txt.position, ccp(hitInfo_txt.contentSize.width,0));
        
		hitInfo.color = ccYELLOW;
	}
	[randomInfo setString:[NSString stringWithFormat:@"%d",yinBiCount]];
	[hitInfo setString:[NSString stringWithFormat:@"%d",yuanBaoCount]];
	if (vipFreeCountInfo) {
		[vipFreeCountInfo setString:[NSString stringWithFormat:@"%d",yuanBaoFreeCount]];
	}

}
//***************
-(void)randomGetBackCall:(id)sender :(NSDictionary*)_data{
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		[[GameConfigure shared] updatePackage:data];
		[self setBackFateArray:[self getItemDictArrayWithArray:[data objectForKey:@"wait"] ]];
		[self updateMoneyWithDict:data];
		guanXingCount = [backFateArray count];
		
		//[self setGetAllButtonVisible:NO];
		[self setGetAllButtonDisabled:YES];
		//TODO
		if (_data) {
			int type = [[_data objectForKey:@"type"] intValue];// 1=银币猎命 2＝元宝猎命
			int count = [[_data objectForKey:@"count"] intValue];
			if (type == 1) {
				yinBiCount -= count;
			}else if(type == 2){
				yuanBaoCount -= count;
			}else if(type == 3){
				yuanBaoFreeCount -= count;
			}
			else{
				CCLOG(@"guanxing type is error");
			}
			
		}else{
			CCLOG(@"guanxing type is error");
		}

		[self updateButtonInfo];
		//[self setBatGetFateWithHeightValue:yuanBaoCount randomValue:yinBiCount];
	}else{
		CCLOG(@"GuanXingRoom get error");
		//CCLOG(getResponseMessage(sender));
        [ShowItem showErrorAct:getResponseMessage(sender)];
#ifdef GAME_DEBUGGER
		CGPoint pos = ccp(400, self.contentSize.height/2+100);
		CCSprite* spr = [CCLabelTTF labelWithString:@"GuanXingRoom get error" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
		[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
#endif
		guanXingCount = 0;
	}
	state = GXRS_GuanXing;
	isSend = NO;
}
-(void)batAllWaitFetchBackCall:(id)sender{
	[self waitFetchBackCall:sender];
	//fix chao
	CCMenuItem *item_obj = (CCMenuItem *)[menu getChildByTag:BT_GXR_GET_ALL_TAG];
	[item_obj setIsEnabled:YES];
	//end
}
-(void)waitFetchBackCall:(id)sender{
	
	//TODO wait fetch
	if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);		
		[[GameConfigure shared] updatePackage:data];
		NSArray *delArr = [data objectForKey:@"delWids"];
		GXRCardLayer *cardLayer = (GXRCardLayer *)[self getChildByTag:GXR_CARDLAYER_TAG];
		int i = 1;		
		float t_time = [delArr count]*0.015;
		for (NSNumber *itemIDNum in delArr) {
			NSArray *delCardArr = [cardLayer getCardsWithItemID:[itemIDNum intValue]];			
			if (delCardArr) {
				NSArray *showCardArr = [cardLayer getShowCards];				
				for (GXRCard *card in delCardArr) {
					if (card && [card getItemID]>0) {
						BOOL _isShowed = NO;						
						for (Card *s_card in showCardArr) {
							if ([s_card getItemID] == [card getItemID]) {
								_isShowed = YES;
								break;
							}							
						}
						if (_isShowed) {						
							GXRCard *tCard;
							tCard = [GXRCard node];
							[self addChild:tCard];
							[tCard changeItemWithOther:card];
							[tCard setNameVisible:NO];
							//
							CGPoint pos;
							pos.x = card.position.x + cardLayer.position.x;
							pos.y = card.position.y;
							tCard.position = pos;
							//fix chao
							i = GXCL_SHOW_LEN - (pos.x-s_gxcl_card_startpos_x)/GXR_CARD_W;
							if (i<0) {
								i=0;
							}
							id waitAc = [CCDelayTime actionWithDuration:t_time*i];
							id scale1 = [CCScaleTo actionWithDuration:0.5 scale:0.5];
							CGPoint ptRole=ccp(735,230);
							if (iPhoneRuningOnGame()) {
								if (isIphone5()) {
									ptRole=ccp(770/2.0f,260/2.0f);
								}else{
									ptRole=ccp(694/2.0f,260/2.0f);
								}
							}
							id move1 = [CCMoveTo actionWithDuration:0.25 position:ptRole];
							[tCard runAction:([CCSequence actions:waitAc,[CCSpawn actions:scale1,move1, nil],[CCCallFuncN actionWithTarget:self selector:@selector(removeItemCall:)], nil ])];
							//end
							////
						}
					}
					
				}
				[cardLayer removeItemWithArray:delCardArr];
				//
				if ([cardLayer getCardsCount]>GXCL_SHOW_LEN) {
					[self setIsOpenDirButton:YES];
				}else{
					[self setIsOpenDirButton:NO];
				}				
			}
			////
			////----
			[[Intro share] removeCurrenTipsAndNextStep:INTRO_GuangXingRoom_Step_2];
			//CCNode *node = [menu getChildByTag:BT_CLOSE_WIN_TAG];
			//[[Intro share] runIntroTager:node step:INTRO_CLOSE_GuangXingRoom];
		}
		
		NSDictionary *p_data = [[GameConfigure shared] getPlayerInfo];
		[self  updateMoneyWithYuanBao01:[[p_data objectForKey:@"coin2"] intValue] yuanBao02:[[p_data objectForKey:@"coin3"] intValue] yinBi:[[p_data objectForKey:@"coin1"] intValue]];
		
	}else{
		CCLOG(@"GuanXingRoom wait fetch back  error");
		//CCLOG(getResponseMessage(sender));
        [ShowItem showErrorAct:getResponseMessage(sender)];
#ifdef GAME_DEBUGGER
		CGPoint pos = ccp(400, self.contentSize.height/2+100);
		CCSprite* spr = [CCLabelTTF labelWithString:@"GuanXingRoom wait fetch back  error" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
		[ClickAnimation showSpriteInLayer:self z:99 call:nil point:pos moveTo:pos sprite:spr  loop:NO];
#endif
	}
    isSend = NO;
}


@end
