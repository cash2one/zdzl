//
//  DragonRank.m
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "DragonRank.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "CCPanel.h"
#import "UnionConfig.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "MessageBox.h"

#define DRAGONRANK_LINE_W (25)
#define DRAGONRANK_LINE_H (20)
#define DRAGONRANK_BUTTON_PRI (255)
#define DRAGONRANK_PANEL_H (280)
#define DRAGONRANK_PANEL_OFF_H (15)
//
static BOOL s_bDragonRankSend = NO;

#pragma mark -
#pragma mark rank item
typedef enum{
    RIVT_int = 1,
    RIVT_float,
    RIVT_string,
}RankItemValueType;

@interface RankItemStruct : NSObject{
    int RIVType;
    int len;
    int fontSize;
    ccColor4B color;
    NSObject *data;
}
+(RankItemStruct*)rankItemStructWithType:(int)type len:(int)len data:(NSObject*)data;
-(NSString*)getItemString;
@property(nonatomic,assign) int RIVType;
@property(nonatomic,assign) int len;
@property(nonatomic,assign) int fontSize;
@property(nonatomic,assign) ccColor4B color;
@property(nonatomic,retain) NSObject *data;
@end
@implementation RankItemStruct
@synthesize RIVType;
@synthesize len;
@synthesize fontSize;
@synthesize color;
@synthesize data;
-(id)init{
    if ((self = [super init]) != NULL) {
        RIVType = RIVT_string;
        len = 0;
        data = NULL;
        fontSize = 18;
        //color = ccc4(230, 180, 60, 255);
        color = ccc4(230, 230, 230, 255);
    }
    return self;
}
-(void)dealloc{
    if (data) {
        [data release];
        data = NULL;
    }
    [super dealloc];
}
+(RankItemStruct*)rankItemStructWithType:(int)type len:(int)len data:(NSObject*)data{
    if (data) {
        RankItemStruct *node = [[RankItemStruct alloc] autorelease];
        node.RIVType = type;
        node.fontSize = 18;
        node.len = len;
        node.data = data;
        node.color = ccc4(230, 230, 230, 255);
        return node;
    }else{
        CCLOG(@"---number is null!");
        return NULL;
    }
}
-(NSString*)getItemString{
    NSString *str = @"";
    if (data) {
        if (RIVType == RIVT_int) {
            str = [NSString stringWithFormat:@"%d",[(NSNumber*)data intValue]];
        }else if(RIVType == RIVT_float){
            str = [NSString stringWithFormat:@"%.2f",[(NSNumber*)data floatValue]];
        }else if(RIVType == RIVT_string){
            str = [NSString stringWithFormat:@"%@",data];
        }
    }
    return str;
}
@end

#pragma mark -
#pragma mark rank item
@interface DragonRankItem : CCNode {
    int rankValue;
}
@property (nonatomic,assign) int rankValue;
-(void)setRIStructArrayWithArray:(NSArray*)RankItemStruct_array BGPath:(NSString*)file;
-(void)setRIStructArrayWithArray:(NSArray*)RankItemStruct_array BGPath:(NSString*)file BGSize:(CGSize)size;
@end

@implementation DragonRankItem
@synthesize rankValue;
-(id)init{
    if ((self = [super init]) != NULL) {
        self.contentSize = CGSizeMake(cFixedScale(524), cFixedScale(30));
    }
    return self;
}
-(void)setRIStructArrayWithArray:(NSArray *)RankItemStruct_array BGPath:(NSString*)file{
    [self removeAllChildrenWithCleanup:YES];
    if (file) {
        CCSprite *spr_ = [CCSprite spriteWithFile:file];
        if (spr_) {
            [spr_ setAnchorPoint:ccp(0,0.5)];
            self.contentSize= spr_.contentSize;
            [self addChild:spr_];
            [spr_ setPosition:ccp(0,0)];
        }else{
            CCLOG(@"---load sprite is null!");
        }
    }else{
        CCLOG(@"----file is null!");
    }
    //
    [self setRIStructArrayWithArray:RankItemStruct_array];
    /*
    if (RankItemStruct_array && [RankItemStruct_array count]>0) {
        CGPoint pos = ccp(0, 0);
        int len = 0;
        //
        RankItemStruct *t_ris = [RankItemStruct_array objectAtIndex:0];
        if ([t_ris RIVType] == RIVT_int) {
            NSNumber *number = (NSNumber *)t_ris.data;
           rankValue = [number intValue];
        }
        //
        for (RankItemStruct *node_ in RankItemStruct_array) {
                CCLabelFX *label = [CCLabelFX labelWithString:[node_ getItemString]
                                                       dimensions:CGSizeMake(0,0)
                                                        alignment:kCCTextAlignmentLeft
                                                         fontName:getCommonFontName(FONT_1)
                                                         fontSize:21
                                                     shadowOffset:CGSizeMake(-0.5, -0.5)
                                                       shadowBlur:1.0f
                                                      shadowColor:ccc4(160,100,20, 128)
                                                        fillColor:node_.color];
            [self addChild:label];
            pos.x += (len/2+node_.len/2);
            label.position = pos;
            len = node_.len;
        }
    }
     */
}
-(void)setRIStructArrayWithArray:(NSArray*)RankItemStruct_array BGPath:(NSString*)file BGSize:(CGSize)size{
    [self removeAllChildrenWithCleanup:YES];
    if (file) {
        CCSprite *spr_ = [CCSprite spriteWithFile:file];
        spr_ = getSpriteWithSpriteAndNewSize(spr_, size);
        if (spr_) {
            [spr_ setAnchorPoint:ccp(0,0.5)];
            self.contentSize= spr_.contentSize;
            [self addChild:spr_];
            [spr_ setPosition:ccp(0,0)];
        }else{
            CCLOG(@"---load sprite is null!");
        }
    }else{
        CCLOG(@"----file is null!");
    }
    //
    [self setRIStructArrayWithArray:RankItemStruct_array];
}
-(void)setRIStructArrayWithArray:(NSArray *)RankItemStruct_array{
    //
    if (RankItemStruct_array && [RankItemStruct_array count]>0) {
        CGPoint pos = ccp(0, 0);
        int len = 0;
        //
        RankItemStruct *t_ris = [RankItemStruct_array objectAtIndex:0];
        if ([t_ris RIVType] == RIVT_int) {
            NSNumber *number = (NSNumber *)t_ris.data;
            rankValue = [number intValue];
        }
        //
        for (RankItemStruct *node_ in RankItemStruct_array) {
            CCLabelFX *label = [CCLabelFX labelWithString:[node_ getItemString]
                                               dimensions:CGSizeMake(0,0)
                                                alignment:kCCTextAlignmentLeft
                                                 fontName:getCommonFontName(FONT_1)
                                                 fontSize:[node_ fontSize]
                                             shadowOffset:CGSizeMake(-0.5, -0.5)
                                               shadowBlur:1.0f
                                              shadowColor:ccc4(160,100,20, 128)
                                                fillColor:node_.color];
            [self addChild:label];
            pos.x += (len/2+node_.len/2);
            label.position = pos;
            len = node_.len;
        }
    }
}
-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

@end

//------------
int sortDragonRank(DragonRankItem *p1, DragonRankItem*p2, void*context){
	if(p1.rankValue<p2.rankValue) return NSOrderedAscending;
	if(p1.rankValue>p2.rankValue) return NSOrderedDescending;
	return NSOrderedSame;
}
//-------------
#pragma mark -
#pragma mark union rank

@implementation DragonUnionRank
enum{
    DragonUnionRank_bg_tag = 1,
    DragonUnionRank_icon_tag,
    DragonUnionRank_npc_text_tag,
    DragonUnionRank_npc_text2_tag,
    DragonUnionRank_rank_text_tag,
    DragonUnionRank_button_tag,
    DragonUnionRank_item_tag,
    DragonUnionRank_itemPanel_tag,
};
@synthesize rankValue;

-(NSString*)getBackgroundPath{
	return @"images/ui/panel/p5.png";
}

-(NSString*)getCaptionPath{
	return @"images/ui/panel/t82.png";
}
-(id)init{
    if ((self = [super init])!=nil) {
        rankValue = 0;
        currentPageCount = 1;
        mutItemArray = [NSMutableArray array];
        [mutItemArray retain];
    }
    return self;
}
-(void)dealloc{
    if (mutItemArray) {
        [mutItemArray removeAllObjects];
        [mutItemArray release];
        mutItemArray = NULL;
    }
    [super dealloc];
}
-(void)onEnter{
	[super onEnter];
    //
    s_bDragonRankSend = NO;
    
    [self loadWindow];
    [self loadText];
}

-(void)closeWindow{
    s_bDragonRankSend = YES;
	[super closeWindow];
}

-(void)onExit{
    //
    s_bDragonRankSend = NO;
    
	[super onExit];
}
-(void)loadText{
    [self removeChildByTag:DragonUnionRank_item_tag cleanup:YES];
    //
    RankItemStruct *node_rank = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(100) data:NSLocalizedString(@"dragon_rank_rank",nil)];
    RankItemStruct *node_name = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(256) data:NSLocalizedString(@"dragon_rank_name",nil)];
    RankItemStruct *node_job = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(220) data:NSLocalizedString(@"dragon_rank_job",nil)];
    RankItemStruct *node_donate = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(220) data:NSLocalizedString(@"dragon_rank_donate",nil)];
    node_rank.color = node_name.color  = node_job.color = node_donate.color = ccc4(62, 22, 12, 255);
    NSArray *array=[NSArray arrayWithObjects:node_rank,node_name,node_job,node_donate, nil];
    DragonRankItem *item = [DragonRankItem node];
    //[item setRIStructArrayWithArray:array BGPath:@"images/ui/panel/t63.png"];
    [item setRIStructArrayWithArray:array BGPath:@"images/ui/panel/columnTop-1.png" BGSize:CGSizeMake(cFixedScale(793), cFixedScale(30))];
    [self addChild:item];
    item.tag = DragonUnionRank_item_tag;
    item.position = ccp(cFixedScale(DRAGONRANK_LINE_W*2-10),cFixedScale(378));
    //
    //[self loadRecordWithArray:[self getArrayData]];
    [self loadRankData];
}

-(void)loadRankData{
    NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
    //[dict_ setValue:[NSNumber numberWithInt:currentPageCount] forKey:@"page"];
    [GameConnection request:@"allyInGloryRank" data:dict_ target:self call:@selector(didInGloryRank:)];
}

-(void)didInGloryRank:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
            NSArray *array_ = (NSArray *)dict;
            [self loadRecordWithArray:[self getArrayDataWithDictArray:array_]];
        }
    } else {
        CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        [[Window shared] removeWindow:PANEL_UNION_Dragon_Union_Rank];
    }
    
}

-(NSArray*)getArrayDataWithDictArray:(NSArray*)dictArray_{
    NSMutableArray *mutArray = [NSMutableArray array];
    if (dictArray_ && [dictArray_ count]>0) {
        for (NSDictionary *dict_ in dictArray_) {
            RankItemStruct *node_rank = [RankItemStruct rankItemStructWithType:RIVT_int len:cFixedScale(100) data:[dict_ objectForKey:@"rk"]];
            RankItemStruct *node_name = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(256) data:[dict_ objectForKey:@"n"]];
            RankItemStruct *node_job = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(220) data:getJobName([[dict_ objectForKey:@"dt"] intValue])];
            RankItemStruct *node_donate = [RankItemStruct rankItemStructWithType:RIVT_int len:cFixedScale(220) data:[dict_ objectForKey:@"gy"]];
            NSArray *array=[NSArray arrayWithObjects:node_rank,node_name,node_job,node_donate, nil];
            if ([node_name.data isEqual:[[[RoleManager shared] player] name]]) {
                node_rank.color = node_name.color  = node_job.color = node_donate.color = ccc4(250, 225, 135, 255);
            }
            [mutArray addObject:array];
        }
    }
    return mutArray;
}
-(void)loadRecordWithArray:(NSArray*)array{
    NSMutableArray *mutArray = [NSMutableArray array];
    //
    if (array && [array count]>0) {
        for (NSArray *object_ in array) {
            if (object_ && [object_ count]>0) {
                DragonRankItem *item = [DragonRankItem node];
                [item setRIStructArrayWithArray:object_ BGPath:@"images/ui/panel/p14.png" BGSize:CGSizeMake(cFixedScale(793), cFixedScale(30))];
                [mutArray addObject:item];
            }

        }
    }
    //
    if (mutArray && [mutArray count]>0) {
        //
        [mutItemArray addObjectsFromArray:mutArray];
        [mutItemArray sortUsingFunction:sortDragonRank context:nil];
        //
        [self removeChildByTag:DragonUnionRank_itemPanel_tag cleanup:YES];
        //
        int w_ = [[mutItemArray objectAtIndex:0] contentSize].width;
        int h_ = ([mutItemArray count])*([[mutItemArray objectAtIndex:0] contentSize].height + cFixedScale(DRAGONRANK_PANEL_OFF_H));
        int UI_W = w_;
        int UI_H = cFixedScale(DRAGONRANK_PANEL_H);
        if (w_<UI_W) {
            w_ = UI_W;
        }
        if (h_<UI_H) {
            h_ = UI_H;
        }
        CCLayerColor *contentLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:w_ height:h_];
        CGPoint pos = ccp(0, h_ - cFixedScale(DRAGONRANK_PANEL_OFF_H) - [[mutItemArray objectAtIndex:0] contentSize].height/2);
        for (DragonRankItem *item_ in mutItemArray) {
            [item_ setPosition:pos];
            [contentLayer addChild:item_];
            pos.y -= (item_.contentSize.height + cFixedScale(DRAGONRANK_PANEL_OFF_H));
        }
        //------
        /*
        CCSimpleButton *moreButton = [CCSimpleButton spriteWithFile:@"images/ui/panel/t63.png" select:@"images/ui/panel/t63.png" target:self call:@selector(loadWithType:)];
        moreButton.anchorPoint = ccp(0, 0.5);
        
        //Kevin added
        int	iFontSize = 16;
        if (iPhoneRuningOnGame()) {
            iFontSize = 8;
        }
        //----------------//
        //CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:@"查看更多..." fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
        CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_read_much",nil) fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
        moreLabel.color = ccc3(238, 228, 207);
        moreLabel.position = ccp(moreButton.contentSize.width/2,
                                 moreButton.contentSize.height/2);
        [moreButton addChild:moreLabel];
        [moreButton setPosition:pos];
        [contentLayer addChild:moreButton];
         */
        //------
        CCPanel *newPanel = [CCPanel panelWithContent:contentLayer viewSize:CGSizeMake(UI_W, UI_H)];
        [newPanel showScrollBar:@"images/ui/common/scroll3.png"];
        newPanel.position = ccp(cFixedScale(DRAGONRANK_LINE_W*2-10), cFixedScale(80));
        [newPanel updateContentToTop:0];
        [self addChild:newPanel z:10 tag:DragonUnionRank_itemPanel_tag];
    }
}
/*
-(void)loadWithType:(CCNode*)node{
    if (node) {
        CCPanel* temp = (CCPanel*)node.parent.parent.parent;
        if (!temp.isTouchValid) {
            return;
        }
    }
    CCLOG(@"--dragon union load with type");
}
 */
-(void)loadWindow{
    //
    CCLayerColor *bg = (CCLayerColor *)[self getChildByTag:DragonUnionRank_bg_tag];
    if (bg) {
        [bg removeFromParentAndCleanup:YES];
        bg = NULL;
    }
    bg = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
    bg.contentSize = CGSizeMake(self.contentSize.width-cFixedScale(DRAGONRANK_LINE_W)*2, self.contentSize.height-cFixedScale(DRAGONRANK_LINE_H)*2-cFixedScale(47));
    //bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width-cFixedScale(DRAGONEXCHANGE_LINE_W)*2 height:self.contentSize.height-cFixedScale(DRAGONEXCHANGE_LINE_H)*2-cFixedScale(50) capx:cFixedScale(8) capy:cFixedScale(8)];
    
    bg.anchorPoint = ccp(0,0);
    [self addChild:bg];
    bg.tag = DragonUnionRank_bg_tag;
    bg.position = ccp(cFixedScale(DRAGONRANK_LINE_W),cFixedScale(DRAGONRANK_LINE_H));
    //
    CCSprite *icon = (CCSprite *)[self getChildByTag:DragonUnionRank_icon_tag];
    if (icon) {
        [icon removeFromParentAndCleanup:YES];
        icon = NULL;
    }
    //icon = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
    //icon = [CCSprite spriteWithFile:@"Icon-72.png"];
//    if (iPhoneRuningOnGame()) {
//		icon = [CCSprite spriteWithFile:@"images/ui/wback/t27.png"];
//	}else{
//		icon = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
//	}
    icon = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
    //
    CCSprite *icon_f = [CCSprite spriteWithFile:@"images/ui/dragon/player_team_change.png"];
    if (icon && icon_f) {
        [icon addChild:icon_f];
        //icon_f.scale = 1.3f;
        [icon_f setPosition:ccp(icon.contentSize.width/2, icon.contentSize.height/2)];
    }
    //
    [self addChild:icon];
    icon.anchorPoint = ccp(0,1);
    icon.position = ccp(0+cFixedScale(DRAGONRANK_LINE_W)*3,bg.contentSize.height-cFixedScale(DRAGONRANK_LINE_H/3));
    icon.tag = DragonUnionRank_icon_tag;
    //
    CCLabelFX *label_npc_text = (CCLabelFX *)[self getChildByTag:DragonUnionRank_npc_text_tag];
    if (NULL == label_npc_text) {
        label_npc_text = [CCLabelFX labelWithString:@""
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentLeft
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:18
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(160,100,20, 128)
                                          fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_npc_text];
        label_npc_text.tag = DragonUnionRank_npc_text_tag;
    }
    [label_npc_text setString:NSLocalizedString(@"dragon_rank_npc",nil)];
    label_npc_text.anchorPoint = ccp(0,0);
    label_npc_text.position = ccpAdd(icon.position,ccp(icon.contentSize.width+cFixedScale(18),-icon.contentSize.height/2+icon.contentSize.height/10));
    //
    CCLabelFX *label_npc_text2 = (CCLabelFX *)[self getChildByTag:DragonUnionRank_npc_text2_tag];
    if (NULL == label_npc_text2) {
        label_npc_text2 = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:18
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(0, 150, 255, 255)];
        [self addChild:label_npc_text2];
        label_npc_text2.tag = DragonUnionRank_npc_text2_tag;
    }
    [label_npc_text2 setString:NSLocalizedString(@"dragon_rank_text2",nil)];
    label_npc_text2.anchorPoint = ccp(0,1);
    label_npc_text2.position = ccpAdd(icon.position,ccp(icon.contentSize.width + cFixedScale(18),-icon.contentSize.height/2-icon.contentSize.height/10));
    //
    CCSimpleButton *button1 = (CCSimpleButton *)[self getChildByTag:DragonUnionRank_button_tag];
    if (NULL == button1) {
        button1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_return_1.png" select:@"images/ui/button/bts_return_2.png" invalid:@"images/ui/button/bts_return_3.png" target:self call:@selector(CallBack:)];
        button1.tag = DragonUnionRank_button_tag;
        button1.priority = DRAGONRANK_BUTTON_PRI;
        [self addChild:button1];
        [button1 setPosition:ccp(cFixedScale(DRAGONRANK_LINE_W*2)+button1.contentSize.width/2,button1.contentSize.height/2 + cFixedScale(DRAGONRANK_LINE_H*2))];
    }
    //
    /*
    NSString *str_rank = [NSString stringWithFormat:@"建设度排名100的盟友"];
    CCLabelFX *label_rank_text = (CCLabelFX *)[self getChildByTag:DragonUnionRank_rank_text_tag];
    if (NULL == label_rank_text) {
        label_rank_text = [CCLabelFX labelWithString:@""
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:21
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_rank_text];
        label_rank_text.tag = DragonUnionRank_rank_text_tag;
    }
    [label_rank_text setString:str_rank];
    label_rank_text.anchorPoint = ccp(1,0);
    label_rank_text.position = ccp(self.contentSize.width - DRAGONRANK_LINE_W,DRAGONRANK_LINE_H);
     */
}
-(void)CallBack:(CCNode*)node{
    CCLOG(@"---dragon union rank!");
    if (s_bDragonRankSend) {
        return;
    }
    s_bDragonRankSend = YES;
    [[Window shared] showWindow:PANEL_UNION_Dragon_Exchange];
}
@end
#pragma mark -
#pragma mark world rank

@implementation DragonWorldRank
enum{
    DragonWorldRank_bg_tag = 1,
    DragonWorldRank_icon_tag,
    DragonWorldRank_npc_text_tag,
    DragonWorldRank_npc_text2_tag,
    DragonWorldRank_rank_text_tag,
    DragonWorldRank_rank_text2_tag,
    DragonWorldRank_button_tag,
    DragonWorldRank_item_tag,
    DragonWorldRank_itemPanel_tag,
};
@synthesize rankValue;
-(NSString*)getBackgroundPath{
	return @"images/ui/panel/p5.png";
}

-(NSString*)getCaptionPath{
	return @"images/ui/panel/t82.png";
}
-(id)init{
    if ((self = [super init])!=nil) {
        rankValue = 0;
        currentPageCount = 1;
        mutItemArray = [NSMutableArray array];
        [mutItemArray retain];
    }
    return self;
}
-(void)dealloc{
    if (mutItemArray) {
        [mutItemArray removeAllObjects];
        [mutItemArray release];
        mutItemArray = NULL;
    }
    [super dealloc];
}
-(void)onEnter{
	[super onEnter];
    //
    s_bDragonRankSend = NO;
    
    [self loadWindow];
    [self loadText];
}

-(void)closeWindow{
    s_bDragonRankSend = YES;
	[super closeWindow];
}

-(void)onExit{
    //
    s_bDragonRankSend = NO;
    
	[super onExit];
}-(void)loadText{
    [self removeChildByTag:DragonWorldRank_item_tag cleanup:YES];
    //
    RankItemStruct *node_rank = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(120) data:NSLocalizedString(@"dragon_rank_rank",nil)];
    RankItemStruct *node_name = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:NSLocalizedString(@"dragon_rank_name",nil)];
    RankItemStruct *node_union = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:NSLocalizedString(@"dragon_rank_union",nil)];
    RankItemStruct *node_job = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:NSLocalizedString(@"dragon_rank_job",nil)];
    RankItemStruct *node_donate = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:NSLocalizedString(@"dragon_rank_donate",nil)];
    node_rank.color = node_name.color  = node_union.color = node_job.color = node_donate.color = ccc4(62, 22, 12, 255);
    NSArray *array=[NSArray arrayWithObjects:node_rank,node_name,node_union,node_job,node_donate, nil];
    DragonRankItem *item = [DragonRankItem node];
    //[item setRIStructArrayWithArray:array BGPath:@"images/ui/panel/t63.png"];
    [item setRIStructArrayWithArray:array BGPath:@"images/ui/panel/columnTop-1.png" BGSize:CGSizeMake(cFixedScale(793), cFixedScale(30))];
    [self addChild:item];
    item.tag = DragonWorldRank_item_tag;
    item.position = ccp(cFixedScale(DRAGONRANK_LINE_W*2-10),cFixedScale(378));
    //
    //[self loadRecordWithArray:[self getArrayData]];
    [self loadRankData];
}

-(void)loadRankData{
    NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
    [dict_ setValue:[NSNumber numberWithInt:currentPageCount] forKey:@"page"];
    [GameConnection request:@"allyAllGloryRank" data:dict_ target:self call:@selector(didAllGloryRank:)];
}

-(void)didAllGloryRank:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
            NSArray *array_ = (NSArray *)[dict objectForKey:@"l"];
            rankValue = [[dict objectForKey:@"prk"] intValue];
            [self loadRecordWithArray:[self getArrayDataWithDictArray:array_]];
            //
            [self setRankValue:rankValue];
        }
    } else {
        CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        [[Window shared] removeWindow:PANEL_UNION_Dragon_World_Rank];
    }
    
    s_bDragonRankSend = NO;
}

-(NSArray*)getArrayDataWithDictArray:(NSArray*)dictArray_{
    NSMutableArray *mutArray = [NSMutableArray array];
    if (dictArray_ && [dictArray_ count]>0) {
        for (NSDictionary *dict_ in dictArray_) {
            RankItemStruct *node_rank = [RankItemStruct rankItemStructWithType:RIVT_int len:cFixedScale(120) data:[dict_ objectForKey:@"rk"]];
            RankItemStruct *node_name = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:[dict_ objectForKey:@"n"]];
            RankItemStruct *node_union = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:[dict_ objectForKey:@"an"]];
            RankItemStruct *node_job = [RankItemStruct rankItemStructWithType:RIVT_string len:cFixedScale(160) data:getJobName([[dict_ objectForKey:@"dt"] intValue])];
            RankItemStruct *node_donate = [RankItemStruct rankItemStructWithType:RIVT_int len:cFixedScale(160) data:[dict_ objectForKey:@"gy"]];
            NSArray *array=[NSArray arrayWithObjects:node_rank,node_name,node_union,node_job,node_donate, nil];
            if ([node_name.data isEqual:[[[RoleManager shared] player] name]]) {
                node_rank.color = node_name.color = node_union.color = node_job.color = node_donate.color = ccc4(250, 225, 135, 255);
            }
            [mutArray addObject:array];
        }
    }
    
    return mutArray;
}
-(void)loadRecordWithArray:(NSArray*)array{
    NSMutableArray *mutArray = [NSMutableArray array];
    //
    if (array && [array count]>0) {
        for (NSArray *object_ in array) {
            if (object_ && [object_ count]>0) {
                DragonRankItem *item = [DragonRankItem node];
                [item setRIStructArrayWithArray:object_ BGPath:@"images/ui/panel/p14.png" BGSize:CGSizeMake(cFixedScale(793), cFixedScale(30))];
                [mutArray addObject:item];
            }
            
        }
    }
    //
    if (mutArray && [mutArray count]>0) {
        [mutItemArray addObjectsFromArray:mutArray];
        [mutItemArray sortUsingFunction:sortDragonRank context:nil];
        //
        [self removeChildByTag:DragonWorldRank_itemPanel_tag cleanup:YES];
        //
        int w_ = [[mutItemArray objectAtIndex:0] contentSize].width;
        int h_ = ([mutItemArray count]+1)*([[mutItemArray objectAtIndex:0] contentSize].height + cFixedScale(DRAGONRANK_PANEL_OFF_H));
        int UI_W = w_;
        int UI_H = cFixedScale(DRAGONRANK_PANEL_H);
        if (w_<UI_W) {
            w_ = UI_W;
        }
        if (h_<UI_H) {
            h_ = UI_H;
        }
        CCLayerColor *contentLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:w_ height:h_];
        CGPoint pos = ccp(0, h_ - cFixedScale(DRAGONRANK_PANEL_OFF_H) -[[mutItemArray objectAtIndex:0] contentSize].height/2);
        for (DragonRankItem *item_ in mutItemArray) {
            [item_ setPosition:pos];
            [contentLayer addChild:item_];
            pos.y -= (item_.contentSize.height + cFixedScale(DRAGONRANK_PANEL_OFF_H));
        }
        //------
        //CCSimpleButton *moreButton = [CCSimpleButton spriteWithFile:@"images/ui/panel/p14.png" select:@"images/ui/panel/p14.png" target:self call:@selector(loadWithType:)];
        CCSimpleButton *moreButton = [CCSimpleButton node];
        moreButton.contentSize = CGSizeMake(cFixedScale(793), cFixedScale(30));
        CCSprite *spr_ = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
        [moreButton setNormalSprite:getSpriteWithSpriteAndNewSize(spr_, CGSizeMake(cFixedScale(793), cFixedScale(30)))];
        //
        spr_ = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
        [moreButton setSelectSprite:getSpriteWithSpriteAndNewSize(spr_, CGSizeMake(cFixedScale(793), cFixedScale(35)))];
        //
        moreButton.anchorPoint = ccp(0, 0.5);
        moreButton.target = self;
        moreButton.call = @selector(loadWithType:);
        
        //Kevin added
        int	iFontSize = 16;
        if (iPhoneRuningOnGame()) {
            iFontSize = 8;
        }
        //----------------//
        //CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:@"查看更多..." fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
        CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_read_much",nil) fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
        moreLabel.color = ccc3(238, 228, 207);
        moreLabel.position = ccp(moreButton.contentSize.width/2,
                                 moreButton.contentSize.height/2);
        [moreButton addChild:moreLabel];
        [moreButton setPosition:pos];
        [contentLayer addChild:moreButton];
        //------
        CCPanel *newPanel = [CCPanel panelWithContent:contentLayer viewSize:CGSizeMake(UI_W, UI_H)];
        [newPanel showScrollBar:@"images/ui/common/scroll3.png"];
        newPanel.position = ccp(cFixedScale(DRAGONRANK_LINE_W*2-10), cFixedScale(80));
        [newPanel updateContentToTop:0];
        [self addChild:newPanel z:10 tag:DragonWorldRank_itemPanel_tag];
    }
}
-(void)loadWithType:(CCNode*)node{
    if (s_bDragonRankSend) {
        return;
    }
  
    if (node) {
        /*
        CCPanel* temp = (CCPanel*)node.parent.parent.parent;
        if (!temp.isTouchValid) {
            return;
        }
         */
        
        CCNode *temp = node;
        for (;; ) {
            if (temp == NULL) {
                break;
            }
            if ([temp isKindOfClass:[CCPanel class]]) {
                CCPanel *temp_ = (CCPanel *)temp;
                if(!temp_.isTouchValid){
                    return;
                }
                break;
            }
            temp = temp.parent;
        }

        s_bDragonRankSend = YES;
        //
        currentPageCount++;
        [self loadRankData];
         
    }
    CCLOG(@"--dragon world load with type");
}
-(void)loadWindow{
    //
    CCLayerColor *bg = (CCLayerColor *)[self getChildByTag:DragonWorldRank_bg_tag];
    if (bg) {
        [bg removeFromParentAndCleanup:YES];
        bg = NULL;
    }
    bg = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
    bg.contentSize = CGSizeMake(self.contentSize.width-cFixedScale(DRAGONRANK_LINE_W)*2, self.contentSize.height-cFixedScale(DRAGONRANK_LINE_H)*2-cFixedScale(47));
    //bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width-cFixedScale(DRAGONEXCHANGE_LINE_W)*2 height:self.contentSize.height-cFixedScale(DRAGONEXCHANGE_LINE_H)*2-cFixedScale(50) capx:cFixedScale(8) capy:cFixedScale(8)];
    
    bg.anchorPoint = ccp(0,0);
    [self addChild:bg];
    bg.tag = DragonWorldRank_bg_tag;
    bg.position = ccp(cFixedScale(DRAGONRANK_LINE_W),cFixedScale(DRAGONRANK_LINE_H));
    //
    CCSprite *icon = (CCSprite *)[self getChildByTag:DragonWorldRank_icon_tag];
    if (icon) {
        [icon removeFromParentAndCleanup:YES];
        icon = NULL;
    }
    //icon = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
    //icon = [CCSprite spriteWithFile:@"Icon-72.png"];
//    if (iPhoneRuningOnGame()) {
//		icon = [CCSprite spriteWithFile:@"images/ui/wback/t27.png"];
//	}else{
//		icon = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
//	}
    icon = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
    //
    CCSprite *icon_f = [CCSprite spriteWithFile:@"images/ui/dragon/player_team_change.png"];
    if (icon && icon_f) {
        [icon addChild:icon_f];
        [icon_f setPosition:ccp(icon.contentSize.width/2, icon.contentSize.height/2)];
    }
    //
    [self addChild:icon];
    icon.anchorPoint = ccp(0,1);
    icon.position = ccp(0+cFixedScale(DRAGONRANK_LINE_W)*3,bg.contentSize.height-cFixedScale(DRAGONRANK_LINE_H/3));
    icon.tag = DragonWorldRank_icon_tag;
    //
    CCLabelFX *label_npc_text = (CCLabelFX *)[self getChildByTag:DragonWorldRank_npc_text_tag];
    if (NULL == label_npc_text) {
        label_npc_text = [CCLabelFX labelWithString:@""
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentLeft
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:18
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(160,100,20, 128)
                                          fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_npc_text];
        label_npc_text.tag = DragonWorldRank_npc_text_tag;
    }
    [label_npc_text setString:NSLocalizedString(@"dragon_rank_npc",nil)];
    label_npc_text.anchorPoint = ccp(0,0);
    label_npc_text.position = ccpAdd(icon.position,ccp(icon.contentSize.width+cFixedScale(18),-icon.contentSize.height/2+icon.contentSize.height/10));
    //
    CCLabelFX *label_npc_text2 = (CCLabelFX *)[self getChildByTag:DragonWorldRank_npc_text2_tag];
    if (NULL == label_npc_text2) {
        label_npc_text2 = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:18
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(0, 150, 255, 255)];
        [self addChild:label_npc_text2];
        label_npc_text2.tag = DragonWorldRank_npc_text2_tag;
    }
    [label_npc_text2 setString:NSLocalizedString(@"dragon_rank_text2",nil)];
    label_npc_text2.anchorPoint = ccp(0,1);
    label_npc_text2.position = ccpAdd(icon.position,ccp(icon.contentSize.width + cFixedScale(18),-icon.contentSize.height/2-icon.contentSize.height/10));
    //
    CCSimpleButton *button1 = (CCSimpleButton *)[self getChildByTag:DragonWorldRank_button_tag];
    if (NULL == button1) {
        button1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_return_1.png" select:@"images/ui/button/bts_return_2.png" invalid:@"images/ui/button/bts_return_3.png" target:self call:@selector(CallBack:)];
        button1.tag = DragonWorldRank_button_tag;
        button1.priority = DRAGONRANK_BUTTON_PRI;
        [self addChild:button1];
        [button1 setPosition:ccp(cFixedScale(DRAGONRANK_LINE_W*2)+button1.contentSize.width/2,button1.contentSize.height/2 + cFixedScale(DRAGONRANK_LINE_H*2))];
    }
    //
    [self setRankValue:rankValue];
}
-(void)setRankValue:(int)rankValue_{
    rankValue = rankValue_;
    //

    CCLabelFX *label_rank_text = (CCLabelFX *)[self getChildByTag:DragonWorldRank_rank_text_tag];
    if (NULL == label_rank_text) {
        label_rank_text = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_rank_rank_text",nil)
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:18
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(230, 230, 230, 255)];
        [self addChild:label_rank_text];
        label_rank_text.tag = DragonWorldRank_rank_text_tag;
        label_rank_text.anchorPoint = ccp(1,0);
    }
    //
    CCLabelFX *label_rank_text_2 = (CCLabelFX *)[self getChildByTag:DragonWorldRank_rank_text2_tag];
    if (NULL == label_rank_text_2) {
        label_rank_text_2 = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:18
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_rank_text_2];
        label_rank_text_2.tag = DragonWorldRank_rank_text2_tag;
        label_rank_text_2.anchorPoint = ccp(1,0);
    }
    [label_rank_text_2 setString:[NSString stringWithFormat:@"%d",rankValue]];
    //
    label_rank_text_2.position = ccp(self.contentSize.width - cFixedScale(DRAGONRANK_LINE_W*2),cFixedScale(DRAGONRANK_LINE_H*2));
    label_rank_text.position = ccpAdd(label_rank_text_2.position, ccp(-label_rank_text_2.contentSize.width,0));

}
-(void)CallBack:(CCNode*)node{
    CCLOG(@"---dragon world rank!");
    if (s_bDragonRankSend) {
        return;
    }
    s_bDragonRankSend = YES;
    
    [[Window shared] showWindow:PANEL_UNION_Dragon_Exchange];
}
@end

