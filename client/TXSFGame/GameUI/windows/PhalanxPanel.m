//
//  PhalanxPanel.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-17.
//  Copyright 2012 eGame. All rights reserved.
//

#import "PhalanxPanel.h"
#import "Window.h"
#import "RoleViewerContent.h"
#import "InfoAlert.h"

static BOOL isTouchReal = NO; // 成员列表，阵形详细信息，阵形列表三部分，同时只有一个屏幕触摸事件

static CCNode *guanpingNode = nil;
static CCNode *currenNodeStation = nil;
static CCNode *currenNodeClose = nil;
static PhalanxDetail *phalanxDetail = nil;

@implementation PhalanxMemberMenu

-(void)onEnter{
	[super onEnter];
	if([self tag]==21){
		guanpingNode = self;
		[[Intro share]runIntroTager:self step:INTRO_Phalanx_Step_1];
	}
}

-(id)initWithRoleId:(int)rid{
	
    if (self = [super init]) {
		
        CCSprite *characterIconBg = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_character_bg.png"];
        self.contentSize = characterIconBg.contentSize;
        characterIcon = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
        CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        inIcon = [CCSprite spriteWithFile:@"images/ui/common/fight.png"];
        inIcon.visible = NO;
        characterIconBg.position = halfPoint;
        characterIcon.position = halfPoint;
        if (iPhoneRuningOnGame()) {
			characterIconBg.scaleX=1.1f;
            inIcon.position = ccp(self.contentSize.width - 15/2, self.contentSize.height - 17/2);
        }else{
            inIcon.position = ccp(self.contentSize.width - 15, self.contentSize.height - 17);
		}
		
        [self addChild:characterIconBg];
        [self addChild:characterIcon];
        [self addChild:inIcon];
		
    }
    
    return self;
}

-(void)setInArray:(BOOL)inArray
{
    if (inArray) {
        inIcon.visible = YES;
    } else {
        inIcon.visible = NO;
    }
}

@end

@implementation PhalanxMemberList

@synthesize delegate;

-(void)onEnter
{
	[super onEnter];
	if (iPhoneRuningOnGame()) {
        self.contentSize = CGSizeMake(188/2, 548/2);
    }else{
        self.contentSize = CGSizeMake(188, 403);
	}
	
	CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] addTargetedDelegate:self priority:-257 swallowsTouches:YES];
	//fix chao
    if (!iPhoneRuningOnGame()) {
        //CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:@"拖动伙伴至右侧阵型面板进行布阵" fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(160, 50) hAlignment:kCCTextAlignmentLeft];
        CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"phalanx_info_right",nil) fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(160, 50) hAlignment:kCCTextAlignmentLeft];
        tipsLabel.anchorPoint = ccp(0, 1);
        tipsLabel.position = ccp(16, 86);
        tipsLabel.color = ccc3(236, 228, 206);
        [self addChild:tipsLabel];
    }
	//end
	memberArray = [NSMutableArray array];
	[memberArray retain];
	
	NSArray *roleList = [[GameConfigure shared] getPlayerRoleList];
	int j = 0;
	for (int i = 0; i < roleList.count; i++) {
		NSDictionary *roleInfo = [roleList objectAtIndex:i];
		// 在队中
		if ([[roleInfo objectForKey:@"status"] intValue] == 1) {
			int rid = [[roleInfo objectForKey:@"rid"] intValue];
			PhalanxMemberMenu *phalanxMemberMenu = [[[PhalanxMemberMenu alloc] initWithRoleId:rid] autorelease];
			phalanxMemberMenu.tag = rid;
            float x = 0;
            float y = 0;
			if (iPhoneRuningOnGame()) {
               // x = ((j % 2 == 0) ? 0 : 96/2) + 45/2;
               // y = self.contentSize.height - (j/2+1)*66/2 - (j/2)*6/2 + 33/2;
               x =  45/2;
               y = self.contentSize.height - (j+1)*66/2 - (j)*1 + 33/2;
            }else{
                x = ((j % 2 == 0) ? 0 : 96) + 45;
                y = self.contentSize.height - (j/2+1)*66 - (j/2)*6 + 33;
			}
            phalanxMemberMenu.position = ccp(x, y);
			j++;
			
			[self addChild:phalanxMemberMenu];
			[memberArray addObject:phalanxMemberMenu];
		}
	}
    
}

-(void)onExit
{
	if (memberArray) {
		[memberArray release];
		memberArray = nil;
	}
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (isTouchReal) return NO;
	
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	for (CCNode *node in memberArray) {
		if (CGRectContainsPoint(node.boundingBox, touchLocation)) {
            //			if (delegate) {
            //				[delegate clickMemberWithRoleId:node.tag touch:touch];
            //			}
			
			if (phalanxDetail) {
				phalanxDetail.dragRole = YES;
				[phalanxDetail setSelectRoleWithRoleId:node.tag touch:touch];
			}
			
			isTouchReal = YES;
			return YES;
		}
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (phalanxDetail && phalanxDetail.dragRole) {
		[phalanxDetail ccTouchMoved:touch withEvent:event];
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (phalanxDetail) {
		[phalanxDetail ccTouchEnded:touch withEvent:event];
		phalanxDetail.dragRole = NO;
	}
	
	isTouchReal = NO;
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (phalanxDetail) {
		[phalanxDetail ccTouchCancelled:touch withEvent:event];
		phalanxDetail.dragRole = NO;
	}
	
	isTouchReal = NO;
}

-(void)updateByPhalanxId:(int)pid
{
    NSDictionary *phalanxInfo = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    NSMutableArray *rolePhalanxArray = [NSMutableArray array];
    for (int i = 0; i < 15; i++) {
        NSString *key = [NSString stringWithFormat:@"s%d", i + 1];
        int value = [[phalanxInfo objectForKey:key] intValue];
        if (value != 0) {
            [rolePhalanxArray addObject:[NSNumber numberWithInt:value]];
        }
    }
    
	for (PhalanxMemberMenu *phalanxMemberMenu in memberArray) {
		BOOL isIn = [rolePhalanxArray containsObject:[NSNumber numberWithInt:phalanxMemberMenu.tag]];
        [phalanxMemberMenu setInArray:isIn];
	}
}

-(void)callbackTouch:(CCLayerList *)_list :(CCListItem *)_listItem :(UITouch *)touch
{
    [delegate clickMemberWithRoleId:_listItem.tag touch:touch];
}

@end

// 阵形八卦，添加增益属性
@interface PhalanxIcon : CCSprite
@property (nonatomic) BOOL isEye;
@property (nonatomic, retain) NSString *info;
@end

@implementation PhalanxIcon
@synthesize isEye;
@synthesize info;

-(void)dealloc{
	if(info){
		[info release];
		info = nil;
	}
	[super dealloc];
}

@end

// 加成提示框
@interface PhalanxAttributeTips : CCLayer {
    float defaultHeight;
    float rowHeight;
    ccColor3B color;
    ccColor3B eyeColor;
    CCSprite *topSprite;
    CCSprite *contentSprite;
    CCLabelTTF *label;
}
@end

@implementation PhalanxAttributeTips

// 通过文本行数决定提示框高度
-(void)setLayerWithAttribute:(NSString *)attribute isEye:(BOOL)isEye atPoint:(CGPoint)point
{
    NSArray *attributeArray = [attribute componentsSeparatedByString:@"|"];
    int rowCount = attributeArray.count;
    float height = rowHeight * rowCount;
    if (iPhoneRuningOnGame()) {
        self.contentSize = CGSizeMake(140/2, defaultHeight + rowHeight * rowCount);
    }else{
        self.contentSize = CGSizeMake(140, defaultHeight + rowHeight * rowCount);
	}
    topSprite.position = ccp(0, self.contentSize.height);
    
    contentSprite.scaleY = (self.contentSize.height - defaultHeight) / contentSprite.contentSize.height;
    
	int speed_Per = 0;
    NSMutableArray *finalAttributeArray = [NSMutableArray array];
    for (NSString *attribute in attributeArray) {
        NSArray *array = [attribute componentsSeparatedByString:@":"];
        NSString *finalKey = @"";
        NSString *key = [array objectAtIndex:0];
        BOOL isPercent = NO;
        if ([key isEqualToString:@"STR"]) {
            //finalKey = @"勇力";
            finalKey = NSLocalizedString(@"phalanx_str",nil);
        } else if ([key isEqualToString:@"DEX"]) {
            //finalKey = @"迅捷";
            finalKey = NSLocalizedString(@"phalanx_dex",nil);
        } else if ([key isEqualToString:@"VIT"]) {
            //finalKey = @"体魄";
            finalKey = NSLocalizedString(@"phalanx_vit",nil);
        } else if ([key isEqualToString:@"INT"]) {
            //finalKey = @"智略";
            finalKey = NSLocalizedString(@"phalanx_int",nil);
        } else if ([key isEqualToString:@"HP"]) {
            //finalKey = @"生命";
            finalKey = NSLocalizedString(@"phalanx_hp",nil);
        } else if ([key isEqualToString:@"ATK"]) {
            //finalKey = @"攻击";
            finalKey = NSLocalizedString(@"phalanx_atk",nil);
        } else if ([key isEqualToString:@"STK"]) {
            //finalKey = @"绝攻";
            finalKey = NSLocalizedString(@"phalanx_stk",nil);
        } else if ([key isEqualToString:@"DEF"]) {
            //finalKey = @"防御";
            finalKey = NSLocalizedString(@"phalanx_def",nil);
        } else if ([key isEqualToString:@"SPD"]) {
            //finalKey = @"速度";
            finalKey = NSLocalizedString(@"phalanx_spd",nil);
        } else if ([key isEqualToString:@"SPD_P"]) {
            //finalKey = @"速度";
            finalKey = NSLocalizedString(@"phalanx_spd_p",nil);
			if (speed_Per==1) {
				//finalKey = @"首次攻击速度";
                finalKey = NSLocalizedString(@"phalanx_spd_per",nil);
			}
			speed_Per++;
			isPercent = YES;
        } else if ([key isEqualToString:@"MP"]) {
            //finalKey = @"聚气";
            finalKey = NSLocalizedString(@"phalanx_mp",nil);
        } else if ([key isEqualToString:@"MPS"]) {
            //finalKey = @"初聚气";
            finalKey = NSLocalizedString(@"phalanx_mps",nil);
        } else if ([key isEqualToString:@"MPR"]) {
            //finalKey = @"回气值";
            finalKey = NSLocalizedString(@"phalanx_mpr",nil);
        } else if ([key isEqualToString:@"HIT"]) {
            //finalKey = @"命中率";
            finalKey = NSLocalizedString(@"phalanx_hit",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"MIS"]) {
            //finalKey = @"回避率";
            finalKey = NSLocalizedString(@"phalanx_mis",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"BOK"]) {
            //finalKey = @"格挡率";
            finalKey = NSLocalizedString(@"phalanx_bok",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"COT"]) {
            //finalKey = @"反击率";
            finalKey = NSLocalizedString(@"phalanx_cot",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"COB"]) {
            //finalKey = @"连击率";
            finalKey = NSLocalizedString(@"phalanx_cob",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"CRI"]) {
            //finalKey = @"暴击率";
            finalKey = NSLocalizedString(@"phalanx_cri",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"CPR"]) {
            //finalKey = @"爆伤率";
            finalKey = NSLocalizedString(@"phalanx_cpr",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"PEN"]) {
            //finalKey = @"破甲率";
            finalKey = NSLocalizedString(@"phalanx_pen",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"TUF"]) {
            //finalKey = @"免伤率";
            finalKey = NSLocalizedString(@"phalanx_tuf",nil);
            isPercent = YES;
        } else if ([key isEqualToString:@"add_hurt_hp_p"]) {
            //finalKey = @"回复伤害值";
            finalKey = NSLocalizedString(@"phalanx_add_hurt_hp_p",nil);
            isPercent = YES;
        }
        if (isPercent) {
			[finalAttributeArray addObject:[NSString stringWithFormat:@"%@ + %.1f%%", finalKey, [[array objectAtIndex:1] floatValue]]];
        } else {
            [finalAttributeArray addObject:[NSString stringWithFormat:@"%@ + %d", finalKey, [[array objectAtIndex:1] intValue]]];
        }
        
    }
    
    label.string = [finalAttributeArray componentsJoinedByString:@"\n"];
    label.color = isEye ? eyeColor : color;
    if (iPhoneRuningOnGame()) {
        label.dimensions = CGSizeMake(120, height*2);
        self.position = ccp(point.x - self.contentSize.width / 2+10,
                            point.y + 30/2 + self.contentSize.height+40/2);
    }else{
        label.dimensions = CGSizeMake(120, height);
        self.position = ccp(point.x - self.contentSize.width / 2,
                            point.y + 30 + self.contentSize.height+40);
    }
    self.visible = YES;
}

-(id)init
{
    if (self = [super init]) {
        if (iPhoneRuningOnGame()) {
            defaultHeight = 10/2;
            rowHeight = 13/2;
        }else{
            defaultHeight = 10;
            rowHeight = 13;
        }
        color = ccc3(109, 207, 246);
        eyeColor = ccc3(255, 210, 72);
        
        topSprite = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_tips_top.png"];
        topSprite.anchorPoint = ccp(0, 1);
        [self addChild:topSprite];
        contentSprite = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_tips_content.png"];
        contentSprite.anchorPoint = ccp(0, 0);
        contentSprite.position = ccp(0, defaultHeight / 2);
        [self addChild:contentSprite];
        CCSprite *bottomSprite = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_tips_bottom.png"];
        bottomSprite.anchorPoint = ccp(0, 0);
        bottomSprite.position = ccp(0, 0);
        [self addChild:bottomSprite];
        if (iPhoneRuningOnGame()) {
            topSprite.scaleX = 0.8;
            contentSprite.scaleX = 0.8;
            bottomSprite.scaleX = 0.8;
        }
        
        if (iPhoneRuningOnGame()) {
            label = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica" fontSize:10 dimensions:CGSizeMake(120/2, 0) hAlignment:kCCTextAlignmentLeft];
            label.position = ccp(10/2, defaultHeight / 2);
            label.scale = 0.5;
        }else{
            label = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica" fontSize:10 dimensions:CGSizeMake(120, 0) hAlignment:kCCTextAlignmentLeft];
            label.position = ccp(10, defaultHeight / 2);
        }
        label.anchorPoint = ccp(0, 0);
        [self addChild:label];
        
        self.visible = NO;
    }
    return self;
}
@end

@implementation PhalanxDetail

@synthesize delegate;
@synthesize phalanxId;
@synthesize dragRole;
@synthesize posArray;
//@synthesize title;
//@synthesize effect;
@synthesize phalanxIconArray;
@synthesize phalanxAttributeTips;
@synthesize roleArray;

// 角色是否出战
-(BOOL)isRoleIn:(int)rid
{
    NSArray *array = [[GameConfigure shared] getPlayerRoleList];
    for (NSDictionary *dict in array) {
        if ([[dict objectForKey:@"rid"] intValue] == rid) {
            if ([[dict objectForKey:@"status"] intValue] == 1) {
                return YES;
            }
            break;
        }
    }
    return NO;
}

// 设置阵位角色（index为1~15）
-(NSMutableDictionary *)setIndexWithPlayerPhalanx:(NSMutableDictionary *)dict index:(int)index roleId:(int)rid
{
    if(rid==21){
		[[Intro share]removeCurrenTipsAndNextStep:INTRO_Phalanx_Step_2];
		[[Intro share]runIntroTager:currenNodeClose step:INTRO_CLOSE_Phalanx];
	}
	NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
    if (_dict) {
        NSString *key = [NSString stringWithFormat:@"s%d", index];
        [_dict setObject:[NSNumber numberWithInt:rid] forKey:key];
    } else {
        CCLOG(@"setIndexByPhalanxId is nil");
    }
    return _dict;
}

-(void)updateRoleByPhalanxIndex:(int)index
{
    NSDictionary *dict = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:phalanxId];
    if (dict) {
        NSString *key = [NSString stringWithFormat:@"s%d", index];
        int rid = [[dict objectForKey:key] intValue];
        if (rid != 0) {
            CGPoint position = [[posArray objectAtIndex:index - 1 + adjustPos] CGPointValue];
            // 如果该坐标有角色，先删除
            for (CCNode *node in roleArray) {
                if (CGPointEqualToPoint(node.position, position)) {
                    [node removeFromParentAndCleanup:YES];
                    [roleArray removeObject:node];
					node = nil;
                    break;
                }
            }
            
			if([self isRoleIn:rid]){
				CCNode *roleAnima = [self getSelectedRoleWithRoleId:rid];
				if (roleAnima) {
					roleAnima.tag = index + 100;
					roleAnima.position = position;
					[self addChild:roleAnima z:index];
					[roleArray addObject:roleAnima];
				}
            }
			
        }
        // 该阵形没人，如果之前有，即删除
        else {
            for (CCSprite *node in roleArray) {
                if (node.tag == index + 100) {
                    [node removeFromParentAndCleanup:YES];
                    [roleArray removeObject:node];
					node = nil;
                    break;
                }
            }
        }
    } else {
        CCLOG(@"updateRoleByPhalanxIndex index is nil");
    }
}

-(void)updateRolesByPhalanxId:(int)pid
{
    // 改变了阵形，重新生成角色
    for (CCNode *role in roleArray) {
        [role removeFromParentAndCleanup:YES];
		role = nil;
    }
    [roleArray removeAllObjects];
    
    NSArray *array = [[GameConfigure shared] getPlayerPhalanxList];
    for (NSDictionary *dict in array) {
        if ([[dict objectForKey:@"posId"] intValue] == pid) {
            for (int i = 1; i <= 15; i++) {
                NSString *key = [NSString stringWithFormat:@"s%d", i];
                int rid = [[dict objectForKey:key] intValue];
                if (rid != 0) {
                    [self updateRoleByPhalanxIndex:i];
                }
            }
            
            break;
        }
    }
}

// 通过玩家阵形id和阵位返回角色id（没有为0）
-(int)getRoleIdByPhalanxId:(int)pid index:(int)index
{
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    if (playerPhalanx) {
        NSString *indexName = [NSString stringWithFormat:@"s%d", index];
        int roleId = [[playerPhalanx objectForKey:indexName] intValue];
        return roleId;
    }
    return 0;
}

// 通过玩家阵形id和角色id返回阵位（没有为0）
-(int)getIndexByPhalanxId:(int)pid roleId:(int)rid
{
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    if (playerPhalanx) {
        for (int i = 1; i <= 15; i++) {
            NSString *indexName = [NSString stringWithFormat:@"s%d", i];
            int Id = [[playerPhalanx objectForKey:indexName] intValue];
            if (Id == rid) {
                return i;
            }
        }
    }
    return 0;
}

// iconIndex 八卦图标索引(0~4,0为阵眼)
// phalanxIndex 阵位索引(1~15)
// info 阵位信息
-(void)setPhalanxIconPos:(int)iconIndex :(int)phalanxIndex :(NSString *)info
{
    PhalanxIcon *phalanxIcon = [phalanxIconArray objectAtIndex:iconIndex];
	if(phalanxIndex==4){
		currenNodeStation=phalanxIcon;
	}
    phalanxIcon.position = [[posArray objectAtIndex:phalanxIndex-1] CGPointValue];
    // 特殊处理
    phalanxIcon.tag = phalanxIndex - adjustPos;
    phalanxIcon.info = info;
}

-(void)enterPhalanxIndex:(int)index
{
    for (PhalanxIcon *icon in phalanxIconArray) {
        if (icon.tag == index) {
            icon.visible = NO;
            CCNode *node = icon.isEye ? eyePhalanxIcon : normalPhalanxIcon;
            node.position = [[posArray objectAtIndex:index-1+adjustPos] CGPointValue];
            node.visible = YES;
        }
    }
}

-(void)leavePhalanxIndex:(int)index
{
    for (PhalanxIcon *icon in phalanxIconArray) {
        if (icon.tag == index) {
            icon.visible = YES;
            CCNode *node = icon.isEye ? eyePhalanxIcon : normalPhalanxIcon;
            node.visible = NO;
        }
    }
}

-(void)onEnter
{
	[super onEnter];
	
	CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] addTargetedDelegate:self priority:-256 swallowsTouches:YES];
    //fix chao
    if (iPhoneRuningOnGame()) {
     //CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:@"拖动左侧伙伴至阵型面板进行布阵" fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(260, 50) hAlignment:kCCTextAlignmentLeft];
        CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"phalanx_info_left",nil) fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(260, 50) hAlignment:kCCTextAlignmentLeft];
     tipsLabel.anchorPoint = ccp(0, 1);
    
     tipsLabel.position = ccp(4/2,20/2);
     tipsLabel.scale = 0.5;

     tipsLabel.color = ccc3(236, 228, 206);
     [self addChild:tipsLabel];
    }
	//end
}

-(void)onExit{
	
	if(posArray){
		[posArray release];
		posArray = nil;
	}
	if(phalanxIconArray){
		[phalanxIconArray release];
		phalanxIconArray = nil;
	}
	if(roleArray){
		[roleArray release];
		roleArray = nil;
	}
	
	CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] removeDelegate:self];
	
	[GameConnection freeRequest:self];
	
	[super onExit];
	
}

-(id)init
{
    BOOL initIsTrue =false;
    if (iPhoneRuningOnGame()) {
        if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:466/2 height:403/2]) {
            initIsTrue = true;
        }
    }else{
        if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:466 height:403]) {
            initIsTrue = true;
        }
    }
    //    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:466 height:403]) {
    if (initIsTrue) {
        movePhalanxId = -1;
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_bg.jpg"];
        bg.anchorPoint = ccp(0, 0);
        [self addChild:bg];
        if (iPhoneRuningOnGame()) {
            posArray =  [NSArray arrayWithObjects:
                         [NSValue valueWithCGPoint:ccp(0, 0)],
                         [NSValue valueWithCGPoint:ccp(77/2, 226/2)],
                         [NSValue valueWithCGPoint:ccp(0, 0)],
                         [NSValue valueWithCGPoint:ccp(77/2, 136/2)],
                         [NSValue valueWithCGPoint:ccp(153/2, 181/2)],
                         [NSValue valueWithCGPoint:ccp(230/2, 227/2)],
                         [NSValue valueWithCGPoint:ccp(153/2, 91/2)],
                         [NSValue valueWithCGPoint:ccp(230/2, 136/2)],
                         [NSValue valueWithCGPoint:ccp(306/2, 181/2)],
                         [NSValue valueWithCGPoint:ccp(230/2, 47/2)],
                         [NSValue valueWithCGPoint:ccp(306/2, 91/2)],
                         [NSValue valueWithCGPoint:ccp(383/2, 136/2)],
                         [NSValue valueWithCGPoint:ccp(0, 0)],
                         [NSValue valueWithCGPoint:ccp(383/2, 47/2)],
                         [NSValue valueWithCGPoint:ccp(0, 0)],
                         nil];
            
        }else{
            posArray = [NSArray arrayWithObjects:
                        [NSValue valueWithCGPoint:ccp(0, 0)],
                        [NSValue valueWithCGPoint:ccp(77, 226)],
                        [NSValue valueWithCGPoint:ccp(0, 0)],
                        [NSValue valueWithCGPoint:ccp(77, 136)],
                        [NSValue valueWithCGPoint:ccp(153, 181)],
                        [NSValue valueWithCGPoint:ccp(230, 227)],
                        [NSValue valueWithCGPoint:ccp(153, 91)],
                        [NSValue valueWithCGPoint:ccp(230, 136)],
                        [NSValue valueWithCGPoint:ccp(306, 181)],
                        [NSValue valueWithCGPoint:ccp(230, 47)],
                        [NSValue valueWithCGPoint:ccp(306, 91)],
                        [NSValue valueWithCGPoint:ccp(383, 136)],
                        [NSValue valueWithCGPoint:ccp(0, 0)],
                        [NSValue valueWithCGPoint:ccp(383, 47)],
                        [NSValue valueWithCGPoint:ccp(0, 0)],
                        nil];
        }
		[posArray retain];
        
        // 初始化5个阵位八卦和5个阵位中的角色
        phalanxIconArray = [NSMutableArray array];
		[phalanxIconArray retain];
		
        roleArray = [NSMutableArray array];
		[roleArray retain];
		
        for (int i = 0; i < 5; i++) {
            NSString *iconName = i == 0 ? @"images/animations/phalanx/1/0.png" : @"images/animations/phalanx/0/0.png";
            PhalanxIcon *phalanxIcon = [PhalanxIcon spriteWithFile:iconName];
            phalanxIcon.isEye = (i == 0);
            phalanxIcon.anchorPoint = ccp(0.5, 0.43);
            [self addChild:phalanxIcon];
            [phalanxIconArray addObject:phalanxIcon];
        }
		
		normalPhalanxIcon = [AnimationViewer node];
		NSArray *normalFrames = [AnimationViewer loadFileByFileFullPath:@"images/animations/phalanx/0/" name:@"%d.png"];
		if (normalFrames.count != 0) {
			normalPhalanxIcon.anchorPoint = ccp(0.5, 0.43);
			[normalPhalanxIcon playAnimation:normalFrames delay:0.2];
			normalPhalanxIcon.visible = NO;
		}
		[self addChild:normalPhalanxIcon];
		
		eyePhalanxIcon = [AnimationViewer node];
		NSArray *eyeFrames = [AnimationViewer loadFileByFileFullPath:@"images/animations/phalanx/1/" name:@"%d.png"];
		if (eyeFrames.count != 0) {
			eyePhalanxIcon.anchorPoint = ccp(0.5, 0.43);
			[eyePhalanxIcon playAnimation:eyeFrames delay:0.2];
			eyePhalanxIcon.visible = NO;
		}
		[self addChild:eyePhalanxIcon];
        
        title = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:24];
        title.anchorPoint = ccp(0, 1);
        if (iPhoneRuningOnGame()) {
            title.position = ccp(13/2, 386/2);
            title.scale = 0.5;
        }else{
            title.position = ccp(13, 386);
		}
        title.color = ccc3(47, 16, 6);
        [self addChild:title];
        if (iPhoneRuningOnGame()) {
            effect = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(600/2, 300/2) hAlignment:kCCTextAlignmentLeft];
            effect.position = ccp(13/2, 350/2);
            effect.scale = 0.5;
        }else{
            effect = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:14 dimensions:CGSizeMake(600, 300) hAlignment:kCCTextAlignmentLeft];
            effect.position = ccp(13, 350);
        }
        effect.anchorPoint = ccp(0, 1);
        effect.color = ccc3(47, 16, 6);
        [self addChild:effect];
        
        phalanxAttributeTips = [[[PhalanxAttributeTips alloc] init] autorelease];
        if (iPhoneRuningOnGame()) {
            phalanxAttributeTips.scale = 1.3f;
        }
        [self addChild:phalanxAttributeTips z:1000];
        
        currentphalanxId = -1;
    }
    return self;
}

-(void)updateDetailByPhalanxLevel:(NSDictionary *)phalanxLevel level:(int)level
{
    // 阵形id
    int pid = [[phalanxLevel objectForKey:@"pid"] intValue];
    
    // 读取阵形表
    NSDictionary *phalanx = [[GameDB shared] getPositionInfo:pid];
    //title.string = [NSString stringWithFormat:@"%@ %d级", [phalanx objectForKey:@"name"], level];
    title.string = [NSString stringWithFormat:NSLocalizedString(@"phalanx_level",nil), [phalanx objectForKey:@"name"], level];
    NSString *info = [phalanx objectForKey:@"info"];
    effect.string = [[info componentsSeparatedByString:@"|"] componentsJoinedByString:@"\n"];
    int eye = [[phalanx objectForKey:@"eye"] intValue];
    int count = 0;
    
    NSString *value1 = [phalanxLevel objectForKey:@"s1"];
    NSString *value3 = [phalanxLevel objectForKey:@"s3"];
    if ([value1 isEqualToString:@""] && [value3 isEqualToString:@""]) {
        adjustPos = 0;
    } else {
        adjustPos = 3;
    }
    
    if (phalanxId != currentphalanxId) {
        [self updateRolesByPhalanxId:pid];
        
        currentphalanxId = phalanxId;
    }
    
    for (int i = 1; i <= 15; i++) {
        NSString *key = [NSString stringWithFormat:@"s%d", i];
        NSString *value = [phalanxLevel objectForKey:key];
        if (![value isEqualToString:@""]) {
            if (i != eye) {
                [self setPhalanxIconPos:++count :i+adjustPos :value];
            } else {
                [self setPhalanxIconPos:0 :eye+adjustPos :value];
            }
        }
    }
	
	NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
	if (playerPhalanx) {
		int mainRoleId = [[GameConfigure shared] getPlayerRole];
		BOOL existMainRole = NO;
		for (int i = 1; i <= 15; i++) {
			int roleId = [[playerPhalanx objectForKey:[NSString stringWithFormat:@"s%d", i]] intValue];
			if (roleId == mainRoleId) {
				existMainRole = YES;
				break;
			}
		}
		// 如果主角不在阵列中，将主角放到阵眼中
		if (!existMainRole) {
			NSDictionary *phalanxDict = [[GameDB shared] getPositionInfo:pid];
			if (phalanxDict) {
				int eye = [[phalanxDict objectForKey:@"eye"] intValue];
				playerPhalanx = [self setIndexWithPlayerPhalanx:(NSMutableDictionary*)playerPhalanx index:eye roleId:mainRoleId];
				[self updatePlayerPhalanx:playerPhalanx indexs:[NSString stringWithFormat:@"%d", eye]];
			}
		}
	}
}

-(void)showAttribute:(NSString *)attribute isEye:(BOOL)isEye atPoint:(CGPoint)point
{
    [phalanxAttributeTips setLayerWithAttribute:attribute isEye:isEye atPoint:point];
}

-(void)hiddenAttribute
{
    if (phalanxAttributeTips.visible) {
        phalanxAttributeTips.visible = NO;
    }
}

-(CCNode*)getSelectedRoleWithRoleId:(int)rid{
	
	/*
     CCSprite * node = [CCSprite node];
     AnimationViewer *roleAnima = [AnimationViewer node];
     [node addChild:roleAnima];
     
     NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:rid];
     if (roleInfo) {
     
     float offset = [[roleInfo objectForKey:@"offset"] intValue];
     offset = cFixedScale(offset);
     
     NSString *fullPath = nil;
     
     // 主角
     if (rid == [RoleManager shared].player.role_id) {
     
     int eqid = 0;
     int eq2 = 0;
     
     NSDictionary* playerRole = [[GameConfigure shared] getPlayerRoleFromListById:rid];
     if (playerRole) {
     eq2 = [[playerRole objectForKey:@"eq2"] intValue];
     NSDictionary* playerEquip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
     if (playerEquip) {
     eqid = [[playerEquip objectForKey:@"eid"] intValue];
     }
     }
     
     if (eqid == 0) {
     fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/2/battle-stand/", rid];
     } else {
     fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d_%d/2/battle-stand/", rid, eqid];
     }
     }else{
     fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/2/battle-stand/", rid];
     }
     
     NSArray * roleFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
     [roleAnima playAnimation:roleFrames delay:0.2];
     //roleAnima.anchorPoint = ccp(0.5, offset / roleAnima.contentSize.height);
     roleAnima.anchorPoint = ccp(0.5, 0);
     roleAnima.position = ccp(0,-offset);
     
     }
     */
	
	RoleViewerContent * target = [RoleViewerContent node];
	target.dir = 2;
	[target loadTargetRole:rid];
	return target;
}

-(void)initSelectedRoleWithRoleId:(int)rid atPoint:(CGPoint)point
{
	selectedRoleId = rid;
	CCNode *roleChild = [self getChildByTag:Tag_Selected_Role];
    if (roleChild) {
        [roleChild removeFromParentAndCleanup:YES];
        roleChild = nil;
    }
	
	CCNode *roleAnima = [self getSelectedRoleWithRoleId:rid];
	if (roleAnima) {
		roleAnima.tag = Tag_Selected_Role;
		roleAnima.position = point;
		[self addChild:roleAnima z:100];
	}
	
}

-(void)setSelectRoleWithRoleId:(int)rid touch:(UITouch *)touch
{
    if(rid==21){
		//CCLOG(@"%@",currenNode);
		[[Intro share]removeCurrenTipsAndNextStep:INTRO_Phalanx_Step_1];
		[[Intro share]runIntroTager:currenNodeStation step:INTRO_Phalanx_Step_2];
	}
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
	[self initSelectedRoleWithRoleId:rid atPoint:touchLocation];
	
    fromMember = YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (isTouchReal) return NO;
	
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    CGRect realRect = CGRectZero;
    if (iPhoneRuningOnGame()) {
        realRect = CGRectMake(-45/2, -24/2, 90/2, 120/2);
    }else{
        realRect = CGRectMake(-45, -24, 90, 120);
	}
    PhalanxIcon *finalPhalanxIcon = nil;
    for (PhalanxIcon *phalanxIcon in phalanxIconArray) {
        if (CGRectContainsPoint(CGRectOffset(realRect, phalanxIcon.position.x, phalanxIcon.position.y),
                                touchLocation)) {
			
			if (finalPhalanxIcon) {
				if (finalPhalanxIcon.position.y > phalanxIcon.position.y) {
					finalPhalanxIcon = phalanxIcon;
				}
			} else {
				finalPhalanxIcon = phalanxIcon;
			}
        }
    }
	if (finalPhalanxIcon) {
		int roleId = [self getRoleIdByPhalanxId:phalanxId index:finalPhalanxIcon.tag];
		// 出战状态点击才有效
		if (roleId != 0 && [self isRoleIn:roleId]) {
			self.dragRole = YES;
			
			[self initSelectedRoleWithRoleId:roleId atPoint:touchLocation];
			// 改变角色锚点为当前点击位置
			CCNode *roleChild = [self getChildByTag:Tag_Selected_Role];
			if (roleChild) {
				CGPoint offsetPoint = ccpSub(touchLocation, finalPhalanxIcon.position);
				CGPoint offsetAnchor = ccp(offsetPoint.x/cFixedScale(200),
										   offsetPoint.y/cFixedScale(200));
				roleChild.anchorPoint = ccpAdd(roleChild.anchorPoint, offsetAnchor);
				roleChild.position = touchLocation;
			}
            
			fromMember = NO;
		}
		[self showAttribute:finalPhalanxIcon.info isEye:finalPhalanxIcon.isEye atPoint:finalPhalanxIcon.position];
	}
    
	if (CGRectContainsPoint(CGRectMake(0, 0, self.contentSize.width, self.contentSize.height), touchLocation)) {
		isTouchReal = YES;
		return YES;
	}
    return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	CCNode *roleChild = [self getChildByTag:Tag_Selected_Role];
    if (roleChild) {
        roleChild.position = touchLocation;
        CGRect realRect = CGRectZero;
        if (iPhoneRuningOnGame()) {
            realRect = CGRectMake(-45/2, -24/2, 90/2, 120/2);
        }else{
            realRect = CGRectMake(-45, -24, 90, 120);
        }
        int currentMovePhalanxId = -1;
        PhalanxIcon *currentPhalanxIcon = nil;
        for (PhalanxIcon *phalanxIcon in phalanxIconArray) {
            if (CGRectContainsPoint(CGRectOffset(realRect, phalanxIcon.position.x, phalanxIcon.position.y),
                                    touchLocation)) {
				
				if (currentPhalanxIcon) {
					if (currentPhalanxIcon.position.y > phalanxIcon.position.y) {
						currentPhalanxIcon = phalanxIcon;
					}
				} else {
					currentPhalanxIcon = phalanxIcon;
				}
            }
        }
		
		if (currentPhalanxIcon) {
			currentMovePhalanxId = currentPhalanxIcon.tag;
		}
		
        if (currentMovePhalanxId != -1 && movePhalanxId == -1) {
            [self enterPhalanxIndex:currentMovePhalanxId];
            if (currentPhalanxIcon) {
                [self showAttribute:currentPhalanxIcon.info isEye:currentPhalanxIcon.isEye atPoint:currentPhalanxIcon.position];
            }
			
            movePhalanxId = currentMovePhalanxId;
        }
        // 刚离开阵位
        if (movePhalanxId != -1 && (currentMovePhalanxId != movePhalanxId)) {
            [self leavePhalanxIndex:movePhalanxId];
            [self hiddenAttribute];
            
            movePhalanxId = -1;
        }
    }
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
	CCNode *roleChild = [self getChildByTag:Tag_Selected_Role];
	if (roleChild) {
        // 在阵位上
        if (movePhalanxId != -1) {
            [self leavePhalanxIndex:movePhalanxId];
            
			int selectRoleId = selectedRoleId;
            int phalanxRoleId = [self getRoleIdByPhalanxId:phalanxId index:movePhalanxId];
            // 移动到不同角色上
            if (selectRoleId != phalanxRoleId) {
                // 拖拽角色的阵位（0为没有）
                int selectRoleIndex = [self getIndexByPhalanxId:phalanxId roleId:selectRoleId];
				int hostRoleId = [[GameConfigure shared] getPlayerRole];
				if (phalanxRoleId == hostRoleId && selectRoleIndex == 0) {
					//[ShowItem showItemAct:@"主角不能离阵"];
                    [ShowItem showItemAct:NSLocalizedString(@"phalanx_no_main_role",nil)];
				} else {
					NSMutableArray *indexArray = [NSMutableArray array];
					
					NSMutableDictionary *dict = (NSMutableDictionary *)[[GameConfigure shared] getPlayerPhalanxByPhalanxId:phalanxId];
					if (selectRoleIndex != 0) {
						dict = [self setIndexWithPlayerPhalanx:dict index:selectRoleIndex roleId:phalanxRoleId];
						
						[indexArray addObject:[NSString stringWithFormat:@"%d", selectRoleIndex]];
					}
					dict = [self setIndexWithPlayerPhalanx:dict index:movePhalanxId roleId:selectRoleId];
					
					[indexArray addObject:[NSString stringWithFormat:@"%d", movePhalanxId]];
					NSString *indexs = [indexArray componentsJoinedByString:@"|"];
					
					[self updatePlayerPhalanx:dict indexs:indexs];
				}
            }
        }
        // 离开阵形信息框
        else if (!fromMember && !CGRectContainsPoint(CGRectMake(0, 0, self.contentSize.width, self.contentSize.height), touchLocation)) {
			int selectRoleId = selectedRoleId;
			int hostRoleId = [[GameConfigure shared] getPlayerRole];
			if (hostRoleId == selectRoleId) {
				//[ShowItem showItemAct:@"主角不能离阵"];
                [ShowItem showItemAct:NSLocalizedString(@"phalanx_no_main_role",nil)];
			} else {
				int selectRoleIndex = [self getIndexByPhalanxId:phalanxId roleId:selectRoleId];
				
				NSMutableDictionary *dict = (NSMutableDictionary *)[[GameConfigure shared] getPlayerPhalanxByPhalanxId:phalanxId];
				dict = [self setIndexWithPlayerPhalanx:dict index:selectRoleIndex roleId:0];
				NSString *indexs = [NSString stringWithFormat:@"%d", selectRoleIndex];
				
				[self updatePlayerPhalanx:dict indexs:indexs];
			}
        }
		// 新手教程，拖关平
		else if (fromMember && [Intro getCurrenStep]==INTRO_Phalanx_Step_2 && selectedRoleId == 21) {
			[[Intro share] runBackIntro];
			if (guanpingNode) {
				[[Intro share] runIntroTager:guanpingNode step:INTRO_Phalanx_Step_1];
			}
		}
		
		[roleChild removeFromParentAndCleanup:YES];
		roleChild = nil;
    }
	
    selectedRoleId = 0;
    movePhalanxId = -1;
    
    [self hiddenAttribute];
	
	isTouchReal = NO;
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCNode *roleChild = [self getChildByTag:Tag_Selected_Role];
	if (roleChild) {
		if (fromMember && [Intro getCurrenStep]==INTRO_Phalanx_Step_2 && selectedRoleId == 21) {
			[[Intro share] runBackIntro];
			if (guanpingNode) {
				[[Intro share] runIntroTager:guanpingNode step:INTRO_Phalanx_Step_1];
			}
		}
		
		[roleChild removeFromParentAndCleanup:YES];
		roleChild = nil;
	}
	
	selectedRoleId = 0;
    movePhalanxId = -1;
    
    [self hiddenAttribute];
	
	isTouchReal = NO;
}

-(void)updatePlayerPhalanx:(NSDictionary *)dict indexs:(NSString *)indexs
{
    NSMutableDictionary *adjustDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSMutableDictionary *t_dict = [NSMutableDictionary dictionary];
    [t_dict setObject:dict forKey:@"dict"];
    [t_dict setObject:indexs forKey:@"indexs"];
    [GameConnection request:@"posSet" data:adjustDict target:self call:@selector(didUpdate::) arg:t_dict];
}

-(void)didUpdate:(id)sender :(NSDictionary*)_data
{
    if (checkResponseStatus(sender)) {
        if (_data) {
            NSDictionary *dict = [_data objectForKey:@"dict"];
            NSString *indexs = [_data objectForKey:@"indexs"];
            
            // 更新本地玩家阵形数据
            [[GameConfigure shared] updatePlayerPhalanx:dict];
            
            // 更新角色站位显示
            NSArray *indexArray = [indexs componentsSeparatedByString:@"|"];
            for (NSString *string in indexArray) {
                int value = [string intValue];
                [self updateRoleByPhalanxIndex:value];
            }
            
            if (delegate && [delegate respondsToSelector:@selector(updateMemberListByPhalanxId:)]) {
                [delegate updateMemberListByPhalanxId:phalanxId];
            }
        }
    } else {
        CCLOG(@"修改玩家阵形不成功");
    }
}

@end

@implementation PhalanxInfoMenu

@synthesize isActive;
@synthesize isSelected;
@synthesize study;
@synthesize levelup;
@synthesize use;
@synthesize title;

-(id)initWithPhalanxId:(int)pid
{
    if (self = [super init]) {
        itemBg = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_menu_bg.png"];
        currentItemBg = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_menu_bg2.png"];
        
        self.contentSize = itemBg.contentSize;
        CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        itemBg.position = halfPoint;
        currentItemBg.position = halfPoint;
        currentItemBg.visible = NO;
        [self addChild:itemBg];
        [self addChild:currentItemBg];
        
        currentColor = ccc3(254, 242, 99);
        color = ccc3(47, 19, 8);
        
        icon = getPhalanxIcon(pid);
        icon.position = ccp(33, 39);
        [self addChild:icon];
        
        study = [CCSprite spriteWithFile:@"images/ui/button/bt_study.png"];
        if (iPhoneRuningOnGame()) {
            study.scale =1.1f;
        }
        study.position = ccp(102, 18);
        study.visible = NO;
        [self addChild:study];
        
        levelup = [CCSprite spriteWithFile:@"images/ui/button/bt_levelup.png"];
        if (iPhoneRuningOnGame()) {
            levelup.scale =1.1f;
        }
        
        levelup.position = ccp(102, 18);
        levelup.visible = NO;
        [self addChild:levelup];
        
        //use = [CCLabelTTF labelWithString:@"(启用中）" fontName:@"Helvetica-Bold" fontSize:13];
        use = [CCLabelTTF labelWithString:NSLocalizedString(@"phalanx_use",nil) fontName:@"Helvetica-Bold" fontSize:13];
        use.color = ccc3(141, 198, 60);
        use.anchorPoint = ccp(0, 0.5);
        use.position = ccp(68, 61);
        use.visible = NO;
        [self addChild:use];
        
        title = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:13];
        title.color = color;
        title.anchorPoint = ccp(0, 0.5);
        title.position = ccp(68, 42);
        [self addChild:title];
        if (iPhoneRuningOnGame()) {
            icon.position = ccp(33/2.0f, 39/2.0f);
            study.position = ccp(102/2.0f, 18/2.0f);
            levelup.position = ccp(102/2.0f, 18/2.0f);
            use.position = ccp(68/2.0f, 61/2.0f);
            use.scale = 0.5f;
            title.position = ccp(68/2.0f, 42/2.0f);
            title.scale = 0.5f;
        }
//		showNode(levelup);
        isActive = NO;
        isSelected = NO;
    }
    return self;
}

-(void)setIsActive:(BOOL)_isActive
{
    use.visible = _isActive;
    itemBg.visible = !_isActive;
    currentItemBg.visible = _isActive;
    title.color = _isActive ? currentColor : color;
    
    isActive = _isActive;
}

-(void)setIsSelected:(BOOL)_isSelected
{
    if (isActive) {
        return;
    }
    
    itemBg.visible = !_isSelected;
    currentItemBg.visible = _isSelected;
    title.color = _isSelected ? currentColor : color;
}

@end

@implementation PhalanxList

@synthesize delegate;

-(id)init
{
    BOOL initIsTrue = false;
    if (iPhoneRuningOnGame()) {
        if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:144/2.0f height:545/2.0f]) {
            initIsTrue = true;
        }
    }else{
        if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:141 height:401]) {
            initIsTrue = true;
        }
    }
    if (initIsTrue) {
		[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority+1 swallowsTouches:YES];
        
        activePid = -1;
        selectedPid = -1;
        
        NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
        int playerLevel = [[playerInfo objectForKey:@"level"] intValue];
        
        NSDictionary *phalanxDict = [[GameDB shared] readDB:@"position"];
        // 排序
        NSArray *sorteArray = [[phalanxDict allKeys] sortedArrayUsingComparator:^(id obj1, id obj2){
            if([obj1 integerValue] > [obj2 integerValue]) {
                return(NSComparisonResult)NSOrderedDescending;
            }
            if([obj1 integerValue] < [obj2 integerValue]) {
                return(NSComparisonResult)NSOrderedAscending;
            }
            return(NSComparisonResult)NSOrderedSame;
        }];
        float scale_ = 1.2f;
        NSMutableArray *phalanxArray = [NSMutableArray array];
        for (NSString *key in sorteArray) {
            BOOL isStudy = NO;
            NSArray *playerPhalanxList = [[GameConfigure shared] getPlayerPhalanxList];
            for (NSDictionary *playerPhalanx in playerPhalanxList) {
                int pid = [[playerPhalanx objectForKey:@"posId"] intValue];
                // 已经学习了该阵形
                if (pid == [key intValue]) {
                    PhalanxInfoMenu *phalanxInfoMenu = [[[PhalanxInfoMenu alloc] initWithPhalanxId:pid] autorelease];
                    if (iPhoneRuningOnGame()) {
                        phalanxInfoMenu.scale = scale_;
                    }
                    int level = [[playerPhalanx objectForKey:@"level"] intValue];
                    NSDictionary *phalanx = [[GameDB shared] getPositionInfo:pid];
                    NSString *phalanxName = [phalanx objectForKey:@"name"];
                    //phalanxInfoMenu.title.string = [NSString stringWithFormat:@"%@ %d级", phalanxName, level];
                    phalanxInfoMenu.title.string = [NSString stringWithFormat:NSLocalizedString(@"phalanx_level",nil), phalanxName, level];
                    phalanxInfoMenu.tag = pid;
                    
                    if (getCanLevelupByPhalanxId(pid)) {
                        phalanxInfoMenu.levelup.visible= YES;
                    }
                    
                    [phalanxArray addObject:phalanxInfoMenu];
                    
                    isStudy = YES;
                    break;
                }
            }
            // 没学习该阵形，如果解锁，即显示需学习
            if (!isStudy) {
                NSDictionary *playerLevelDict = [[GameDB shared] readDB:[NSString stringWithFormat:@"pos_level_%d", [key intValue]]];
                if (playerLevelDict) {
                    NSArray *sorteLevelArray = [[phalanxDict allKeys] sortedArrayUsingComparator:^(id obj1, id obj2){
                        if([obj1 integerValue] > [obj2 integerValue]) {
                            return(NSComparisonResult)NSOrderedDescending;
                        }
                        if([obj1 integerValue] < [obj2 integerValue]) {
                            return(NSComparisonResult)NSOrderedAscending;
                        }
                        return(NSComparisonResult)NSOrderedSame;
                    }];
                    NSDictionary *firstDict = [playerLevelDict objectForKey:[sorteLevelArray objectAtIndex:0]];
                    if (firstDict) {
                        int needLevel = [[firstDict objectForKey:@"lockLevel"] intValue];
						// 除了解锁等级判断，还需要判断是否完成了某个任务
                        if (playerLevel >= needLevel) {
							BOOL islock = YES;
							int lockTask = [[firstDict objectForKey:@"lockTask"] intValue];
							if (lockTask == 0) {
								islock = NO;
							} else {
								NSDictionary *completeArray = [TaskManager shared].completeList;
								NSArray *completeKeys = [completeArray allKeys];
								if ([completeKeys containsObject:[NSString stringWithFormat:@"%d", lockTask]]) {
									islock = NO;
								}
							}
							// 解锁了
							if (!islock) {
								int pid = [key intValue];
								PhalanxInfoMenu *phalanxInfoMenu = [[[PhalanxInfoMenu alloc] initWithPhalanxId:pid] autorelease];
                                if (iPhoneRuningOnGame()) {
                                    phalanxInfoMenu.scale = scale_;
                                }
								NSDictionary *phalanx = [[GameDB shared] getPositionInfo:pid];
								NSString *phalanxName = [phalanx objectForKey:@"name"];
								//phalanxInfoMenu.title.string = [NSString stringWithFormat:@"%@ %d级", phalanxName, 0];
                                phalanxInfoMenu.title.string = [NSString stringWithFormat:NSLocalizedString(@"phalanx_level",nil), phalanxName, 0];
								phalanxInfoMenu.tag = pid;
								phalanxInfoMenu.study.visible= YES;
								[phalanxArray addObject:phalanxInfoMenu];
							}
                        }
                    } else {
                        CCLOG(@"get pos_level_%d first Dictionary is nil", [key intValue]);
                    }
                } else {
                    CCLOG(@"get pos_level_%d is nil", [key intValue]);
                }
            }
        }
        
        float perHeight = 80;
        float offsetHeight = 6;
		float width = 141;
		
        if (iPhoneRuningOnGame()) {
//            if (isIphone5()) {
//                perHeight = 80/2 * 1.4;
//                offsetHeight = 6/2 *1.4;
//                 width = 141/2 *1.4;
//            }else{
                perHeight = 80*1.2/2;
                offsetHeight = 6*1.1/2;
                //width = 141/2;
//            }
        }else{
            perHeight = 80;
            offsetHeight = 6;
            //width = 141;
        }
		
        int count = phalanxArray.count;
		int totalCount=4;
		if (iPhoneRuningOnGame()) {
			//totalCount=5;
		}
		float pageHeight = perHeight*totalCount+offsetHeight*3;
        
		layerList = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
		if (count != 0) {
			CCNode *node = [phalanxArray lastObject];
			width = node.contentSize.width * node.scale;
			float layerListHeight = MAX(perHeight*count+offsetHeight*(count-1), pageHeight);
			layerList.contentSize = CGSizeMake(width, layerListHeight);
		}
        
        for (int i = 0; i < count; i++) {
            CCNode *node = [phalanxArray objectAtIndex:i];
			node.position = ccp(0, layerList.contentSize.height - perHeight*(i+1) - offsetHeight*i-1);
            [layerList addChild:node];
        }
		
		CCPanel *listPanel = [CCPanel panelWithContent:layerList viewSize:CGSizeMake(layerList.contentSize.width , pageHeight)];
		[listPanel updateContentToTop];
		listPanel.tag = 10;
        if (iPhoneRuningOnGame()) {
//            if (isIphone5()) {
//                listPanel.position = ccp(0,34);
//            }else{
                listPanel.position = ccp(0,115/2.0f+15);
//			}
        }else{
            listPanel.position = ccp(0, 65);
        }
		
		[listPanel showScrollBar:@"images/ui/common/scroll3.png"];
		[self addChild:listPanel];
        
		NSArray *usePhalanxBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_use_phalanx");
		
        CCMenuItemImage *usePhalanxMenuItem = [CCMenuItemImage itemWithNormalSprite:[usePhalanxBtns objectAtIndex:0]
                                                                     selectedSprite:[usePhalanxBtns objectAtIndex:1]
                                                                     disabledSprite:nil
                                                                             target:self
                                                                           selector:@selector(usePhalanxTapped)];
        usePhalanxMenuItem.position = ccp(71, 21);
        CCMenu *usePhalanxMenu = [CCMenu menuWithItems:usePhalanxMenuItem, nil];
        usePhalanxMenu.position = CGPointZero;
        
        if (iPhoneRuningOnGame()) {
			usePhalanxMenuItem.scale = 1.3f;
			usePhalanxMenuItem.position = ccp(71/2.0f+5, 21/2.0f+8);
        }
        [self addChild:usePhalanxMenu];
    }
    return self;
}

-(void)onEnter
{
	[super onEnter];
	
	requesting = NO;
}

-(void)setActiveWithPhalanxId:(int)pid
{
    for (PhalanxInfoMenu *phalanxInfoMenu in layerList.children) {
        phalanxInfoMenu.isActive = phalanxInfoMenu.tag == pid ? YES : NO;
    }
    
    activePid = pid;
}

-(void)setSelectedWithPhalanxId:(int)pid
{
    for (PhalanxInfoMenu *phalanxInfoMenu in layerList.children) {
        phalanxInfoMenu.isSelected = phalanxInfoMenu.tag == pid ? YES : NO;
    }
    
    selectedPid = pid;
}

-(void)updateByPhalanxId:(int)pid
{
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    for (PhalanxInfoMenu *phalanxInfoMenu in layerList.children) {
        if (pid == phalanxInfoMenu.tag) {
            phalanxInfoMenu.study.visible = NO;
            
            if (getCanLevelupByPhalanxId(pid)) {
                phalanxInfoMenu.levelup.visible = YES;
            } else {
                phalanxInfoMenu.levelup.visible = NO;
            }
            
            int level = [[playerPhalanx objectForKey:@"level"] intValue];
            
            NSDictionary *phalanx = [[GameDB shared] getPositionInfo:pid];
            NSString *phalanxName = [phalanx objectForKey:@"name"];
            
            //phalanxInfoMenu.title.string = [NSString stringWithFormat:@"%@ %d级", phalanxName, level];
            phalanxInfoMenu.title.string = [NSString stringWithFormat:NSLocalizedString(@"phalanx_level",nil), phalanxName, level];
            break;
        }
    }
}

-(void)usePhalanxTapped
{
    if (selectedPid == activePid) {
		//[ShowItem showItemAct:@"已启用"];
        [ShowItem showItemAct:NSLocalizedString(@"phalanx_used",nil)];
        return;
    }
	
	NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxById:playerPhalanxId];
	BOOL hasMainRole = NO;
	if (playerPhalanx) {
		for (int i = 1; i <= 15; i++) {
			int roleId = [[playerPhalanx objectForKey:[NSString stringWithFormat:@"s%d", i]] intValue];
			if (roleId == [[GameConfigure shared] getPlayerRole]) {
				hasMainRole = YES;
				break;
			}
		}
	}
	if (!hasMainRole) {
		//[ShowItem showItemAct:@"主角必须在阵中"];
        [ShowItem showItemAct:NSLocalizedString(@"phalanx_main_role_in",nil)];
		return;
	}
    
    NSString *str = [NSString stringWithFormat:@"pid::%d", playerPhalanxId];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:selectedPid] forKey:@"posId"];
    [dict setObject:[NSNumber numberWithInt:playerPhalanxId] forKey:@"playerPhalanxId"];
    [GameConnection request:@"posActive" format:str target:self call:@selector(didUsePhalanx::) arg:dict];
}

-(void)didUsePhalanx:(id)sender :(NSDictionary *)_data
{
    if (checkResponseStatus(sender)) {
        if (_data) {
			//[ShowItem showItemAct:@"成功启用阵形"];
            [ShowItem showItemAct:NSLocalizedString(@"phalanx_use_ok",nil)];
			int playerPid = [[_data objectForKey:@"playerPhalanxId"] intValue];
            [[GameConfigure shared] updatePlayerPosId:playerPid];
            
			int posId = [[_data objectForKey:@"posId"] intValue];
            [self setActiveWithPhalanxId:posId];
            [self setSelectedWithPhalanxId:posId];
        }
    } else {
        CCLOG(@"启用阵形失败");
    }
}

-(void)updateFatherByPlayerPhalanxId:(int)pid
{
    if (delegate && [delegate respondsToSelector:@selector(updatePanelByPlayerPhalanxId:)]) {
        [delegate updatePanelByPlayerPhalanxId:pid];
    }
}

-(void)showPhalanxWithId:(int)pid
{
	NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    playerPhalanxId = [[playerPhalanx objectForKey:@"id"] intValue];
	phalanxId = pid;
	selectedPid = pid;
	
	[self setSelectedWithPhalanxId:pid];
	[self updateFatherByPlayerPhalanxId:pid];
}

-(void)clickPhalanxWithId:(int)pid
{
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    playerPhalanxId = [[playerPhalanx objectForKey:@"id"] intValue];
    
    NSDictionary *phalanxLevel;
    
    phalanxId = pid;
    
    // 该阵形存在，但是又不在玩家列表中，需学习
    if (!playerPhalanx) {
		if (requesting) return;
		
        phalanxLevel = [[GameDB shared] getPositionLevelInfo:pid level:1];
        cost = [[phalanxLevel objectForKey:@"coin1"] intValue];
		
		NSString *levelInfo = [phalanxLevel objectForKey:@"info"];
		
		//NSString *message = [NSString stringWithFormat:@"学习该阵形需要花费 %d 银币，是否继续？*%@", cost, levelInfo];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"phalanx_study",nil), cost, levelInfo];
		[[AlertManager shared] showMessage:message target:self confirm:@selector(studyPhalanx) canel:@selector(cancelStudyPhalanx) father:delegate];
        
        return;
    }
    // 升级
    else if (getCanLevelupByPhalanxId(pid)) {
		if (requesting) return;
		
        selectedPid = pid;
        
        int level = [[playerPhalanx objectForKey:@"level"] intValue];
        phalanxLevel = [[GameDB shared] getPositionLevelInfo:pid level:level+1];
        cost = [[phalanxLevel objectForKey:@"coin1"] intValue];
		
		NSString *levelInfo = [phalanxLevel objectForKey:@"info"];
		
		//NSString *message = [NSString stringWithFormat:@"升级该阵形需要花费 %d 银币，是否继续？*%@", cost, levelInfo];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"phalanx_upgrade",nil), cost, levelInfo];
		[[AlertManager shared] showMessage:message target:self confirm:@selector(levelupPhalanx) canel:@selector(cancelLevelupPhalanx) father:delegate];
        
        return;
    }
    // 显示阵形信息
    else {
        [self showPhalanxWithId:pid];
    }
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (isTouchReal) return NO;
	
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	float widthScale = 1.0f;
	if (iPhoneRuningOnGame()) {
		widthScale = 1.2f;
	}
	if (CGRectContainsPoint(CGRectMake(0, 0, self.contentSize.width*widthScale, self.contentSize.height), touchLocation)) {
		isTouchReal = YES;
		return YES;
	} else {
		return NO;
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [layerList convertToNodeSpace:touchLocation];
    
    for (PhalanxInfoMenu *infoMenu in layerList.children) {
        if (CGRectContainsPoint(infoMenu.boundingBox, touchLocation)) {
			if (infoMenu.study.visible) {
				[self clickPhalanxWithId:infoMenu.tag];
			} else if (infoMenu.levelup.visible) {
				CGPoint offset = ccp(touchLocation.x - infoMenu.boundingBox.origin.x,
									 touchLocation.y - infoMenu.boundingBox.origin.y);
                CGRect rect = CGRectZero;
                if (iPhoneRuningOnGame()) {
					rect = CGRectMake(62*infoMenu.scale/2.0f, 4*infoMenu.scale/2.0f, 76*infoMenu.scale/2.0f, 70*infoMenu.scale/2.0f);
                }else{
                    rect = CGRectMake(62, 4, 76, 35);
				}
				// 判断是否升级
				if (CGRectContainsPoint(rect, offset)) {
					[self clickPhalanxWithId:infoMenu.tag];
				}
				// 直接切换
				else {
					[self showPhalanxWithId:infoMenu.tag];
				}
			} else {
				[self showPhalanxWithId:infoMenu.tag];
			}
            break;
        }
    }
	
	isTouchReal = NO;
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	isTouchReal = NO;
}

// 升级
-(void)levelupPhalanx
{
    NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
    int coin1 = [[playerInfo objectForKey:@"coin1"] intValue];
    if (coin1 < cost) {
		//[ShowItem showItemAct:@"升级银币不足"];
        [ShowItem showItemAct:NSLocalizedString(@"phalanx_upgrade_no_money",nil)];
        [self updateFatherByPlayerPhalanxId:phalanxId];
        [self setSelectedWithPhalanxId:phalanxId];
    }
    else {
        NSString *str = [NSString stringWithFormat:@"pid::%d", playerPhalanxId];
        NSDictionary *phalanxDict = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:phalanxId];
        int level = [[phalanxDict objectForKey:@"level"] intValue];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSNumber numberWithInt:phalanxId] forKey:@"posId"];
        [dict setObject:[NSNumber numberWithInt:level] forKey:@"level"];
        [GameConnection request:@"posUpgrade" format:str target:self call:@selector(didLevelup::) arg:dict];
		
		requesting = YES;
    }
}

-(void)cancelLevelupPhalanx
{
    [self updateFatherByPlayerPhalanxId:phalanxId];
    [self setSelectedWithPhalanxId:phalanxId];
}

-(void)cancelStudyPhalanx
{
	// 取消学习时候，回滚playerPhalanxId
	NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:selectedPid];
	if (playerPhalanx) {
		playerPhalanxId = [[playerPhalanx objectForKey:@"id"] intValue];
	}
}

-(void)didLevelup:(NSDictionary *)sender :(NSDictionary *)_data
{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            int posId = [[_data objectForKey:@"posId"] intValue];
            int level = [[_data objectForKey:@"level"] intValue];
            [[GameConfigure shared] updatePlayerPhalanxWithId:posId level:level+1];
            [[GameConfigure shared] updatePlayerMoney:[[dict objectForKey:@"coin1"] intValue]];
            [self updateFatherByPlayerPhalanxId:phalanxId];
            [self setSelectedWithPhalanxId:phalanxId];
            [self updateByPhalanxId:phalanxId];
        }
        
        //[ShowItem showItemAct:@"成功升级阵型"];
        [ShowItem showItemAct:NSLocalizedString(@"phalanx_upgrade_ok",nil)];
        
    } else {
        CCLOG(@"升级失败");
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
	
	requesting = NO;
}

// 学习
-(void)studyPhalanx
{
    NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
    int coin1 = [[playerInfo objectForKey:@"coin1"] intValue];
    if (coin1 < cost) {
		//[ShowItem showItemAct:@"学习银币不足"];
        [ShowItem showItemAct:NSLocalizedString(@"phalanx_study_no_money",nil)];
    }
    else {
        NSString *str = [NSString stringWithFormat:@"pid::%d", phalanxId];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        int pid = [[playerInfo objectForKey:@"id"] intValue];
        [dict setObject:[NSNumber numberWithInt:pid] forKey:@"pid"];
        [dict setObject:[NSNumber numberWithInt:phalanxId] forKey:@"posId"];
        [GameConnection request:@"posStudy" format:str target:self call:@selector(didStudy::) arg:dict];
		
		requesting = YES;
    }
}

-(void)didStudy:(NSDictionary *)sender :(NSDictionary *)_data
{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            NSMutableDictionary *playerPhalanx = [NSMutableDictionary dictionary];
            int _id = [[dict objectForKey:@"pid"] intValue];
            int pid = [[_data objectForKey:@"pid"] intValue];
            int posId = [[_data objectForKey:@"posId"] intValue];
            
            selectedPid = pid;
            
            [playerPhalanx setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
            [playerPhalanx setObject:[NSNumber numberWithInt:pid] forKey:@"pid"];
            [playerPhalanx setObject:[NSNumber numberWithInt:posId] forKey:@"posId"];
            [playerPhalanx setObject:[NSNumber numberWithInt:1] forKey:@"level"];
            for (int i = 1; i <= 15; i++) {
                NSString *key = [NSString stringWithFormat:@"s%d", i];
                [playerPhalanx setObject:[NSNumber numberWithInt:0] forKey:key];
            }
            [[GameConfigure shared] addPlayerPhalanx:playerPhalanx];
            [[GameConfigure shared] updatePlayerMoney:[[dict objectForKey:@"coin1"] intValue]];
            [self setSelectedWithPhalanxId:phalanxId];
            [self updateByPhalanxId:phalanxId];
			
			[self updateFatherByPlayerPhalanxId:phalanxId];
            
            NSDictionary *newPlayerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:posId];
            if (newPlayerPhalanx) {
                playerPhalanxId = [[newPlayerPhalanx objectForKey:@"id"] intValue];
            }
            //[ShowItem showItemAct:@"成功学习阵型"];
            [ShowItem showItemAct:NSLocalizedString(@"phalanx_study_ok",nil)];
        }
        
    } else {
        CCLOG(@"学习失败");
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
	
	requesting = NO;
}

-(void)onExit
{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	
	CCNode *listNode = [self getChildByTag:10];
	if (listNode) {
		[listNode removeFromParentAndCleanup:YES];
		listNode = nil;
	}
	
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end

// 主要内容框
@interface PhalanxBox : CCLayerColor{
    
}

@end

@implementation PhalanxBox

-(void)draw
{
    [super draw];
    glLineWidth(1.0f);
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    ccDrawRect(ccp(0, 0), ccp(self.contentSize.width, self.contentSize.height));
}

-(id)init
{
    BOOL initIsTrue = false;
    if (iPhoneRuningOnGame()) {
            if (self = [super initWithColor:ccc4(0, 0, 0, 190/2) width:475 height:556/2]) {
                initIsTrue = true;
            }
    }else{
        if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:820 height:418]) {
            initIsTrue = true;
        }
        
    }
    if (initIsTrue) {
    }
    return  self;
}

@end

@implementation PhalanxPanel

-(void)onEnter
{
    [super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	currenNodeClose = _closeBnt;
    
    // 大内容框
    phalanxBox = [PhalanxBox node];
    if (iPhoneRuningOnGame()) {
        phalanxBox.position = ccp(0 + 46,12);
    }else{
        phalanxBox.position = ccp(self.contentSize.width/2-410.5, self.contentSize.height/2-232);
	}
    [self addChild:phalanxBox];
    
    
    phalanxMemberList = [PhalanxMemberList node];
    phalanxMemberList.position = ccp(7, 9);
    [phalanxBox addChild:phalanxMemberList z:10];
    phalanxMemberList.delegate = self;
    phalanxDetail = [PhalanxDetail node];
    if (iPhoneRuningOnGame()) {
		phalanxMemberList.position = ccp(10/2+3, 5/2);
		phalanxDetail.scaleX = 1.37f;
		phalanxDetail.scaleY = 1.37f;
		phalanxDetail.position =  ccp(180/2 + 11, 39);
    }else{
        phalanxDetail.position = ccp(200, 9);
	}
    
    phalanxDetail.dragRole = NO;
    [phalanxBox addChild:phalanxDetail z:10];
    phalanxDetail.delegate = self;
    
    // 设置阵型信息
    phalanxList = [PhalanxList node];
    if (iPhoneRuningOnGame()) {
		phalanxList.position = ccp(407-22, 0);
    }else{
        phalanxList.position = ccp(672, 9);
    }
	
    [phalanxBox addChild:phalanxList z:5];
    phalanxList.delegate = self;
    
    // 默认阵容Id
    int posId = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"posId"] intValue];
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxById:posId];
    int currentPosId = 1;
    if (playerPhalanx) {
        currentPosId = [[playerPhalanx objectForKey:@"posId"] intValue];
        
    }
    [self updateByPhalanxId:currentPosId];
    
    // 默认
    [phalanxList setActiveWithPhalanxId:currentPosId];
    [phalanxList setSelectedWithPhalanxId:currentPosId];
}

-(void)updateByPhalanxId:(int)pid
{
    // 更新左栏成员列表出战状态
    [phalanxMemberList updateByPhalanxId:pid];
    
    // 阵形内容
    NSDictionary *playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:pid];
    if (!playerPhalanx) {
        playerPhalanx = [[GameConfigure shared] getPlayerPhalanxByPhalanxId:1];
    }
    
    int level = [[playerPhalanx objectForKey:@"level"] intValue];
    NSDictionary *phalanxLevel = [[GameDB shared] getPositionLevelInfo:pid level:level];
    phalanxDetail.phalanxId = pid;
    [phalanxDetail updateDetailByPhalanxLevel:phalanxLevel level:level];
}

-(void)clickMemberWithRoleId:(int)rid touch:(UITouch *)touch
{
    phalanxDetail.dragRole = YES;
    [phalanxDetail setSelectRoleWithRoleId:rid touch:touch];
}

-(void)updateMemberListByPhalanxId:(int)pid
{
    [self updateByPhalanxId:pid];
}

-(void)updatePanelByPlayerPhalanxId:(int)pid
{
    [self updateByPhalanxId:pid];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void)closeWindow{
	[super closeWindow];
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_CLOSE_Phalanx];
}

-(void)onExit
{
    phalanxBox = nil;
    phalanxMemberList = nil;
    phalanxDetail = nil;
    phalanxList = nil;
	
	isTouchReal = NO;

	[super onExit];
}

-(int)getAboutZIndex
{
	return 0;
}

-(void)draw
{
	[super draw];
}

@end
