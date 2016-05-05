//
//  RoleUp.m
//  TXSFGame
//
//  Created by peak on 13-7-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "RoleUp.h"
#import "GameConfigure.h"
#import "MemberSizer.h"
#import "StretchingImg.h"
#import "GameDB.h"
#import "CCNode+AddHelper.h"
#import "CFPage.h"
#import "SectionManager.h"
#import "Config.h"
#import "MessageAlert.h"
#import "RoleManager.h"
#import "RolePlayer.h"

#define SECTION_WIDTH (480)


int sortSectionKeyArray(id p1, id p2, void*context){
    NSNumber *n1 = (NSNumber *)p1;
    NSNumber *n2 = (NSNumber *)p2;
	int quality1 = [n1  intValue];
	int quality2 = [n2 intValue];
	
	if(quality1<quality2){
		return NSOrderedAscending;
	}else if(quality1==quality2){
        return NSOrderedSame;
	}else if(quality1>quality2){
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

static int getRoleUpType(int _rid){
	NSDictionary* dict = [[GameDB shared] getRoleupTypeInfo:_rid];
	return [[dict objectForKey:@"type"] intValue];
}

static NSDictionary* getRoleGradeInfo(int _rid){
	int quality = [[GameConfigure shared] getRoleQualityWithRid:_rid];
	int type = getRoleUpType(_rid);
	return [[GameDB shared] getRoleupQualityInfo:type quality:quality];
}

#pragma mark -
#pragma mark role up step display
@interface RoleUpStepDisplay:CCNode{
    int roleUpQuality;
    int roleUpLevel;
    int roleUpStep;
    //
    int roleRID;
    NSString *nameString;
    //
    BOOL isUpdateState;
}
@property (assign,nonatomic) int roleRID;
@property (assign,nonatomic) int roleUpLevel;
@property (assign,nonatomic) int roleUpStep;
@property (assign,nonatomic) int roleUpQuality;
@property (retain,nonatomic) NSString* nameString;
@end
//
@implementation RoleUpStepDisplay
enum{
    RUSD_bg_tag = 301,
    RUSD_name_tag,
    RUSD_property_tag,
    RUSD_property_node_tag,
    RUSD_label_01_tag,
};
@synthesize roleRID;
@synthesize roleUpLevel;
@synthesize roleUpStep;
@synthesize roleUpQuality;
@synthesize nameString;
-(id)init{
    if ((self = [super init])!=nil) {
        //
        roleUpQuality = 0;
        roleUpLevel = 0;
        roleUpStep = 0;
        self.nameString = @"";
        //
        roleRID = 0;
        isUpdateState = NO;
        self.contentSize = CGSizeMake(cFixedScale(145), cFixedScale(150));
    }
    return self;
}
-(void)onEnter{
    [super onEnter];
    //
    CCNode *node = [CCNode node];
    if (node) {
        [self addChild:node z:1 tag:RUSD_property_node_tag];
        node.position = ccp(0,0);
        node.contentSize = self.contentSize;
    }
    [self schedule:@selector(updateState)];
}
-(void)onExit{
    if (nameString) {
        [nameString release];
        nameString = nil;
    }
    isUpdateState = NO;
    [super onExit];
}
-(void)setNameString:(NSString *)nameString_{
    if (nameString_) {
        if (![nameString_ isEqualToString:nameString]) {
            [nameString release];
            nameString = nameString_;
            [nameString retain];
            //
            isUpdateState = YES;
        }
    }else{
        [nameString release];
        nameString = @"";
        [nameString retain];
        //
        isUpdateState = YES;
    }
    
}
-(void)setRoleRID:(int)roleRID_{
    if (roleRID!=roleRID_) {
        roleRID = roleRID_;
        //
        isUpdateState = YES;
    }
}
-(void)setRoleUpLevel:(int)roleUpLevel_{
    if (roleUpLevel!=roleUpLevel_) {
        roleUpLevel = roleUpLevel_;
        //
        isUpdateState = YES;
    }
}
-(void)setRoleUpStep:(int)roleUpStep_{
    if (roleUpStep!=roleUpStep_) {
        roleUpStep = roleUpStep_;
        //
        isUpdateState = YES;
    }
}
-(void)setRoleUpQuality:(int)roleUpQuality_{
    if (roleUpQuality!=roleUpQuality_) {
        roleUpQuality = roleUpQuality_;
        //
        isUpdateState = YES;
    }
}
-(void)loadWindowWithDict:(NSDictionary*)dict{
    if (dict) {
        int h_=0;
        int h_off = 0;
        if (iPhoneRuningOnGame()) {
            h_off = 5;
        }
        //bg
        //[self removeChildByTag:RUSD_bg_tag cleanup:YES];
        CCSprite *bg = (CCSprite *)[self getChildByTag:RUSD_bg_tag];
        if (!bg) {
            bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width height:self.contentSize.height capx:cFixedScale(8) capy:cFixedScale(8)];
            if (bg) {
                [self addChild:bg z:0 tag:RUSD_bg_tag];
                bg.position = ccp(0,0);
            }
        }
        //name
        //[self removeChildByTag:RUSD_name_tag cleanup:YES];
        CCLabelFX *name_label = (CCLabelFX *)[self getChildByTag:RUSD_name_tag];
        if (!name_label) {
            name_label = [CCLabelFX labelWithString:@""
                                         dimensions:CGSizeMake(0,0)
                                          alignment:kCCTextAlignmentCenter
                                           fontName:getCommonFontName(FONT_1)
                                           fontSize:21
                                       shadowOffset:CGSizeMake(-0.5, -0.5)
                                         shadowBlur:1.0f
                                        shadowColor:ccc4(255,255,255,200)
                                          fillColor:ccc4(255,255,255,255)];
            [self addChild:name_label z:1 tag:RUSD_name_tag];
        }
        [name_label setString:nameString];
        name_label.anchorPoint = ccp(0.5,1);
        name_label.position = ccp(0,self.contentSize.height/2 - h_);
        h_ += cFixedScale(name_label.contentSize.height + h_off);
        //property
        //[self removeChildByTag:RUSD_property_tag cleanup:YES];
        CCLabelFX *property_label = (CCLabelFX *)[self getChildByTag:RUSD_property_tag];
        if (!property_label) {
            property_label = [CCLabelFX labelWithString:@""
                                                       dimensions:CGSizeMake(0,0)
                                                        alignment:kCCTextAlignmentCenter
                                                         fontName:getCommonFontName(FONT_1)
                                                         fontSize:18
                                                     shadowOffset:CGSizeMake(-0.5, -0.5)
                                                       shadowBlur:1.0f
                                                      shadowColor:ccc4(255,255,255,200)
                                                        fillColor:ccc4(255,255,255,255)];
            [self addChild:property_label z:1 tag:RUSD_property_tag];
        }
        NSString *property_name_str = NSLocalizedString(getRoleUpStringWithQuality(roleUpQuality),nil);
        NSString *property_Str = [NSString stringWithFormat:NSLocalizedString(@"role_up_text",nil),property_name_str,roleUpLevel,roleUpStep];
        [property_label setString:property_Str];
        property_label.anchorPoint = ccp(0.5,1);
        property_label.position = ccp(0,self.contentSize.height/2 - h_);
        h_ += cFixedScale(property_label.contentSize.height + h_off);
        //
        CCNode *property_node = (CCNode *)[self getChildByTag:RUSD_property_node_tag];
        if (property_node) {
            //
            [property_node removeAllChildrenWithCleanup:YES];
            //
            NSString *info_ = nil;
            NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
            info_ = [globalConfig objectForKey:@"grow_up"];
            BaseAttribute r2 = BaseAttributeFromDict(dict);
            info_ = BaseAttributeToDisplayStringWithFilter(r2, info_);
            NSArray *info_array = [info_ componentsSeparatedByString:@"|"];
            if(info_array){
                for (int i=0;i<[info_array count];i++) {
                    NSString *str_ = [info_array objectAtIndex:i];
                    NSArray *array_ = [str_ componentsSeparatedByString:@":"];
                    if (array_ && [array_ count]>1) {
                        if ([[array_ objectAtIndex:1] intValue]!=0) {
                            NSString *label_str = [NSString stringWithFormat:@" %@ %d",[array_ objectAtIndex:0],[[array_ objectAtIndex:1] intValue]];
                            CCSprite *text_label = [CCLabelFX labelWithString:label_str
                                                                   dimensions:CGSizeMake(0,0)
                                                                    alignment:kCCTextAlignmentCenter
                                                                     fontName:getCommonFontName(FONT_1)
                                                                     fontSize:18
                                                                 shadowOffset:CGSizeMake(-0.5, -0.5)
                                                                   shadowBlur:1.0f
                                                                  shadowColor:ccc4(255,255,255,200)
                                                                    fillColor:ccc4(0,255,0,255)];
                            [property_node addChild:text_label z:1 tag:RUSD_label_01_tag+i];
                            text_label.anchorPoint = ccp(0,1);
                            text_label.position = ccp(-property_node.contentSize.width/2,property_node.contentSize.height/2-h_);
                            h_ += cFixedScale(text_label.contentSize.height + h_off);
                        }
                    }
                }
            }
        } //if property_node
        self.visible = YES;
    }else{
        self.visible = NO;
    }
    
}
-(void)updateState{
    if (!isUpdateState) {
        return;
    }
    //
    //[self removeAllChildrenWithCleanup:YES];
    //
    NSDictionary *role_up_dict = [[GameDB shared] getRoleupTypeInfo:roleRID];
    if (role_up_dict && [role_up_dict objectForKey:@"type"]) {
        
        int type_ = [[role_up_dict objectForKey:@"type"] intValue];
		NSDictionary *role_up_info_dict = [[GameDB shared] getRoleupInfo:type_ quality:roleUpQuality grade:roleUpLevel check:roleUpStep];
        if(role_up_info_dict && [role_up_info_dict objectForKey:@"attr"]){
            [self loadWindowWithDict:[role_up_info_dict objectForKey:@"attr"]];
        }else{
            self.visible = NO;
        }
    }else{
        self.visible = NO;
    }
    //
    isUpdateState = NO;
}
@end

#pragma mark -
#pragma mark role up
static RoleUp *s_roleUp = nil;
static int *s_roleUp_rid = 0;

@implementation RoleUp
enum{
    RU_bg_tag,
    RU_name_text_tag = 111,
    RU_quality_text_tag,
    RU_symbol_text_tag,
    RU_role_up_count_text_tag,
    //
    RU_name_tag,
    RU_quality_tag,
    RU_symbol_tag,
    RU_role_up_count_tag,
    //
    RU_section_manager_tag,
    //
    RU_now_step_display_tag,
    RU_next_step_display_tag,
    //
    RU_menu_tag,
    RU_button_green_tag,
    RU_button_blue_tag,
    RU_button_purple_tag,
    RU_button_orange_tag,
};
@synthesize roleRID;
@synthesize symbolID;
@synthesize symbolCount;
@synthesize symbolCost;
@synthesize roleUpQuality;
@synthesize roleUpCount;
@synthesize nameString;
@synthesize isSend;
@synthesize isMoveContent;
-(id)init{
    if ((self = [super init])!=nil) {
        symbolCount = 0;
        
        roleUpCount = 0;
        //
        roleUpStartQuality = selectQuality = roleUpQuality = 0;
        roleUpLevel = 0;
        roleUpStep = 0;
        self.nameString = @"";
        isMoveContent = NO;
        isSend = NO;
        //
        roleRID = 0;
        symbolID = 0;
        symbolCost = 0;
        
        NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
        NSString *cost_str = [globalConfig objectForKey:@"roleUpCost"];
        if (cost_str) {
            NSArray *cost_arr = [cost_str componentsSeparatedByString:@"|"];
            if (cost_arr && [cost_arr count]>1) {
                symbolID = [[cost_arr objectAtIndex:0] intValue];
                symbolCost = [[cost_arr objectAtIndex:1] intValue];
            }else{
                CCLOG(@"role up data error!");
            }
        }else{
            CCLOG(@"role up data error!");
        }
    }
    return self;
}
+(void)setRoleUpStaticRid:(int)rid{
    s_roleUp_rid = rid;
}
-(void)onEnter{
	[super onEnter];
    self.touchEnabled = YES;
    roleRID = s_roleUp_rid;
    //
    s_roleUp = self;
    //
    [self enterWindow];
    //
    //[self loadWindow];
	
	//	//todo test
	//	Section* section = [Section node];
	//	[section showSction:[NSDictionary dictionary]];
	//	[self Category_AddChildToCenter:section z:10];
	
}

-(void)enterWindow{
    [GameConnection request:@"roleUpEnter" data:[NSDictionary dictionary] target:self call:@selector(didEnterWindow:)];
}
-(void)didEnterWindow:(id)sender{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict && [dict objectForKey:@"update"]) {
            //
            NSDictionary *data_dict =[dict objectForKey:@"update"];
            if (data_dict) {
                NSArray *allKeys = [data_dict allKeys];
                NSArray *playerRoleList = [[GameConfigure shared] getPlayerRoleList];
                for (NSNumber *key in allKeys) {
                    if (key) {
                        int n = [[data_dict objectForKey:key] intValue];
                        int role_id = [key intValue];
                        for (NSDictionary *playerRole_dict in playerRoleList) {
                            if (playerRole_dict) {
                                int playerRoleId = [[playerRole_dict objectForKey:@"id"] intValue];
                                if (playerRoleId == role_id) {
                                    //
                                    NSMutableDictionary *rid_mut_dict = [NSMutableDictionary dictionaryWithDictionary:playerRole_dict];
                                    [rid_mut_dict setObject:[NSNumber numberWithInt:n] forKey:@"n"];
                                    [[GameConfigure shared] updateRoleByDict:rid_mut_dict];
                                }
                            }
                        }
                    }
                }
            }
        }
        //
        [self loadWindow];
    }else{
        CCLOG(@"数据错误......");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        [[Window shared] removeWindow:PANEL_ROLE_UP];
    }
}
-(void)onExit{
    if (nameString) {
        [nameString release];
        nameString = nil;
    }
    //[GameConnection freeRequest:self];
	[super onExit];
    s_roleUp = nil;
    s_roleUp_rid = 0;
}

+(void)didAutoShopBuy:(id)sender{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            // 更新背包
            [[GameConfigure shared] updatePackage:dict];
            if (s_roleUp) {
                [s_roleUp loadRidDataWithRid:[s_roleUp roleRID]];
                //
                NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
                [dict_ setObject:[NSNumber numberWithInt:[s_roleUp roleRID]] forKey:@"rid"];
                NSMutableDictionary *dict_arg = [NSMutableDictionary dictionary];
                [dict_arg setObject:[NSNumber numberWithInt:[s_roleUp roleRID]] forKey:@"rid"];
                [GameConnection request:@"roleUpDo" data:dict_ target:[s_roleUp class] call:@selector(didRoleUpButton::) arg:dict_arg];
                return;
            }
        }
    } else {
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    if (s_roleUp) {
        s_roleUp.isSend = NO;
    }
}

+(void)didShopBuy:(id)sender{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            // 更新背包
            [[GameConfigure shared] updatePackage:dict];
            if (s_roleUp) {
                [s_roleUp loadRidDataWithRid:[s_roleUp roleRID]];
            }
        }
    } else {
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    if (s_roleUp) {
        s_roleUp.isSend = NO;
    }
}

+(void)autoBuyEvent{
    if (s_roleUp) {
        
        int _id = 0;
        NSDictionary *itemDict = [[GameDB shared] getDireShopInfo:s_roleUp.symbolID];
        if (itemDict) {
            _id = [[itemDict objectForKey:@"id"] intValue];
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:[NSNumber numberWithInt:_id] forKey:@"id"];
        [dict setValue:[NSNumber numberWithInt:1] forKey:@"c"];
        
        [GameConnection request:@"dshopBuy" data:dict target:[RoleUp class] call:@selector(didAutoShopBuy:)];
    }
}
+(void)buyEvent{
    if (s_roleUp) {
        
        int _id = 0;
        NSDictionary *itemDict = [[GameDB shared] getDireShopInfo:s_roleUp.symbolID];
        if (itemDict) {
            _id = [[itemDict objectForKey:@"id"] intValue];
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:[NSNumber numberWithInt:_id] forKey:@"id"];
        [dict setValue:[NSNumber numberWithInt:1] forKey:@"c"];
        
        [GameConnection request:@"dshopBuy" data:dict target:[RoleUp class] call:@selector(didShopBuy:)];
    }
}

+(void)cancel{
    if (s_roleUp) {
        s_roleUp.isSend = NO;
    }
}

+(void)buttonBack{
    SectionManager *sectionManager = (SectionManager *)[s_roleUp getChildByTag:RU_section_manager_tag];
    if (sectionManager && sectionManager.isShowFrameEffect==YES) {
        return;
    }
    if (s_roleUp && s_roleUp.isSend == NO && s_roleUp.isMoveContent == NO ) {
        if(s_roleUp.roleUpCount<=0){
          [ShowItem showErrorAct:@"431"];  
        }else if (s_roleUp.symbolCount < s_roleUp.symbolCost) {
            //[ShowItem showErrorAct:@"31"];
            int value_ = 0;
            NSDictionary *itemDict = [[GameDB shared] getDireShopInfo:s_roleUp.symbolID];
            if (itemDict && [itemDict objectForKey:@"coin3"]) {
                value_ = [[itemDict objectForKey:@"coin3"] intValue];
            }else{
                CCLOG(@"data error.....");
                return;
            }
            //
            BOOL isRecordBait = [[[GameConfigure shared] getPlayerRecord:NO_REMIDE_ROLE_UP_SYMBOL] boolValue];
            if (isRecordBait) {
                [RoleUp autoBuyEvent];
            } else {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"role_up_yuanbao_buy",nil),value_,1];
                MessageAlert *alert = (MessageAlert *)[[AlertManager shared] showMessageWithSettingFormFather:message target:[RoleUp class] confirm:@selector(buyEvent) key:NO_REMIDE_ROLE_UP_SYMBOL father:[Window shared]];
                alert.canel = @selector(cancel);
            }
            //
            s_roleUp.isSend = YES;
        }else{
            NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
            [dict_ setObject:[NSNumber numberWithInt:[s_roleUp roleRID]] forKey:@"rid"];
            NSMutableDictionary *dict_arg = [NSMutableDictionary dictionary];
            [dict_arg setObject:[NSNumber numberWithInt:[s_roleUp roleRID]] forKey:@"rid"];
            [GameConnection request:@"roleUpDo" data:dict_ target:[s_roleUp class] call:@selector(didRoleUpButton::) arg:dict_arg];
        }
    }
}
+(void)didRoleUpButton:(NSDictionary*)sender :(NSDictionary*)arg{
    if (checkResponseStatus(sender)) {
		NSDictionary *data = getResponseData(sender);
		if (!data) {
			CCLOG(@"data error");
            if(s_roleUp){
                s_roleUp.isSend = NO;
            }
			return;
		}

        [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
		
        if ([data objectForKey:@"q"] &&
            [data objectForKey:@"g"] &&
            [data objectForKey:@"c"] &&
            [data objectForKey:@"n"]) {
            if(arg && [arg objectForKey:@"rid"]){
                int rid_ = [[arg objectForKey:@"rid"] intValue];
                NSDictionary *rid_dict =  [[GameConfigure shared] getPlayerRoleFromListById:rid_];
                if (rid_dict) {
                    NSMutableDictionary *rid_mut_dict = [NSMutableDictionary dictionaryWithDictionary:rid_dict];
                    [rid_mut_dict setObject:[data objectForKey:@"q"] forKey:@"q"];
                    [rid_mut_dict setObject:[data objectForKey:@"g"] forKey:@"g"];
                    [rid_mut_dict setObject:[data objectForKey:@"c"] forKey:@"c"];
                    [rid_mut_dict setObject:[data objectForKey:@"n"] forKey:@"n"];
                    [[GameConfigure shared] updateRoleByDict:rid_mut_dict];
                    if (rid_>0 && rid_<10) {
                        [[[RoleManager shared] player] setQuality:[[data objectForKey:@"q"] intValue]] ;
                        [[[RoleManager shared] player] updateViewer];
                    }
                }else{
                    CCLOG(@"role list data is error!");
                }
            }
        }else{
            CCLOG(@"send return data is error");
        }
		
        if (s_roleUp) {
            //TODO
            [s_roleUp loadRidDataWithRid:[s_roleUp roleRID]];
            SectionManager *sectionManager = (SectionManager *)[s_roleUp getChildByTag:RU_section_manager_tag];
            if (sectionManager) {
                [sectionManager setUpdateState:YES];
                [sectionManager setIsShowFrameEffect:YES];
            }
            //text
            [s_roleUp loadDataText];
            //
            [s_roleUp loadStepDisplay];
        }
    }else{
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
    if(s_roleUp){
        s_roleUp.isSend = NO;
    }
}
-(void)updateRid:(CCNode*)node{
    if (node) {
        NSNumber *object_ = (NSNumber *)node;
        roleRID = [object_ intValue];
        [self loadRidDataWithRid:roleRID];
    }
}
-(void)loadBG{
    [self removeChildByTag:RU_bg_tag cleanup:YES];
    CCSprite *bg_spr = [CCSprite spriteWithFile:@"images/ui/role_up/role_up_bg.jpg"];
    [self addChild:bg_spr z:0  tag:RU_bg_tag];
    bg_spr.position = ccp(self.contentSize.width/2+cFixedScale(50),self.contentSize.height/2+cFixedScale(-15));;
}
-(void)loadText{
    //name
    [self removeChildByTag:RU_name_text_tag cleanup:YES];
    CCSprite *name_text_spr = getStrokeSprite(NSLocalizedString(@"role_up_role_name",nil), getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(1.6), ccc4(76,58,20,200), ccc4(213,190,150,128));
    [self addChild:name_text_spr z:10 tag:RU_name_text_tag];
    name_text_spr.position = ccp(self.contentSize.width/2-cFixedScale(295)+name_text_spr.contentSize.width/2,self.contentSize.height/2 + cFixedScale(185));
    //quality
    [self removeChildByTag:RU_quality_text_tag cleanup:YES];
    CCSprite *quality_text_spr = getStrokeSprite(NSLocalizedString(@"role_up_role_quality",nil), getCommonFontName(FONT_1), cFixedScale(20), cFixedScale(1.6), ccc4(76,58,20,200), ccc4(213,190,150,128));
    [self addChild:quality_text_spr z:10 tag:RU_quality_text_tag];
    quality_text_spr.position = ccp(self.contentSize.width/2-cFixedScale(295)+quality_text_spr.contentSize.width/2,self.contentSize.height/2 + cFixedScale(185)+quality_text_spr.contentSize.height);
    //symbol
    [self removeChildByTag:RU_symbol_text_tag cleanup:YES];
    CCSprite *symbol_text_spr = [CCLabelFX labelWithString:NSLocalizedString(@"role_up_symbol",nil)
                                                dimensions:CGSizeMake(0,0)
                                                 alignment:kCCTextAlignmentCenter
                                                  fontName:getCommonFontName(FONT_1)
                                                  fontSize:18
                                              shadowOffset:CGSizeMake(-0.5, -0.5)
                                                shadowBlur:1.0f
                                               shadowColor:ccc4(255,255,255,200)
                                                 fillColor:ccc4(255,255,255,255)];
    //getStrokeSprite(@"剩余升段符:", getCommonFontName(FONT_1), 18, 0, ccc4(255,255,255,255), ccc4(255,255,255,255));
    [self addChild:symbol_text_spr z:10 tag:RU_symbol_text_tag];
    symbol_text_spr.position = ccp(self.contentSize.width/2 - cFixedScale(295)+symbol_text_spr.contentSize.width/2,self.contentSize.height/2 - cFixedScale(248));
    //count
    [self removeChildByTag:RU_role_up_count_text_tag cleanup:YES];
    CCSprite *count_text_spr = [CCLabelFX labelWithString:NSLocalizedString(@"role_up_today_count",nil)
                                               dimensions:CGSizeMake(0,0)
                                                alignment:kCCTextAlignmentCenter
                                                 fontName:getCommonFontName(FONT_1)
                                                 fontSize:18
                                             shadowOffset:CGSizeMake(-0.5, -0.5)
                                               shadowBlur:1.0f
                                              shadowColor:ccc4(255,255,255,200)
                                                fillColor:ccc4(255,255,255,255)];
    //getStrokeSprite(@"今日剩余升段次数:", getCommonFontName(FONT_1), 18, 0, ccc4(255,255,255,255), ccc4(255,255,255,255));
    [self addChild:count_text_spr z:10 tag:RU_role_up_count_text_tag];
    count_text_spr.position = ccp(self.contentSize.width/2 - cFixedScale(120)+count_text_spr.contentSize.width/2, self.contentSize.height/2 -cFixedScale(248));
}
-(void)loadDataText{
    //name
    CCSprite *name_text_spr = (CCSprite *)[self getChildByTag:RU_name_text_tag];
    if (name_text_spr) {
        [self removeChildByTag:RU_name_tag cleanup:YES];
        CCSprite *name_spr =[CCLabelFX labelWithString:nameString
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:getCommonFontName(FONT_1)
                                              fontSize:18
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(255,255,255,200)
                                             fillColor:ccc4(255,200,70,255)];;
        [self addChild:name_spr z:10 tag:RU_name_tag];
        name_spr.position = ccpAdd(name_text_spr.position, ccp(name_text_spr.contentSize.width/2+name_spr.contentSize.width/2,0));
    }
    
    //quality
    CCSprite *quality_text_spr = (CCSprite *)[self getChildByTag:RU_quality_text_tag];
    ccColor3B color_ = getColorByQuality(roleUpQuality);
    if (quality_text_spr) {
        [self removeChildByTag:RU_quality_tag cleanup:YES];
        CCSprite *quality_spr =[CCLabelFX labelWithString: NSLocalizedString(getTextWithQuality(roleUpQuality),nil)
                                               dimensions:CGSizeMake(0,0)
                                                alignment:kCCTextAlignmentLeft
                                                 fontName:getCommonFontName(FONT_1)
                                                 fontSize:18
                                             shadowOffset:CGSizeMake(-0.5, -0.5)
                                               shadowBlur:1.0f
                                              shadowColor:ccc4(255,255,255,200)
                                                fillColor:ccc4(color_.r,color_.g,color_.b,255)];;
        [self addChild:quality_spr z:10 tag:RU_quality_tag];
        quality_spr.position = ccpAdd(quality_text_spr.position, ccp(quality_text_spr.contentSize.width/2+quality_spr.contentSize.width/2,0));
    }
    //symbol
    CCSprite *symbol_text_spr = (CCSprite *)[self getChildByTag:RU_symbol_text_tag];
    if (symbol_text_spr) {
        [self removeChildByTag:RU_symbol_tag cleanup:YES];
        CCSprite *symbol_spr =[CCLabelFX labelWithString:[NSString stringWithFormat:@" %d",symbolCount]
                                              dimensions:CGSizeMake(0,0)
                                               alignment:kCCTextAlignmentLeft
                                                fontName:getCommonFontName(FONT_1)
                                                fontSize:18
                                            shadowOffset:CGSizeMake(-0.5, -0.5)
                                              shadowBlur:1.0f
                                             shadowColor:ccc4(255,255,255,200)
                                               fillColor:ccc4(255,200,70,255)];;
        [self addChild:symbol_spr z:10 tag:RU_symbol_tag];
        symbol_spr.position = ccpAdd(symbol_text_spr.position, ccp(symbol_text_spr.contentSize.width/2+symbol_spr.contentSize.width/2,0));
    }
    //count
    CCSprite *count_text_spr = (CCSprite *)[self getChildByTag:RU_role_up_count_text_tag];
    if (count_text_spr) {
        [self removeChildByTag:RU_role_up_count_tag cleanup:YES];
        CCSprite *count_spr =[CCLabelFX labelWithString:[NSString stringWithFormat:@" %d",roleUpCount]
                                             dimensions:CGSizeMake(0,0)
                                              alignment:kCCTextAlignmentLeft
                                               fontName:getCommonFontName(FONT_1)
                                               fontSize:18
                                           shadowOffset:CGSizeMake(-0.5, -0.5)
                                             shadowBlur:1.0f
                                            shadowColor:ccc4(255,255,255,200)
                                              fillColor:ccc4(255,200,70,255)];;
        [self addChild:count_spr z:10 tag:RU_role_up_count_tag];
        count_spr.position = ccpAdd(count_text_spr.position, ccp(count_text_spr.contentSize.width/2+count_spr.contentSize.width/2,0));
    }
}
-(void)loadRidDataWithRid:(int)rid_{
    //name
    NSDictionary *dict_role_info = [[GameDB shared] getRoleInfo:rid_];
    if (dict_role_info) {
        if (rid_>0 && rid_<10) {
            [nameString release];
            nameString = [[GameConfigure shared] getPlayerName];//[[GameConfigure shared] getPlayerName];
            [nameString retain];
        }else if(rid_>10){
            if (dict_role_info && [dict_role_info objectForKey:@"name"]) {
                [nameString release];
                nameString = [dict_role_info objectForKey:@"name"];
                [nameString retain];
            }
        }
        if (nameString == nil) {
            [nameString release];
            nameString = @"";
            [nameString retain];
        }
        NSDictionary *role_info = [[GameConfigure shared] getPlayerRoleFromListById:rid_];
        if (role_info) {
            roleUpStartQuality = selectQuality = roleUpQuality = [[role_info objectForKey:@"q"] intValue];
            roleUpLevel = [[role_info objectForKey:@"g"] intValue];
            roleUpStep = [[role_info objectForKey:@"c"] intValue];
            roleUpCount = [[role_info objectForKey:@"n"] intValue];
        }else{
            CCLOG(@"role up data error");
        }
        //
        if (dict_role_info && [dict_role_info objectForKey:@"quality"]) {
            roleUpStartQuality = [[dict_role_info objectForKey:@"quality"] intValue];
        }else{
            CCLOG(@"role up data error");
        }
    }else{
        CCLOG(@"role up data error");
    }
    
    symbolCount=[[GameConfigure shared] getPlayerItemCountByIid:symbolID];
    //load data text
    [self loadDataText];
    //check state
    [self checkButtonState];
    //
    [self loadQualityDisplay];
    //
    [self loadStepDisplay];
}
-(void)addButtonToMenuWithFile:(NSString*)file tag:(int)tag{
    CCMenu *menu = (CCMenu *)[self getChildByTag:RU_menu_tag];
    if (menu && file) {
        NSArray *bt_arr = nil;
        //
        bt_arr = getDisableBtnSpritesArrayWithStatus(file);
        if (bt_arr && [bt_arr count]>2) {
            [menu removeChildByTag:tag cleanup:YES];
            CCMenuItemSprite *bt_green_spr01 = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:nil];
            CCMenuItemSprite *bt_green_spr02 = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:1] selectedSprite:nil];
            CCMenuItemSprite *bt_green_spr03 = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:2] selectedSprite:nil];
            CCMenuItemToggle *bt_green = [CCMenuItemToggle itemWithTarget:self selector:@selector(buttonBack:) items:bt_green_spr01,bt_green_spr02,bt_green_spr03, nil];
            [menu addChild:bt_green z:1 tag:tag];
            bt_green.position = [self getButtonPointWithTag:tag];
            //
        }
    }else{
        CCLOG(@"menu or file is nil");
    }
}
-(void)loadButton{
    //menu
    [self removeChildByTag:RU_menu_tag cleanup:YES];
    CCMenu *menu = [CCMenu node];
    [self addChild:menu z:10 tag:RU_menu_tag];
    menu.position = ccp(0,0);
    
    if (menu) {
        
        //green
        [self addButtonToMenuWithFile:@"images/ui/button/bt_role_up_green" tag:RU_button_green_tag];
        //blue
        [self addButtonToMenuWithFile:@"images/ui/button/bt_role_up_blue" tag:RU_button_blue_tag];
        //purple
        [self addButtonToMenuWithFile:@"images/ui/button/bt_role_up_purple" tag:RU_button_purple_tag];
        //orange
        [self addButtonToMenuWithFile:@"images/ui/button/bt_role_up_orange" tag:RU_button_orange_tag];
    }
}
-(void)checkButtonState{
    CCMenu *menu = (CCMenu *)[self getChildByTag:RU_menu_tag];
    if (menu) {
        CCMenuItemToggle *bt_green = (CCMenuItemToggle *)[menu getChildByTag:RU_button_green_tag];
        if (bt_green) {
            if (IQ_GREEN < roleUpStartQuality) {
                [bt_green setSelectedIndex:0];
                bt_green.isEnabled = NO;
            }else{
                if(IQ_GREEN<=roleUpQuality){
                    if (IQ_GREEN==selectQuality) {
                        [bt_green setSelectedIndex:1];
                    }else{
                        [bt_green setSelectedIndex:0];
                    }
                    bt_green.isEnabled = YES;
                }else{
                    [bt_green setSelectedIndex:2];
                    bt_green.isEnabled = NO;
                }
            }
        }
        CCMenuItemToggle *bt_blue = (CCMenuItemToggle *)[menu getChildByTag:RU_button_blue_tag];
        if (bt_blue) {
            if (IQ_BLUE < roleUpStartQuality) {
                [bt_blue setSelectedIndex:0];
                bt_blue.isEnabled = NO;
            }else{
                if(IQ_BLUE<=roleUpQuality){
                    if (IQ_BLUE==selectQuality) {
                        [bt_blue setSelectedIndex:1];
                    }else{
                        [bt_blue setSelectedIndex:0];
                    }
                    bt_blue.isEnabled = YES;
                }else{
                    [bt_blue setSelectedIndex:2];
                    bt_blue.isEnabled = NO;
                }
            }
        }
        CCMenuItemToggle *bt_purple = (CCMenuItemToggle *)[menu getChildByTag:RU_button_purple_tag];
        if (bt_purple) {
            if (IQ_PURPLE < roleUpStartQuality) {
                [bt_purple setSelectedIndex:0];
                bt_purple.isEnabled = NO;
            }else{
                if(IQ_PURPLE<=roleUpQuality){
                    if (IQ_PURPLE==selectQuality) {
                        [bt_purple setSelectedIndex:1];
                    }else{
                        [bt_purple setSelectedIndex:0];
                    }
                    bt_purple.isEnabled = YES;
                }else{
                    [bt_purple setSelectedIndex:2];
                    bt_purple.isEnabled = NO;
                }
            }
        }
        CCMenuItemToggle *bt_orange = (CCMenuItemToggle *)[menu getChildByTag:RU_button_orange_tag];
        if (bt_orange) {
            if (IQ_ORANGE < roleUpStartQuality) {
                [bt_orange setSelectedIndex:0];
                bt_orange.isEnabled = NO;
            }else{
                if(IQ_ORANGE<=roleUpQuality){
                    if (IQ_ORANGE==selectQuality) {
                        [bt_orange setSelectedIndex:1];
                    }else{
                        [bt_orange setSelectedIndex:0];
                    }
                    bt_orange.isEnabled = YES;
                }else{
                    [bt_orange setSelectedIndex:2];
                    bt_orange.isEnabled = NO;
                }
            }
        }
    }
}
-(CGPoint)getButtonPointWithTag:(int)tag{
    CGPoint pos = ccp(self.contentSize.width/2, self.contentSize.height/2);
    if (tag == RU_button_green_tag) {
        pos.x +=  cFixedScale(300+15);
        pos.y += cFixedScale(200-50);
    }else if(tag == RU_button_blue_tag){
        pos.x += cFixedScale(330+15);
        pos.y += cFixedScale(90-50);
    }else if(tag == RU_button_purple_tag){
        pos.x += cFixedScale(330+15);
        pos.y += cFixedScale(-10-50);
    }else if(tag == RU_button_orange_tag){
        pos.x += cFixedScale(300+15);
        pos.y += cFixedScale(-120-50);
    }
    return pos;
}
-(void)buttonBack:(CCNode*)node{
    BOOL isChange = NO;
    if (node) {
        switch (node.tag) {
            case RU_button_green_tag:
            {
                if (selectQuality != IQ_GREEN) {
                    selectQuality = IQ_GREEN;
                    //TODO
                    isChange = YES;
                }
                CCLOG(@"RU_button_green_tag");
            }
                break;
            case RU_button_blue_tag:
            {
                if (selectQuality != IQ_BLUE) {
                    selectQuality = IQ_BLUE;
                    //TODO
                    isChange = YES;
                }
				CCLOG(@"RU_button_blue_tag");
            }
                break;
            case RU_button_purple_tag:
            {
                if (selectQuality != IQ_PURPLE) {
                    selectQuality = IQ_PURPLE;
                    //TODO
                    isChange = YES;
                }
				CCLOG(@"RU_button_purple_tag");
            }
                break;
            case RU_button_orange_tag:
            {
                if (selectQuality != IQ_ORANGE) {
                    selectQuality = IQ_ORANGE;
                    //TODO
                    isChange = YES;
                }
				CCLOG(@"RU_button_orange_tag");
            }
                break;
            default:
                break;
        }
    }
    if (isChange) {
        //
        [self loadStepDisplay];
        //
        [self loadQualityDisplayWithEffect];
    }
    //
    [self checkButtonState];
	
}
-(CGPoint)getStepPointWithTag:(int)tag{
    CGPoint pos = CGPointZero;
    if ( tag == RU_now_step_display_tag) {
       pos = ccp(self.contentSize.width/2 - cFixedScale(238),self.contentSize.height/2 + cFixedScale(70));
    }else if ( tag == RU_next_step_display_tag){
       pos = ccp(self.contentSize.width/2 - cFixedScale(238),self.contentSize.height/2 - cFixedScale(110));
    }
    return pos;
}
-(void)changeStepDisplayWithName:(NSString*)name rid:(int)rid_ quality:(int)quality_ roleUpLevel:(int)upLevel_ step:(int)step_ tag:(int)tag{
    if (!name) {
        name = @"";
    }
    RoleUpStepDisplay *stepDisplay = (RoleUpStepDisplay *)[self getChildByTag:tag];
    if (!stepDisplay) {
        stepDisplay = [RoleUpStepDisplay node];
        [self addChild:stepDisplay z:11 tag:tag];
        stepDisplay.position = [self getStepPointWithTag:tag];
    }
    stepDisplay.roleRID = rid_;
    stepDisplay.roleUpQuality = quality_;
    stepDisplay.roleUpLevel = upLevel_;
    stepDisplay.roleUpStep = step_;
    stepDisplay.nameString = name;
    
}
-(void)loadQualityDisplay{
    SectionManager *sectionManager = (SectionManager *)[self getChildByTag:RU_section_manager_tag];
    if (!sectionManager) {
        sectionManager = [SectionManager node];
        [self addChild:sectionManager z:1 tag:RU_section_manager_tag];
        sectionManager.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
        //[sectionManager setOldPoint:sectionManager.position];
    }
    [sectionManager setRoleId:roleRID];
    [sectionManager setSelectQuality:selectQuality];
}
-(void)loadQualityDisplayWithEffect{
    [self loadQualityDisplay];
    //
    SectionManager *sectionManager = (SectionManager *)[self getChildByTag:RU_section_manager_tag];
    [sectionManager showEffect];
}
-(void)loadStepDisplay{
    //
    [RoleUp loadStepDisplayWithRid:roleRID quality:roleUpQuality roleUpLevel:roleUpLevel step:roleUpStep];
}
+(void)loadStepDisplayWithRid:(int)rid_ quality:(int)quality_ roleUpLevel:(int)upLevel_ step:(int)step_{
    //
    if (s_roleUp) {
        [s_roleUp changeStepDisplayWithName:NSLocalizedString(@"role_up_now",nil)
                                        rid:rid_ quality:quality_ roleUpLevel:upLevel_ step:step_ tag:RU_now_step_display_tag];
        [s_roleUp changeStepDisplayWithName:NSLocalizedString(@"role_up_next",nil)
                                        rid:rid_ quality:quality_ roleUpLevel:upLevel_ step:step_+1 tag:RU_next_step_display_tag];
     
    }
    
}
-(void)loadWindow{
    //bg
    [self loadBG];
    //button
    [self loadButton];
    //text
    [self loadText];
    //roles
    NSArray *_roles = [[GameConfigure shared] getTeamMember];
    MemberSizer *member_sizer = [MemberSizer create:_roles target:self call:@selector(updateRid:) defaultIndex:roleRID];
    [self addChild:member_sizer z:1];
    //member_sizer.position = ccp(cFixedScale(25),cFixedScale(15));
    
    member_sizer.position = ccp(self.contentSize.width/2 - cFixedScale(410),self.contentSize.height/2 - cFixedScale(272));
    
    //
    [self loadStepDisplay];
	
    
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    //TODO
	touchLocation = [self convertToNodeSpace:touchLocation];
    startMovePos = touchLocation;
    return YES;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"moveing");
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	
    //TODO
    SectionManager *sectionManager = (SectionManager *)[self getChildByTag:RU_section_manager_tag];
    if (sectionManager) {
        touchLocation = [self convertToNodeSpace:touchLocation];
        CGPoint dPos = ccpSub(touchLocation, startMovePos);
        if (abs(dPos.x)>30) {
            
        }
        [sectionManager contentMoveOff:ccp(dPos.x,0)];
        startMovePos = touchLocation;
        CCLOG(@"dPos.x:%f",dPos.x);
        isMoveContent = YES;
    }
	
}
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
    //
    SectionManager *sectionManager = (SectionManager *)[self getChildByTag:RU_section_manager_tag];
    if (sectionManager) {
        [sectionManager checkPoint];
        isMoveContent = NO;
    }
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    //
    SectionManager *sectionManager = (SectionManager *)[self getChildByTag:RU_section_manager_tag];
    if (sectionManager) {
        [sectionManager checkPoint];
        isMoveContent = NO;
    }
}
@end
