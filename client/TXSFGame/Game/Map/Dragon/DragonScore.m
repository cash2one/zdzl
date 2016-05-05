//
//  DragonScore.m
//  TXSFGame
//
//  Created by peak on 13-9-25.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "DragonScore.h"
#import "InfoAlert.h"
#import "GameLayer.h"
#import "DragonDefine.h"

@implementation DragonScore
enum{
    DragonScoreTag_name = 5,
     DragonScoreTag_score,
    DragonScoreTag_time,
}DragonScoreTag;
@synthesize scoreLevelStr;
//
+(void)showScoreWithSender:(id)sender{
    DragonScore *scoreNode = [DragonScore node];
    [scoreNode setSender:sender];
    //
    CCNode *layer = [GameLayer shared];
    [layer addChild:scoreNode z:INT32_MAX-10];
    scoreNode.position = ccp(layer.contentSize.width/2,layer.contentSize.height/2);
}

-(id)init{
    if ((self = [super init])!=nil) {
        scoreLevelStr = @"?";
    }
    return self;
}

-(void)onEnter{
	[super onEnter];
    scoreTime = [[NSDate date] timeIntervalSince1970];
    scoreMaxTime = 3.0;
    [self schedule:@selector(update:) interval:1/60.0f];
    //
    CCSprite *bg_ = [CCSprite spriteWithFile:@"images/ui/dragon/score_bg.png"];
    self.contentSize = bg_.contentSize;
    [self addChild:bg_];
    //
    CCSprite *name = drawBoundString(NSLocalizedString(@"dragon_score_level",nil),
                    2,
                    GAME_DEF_CHINESE_FONT,
                    26,
                    ccc3(220, 220, 200), ccc3(50, 50, 30));
    [self addChild:name];
    name.tag = DragonScoreTag_name;
    name.position = ccp(-self.contentSize.width/2 + cFixedScale(10) + name.contentSize.width/2,cFixedScale(10));
    //
    int int_time = scoreMaxTime;
    CCLabelFX *time_label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",int_time]
                                      dimensions:CGSizeMake(0,0)
                                       alignment:kCCTextAlignmentLeft
                                        fontName:@"Verdana-Bold"
                                        fontSize:20
                                    shadowOffset:CGSizeMake(-0.5, -0.5)
                                      shadowBlur:1.0f
                                     shadowColor:ccc4(160,100,20, 128)
                                       fillColor:ccc4(255, 0, 0, 255)];
    [self addChild:time_label];
    time_label.tag = DragonScoreTag_time;
    time_label.anchorPoint = ccp(1,0.5);
    time_label.position = ccp(-self.contentSize.width/2 + cFixedScale(220),-self.contentSize.height/2 + cFixedScale(30));
    //
    CCLabelFX *text_label = [CCLabelFX labelWithString:NSLocalizedString(@"dragon_score_text",nil)
                                            dimensions:CGSizeMake(0,0)
                                             alignment:kCCTextAlignmentLeft
                                              fontName:@"Verdana-Bold"
                                              fontSize:20
                                          shadowOffset:CGSizeMake(-0.5, -0.5)
                                            shadowBlur:1.0f
                                           shadowColor:ccc4(160,100,20, 128)
                                             fillColor:ccc4(255, 255, 255, 255)];
    [self addChild:text_label];
    text_label.anchorPoint = ccp(0,0.5);
    text_label.position = ccp(-self.contentSize.width/2 + cFixedScale(220),-self.contentSize.height/2 + cFixedScale(30));
    //
    [self setScoreLevelStr:scoreLevelStr];
}

-(void)onExit{
	[super onExit];
}

-(void)update:(ccTime)delta{
    NSTimeInterval t_time = [[NSDate date] timeIntervalSince1970] - scoreTime;
    //
    if ( t_time >= scoreMaxTime ) {
        [self removeFromParentAndCleanup:YES];
        //
        [GameConnection post:ConnPost_Dragon_local_box object:nil];
    }else{
        CCLabelFX *time_label = (CCLabelFX *)[self getChildByTag:DragonScoreTag_time];
        if (time_label) {
            int time_ = scoreMaxTime-t_time;
            if (time_<0) {
                time_ = 0;
            }
            [time_label setString:[NSString stringWithFormat:@"%d",time_]];
        }
    }
}

-(void)setSender:(id)sender_{
    //TODO
    if (sender_) {
        NSDictionary *dict_ = sender_;
        if ([dict_ objectForKey:@"assess"]) {
            [self setScoreLevelStr:[dict_ objectForKey:@"assess"]];
        }
    }
    //
}
-(void)setScoreLevelStr:(NSString *)scoreLevelStr_{
    if (scoreLevelStr_ && [scoreLevelStr_ length]>0) {
        scoreLevelStr = scoreLevelStr_;
    }else{
        CCLOG(@"score sender is error......");
    }
    //
    CCNode *name = (CCNode *)[self getChildByTag:DragonScoreTag_name];
    //
    if (name) {
        [self removeChildByTag:DragonScoreTag_score cleanup:YES];
        //
        if (scoreLevelStr && [scoreLevelStr isEqualToString:@"?"]) {
            CCLabelFX *text_label = [CCLabelFX labelWithString:scoreLevelStr
                                                    dimensions:CGSizeMake(0,0)
                                                     alignment:kCCTextAlignmentLeft
                                                      fontName:@"Verdana-Bold"
                                                      fontSize:40
                                                  shadowOffset:CGSizeMake(-0.5, -0.5)
                                                    shadowBlur:1.0f
                                                   shadowColor:ccc4(160,100,20, 128)
                                                     fillColor:ccc4(255, 0, 0, 255)];
            [self addChild:text_label];
            text_label.tag = DragonScoreTag_score;
            [text_label setAnchorPoint:ccp(0, 0.5)];
            [text_label setPosition:ccp(0, cFixedScale(10))];
            
        }else if (scoreLevelStr && [scoreLevelStr length]>0) {
            CCNode *node = [CCNode node];
            NSString *one_str = nil;
            CCSprite *spr_ = nil;
            NSString *path_ = nil;
            CGPoint pos_ = ccp(0, 0);
            NSString *l_scoreLevelStr = [scoreLevelStr lowercaseString];
            //
            for (int i=0; i<[l_scoreLevelStr length]; i++) {
                NSRange range;
                range.location = i;
                range.length = 1;
                one_str = [l_scoreLevelStr substringWithRange:range];
                if (one_str) {
                    path_ = [NSString stringWithFormat:@"images/ui/dragon/score_%@.png",one_str];
                    spr_ = [CCSprite spriteWithFile:path_];
                    if (spr_) {
                        [node addChild:spr_];
                        [spr_ setAnchorPoint:ccp(0, 0.5)];
                        [spr_ setPosition:pos_];
                        pos_.x += spr_.contentSize.width;
                    }else{
                        CCLOG(@".....%@ is not......",path_);
                    }
                }
            }
            //
            [self addChild:node];
            node.tag = DragonScoreTag_score;
            [node setPosition:ccp(0, cFixedScale(10))];
        }
    }
}
@end
