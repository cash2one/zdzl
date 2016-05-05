//
//  SectionManager.m
//  TXSFGame
//
//  Created by Soul on 13-7-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "SectionManager.h"
#import "GameConfigure.h"
#import "StretchingImg.h"
#import "GameDB.h"
#import "CCNode+AddHelper.h"
#import "CFPage.h"
#import "Config.h"
#import "RoleUp.h"
#import "ClickAnimation.h"

@implementation SectionQueue

-(id)init{
	if ((self = [super init]) != nil) {
		self.contentSize = CGSizeMake(0, 0);
		self.anchorPoint = ccp(0, 0.5);
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(void)insert:(Section *)section{
	CGPoint gap = ccp(section.contentSize.width,0);
	CCNode * _iterator = nil;
	CCARRAY_FOREACH(_children, _iterator) {
		CGPoint pt = _iterator.position;
		_iterator.position = ccpAdd(pt, gap);
	}
	//section.anchorPoint = CGPointZero;
	//section.position = CGPointZero;
    section.position = ccp(+section.contentSize.width/2,section.contentSize.height/2);
	[self addChild:section z:0];
	[self updateContentSize];
}
-(void)insert:(Section *)section index:(int)index{
    //section.anchorPoint = CGPointZero;
	section.position = ccp(section.contentSize.width*index+section.contentSize.width/2, section.contentSize.height/2);
	[self addChild:section z:0];
	//[self updateContentSize];
}
-(void)push:(Section *)section{
	//section.anchorPoint = CGPointZero;
	section.position = ccp(self.contentSize.width+section.contentSize.width/2, section.contentSize.height/2);
	[self addChild:section z:0];
	[self updateContentSize];
}


-(void)updateContentSize{
	CCNode * _iterator = nil;
	float pointX = 0 ;
	float pointY = 0 ;
	CCARRAY_FOREACH(_children, _iterator) {
		if (_iterator.contentSize.height > pointY) {
			pointY = _iterator.contentSize.height ;
		}
		pointX += _iterator.contentSize.width ;
	}
	self.contentSize = CGSizeMake(pointX, pointY);
}

@end

@implementation SectionQueueRect

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(void)visit{
    float off_w = 20;
	CGPoint pt = [self.parent convertToWorldSpace:self.position];
	int clipX = pt.x - cFixedScale(off_w/2);
	int clipY = pt.y;
	int clipW = self.contentSize.width + cFixedScale(off_w);
	int clipH = self.contentSize.height;
	float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
	glScissor(clipX*zoom, clipY*zoom, clipW*zoom, clipH*zoom);
    glEnable(GL_SCISSOR_TEST);
    [super visit];
    glDisable(GL_SCISSOR_TEST);
}

@end

#pragma mark -
#pragma mark Section
@implementation Section
@synthesize selfManager;
@synthesize roleUpLevel;

+(Section*)create:(CGSize)_size{
	Section* obj = [Section node];
	[obj initWithTargetSize:_size];
	return obj;
}

-(void)initWithTargetSize:(CGSize)_size{
	CCSprite* ring_bg = [CCSprite spriteWithFile:@"images/ui/role_up/ring_bg.png"];
    CCSprite* ring = [CCSprite spriteWithFile:@"images/ui/role_up/ring.png"];
	[self setContentSize:_size];
    [self Category_AddChildToCenter:ring_bg z:0];
	[self Category_AddChildToCenter:ring z:5];
	
	radius = ring.contentSize.width/2;
	radius_half = radius/2;
	
	center = ccp(self.contentSize.width/2, self.contentSize.height/2);
    //
    roleUpLevel = 0;
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:NO];
}

-(int)getFrame:(CGPoint)pt{
	float dis = ccpDistance(pt, center);
	if (dis < radius_half || dis > radius) {
		return 0 ;
	}
	float angle = getAngle(center, pt);
	for (int start = 405 ,index = 1	; start >= 90; start -= 45 , index += 1) {
		int tempAngel = start%360;
		if (angle > tempAngel && angle < tempAngel + 45) {
			return index;
		}
	}
	return 0;
}

-(void)showSction:(NSDictionary *)dict{
	if (dict == nil) return ;
}

-(void)showFrameTo:(int)frame{
	//已经更新到第几个格
	for (int i = 1; i <= frame; i++) {
		[self showFrame:i];
	}
    for (int i=frame+1; i<=8; i++) {
        CCSprite* frameSpr = (CCSprite*)[self getChildByTag:300+i];
        if (frameSpr) {
            frameSpr.visible = NO;
        }
    }
}

-(CGPoint)getAnchorWith:(int)frame{
	float ptx = 0 ;
	float pty = 0 ;
	if (frame > 4) {
		ptx = 1 ;
	}
	if (frame > 2 && frame < 7) {
		pty = 1 ;
	}
	return ccp(ptx, pty);
}
-(void)endShowAction:(id)sender{
//    CCNode *node_ = sender;
//    node_.visible = YES;
    //
    SectionManager *selfManager_ = selfManager;
    [selfManager_ setIsShowFrameEffect:NO];
}
-(BOOL)checkCanShowEffectWithIndex:(int)index{
    SectionManager *selfManager_ = selfManager;
    if ([selfManager_ roleLevel] == roleUpLevel && [selfManager_ roleStep]==index) {
        return YES;
    }
    return NO;
}
-(void)showActionWithSprite:(CCSprite*)sprite index:(int)index{
    if (sprite && index>0 && index<=8 && [self checkCanShowEffectWithIndex:index]) {
//        sprite.visible = NO;
        
        id call = [CCCallFuncO actionWithTarget:self selector:@selector(endShowAction:) object:sprite];
        CGPoint pos=ccpAdd(ccp(0,0), ccp(self.contentSize.width/2, self.contentSize.height/2));
        ClickAnimation *click_ = [ClickAnimation showInLayer:self tag:555 call:call point:pos path:@"images/ui/role_up/effect/" loop:NO];
        [click_ setAnchorPoint:ccp(0, 0)];
        [click_ setRotation:(index-1)*360/8];
    }
}
-(void)showFrame:(int)frame{
	if (frame <= 0 || frame > 8) return ;
	
	CCSprite* frameSpr = (CCSprite*)[self getChildByTag:300+frame];
    if (frameSpr) {
        [frameSpr removeFromParentAndCleanup:YES];
        frameSpr = nil;
    }
    SectionManager* temp = (SectionManager*)selfManager;
    int value = [temp selectQuality];
    NSString* path = [NSString stringWithFormat:@"images/ui/role_up/c%d%d.png",value,frame];
    frameSpr = [CCSprite spriteWithFile:path];
    frameSpr.anchorPoint = [self getAnchorWith:frame];
    frameSpr.position = center;
    [self addChild:frameSpr z:2 tag:300+frame];
    /*
    if (!frameSpr) {
		SectionManager* temp = (SectionManager*)selfManager;
		int value = [temp selectQuality];
        NSString* path = [NSString stringWithFormat:@"images/ui/role_up/c%d%d.png",value,frame];
        frameSpr = [CCSprite spriteWithFile:path];
		frameSpr.anchorPoint = [self getAnchorWith:frame];
		frameSpr.position = center;
		[self addChild:frameSpr z:2 tag:300+frame];
    }else{
        frameSpr.visible = YES;
    }
     */
	//
    SectionManager *selfManager_ = selfManager;
    if ([selfManager_ isShowFrameEffect]) {
        [self showActionWithSprite:frameSpr index:frame];
    }
}
-(void)showFrameText:(int)frame{
    if (frame <= 0 || frame > 8) return ;
	//TODO show text
    int t_role_id = 0;
    int t_quality = 0;
    int t_level = 0;
    int t_step = 0;
    int role_quality = 0;
    int role_Level = 0;
    int role_step = 0;
    //
    SectionManager *sectionManager_  = selfManager;
    t_role_id = [sectionManager_ roleId];
    t_quality = [sectionManager_ selectQuality];
    t_level = [sectionManager_ pageIndex]+1;
    t_step = frame;
    //
    role_quality = [sectionManager_ roleQuality];
    role_Level = [sectionManager_ roleLevel];
    role_step = [sectionManager_ roleStep];
    if (self.visible) {
        if (t_quality >= role_quality &&
            t_level >= role_Level &&
            t_step > role_step) {
            [ShowItem showItemAct:NSLocalizedString(@"role_up_no_open",nil)];
        }else{
            [RoleUp loadStepDisplayWithRid:t_role_id quality:t_quality roleUpLevel:t_level step:t_step];
        }
    }
    //
    //[RoleUp loadStepDisplayWithRid:t_role_id quality:t_quality roleUpLevel:t_level step:t_step];
}
-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}
-(BOOL)checkTouchInShowLayer:(UITouch *)touch{
    CGPoint t_pos = [touch locationInView: [touch view]];
	t_pos = [[CCDirector sharedDirector] convertToGL: t_pos];
	t_pos = [self.parent.parent convertToNodeSpace: t_pos];
    CGSize size_ = self.parent.parent.contentSize;
    if(t_pos.x>0 && t_pos.y>0 && t_pos.x<size_.width && t_pos.y<size_.height){
        return YES;
    }
    return NO;
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    isMove = NO;
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	if ([self isTouchInSite:touch]) {
//		int f = [self getFrame:touchLocation];
//        [self showFrameText:f];
        startMovePos = touchLocation;
		return YES;
	}
	return NO ;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"moveing");
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    //TODO
    if ( (abs(startMovePos.x-touchLocation.x) + abs(startMovePos.y-touchLocation.y)) >  cFixedScale(5) ) {
        isMove = YES;
    }	
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	if ([self isTouchInSite:touch] && isMove == NO && [self checkTouchInShowLayer:touch]) {
		int f = [self getFrame:touchLocation];
		//[self showFrame:f];
        [self showFrameText:f];
        CCLOG(@"showFrameText:::");
	}
    isMove = NO;
}


@end

#pragma mark -
#pragma mark SectionManager
@implementation SectionManager

enum{
    SectionManager_page_tag = 1101,
    SectionManager_menu_tag = 102,
    SectionManager_button_tag,
    //SectionManager_content_tag = 1101,
};
@dynamic dictInfo;
@synthesize isShowFrameEffect;

-(id)init{
    if ((self = [super init])!=nil) {
        _roleId = 0;
        _roleUpStartQuality = 0;
        _roleUpQuality = 0;
        _roleupSelectQuality = 0;
        _roleUpLevel = 0;
        _roleUpStep = 0;
        isUpdateState = NO;
        dictInfo = nil;
    }
    return self;
}

-(void)onEnter{
	[super onEnter];
    //self.contentSize = CGSizeMake(cFixedScale(SECTION_WIDTH), cFixedScale(SECTION_WIDTH));
	
	CCSprite* sprite = [CCSprite spriteWithFile:@"images/ui/role_up/section.png"];
	[self setContentSize:sprite.contentSize];
	[self Category_AddChildToCenter:sprite z:0];
	
	CCSprite* cloud1 = [CCSprite spriteWithFile:@"images/ui/role_up/cloud.png"];
	[self addChild:cloud1 z:0];
	cloud1.anchorPoint = ccp(1.0, 0.5);
	cloud1.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	//
    CCSprite* cloud_f1 = [CCSprite spriteWithFile:@"images/ui/role_up/cloud_front.png"];
	[self addChild:cloud_f1 z:13];
	cloud_f1.anchorPoint = ccp(1.0, 0.5);
	cloud_f1.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
    
	CCSprite* cloud2 = [CCSprite spriteWithFile:@"images/ui/role_up/cloud.png"];
	[cloud2 setFlipX:YES];
	[self addChild:cloud2 z:0];
	cloud2.anchorPoint = ccp(0, 0.5);
	cloud2.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
    //
    CCSprite* cloud_f2 = [CCSprite spriteWithFile:@"images/ui/role_up/cloud_front.png"];
    [cloud_f2 setFlipX:YES];
	[self addChild:cloud_f2 z:13];
	cloud_f2.anchorPoint = ccp(0, 0.5);
	cloud_f2.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	//
    [self setPageCount:1];
    //
    [self loadButton];
	
	
	contentRect = [SectionQueueRect node];
	contentRect.contentSize = self.contentSize;
	[self addChild:contentRect z:10];
	
    //
    content = [SectionQueue node];
    [contentRect addChild:content z:1];
    oldPoint = ccp(0, self.contentSize.height/2);
    content.position = oldPoint;
	
    [self schedule:@selector(updateContent)];
}

-(void)onExit{
    content = nil;
	contentRect = nil ;
    if (dictInfo) {
        [dictInfo release];
        dictInfo = nil;
    }
	[super onExit];
}
-(void)showEffect{
    //
    [leftSection stopAllActions];
    [leftSection setScale:0.2f];
    [leftSection runAction:[CCScaleTo actionWithDuration:0.3 scale:1.0f]];
    //
    [middlelSection stopAllActions];
    [middlelSection setScale:0.2f];
    [middlelSection runAction:[CCScaleTo actionWithDuration:0.3 scale:1.0f]];
    //
    [rightSection stopAllActions];
    [rightSection setScale:0.2f];
    [rightSection runAction:[CCScaleTo actionWithDuration:0.3 scale:1.0f]];
}
-(void)setRoleId:(int)_value{
	if (_value <= 0 || _roleId == _value) {
		return ;
	}
    _roleId = _value ;
    isUpdateState = YES;
	//[self updateContent];
}
-(void)setPageCount:(int)count_{
    if (count_>=0) {
        //
        PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
        if (!pageBack) {
            pageBack = [PageDot node];
            [self addChild:pageBack z:13 tag:SectionManager_page_tag];
            pageBack.position = ccp(self.contentSize.width/2,- cFixedScale(30));
            [pageBack setSize:CGSizeMake(self.contentSize.width, cFixedScale(30))];
        }
        [pageBack setDotCount:count_];
    }
}
-(int)roleId{
    return _roleId;
}
-(int)pageIndex{
    PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
    if (pageBack) {
        return [pageBack index];
    }
    return 0;
}
-(int)selectQuality{
    return _roleupSelectQuality;
}
-(int)roleQuality{
    return _roleUpQuality;
}
-(int)roleLevel{
    return _roleUpLevel;
}
-(int)roleStep{
    return _roleUpStep;
}

-(void)loadButton{
	    [self removeChildByTag:SectionManager_menu_tag cleanup:YES];
	    CCMenu *menu = [CCMenu node];
	    [self addChild:menu z:15 tag:SectionManager_menu_tag];
	    menu.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	    //
	    NSArray *bt_arr = getDisableBtnSpritesArrayWithStatus(@"images/ui/button/bt_role_up");
	    if (bt_arr && [bt_arr count]>2) {
	        CCMenuItemSprite *bt_green = [CCMenuItemSprite itemWithNormalSprite:[bt_arr objectAtIndex:0] selectedSprite:[bt_arr objectAtIndex:1] disabledSprite:[bt_arr objectAtIndex:2] target:[RoleUp class] selector:@selector(buttonBack)];
	        [menu addChild:bt_green z:1 tag:SectionManager_button_tag];
	        bt_green.position = ccp(0,0);
	    }
}
-(void)setSelectQuality:(int)_value{
    if (_value != _roleupSelectQuality) {
        _roleupSelectQuality = _value ;
        isUpdateState = YES;
    }
}
-(void)loadRidData{
    NSDictionary *role_info = [[GameConfigure shared] getPlayerRoleFromListById:_roleId];
    if (role_info) {
        _roleUpStartQuality = _roleUpQuality = [[role_info objectForKey:@"q"] intValue];
        _roleUpLevel = [[role_info objectForKey:@"g"] intValue];
        _roleUpStep = [[role_info objectForKey:@"c"] intValue];
    }else{
        CCLOG(@"role up data error");
    }
    //
    NSDictionary *dict_role_info = [[GameDB shared] getRoleInfo:_roleId];
    if (dict_role_info && [dict_role_info objectForKey:@"quality"]) {
        _roleUpStartQuality = [[dict_role_info objectForKey:@"quality"] intValue];
    }else{
        CCLOG(@"role up data error");
    }
}
/*
-(void)loadDisplay{
    if (content) {
        [content removeAllChildrenWithCleanup:YES];
        content.contentSize = CGSizeMake(0, 0);
        content.position = oldPoint;
        //[self ];
        NSDictionary* dict = [[GameDB shared] getRoleupTypeInfo:_roleId];
        if (dict && [dict objectForKey:@"type"]) {
            int type_ = [[dict objectForKey:@"type"] intValue];
            NSDictionary *dict_info = [[GameDB shared] getRoleupQualityInfo:type_ quality:_roleupSelectQuality];
            if (dict_info) {
                NSArray *keys = [dict_info allKeys];
                NSMutableArray *mut_keys = [NSMutableArray arrayWithArray:keys];
				[mut_keys sortUsingSelector:@selector(compare:)];
                int i = 0;
                //
                [self setPageCount:[keys count]];
                //
                for (NSNumber *key in mut_keys) {
                    NSDictionary *level_dict = [dict_info objectForKey:key];
                    if (level_dict) {
                        Section* section = [Section create:self.contentSize];
                        [section showSction:[NSDictionary dictionary]];
						[content push:section];
                        i++;
                        //
                        if (level_dict) {
                            if (_roleupSelectQuality<_roleUpQuality) {
                                [section showFrameTo:[[level_dict allKeys] count]];
                            }else if(_roleupSelectQuality == _roleUpQuality){
                                if ([key intValue] < _roleUpLevel) {
                                    [section showFrameTo:[[level_dict allKeys] count]];
                                }else if([key intValue] == _roleUpLevel){
                                    [section showFrameTo:_roleUpStep];
                                }else{
                                    [section showFrameTo:0];
                                }
                            }else{
                                [section showFrameTo:0];
                            }
                        }
                        
                    }
                }
                //
                [self setPage:_roleUpLevel];
            }else{
                CCLOG(@"role up data error");
            }
        }else{
            CCLOG(@"role up data error");
        }
    }
	
	
}
 */
//----------------
-(void)cleanupContent{
    if (content) {
        [content removeAllChildrenWithCleanup:YES];
        content.contentSize = CGSizeMake(0, 0);
        content.position = oldPoint;
    }
    leftSection = nil;
    middlelSection = nil;
    rightSection = nil;
}
-(void)loadDictInfo{
    NSDictionary* dict = [[GameDB shared] getRoleupTypeInfo:_roleId];
    if (dict && [dict objectForKey:@"type"]) {
        int type_ = [[dict objectForKey:@"type"] intValue];
        [dictInfo release];
        dictInfo = [[GameDB shared] getRoleupQualityInfo:type_ quality:_roleupSelectQuality];
        [dictInfo retain];
    }else{
        CCLOG(@"dict data error");
    }
}
-(void)setDisplayWithLevel:(int)level{
    if (content) {
            if (dictInfo) {
                //
                if (leftSection) {
                    leftSection.roleUpLevel = level-1;
                    NSDictionary *left_dict = [dictInfo objectForKey:[NSString stringWithFormat:@"%d",(level-1)]];
                    if (left_dict) {
                        leftSection.position = ccp(self.contentSize.width*(level-2)+leftSection.contentSize.width/2,  leftSection.contentSize.height/2);
                        if (_roleupSelectQuality<_roleUpQuality) {
                            [leftSection showFrameTo:[[left_dict allKeys] count]];
                            leftSection.visible = YES;
                        }else if(_roleupSelectQuality == _roleUpQuality){
                            if ((level-1) < _roleUpLevel) {
                                [leftSection showFrameTo:[[left_dict allKeys] count]];
                                leftSection.visible = YES;
                            }else if((level-1) == _roleUpLevel){
                                [leftSection showFrameTo:_roleUpStep];
                                leftSection.visible = YES;
                            }else{
                                [leftSection showFrameTo:0];
                                leftSection.visible = NO;
                            }
                        }else{
                            [leftSection showFrameTo:0];
                            leftSection.visible = NO;
                        }
                        //leftSection.visible = YES;
                    }else{
                        leftSection.visible = NO;
                    }
                }
                //
                if (middlelSection) {
                    middlelSection.roleUpLevel = level;
                    NSDictionary *middle_dict = [dictInfo objectForKey:[NSString stringWithFormat:@"%d",(level)]];
                    if (middle_dict) {
                        middlelSection.position = ccp(self.contentSize.width*(level-1)+middlelSection.contentSize.width/2, middlelSection.contentSize.height/2);
                        if (_roleupSelectQuality<_roleUpQuality) {
                            [middlelSection showFrameTo:[[middle_dict allKeys] count]];
                            middlelSection.visible = YES;
                        }else if(_roleupSelectQuality == _roleUpQuality){
                            if (level < _roleUpLevel) {
                                [middlelSection showFrameTo:[[middle_dict allKeys] count]];
                                middlelSection.visible = YES;
                            }else if(level == _roleUpLevel){
                                [middlelSection showFrameTo:_roleUpStep];
                                middlelSection.visible = YES;
                            }else{
                                [middlelSection showFrameTo:0];
                                middlelSection.visible = NO;
                            }
                        }else{
                            [middlelSection showFrameTo:0];
                            middlelSection.visible = NO;
                        }
                        //middlelSection.visible = YES;
                    }else{
                        middlelSection.visible = NO;
                    }
                }
                //
                if (rightSection) {
                    rightSection.roleUpLevel = level+1;
                    NSDictionary *right_dict = [dictInfo objectForKey:[NSString stringWithFormat:@"%d",(level+1)]];
                    if (right_dict) {
                        rightSection.position = ccp(self.contentSize.width*(level)+rightSection.contentSize.width/2, rightSection.contentSize.height/2);
                        if (_roleupSelectQuality<_roleUpQuality) {
                            [rightSection showFrameTo:[[right_dict allKeys] count]];
                            rightSection.visible = YES;
                        }else if(_roleupSelectQuality == _roleUpQuality){
                            if ((level+1) < _roleUpLevel) {
                                [rightSection showFrameTo:[[right_dict allKeys] count]];
                                rightSection.visible = YES;
                            }else if((level+1) == _roleUpLevel){
                                [rightSection showFrameTo:_roleUpStep];
                                rightSection.visible = YES;
                            }else{
                                [rightSection showFrameTo:0];
                                rightSection.visible = NO;
                            }
                        }else{
                            [rightSection showFrameTo:0];
                            rightSection.visible = NO;
                        }
                        //rightSection.visible = YES;
                    }else{
                        rightSection.visible = NO;
                    }
                }
            }else{
                CCLOG(@"role up data error");
            }
//        }else{
//            CCLOG(@"role up data error");
//        }
        [self checkButtonState];
    }
}
-(void)loadDisplay{
    //[self cleanupContent];
    [self loadDictInfo];
    //
    if (content) {
        int updateLevel = _roleUpLevel;
        if(_roleupSelectQuality != _roleUpQuality){
            updateLevel = 1;
        }
        //
//        NSDictionary* dict = [[GameDB shared] getRoleupTypeInfo:_roleId];
//        if (dict && [dict objectForKey:@"type"]) {
//            int type_ = [[dict objectForKey:@"type"] intValue];
//            NSDictionary *dict_info = [[GameDB shared] getRoleupQualityInfo:type_ quality:_roleupSelectQuality];
            if (dictInfo) {
                NSArray *keys = [dictInfo allKeys];
                //
                content.contentSize = CGSizeMake(self.contentSize.width*[keys count], self.contentSize.height);
                //
                [self setPageCount:[keys count]];
                //
                if (!leftSection) {
                    leftSection = [Section create:self.contentSize];
                    leftSection.selfManager = self;
                    [content push:leftSection];
                }
                //
                if (!middlelSection) {
                    middlelSection  = [Section create:self.contentSize];
                    middlelSection.selfManager = self;
                    [content push:middlelSection];
                }
                //
                if (!rightSection) {
                    rightSection  = [Section create:self.contentSize];
                    rightSection.selfManager = self;
                    [content push:rightSection];
                }
                //
                [self setDisplayWithLevel:updateLevel];
                //
                 [self setPage:updateLevel];
            }else{
                CCLOG(@"role up data error");
            }
//        }else{
//            CCLOG(@"role up data error");
//        }
        //
        [self checkButtonState];
    }
}
//--------------
-(void)updateContent{
    if (isUpdateState) {
        //TODO
        [self loadRidData];
        //
        [self loadDisplay];
    }
    isUpdateState = NO;
}

-(void)setPage:(int)index{
    if (content) {
        //
        CGPoint moveToPos = content.position;
        CGSize size = self.contentSize;
        int count = 0;
        PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
        if (pageBack) {
            count = [pageBack dotCount];
        }
        if (index>0&& index<=count) {
            moveToPos.x = oldPoint.x -(index-1)*size.width;
            [content stopAllActions];
            content.position = moveToPos;
        }
        //
        if (pageBack) {
            [pageBack setIndex:index-1];
        }
    }
}
-(void)setUpdateState:(BOOL)isUpdate{
    isUpdateState = isUpdate;
}
-(void)contentMoveOff:(CGPoint)pos{
    if (content) {
        content.position = ccpAdd(content.position, pos);
        //
        int index = [self getPageIndexWithContentPos:content.position];
         PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
        if (index>=0 && index<[pageBack dotCount]) {
            BOOL isOver = NO;
            if (_roleupSelectQuality > _roleUpQuality) {
                isOver = YES;
            }else if(_roleupSelectQuality == _roleUpQuality){
                if (index>=(_roleUpLevel-1)) {
                    isOver = YES;
                }
            }
            if (isOver==NO) {
                [self setDisplayWithLevel:(index+1)];
            }
            //[self setDisplayWithLevel:(index+1)];
        }
        CCLOG(@"index::::%d",index);
    }
}

-(int)getPageIndexWithContentPos:(CGPoint)pos{
    
    //
    int index = 0;
    if (content) {
        index = -(pos.x-oldPoint.x)/self.contentSize.width;
    }
    int x_ = pos.x-(oldPoint.x+index*self.contentSize.width);
    if (x_>=0) {
        index -= 1;
    }else{
        index += 1;
    }
    if (pos.x>0) {
        index += 1;
    }
    return index;
}

-(void)checkPoint{
    if (content) {
        //
        BOOL isOver = NO;
        CGPoint pos = content.position;
        CGPoint moveToPos = content.position;
        CGSize size = self.contentSize;
        int count = 0;
        int index = 0;
        PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
        if (pageBack) {
            count = [pageBack dotCount];
        }
        if (count<=0) {
            content.position = oldPoint;
            CCLOG(@"check point count error");
        }else{
            if (pos.x > oldPoint.x ) {
                moveToPos.x = oldPoint.x;
                index = 0;
            }else if(pos.x < (oldPoint.x - (count-1)*size.width)){
                moveToPos.x = (oldPoint.x - (count-1)*size.width);
                index = (count-1);
            }else{
                index = abs((pos.x-oldPoint.x)/size.width);
                //
                if (_roleupSelectQuality > _roleUpQuality) {
                    moveToPos.x = oldPoint.x;
                    index = 0;
                    isOver = YES;
                }else if(_roleupSelectQuality == _roleUpQuality){
                    if (index>=(_roleUpLevel-1)) {
                        index = (_roleUpLevel-1);
                        moveToPos.x = (oldPoint.x - (index)*size.width);
                        isOver = YES;
                    }
                }
                //
                if (isOver==NO) {
                    int x_ = abs(pos.x-oldPoint.x)-index*size.width;
                    if (x_>=0 && x_<=size.width) {
                        if (x_>size.width/2) {
                            moveToPos.x = oldPoint.x - (index+1)*size.width;
                            index += 1;
                        }else{
                            moveToPos.x = oldPoint.x -index*size.width;
                        }
                    }else{
                        CCLOG(@"check point error");
                    }
                }
            }
        }
        
        if (pageBack) {
            if (index >= [pageBack dotCount]) {
                index = [pageBack dotCount];
            }
            if (index < 0) {
                index = 0;
            }
            [pageBack setIndex:index];
        }
        [content stopAllActions];
        CCAction* t_ac_ = [CCCallFunc actionWithTarget:self selector:@selector(checkButtonState)];
        CCAction* ac_ = [CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:moveToPos], t_ac_,nil];
        [content runAction:ac_];

        //[content runAction:[CCMoveTo actionWithDuration:0.5 position:moveToPos]];
        
    }
}
//
-(void)checkButtonState{
    BOOL isChange = NO;
    PageDot * pageBack = (PageDot * )[self getChildByTag:SectionManager_page_tag];
    
    int level = 0;
    if (pageBack) {
        level = [pageBack index] + 1;
    }
    if (_roleupSelectQuality == _roleUpQuality && level == _roleUpLevel) {
        isChange = YES;
    }
    //
    CCMenuItemSprite *bt_up = nil;
    CCMenu *menu = (CCMenu *)[self getChildByTag:SectionManager_menu_tag];
    if (menu) {
        bt_up = (CCMenuItemSprite *)[menu getChildByTag:SectionManager_button_tag];
    }
    if (bt_up) {
       [bt_up setIsEnabled:isChange];
    }

}
@end
