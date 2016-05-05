//
//  DragonWorldMap.m
//  TXSFGame
//
//  Created by peak on 13-9-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "DragonWorldMap.h"
#import "GameDB.h"
#import "CCLabelFX.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "InfoAlert.h"
#import "DragonDefine.h"
#import "DragonFightData.h"

//#define MAP_NODE_STEP_W (800)
//#define MAP_NODE_STEP_H (70)
@interface XDashedLine : CCNode{
    CGPoint startPos;
    CGPoint endPos;
}
@property(assign,nonatomic) CGPoint startPos;
@property(assign,nonatomic) CGPoint endPos;
@end
@implementation XDashedLine
@synthesize startPos;
@synthesize endPos;
@end

#pragma mark -
#pragma mark dragon world map node face
//
@interface DragonWorldMapNode:CCNode{
    int nodeID;
    int nodeType;
    int nodeAPCID;
    int nodeIconID;
    NSString *nodeName;
    NSString *unionName;
    int nodeState;
    int nodeLineType;
    int nodeFaceType;
    CGPoint pos;
    BOOL isSetPos;
    BOOL isChange;//可选（可以按）
    int pathNodeID;
    //
    NSMutableArray *frontMutArray;
    NSMutableArray *nextMutArray;
}
@property(assign,nonatomic) int nodeID;
@property(assign,nonatomic) int nodeType;
@property(assign,nonatomic) int nodeFaceType;
@property(assign,nonatomic) int nodeAPCID;
@property(assign,nonatomic) int nodeIconID;
@property(assign,nonatomic) int nodeState;
@property(assign,nonatomic) NSString* nodeName;
@property(assign,nonatomic) NSString* unionName;
@property(assign,nonatomic) CGPoint pos;
@property(assign,nonatomic) BOOL isSetPos;
@property(assign,nonatomic) BOOL isChange;
@property(assign,nonatomic) int pathNodeID;
-(void)setUnionName:(NSString*)unionName;
-(void)drowLowLine;
-(void)drowLightLine;
-(void)drowBrokenLine;
-(void)removeFont:(DragonWorldMapNode*)node;
-(void)removeNext:(DragonWorldMapNode*)node;
-(void)removeAllFont;
-(void)removeAllNext;
-(void)addNodeFont:(DragonWorldMapNode*)node;
-(void)addNodeNext:(DragonWorldMapNode*)node;
-(NSArray*)getNodeFront;
-(NSArray*)getNodeNext;
@end

static int sortByMapNode(DragonWorldMapNode*p1, DragonWorldMapNode*p2, void*context){
	if(p2.nodeID > p1.nodeID) return NSOrderedAscending;
    return NSOrderedDescending;
}

#pragma mark -
#pragma mark dragon world map node face
@implementation DragonWorldMapNode
enum{
    NodeState_none = 0,
    NodeState_select,
    NodeState_can_select,
    NodeState_flash,
}NodeState;
enum{
    NodeType_monster = 1,
    NodeType_player,
}NodeType;
enum{
    NodeFaceType_leaf = 1,
    NodeFaceType_middle,
    NodeFaceType_root,
}NodeFaceType;
enum{
    NodeLinType_none = 0,
    NodeLinType_low,
    NodeLinType_light,
    NodeLinType_broken,
}NodeLineType;
enum{
    //NodeTag_effect,
    NodeTag_button = 1,
    NodeTag_icon,
    NodeTag_name,
    NodeTag_union_name,
    NodeTag_affiche,
    NodeTag_button_monster,
    NodeTag_button_player,
    NodeTag_button_back,
}NodeTag;
@synthesize nodeID;
@synthesize nodeType;
@synthesize nodeFaceType;
@synthesize nodeAPCID;
@synthesize nodeIconID;
@synthesize nodeState;
@synthesize nodeName;
@synthesize unionName;
@synthesize pos;
@synthesize isSetPos;
@synthesize isChange;
@synthesize pathNodeID;
-(id)init{
    if ((self = [super init])!=nil) {
        nodeID = 0;
        nodeType = NodeType_monster;
        //nodeType = NodeType_player;
        nodeAPCID  = 0;
        nodeName  = NULL;
        unionName  = NULL;
        nodeState  = NodeState_none;
        nodeLineType = NodeLinType_none;
        nodeFaceType =  NodeFaceType_leaf;
        pos = CGPointZero;
        isSetPos = NO;
        isChange = NO;
        pathNodeID = 0;
        //isChange = YES;
        self.contentSize = CGSizeMake(cFixedScale(74), cFixedScale(32));
        //
        frontMutArray = [NSMutableArray array];
        [frontMutArray retain];
        nextMutArray = [NSMutableArray array];
        [nextMutArray retain];
    }
    return self;
}

-(void)dealloc{
    if (frontMutArray) {
        [frontMutArray removeAllObjects];
        [frontMutArray release];
        frontMutArray = NULL;
    }
    if (nextMutArray) {
        [nextMutArray removeAllObjects];
        [nextMutArray release];
        nextMutArray = NULL;
    }
    //
    [super dealloc];
}

-(void)onEnter{
    [super onEnter];
    //TODO
    [self setIsChange:isChange];
    [self setNodeState:nodeState];
    [self setNodeName:nodeName];
    [self setNodeIconID:nodeIconID];
    CCLOG(@".....id:%d....x:%f y:%f",nodeID,pos.x,pos.y);
    
}

-(void)onExit{
    //
    [super onExit];
}
-(void)setNodeFaceType:(int)nodeFaceType_{
    nodeFaceType = nodeFaceType_;
    [self removeChildByTag:NodeTag_button cleanup:YES];
    //
    CCSimpleButton    *button = nil;
    //TODO
    if (isChange) {
        if (NodeFaceType_leaf == nodeFaceType) {
            if( NodeState_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_leaf_2.png"];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_leaf_1.png"];
            }
        }else if (NodeFaceType_root == nodeFaceType){
            if( NodeState_can_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_boss_2.png" ];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_boss_1.png"];
            }
        }else {
            if( NodeState_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_3.png"];
            }else if( NodeState_can_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_2.png"];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_1.png"];
            }
        }
    }else{
        if (NodeFaceType_leaf == nodeFaceType) {
            if( NodeState_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_leaf_2.png" select:@"images/ui/dragon/map_leaf_2.png" ];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_leaf_1.png" select:@"images/ui/dragon/map_leaf_1.png" ];
            }
        }else if (NodeFaceType_root == nodeFaceType){
            if( NodeState_can_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_boss_2.png" select:@"images/ui/dragon/map_boss_2.png" ];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_boss_1.png" select:@"images/ui/dragon/map_boss_1.png" ];
            }
        }else {
            if( NodeState_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_3.png" select:@"images/ui/dragon/map_node_3.png" ];
            }else if( NodeState_can_select == nodeState ){
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_2.png" select:@"images/ui/dragon/map_node_2.png" ];
            }else{
                button = [CCSimpleButton spriteWithFile:@"images/ui/dragon/map_node_1.png" select:@"images/ui/dragon/map_node_1.png" ];
            }
        }
    }
    if (NodeState_flash == nodeState) {
        [self setFighting];
    }
    //
    if (button) {
        self.contentSize = button.contentSize;
        [button setTarget:self];
        [button setCall:@selector(CallBack:)];
        [button setIsEnabled:isChange];
        [self addChild:button z:NodeTag_button tag:NodeTag_button];
    }
}

-(void)setIsChange:(BOOL)isChange_{
    isChange = isChange_;
    [self setNodeFaceType:nodeFaceType];
}

-(void)setNodeState:(int)nodeState_{
    nodeState = nodeState_;
    [self setNodeFaceType:nodeFaceType];
    //
    if (NodeState_select == nodeState) {
        [self showName];
    }
}
-(void)setFighting{
    [self removeChildByTag:NodeTag_union_name cleanup:YES];
    CCSprite *spr_ = [CCSprite spriteWithFile:@"images/ui/dragon/icon_fight.png"];
    spr_ = getSpriteWithSpriteAndNewSize(spr_, CGSizeMake(spr_.contentSize.width*4/6, spr_.contentSize.height*4/6));
    [self addChild:spr_ z:NodeTag_union_name tag:NodeTag_union_name];
    //[spr_ setPosition:ccp(0, self.contentSize.height/2)];
}
-(void)setUnionName:(NSString*)unionName_{
    unionName = unionName_;
    [self removeChildByTag:NodeTag_union_name cleanup:YES];
    
    if (NodeFaceType_leaf == nodeFaceType) {
        [self setNodeName:unionName];
    }else if(NodeFaceType_middle == nodeFaceType){
        CCSprite *spr_ = [CCSprite spriteWithFile:@"images/ui/dragon/map_flag.png"];
        [self addChild:spr_ z:NodeTag_union_name tag:NodeTag_union_name];
        [spr_ setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
        CCNode *name_ = [CCLabelFX labelWithString:unionName
                                       dimensions:CGSizeMake(0,0)
                                        alignment:kCCTextAlignmentLeft
                                         fontName:@"Verdana-Bold"
                                         fontSize:20
                                     shadowOffset:CGSizeMake(-0.5, -0.5)
                                       shadowBlur:1.0f
                                      shadowColor:ccc4(160,100,20, 128)
                                        fillColor:ccc4(255, 0, 0, 255)];
        [spr_ addChild:name_];
        [name_ setAnchorPoint:ccp(0, 0)];
        [name_ setPosition:ccp(0, spr_.contentSize.height)];
    }else if(NodeFaceType_root == nodeFaceType){
        CCSprite *spr_ = [CCSprite spriteWithFile:@"images/ui/dragon/map_flag.png"];
        [self addChild:spr_ z:NodeTag_union_name tag:NodeTag_union_name];
        [spr_ setPosition:ccp(self.contentSize.width/2+cFixedScale(6), self.contentSize.height/2+cFixedScale(6))];
    }
}
-(void)showName{
    [self removeChildByTag:NodeTag_name cleanup:YES];
    
    CCNode *name_ = nil;
    int size_ = 16;
    if (nodeName) {
        if (NodeFaceType_leaf == nodeFaceType) {
            size_ = 16;
        }else if (NodeFaceType_root == nodeFaceType){
            size_ = 26;
        }
        //name_ = getStrokeSprite(nodeName, getCommonFontName(FONT_2), cFixedScale(size_), cFixedScale(0.1), ccc4(255,240,220,255), ccc4(220,50,50,255));
        if (nodeName && [nodeName isKindOfClass:[NSString class]]) {
            if (NodeState_select == nodeState ) {
                name_ = drawBoundString(nodeName,
                                        8,
                                        GAME_DEF_CHINESE_FONT,
                                        size_,
                                        ccWHITE, ccc3(220, 30, 30));
            }else{
                name_ = drawBoundString(nodeName,
                                        8,
                                        GAME_DEF_CHINESE_FONT,
                                        size_,
                                        ccWHITE, ccc3(100, 50, 30));
            }
        }
    }
    if (name_) {
        [self addChild:name_ z:NodeTag_name tag:NodeTag_name];
        [name_ setPosition:ccp(0,cFixedScale(100/size_))];
    }
}
-(void)setNodeName:(NSString *)nodeName_{
    nodeName = nodeName_;
    //
    [self showName];
}

-(void)setNodeIconID:(int)nodeIconID_{
    nodeIconID = nodeIconID_;
    /*
    [self removeChildByTag:NodeTag_icon cleanup:YES];
    //
    CCNode *icon = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",nodeID]
                                        dimensions:CGSizeMake(0,0)
                                         alignment:kCCTextAlignmentLeft
                                          fontName:@"Verdana-Bold"
                                          fontSize:20
                                      shadowOffset:CGSizeMake(-0.5, -0.5)
                                        shadowBlur:1.0f
                                       shadowColor:ccc4(160,100,20, 128)
                                         fillColor:ccc4(0, 255, 0, 255)];
    if (icon) {
        [self addChild:icon z:NodeTag_icon tag:NodeTag_icon];
    }
     */
}
-(NSArray*)getDashedPointsWithStartPos:(CGPoint)startPos endPos:(CGPoint)endPos len:(float)len{
    NSMutableArray *mutArray = [NSMutableArray array];
    CGPoint vPos = ccp(endPos.x-startPos.x, endPos.y-startPos.y);
    vPos = ccpNormalize(vPos);
    for (; ; ) {
        if (ccpDistance(endPos,startPos)<len) {
            break;
        }else{
            
        }
        XDashedLine *dashedLine = [XDashedLine node];
        dashedLine.startPos = startPos;
        dashedLine.endPos = ccpAdd(ccp(vPos.x*len,vPos.y*len),startPos);
        [mutArray addObject:dashedLine];
        //
        startPos = dashedLine.endPos;
        if (ccpDistance(endPos,startPos)<len) {
            break;
        }
        startPos = ccpAdd(ccp(vPos.x*len,vPos.y*len),startPos);
    }
    float angle = ccpToAngle(vPos);
    CGPoint vPos_1 = ccpForAngle(angle+3.1415926/4.5);
    CGPoint vPos_2 = ccpForAngle(angle-3.1415926/4.5);
    float len_ = cFixedScale(12);
    //
    XDashedLine *dashedLine = [XDashedLine node];
    dashedLine.startPos = endPos;
    dashedLine.endPos = ccpAdd(ccpNeg(ccp(vPos.x*len_,vPos.y*len_)),endPos);
    [mutArray addObject:dashedLine];
    //
    dashedLine = [XDashedLine node];
    dashedLine.startPos = endPos;
    dashedLine.endPos = ccpAdd(ccpNeg(ccp(vPos_1.x*len_,vPos_1.y*len_)),endPos);
    [mutArray addObject:dashedLine];
    //
    dashedLine = [XDashedLine node];
    dashedLine.startPos = endPos;
    dashedLine.endPos = ccpAdd(ccpNeg(ccp(vPos_2.x*len_,vPos_2.y*len_)),endPos);
    [mutArray addObject:dashedLine];
    //
    return mutArray;
}

-(void)draw{
	[super draw];
    //TODO
    if (NodeLinType_none != nodeLineType) {
//        if (nodeLineType == NodeLinType_low) {
//            ccDrawColor4F(255, 190, 79, 128);
//            glLineWidth(0.5f);
//        }else if (nodeLineType == NodeLinType_light) {
//            ccDrawColor4F(74, 45, 49, 128);
//            glLineWidth(3.0f);
//        }else if(nodeLineType == NodeLinType_broken){
//            ccDrawColor4F(109, 80, 109, 128);
//            glLineWidth(3.0f);
//        }else {
//            ccDrawColor4F(255, 0, 0, 128);
//            glLineWidth(2.0f);
//        }
        //
        ccPointSize(10);
        for (DragonWorldMapNode *n in frontMutArray) {
            CGPoint pos_ = [self.parent convertToWorldSpace:n.pos];
            pos_ = [self convertToNodeSpace:pos_];
            pos_.y -= (n.contentSize.height/2-cFixedScale(4));
            if(nodeLineType == NodeLinType_broken){
                ccDrawColor4F(109, 80, 109, 128);
                glLineWidth(3.0f);
                NSArray *posArray = [self getDashedPointsWithStartPos:ccp(0, self.contentSize.height/2-cFixedScale(4)) endPos:pos_ len:cFixedScale(6)];
                for (XDashedLine *node in posArray) {
                    ccDrawLine(node.startPos,node.endPos);
                }
            }else if(nodeLineType == NodeLinType_light){
                if (pathNodeID == [n nodeID]) {
                    ccDrawColor4F(74, 45, 49, 128);
                    glLineWidth(3.0f);
                    ccDrawLine(ccp(0, self.contentSize.height/2-cFixedScale(4)),pos_);
                }else{
                    ccDrawColor4F(255, 190, 79, 128);
                    glLineWidth(0.5f);
                    ccDrawLine(ccp(0, self.contentSize.height/2-cFixedScale(4)),pos_);
                }
            }else{
                ccDrawColor4F(255, 190, 79, 128);
                glLineWidth(0.5f);
                ccDrawLine(ccp(0, self.contentSize.height/2-cFixedScale(4)),pos_);
            }
        }
    }
}
-(void)CallBack:(CCNode*)sender{
    CCLOG(@"------id:%d sender",nodeID);
    BOOL map_isChange = NO;
    DragonWorldMap *worldMap_ = nil;
    //
    CCNode *temp = self;
    for (;; ) {
        if (temp == NULL) {
            break;
        }
        if ([temp isKindOfClass:[DragonWorldMap class]]) {
            DragonWorldMap *temp_ = (DragonWorldMap *)temp;
            map_isChange = [temp_ isChange];
            worldMap_ = temp_;
            break;
        }
        temp = temp.parent;
    }
    //
    if (isChange && map_isChange) {
        if ( NodeType_monster == nodeType ) {
            NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
            [dict_ setValue:[NSNumber numberWithInt:nodeID] forKey:@"node"];
            [dict_ setValue:[NSNumber numberWithInt:nodeType] forKey:@"type"];
            [GameConnection request:@"awarWorldChoose" data:dict_ target:nil call:nil];
            [self setNodeState:NodeState_flash];
            if (worldMap_) {
                [worldMap_ setIsChange:NO];
            }
        }else if ( NodeType_player == nodeType ){
            //
            [self showAffiche];
        }
    }
}

-(void)showAffiche{
    //TODO
    CCSprite *affiche = [StretchingImg stretchingImg:@"images/ui/bound2.png" width:cFixedScale(450) height:cFixedScale(250) capx:cFixedScale(8) capy:cFixedScale(8)];
    CGSize size = [[CCDirector sharedDirector] winSize];
    CGPoint pos_ = ccp(size.width/2, size.height/2);
    pos_ = [self.parent convertToNodeSpace:pos_];
    affiche.position = pos_;
    [self.parent addChild:affiche z:NodeTag_affiche tag:NodeTag_affiche];
    CGPoint off_pos = ccp(affiche.contentSize.width/2, affiche.contentSize.height/2);
    //
    CCSprite *line = [CCSprite spriteWithFile:@"images/ui/alert/line.png"];
    if (line) {
        line = getSpriteWithSpriteAndNewSize(line, CGSizeMake(affiche.contentSize.width, line.contentSize.height));
        [affiche addChild:line];
        line.position = ccpAdd(off_pos,ccp(0,-cFixedScale(45)));
    }
    //
    CCNode *name_ = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_map_union",nil)
                            dimensions:CGSizeMake(0,0)
                             alignment:kCCTextAlignmentLeft
                              fontName:@"Verdana-Bold"
                              fontSize:22
                          shadowOffset:CGSizeMake(-0.5, -0.5)
                            shadowBlur:1.0f
                           shadowColor:ccc4(160,100,20, 128)
                             fillColor:ccc4(255, 255, 255, 255)];
    [affiche addChild:name_];
    name_.position = ccpAdd(off_pos,ccp(0,affiche.contentSize.height/2-cFixedScale(40)));
    
    //
    NSString *text_p_str = nil;
    if (unionName) {
        text_p_str = [NSString stringWithFormat:NSLocalizedString(@"dragon_map_player",nil), unionName];
    }else{
        text_p_str =[NSString stringWithFormat:NSLocalizedString(@"dragon_map_player",nil), @""];
    }
//    CCNode *text_p = [CCLabelFX labelWithString:text_p_str
//                                        dimensions:CGSizeMake(0,0)
//                                         alignment:kCCTextAlignmentLeft
//                                          fontName:@"Verdana-Bold"
//                                          fontSize:18
//                                      shadowOffset:CGSizeMake(-0.5, -0.5)
//                                        shadowBlur:1.0f
//                                       shadowColor:ccc4(160,100,20, 128)
//                                         fillColor:ccc4(125, 125, 125, 255)];
    CCNode *text_p = drawString(text_p_str,CGSizeMake(450,0),getCommonFontName(FONT_1), 18,19, @"777777");
        [affiche addChild:text_p];
        text_p.anchorPoint = ccp(0.5,0);
        text_p.position = ccpAdd(off_pos,ccp(0,+cFixedScale(9)));
    //
    CCNode *text_ = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_map_text",nil)
                                    dimensions:CGSizeMake(0,0)
                                     alignment:kCCTextAlignmentLeft
                                      fontName:@"Verdana-Bold"
                                      fontSize:18
                                  shadowOffset:CGSizeMake(-0.5, -0.5)
                                    shadowBlur:1.0f
                                   shadowColor:ccc4(160,100,20, 128)
                                     fillColor:ccc4(255, 150, 50, 255)];
    [affiche addChild:text_];
    text_.anchorPoint = ccp(0.5,1);
    text_.position = ccpAdd(off_pos,ccp(0,+cFixedScale(5)));
    //
    CCSimpleButton *button_monster = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_cancel_1.png" select:@"images/ui/button/bt_cancel_2.png" invalid:@"images/ui/button/bt_cancel_3.png" target:self call:@selector(AfficheCallBack:)];
    button_monster.tag = NodeTag_button_monster;
    button_monster.position = ccpAdd(off_pos,ccp(+affiche.contentSize.width/4,-affiche.contentSize.height/2+cFixedScale(40)));
    [affiche addChild:button_monster];
    //
    CCSimpleButton *button_player = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_ok_1.png" select:@"images/ui/button/bt_ok_2.png" invalid:@"images/ui/button/bt_ok_3.png" target:self call:@selector(AfficheCallBack:)];
    button_player.tag = NodeTag_button_player;
    button_player.position = ccpAdd(off_pos,ccp(-affiche.contentSize.width/4,-affiche.contentSize.height/2+cFixedScale(40)));
    [affiche addChild:button_player];
 
}
-(void)AfficheCallBack:(CCNode*)sender{
    CCLOG(@"affiche call back");
    if (NodeTag_button_monster == sender.tag) {
        NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
        [dict_ setValue:[NSNumber numberWithInt:nodeID] forKey:@"node"];
        [dict_ setValue:[NSNumber numberWithInt:NodeType_monster] forKey:@"type"];
        [GameConnection request:@"awarWorldChoose" data:dict_ target:nil call:nil];
        [self setNodeState:NodeState_flash];
        CCLOG(@"------sender fight monster.....");
    }else if (NodeTag_button_player == sender.tag) {
        NSMutableDictionary *dict_ = [NSMutableDictionary dictionary];
        [dict_ setValue:[NSNumber numberWithInt:nodeID] forKey:@"node"];
        [dict_ setValue:[NSNumber numberWithInt:NodeType_player] forKey:@"type"];
        [GameConnection request:@"awarWorldChoose" data:dict_ target:nil call:nil];
        [self setNodeState:NodeState_flash];
        CCLOG(@"------sender fight player.....");
    }
    //
    [self.parent removeChildByTag:NodeTag_affiche cleanup:YES];
}
-(void)drowLowLine{
    //TODO
    nodeLineType = NodeLinType_low;
    CCLOG(@"...id:%d drow low line",nodeID);
}

-(void)drowLightLine{
    //TODO
    nodeLineType = NodeLinType_light;
    CCLOG(@"...id:%d drow light line",nodeID);
}

-(void)drowBrokenLine{
    //TODO
    nodeLineType = NodeLinType_broken;
    CCLOG(@"...id:%d drow light line",nodeID);
}

-(void)removeFont:(DragonWorldMapNode*)node{
    //
    [frontMutArray removeObject:node];
}
-(void)removeNext:(DragonWorldMapNode*)node{
    //
    [nextMutArray removeObject:node];
}
-(void)removeAllFont{
    [frontMutArray removeAllObjects];
}
-(void)removeAllNext{
    [nextMutArray removeAllObjects];
}
-(void)addNodeFont:(DragonWorldMapNode*)node{
    if (node) {
        BOOL isMyFont = NO;
        for (DragonWorldMapNode *n in frontMutArray) {
            if (n == node) {
                isMyFont = YES;
                break;
            }
        }
        if (NO == isMyFont) {
            //[node addNodeNext:self];
            [frontMutArray addObject:node];
            [frontMutArray sortUsingFunction:sortByMapNode context:nil];
        }
    }
}
-(void)addNodeNext:(DragonWorldMapNode*)node{
    if (node) {
        BOOL isMyNext = NO;
        for (DragonWorldMapNode *n in nextMutArray) {
            if (n == node) {
                isMyNext = YES;
                break;
            }
        }
        if (NO == isMyNext) {
            //[node addNodeFont:self];
            [nextMutArray addObject:node];
            //
            [nextMutArray sortUsingFunction:sortByMapNode context:nil];
        }
    }
}
-(NSArray*)getNodeFront{
    return frontMutArray;
}
-(NSArray*)getNodeNext{
    return nextMutArray;
}
@end

#pragma mark -
#pragma mark dragon world map
//
static id s_dragonWorldMapSender = nil;
//
@implementation DragonWorldMap
enum{
  DragonWorldMapTag_time=3,
}DragonWorldMapTag;
//
+(void)showMapWithSender:(id)sender{
    [s_dragonWorldMapSender release];
    s_dragonWorldMapSender = sender;
    [s_dragonWorldMapSender retain];
    //
    if ( -1 == [[Window shared] showWindow:PANEL_UNION_Dragon_World_Map] ) {
        [s_dragonWorldMapSender release];
        s_dragonWorldMapSender = nil;
    }
}
+(void)removeMap{
    [[Window shared] removeWindow:PANEL_UNION_Dragon_World_Map];
}
-(NSString*)getBackgroundPath{
	return @"images/ui/panel/p44.jpg";
}

-(NSString*)getCaptionPath{
	return @"images/ui/panel/t83.png";
}
-(CGPoint)getCaptionPosition{
	if (iPhoneRuningOnGame()) {
		return ccp(self.contentSize.width/2,
                   self.contentSize.height-48);
	}else{
		return  ccp(self.contentSize.width/2,
                    self.contentSize.height-cFixedScale(40));
	}
}
-(id)init{
    if ((self = [super init])!=nil) {
        nodeMap = [DragonWorldMapNode node];
        [nodeMap retain];
        NSDictionary *globalConfig = [[GameDB shared] getGlobalConfig];
		mapMaxTime = [[globalConfig objectForKey:@"awarWorldChooseTime"] intValue];
        isChange = NO;
    }
    return self;
}
-(void)dealloc{
    if (nodeMap) {
        [self removeAllMapNode:nodeMap];
        [nodeMap release];
        nodeMap = NULL;
    }
    if (s_dragonWorldMapSender) {
        [s_dragonWorldMapSender release];
        s_dragonWorldMapSender = nil;
    }
    //
    [super dealloc];
}
-(void)onEnter{
	[super onEnter];
    //
    [_closeBnt removeFromParentAndCleanup:YES];
    _closeBnt = nil;
    //
    mapTime = [[NSDate date] timeIntervalSince1970];
    //
    [GameConnection addPost:ConnPost_Dragon_local_warChoose target:[DragonWorldMap class] call:@selector(onWarChoose:)];
    //
    mapViewer = [CCNode node];
    CGSize size = [[CCDirector sharedDirector] winSize];
    int w_ = size.width;
    int h_ = size.height - cFixedScale(80);
    if (iPhoneRuningOnGame()) {
        w_ *= 2;
        h_ *= 2;
    }
    mapViewer.contentSize = CGSizeMake(w_, h_);
    [self addChild:mapViewer];
    if (iPhoneRuningOnGame()) {
        mapViewer.position = ccp(self.contentSize.width/2-mapViewer.contentSize.width/4,self.contentSize.height/2-mapViewer.contentSize.height/4-cFixedScale(20));
    }else{
        mapViewer.position = ccp(self.contentSize.width/2-mapViewer.contentSize.width/2,self.contentSize.height/2-mapViewer.contentSize.height/2-cFixedScale(20));
    }
    //
    [self loadNodeMap];
    [self drawMap];
    [self drawMapLine];
    [self changeNodeMap:s_dragonWorldMapSender];
    //
    int time_ = mapMaxTime;
    NSString *timeNameStr = [NSString stringWithFormat:NSLocalizedString(@"dragon_map_time",nil),time_];
    CCLabelFX *name_time = [CCLabelFX labelWithString:timeNameStr
                            dimensions:CGSizeMake(0,0)
                             alignment:kCCTextAlignmentLeft
                              fontName:@"Verdana-Bold"
                              fontSize:20
                          shadowOffset:CGSizeMake(-0.5, -0.5)
                            shadowBlur:1.0f
                           shadowColor:ccc4(160,100,20, 128)
                             fillColor:ccc4(0, 255, 0, 255)];
    [self addChild:name_time z:3 tag:DragonWorldMapTag_time];
    name_time.anchorPoint = ccp(0,0);
    name_time.position = ccp(mapViewer.position.x + cFixedScale(80),self.contentSize.height/2 + size.height/2 - cFixedScale(130));
    //
    [self schedule:@selector(update:) interval:1/60.0f];
}

-(void)onExit{
	[super onExit];
    [GameConnection removePostTarget:self];
}

-(void)update:(ccTime)delta{
     NSTimeInterval t_time = [[NSDate date] timeIntervalSince1970] - mapTime;
    //
    if ( t_time >= mapMaxTime ) {
        isChange = NO;
    }
    //TODO
    CCLabelFX *name_time = (CCLabelFX *)[self getChildByTag:DragonWorldMapTag_time];
    if (name_time) {
        int time_ = mapMaxTime-t_time;
        if (time_<0) {
            time_ = 0;
        }
         NSString *timeNameStr = [NSString stringWithFormat:@"倒计时:%d",time_];
        [name_time setString:timeNameStr];
        if ( time_<= mapMaxTime/3 ) {
            [name_time setFillColor:ccc4(255, 0, 0, 255)];
        }else if(time_<= mapMaxTime*2/3){
            [name_time setFillColor:ccc4(255, 255, 0, 255)];
        }
    }
}

+(void)onWarChoose:(NSNotification*)notification{
    CCLOG(@"-------on war choose...");
    NSDictionary * dict = notification.object;
	if (dict) {
		int node_id = [[dict objectForKey:@"node"] intValue];
        DragonWorldMap *worldMap = (DragonWorldMap *)[[Window shared] getChildByTag:PANEL_UNION_Dragon_World_Map];
        if (worldMap) {
            DragonWorldMapNode *node_ = [worldMap getNodeWithID:node_id];
            if (node_) {
                NSArray *nextArray = [node_ getNodeNext];
                for (DragonWorldMapNode *next_n in nextArray) {
                    NSArray *frontArray_ = [next_n getNodeFront];
                    for (DragonWorldMapNode *front_n in frontArray_) {
                        [front_n setNodeState:NodeState_can_select];
                    }
                }
                //
                [node_ setNodeState:NodeState_flash];
                CCLOG(@"----- node ID:%d  flash......",node_.nodeID);
            }else{
                CCLOG(@"on war choose is error....");
            }
        }
	}
}

-(DragonWorldMapNode*)findMapNode:(DragonWorldMapNode*)node nodeID:(int)nodeID_{
    DragonWorldMapNode *node_ = nil;
    if (node) {
        if ([node nodeID] == nodeID_) {
            return node;
        }
        NSArray *nodeNextArray = [node getNodeNext];
        if (nodeNextArray && [nodeNextArray count]>0) {
            for (DragonWorldMapNode *n in nodeNextArray) {
                node_ = [self findMapNode:n nodeID:nodeID_];
                if (node_) {
                    return node_;
                }
            }
        }
    }
    return node_;
}
-(void)addMapNode:(DragonWorldMapNode*)node{
    if (node) {
        if (nodeMap) {
            [nodeMap addNodeNext:node];
        }
    }
}
-(BOOL)removeMapNodeWithID:(int)nodeID_{
    if (nodeMap) {
        DragonWorldMapNode *node_ = [self findMapNode:nodeMap nodeID:nodeID_];
        if (node_) {
           return [self removeMapNode:node_];
        }
    }
    return NO;
}
-(BOOL)removeMapNode:(DragonWorldMapNode*)node{
    if (node) {
        //
        NSArray *nodeFrontArray = [node getNodeFront];
        NSArray *nodeNextArray = [node getNodeNext];
        //
        if (nodeNextArray && [nodeNextArray count] <= 0 && [nodeFrontArray count]>0) {
            for (DragonWorldMapNode *n in nodeFrontArray) {
                [n removeNext:node];
            }
            [node removeAllFont];
            return YES;
        }
    }
    return NO;
}
-(void)removeAllMapNode:(DragonWorldMapNode*)node{
    if (node) {
        //
        int deep = 0;
        CCNode *saveDeep = [CCNode node];
        [saveDeep retain];
        saveDeep.tag = deep;
        [self getNodeDeep:node deep:deep saveDeep:saveDeep];
        deep = saveDeep.tag;
        [saveDeep release];
        //
        for (int i=deep; i>=0; i--) {
            NSMutableArray *saveArray = [NSMutableArray array];
            [saveArray retain];
            [self getDeepNode:node deep:0 endDeep:i saveArray:saveArray];
            NSArray *r_array = [NSArray arrayWithArray:saveArray];
            [saveArray release];
            //
            for (DragonWorldMapNode *n in r_array) {
                [self removeMapNode:n];
            }
        }
    }
}
-(void)loadNodeMapWithDict:(NSDictionary*)dict dictArray:(NSMutableArray*)mutArray{
    int node_id = [[dict objectForKey:@"id"] intValue];
    if (node_id != 0) {
        DragonWorldMapNode *have_node = [self findMapNode:nodeMap nodeID:node_id];
        if (have_node) {
            return;
        }
        //
        NSString *nextIDStr = [dict objectForKey:@"smids"];
        NSArray *strArray = [nextIDStr componentsSeparatedByString:@"|"];
        if (![nextIDStr isEqual:@""]) {
            if (strArray) {
                if ([strArray count]>0) {
                    for (NSString *str_ in strArray) {
                        for (NSDictionary *dict_ in mutArray) {
                            if ([str_ intValue] == [[dict_ objectForKey:@"id"] intValue]) {
                                [self loadNodeMapWithDict:dict_ dictArray:mutArray];
                            }
                        }
                    }
                }
            }
        }else{
            int node_id = [[dict objectForKey:@"id"] intValue];
            if (node_id != 0) {
                DragonWorldMapNode *node_ = [self findMapNode:nodeMap nodeID:node_id];
                if (NULL == node_) {
                    node_ = [DragonWorldMapNode node];
                    node_.nodeID = node_id;
                    node_.nodeAPCID = [[dict objectForKey:@"apcid"] intValue];
                    node_.nodeName = [dict objectForKey:@"name"];
                    //TODO
                    
                    //
                    [nodeMap addNodeNext:node_];
                    [node_ addNodeFont:nodeMap];
                    return;
                }
            }
        }
        //
        if (![nextIDStr isEqual:@""]) {
            if (strArray) {
                if ([strArray count]>0) {
                    DragonWorldMapNode *node_ = [DragonWorldMapNode node];
                    node_.nodeID = node_id;
                    node_.nodeAPCID = [[dict objectForKey:@"apcid"] intValue];
                    node_.nodeName = [dict objectForKey:@"name"];
                    //TODO
                    //
                    for (NSString *str_ in strArray) {
                        int id_ = [str_ intValue];
                        if (id_ != 0) {
                            DragonWorldMapNode *t_node = [self findMapNode:nodeMap nodeID:id_];
                            if (t_node) {
                                [t_node addNodeNext:node_];
                                [node_ addNodeFont:t_node];
                            }else{
                                CCLOG(@"---------data error........");
                            }
                        }
                    }
                }
            }
        }
        //
    }
}

-(void)loadNodeMap{
    if (nodeMap) {
        [self removeAllMapNode:nodeMap];
        //TODO
        NSDictionary *dict = [[GameDB shared] getAwarStrongMap];
        if (dict) {
            NSMutableArray *all = [NSMutableArray arrayWithArray:[dict allValues]];
            for (NSDictionary *dict_ in all) {
                DragonWorldMapNode *node_ = [self findMapNode:nodeMap nodeID:[[dict_ objectForKey:@"id"] intValue]];
                if (node_ == NULL) {
                    [self loadNodeMapWithDict:dict_ dictArray:all];
                }
            }
        }
    }
}
-(void)changeNodeMap:(id)sender{
    if (nil == sender) {
        CCLOG(@"获取数据不成功");
        [self closeWindow];
        return;
    }
    //TODO
    isChange = [DragonFightData checkIsCaptain];
    NSDictionary *dict = sender;
    NSDictionary *namesDict = [dict objectForKey:@"names"];
    int now_node_id = [[dict objectForKey:@"node"] intValue];
    NSArray *nodeArray =[dict objectForKey:@"hnodes"];
    NSMutableArray *nodeMutArray = [NSMutableArray array];
    //
    DragonWorldMapNode *now_node = [self getNodeWithID:now_node_id];
    if (now_node) {
        [now_node drowBrokenLine];
        [now_node setNodeState:NodeState_select];
        //
        NSArray *now_front_array = [now_node getNodeFront];
        for (DragonWorldMapNode *n in now_front_array) {
            [n setIsChange:isChange];
            [n setNodeState:NodeState_can_select];
        }
    }
    //
    if (namesDict) {
        NSArray *keys = [namesDict allKeys];
        for (NSString  *key in keys) {
            int node_id = [key intValue];
            DragonWorldMapNode *node = [self getNodeWithID:node_id];
            if (node) {
                //[node setNodeName:[namesDict objectForKey:key]];
                [node setUnionName:[namesDict objectForKey:key]];
                [node setNodeType:NodeType_player];
            }
        }
    }
    //
    if (nodeArray && [nodeArray count]>0) {
        [nodeMutArray addObjectsFromArray:nodeArray];
        [nodeMutArray sortUsingSelector:@selector(compare:)];
        for (int i=0;i<([nodeMutArray count]-1);i++) {
            NSNumber *number = [nodeMutArray objectAtIndex:i];
            NSNumber *next_number = [nodeMutArray objectAtIndex:i+1];
            DragonWorldMapNode *h_node = [self getNodeWithID:[number intValue]];
            if (h_node) {
                [h_node drowLightLine];
                [h_node setPathNodeID:[next_number intValue]];
                [h_node setNodeState:NodeState_select];
            }
        }
        NSArray *leaf_array = [self getLeafNode];
        for (DragonWorldMapNode *l_node in leaf_array) {
            NSArray *l_front_array = [l_node getNodeFront];
            for (DragonWorldMapNode *l_f_node in l_front_array) {
                if ([l_f_node nodeID] == [[nodeMutArray objectAtIndex:0] intValue]) {
                    [l_node drowLightLine];
                    [l_node setNodeState:NodeState_select];
                    [l_node setPathNodeID:[[nodeMutArray objectAtIndex:0] intValue]];
                }
            }
        }
    }
    
}
//
-(DragonWorldMapNode*)getNodeWithID:(int)nodeID_{
    return [self findMapNode:nodeMap nodeID:nodeID_];
}
-(NSArray*)getLeafNode{
    NSMutableArray *array_ = [NSMutableArray array];
    [array_ retain];
    [self getLeafNodeWithNode:nodeMap saveArray:array_];
    NSArray *r_array = [NSArray arrayWithArray:array_];
    [array_ release];
    return r_array;
}

-(void)drawMap{
    //
    [mapViewer removeAllChildrenWithCleanup:YES];
    //
    CGPoint pos = CGPointZero;
    int map_deep = [self getDeep];
    if (map_deep<0) {
        map_deep = 1;
    }
    int map_node_w = mapViewer.contentSize.width;
    int map_node_h = mapViewer.contentSize.height;
    int map_node_step_h = 0;
    int deep_ = [self getDeep];
    if (deep_>0) {
       map_node_step_h = map_node_h/(deep_);  
    }
    pos.x = cFixedScale(map_node_w/2);
    //
    for (int i=1; i<=map_deep; i++) {
        NSArray *node_array = [self getNodeWithDeep:i];
        int w_ = cFixedScale(map_node_w/([node_array count]+1));
        //
        pos.x = w_;
        pos.y =  cFixedScale(map_node_h - map_node_step_h*(i-1) - map_node_step_h/2);
        //
        for (DragonWorldMapNode *n in node_array) {
            if (i==1) {
                [n setNodeFaceType:NodeFaceType_root];
            }else if(i==map_deep){
                [n setNodeFaceType:NodeFaceType_leaf];
            }else{
                [n setNodeFaceType:NodeFaceType_middle];
            }
            n.pos = pos;
            [self drawNode:n];
            pos.x += w_;
        }
    }
}
-(void)drawMapLine{
    int map_deep = [self getDeep];
    if (map_deep<0) {
        map_deep = 1;
    }
    //
    for (int i=2; i<=map_deep; i++) {
        NSArray *node_array = [self getNodeWithDeep:i];
        //
        for (DragonWorldMapNode *n in node_array) {
            [n drowLowLine];
        }
    }

}
-(void)drawNode:(DragonWorldMapNode*)node{
    //
    if (node) {
        node.position = node.pos;
        [mapViewer addChild:node];
    }
}
-(void)getLeafNodeWithNode:(DragonWorldMapNode*)node saveArray:(NSMutableArray*)saveArray{
    //
    if (node) {
        NSArray *nodeNextArray = [node getNodeNext];
        if (nodeNextArray) {
            if (nodeNextArray && [nodeNextArray count] <= 0) {
                BOOL isSave = NO;
                for (DragonWorldMapNode *n in saveArray) {
                    if(n == node && [n nodeID] == [node nodeID] ){
                        isSave = YES;
                    }
                
                }
                if (NO == isSave) {
                    [saveArray addObject:node];
                }
            }else{
                for (DragonWorldMapNode *n in nodeNextArray) {
                    [self getLeafNodeWithNode:n saveArray:saveArray];
                }
                
            }
        }
    }
}
-(void)getNodeDeep:(DragonWorldMapNode*)node deep:(int)deep saveDeep:(CCNode*)saveDeep{
    if (node) {
        NSArray *nodeNextArray = [node getNodeNext];
        if( nodeNextArray && [nodeNextArray count] > 0 ){
            deep++;
            if (deep>saveDeep.tag) {
                saveDeep.tag = deep;
            }
            for (DragonWorldMapNode *n in nodeNextArray) {
                [self getNodeDeep:n deep:deep saveDeep:saveDeep];
            }
        }
    }
}
-(int)getDeep{
    int deep = 0;
    CCNode *saveDeep = [CCNode node];
    [saveDeep retain];
    saveDeep.tag = deep;
    [self getNodeDeep:nodeMap deep:deep saveDeep:saveDeep];
    deep = saveDeep.tag;
    [saveDeep release];
    return deep;
}
-(void)getDeepNode:(DragonWorldMapNode*)node deep:(int)deep endDeep:(int)endDeep saveArray:(NSMutableArray*)saveArray{
    if (node) {
        if (deep == endDeep) {
            BOOL isSave = NO;
            for (DragonWorldMapNode *n in saveArray) {
                if (n == node && n.nodeID == node.nodeID) {
                    isSave = YES;
                    break;
                }
            }
            if (NO == isSave) {
                [saveArray addObject:node];
            }
        }
        NSArray *nodeNextArray = [node getNodeNext];
        if( nodeNextArray && [nodeNextArray count] > 0 ){
            deep++;
            for (DragonWorldMapNode *n in nodeNextArray) {
                [self getDeepNode:n deep:deep endDeep:endDeep saveArray:saveArray];
            }
        }
    }
}
-(NSArray*)getNodeWithDeep:(int)deep{
    NSMutableArray *saveArray = [NSMutableArray array];
    [saveArray retain];
    [self getDeepNode:nodeMap deep:0 endDeep:deep saveArray:saveArray];
    NSArray *r_array = [NSArray arrayWithArray:saveArray];
    [saveArray release];
    return r_array;
}
-(BOOL)isChange{
    return isChange;
}
-(void)setIsChange:(BOOL)isChange_{
    isChange = isChange_;
}
@end
