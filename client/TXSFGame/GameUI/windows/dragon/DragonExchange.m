//
//  DragonExchange.m
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "DragonExchange.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "CCPanel.h"
#import "CJSONDeserializer.h"
#import "StretchingImg.h"
#import "MessageBox.h"

#define DRAGONEXCHANGE_LINE_W (25)
#define DRAGONEXCHANGE_LINE_H (20)
#define DRAGONEXCHANGE_BUTTON_H (106)
#define DRAGONEXCHANGE_BUTTON_PRI (255)

#define DRAGONEXCHANGE_PANEL_W (700)
#define DRAGONEXCHANGE_PANEL_H (380)
#define DRAGONEXCHANGE_PANEL_OFF_W (110)

//
static BOOL s_bDragonExchangeSend = NO;

#pragma mark-
#pragma mark dragon exchange item
//typedef enum {
//    DEIT_type_1 = 0,
//    DEIT_type_2,
//    DEIT_type_3,
//    DEIT_type_4,
//}DragonDonateItemType;

@interface DragonExchangeItem:CCNode{
    int rewardRecordID;
    int rewardID;
    //
    int itemID;
    NSString *name;
    NSString *typeString;
    int count;
    int donateCost;
    int quality;
    //
}
@property(assign,nonatomic) int rewardRecordID;
@property(assign,nonatomic) int rewardID;
@property(assign,nonatomic) int itemID;
@property(assign,nonatomic) NSString *name;
@property(assign,nonatomic) NSString *typeString;
@property(assign,nonatomic) int quality;
@property(assign,nonatomic) int count;
@property(assign,nonatomic) int donateCost;

@end
@implementation DragonExchangeItem
enum{
    DEItem_icon_tag,
    DEItem_name_tag,
    DEItem_count_tag,
    DEItem_donate_cost_tag,
    DEItem_donate_cost_text_tag,
    DEItem_button_tag,
};
@synthesize rewardRecordID;
@synthesize rewardID;
@synthesize itemID;
@synthesize name;
@synthesize typeString;
@synthesize quality;
@synthesize count;
@synthesize donateCost;

-(id)init{
    if ((self = [super init])!=nil) {
        itemID = 0;
        rewardRecordID = 0;
        rewardID = 0;
        count = 100;
        donateCost = 900;
        quality = 0;
        name = nil;
        typeString = nil;
        self.contentSize = CGSizeMake(cFixedScale(64), cFixedScale(64));
    }
    return self;
}
-(void)onEnter{
	[super onEnter];
    [self loadWindow];
    [self loadButton];
}
-(void)onExit{
    [super onExit];
}

-(void)setDonateCost:(int)donateCost_{
    donateCost = donateCost_;
}
-(void)setName:(NSString *)name_{
    name = name_;
}
-(void)setItemID:(int)itemID_{
    itemID = itemID_;
}
-(void)setCount:(int)count_{
    count = count_;
}

-(void)setRewardID:(int)rewardID_{
    rewardID = rewardID_;
}
//-(NSString*)getNameWithType:(int)type{
//    return @"高级鱼饵";
//}
-(CCSprite*)getIconSpriteWithItemID:(int)itmeID{
    //return [CCSprite spriteWithFile:@"images/ui/task_icon/task_icon_1.png"];
    NSString *path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
	CCSprite *result = [CCSprite spriteWithFile:path];
    CCSprite *front = nil;
    //CCSprite *front = getItemIcon(itmeID);
    if([typeString isEqualToString:@"i"]){
        front=getItemIcon(itmeID);
    }
    if([typeString isEqualToString:@"e"]){
        front=getEquipmentIcon(itmeID);
    }
    if([typeString isEqualToString:@"f"]){
        front=getFateIconWithQa(itmeID,quality);
    }
    if([typeString isEqualToString:@"c"]){
        front=getCarIcon(itmeID);
    }
    if([typeString isEqualToString:@"r"]){
        front=getTMemberIcon(itmeID);
    }

    if (result && front) {
        [result addChild:front];
        [front setPosition:ccp(result.contentSize.width/2, result.contentSize.height/2)];
    }
    return result;
}
-(void)loadButton{
    CCSimpleButton *button1 = (CCSimpleButton *)[self getChildByTag:DEItem_button_tag];
    if (NULL == button1) {
        button1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_union_exchange_1.png" select:@"images/ui/button/bts_union_exchange_2.png" invalid:@"images/ui/button/bts_union_exchange_3.png" target:self call:@selector(CallBack:)];
        button1.tag = DEItem_button_tag;
        button1.priority = DRAGONEXCHANGE_BUTTON_PRI;
        [self addChild:button1];
        [button1 setPosition:ccp(0, -self.contentSize.height/2-cFixedScale(DRAGONEXCHANGE_BUTTON_H))];
    }
}
-(void)loadWindow{
    //
    CCSprite *icon = (CCSprite *)[self getChildByTag:DEItem_icon_tag];
    if (icon) {
        [icon removeFromParentAndCleanup:YES];
        icon = NULL;
    }
    icon = [self getIconSpriteWithItemID:itemID];
    if (icon) {
        [self addChild:icon];
        self.contentSize = icon.contentSize;
        icon.tag = DEItem_icon_tag;
    }
    //
    CCLabelFX *label_name_text = (CCLabelFX *)[self getChildByTag:DEItem_name_tag];
    if (label_name_text) {
        [label_name_text removeFromParentAndCleanup:YES];
        label_name_text = NULL;
    }
    if (NULL == label_name_text) {
        ccColor3B color_ = getColorByQuality(quality);
        label_name_text = [CCLabelFX labelWithString:@""
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentLeft
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:21
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(160,100,20, 128)
                                          fillColor:ccc4(color_.r, color_.g, color_.b, 255)];
        [self addChild:label_name_text];
        label_name_text.anchorPoint = ccp(0.5,0);
        label_name_text.tag = DEItem_name_tag;
    }
    if (name) {
        [label_name_text setString:name];
    }
    [label_name_text setPosition:ccp(0, self.contentSize.height/2+label_name_text.contentSize.height)];
    //
    CCLabelFX *label_count_text = (CCLabelFX *)[self getChildByTag:DEItem_count_tag];
    if (NULL == label_count_text) {
        label_count_text = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:21
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_count_text];
        label_count_text.tag = DEItem_count_tag;
    }
    if (count>1) {
       [label_count_text setString:[NSString stringWithFormat:@"%d",count]];
    }else{
        [label_count_text setString:@""];
    }
    //
    int fize_ = 16;
    CCLabelFX *label_donate_cost_text = (CCLabelFX *)[self getChildByTag:DEItem_donate_cost_tag];
    if (NULL == label_donate_cost_text) {
        label_donate_cost_text = [CCLabelFX labelWithString:@""
                                           dimensions:CGSizeMake(0,0)
                                            alignment:kCCTextAlignmentLeft
                                             fontName:getCommonFontName(FONT_1)
                                             fontSize:fize_
                                         shadowOffset:CGSizeMake(-0.5, -0.5)
                                           shadowBlur:1.0f
                                          shadowColor:ccc4(160,100,20, 128)
                                            fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_donate_cost_text];
        label_donate_cost_text.anchorPoint = ccp(0,1);
        label_donate_cost_text.tag = DEItem_donate_cost_tag;
    }
    [label_donate_cost_text setString:[NSString stringWithFormat:@"%d",donateCost]];
    //
    CCLabelFX *label_donate_cost_text_text = (CCLabelFX *)[self getChildByTag:DEItem_donate_cost_text_tag];
    if (NULL == label_donate_cost_text_text) {
        label_donate_cost_text_text = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_exchange_donate_unit",nil)
                                                 dimensions:CGSizeMake(0,0)
                                                  alignment:kCCTextAlignmentLeft
                                                   fontName:getCommonFontName(FONT_1)
                                                   fontSize:fize_
                                               shadowOffset:CGSizeMake(-0.5, -0.5)
                                                 shadowBlur:1.0f
                                                shadowColor:ccc4(160,100,20, 128)
                                                  fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_donate_cost_text_text];
        label_donate_cost_text_text.anchorPoint = ccp(1,1);
        label_donate_cost_text_text.tag = DEItem_donate_cost_text_tag;
    }
    int count_w = label_donate_cost_text.contentSize.width + label_donate_cost_text_text.contentSize.width;
    //
    [label_donate_cost_text setPosition:ccp(-count_w/2,-self.contentSize.height/2-label_donate_cost_text.contentSize.height)];
    [label_donate_cost_text_text setPosition:ccp(count_w/2,-self.contentSize.height/2-label_donate_cost_text.contentSize.height)];
}
-(void)CallBack:(CCNode*)node{
    if (s_bDragonExchangeSend) {
        return;
    }
    NSMutableDictionary *Dict_ = [NSMutableDictionary dictionary];
    [Dict_ setObject:[NSNumber numberWithInt:rewardRecordID] forKey:@"iid"];
    if (DEItem_button_tag == node.tag) {
        CCLOG(@"--DEItem_button_tag!");
        s_bDragonExchangeSend = YES;
        [GameConnection request:@"allyGloryExchange" data:Dict_ target:self call:@selector(didGloryExchange:)];
    }
}
-(void)didGloryExchange:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
            int glory_ = [[dict objectForKey:@"glory"] intValue];
            CCNode *exchange = self;
            for (;; ) {
                if (exchange == NULL) {
                    break;
                }
                if ([exchange isKindOfClass:[DragonExchange class]]) {
                    DragonExchange *exchange_ = (DragonExchange *)exchange;
                    [exchange_ setDonateValue:glory_];
                    break;
                }
                exchange = exchange.parent;
            }
            //[[GameConfigure shared] updatePackage:[dict objectForKey:@"data"]];
            //
            [GameConnection post:ConnPost_ally_map_crystal_enter object:nil];
        }
    }else {
        CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    s_bDragonExchangeSend = NO;
}
@end

#pragma mark-
#pragma mark dragon exchange
@implementation DragonExchange

enum{
    DragonExchange_bg_tag = 23,
    DragonExchange_icon_tag,
    DragonExchange_npc_text_tag,
    DragonExchange_npc_text2_tag,
    DragonExchange_donate_text_1_tag,
    DragonExchange_donate_text_2_tag,
    DragonExchange_union_rank_menu_tag,
    DragonExchange_union_rank_bt_tag,
    DragonExchange_world_rank_bt_tag,
    DragonExchange_itemPanel_tag,
    DragonExchange_item1_tag,
    DragonExchange_item2_tag,
    DragonExchange_item3_tag,
    DragonExchange_item4_tag,
};

-(NSString*)getBackgroundPath{
	return @"images/ui/panel/p5.png";
}

-(NSString*)getCaptionPath{
	return @"images/ui/panel/t82.png";
}
-(void)onEnter{
	[super onEnter];
    s_bDragonExchangeSend = NO;
    [self enterWindow];
    //
    [GameConnection addPost:ConnPost_updatePackageLuck target:self call:@selector(showUpdatePackage:)];
    //
//    [self loadWindow];
//    [self loadButton];
//    [self loadItem];
}
-(void)closeWindow{
    s_bDragonExchangeSend = YES;
	[super closeWindow];
}
-(void)onExit{
    s_bDragonExchangeSend = NO;
    [GameConnection removePostTarget:self];
    //
	[super onExit];
}
-(void)showUpdatePackage:(NSNotification*)nof{
	NSArray *updateData = [[GameConfigure shared] getPackageAddData:nof.object type:PackageItem_all];
	[[AlertManager shared] showReceiveItemWithArray:updateData];
}
-(void)enterWindow{
    [GameConnection request:@"allyGloryExchangeEnter" data:[NSDictionary dictionary] target:self call:@selector(didEnterWindow:)];
}
-(void)didEnterWindow:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			CCLOG(@"did action info %@", dict);
            donateValue = [[dict objectForKey:@"glory"] intValue];
            //
            [self loadWindow];
            [self loadButton];
            [self loadItem];
        }
	} else {
		CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        [[Window shared] removeWindow:PANEL_UNION_Dragon_Exchange];
	}
}

-(void)setDonateValue:(int)value{
    donateValue = value;
    //
    int fize_ = 18;
    CCLabelFX *label_donate_text_1 = (CCLabelFX *)[self getChildByTag:DragonExchange_donate_text_1_tag];
    if (NULL == label_donate_text_1) {
        label_donate_text_1 = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_exchange_donate",nil)
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:fize_
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_donate_text_1];
        label_donate_text_1.tag = DragonExchange_donate_text_1_tag;
        label_donate_text_1.anchorPoint = ccp(0,0);
        label_donate_text_1.position = ccp(cFixedScale(DRAGONEXCHANGE_LINE_W*2),cFixedScale(DRAGONEXCHANGE_LINE_H*2));
    }
    //
    CCLabelFX *label_donate_text_2 = (CCLabelFX *)[self getChildByTag:DragonExchange_donate_text_2_tag];
    if (NULL == label_donate_text_2) {
        label_donate_text_2 = [CCLabelFX labelWithString:@""
                                              dimensions:CGSizeMake(0,0)
                                               alignment:kCCTextAlignmentLeft
                                                fontName:getCommonFontName(FONT_1)
                                                fontSize:fize_
                                            shadowOffset:CGSizeMake(-0.5, -0.5)
                                              shadowBlur:1.0f
                                             shadowColor:ccc4(160,100,20, 128)
                                               fillColor:ccc4(250, 230, 130, 255)];
        [self addChild:label_donate_text_2];
        label_donate_text_2.tag = DragonExchange_donate_text_2_tag;
        label_donate_text_2.anchorPoint = ccp(0,0);
        label_donate_text_2.position = ccpAdd(label_donate_text_1.position, ccp(label_donate_text_1.contentSize.width,0));
    }
    //
    [label_donate_text_2 setString:[NSString stringWithFormat:@"%d",donateValue]];
}

-(void)loadItem{
    NSDictionary *dict = [[GameDB shared] getAllBoatExchange];
    if (dict) {
        NSArray *allkeys = [dict allKeys];
        NSMutableArray *mutallkeys = [NSMutableArray arrayWithArray:allkeys];
        [mutallkeys sortUsingSelector:@selector(compare:)];
        NSMutableArray *array_ = [NSMutableArray array];
        //
        //"reward"
        NSDictionary *rewardInfo_dict = [[GameDB shared] getInfo:@"reward"];
        //"item"
        //NSDictionary *itemInfo_dict = [[GameDB shared] getInfo:@"item"];
        
        for (id t_key in mutallkeys) {
            NSDictionary *t_dict = [dict objectForKey:t_key];
            int rewardRecord_id = [[t_dict objectForKey:@"id"] intValue];
            int rewaid_id = [[t_dict objectForKey:@"rid"] intValue];
            int glory = [[t_dict objectForKey:@"glory"] intValue];;
            //NSDictionary *rewaid_dict = [[[GameDB shared] getRewardInfo:rewaid_id];
            NSDictionary *rewaid_dict =  [rewardInfo_dict objectForKey:[NSString stringWithFormat:@"%d",rewaid_id]];
            
            CCLOG(@"%@",[rewaid_dict objectForKey:@"info"]);
            NSData *data = getDataFromString([rewaid_dict objectForKey:@"reward"]);
            NSError *error = nil;
            NSArray * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
            if (!error) {
                if (rewards && [rewards count]==1) {
                    NSDictionary * reward = [rewards objectAtIndex:0];
                    int i = [[reward objectForKey:@"i"] intValue];
                    int count = [[reward objectForKey:@"c"] intValue];
                    int quality = 0;
                    NSString *type_str = [reward objectForKey:@"t"];
                    NSString *name = @"";
                    NSDictionary *info_dict = nil;
                    ////
                    if([type_str isEqualToString:@"i"]){
                        info_dict = [[[GameDB shared] getInfo:@"item"] objectForKey:[NSString stringWithFormat:@"%d",i]];
                    }
                    if([type_str isEqualToString:@"e"]){
                        info_dict = [[[GameDB shared] getInfo:@"equip"] objectForKey:[NSString stringWithFormat:@"%d",i]];
                    }
                    if([type_str isEqualToString:@"f"]){
                        info_dict = [[[GameDB shared] getInfo:@"fate"] objectForKey:[NSString stringWithFormat:@"%d",i]];
                    }
                    if([type_str isEqualToString:@"c"]){
                        info_dict = [[[GameDB shared] getInfo:@"car"] objectForKey:[NSString stringWithFormat:@"%d",i]];
                    }
                    if([type_str isEqualToString:@"r"]){
                        info_dict = [[[GameDB shared] getInfo:@"role"] objectForKey:[NSString stringWithFormat:@"%d",i]];
                    }
                    //
                    if (info_dict) {
                        name = [info_dict objectForKey:@"name"];
                        if ([type_str isEqualToString:@"e"]) {
                            NSDictionary *eqset = [[GameDB shared] getEquipmentSetInfo:[[info_dict objectForKey:@"sid"] intValue]];
                            if (eqset) {
                                quality = [[eqset objectForKey:@"quality"] intValue];
                            }
                        }else{
                            quality = [[info_dict objectForKey:@"quality"] intValue];
                        }
                    }
                    
                    //NSDictionary *item_dict = [[GameDB shared] getItemInfo:i];
                    if (info_dict) {
                        DragonExchangeItem *DE_item = [DragonExchangeItem node];
                        [DE_item setTypeString:type_str];
                        [DE_item setCount:count];
                        [DE_item setItemID:i];
                        [DE_item setName:name];
                        [DE_item setQuality:quality];
                        [DE_item setRewardRecordID:rewardRecord_id];
                        [DE_item setRewardID:rewaid_id];
                        [DE_item setDonateCost:glory];
                        [array_ addObject:DE_item];
                    }
                }else{
                    CCLOG(@"------rewards data error!");
                }
            }
        }
        //
        [self loadItemWithItemArray:array_];
    }

}
-(void)loadItemWithItemArray:(NSArray*)itemArray{
    if (itemArray && [itemArray count]>1) {
        [self removeChildByTag:DragonExchange_itemPanel_tag cleanup:YES];
        //
        int w_ = ([itemArray count])*([[itemArray objectAtIndex:0] contentSize].width+cFixedScale(DRAGONEXCHANGE_PANEL_OFF_W));
        int h_ = [[itemArray objectAtIndex:0] contentSize].height;
        int UI_W = cFixedScale(DRAGONEXCHANGE_PANEL_W);
        int UI_H = cFixedScale(DRAGONEXCHANGE_PANEL_H);
        if (w_<UI_W) {
            w_ = UI_W;
        }
        if (h_<UI_H) {
            h_ = UI_H;
        }
        CCLayerColor *contentLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:w_ height:h_];
        CGPoint pos = ccp([[itemArray objectAtIndex:0] contentSize].width/2+cFixedScale(DRAGONEXCHANGE_PANEL_OFF_W/2),UI_H/2 );
        for (DragonExchangeItem *item_ in itemArray) {
            [item_ setPosition:pos];
            [contentLayer addChild:item_];
            pos.x += (item_.contentSize.width+cFixedScale(DRAGONEXCHANGE_PANEL_OFF_W));
        }
        
        //------
        CCPanel *newPanel = [CCPanel panelWithContent:contentLayer viewSize:CGSizeMake(UI_W, UI_H)];
        //
        CCSprite *bg_ = nil;
        if (iPhoneRuningOnGame()) {
            bg_=[CCSprite spriteWithFile:@"images/ui/wback/select_bg.png"];
            bg_.scaleX = 1.2;
        }else{
            bg_=[CCSprite spriteWithFile:@"images/ui/car/select_bg.png"];
            bg_.scaleX = 1.5;
        }
        [newPanel addChild:bg_];
        bg_.position = ccp(newPanel.contentSize.width/2,newPanel.contentSize.height/2);
        //
        if (w_>cFixedScale(DRAGONEXCHANGE_PANEL_W)) {
            [newPanel showHorzScrollBar:@"images/ui/common/scroll3.png"];
        }
        newPanel.position = ccp(cFixedScale(100), cFixedScale(100));
        [newPanel updateContentToTop:0];
        [self addChild:newPanel z:10 tag:DragonExchange_itemPanel_tag];
    }
}
-(void)loadButton{
    CCMenu *menu = (CCMenu *)[self getChildByTag:DragonExchange_union_rank_menu_tag];
    if (NULL == menu) {
        menu = [CCMenu node];
        menu.position = ccp(0,0);
        [self addChild:menu z:DragonExchange_union_rank_menu_tag tag:DragonExchange_union_rank_menu_tag];
    }
    //
    int fize_ = cFixedScale(18);
    CCMenuItemFont *button_union = (CCMenuItemFont *)[menu getChildByTag:DragonExchange_union_rank_bt_tag];
    if (NULL == button_union) {
        NSArray *labelArray = getUnderlineSpriteArray(NSLocalizedString(@"dragon_exchange_union_rank",nil),getCommonFontName(FONT_1), fize_, ccc4(250, 150, 50,255));
        button_union = [CCMenuItemSprite itemWithNormalSprite:[labelArray objectAtIndex:0] selectedSprite:[labelArray objectAtIndex:1] target:self selector:@selector(CallBack:)];
        //
        button_union.tag = DragonExchange_union_rank_bt_tag;
        [menu addChild:button_union];
    }
    //
    CCMenuItemFont *button_world = (CCMenuItemFont *)[menu getChildByTag:DragonExchange_world_rank_bt_tag];
    if (NULL == button_world) {
        NSArray *labelArray = getUnderlineSpriteArray(NSLocalizedString(@"dragon_exchange_world_rank",nil),getCommonFontName(FONT_1), fize_, ccc4(250, 150, 50,255));
        button_world = [CCMenuItemSprite itemWithNormalSprite:[labelArray objectAtIndex:0] selectedSprite:[labelArray objectAtIndex:1] target:self selector:@selector(CallBack:)];
        //
        button_world.tag = DragonExchange_world_rank_bt_tag;
        [menu addChild:button_world];
    }
    //
    [button_world setPosition: ccp(self.contentSize.width-button_world.contentSize.width/2-cFixedScale(DRAGONEXCHANGE_LINE_W*2), button_world.contentSize.height/2+cFixedScale(DRAGONEXCHANGE_LINE_H*2))];
    [button_union setPosition:ccpAdd(button_world.position, ccp(-(button_union.contentSize.width/2+button_world.contentSize.width/2+cFixedScale(20)),0))];
}
-(void)loadWindow{
    //
    CCLayerColor *bg = (CCLayerColor *)[self getChildByTag:DragonExchange_bg_tag];
    if (bg) {
        [bg removeFromParentAndCleanup:YES];
        bg = NULL;
    }
    bg = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
    bg.contentSize = CGSizeMake(self.contentSize.width-cFixedScale(DRAGONEXCHANGE_LINE_W)*2, self.contentSize.height-cFixedScale(DRAGONEXCHANGE_LINE_H)*2-cFixedScale(47));
    //bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width-cFixedScale(DRAGONEXCHANGE_LINE_W)*2 height:self.contentSize.height-cFixedScale(DRAGONEXCHANGE_LINE_H)*2-cFixedScale(50) capx:cFixedScale(8) capy:cFixedScale(8)];
    
    bg.anchorPoint = ccp(0,0);
    [self addChild:bg];
    bg.tag = DragonExchange_bg_tag;
    bg.position = ccp(cFixedScale(DRAGONEXCHANGE_LINE_W),cFixedScale(DRAGONEXCHANGE_LINE_H));
    //
    CCSprite *icon = (CCSprite *)[self getChildByTag:DragonExchange_icon_tag];
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
    icon.position = ccp(0+cFixedScale(DRAGONEXCHANGE_LINE_W)*3,bg.contentSize.height-cFixedScale(DRAGONEXCHANGE_LINE_H/3));
    icon.tag = DragonExchange_icon_tag;
    //
    CCLabelFX *label_npc_text = (CCLabelFX *)[self getChildByTag:DragonExchange_npc_text_tag];
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
        label_npc_text.tag = DragonExchange_npc_text_tag;
    }
    [label_npc_text setString:NSLocalizedString(@"dragon_exchange_npc",nil)];
    label_npc_text.anchorPoint = ccp(0,0);
    label_npc_text.position = ccpAdd(icon.position,ccp(icon.contentSize.width+cFixedScale(18),-icon.contentSize.height/2+icon.contentSize.height/10));
    //
    CCLabelFX *label_npc_text2 = (CCLabelFX *)[self getChildByTag:DragonExchange_npc_text2_tag];
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
        label_npc_text2.tag = DragonExchange_npc_text2_tag;
    }
    [label_npc_text2 setString:NSLocalizedString(@"dragon_exchange_text",nil)];
    label_npc_text2.anchorPoint = ccp(0,1);
    label_npc_text2.position = ccpAdd(icon.position,ccp(icon.contentSize.width + cFixedScale(18),-icon.contentSize.height/2-icon.contentSize.height/10));
    
    //
    [self setDonateValue:donateValue];
}
-(void)CallBack:(CCNode*)node{
    if (s_bDragonExchangeSend) {
        return;
    }
    CCLOG(@"call back dragon donate---!");
    if (DragonExchange_union_rank_bt_tag == node.tag) {
        CCLOG(@" ---DragonExchange_union_rank_bt_tag!");
        s_bDragonExchangeSend = YES;
        [[Window shared] showWindow:PANEL_UNION_Dragon_Union_Rank];
    }else if (DragonExchange_world_rank_bt_tag == node.tag) {
        CCLOG(@" ---DragonExchange_world_rank_bt_tag!");
        s_bDragonExchangeSend = YES;
        [[Window shared] showWindow:PANEL_UNION_Dragon_World_Rank];
    }
}
@end
