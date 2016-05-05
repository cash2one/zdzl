//
//  RoleCultivate.m
//  TXSFGame
//
//  Created by peak on 13-7-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "RoleCultivate.h"
#import "CCSimpleButton.h"
#import "MemberSizer.h"
#import "GameConfigure.h"
#import "StretchingImg.h"
#import "GameMoney.h"
#import "PlayerDataHelper.h"
#import "InfoAlert.h"
#import "MessageAlert.h"

#define ROLE_CULTIVATE_PRIORITY (-256)
@interface RoleCultivateMenu:CCMenu
-(void) registerWithTouchDispatcher;
@end
@implementation RoleCultivateMenu
-(void) registerWithTouchDispatcher{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:(ROLE_CULTIVATE_PRIORITY-1) swallowsTouches:YES];
}
@end

#pragma mark -
#pragma mark role cultivate lalel
@interface RoleCultivateLabel:CCNode{
    NSString *labelTypeString;
    NSString *labelNameString;
    int labelValue;
    int labelBaseValue;
    int labelAddValue;
    //
    BOOL isShow;
}
@property (retain,nonatomic) NSString* labelNameString;
@property (retain,nonatomic) NSString* labelTypeString;
@property (assign,nonatomic) int labelValue;
@property (assign,nonatomic) int labelBaseValue;
@property (assign,nonatomic) int labelAddValue;
-(void)resetLabelAddValue;
@end
//
@implementation RoleCultivateLabel
enum{
    RCL_bg_1_tag = 120,
    RCL_bg_2_tag,
    RCL_name_tag,
    RCL_value_tag,
    RCL_base_value_tag,
    RCL_add_value_tag,
};
@synthesize labelNameString;
@synthesize labelTypeString;
@synthesize labelValue;
@synthesize labelBaseValue;
@synthesize labelAddValue;
-(id)init{
    if ((self = [super init])!=nil) {
        self.labelTypeString = @"";
        self.labelNameString = @"";
        labelValue  = 0;
        labelBaseValue  = 0;
        labelAddValue  = 0;
    }
    return self;
}
-(void)onEnter{
	[super onEnter];
    //
    isShow = NO;
    //
    [self loadData];
}

-(void)onExit{
    if (labelTypeString) {
        [labelTypeString release];
        labelTypeString = nil;
    }
    if (labelNameString) {
        [labelNameString release];
        labelNameString = nil;
    }
	[super onExit];
}

-(void)setLabelNameString:(NSString*)labelNameString_{
    if (labelNameString_ == nil) {
        [labelNameString release];
        labelNameString = @"";
        [labelNameString retain];
        [self removeChildByTag:RCL_name_tag cleanup:YES];
        CCLabelFX *label_name = [CCLabelFX labelWithString:labelNameString
                                                dimensions:CGSizeMake(0,0)
                                                 alignment:kCCTextAlignmentLeft
                                                  fontName:getCommonFontName(FONT_1)
                                                  fontSize:21
                                              shadowOffset:CGSizeMake(-1.5, -1.5)
                                                shadowBlur:1.0f
                                               shadowColor:ccc4(160,100,20, 128)
                                                 fillColor:ccc4(70, 150, 200, 255)];
        [self addChild:label_name z:1 tag:RCL_name_tag];
        return;
    }
    //name
    if (![labelNameString_ isEqualToString:labelNameString]) {
        [labelNameString release];
        labelNameString = labelNameString_;
        [labelNameString retain];
        [self removeChildByTag:RCL_name_tag cleanup:YES];
        CCLabelFX *label_name = [CCLabelFX labelWithString:labelNameString
                                                dimensions:CGSizeMake(0,0)
                                                 alignment:kCCTextAlignmentLeft
                                                  fontName:getCommonFontName(FONT_1)
                                                  fontSize:21
                                              shadowOffset:CGSizeMake(-1.5, -1.5)
                                                shadowBlur:1.0f
                                               shadowColor:ccc4(255,255,255, 128)
                                                 fillColor:ccc4(70, 150, 200, 255)];
        [self addChild:label_name z:1 tag:RCL_name_tag];
    }
    
}
-(void)setLabelValue:(int)labelValue_{
    //value
    labelValue = labelValue_;
    CCLabelFX *label_name = (CCLabelFX *)[self getChildByTag:RCL_name_tag];
    if (label_name) {
        [self removeChildByTag:RCL_value_tag cleanup:YES];
        CCLabelFX *label_value = [CCLabelFX labelWithString:[NSString stringWithFormat:@" %d",labelValue]
                                                 dimensions:CGSizeMake(0,0)
                                                  alignment:kCCTextAlignmentLeft
                                                   fontName:getCommonFontName(FONT_2)
                                                   fontSize:18
                                               shadowOffset:CGSizeMake(-1.5, -1.5)
                                                 shadowBlur:1.0f
                                                shadowColor:ccc4(160,100,20, 128)
                                                  fillColor:ccc4(255, 255, 255, 255)];
        [self addChild:label_value z:1 tag:RCL_value_tag];
        label_value.position =  ccp(cFixedScale(15)+label_name.position.x + label_name.contentSize.width,label_name.position.y);
    }
}
-(void)setLabelBaseValue:(int)labelBaseValue_{
    //base value
    labelBaseValue = labelBaseValue_;
    CCLabelFX *label_value = (CCLabelFX *)[self getChildByTag:RCL_value_tag];
    if (label_value) {
        [self removeChildByTag:RCL_base_value_tag cleanup:YES];
        CCLabelFX *label_base_value = [CCLabelFX labelWithString:[NSString stringWithFormat:@"+ %d",labelBaseValue]
                                                      dimensions:CGSizeMake(0,0)
                                                       alignment:kCCTextAlignmentLeft
                                                        fontName:getCommonFontName(FONT_2)
                                                        fontSize:18
                                                    shadowOffset:CGSizeMake(-1.5, -1.5)
                                                      shadowBlur:1.0f
                                                     shadowColor:ccc4(160,100,20, 128)
                                                       fillColor:ccc4(255, 255, 255, 255)];
        [self addChild:label_base_value z:1 tag:RCL_base_value_tag];
        label_base_value.position =  ccp(label_value.position.x + label_value.contentSize.width,label_value.position.y);
    }
}
-(void)setLabelAddValue:(int)labelAddValue_{
    //add value
    labelAddValue = labelAddValue_;
    CCLabelFX *label_base_value = (CCLabelFX *)[self getChildByTag:RCL_base_value_tag];
    if (label_base_value) {
        [self removeChildByTag:RCL_add_value_tag cleanup:YES];
        ccColor4B color_ = ccc4(255, 0, 0, 255);
        if (isShow==NO) {
            color_ = ccc4(255, 255, 255, 255);
        }else{
            if (labelAddValue>labelBaseValue) {
                color_ = ccc4(130, 210, 75, 255);
            }else if(labelAddValue == labelBaseValue){
                color_ = ccc4(255, 255, 255, 255);
            }
        }
        CCLabelFX *label_add_value = [CCLabelFX labelWithString:[NSString stringWithFormat:@" +%d",labelAddValue]
                                                     dimensions:CGSizeMake(0,0)
                                                      alignment:kCCTextAlignmentLeft
                                                       fontName:getCommonFontName(FONT_2)
                                                       fontSize:18
                                                   shadowOffset:CGSizeMake(-1.5, -1.5)
                                                     shadowBlur:1.0f
                                                    shadowColor:ccc4(160,100,20, 128)
                                                      fillColor:color_];
        [self addChild:label_add_value z:1 tag:RCL_add_value_tag];
        label_add_value.position =  ccp(cFixedScale(200),label_base_value.position.y);
    }
    isShow = YES;
}
-(void)resetLabelAddValue{
    CCLabelFX *label_base_value = (CCLabelFX *)[self getChildByTag:RCL_base_value_tag];
    if (label_base_value) {
        [self removeChildByTag:RCL_add_value_tag cleanup:YES];
        ccColor4B color_ = ccc4(255, 255, 255, 255);
        CCLabelFX *label_add_value = [CCLabelFX labelWithString:[NSString stringWithFormat:@" +%d",0]
                                                     dimensions:CGSizeMake(0,0)
                                                      alignment:kCCTextAlignmentLeft
                                                       fontName:getCommonFontName(FONT_2)
                                                       fontSize:18
                                                   shadowOffset:CGSizeMake(-1.5, -1.5)
                                                     shadowBlur:1.0f
                                                    shadowColor:ccc4(160,100,20, 128)
                                                      fillColor:color_];
        [self addChild:label_add_value z:1 tag:RCL_add_value_tag];
        label_add_value.position =  ccp(cFixedScale(200),label_base_value.position.y);
    }
    isShow = YES;
}
-(void)loadBG{
    //
    [self removeChildByTag:RCL_bg_1_tag cleanup:YES];
    CCSprite *bg_1 = [CCSprite spriteWithFile:@"images/ui/role_cultivate/label_bg.png"];
    bg_1 = getSpriteWithSpriteAndNewSize(bg_1, CGSizeMake(cFixedScale(130), bg_1.contentSize.height));
    [self addChild:bg_1 z:0 tag:RCL_bg_1_tag];
    bg_1.position = ccp(cFixedScale(40)+bg_1.contentSize.width/2,0);
    //
    [self removeChildByTag:RCL_bg_2_tag cleanup:YES];
    CCSprite *bg_2 = [CCSprite spriteWithFile:@"images/ui/role_cultivate/label_bg.png"];
    bg_2 = getSpriteWithSpriteAndNewSize(bg_2, CGSizeMake(cFixedScale(90), bg_2.contentSize.height));
    [self addChild:bg_2 z:0 tag:RCL_bg_2_tag];
    bg_2.position = ccpAdd(bg_1.position, ccp(bg_1.contentSize.width/2+bg_2.contentSize.width/2+cFixedScale(10),0));
}
-(void)loadData{
    [self loadBG];
    //name
    [self setLabelTypeString:labelTypeString];
    //value
    [self setLabelValue:labelValue];
    //base value
    [self setLabelBaseValue:labelBaseValue];
    //add value
    [self setLabelAddValue:labelAddValue];
}
@end

#pragma mark -
#pragma mark role cultivate
RoleCultivate *s_roleCultivate=nil;

@implementation RoleCultivate
enum{
    RCType_yinbi = 0,
    RCType_yuanbao,
};
enum{
    RC_head_bg_tag = 1020,
    RC_name_tag,
    RC_text_tag,

    RC_menu_tag,
    RC_button_yinbi_tag,
    RC_button_yuanbao_tag,
    RC_button_save_tag,
    RC_button_close_tag,
    RC_label_1_tag,
    RC_label_2_tag,
    RC_label_3_tag,
    RC_label_4_tag,
};
@synthesize labelLength;
@synthesize roleID;
@synthesize isSave;
@synthesize isSend;

-(id)init{
    if ((self = [super init])!=nil) {
        //self.contentSize = CGSizeMake(cFixedScale(432), cFixedScale(516));
        roleCultivateType = 0;
        roleQuality = 0;
        roleCultivateLevel = 0;
        roleCultivateStep = 0;
        roleID = 0;
        yinbiValue = 0;
        yuanbaoValue = 0;
        NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
        NSString *cost_str = [globalConfig objectForKey:@"roleTrainCost"];
        if (cost_str) {
            NSArray *cost_arr = [cost_str componentsSeparatedByString:@"|"];
            if (cost_arr && [cost_arr count]>1) {
                yinbiValue = [[cost_arr objectAtIndex:0] intValue];
                yuanbaoValue = [[cost_arr objectAtIndex:1] intValue];
            }else{
                CCLOG(@"data error!");
            }
        }else{
            CCLOG(@"data error!");
        }
        self.contentSize = CGSizeMake(cFixedScale(660), cFixedScale(452));
    }
    return self;
}
-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:ROLE_CULTIVATE_PRIORITY swallowsTouches:YES];
}
-(void)onEnter{
	[super onEnter];
    isSave = NO;
    isSend = NO;
    labelLength = 0;
    //
    [self LoadWindow];
    self.touchEnabled = YES;
    // 规则
    //fix chao
    RuleButton *ruleButton = [RuleButton node];
    RoleCultivateMenu *menu = (RoleCultivateMenu *)[self getChildByTag:RC_menu_tag];
    CCMenuItem *bt_close = (CCMenuItem *)[menu getChildByTag:RC_button_close_tag];
    if (bt_close) {
        ruleButton.position = ccp(bt_close.position.x- cFixedScale(FULL_WINDOW_RULE_OFF_X2), bt_close.position.y-bt_close.contentSize.height/2-cFixedScale(WINDOW_RULE_OFF_Y));
        ruleButton.type = RuleType_roleCultivate;
        ruleButton.priority = (ROLE_CULTIVATE_PRIORITY-1);
        [self addChild:ruleButton];
    }
    //end
    s_roleCultivate = self;
}

-(void)onExit{
    [GameConnection freeRequest:self];
	[super onExit];
    s_roleCultivate = nil;
}
-(CGPoint)getButtonPointWithTag:(int)tag{
    CGPoint pos;
    if (tag == RC_button_yinbi_tag) {
        pos = ccp(-self.contentSize.width/4, cFixedScale(76)-self.contentSize.height/2);
    }else if(tag == RC_button_yuanbao_tag){
        pos = ccp(0, cFixedScale(76)-self.contentSize.height/2);
    }else if(tag == RC_button_save_tag){
        pos = ccp(+self.contentSize.width/4, cFixedScale(76)-self.contentSize.height/2);
    }
    return pos;
}

-(void)addRoleHeadWith:(int)rid_ point:(CGPoint)pos{
    //
    if (rid_>0) {
        [self removeChildByTag:RC_head_bg_tag cleanup:YES];
        CCSprite *head_bg = [CCSprite spriteWithFile:@"images/ui/role_cultivate/head_bg.png"];
        CCSprite* node_ = getCharacterIcon(rid_, ICON_PLAYER_BIG);
        if (head_bg && node_) {
            [head_bg addChild:node_];
            node_.anchorPoint = ccp(0,0.5);
            node_.position = ccp(head_bg.contentSize.width/2,head_bg.contentSize.height/2);
            //
            [self addChild:head_bg z:1 tag:RC_head_bg_tag];
            head_bg.position = pos;
        }else{
            CCLOG(@"add role head error!");
        }
        
    }else{
        CCLOG(@"role id error!");
    }
}
-(void)loadRidDataWith:(int)rid_{
    if (rid_<=0) {
        return;
    }
    //image
    [self addRoleHeadWith:rid_ point:ccp(self.contentSize.width/4, cFixedScale(246)-self.contentSize.height/2)];
    //
    NSDictionary *dict_info = [[GameDB shared] getRoleupTypeInfo:rid_];
    if (dict_info) {
        //name
        NSString *name = @"";
        if (rid_>0 && rid_<10) {
            name = [[PlayerDataHelper shared] getPlayerName];//[[GameConfigure shared] getPlayerName];
        }else if(rid_>10){
            NSDictionary *dict_role_info = [[GameDB shared] getRoleInfo:rid_];
            if (dict_role_info && [dict_role_info objectForKey:@"name"]) {
                name = [dict_role_info objectForKey:@"name"];
            }
        }
        NSDictionary *role_info = [[PlayerDataHelper shared] getRole:roleID];//[[GameConfigure shared] getPlayerRoleFromListById:rid_];
        if (role_info) {
            roleQuality = [[role_info objectForKey:@"q"] intValue];
            roleCultivateLevel = [[role_info objectForKey:@"g"] intValue];
            roleCultivateStep = [[role_info objectForKey:@"c"] intValue];
            //
            //ccColor3B color_ = getColorByQuality(roleQuality);
            if ([name length]>0) {
                [self removeChildByTag:RC_name_tag cleanup:YES];
                
                CCLabelFX *label_name = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%@",name]
                                                        dimensions:CGSizeMake(0,0)
                                                         alignment:kCCTextAlignmentCenter
                                                          fontName:getCommonFontName(FONT_1)
                                                          fontSize:26
                                                      shadowOffset:CGSizeMake(-1.5, -1.5)
                                                        shadowBlur:1.0f
                                                       shadowColor:ccc4(160,100,20, 128)
                                                         fillColor:ccc4(255, 220, 150, 255)];
                [self addChild:label_name z:1 tag:RC_name_tag];
                label_name.position =ccp(0,self.contentSize.height/2-cFixedScale(32));
            }
            //
            NSString* info=nil;
            NSString* info_temp=nil;
            //
            NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
            info_temp = info = [globalConfig objectForKey:@"grow_up"];
            NSArray *nameKeyArray = nil;
            if (info) {
                nameKeyArray = [info componentsSeparatedByString:@"|"];
            }
            //
            int level = [[PlayerDataHelper shared] getPlayerLevel];//[[GameConfigure shared] getPlayerLevel];
            NSDictionary* dict =[[GameDB shared] getRoleLevelInfo:roleID level:level];
            BaseAttribute r1 = BaseAttributeFromDict(dict);
            r1 = BaseAttributeCheck(r1);
            info = BaseAttributeToDisplayStringWithFilter(r1, info);
            NSArray * t_nameArray = nil;
            if (info) {
               t_nameArray = [info componentsSeparatedByString:@"|"];
            }
            CCLOG(info);
            //
            NSDictionary* d1 = [role_info objectForKey:@"tr"];
            BaseAttribute r2 = BaseAttributeFromDict(d1);
            info = BaseAttributeToDisplayStringWithFilter(r2, info_temp);
            NSArray *info_array = [info componentsSeparatedByString:@"|"];
            //
            if(t_nameArray && nameKeyArray && [t_nameArray count]>0 && [nameKeyArray count] == [t_nameArray count]){
                //1
                int h_ = 56;
                int off_h = (h_*[nameKeyArray count])/2;
                for (int i=0;i<[nameKeyArray count];i++) {
                    NSString *str_ = [t_nameArray objectAtIndex:i];
                    NSArray *array_ = [str_ componentsSeparatedByString:@":"];
                    if (array_ && [array_ count]>1) {
                        [self removeChildByTag:RC_label_1_tag+i cleanup:YES];
                        RoleCultivateLabel *rcl_label = [RoleCultivateLabel node];
                        rcl_label.labelNameString = [array_ objectAtIndex:0];
                        rcl_label.labelTypeString = [nameKeyArray objectAtIndex:i];
                        rcl_label.labelValue = [[array_ objectAtIndex:1] intValue];
                        int addBaseValue = 0;
                        if (info_array && [info_array count]>i) {
                            NSString *tt_str_name = [info_array objectAtIndex:i];
                            NSArray *tt_array_name = [tt_str_name componentsSeparatedByString:@":"];
                            if (tt_array_name && [tt_array_name count]>1) {
                                if ([ [tt_array_name objectAtIndex:0] isEqualToString:[array_ objectAtIndex:0] ]) {
                                    addBaseValue = [[tt_array_name objectAtIndex:1] intValue];
                                }
                            }
                            
                        }
                        rcl_label.labelBaseValue = addBaseValue;
                        [self addChild:rcl_label z:1 tag:RC_label_1_tag+i];
                        rcl_label.position = ccp(cFixedScale(82)-self.contentSize.width/2,cFixedScale(off_h-i*h_));
                        //
                        labelLength = i+1;
                    }else{
                        CCLOG(@"array data error!");
                    }
                    
                }
            }
        }
                
        //load text
        //[self loadText];
    }
}
-(void)LoadWindow{
    
    CCSprite *bg = [StretchingImg stretchingImg:@"images/ui/bound2.png" width:self.contentSize.width height:self.contentSize.height capx:cFixedScale(8) capy:cFixedScale(8)];
    if (bg) {
        [self addChild:bg];
        bg.position = ccp(0,0);
    }

    //
     CCSprite *line = [CCSprite spriteWithFile:@"images/ui/alert/line.png"];
    if (line) {
        line = getSpriteWithSpriteAndNewSize(line, CGSizeMake(cFixedScale(356), cFixedScale(2)));
        [self addChild:line];
        line.position = ccp(0,cFixedScale(404-2)-self.contentSize.height/2);
    }

   //button
    [self loadButton];
    //roles
    [self loadRidDataWith:roleID];
}
-(void)loadButton{
    //
    [self removeChildByTag:RC_menu_tag cleanup:YES];
    RoleCultivateMenu *menu = [RoleCultivateMenu node];
    [self addChild:menu z:1 tag:RC_menu_tag];
    menu.position = ccp(0,0);
    
    //close
    NSArray *bt_arr = getBtnSprite(@"images/ui/worldboss/btn_tipsclose.png");
    if (bt_arr && [bt_arr count]>1) {
        CCMenuItem *bt_close = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:[bt_arr objectAtIndex:1] target:self selector:@selector(closeWindowBack)];
        bt_close.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
        bt_close.anchorPoint = ccp(1,1);
        [menu addChild:bt_close z:1 tag:RC_button_close_tag];
    }

    
    //yin bi
    bt_arr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_yinbi_cultivate");
    if (bt_arr && [bt_arr count]>2) {
        CCMenuItem *bt_yinbi = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:[bt_arr objectAtIndex:1] disabledSprite:[bt_arr objectAtIndex:2] target:self selector:@selector(buttonBack:)];;
        [menu addChild:bt_yinbi z:1 tag:RC_button_yinbi_tag];
        bt_yinbi.position = [self getButtonPointWithTag:RC_button_yinbi_tag];
        //
        GameMoney *yinbi = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:yinbiValue];
        [self addChild:yinbi z:1];
        yinbi.position = ccpAdd(bt_yinbi.position, ccp(0,-bt_yinbi.contentSize.height));
    }
    //yuan bao
    bt_arr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_yuanbao_cultivate");
    if (bt_arr && [bt_arr count]>2) {
        CCMenuItem *bt_yuanbao = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:[bt_arr objectAtIndex:1] disabledSprite:[bt_arr objectAtIndex:2] target:self selector:@selector(buttonBack:)];;
        [menu addChild:bt_yuanbao z:1 tag:RC_button_yuanbao_tag];
        bt_yuanbao.position = [self getButtonPointWithTag:RC_button_yuanbao_tag];
        //
        GameMoney *yuanbao = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:yuanbaoValue];
        [self addChild:yuanbao z:1];
        yuanbao.position = ccpAdd(bt_yuanbao.position, ccp(0,-bt_yuanbao.contentSize.height));
    }
    //save
    bt_arr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_save");
    if (bt_arr && [bt_arr count]>2) {
        CCMenuItem *bt_save = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:[bt_arr objectAtIndex:1] disabledSprite:[bt_arr objectAtIndex:2] target:self selector:@selector(buttonBack:)];;
        [menu addChild:bt_save z:1 tag:RC_button_save_tag];
        bt_save.position = [self getButtonPointWithTag:RC_button_save_tag];
    }
    //
    [self checkButtonState];
}
-(void)checkButtonState{
    CCMenu *menu = (CCMenu *)[self getChildByTag:RC_menu_tag];
    if (menu) {
        CCMenuItemSprite *bt_yinbi = (CCMenuItemSprite *)[menu getChildByTag:RC_button_yinbi_tag];
        CCMenuItemSprite *bt_yuanbao = (CCMenuItemSprite *)[menu getChildByTag:RC_button_yuanbao_tag];
        CCMenuItemSprite *bt_save = (CCMenuItemSprite *)[menu getChildByTag:RC_button_save_tag];
        NSDictionary *player_dict = [[PlayerDataHelper shared] getPlayerInfo];//[[GameConfigure shared] getPlayerInfo];
  
        if (player_dict) {
            if (bt_yinbi){
                if([player_dict objectForKey:@"coin1"] &&
                   [[player_dict objectForKey:@"coin1"] intValue]<yinbiValue
                   ) {
                    [bt_yinbi setIsEnabled:NO];
                }else{
                    [bt_yinbi setIsEnabled:YES];
                }
            }
            if ( bt_yuanbao ){
                if([player_dict objectForKey:@"coin2"] &&
                   [player_dict objectForKey:@"coin3"] &&
                   ([[player_dict objectForKey:@"coin2"] intValue]+[[player_dict objectForKey:@"coin3"] intValue]<yuanbaoValue)
                   ){
                    [bt_yuanbao setIsEnabled:NO];
                }else{
                    [bt_yuanbao setIsEnabled:YES];
                }
            }
        }
        if (bt_save) {
            if(isSave){
                [bt_save setIsEnabled:YES];
            }else{
                [bt_save setIsEnabled:NO];
            }
        }
        
    }
}

-(void)labelSaveData{
    for (int i=0; i<labelLength; i++) {
        RoleCultivateLabel *rcl_label = (RoleCultivateLabel *)[s_roleCultivate getChildByTag:RC_label_1_tag+i];
        if (rcl_label) {
            [rcl_label setLabelBaseValue:[rcl_label labelAddValue]];
            [rcl_label resetLabelAddValue];
        }
    }
}

-(void)loadText{
    [self removeChildByTag:RC_text_tag cleanup:YES];
    NSString *str_name = getRoleUpStringWithQuality(roleQuality);
    NSString *text_string = [NSString stringWithFormat:NSLocalizedString(@"role_cultivate_text",nil),NSLocalizedString(str_name,nil),roleCultivateLevel,roleCultivateStep];
    CCLabelFX *label_text = [CCLabelFX labelWithString:text_string
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:21
                                          shadowOffset:CGSizeMake(-1.5, -1.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 180, 60, 255)];
    /*
    CCLabelFX *label_text = [CCLabelFX labelWithString:[NSString stringWithFormat:@"当前: %@ %d段 第%d格",str_name,roleCultivateLevel,roleCultivateStep]
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:21
                                          shadowOffset:CGSizeMake(-1.5, -1.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(230, 180, 60, 255)];
     */
    [self addChild:label_text z:1 tag:RC_text_tag];
    label_text.anchorPoint = ccp(0,0.5);
    label_text.position = ccp(cFixedScale(42-20)-self.contentSize.width/2,cFixedScale(350)-self.contentSize.height/2);
}
-(void)closeWindow{
    [self removeFromParentAndCleanup:YES];
}
-(void)closeWindowWithSave{
    NSMutableDictionary *dict_save = [NSMutableDictionary dictionary];
    [dict_save setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
    //
    NSMutableDictionary *dict_save_arg = [NSMutableDictionary dictionary];
    [dict_save_arg setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
    NSMutableDictionary *dict_save_tr = [NSMutableDictionary dictionary];
    for (int i=0; i<labelLength; i++) {
        RoleCultivateLabel *rcl_label = (RoleCultivateLabel *)[self getChildByTag:RC_label_1_tag+i];
        if (rcl_label) {
            [dict_save_tr setObject:[NSNumber numberWithInt:[rcl_label labelAddValue]] forKey:rcl_label.labelTypeString];
        }
    }
    [dict_save_arg setObject:dict_save_tr forKey:@"tr"];
    //
    isSend = YES;
    [GameConnection request:@"roleUpTrainOk" data:dict_save target:[RoleCultivate class] call:@selector(didRoleCultivateSave::) arg:dict_save_arg];
    //
    [self closeWindow];
}
-(void)closeWindowBack{
    if (isSave && isSend==NO) {
        [[AlertManager shared] showMessage:[NSString stringWithFormat:NSLocalizedString(@"role_cultivate_save",nil)]
                                    target:self
                                   confirm:@selector(closeWindowWithSave)
                                     canel:@selector(closeWindow)];
    }else{
        [self closeWindow];
    }
    
}
-(void)buttonBack:(CCNode*)node{
    if (isSend) {
        return;
    }
    if (node) {
        switch (node.tag) {
            case RC_button_yinbi_tag:
            {
                CCLOG(@"yin bi button...");
                NSMutableDictionary *dict_yinbi = [NSMutableDictionary dictionary];
                [dict_yinbi setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
                [dict_yinbi setObject:[NSNumber numberWithInt:RCType_yinbi] forKey:@"type"];
                isSend = YES;
                [GameConnection request:@"roleUpTrain" data:dict_yinbi target:[RoleCultivate class] call:@selector(didRoleCultivate:)];
            }
                break;
            case RC_button_yuanbao_tag:
            {
                CCLOG(@"yuan bao button...");
                //
                BOOL isRecordBait = [[[GameConfigure shared] getPlayerRecord:NO_REMIDE_ROLE_CULTIVATE_SYMBOL] boolValue];
                if (isRecordBait) {
                    [RoleCultivate buyEvent];
                } else {
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"role_cultivate_yuanbao_buy",nil),yuanbaoValue];
                    MessageAlert *alert = (MessageAlert *)[[AlertManager shared] showMessageWithSettingFormFather:message target:[RoleCultivate class] confirm:@selector(buyEvent) key:NO_REMIDE_ROLE_CULTIVATE_SYMBOL father:[Window shared]];
                    alert.canel = @selector(cancel);
                }
                //
                /*
                NSMutableDictionary *dict_yuanbao = [NSMutableDictionary dictionary];
                [dict_yuanbao setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
                [dict_yuanbao setObject:[NSNumber numberWithInt:RCType_yuanbao] forKey:@"type"];
                isSend = YES;
                [GameConnection request:@"roleUpTrain" data:dict_yuanbao target:[RoleCultivate class] call:@selector(didRoleCultivate:)];
                 */
            }
                
                break;
            case RC_button_save_tag:
            {
                CCLOG(@"save button...");
                
                NSMutableDictionary *dict_save = [NSMutableDictionary dictionary];
                [dict_save setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
                //
                NSMutableDictionary *dict_save_arg = [NSMutableDictionary dictionary];
                [dict_save_arg setObject:[NSNumber numberWithInt:roleID] forKey:@"rid"];
                NSMutableDictionary *dict_save_tr = [NSMutableDictionary dictionary];
                for (int i=0; i<labelLength; i++) {
                    RoleCultivateLabel *rcl_label = (RoleCultivateLabel *)[self getChildByTag:RC_label_1_tag+i];
                    if (rcl_label) {
                        [dict_save_tr setObject:[NSNumber numberWithInt:[rcl_label labelAddValue]] forKey:rcl_label.labelTypeString];
                    }
                }
                [dict_save_arg setObject:dict_save_tr forKey:@"tr"];
                //
                isSend = YES;
                [GameConnection request:@"roleUpTrainOk" data:dict_save target:[RoleCultivate class] call:@selector(didRoleCultivateSave::) arg:dict_save_arg];
                /*
                isSend = YES;
                [GameConnection request:@"roleUpTrainOk" data:[NSDictionary dictionary] target:[RoleCultivate class] call:@selector(didRoleCultivateSave:)];
                 */
            }
                break;
            default:
                break;
        }
    }
}
+(void)buyEvent{
    //
    if (s_roleCultivate) {
        NSMutableDictionary *dict_yuanbao = [NSMutableDictionary dictionary];
        [dict_yuanbao setObject:[NSNumber numberWithInt:s_roleCultivate.roleID] forKey:@"rid"];
        [dict_yuanbao setObject:[NSNumber numberWithInt:RCType_yuanbao] forKey:@"type"];
        s_roleCultivate.isSend = YES;
        [GameConnection request:@"roleUpTrain" data:dict_yuanbao target:[RoleCultivate class] call:@selector(didRoleCultivate:)];
    }
}
+(void)cancel{
    if (s_roleCultivate) {
        s_roleCultivate.isSend = NO;
    }
}
+(void)didRoleCultivate:(NSDictionary*)sender{
    if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if (!data) {
			CCLOG(@"data error");
            if(s_roleCultivate){
            s_roleCultivate.isSend = NO;
            }
			return;
		}
        NSDictionary *add_dict = [data objectForKey:@"radd"];
        if(s_roleCultivate){
            if(add_dict){
                for (int i=0; i<s_roleCultivate.labelLength; i++) {
                    RoleCultivateLabel *rcl_label = (RoleCultivateLabel *)[s_roleCultivate getChildByTag:RC_label_1_tag+i];
                    if (rcl_label) {
                        NSNumber *t_num = [add_dict objectForKey:rcl_label.labelTypeString];
                        if (t_num) {
                            [rcl_label setLabelAddValue:[t_num intValue]];
                        }
                    }
                }
            }
        }
        if ([data objectForKey:@"update"]) {
            if ([PlayerDataHelper shared]) {
                [[PlayerDataHelper shared] updatePackage:[data objectForKey:@"update"]];
            }else{
                [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
            }
        }
        if(s_roleCultivate){
            s_roleCultivate.isSave = YES;
            [s_roleCultivate checkButtonState];
        }
    }else{
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    if(s_roleCultivate){
        s_roleCultivate.isSend = NO;
    }
}
+(void)didRoleCultivateSave:(NSDictionary*)sender :(NSDictionary*)arg{
    if (checkResponseStatus(sender)) {
        NSMutableDictionary *dict_save_tr = [arg objectForKey:@"tr"];
        
        if ([PlayerDataHelper shared]) {
            int roleID_ = [[arg objectForKey:@"rid"] intValue];
            NSDictionary* roleinfo = [[PlayerDataHelper shared] getRole:roleID_];//[[GameConfigure shared] getPlayerRoleFromListById:roleID];
            if (roleinfo && dict_save_tr) {
                NSMutableDictionary *mut_dict = [NSMutableDictionary dictionaryWithDictionary:roleinfo];
                [mut_dict setObject:dict_save_tr forKey:@"tr"];
                [[PlayerDataHelper shared] updateRoleByDict:mut_dict];
                //
                [[PlayerDataHelper shared] updateAllPower];
            }
        }else{
            int roleID_ = [[arg objectForKey:@"rid"] intValue];
            NSDictionary* roleinfo = [[GameConfigure shared] getPlayerRoleFromListById:roleID_];
            if (roleinfo && dict_save_tr) {
                NSMutableDictionary *mut_dict = [NSMutableDictionary dictionaryWithDictionary:roleinfo];
                [mut_dict setObject:dict_save_tr forKey:@"tr"];
                [[GameConfigure shared] updateRoleByDict:mut_dict];
            }
        }
        
        if(s_roleCultivate){
            s_roleCultivate.isSave = NO;
            [s_roleCultivate checkButtonState];
            [s_roleCultivate labelSaveData];
        }
        
    }else{
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    if(s_roleCultivate){
        s_roleCultivate.isSend = NO;
    }
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}
@end
