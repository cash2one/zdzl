//
//  ItemSynthesize.m
//  TXSFGame
//
//  Created by chao chen on 12-12-8.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "ItemSynthesize.h"
#import "Config.h"
#import "GameConfigure.h"
#import "MessageBox.h"
#import "GameDB.h"
#import "Window.h"


#define IS_BUTTON_H cFixedScale(60)
//间隔
#define IS_LAYER_SPACE_W cFixedScale(10)
//layer 1 宽 高
#define IS_LAYER_ONE_W	cFixedScale(192)
#define IS_LAYER_ONE_H	cFixedScale(490)
//layer 2 宽 高
#define IS_LAYER_TWO_W	cFixedScale(192)
#define IS_LAYER_TWO_H	cFixedScale(490)
//layer 3 宽 高
#define IS_LAYER_THREE_W	cFixedScale(420)
#define IS_LAYER_THREE_H	cFixedScale(490)
#define POS_CLOSE_ADD_Y		cFixedScale(8)
#define VALUE_LINE_W		cFixedScale(15)
#define VALUE_LINE_H		cFixedScale(10)
#define CGS_TOP_BACK01  CGSizeMake(cFixedScale(170), cFixedScale(29))
#define CGS_TOP_BACK03  CGSizeMake(cFixedScale(402), cFixedScale(29))
#define POS_TOP_LABLE03_ADD_X  cFixedScale(20)
#define TOP_TOP_LABLE04_Y     cFixedScale(280)
#define VALUE_POS_Y  cFixedScale(15)
#define POS_CROSSBAND_ADD_Y   cFixedScale(40)
#define POS_LABELRESULT_ADD_Y cFixedScale(100)
#define POS_CARDRESULT_ADD_X  cFixedScale(11)
#define POS_LABELNEED_ADD_X  cFixedScale(20)
#define POS_LABELNEED_ADD_Y   cFixedScale(70)
#define POS_CARDNEED_ADD_Y  cFixedScale(22)
#define POS_LABELMONEY_ADD_X cFixedScale(20)
#define POS_LABELMONEY_ADD_Y cFixedScale(70)
#define POS_CARDMONEY_ADD_Y cFixedScale(22)
#define CGS_ITEMS   CGSizeMake(cFixedScale(170), cFixedScale(36))
#define SIZE_PARARR    cFixedScale(20)


#pragma mark -
#pragma mark - ISCard

@interface ISCard:  CCSprite{
	NSInteger cardFid;//fid
	ItemQuality	itemQuality;//物品品质
	NSInteger itemCount;//数量
}
@property (nonatomic,assign) NSInteger itemCount;
@property (nonatomic,assign) ItemQuality itemQuality;
-(void)changeItemWithFid:(NSInteger)fid;//改变物品
-(void)removeItem;//删除物品
-(void)setItemIsNull;//设置物品为空
-(BOOL)isOwnItem;//是否有物品
@end

@implementation ISCard
enum {
	kISCardBG = 256,//背景
	kISCardQuality,//品质
	kISCardItem ,//物品
	kISCardCount ,//数量
};
@synthesize itemQuality;
@synthesize itemCount;
-(void)onEnter{
	////
	[super onEnter];
	////
	[self setItemIsNull];
	
}
-(void)setItemCount:(NSInteger)_itemCount{
	
	itemCount = _itemCount;
	if (itemCount<0) {
		//[self removeChildByTag:kISCardCount cleanup:YES];
		itemCount = 0;
		CCLOG(@"item cout < 0");		
		return;
	}
	////
	CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:kISCardCount];
	if (!label) {
		label = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:21];
		[self addChild:label z:kISCardCount tag:kISCardCount];
		label.anchorPoint = ccp(1,1);
		label.position = ccp(self.contentSize.width,self.contentSize.height);
        if (iPhoneRuningOnGame()) {
            label.scale = 0.5;
        }
	}
	if (itemCount>99) {
		[label setString:@"99+"];
	}else{
		[label setString:[NSString stringWithFormat:@"%d",itemCount]];
	}
}
//是否有物品
-(BOOL)isOwnItem{
	if (cardFid <=0) {
		return NO;
	}
	return YES;
}
-(ItemQuality)getItemQualityWithFid:(NSInteger)fid{
    
    NSDictionary *dict = [[GameDB shared] getItemInfo:fid];
    if (dict) {
        return [[dict objectForKey:@"quality"] intValue];
    }
    return 0;
}
//改变物品
-(void)changeItemWithFid:(NSInteger)fid{
	if (fid<=0) {
		return;
	}
	////
	cardFid = fid;
	
    [self setItemQuality:[self getItemQualityWithFid:cardFid]];
	
	////
	[self removeChildByTag:kISCardItem cleanup:YES];
    
    CCSprite *spr = nil;
    if (cardFid == 1) {
        spr = [CCSprite spriteWithFile:@"images/ui/object-icon/1.png"];
    }else if (cardFid == 2) {
        spr = [CCSprite spriteWithFile:@"images/ui/object-icon/2.png"];
    }else if (cardFid == 3) {
        spr = [CCSprite spriteWithFile:@"images/ui/object-icon/3.png"];
    } else {
        spr = getItemIcon(cardFid);
    }
	if (!spr) {
		CCLOG(@"iid %d is nil", cardFid);
		
	} else {
		[self addChild:spr z:kISCardItem tag:kISCardItem];
		spr.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	}
}
-(void)setItemQuality:(ItemQuality)_itemQuality{
	itemQuality = _itemQuality;
	
	[self removeChildByTag:kISCardQuality cleanup:YES];
	CCSprite *spr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png",itemQuality]];
	if (!spr) {
		CCLOG(@"set quality error");
		spr = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	}
	[self addChild:spr z:kISCardQuality tag:kISCardQuality];
	
	spr.position = ccp(self.contentSize.width /2,self.contentSize.height /2);
	
//	CCSprite *spr;
//	CCTexture2D *text;
//	spr = (CCSprite *)[self getChildByTag:kISCardQuality];
//	if (!spr) {
//		spr = [CCSprite spriteWithFile:@"images/ui/panel/itemNull.png"];
//		[self addChild:spr z:kISCardQuality tag:kISCardQuality];
//	}
//	switch (itemQuality) {
//        case IQ_WHITE:{
//            text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemNull.png"];
//        }
//            break;
//		case IQ_GREEN:{
//			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemGreen.png"];
//		}
//			break;
//		case IQ_BLUE:{
//			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemBlue.png"];
//		}
//			break;
//		case IQ_PURPLE:{
//			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemPurple.png"];
//			
//		}
//			break;
//		case IQ_ORANGE:{
//			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemOrange.png"];
//		}
//			break;
//        case IQ_RED:{
//			text = [[CCTextureCache sharedTextureCache] addImage: @"images/ui/panel/itemOrange.png"];
//		}
//			break;
//		default:
//			break;
//	}
//	
//	[spr setTexture:text];
//	spr.position = ccp(self.contentSize.width /2,self.contentSize.height /2);
}
//删除
-(void)removeItem{
	[self removeChildByTag:kISCardQuality cleanup:YES];
	[self removeChildByTag:kISCardItem cleanup:YES];
	
	cardFid = -1;
}

//设置物品为空
-(void)setItemIsNull{
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	self.contentSize = bg.contentSize;
	[self addChild:bg];
	bg.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
}
@end

#pragma mark -
#pragma mark - ItemSynthesize
@implementation ItemSynthesize
enum{
	ItemSynthesizeTag_BG=211,
	ItemSynthesizeTag_Title,
	ItemSynthesizeTag_LayerBack01,
	ItemSynthesizeTag_LayerBack02,
	ItemSynthesizeTag_LayerBack03,
	
	//ItemSynthesizeTag_BingFu,
	ItemSynthesizeTag_YuEr,
	ItemSynthesizeTag_XuanTie,
	ItemSynthesizeTag_Dir,//方向图
	ItemSynthesizeTag_Level_m,
	ItemSynthesizeTag_Level_h,
	ItemSynthesizeTag_Level_s,
	ItemSynthesizeTag_LevelLabel01,
	ItemSynthesizeTag_LevelLabel02,
	ItemSynthesizeTag_LevelLabel03,
	ItemSynthesizeTag_LabelResult,//合成结果标签
	ItemSynthesizeTag_SpriteResult,//合成结果图标
	ItemSynthesizeTag_LabelNeed,//所需材料标签
	ItemSynthesizeTag_SpriteNeed,//所需材料图标
	ItemSynthesizeTag_LabelMoney,//所需钱标签
	ItemSynthesizeTag_SpriteMoney,//所需钱图标
};

@synthesize levelMenus;
@synthesize menuItems;

-(void)onEnter{
	[super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	menu = [CCMenu menuWithItems:nil];
	menu.position = CGPointZero;
	[self addChild:menu z:3];
	
	NSArray *sprArr;
	sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_synthesize");
	CCMenuItem *bt_Syn = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	bt_Syn.position = ccp(self.contentSize.width*5/8,IS_BUTTON_H);
	[menu addChild:bt_Syn z:0 tag:BT_IS_SYNTHESIZE_TAG];
	
	sprArr = getBtnSpriteWithStatus(@"images/ui/button/bt_all_synthesize");

	CCMenuItem *bt_Syn_All = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:[sprArr objectAtIndex:1] target:self selector:@selector(menuCallbackBack:)];
	if (iPhoneRuningOnGame()) {
		bt_Syn.scale = 1.3f;														//Kevin added
		bt_Syn_All.scale = 1.3f;													//Kevin added
		bt_Syn.position = ccp(bt_Syn.position.x-15,bt_Syn.position.y+10);					//Kevin added
		bt_Syn_All.position = ccp(self.contentSize.width*7/8 - 30,IS_BUTTON_H+10);
	}else{
		bt_Syn_All.position = ccp(self.contentSize.width*7/8,IS_BUTTON_H);
	}
	[menu addChild:bt_Syn_All z:0 tag:BT_IS_SYNTHESIZE_ALL_TAG];
	int line_w = VALUE_LINE_W;
	int line_h = VALUE_LINE_H;
	
	////层1
	MessageBox *box01 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
	if (iPhoneRuningOnGame()) {
		box01.contentSize = CGSizeMake(115,556/2);									//Kevin fixed, before CGSizeMake(120, 556/2)
		box01.position = ccp(50 ,line_h+IS_LAYER_SPACE_W +3);						//Kevin fixed, before ccp(44,
	}else{
		box01.contentSize = CGSizeMake(IS_LAYER_ONE_W, IS_LAYER_ONE_H);
		box01.position = ccp(line_w+IS_LAYER_SPACE_W,line_h+IS_LAYER_SPACE_W);
	}
	[self addChild:box01 z:0 tag:ItemSynthesizeTag_LayerBack01];
	
	////层2
	MessageBox *box02 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
	if (iPhoneRuningOnGame()) {
		
		box02.contentSize = box01.contentSize;										//Kevin fixed, before CGSizeMake(IS_LAYER_TWO_W + 18, 556/2);
		box02.position =
		ccp(box01.position.x + box01.contentSize.width + 4,box01.position.y);			//Kevin fixed, before ccp(line_w+IS_LAYER_SPACE_W*2+IS_LAYER_ONE_W +60,line_h+IS_LAYER_SPACE_W +3);

	}else{
		box02.contentSize = CGSizeMake(IS_LAYER_TWO_W, IS_LAYER_TWO_H);
		box02.position = ccp(line_w+IS_LAYER_SPACE_W*2+IS_LAYER_ONE_W,line_h+IS_LAYER_SPACE_W);
	}
	[self addChild:box02 z:0 tag:ItemSynthesizeTag_LayerBack02];
	
	////层3
	MessageBox *box03 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
	if (iPhoneRuningOnGame()) {
//		if (isIphone5()) {
//			box03.contentSize = CGSizeMake(230 +30, 556/2);
//			box03.position = ccp(line_w+IS_LAYER_SPACE_W*3+IS_LAYER_ONE_W+IS_LAYER_TWO_W +80,line_h+IS_LAYER_SPACE_W +3);
//		}else{
		box03.contentSize = CGSizeMake(230, 556/2);									//Kevin fixed, before CGSizeMake(230, 556/2);
		box03.position =
		ccp( box02.position.x+ box02.contentSize.width + 4, box02.position.y);			//Kevin fixed, before
		//box03.position = ccp(line_w+IS_LAYER_SPACE_W*3+IS_LAYER_ONE_W+IS_LAYER_TWO_W +80,line_h+IS_LAYER_SPACE_W +3);
//		}
	}else{
		box03.contentSize = CGSizeMake(IS_LAYER_THREE_W, IS_LAYER_THREE_H);
		box03.position = ccp(line_w+IS_LAYER_SPACE_W*3+IS_LAYER_ONE_W+IS_LAYER_TWO_W,line_h+IS_LAYER_SPACE_W);
	}
	[self addChild:box03 z:0 tag:ItemSynthesizeTag_LayerBack03];
	
	//合成物品分类
	CCSprite *top_back01 = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	top_back01 = getSpriteWithSpriteAndNewSize(top_back01, CGS_TOP_BACK01);
	[self addChild:top_back01 z:1];
	top_back01.position = ccp(box01.position.x+box01.contentSize.width/2,box01.position.y+box01.contentSize.height-IS_LAYER_SPACE_W-top_back01.contentSize.height/2);
	//CCLabelTTF *top_lable01 = [CCLabelTTF labelWithString:@"合成物品分类" fontName:@"Verdana-Bold"  fontSize:18];
    CCLabelTTF *top_lable01 = [CCLabelTTF labelWithString:NSLocalizedString(@"item_synthesize_type",nil) fontName:@"Verdana-Bold"  fontSize:18];
    if (iPhoneRuningOnGame()) {
        top_lable01.scale = 0.5;
		top_back01.position = ccp( top_back01.position.x, top_back01.position.y - 5);	//Kevin added
		top_back01.scale		= 1.3f;														//Kevin added
    }
	[top_lable01 setColor:ccc3(49,15,7)];
	[top_back01 addChild:top_lable01];
	top_lable01.position = ccp(top_back01.contentSize.width/2,top_back01.contentSize.height/2);
	
	//合成物品级别
	CCSprite *top_back02 = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	top_back02 = getSpriteWithSpriteAndNewSize(top_back02, CGS_TOP_BACK01);
	[self addChild:top_back02 z:1];
	top_back02.position = ccp(box02.position.x+box02.contentSize.width/2,box02.position.y+box02.contentSize.height-IS_LAYER_SPACE_W-top_back02.contentSize.height/2);
	//CCLabelTTF *top_lable02 = [CCLabelTTF labelWithString:@"合成物品级别" fontName:@"Verdana-Bold"  fontSize:18];
    CCLabelTTF *top_lable02 = [CCLabelTTF labelWithString:NSLocalizedString(@"item_synthesize_level",nil) fontName:@"Verdana-Bold"  fontSize:18];
    if (iPhoneRuningOnGame()) {
//		if (isIphone5()) {
//			top_back02.scale = 1.2;
//			top_lable02.scale = 0.6;
//		}else{
        top_lable02.scale = 0.5;
		
		top_back02.position = ccp( top_back02.position.x, top_back01.position.y);		//Kevin added
		top_back02.scale = 1.3f;															//Kevin added
//		}
    }
	[top_lable02 setColor:ccc3(49,15,7)];
	[top_back02 addChild:top_lable02];
	top_lable02.position = ccp(top_back02.contentSize.width/2,top_back02.contentSize.height/2);
	
	//合成结果
	CCSprite *top_back03 = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	top_back03 = getSpriteWithSpriteAndNewSize(top_back03, CGS_TOP_BACK03);
	[self addChild:top_back03 z:1];
	top_back03.position = ccp(box03.position.x+box03.contentSize.width/2,box03.position.y+box03.contentSize.height-IS_LAYER_SPACE_W-top_back03.contentSize.height/2);
	//CCLabelTTF *top_lable03 = [CCLabelTTF labelWithString:@"合成结果" fontName:@"Verdana-Bold"  fontSize:18];
    CCLabelTTF *top_lable03 = [CCLabelTTF labelWithString:NSLocalizedString(@"item_synthesize_result",nil) fontName:@"Verdana-Bold"  fontSize:18];
    if (iPhoneRuningOnGame()) {
//		if (isIphone5()) {
//			top_back03.scale = 1.2;
//			top_lable03.scale = 0.6;
//		}else{
        top_lable03.scale = 0.5;
		
		top_back03.position = ccp( top_back03.position.x, top_back01.position.y);		//Kevin added
		top_back03.scaleX = 1.1f;													//Kevin added
		top_back03.scaleY = 1.2f;													//Kevin added
//		}
    }
	[top_lable03 setColor:ccc3(49,15,7)];
	[top_back03 addChild:top_lable03];
	top_lable03.position = ccp(POS_TOP_LABLE03_ADD_X+top_lable03.contentSize.width/2,top_back03.contentSize.height/2);
	
	//所需材料
	CCSprite *top_back04 = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	top_back04 = getSpriteWithSpriteAndNewSize(top_back04, CGS_TOP_BACK03);
	[self addChild:top_back04 z:1];
	top_back04.position = ccp(box03.position.x+box03.contentSize.width/2,TOP_TOP_LABLE04_Y);
	//CCLabelTTF *top_lable04 = [CCLabelTTF labelWithString:@"合成所需材料" fontName:@"Verdana-Bold"  fontSize:18];
    CCLabelTTF *top_lable04 = [CCLabelTTF labelWithString:NSLocalizedString(@"item_synthesize_need",nil) fontName:@"Verdana-Bold"  fontSize:18];
    if (iPhoneRuningOnGame()) {
//		if (isIphone5()) {
//			top_back04.scale = 1.2;
//			top_lable04.scale = 0.6;
//		}else{
        top_lable04.scale = 0.5;
		
		top_back04.scaleX = 1.1f;													//Kevin added
		top_back04.scaleY = 1.2f;													//Kevin added
		top_back04.position = ccp(top_back04.position.x,top_back04.position.y+28);		//Kevin added
//		}
    }
	[top_lable04 setColor:ccc3(49,15,7)];
	[top_back04 addChild:top_lable04];
	top_lable04.position = ccp(POS_TOP_LABLE03_ADD_X+top_lable04.contentSize.width/2,top_back04.contentSize.height/2);
	
	//Kevin added
	if (iPhoneRuningOnGame()) {
		top_lable03.anchorPoint = ccp(0,0.5);
		top_lable04.anchorPoint = ccp(0,0.5);
		top_lable03.position = ccp( top_lable03.position.x - 40, top_lable03.position.y);
		top_lable04.position = ccp( top_lable03.position.x , top_lable04.position.y);
	}
	//-------------------------------//
	
	////只显示可交易材料复选
	//	sprArr = getToggleSprites(@"images/ui/button/bt_toggle01.png",@"images/ui/button/bt_toggle02.png",@"只显示可交易材料",14,ccc4(49,15,7,255),ccc4(49,15,7,255) );
	//	CCMenuItemSprite *bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	//	CCMenuItemSprite *bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	//	CCMenuItem *btt_trade_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:bt_spr01,bt_spr02, nil];
	//	[menu addChild:btt_trade_toggle z:0 tag:BTT_GX_NO_HIDE_DEAL_TAG];
	//	btt_trade_toggle.position = ccp(box03.position.x+box03.contentSize.width/2+20+btt_trade_toggle.contentSize.width/2,280);
    
	menuItems = [NSMutableArray array];
	[menuItems retain];
	levelMenus = [NSMutableArray array];
	[levelMenus retain];
	
    
    CCSprite *dirSpr = [CCSprite spriteWithFile:@"images/ui/panel/t34.png"];
	[self addChild:dirSpr z:4 tag:ItemSynthesizeTag_Dir];
	if (iPhoneRuningOnGame()) {
		dirSpr.position = ccp(top_back01.position.x * top_back01.scaleX +top_back01.contentSize.width/2 - 24,0);			//Kevin fixed
		dirSpr.scale = 1.2;
	}else{
		dirSpr.position = ccp(top_back01.position.x+top_back01.contentSize.width/2,0);
	}
	
	///物品分类
    //NSArray *itemNameArr = [NSArray arrayWithObjects:@"兵 符",@"鱼 饵",@"玄 铁", nil];
	//NSArray *itemNameArr = [NSArray arrayWithObjects:@"鱼 饵",@"玄 铁", nil];
    NSArray *itemNameArr = [NSArray arrayWithObjects:NSLocalizedString(@"item_synthesize_fish",nil),NSLocalizedString(@"item_synthesize_mining",nil), nil];
	int i;
	CGPoint pos = top_back01.position;
	pos.y -= top_back01.contentSize.height/2;
	if (iPhoneRuningOnGame()) {
		pos.y -= 10;
	}else{
		pos.y -= VALUE_POS_Y;
	}
	
	i=0;
	for (NSString *name in itemNameArr) {
		if (iPhoneRuningOnGame()) {
			sprArr = [self getToggleButton:@"images/ui/panel/t19.png"
									 path2:@"images/ui/panel/t20.png"
									 label:name fontSize:SIZE_PARARR+2
									color1:ccc4(49,15,7,255)
									color2:ccc4(255,255,100,255)
									  size:CGSizeMake(CGS_ITEMS.width*1.2f, CGS_ITEMS.height*2.0f)];							//Kevin added
		}
		else{
		sprArr = [self getToggleButton:@"images/ui/panel/t19.png" path2:@"images/ui/panel/t20.png" label:name fontSize:SIZE_PARARR color1:ccc4(49,15,7,255) color2:ccc4(255,255,100,255) size:CGS_ITEMS];
		}
		CCMenuItem *btt_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:[sprArr objectAtIndex:0],[sprArr objectAtIndex:1], nil];
		//[menu addChild:btt_toggle z:0 tag:ItemSynthesizeTag_BingFu+i];
		[menu addChild:btt_toggle z:0 tag:ItemSynthesizeTag_YuEr+i];
		
        [menuItems addObject:btt_toggle];
		pos.y -= btt_toggle.contentSize.height/2;
		btt_toggle.position = pos;
		if (!iPhoneRuningOnGame()) {
			pos.y -= btt_toggle.contentSize.height/2;
			pos.y -= IS_LAYER_SPACE_W*btt_toggle.scaleY;
		}
		else
		{
			pos.y -= IS_LAYER_SPACE_W*5.0f;
		}
		i++;
	}
	
	////结果横条
	CCSprite *crossband = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	crossband = getSpriteWithSpriteAndNewSize(crossband, CGSizeMake(box03.contentSize.width-IS_LAYER_SPACE_W, 3));
	[self addChild:crossband z:3];
	if (iPhoneRuningOnGame()) {
		crossband.position = ccp(box03.position.x+box03.contentSize.width/2,IS_BUTTON_H+POS_CROSSBAND_ADD_Y+20);
	}
	else
	{
		crossband.position = ccp(box03.position.x+box03.contentSize.width/2,IS_BUTTON_H+POS_CROSSBAND_ADD_Y);
	}
	
	////结果标识
	CCLabelTTF *labelResult = [CCLabelTTF labelWithString:@"" fontName:@"Verdana-Bold" fontSize:20];
    labelResult.color = ccc3(6, 148, 216);
	[self addChild:labelResult z:3 tag:ItemSynthesizeTag_LabelResult];
	labelResult.anchorPoint = ccp(0,0.5);
	labelResult.position = ccp(top_back03.position.x,top_back03.position.y-POS_LABELRESULT_ADD_Y);
	
	////结果图标
	ISCard *cardResult = [ISCard node];
	[self addChild:cardResult z:3 tag:ItemSynthesizeTag_SpriteResult];
	cardResult.position = ccp(labelResult.position.x-cardResult.contentSize.width/2-POS_CARDRESULT_ADD_X,labelResult.position.y);
	
	////所需材料标识
	CCLabelTTF *labelNeed = [CCLabelTTF labelWithString:@"" fontName:@"Verdana-Bold" fontSize:16];
    labelNeed.color = ccc3(49, 182, 82);
	[self addChild:labelNeed z:3 tag:ItemSynthesizeTag_LabelNeed];
	if (iPhoneRuningOnGame()) {
		labelNeed.position = ccp(bt_Syn.position.x+POS_LABELNEED_ADD_X,bt_Syn.position.y+POS_LABELNEED_ADD_Y+20);
	}
	else{
		labelNeed.position = ccp(bt_Syn.position.x+POS_LABELNEED_ADD_X,bt_Syn.position.y+POS_LABELNEED_ADD_Y);
	}
	
	////所需材料图标
	ISCard *cardNeed = [ISCard node];
	[self addChild:cardNeed z:3 tag:ItemSynthesizeTag_SpriteNeed];
	cardNeed.position = ccp(labelNeed.position.x,labelNeed.position.y+cardNeed.contentSize.height/2+POS_CARDNEED_ADD_Y);
	
	[cardNeed setItemCount:0];
	
	////所需银币
	CCLabelTTF *labelMoney = [CCLabelTTF labelWithString:@"" fontName:@"Verdana-Bold" fontSize:16];
    labelMoney.color = ccc3(254, 237, 131);
	[self addChild:labelMoney z:3 tag:ItemSynthesizeTag_LabelMoney];
	if (iPhoneRuningOnGame()) {
		labelMoney.position = ccp(bt_Syn_All.position.x-POS_LABELMONEY_ADD_X -2 ,bt_Syn_All.position.y+POS_LABELMONEY_ADD_Y+20);
	}else{
		labelMoney.position = ccp(bt_Syn_All.position.x-POS_LABELMONEY_ADD_X,bt_Syn_All.position.y+POS_LABELMONEY_ADD_Y);
	}
	
	////所需银币图标
	ISCard *cardMoney = [ISCard node];
	[self addChild:cardMoney z:3 tag:ItemSynthesizeTag_SpriteMoney];
	cardMoney.position = ccp(labelMoney.position.x,labelMoney.position.y+cardMoney.contentSize.height/2+POS_CARDMONEY_ADD_Y);
    
    if (iPhoneRuningOnGame()) {
        labelResult.scale = 0.7;
        labelNeed.scale= 0.7;
        labelMoney.scale= 0.7;
        
    }
	
    [self setItemWithTag:ItemSynthesizeTag_YuEr];
}
-(void)onExit{
	
	if(levelMenus){
		[levelMenus release];
		levelMenus = nil;
	}
	if(menuItems){
		[menuItems release];
		menuItems = nil;
	}
	[GameConnection freeRequest:self];
	[super onExit];
}
-(NSArray*)getNameArrayWithItemTag:(NSInteger)tag{
	NSArray *nameArr;
	switch (tag) {
//		case ItemSynthesizeTag_BingFu:{
//			nameArr = [NSArray arrayWithObjects:@"中级兵符",@"高级兵符",nil];
//		}
//			break;
		case ItemSynthesizeTag_YuEr:{
			//nameArr = [NSArray arrayWithObjects:@"中级鱼饵",@"高级鱼饵",nil];
            nameArr = [NSArray arrayWithObjects:NSLocalizedString(@"item_synthesize_fish_middle",nil),NSLocalizedString(@"item_synthesize_fish_height",nil),nil];
		}
			break;
		case ItemSynthesizeTag_XuanTie:{
			//nameArr = [NSArray arrayWithObjects:@"中级玄铁",@"高级玄铁",@"特级玄铁",@"至尊玄铁",nil];
            nameArr = [NSArray arrayWithObjects:NSLocalizedString(@"item_synthesize_mining_middle",nil),
                       NSLocalizedString(@"item_synthesize_mining_height",nil),
                       NSLocalizedString(@"item_synthesize_mining_specialties",nil),
                       NSLocalizedString(@"item_synthesize_mining_imperial",nil),
                       nil];
		}
			break;
		default:
			nameArr = nil;
			break;
	}
	return nameArr;
}
-(NSString*)getNameArrayWithItemTag:(NSInteger)itemTag levelTag:(NSInteger)levelTag{
    NSArray *nameArr = [self getNameArrayWithItemTag:itemTag];
    return [nameArr objectAtIndex:levelTag];
}
-(NSArray*)getNeedNameArrayWithItemTag:(NSInteger)tag{
	NSArray *nameArr;
	switch (tag) {
//		case ItemSynthesizeTag_BingFu:{
//			nameArr = [NSArray arrayWithObjects:@"初级兵符",@"中级兵符",nil];
//		}
//			break;
		case ItemSynthesizeTag_YuEr:{
			//nameArr = [NSArray arrayWithObjects:@"初级鱼饵",@"中级鱼饵",nil];
            nameArr = [NSArray arrayWithObjects:NSLocalizedString(@"item_synthesize_fish_elementary",nil),
                       NSLocalizedString(@"item_synthesize_fish_middle",nil),
                       nil];
		}
			break;
		case ItemSynthesizeTag_XuanTie:{
			//nameArr = [NSArray arrayWithObjects:@"初级玄铁",@"中级玄铁",@"高级玄铁",@"特级玄铁",nil];
            nameArr = [NSArray arrayWithObjects:NSLocalizedString(@"item_synthesize_mining_elementary",nil),
                       NSLocalizedString(@"item_synthesize_mining_middle",nil),
                       NSLocalizedString(@"item_synthesize_mining_height",nil),
                       NSLocalizedString(@"item_synthesize_mining_specialties",nil),
                      
                       nil];
		}
			break;
		default:
			nameArr = nil;
			break;
	}
	return nameArr;
}
-(NSString*)getNeedNameArrayWithItemTag:(NSInteger)itemTag levelTag:(NSInteger)levelTag{
    NSArray *nameArr = [self getNeedNameArrayWithItemTag:itemTag];
	return [nameArr objectAtIndex:levelTag];
}
-(NSString *)getTypeStringWithItemTag:(NSInteger)itemTag{
	switch (itemTag) {
		//case ItemSynthesizeTag_BingFu:{return @"兵符";}break;
		//case ItemSynthesizeTag_YuEr:{return @"鱼饵";}break;
		//case ItemSynthesizeTag_XuanTie:{return @"玄铁";}break;
        case ItemSynthesizeTag_YuEr:{return NSLocalizedString(@"item_synthesize_fish",nil);}break;
		case ItemSynthesizeTag_XuanTie:{return NSLocalizedString(@"item_synthesize_mining",nil);}break;
		default:
			break;
	}
	return nil;
}
-(NSInteger)getQualityWithLevelTag:(NSInteger)levelTag{
	switch (levelTag) {
		case 0:{return IQ_BLUE;}break;
		case 1:{return IQ_PURPLE;}break;
		case 2:{return IQ_ORANGE;}break;
        case 3:{return IQ_RED;}break;
		default:
			break;
	}
	return 0;
}
-(void)updateResultLableWithItemTag:(NSInteger)itemTag LeveTag:(NSInteger)leveTag{
	
	currentItemTag = itemTag;
	currentLevelTag = leveTag;
	
	NSNumber *countNumber;
	NSNumber *desIDNumber;
	NSNumber *needIDNumber;
	NSNumber *coin1Number;
	NSNumber *coin2Number;
	NSNumber *coin3Number;
	
    int quality = [self getQualityWithLevelTag:leveTag];
	NSDictionary *dict = [self getSynthesizeDictWithName:[self getTypeStringWithItemTag:itemTag ] quality:quality];
	if (!dict) {
		CCLOG(@"dict is nil");
	}
	countNumber = [dict objectForKey:@"count"];
	desIDNumber = [dict objectForKey:@"desId"];
	needIDNumber = [dict objectForKey:@"srcId"];
	coin1Number = [dict objectForKey:@"coin1"];
	coin2Number = [dict objectForKey:@"coin2"];
	coin3Number = [dict objectForKey:@"coin3"];
	
	needValue = [countNumber intValue];
	desId = [desIDNumber intValue];
	needId = [needIDNumber intValue];
	
	NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
	
	CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:ItemSynthesizeTag_LabelResult];
	[label setString:[self getNameArrayWithItemTag:itemTag levelTag:leveTag]];
    label.color = getColorByQuality(quality);
	//
	label = (CCLabelTTF *)[self getChildByTag:ItemSynthesizeTag_LabelNeed];
	[label setString:[NSString stringWithFormat:@"%@ x%d",[self getNeedNameArrayWithItemTag:itemTag levelTag:leveTag],needValue]];
    label.color = getColorByQuality(quality-1);
	
	ISCard *resultSpr = (ISCard *)[ self getChildByTag: ItemSynthesizeTag_SpriteResult];
	[resultSpr changeItemWithFid:[desIDNumber intValue]];
	//
	ISCard *moneySpr = (ISCard *)[ self getChildByTag: ItemSynthesizeTag_SpriteMoney];
	if ([coin2Number intValue]>0) {
		//[moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:@"元宝"]];
        [moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:NSLocalizedString(@"item_synthesize_coin2",nil)]];
		needMoney = [coin2Number intValue];
		moneyAllValue = [[playerInfo objectForKey:@"coin2"] intValue];
	}else if([coin3Number intValue]>0){
		//[moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:@"绑定"]];
        [moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:NSLocalizedString(@"item_synthesize_coin3",nil)]];
		needMoney = [coin3Number intValue];
		moneyAllValue = [[playerInfo objectForKey:@"coin3"] intValue];
	}else{
		//[moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:@"银币"]];
        [moneySpr changeItemWithFid:[[GameConfigure shared] getItemIdByName:NSLocalizedString(@"item_synthesize_coin1",nil)]];
		needMoney = [coin1Number intValue];
		moneyAllValue = [[playerInfo objectForKey:@"coin1"] intValue];
	}
	label = (CCLabelTTF *)[self getChildByTag:ItemSynthesizeTag_LabelMoney];
	[label setString:[NSString stringWithFormat:@"%d",needMoney]];
	
	needAllValue = [self getItemCountWithID:[needIDNumber intValue]];
	ISCard *needSpr = (ISCard *)[ self getChildByTag: ItemSynthesizeTag_SpriteNeed];
	[needSpr changeItemWithFid:[needIDNumber intValue]];
	[needSpr setItemCount:needAllValue];
}

// 设置二级目录
-(void)setLevelItemWithTag:(NSInteger)tag
{
    for (CCMenu *m in levelMenus) {
        m.visible = NO;
    }
    
    CCMenu *m = (CCMenu *)[self getChildByTag:tag];
    if (m) {
        m.visible = YES;
    } else {
        NSArray *array = [self getNameArrayWithItemTag:tag];
        m = [CCMenu menuWithItems: nil];
        m.tag = tag;
        m.position = CGPointZero;
		CGPoint pos = [menu getChildByTag:ItemSynthesizeTag_YuEr].position;
        int i = 0;
        for (NSString *string in array) {
			NSArray *items;
			if (iPhoneRuningOnGame())
			{
            items = [self getToggleButton:@"images/ui/panel/t21.png" path2:@"images/ui/panel/t22.png" label:string fontSize:12 color1:ccc4(49,15,7,255) color2:ccc4(49,15,7,255) size:CGSizeMake(100, 40)];
			}
			else{
			items = [self getToggleButton:@"images/ui/panel/t21.png" path2:@"images/ui/panel/t22.png" label:string fontSize:22 color1:ccc4(49,15,7,255) color2:ccc4(49,15,7,255) size:CGSizeMake(170, 64)];
			}
            CCMenuItem *menuItem = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuLevelCallbackBack:) items:[items objectAtIndex:0], [items objectAtIndex:1], nil];
            menuItem.tag = i;
            if (iPhoneRuningOnGame()) {
                menuItem.position = ccp(322/2 +65, pos.y -86/2*i);
            }else{
                menuItem.position = ccp(323, 424-71*i);
			}
            [m addChild:menuItem];
            i++;
        }
        [self addChild:m];
        [levelMenus addObject:m];
    }
    
    // 默认第一个
    for (CCMenuItemToggle *menuItem in m.children) {
        if (menuItem.tag != 0) {
            [menuItem setSelectedIndex:0];
        } else {
            [menuItem setSelectedIndex:1];
            [self updateResultLableWithItemTag:m.tag LeveTag:menuItem.tag];
        }
    }
}

// 设置一级目录
-(void)setItemWithTag:(NSInteger)tag
{
    for (CCMenuItemToggle *menuItem in menuItems) {
        if (menuItem.tag != tag) {
            [menuItem setSelectedIndex:0];
        } else {
            [menuItem setSelectedIndex:1];
            CCSprite *dirSpr = (CCSprite *)[self getChildByTag:ItemSynthesizeTag_Dir];
			if (iPhoneRuningOnGame()) {
				dirSpr.position = ccp(dirSpr.position.x, menuItem.position.y);
			}else{
			dirSpr.position = ccp(dirSpr.position.x, menuItem.position.y);
			}
        }
    }
    [self setLevelItemWithTag:tag];
}

-(void)updateLevelLabelWithItemTag:(NSInteger)tag{
	NSArray *nameArr;
	nameArr = [self getNameArrayWithItemTag:tag];
	CCLOG(@"update level count %d", nameArr.count);
	if (nameArr) {
		for (int j=0;j < nameArr.count;j++) {
			////
			CCLabelTTF *label_level = (CCLabelTTF *)[self getChildByTag:ItemSynthesizeTag_LevelLabel01+j];
			[label_level setString:[nameArr objectAtIndex:j]];
		}
	}
}

-(NSArray*)getToggleButton:(NSString*) path1 path2:(NSString *)path2  label:(NSString*)label fontSize:(float) fontSize color1:(ccColor4B )c1 color2:(ccColor4B)c2 size:(CGSize) size{
	
	CCSprite *spr01 = [CCSprite spriteWithFile:path1];
	CCSprite *spr02 = [CCSprite spriteWithFile:path2];
	
	spr01 = getSpriteWithSpriteAndNewSize(spr01, size);
	spr02 = getSpriteWithSpriteAndNewSize(spr02, size);
	if (label) {
		CCLabelTTF *label01 = [CCLabelTTF labelWithString:label fontName:@"Verdana-Bold"  fontSize:fontSize];
		CCLabelTTF *label02 = [CCLabelTTF labelWithString:label fontName:@"Verdana-Bold"  fontSize:fontSize];
		[label01 setColor:ccc3(c1.r, c1.g, c1.b)];
		[label02 setColor:ccc3(c2.r, c2.g, c2.b)];
		
		[spr01 addChild:label01];
		label01.position = ccp(spr01.contentSize.width/2, spr01.contentSize.height/2);
		
		[spr02 addChild:label02];
		label02.position = ccp(spr02.contentSize.width/2, spr02.contentSize.height/2);
	}
	CCMenuItemSprite *bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:spr01 selectedSprite:nil];
	CCMenuItemSprite *bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:spr02 selectedSprite:nil];
	
	return [NSArray arrayWithObjects:bt_spr01,bt_spr02,nil];
}

-(void)menuCallbackBack: (id) sender{
	CCNode *obj = sender;
	if(obj.tag == BT_IS_SYNTHESIZE_TAG){
		[self  synthesizeItemWithValue:BT_IS_SYNTHESIZE_TAG];
	}else if(obj.tag == BT_IS_SYNTHESIZE_ALL_TAG){
		[self  synthesizeItemWithValue:BT_IS_SYNTHESIZE_ALL_TAG];
	}
//	else if(obj.tag == ItemSynthesizeTag_BingFu){
//        [self setItemWithTag:obj.tag];
//		CCLOG(@"ItemSynthesizeTag_BingFu");
//	}
	else if(obj.tag == ItemSynthesizeTag_YuEr){
        [self setItemWithTag:obj.tag];
		CCLOG(@"ItemSynthesizeTag_YuEr");
	}else if(obj.tag == ItemSynthesizeTag_XuanTie){
        [self setItemWithTag:obj.tag];
	}
}

-(void)menuLevelCallbackBack:(id)sender{
    CCMenuItemToggle *menuItem = sender;
    CCMenu *m = (CCMenu *)menuItem.parent;
    int menuTag = m.tag;
    int menuItemTag = menuItem.tag;
    
    for (CCMenuItemToggle *item in m.children) {
        [item setSelectedIndex:0];
    }
    [menuItem setSelectedIndex:1];
    
    [self updateResultLableWithItemTag:menuTag LeveTag:menuItemTag];
}

-(NSDictionary*)getSynthesizeDictWithName:(NSString *)nameStr quality:(ItemQuality) quality{
	NSDictionary *itemDict;
	NSNumber *qualityNumber;
	
	NSDictionary *dict = [[GameDB shared] getFusionTable];
	if (!dict) {
		CCLOG(@"error: get fusion table is nil");
		return nil;
	}
	NSArray *KEYS = [dict allKeys];
	
	for (NSString *key in KEYS) {
		NSDictionary *info = [dict objectForKey:key];
		NSString *typeStr = [info objectForKey:@"type"];
		if (!typeStr) {
			CCLOG(@"error: type is nil ");
			return nil;
		}
		if ([typeStr isEqualToString:nameStr]) {
			int desID = [[info objectForKey:@"desId"] intValue];
			if (desID<=0) {
				CCLOG(@"error: des id <0 ");
				return nil;
			}
			itemDict = [[GameDB shared] getItemInfo:desID];
			qualityNumber = [itemDict objectForKey:@"quality"];
			
			if ([qualityNumber intValue] == quality ) {
				CCLOG(@"finish");
				return info;
			}
		}
	}
	return nil;
}

-(NSInteger)getItemCountWithID:(NSInteger)itemID{
	NSArray *itemArray;
	NSDictionary *itemDict;
	NSNumber *idNumber;
	NSNumber *countNumber;
	NSNumber *isTradeNumber;
	NSInteger count = 0 ;
	
	CCMenuItemToggle *toggle = (CCMenuItemToggle *)[menu getChildByTag:BTT_GX_NO_HIDE_DEAL_TAG];
	[toggle selectedIndex];
	
	
	itemArray = [[GameConfigure shared] getPlayerItemList];
	if (!itemArray) {
		CCLOG(@"error:player item list  is nil");
		return 0;
	}
	for (itemDict in itemArray) {
		idNumber = [itemDict objectForKey:@"iid"];
		if ([idNumber intValue]<=0) {
			CCLOG(@"error:item id <= 0");
			return 0;
		}else if ([idNumber intValue] == itemID ) {
			if ( 1 == [toggle selectedIndex]) {
				isTradeNumber = [itemDict objectForKey:@"isTrade"];
				if ( TradeStatus_no== isTradeNumber) {
					continue;
				}
			}
			countNumber = [itemDict objectForKey:@"count"];
			if (!countNumber) {
				CCLOG(@"error:item count is nil");
			}
			count += [countNumber intValue];
		}
	}
	return count;
}

-(void)didFusion:(NSDictionary *)sender
{
	if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
			//[ShowItem showItemAct:@"合成成功"];
			[ShowItem showItemAct:NSLocalizedString(@"item_synthesize_ok",nil)];
			// 更新背包
            [[GameConfigure shared] updatePackage:dict];
			
			// 更新数据
			[self updateResultLableWithItemTag:currentItemTag LeveTag:currentLevelTag];
        }
        
    } else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(void)gameConnection
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:desId] forKey:@"desId"];
	[dict setObject:[NSNumber numberWithInt:fusionValue] forKey:@"count"];
	[dict setObject:[NSNumber numberWithInt:needId] forKey:@"srcId"];
	[GameConnection request:@"mergeItem" data:dict target:self call:@selector(didFusion:)];
}

-(void)synthesizeItemWithValue:(NSInteger)tag{
	
	if (needAllValue < needValue || moneyAllValue < needMoney) {
		//[ShowItem showItemAct:@"材料不足"];
        [ShowItem showItemAct:NSLocalizedString(@"item_synthesize_no_material",nil)];
		return;
	}
	fusionValue = 0;
	if (tag == BT_IS_SYNTHESIZE_TAG) {
		fusionValue = 1;
	} else if (tag == BT_IS_SYNTHESIZE_ALL_TAG) {
		fusionValue = MIN(needAllValue / needValue,
						  moneyAllValue / needMoney);
	}
	
	// 数据
	NSDictionary *needDict = [[GameDB shared] getItemInfo:needId];
	NSDictionary *desDict = [[GameDB shared] getItemInfo:desId];
	
	if (needDict && desDict) {
		NSString *needName = [needDict objectForKey:@"name"];
		NSString *desName = [desDict objectForKey:@"name"];
		int needQuality = [[needDict objectForKey:@"quality"] intValue];
		int desQuality = [[desDict objectForKey:@"quality"] intValue];
		
		BOOL isRecordFusion = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_FUSION] boolValue];
		if (isRecordFusion) {
			[self gameConnection];
		} else {
			//NSString *message = [NSString stringWithFormat:@"是否消耗%d个 |%@%@| 和%d银币，合成出%d个|%@%@", fusionValue*needValue, needName,getHexStringWithColor3B(getColorByQuality(needQuality)), fusionValue*needMoney, fusionValue, desName, getHexStringWithColor3B(getColorByQuality(desQuality))];
			NSString *message = [NSString stringWithFormat:NSLocalizedString(@"item_synthesize_no_spend",nil), fusionValue*needValue, needName,getHexStringWithColor3B(getColorByQuality(needQuality)), fusionValue*needMoney, fusionValue, desName, getHexStringWithColor3B(getColorByQuality(desQuality))];
			[[AlertManager shared] showMessageWithSettingFormFather:message target:self confirm:@selector(gameConnection) key:NO_REMIND_FUSION father:self];
		}
	}
}

@end
