//
//  DragonDonate.m
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "DragonDonate.h"
#import "CCSimpleButton.h"
#import "ShowItem.h"
#import "DragonWorldMap.h"
#import "DragonScore.h"
#import "StretchingImg.h"
#import "MessageBox.h"

#define DRAGONDONATE_LINE_W (25)
#define DRAGONDONATE_LINE_H (20)
#define DRAGONDONATE_NAME_W (100)
#define DRAGONDONATE_BUTTON_PRI (255)
#define DRAGONDONATE_STEP_H (70)
#define DRAGONDONATE_START_STEP_H (480)
typedef enum {
    DDIT_type_1 = 1,//耐久力
    DDIT_type_2,//炮火力
    DDIT_type_3,//载荷力
    DDIT_type_4,//继航力
    DDIT_type_end,
}DragonDonateItemType;

//
static BOOL s_bDragonDonateSend = NO;

#pragma mark -
#pragma mark donate item
@interface DragonDonateItem:CCNode{
    int type;
    //
    int level;
    int nowExp;
    int nextExp;
    int unionLevel;
    int needUnionLevel;
    int crystalValue1;
    int crystalValue2;
    int crystalValue3;
    //
    int value1;
    int value2;
    //
}
@property(nonatomic,assign) int type;
@property(nonatomic,assign) int level;
@property(nonatomic,assign) int nowExp;
@property(nonatomic,assign) int nextExp;
@property(nonatomic,assign) int unionLevel;
@property(nonatomic,assign) int needUnionLevel;
@property(nonatomic,assign) int crystalValue1;
@property(nonatomic,assign) int crystalValue2;
@property(nonatomic,assign) int value1;
@property(nonatomic,assign) int value2;
+(DragonDonateItem*)itemWithType:(int)type_ level:(int)level_ value1:(int)value1 value2:(int)value2 nowExp:(int)nowExp_ nextExp:(int)nextExp_ unionLevel:(int)unionLevel_ needUnionLevel:(int)needUnionLevel_;
@end

@implementation DragonDonateItem
enum{
    DDItem_scrollBG_tag = 1,
    DDItem_scrollLeft_tag,
    DDItem_scrollMiddle_tag,
    DDItem_scrollRight_tag,
    DDItem_exp_text_tag,
    DDItem_prompt_text_tag,
    DDItem_crystal_button1_tag,
    DDItem_crystal_button2_tag,
    DDItem_crystal_button3_tag,
    DDItem_name_tag,
    DDItem_parameter_tag,
};
@synthesize type;
@synthesize level;
@synthesize nowExp;
@synthesize nextExp;
@synthesize unionLevel;
@synthesize needUnionLevel;
@synthesize crystalValue1;
@synthesize crystalValue2;
@synthesize value1;
@synthesize value2;
-(id)init{
    if ((self = [super init])!=nil) {
        type = DDIT_type_1;
        nowExp = 100;
        nextExp = 900;
        unionLevel = 2;
        needUnionLevel = 1;
        value2 = 1;
        crystalValue1 = 1;
        crystalValue2 = 3;
        crystalValue3 = 5;
    }
    return self;
}
-(void)onEnter{
	[super onEnter];
    //
//    type = DDIT_type_1;
//    nowExp = 100;
//    nextExp = 900;
//    crystalValue1 = 1;
//    crystalValue2 = 2;
//    crystalValue3 = 3;
    //
//    [self loadExp];
//    [self loadExpText];
//    [self loadCrystalButton];
//    [self loadNameText];
    [self loadAll];
}
-(void)loadAll{
    [self loadExp];
    [self loadExpText];
    [self loadCrystalButton];
    [self loadNameText];
}
+(DragonDonateItem*)itemWithType:(int)type_ level:(int)level_ value1:(int)value1 value2:(int)value2 nowExp:(int)nowExp_ nextExp:(int)nextExp_ unionLevel:(int)unionLevel_ needUnionLevel:(int)needUnionLevel_{
    DragonDonateItem *item_1 = [DragonDonateItem node];
    [item_1 setType:type_];
    [item_1 setLevel:level_];
    [item_1 setValue1:value1];
    [item_1 setValue2:value2];
    [item_1 setNowExp:nowExp_];
    [item_1 setNextExp:nextExp_];
    [item_1 setUnionLevel:unionLevel_];
    [item_1 setNeedUnionLevel:needUnionLevel_];
    return item_1;
}
-(void)loadNameText{
    CCLabelFX *label_name_text = (CCLabelFX *)[self getChildByTag:DDItem_name_tag];
    if (NULL == label_name_text) {
        label_name_text = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:18
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_name_text];
        label_name_text.anchorPoint = ccp(0.5,0);
        label_name_text.tag = DDItem_name_tag;
    }
    CCLabelFX *label_parameter_text = (CCLabelFX *)[self getChildByTag:DDItem_parameter_tag];
    if (NULL == label_parameter_text) {
        label_parameter_text = [CCLabelFX labelWithString:@""
                                          dimensions:CGSizeMake(0,0)
                                           alignment:kCCTextAlignmentLeft
                                            fontName:getCommonFontName(FONT_1)
                                            fontSize:14
                                        shadowOffset:CGSizeMake(-0.5, -0.5)
                                          shadowBlur:1.0f
                                         shadowColor:ccc4(160,100,20, 128)
                                           fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_parameter_text];
        label_parameter_text.anchorPoint = ccp(0.5,1);
        label_parameter_text.tag = DDItem_parameter_tag;
    }

    if (DDIT_type_1 == type) {
        [label_name_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_wear_level",nil),level]];
        [label_parameter_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_wear_parameter",nil),value1]];
    }else if(DDIT_type_2 == type){
        [label_name_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_fire_level",nil),level]];
        [label_parameter_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_fire_parameter",nil),value1]];
    }else if(DDIT_type_3 == type){
        [label_name_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_load_level",nil),level]];
        //[label_parameter_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_load_parameter",nil),value2,value1]];
        [label_parameter_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_load_parameter",nil),value1]];
    }else if(DDIT_type_4 == type){
        [label_name_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_again_level",nil),level]];
        [label_parameter_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_again_parameter",nil),value1]];
    }
    
    CCSprite *scrollBg = (CCSprite *)[self getChildByTag:DDItem_scrollBG_tag];
    CGPoint startPos = CGPointZero;
    if (scrollBg) {
        startPos = ccpAdd(scrollBg.position, ccp(-scrollBg.contentSize.width/2-cFixedScale(DRAGONDONATE_NAME_W),0));
    }
    [label_name_text setPosition:startPos];
    [label_parameter_text setPosition:startPos];
}
-(void)loadExpText{
    CCSprite *scrollBg = (CCSprite *)[self getChildByTag:DDItem_scrollBG_tag];
    CCLabelFX *label_exp_text = (CCLabelFX *)[self getChildByTag:DDItem_exp_text_tag];
    int h_ = label_exp_text.contentSize.height;
    if (scrollBg) {
        h_ = scrollBg.contentSize.height;
    }
    if (NULL == label_exp_text) {
        label_exp_text = [CCLabelFX labelWithString:@"0/0"
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentLeft
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:16
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(160,100,20, 128)
                                          fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_exp_text];
        label_exp_text.position = ccp(0,-h_);
        label_exp_text.tag = DDItem_exp_text_tag;
    }
    [label_exp_text setString:[NSString stringWithFormat:@"%d/%d",nowExp,nextExp]];
    //
    if (unionLevel<needUnionLevel) {
        CCLabelFX *label_prompt_text = (CCLabelFX *)[self getChildByTag:DDItem_prompt_text_tag];
        if (NULL == label_prompt_text) {
            label_prompt_text = [CCLabelFX labelWithString:@""
                                             dimensions:CGSizeMake(0,0)
                                              alignment:kCCTextAlignmentLeft
                                               fontName:getCommonFontName(FONT_1)
                                               fontSize:18
                                           shadowOffset:CGSizeMake(-0.5, -0.5)
                                             shadowBlur:1.0f
                                            shadowColor:ccc4(160,100,20, 128)
                                              fillColor:ccc4(255, 0, 0, 255)];
            [self addChild:label_prompt_text];
            label_prompt_text.tag = DDItem_prompt_text_tag;
        }
        [label_prompt_text setString:[NSString stringWithFormat:NSLocalizedString(@"dragon_donate_union_level",nil),needUnionLevel]];
        label_prompt_text.position = ccp(0,+h_);
    }else{
        [self removeChildByTag:DDItem_prompt_text_tag cleanup:YES];
    }
}
-(void)loadCrystalButton{
    CCSimpleButton *button1 = (CCSimpleButton *)[self getChildByTag:DDItem_crystal_button1_tag];
    if (NULL == button1) {
        button1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_dragon_x1_1.png" select:@"images/ui/button/bts_dragon_x1_2.png" invalid:@"images/ui/button/bts_dragon_x1_3.png" target:self call:@selector(CallBack:)];
        button1.tag = DDItem_crystal_button1_tag;
        /*
        CCLabelFX *label_ = [CCLabelFX labelWithString:[NSString stringWithFormat:@"*%d",crystalValue1]
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentLeft
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:21
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(160,100,20, 128)
                                          fillColor:ccc4(230, 180, 60, 255)];
        [button1 addChild:label_];
        label_.tag = DDItem_crystal_button1_tag;
        label_.position = ccp(button1.contentSize.width/2,button1.contentSize.height/2);
         */
        button1.priority = DRAGONDONATE_BUTTON_PRI;
        [self addChild:button1];
    }
    //
    CCSimpleButton *button2 = (CCSimpleButton *)[self getChildByTag:DDItem_crystal_button2_tag];
    if (NULL == button2) {
        button2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_dragon_x3_1.png" select:@"images/ui/button/bts_dragon_x3_2.png" invalid:@"images/ui/button/bts_dragon_x3_3.png" target:self call:@selector(CallBack:)];
        button2.tag = DDItem_crystal_button2_tag;
        /*
        CCLabelFX *label_ = [CCLabelFX labelWithString:[NSString stringWithFormat:@"*%d",crystalValue2]
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:21
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 180, 60, 255)];
        [button2 addChild:label_];
        label_.tag = DDItem_crystal_button2_tag;
        label_.position = ccp(button2.contentSize.width/2,button2.contentSize.height/2);
         */
        button2.priority = DRAGONDONATE_BUTTON_PRI;
        [self addChild:button2];
    }
    //
    CCSimpleButton *button3 = (CCSimpleButton *)[self getChildByTag:DDItem_crystal_button3_tag];
    if (NULL == button3) {
        button3 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_dragon_x5_1.png" select:@"images/ui/button/bts_dragon_x5_2.png" invalid:@"images/ui/button/bts_dragon_x5_3.png" target:self call:@selector(CallBack:)];
        button3.tag = DDItem_crystal_button3_tag;
        /*
        CCLabelFX *label_ = [CCLabelFX labelWithString:[NSString stringWithFormat:@"*%d",crystalValue3]
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:21
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 180, 60, 255)];
        [button3 addChild:label_];
        label_.tag = DDItem_crystal_button3_tag;
        label_.position = ccp(button3.contentSize.width/2,button3.contentSize.height/2);
         */
        button3.priority = DRAGONDONATE_BUTTON_PRI;
        [self addChild:button3];
    }
    /*
    CCLabelFX *label_ = (CCLabelFX *)[button1 getChildByTag:DDItem_crystal_button1_tag];
    [label_ setString:[NSString stringWithFormat:@"*%d",crystalValue1]];
    //
    label_ = (CCLabelFX *)[button2 getChildByTag:DDItem_crystal_button2_tag];
    [label_ setString:[NSString stringWithFormat:@"*%d",crystalValue2]];
    //
    label_ = (CCLabelFX *)[button3 getChildByTag:DDItem_crystal_button3_tag];
    [label_ setString:[NSString stringWithFormat:@"*%d",crystalValue3]];
     */
    //
    CCSprite *scrollBg = (CCSprite *)[self getChildByTag:DDItem_scrollBG_tag];
    CGPoint startPos = CGPointZero;
    int off_w = cFixedScale(10);
    if (scrollBg) {
        startPos = ccpAdd(scrollBg.position, ccp(scrollBg.contentSize.width/2+button1.contentSize.width/2+cFixedScale(20),0));
    }
    
    [button1 setPosition: startPos];
    [button2 setPosition: ccpAdd(button1.position, ccp(button2.contentSize.width+off_w,0))];
    [button3 setPosition: ccpAdd(button2.position, ccp(button3.contentSize.width+off_w,0))];
    //
    if (unionLevel<needUnionLevel) {
        [button1 setInvalid:YES];
        [button2 setInvalid:YES];
        [button3 setInvalid:YES];
    }else{
        [button1 setInvalid:NO];
        [button2 setInvalid:NO];
        [button3 setInvalid:NO];
    }
}
-(void)loadExp{
    int w_ = 0;
    CCSprite *scrollBg = (CCSprite *)[self getChildByTag:DDItem_scrollBG_tag];
    CCSprite *scrollLeft = (CCSprite *)[self getChildByTag:DDItem_scrollLeft_tag];
    CCSprite *scrollMiddle = (CCSprite *)[self getChildByTag:DDItem_scrollMiddle_tag];
    CCSprite *scrollRight = (CCSprite *)[self getChildByTag:DDItem_scrollRight_tag];
    if (NULL == scrollBg) {
        scrollBg = [CCSprite spriteWithFile:@"images/ui/panel/p13.png"];
        //353 23
        scrollBg = getSpriteWithSpriteAndNewSize(scrollBg, CGSizeMake(cFixedScale(353), cFixedScale(23)));
        [self addChild:scrollBg];
        scrollBg.tag = DDItem_scrollBG_tag;
    }
     //
    if (NULL == scrollLeft) {
        scrollLeft = [CCSprite spriteWithFile:@"images/ui/common/progress1.png"];
        scrollLeft = getSpriteWithSpriteAndNewSize(scrollLeft, CGSizeMake(cFixedScale(6), cFixedScale(10)));
        scrollLeft.anchorPoint = ccp(1, 0.5);
        [self addChild:scrollLeft];
        scrollLeft.tag = DDItem_scrollLeft_tag;
    }
    //
    if (NULL == scrollMiddle) {
        scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/progress2.png"];
        scrollMiddle = getSpriteWithSpriteAndNewSize(scrollMiddle, CGSizeMake(cFixedScale(330), cFixedScale(10)));
        scrollMiddle.anchorPoint = ccp(0, 0.5);
        [self addChild:scrollMiddle];
        scrollMiddle.tag = DDItem_scrollMiddle_tag;
    }
    //
    if (NULL == scrollRight) {
        scrollRight = [CCSprite spriteWithFile:@"images/ui/common/progress3.png"];
        scrollRight = getSpriteWithSpriteAndNewSize(scrollRight, CGSizeMake(cFixedScale(6), cFixedScale(10)));
        scrollRight.anchorPoint = ccp(0, 0.5);
        [self addChild:scrollRight];
        scrollRight.tag = DDItem_scrollRight_tag;
    }
    //
    w_ = scrollMiddle.contentSize.width;
    scrollLeft.position = ccp(-w_/2,0);
    scrollMiddle.position = ccp(-w_/2,0);
    scrollRight.position = ccp(w_/2,0);
    //
    if (nextExp!=0) {
        [self setScroll:1.0*nowExp/nextExp];
    }else{
        [self setScroll:0];
    }
}
// scrollValue为0~1
-(void)setScroll:(float)scrollValue{
	if (scrollValue>1) {
        scrollValue = 1;
    }
    if (scrollValue<0.01) {
        scrollValue = 0.01;
    }
    CCSprite *scrollMiddle = (CCSprite *)[self getChildByTag:DDItem_scrollMiddle_tag];
    CCSprite *scrollRight = (CCSprite *)[self getChildByTag:DDItem_scrollRight_tag];
    if (scrollMiddle && scrollRight) {
        scrollMiddle.scaleX = scrollValue;
        scrollRight.position = ccp(scrollMiddle.position.x + scrollMiddle.contentSize.width*scrollMiddle.scaleX,
                                   scrollMiddle.position.y);
    }

}
-(void)CallBack:(CCNode*)node{
    if (s_bDragonDonateSend) {
        return;
    }
    CCLOG(@"call back dragon donate---!");
    NSMutableDictionary *Dict_ = [NSMutableDictionary dictionary];
    [Dict_ setObject:[NSNumber numberWithInt:type] forKey:@"t"];
    if (DDItem_crystal_button1_tag == node.tag) {
        CCLOG(@" ---DDItem_crystal_button1_tag!");
        s_bDragonDonateSend = YES;
        [Dict_ setObject:[NSNumber numberWithInt:crystalValue1] forKey:@"n"];
        [GameConnection request:@"allyCrystalOffer" data:Dict_ target:self call:@selector(didCrystalOffer:)];
    }else if (DDItem_crystal_button2_tag == node.tag) {
        CCLOG(@" ---DDItem_crystal_button2_tag!");
        s_bDragonDonateSend = YES;
        [Dict_ setObject:[NSNumber numberWithInt:crystalValue2] forKey:@"n"];
        [GameConnection request:@"allyCrystalOffer" data:Dict_ target:self call:@selector(didCrystalOffer:)];
    }else if (DDItem_crystal_button3_tag == node.tag) {
        CCLOG(@" ---DDItem_crystal_button3_tag!");
        s_bDragonDonateSend = YES;
        [Dict_ setObject:[NSNumber numberWithInt:crystalValue3] forKey:@"n"];
        [GameConnection request:@"allyCrystalOffer" data:Dict_ target:self call:@selector(didCrystalOffer:)];
    }
}

-(void)didCrystalOffer:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
            int t_ = [[dict objectForKey:@"t"] intValue];
            if (t_ == type) {
                level = [[dict objectForKey:@"lv"] intValue];
                //TODO
                NSDictionary *db_dict = [[GameDB shared] getAllBoatLevelWithType:type level:level];
                NSDictionary *db_dict_next = [[GameDB shared] getAllBoatLevelWithType:type level:(level+1)];
                NSDictionary *db_dict_now = [[GameDB shared] getAllBoatLevelWithType:type level:(level)];
                if (!db_dict) {
                    CCLOG(@"---db data error!");
                    return;
                }
                nowExp = [[dict objectForKey:@"exp"] intValue];
                nextExp = nowExp;
                if (db_dict_next && [db_dict_next objectForKey:@"exp"]) {
                    nextExp = [[db_dict_next objectForKey:@"exp"] intValue];
                    if (db_dict_now && [db_dict_now objectForKey:@"exp"]) {
                        nextExp -= [[db_dict_now objectForKey:@"exp"] intValue];
                    }
                }else{
                    if (db_dict_now && [db_dict_now objectForKey:@"exp"]) {
                        nextExp = [[db_dict_now objectForKey:@"exp"] intValue];
                    }
                }
                value1 = [[db_dict objectForKey:@"us"] intValue];
                //
                int cn_ = [[dict objectForKey:@"cn"] intValue];
                int dv_ = [[dict objectForKey:@"glory"] intValue];
                DragonDonate *donate = (DragonDonate *)self.parent;
                [donate setDonateValue:dv_];
                [donate setCrystalCount:cn_];
                //
                [self loadAll];
                //
                [GameConnection post:ConnPost_ally_map_crystal_enter object:nil];
            }else{
                CCLOG(@"------type error!");
            }
        } else {
            CCLOG(@"获取数据不成功");
        }
    } else {
        CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    s_bDragonDonateSend = NO;
}

-(void)onExit{
	[super onExit];
}
@end

#pragma mark -
#pragma mark donate
@implementation DragonDonate
enum{
    DragonDonate_bg_tag = 23,
    DragonDonate_icon_tag,
    DragonDonate_npc_text_tag,
    DragonDonate_npc_text2_tag,
    DragonDonate_power_tag,
    DragonDonate_crystal_text_tag,
    DragonDonate_crystal_tag,
    DragonDonate_donate_text_1_tag,
    DragonDonate_donate_text_2_tag,
    DragonDonate_item1_tag,
    DragonDonate_item2_tag,
    DragonDonate_item3_tag,
    DragonDonate_item4_tag,
};
-(NSString*)getBackgroundPath{
	return @"images/ui/panel/p5.png";
}

-(NSString*)getCaptionPath{
	return @"images/ui/panel/t81.png";
}

-(void)onEnter{
	[super onEnter];
    s_bDragonDonateSend = NO;

    //
    [self enterWindow];
}
-(void)setCrystalCount:(int)count{
    crystalCount = count;
    //
    CCLabelFX *label_crystal_text = (CCLabelFX *)[self getChildByTag:DragonDonate_crystal_text_tag];
    if (NULL == label_crystal_text) {
        label_crystal_text = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_donate_crystal",nil)
                                             dimensions:CGSizeMake(0,0)
                                              alignment:kCCTextAlignmentLeft
                                               fontName:getCommonFontName(FONT_1)
                                               fontSize:16
                                           shadowOffset:CGSizeMake(-0.5, -0.5)
                                             shadowBlur:1.0f
                                            shadowColor:ccc4(160,100,20, 128)
                                              fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_crystal_text];
        label_crystal_text.tag = DragonDonate_crystal_text_tag;
        label_crystal_text.anchorPoint = ccp(0,0);
        label_crystal_text.position = ccp(0+cFixedScale(DRAGONDONATE_LINE_W*2),0+cFixedScale(DRAGONDONATE_LINE_H*2));
    }
    //
    CCLabelFX *label_crystal = (CCLabelFX *)[self getChildByTag:DragonDonate_crystal_tag];
    if (NULL == label_crystal) {
        label_crystal = [CCLabelFX labelWithString:@""
                                             dimensions:CGSizeMake(0,0)
                                              alignment:kCCTextAlignmentLeft
                                               fontName:getCommonFontName(FONT_1)
                                               fontSize:16
                                           shadowOffset:CGSizeMake(-0.5, -0.5)
                                             shadowBlur:1.0f
                                            shadowColor:ccc4(160,100,20, 128)
                                              fillColor:ccc4(250, 230, 130, 255)];
        [self addChild:label_crystal];
        label_crystal.tag = DragonDonate_crystal_tag;
        label_crystal.anchorPoint = ccp(0,0);
    }
    [label_crystal setString:[NSString stringWithFormat:@"%d",crystalCount]];
    label_crystal.position = ccpAdd(label_crystal_text.position, ccp(label_crystal_text.contentSize.width,0));
}
-(void)setDonateValue:(int)value{
    donateValue = value;
    //
    int fize_ = 16;
    CCLabelFX *label_donate_text_1 = (CCLabelFX *)[self getChildByTag:DragonDonate_donate_text_1_tag];
    if (NULL == label_donate_text_1) {
        label_donate_text_1 = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_donate_value",nil)
                                              dimensions:CGSizeMake(0,0)
                                               alignment:kCCTextAlignmentLeft
                                                fontName:getCommonFontName(FONT_1)
                                                fontSize:fize_
                                            shadowOffset:CGSizeMake(-0.5, -0.5)
                                              shadowBlur:1.0f
                                             shadowColor:ccc4(160,100,20, 128)
                                               fillColor:ccc4(230, 220, 200, 255)];
        [self addChild:label_donate_text_1];
        label_donate_text_1.tag = DragonDonate_donate_text_1_tag;
        label_donate_text_1.anchorPoint = ccp(1,0);
        
    }

    //
    CCLabelFX *label_donate_text_2 = (CCLabelFX *)[self getChildByTag:DragonDonate_donate_text_2_tag];
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
        label_donate_text_2.tag = DragonDonate_donate_text_2_tag;
        label_donate_text_2.anchorPoint = ccp(1,0);
        
    }
    //
    [label_donate_text_2 setString:[NSString stringWithFormat:@"%d",donateValue]];
    //
    label_donate_text_2.position = ccp(self.contentSize.width-cFixedScale(DRAGONDONATE_LINE_W*2),cFixedScale(DRAGONDONATE_LINE_H*2));
    //
    label_donate_text_1.position = ccpAdd(label_donate_text_2.position, ccp(-label_donate_text_2.contentSize.width,0));
}
-(void)enterWindow{
    [GameConnection request:@"allyCrystalEnter" data:[NSDictionary dictionary] target:self call:@selector(didEnterWindow:)];
}

-(void)didEnterWindow:(id)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			CCLOG(@"did action info %@", dict);
            int lv = 0;
            int unionlv = 0;
            int nlv = 0;
            int exp = 0;
            int next_exp = 0;
            int now_exp = 0;
            NSDictionary *dict_ = nil;
            NSDictionary *dict_next = nil;
            NSDictionary *now_next = nil;
            
            int h_ = cFixedScale(DRAGONDONATE_STEP_H);
            CGPoint item_pos = ccp(self.contentSize.width/2 - cFixedScale(50),self.contentSize.height*13/20-cFixedScale(18)*2+h_);
            //
            crystalCount = [[dict objectForKey:@"cn"] intValue];
            donateValue = [[dict objectForKey:@"glory"] intValue];
            unionlv = [[dict objectForKey:@"alv"] intValue];
            //
            [self loadWindow];
            //
            int j = 1;
            //
            for (int i=DDIT_type_1; i<DDIT_type_end; i++) {
                next_exp = 0;
                now_exp = 0;
                //
                lv = [[dict objectForKey:[NSString stringWithFormat:@"lv%d",j]] intValue];
                exp = [[dict objectForKey:[NSString stringWithFormat:@"exp%d",j]] intValue];
                dict_next = [[GameDB shared] getAllBoatLevelWithType:i level:(lv+1)];
                now_next = [[GameDB shared] getAllBoatLevelWithType:i level:(lv)];
                if (now_next && [now_next objectForKey:@"exp"]) {
                    now_exp = [[now_next objectForKey:@"exp"] intValue];
                }
                if (dict_next && [dict_next objectForKey:@"exp"]) {
                    next_exp = [[dict_next objectForKey:@"exp"] intValue];
                }
                if (next_exp == 0) {
                    next_exp = now_exp;
                }else{
                    next_exp -= now_exp;
                }
                dict_ = [[GameDB shared] getAllBoatLevelWithType:i level:lv];
                if (dict_) {
                    nlv = [[dict_ objectForKey:[NSString stringWithFormat:@"nlv",j]] intValue];
                    DragonDonateItem *item = [DragonDonateItem itemWithType:i level:lv value1:[[dict_ objectForKey:@"us"] intValue] value2:1 nowExp:exp nextExp:next_exp unionLevel:unionlv needUnionLevel:nlv];
                    [self addChild:item];
                    item.position = ccpAdd(item_pos, ccp(0,-h_));
                    item.tag = DragonDonate_item1_tag+j-1;
                    item_pos = item.position;
                }else{
                    CCLOG(@"----data error!");
                }
                //
                j++;
            }
            //
            //[self loadWindow];
        }
	} else {
		CCLOG(@"获取数据不成功");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        [[Window shared] removeWindow:PANEL_UNION_Dragon_Donate];
	}
}

-(void)closeWindow{
    s_bDragonDonateSend = YES;
	[super closeWindow];
}

-(void)onExit{
    s_bDragonDonateSend = NO;
	[super onExit];
}

-(void)loadAll{
    [self loadWindow];
}

-(void)loadWindow{
    //
    CCLayerColor *bg = (CCLayerColor *)[self getChildByTag:DragonDonate_bg_tag];
    if (bg) {
        [bg removeFromParentAndCleanup:YES];
        bg = NULL;
    }
    bg = [MessageBox create:CGPointZero color:ccc4(83, 57, 32,255)];
    bg.contentSize = CGSizeMake(self.contentSize.width-cFixedScale(DRAGONDONATE_LINE_W)*2, self.contentSize.height-cFixedScale(DRAGONDONATE_LINE_H)*2-cFixedScale(47));
    //bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width-cFixedScale(DRAGONDONATE_LINE_W)*2 height:self.contentSize.height-cFixedScale(DRAGONDONATE_LINE_H)*2-cFixedScale(50) capx:cFixedScale(8) capy:cFixedScale(8)];
    bg.anchorPoint = ccp(0,0);
    [self addChild:bg];
    bg.tag = DragonDonate_bg_tag;
    bg.position = ccp(cFixedScale(DRAGONDONATE_LINE_W),cFixedScale(DRAGONDONATE_LINE_H));
    //
    CCSprite *icon = (CCSprite *)[self getChildByTag:DragonDonate_icon_tag];
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
    CCSprite *icon_f = [CCSprite spriteWithFile:@"images/ui/dragon/player_team_crystal.png"];
    if (icon && icon_f) {
        [icon addChild:icon_f];
        [icon_f setPosition:ccp(icon.contentSize.width/2, icon.contentSize.height/2)];
    }
    //
    [self addChild:icon];
    icon.anchorPoint = ccp(0,1);
    icon.position = ccp(0+cFixedScale(DRAGONDONATE_LINE_W)*3,bg.contentSize.height-cFixedScale(DRAGONDONATE_LINE_W/3));
    //icon.position = ccp(0,self.contentSize.height);
    icon.tag = DragonDonate_icon_tag;
    //
    CCLabelFX *label_npc_text = (CCLabelFX *)[self getChildByTag:DragonDonate_npc_text_tag];
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
        label_npc_text.tag = DragonDonate_npc_text_tag;
    }
    [label_npc_text setString:NSLocalizedString(@"dragon_donate_npc",nil)];
    label_npc_text.anchorPoint = ccp(0,0);
    label_npc_text.position = ccpAdd(icon.position,ccp(icon.contentSize.width+cFixedScale(18),-icon.contentSize.height/2+icon.contentSize.height/10));
    //
    CCLabelFX *label_npc_text2 = (CCLabelFX *)[self getChildByTag:DragonDonate_npc_text2_tag];
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
        label_npc_text2.tag = DragonDonate_npc_text2_tag;
    }
    [label_npc_text2 setString:NSLocalizedString(@"dragon_donate_text",nil)];
    label_npc_text2.anchorPoint = ccp(0,1);
    label_npc_text2.position = ccpAdd(icon.position,ccp(icon.contentSize.width + cFixedScale(18),-icon.contentSize.height/2-icon.contentSize.height/10));
    //
    CCLabelFX *label_power_text = (CCLabelFX *)[self getChildByTag:DragonDonate_power_tag];
    if (NULL == label_power_text) {
        label_power_text = [CCLabelFX labelWithString:@""
                                           dimensions:CGSizeMake(0,0)
                                            alignment:kCCTextAlignmentLeft
                                             fontName:getCommonFontName(FONT_1)
                                             fontSize:20
                                         shadowOffset:CGSizeMake(-0.5, -0.5)
                                           shadowBlur:1.0f
                                          shadowColor:ccc4(160,100,20, 128)
                                            fillColor:ccc4(230, 180, 60, 255)];
        [self addChild:label_power_text];
        label_power_text.anchorPoint = ccp(0.5,0);
        label_power_text.tag = DragonDonate_power_tag;
    }
    [label_power_text setString:NSLocalizedString(@"dragon_donate_title",nil)];
    label_power_text.position = ccp(self.contentSize.width/2-cFixedScale(56),self.contentSize.height*13/20);
    
    //
    [self setCrystalCount:crystalCount];
    //
    [self setDonateValue:donateValue];
}
@end
