//
//  InfoAlert.m
//  TXSFGame
//
//  Created by efun on 13-1-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "InfoAlert.h"
#import "Arena.h"

@implementation InfoAlert

@synthesize delegate = _delegate;
@synthesize countdownLabel;

+(void)show:(id)t drawSprite:(CCSprite *)d
{
	InfoAlert *infoAlert = [[[InfoAlert alloc] initWithDelegate:t drawSprite:d parent:nil position:CGPointZero anchorPoint:CGPointZero countdown:0 site:InfoAlertSite_screenCenter] autorelease];
	[[Game shared] addChild:infoAlert z:INT32_MAX-10];
}

+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p
{
	InfoAlert *infoAlert = [[[InfoAlert alloc] initWithDelegate:t drawSprite:d parent:p position:CGPointZero anchorPoint:CGPointZero countdown:0 site:InfoAlertSite_parentCenter] autorelease];
	[[Game shared] addChild:infoAlert z:INT32_MAX-10];
}

+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos
{
	InfoAlert *infoAlert = [[[InfoAlert alloc] initWithDelegate:t drawSprite:d parent:p position:pos anchorPoint:CGPointZero countdown:0 site:InfoAlertSite_none] autorelease];
	[[Game shared] addChild:infoAlert z:INT32_MAX-10];
}

+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an
{
	InfoAlert *infoAlert = [[[InfoAlert alloc] initWithDelegate:t drawSprite:d parent:p position:pos anchorPoint:an countdown:0 site:InfoAlertSite_none] autorelease];
	[[Game shared] addChild:infoAlert z:INT32_MAX-10];
}

+(void)show:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an offset:(CGSize)o
{
	InfoAlert *infoAlert = [[[InfoAlert alloc] initWithDelegate:t drawSprite:d parent:p position:pos anchorPoint:an offset:o countdown:0 site:InfoAlertSite_none] autorelease];
	[[Game shared] addChild:infoAlert z:INT32_MAX-10];
}

-(id)initWithDelegate:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an countdown:(int)c site:(InfoAlertSite)s
{
	return [self initWithDelegate:t drawSprite:d parent:p position:pos anchorPoint:an offset:CGSizeMake(25, 20) countdown:c site:s];
}

-(id)initWithDelegate:(id)t drawSprite:(CCSprite *)d parent:(CCNode *)p position:(CGPoint)pos anchorPoint:(CGPoint)an offset:(CGSize)offset countdown:(int)c site:(InfoAlertSite)s
{
	if (self = [super init]) {
		self.delegate = t;
		parent = p;
		position = pos;
		anchorPoint = an;
		countdown = c;
		site = s;
		
		if (d) {
			self.contentSize = CGSizeMake(offset.width*2+d.contentSize.width,
										  offset.height*2+d.contentSize.height+(countdown==0?0:10));

			d.anchorPoint = ccp(0, 1);
			d.position = ccp(offset.width, self.contentSize.height-offset.height);
			[self addChild:d];
		} else {
                self.contentSize = CGSizeMake(offset.width*2, offset.height*2);
		}
		CCSprite *bg = nil;
		
		if(iPhoneRuningOnGame()){
			bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width height:self.contentSize.height capx:8/2 capy:8/2];
		}else{
			bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width height:self.contentSize.height capx:8 capy:8];
		}
		
		bg.anchorPoint = ccp(0, 0);
		[self addChild:bg z:-1];
		
		if (countdown != 0) {
			countdownLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:GAME_PROMPT_FONT_SIZE];
			countdownLabel.color = ccc3(238, 228, 208);
			countdownLabel.anchorPoint = ccp(1, 0.5);
			if(iPhoneRuningOnGame()){
				countdownLabel.position = ccp(self.contentSize.width - 10, 10);
			}else{
				countdownLabel.position = ccp(self.contentSize.width - 20, 20);
			}
			[self addChild:countdownLabel];
		}
	}
	return self;
}

-(void)countDown
{
	countdown--;
	//countdownLabel.string = [NSString stringWithFormat:@"%d 秒后关闭...", countdown];
    countdownLabel.string = [NSString stringWithFormat:NSLocalizedString(@"infoalert_close",nil), countdown];
	if (countdown == 0) {
		[self removeFromParentAndCleanup:YES];
		self = nil;
	}
}

-(void)onEnter
{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:INT32_MIN swallowsTouches:YES];
	
	if (self.zOrder == 0) {
		[self setZOrder:10000];
	}
	
	// 调用方法
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(onInfoAlertEnter:)]) {
			[_delegate onInfoAlertEnter:self];
		}
	}
	
	// 倒计时关闭
	if (countdown > 0) {
		//countdownLabel.string = [NSString stringWithFormat:@"%d 秒后关闭...", countdown];
        countdownLabel.string = [NSString stringWithFormat:NSLocalizedString(@"infoalert_close",nil), countdown];
		[self schedule:@selector(countDown) interval:1];
	}

	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	// 坐标
	CGPoint finalyPoint = CGPointZero;
	if (site == InfoAlertSite_screenCenter) {
		finalyPoint = ccp(winSize.width/2-self.contentSize.width/2,
								  winSize.height/2-self.contentSize.height/2);
	} else if (site == InfoAlertSite_parentCenter) {
		if (parent) {
			CGPoint point = ccp(parent.contentSize.width/2-self.contentSize.width/2,
								parent.contentSize.height/2-self.contentSize.height/2);
			finalyPoint = [parent convertToWorldSpace:point];
		}
	} else if (site == InfoAlertSite_none) {
		if (parent) {
			CGPoint point = ccp(self.contentSize.width*anchorPoint.x,
								self.contentSize.height*anchorPoint.y);
			finalyPoint = ccpSub([parent convertToWorldSpace:position], point);
		}
	}
	self.position = ccp(roundf(finalyPoint.x), roundf(finalyPoint.y));
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self removeFromParentAndCleanup:YES];
	self = nil;
	return YES;
}

-(void)onExit{
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(onInfoAlertExit:)]) {
			[_delegate onInfoAlertExit:self];
		}
		[_delegate release];
		_delegate = nil;
	}
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

@end

@implementation RuleButton

@synthesize name;
@synthesize color;
@synthesize size;
@synthesize type;
@synthesize ruleModel;
@synthesize ruleWidth;
@synthesize ruleAnchorPoint;
@synthesize rulePosition;
@synthesize ruleParent;
//iphone for chenjunming
-(id)init{
	if (self = [super init]) {
		color = ccc3(238, 228, 207);
        //字体大小
        size =cFixedScale(18);
		type = RuleType_abyss;	// 默认无尽深渊
		
		ruleWidth = 300;
		if (iPhoneRuningOnGame()) {
			ruleWidth *= 1.3;
		}
		
		ruleAnchorPoint = CGPointZero;
		rulePosition = ccp(-1, -1);
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];

	if (!name) {
		// 加上所有规则
		switch (type) {
                /*
                 case RuleType_timeBox: name = @"时光盒规则"; break;
                 case RuleType_fight: name = @"竞技场规则"; break;
                 case RuleType_abyss: name = @"深渊规则"; break;
                 case RuleType_mainFight: name = @"首领战规则"; break;
                 case RuleType_cat: name = @"招财猫规则"; break;
                 case RuleType_engrave: name = @"宝具铭刻规则"; break;
                 case RuleType_teamFight: name = @"组队挑战规则"; break;
                 case RuleType_teamBoss: name = @"组队BOSS规则"; break;
                 case RuleType_mining: name = @"玄铁矿洞规则"; break;
                 case RuleType_star: name = @"观星阁规则"; break;
                 case RuleType_recruit: name = @"点将台规则"; break;
                 case RuleType_strengthen: name = @"强化装备规则"; break;
                 case RuleType_shop: name = @"商店规则"; break;
                 case RuleType_fishing: name = @"钓鱼规则"; break;
                 case RuleType_food: name = @"食馆规则"; break;
                 case RuleType_car: name = @"坐骑规则"; break;
                 case RuleType_sacrifice: name = @"祭天规则"; break;
                 case RuleType_starRoom: name = @"观星殿规则"; break;
                 case RuleType_offerTask: name = @"悬赏规则"; break;
                 case RuleType_roleSystem: name = @"角色系统规则"; break;
                 //case RuleType_packSystem: name = @"行囊系统规则"; break;
                 case RuleType_phalanxSystem: name = @"阵型系统规则"; break;
                 case RuleType_weaponSystem: name = @"宝具系统规则"; break;
                 case RuleType_guanxingSystem: name = @"观星系统规则"; break;
                 case RuleType_dailySystem: name = @"日常系统规则"; break;
                 default:
                 name = @"规则";
                 break;
                 */
            case RuleType_timeBox: name = NSLocalizedString(@"infoalert_rule_timebox",nil); break;
            case RuleType_fight: name = NSLocalizedString(@"infoalert_rule_fight",nil); break;
            case RuleType_abyss: name = NSLocalizedString(@"infoalert_rule_abyss",nil); break;
            case RuleType_mainFight: name = NSLocalizedString(@"infoalert_rule_main_fight",nil); break;
            case RuleType_cat: name = NSLocalizedString(@"infoalert_rule_cat",nil); break;
            case RuleType_engrave: name = NSLocalizedString(@"infoalert_rule_engrave",nil); break;
            case RuleType_teamFight: name = NSLocalizedString(@"infoalert_rule_team_fight",nil); break;
            case RuleType_unoinBoss: name = NSLocalizedString(@"infoalert_rule_team_boss",nil); break;
            case RuleType_mining: name = NSLocalizedString(@"infoalert_rule_mining",nil); break;
            case RuleType_star: name = NSLocalizedString(@"infoalert_rule_star",nil); break;
            case RuleType_recruit: name = NSLocalizedString(@"infoalert_rule_recruit",nil); break;
            case RuleType_strengthen: name = NSLocalizedString(@"infoalert_rule_strengthen",nil); break;
            case RuleType_shop: name = NSLocalizedString(@"infoalert_rule_shop",nil); break;
            case RuleType_fishing: name = NSLocalizedString(@"infoalert_rule_fishing",nil); break;
            case RuleType_food: name = NSLocalizedString(@"infoalert_rule_food",nil); break;
            case RuleType_car: name = NSLocalizedString(@"infoalert_rule_car",nil); break;
            case RuleType_sacrifice: name = NSLocalizedString(@"infoalert_rule_sacrific",nil); break;  
            case RuleType_starRoom: name = NSLocalizedString(@"infoalert_rule_star_room",nil); break;
			case RuleType_offerTask: name = NSLocalizedString(@"infoalert_rule_offer_task",nil); break;
            case RuleType_roleSystem: name = NSLocalizedString(@"infoalert_rule_role_system",nil); break;
          //case RuleType_packSystem: name = @"行囊系统规则"; break;
            case RuleType_phalanxSystem: name = NSLocalizedString(@"infoalert_rule_phalanx_system",nil); break;
            case RuleType_weaponSystem: name = NSLocalizedString(@"infoalert_rule_weapon_system",nil); break;
            case RuleType_guanxingSystem: name = NSLocalizedString(@"infoalert_rule_guansing_system",nil); break;
            case RuleType_dailySystem: name = NSLocalizedString(@"infoalert_rule_daily_system",nil); break;
			default:
				name = NSLocalizedString(@"infoalert_rule",nil);
				break;
             
		}
	}
	
	if (self.parent) {
		ruleParent = self.parent;
	}
	//fix chao
	//ccColor4B color4 = ccc4(color.r, color.g, color.b, 255);
	//NSArray *labelArray = getUnderlineSpriteArray(name, getCommonFontName(FONT_1), size, color4);
    //NSString *path = nil;
    if (type == RuleType_timeBox ||
        type == RuleType_fight ||
        type == RuleType_abyss ||
        type == RuleType_mining ||
        type == RuleType_fishing ||
        type == RuleType_unionMap ||
        type == RuleType_mainFight ||
        type == RuleType_unoinBoss ||
        type == RuleType_roleCultivate ||
        ruleModel == RuleModelType_help
        ) {
        NSArray *labelArray = getBtnSpriteWithStatus(@"images/ui/button/bt_help_txt");
        self.contentSize = ((CCNode *)[labelArray objectAtIndex:1]).contentSize;
        self.target = self;
        self.call = @selector(callback);
        
        [self setNormalSprite:[labelArray objectAtIndex:0]];
    }else if(type == RuleType_EDLogin||
             type == RuleType_sign ||
             ruleModel == RuleModelType_string
             ){
        ccColor4B color4 = ccc4(49, 17, 8, 255);
        NSArray *labelArray = getUnderlineSpriteArray(name, getCommonFontName(FONT_1), size, color4);
        self.contentSize = ((CCNode *)[labelArray objectAtIndex:1]).contentSize;
        self.target = self;
        self.call = @selector(callback);
        
        [self setNormalSprite:[labelArray objectAtIndex:0]];
    }else{
        NSArray *labelArray = getBtnSpriteWithStatus(@"images/ui/button/bt_help");
        //path = @"images/ui/button/bt_help";
        self.contentSize = ((CCNode *)[labelArray objectAtIndex:1]).contentSize;
        self.target = self;
        self.call = @selector(callback);
        
        [self setNormalSprite:[labelArray objectAtIndex:0]];
        [self setSelectSprite:[labelArray objectAtIndex:1]];
    }
   //
    //end
	/*
    NSArray *labelArray = getBtnSpriteWithStatus(@"images/ui/button/bt_help");
	self.contentSize = ((CCNode *)[labelArray objectAtIndex:1]).contentSize;
	self.target = self;
	self.call = @selector(callback);
	
	[self setNormalSprite:[labelArray objectAtIndex:0]];
	[self setSelectSprite:[labelArray objectAtIndex:1]];
     */
}

-(void)callback
{
	if ([FightManager isFighting]) {
		return ;
	}
	
	if (ruleParent) {
        if(iPhoneRuningOnGame() && [[Window shared] isHasWindow]){
            if (type == RuleType_timeBox ||
               // type == RuleType_fight ||									//Kevin modified
                type == RuleType_abyss ||
                type == RuleType_mining ||
                type == RuleType_fishing ||
                type == RuleType_unionMap
                )
            {
                return;
            }
        }else if( [Arena arenaIsOpen] ){
            if (type == RuleType_timeBox ||
               // type == RuleType_fight ||
                type == RuleType_abyss ||
                type == RuleType_mining ||
                type == RuleType_fishing ||
                type == RuleType_unionMap
                )
            {
                return;
            }
        }
		// 没设置rulePosition, 则取默认值
		if (CGPointEqualToPoint(rulePosition, ccp(-1, -1))) {
            rulePosition = ccp(self.position.x + self.contentSize.width/2,
							   self.position.y - cFixedScale(20));
			ruleAnchorPoint = ccp(1, 1);
		}
		
		NSString *ruleString = nil;
		NSDictionary *ruleDict = [[GameDB shared] getRuleInfo:type];
		if (ruleDict) {
			ruleString = [ruleDict objectForKey:@"info"];
		} else {
			//ruleString = @"规则";
            ruleString = NSLocalizedString(@"infoalert_rule",nil);
		}

		CCSprite *draw = nil;
		int fontSize = 16;
		int lineHeight = 22;
		if (iPhoneRuningOnGame()) {
			fontSize = 20;
			lineHeight = 28;
		}
		draw = drawString(ruleString, CGSizeMake(ruleWidth, 0), getCommonFontName(FONT_1), fontSize, lineHeight, @"#EBE2D0");
	
		[InfoAlert show:self drawSprite:draw parent:ruleParent position:rulePosition anchorPoint:ruleAnchorPoint offset:CGSizeMake(cFixedScale(25), cFixedScale(20))];
	}
}

-(void)onExit
{
	
	[super onExit];
}



@end
