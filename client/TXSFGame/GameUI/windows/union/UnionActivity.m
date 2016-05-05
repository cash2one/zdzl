//
//  UnionActivity.m
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionActivity.h"
#import "UnionManager.h"
#import "UnionPractice.h"
#import "DragonReadyData.h"

static CCPanel *s_unionActivity_panel=nil;
// 同盟首领战时间
static NSString *s_unionBoss_time = nil;
static NSString *s_unionFly_time = nil;
static NSString *s_unionCometo_time = nil;


static inline NSString *getUnionDailyTypeString(int dailyType){
    NSString *tips = nil;
    NSArray *array = [[GameDB shared] getDailyByType:DailyMainType_union];
    for (NSDictionary *dict_ in array) {
        if([[dict_ objectForKey:@"subType"] intValue] == dailyType){
            tips = [dict_ objectForKey:@"tip"];
        }
    }
    return tips;
}

@implementation UnionActivityItem
-(id)initWithType:(Tag_Union_Activity_Type)type count:(int)count{
	if (self = [super init]) {
		int w_ = 483;
        int h_ = 77;
        int off_w = 0;
        if (iPhoneRuningOnGame()) {
			w_=554;
			h_ += 5;
			off_w=10;
        }
		self.contentSize = CGSizeMake(cFixedScale(w_), cFixedScale(h_));
        self.anchorPoint = ccp(0, 0);
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p10.png"];
        bg.scaleX = self.contentSize.width / bg.contentSize.width;
        bg.scaleY = self.contentSize.height / bg.contentSize.height;
        CGPoint halfPoint = ccp(self.contentSize.width / 2,
                                self.contentSize.height / 2);
        bg.position = halfPoint;
        [self addChild:bg];
        
		//CCSprite *typelogo=[CCSprite spriteWithFile:@""];
		
        // 活动类型
        CCSprite *activityType = nil;
        CCLabelTTF *activityName = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:18];
        activityName.scale=cFixedScale(1);
        activityName.color = ccc3(46, 19, 8);
        activityName.anchorPoint = ccp(0, 0.5);
		if (iPhoneRuningOnGame()) {
			activityName.position = ccp(cFixedScale(79+off_w), halfPoint.y);			
		}else{
			activityName.position = ccp(cFixedScale(79+off_w), halfPoint.y);
		}
        [self addChild:activityName];
		
		NSString * activity = @"";
		Tag_Union_Activity_Status status = Tag_Union_Activity_Ended;
		
        switch (type) {
            case Tag_Union_Activity_Money:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang11.png"];
                //activityName.string = @"招财猫";
                activityName.string = NSLocalizedString(@"union_activity_cat",nil);
				
				//activity = [NSString stringWithFormat:@"剩余次数 : %d",count];
                //activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_count",nil),count];
                activity = [NSString stringWithFormat:getUnionDailyTypeString(DailyType_cat),count];
				if(count>0) status = Tag_Union_Activity_Progress;
				
            }
                break;
            case Tag_Union_Activity_Challenge:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang13.png"];
                //activityName.string = @"组队挑战";
                activityName.string = NSLocalizedString(@"union_activity_team_fight",nil);
				status = Tag_Union_Activity_Progress;
            }
                break;
            case Tag_Union_Activity_MainChallenge:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang14.png"];
                //activityName.string = @"同盟首领战";
                activityName.string = NSLocalizedString(@"union_activity_boss",nil);
				// 时间
                //activity = [self getBossTime];
                //if(count>0) status = Tag_Union_Activity_Progress;
                if(count==1){
                    status = Tag_Union_Activity_Progress;
                }else if(count==2){
                    status = Tag_Union_Activity_Unopened; 
                }
                activity = [self getBossTimeWithStatus:status];
            }
                break;
            case Tag_Union_Activity_Donate:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/top_left/yuanbao.png"];
                //activityName.string = @"捐献斗舰";
                activityName.string = NSLocalizedString(@"union_activity_donate",nil);
            }
                break;
            case Tag_Union_Activity_Engrave:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang12.png"];
                //activityName.string = @"宝具铭刻";
                activityName.string = NSLocalizedString(@"union_activity_engrave",nil);
				
				//activity = [NSString stringWithFormat:@"剩余次数 : %d",count];
                //activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_count",nil),count];
                activity = [NSString stringWithFormat:getUnionDailyTypeString(DailyType_engrave),count];
				if(count>0) status = Tag_Union_Activity_Progress;
				
            }
                break;
            case Tag_Union_Activity_Fly:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang15.png"];
                //activityName.string = @"烛龙飞空";
                activityName.string = NSLocalizedString(@"union_activity_fly_name",nil);
				//activity = [NSString stringWithFormat:@"剩余次数 : %d",count];
                //activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_count",nil),count];
                if (s_unionFly_time) {
                    activity = [NSString stringWithFormat:getUnionDailyTypeString(DailyType_fly),s_unionFly_time];
                }
                if(count==1){
                    status = Tag_Union_Activity_Progress;
                    activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_in_date",nil)];
                }else if(count==2){
                    status = Tag_Union_Activity_Unopened;
                }
				
            }
                break;
            case Tag_Union_Activity_Cometo:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang16.png"];
                //activityName.string = @"魔龙降世";
                activityName.string = NSLocalizedString(@"union_activity_cometo_name",nil);
				//activity = [NSString stringWithFormat:@"剩余次数 : %d",count];
                //activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_count",nil),count];
                if (s_unionCometo_time) {
                    activity = [NSString stringWithFormat:getUnionDailyTypeString(DailyType_cometo),s_unionCometo_time];
                }
                if(count==1){
                    status = Tag_Union_Activity_Progress;
                    activity = [NSString stringWithFormat:NSLocalizedString(@"union_activity_in_date",nil)];
                }else if(count==2){
                    status = Tag_Union_Activity_Unopened;
                }
				
            }
                break;
            default:
                break;
        }
        
        if (activityType) {
            int off_x = 0;
            if (iPhoneRuningOnGame()) {
                if (isIphone5()) {
                    off_x -= 8;
                }else{
                    off_x -= 8;
                }
            }else{
                 off_x -= 8;
            }
			activityType.position = ccp(cFixedScale(50+off_x), cFixedScale(41));
            [self addChild:activityType];
        }
        //
        int size_ = 16;
        if (status != Tag_Union_Activity_Progress) {
            if (Tag_Union_Activity_Fly == type || Tag_Union_Activity_Cometo == type) {
                size_ = 14;
            }
        }
        //
        CCLabelTTF *activityLabel = [CCLabelTTF labelWithString:activity fontName:getCommonFontName(FONT_1) fontSize:size_];
        activityLabel.scale=cFixedScale(1);
        activityLabel.color = ccc3(237, 227, 207);
        activityLabel.anchorPoint = ccp(0, 0.5);
        activityLabel.position = ccp(cFixedScale(210+off_w), halfPoint.y);
        [self addChild:activityLabel];
        if (status != Tag_Union_Activity_Progress) {
            if (Tag_Union_Activity_Fly == type || Tag_Union_Activity_Cometo == type) {
                activityLabel.anchorPoint = ccp(0.5, 0.5);
                activityLabel.position = ccp(self.contentSize.width/2+cFixedScale(25), self.contentSize.height/2);
            }
        }
        //
        switch (status) {
            case Tag_Union_Activity_Unopened:
            case Tag_Union_Activity_Ended:
            {
                CCLabelTTF *statusLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
                statusLabel.color = ccc3(237, 227, 207);
                statusLabel.scale=cFixedScale(1);
                statusLabel.position = ccp(cFixedScale(425+off_w), halfPoint.y);
                //statusLabel.string = status == Tag_Union_Activity_Unopened ? @"活动未开启" : @"活动已结束";
                statusLabel.string = status == Tag_Union_Activity_Unopened ? NSLocalizedString(@"union_activity_no_open",nil) : NSLocalizedString(@"union_activity_finish",nil);
                [self addChild:statusLabel];
				
				//Kevin added
				if (iPhoneRuningOnGame()) {
					statusLabel.position = ccpAdd(statusLabel.position, ccp(20, 0));
				}
				//-------------------------//
            }
                break;
            case Tag_Union_Activity_Progress:{
				
				//TODO
				//NSString *label = type % 2 == 0 ? @"bts_carry" : @"bts_open";
				NSString * label = @"bts_carry";
                NSArray *startBtns = getBtnSpriteWithStatus([NSString stringWithFormat:@"images/ui/button/%@",label]);
				
				//end
                CCMenuItem *startMenuItem = [CCMenuItemSprite itemWithNormalSprite:[startBtns objectAtIndex:0]
																	selectedSprite:[startBtns objectAtIndex:1]
																			target:self
																		  selector:@selector(startTapped:)];
                startMenuItem.tag = type;
//              startMenuItem.scale=cFixedScale(1);
				startMenuItem.tag = type;
				if (iPhoneRuningOnGame()) {
					startMenuItem.position = ccp(cFixedScale(465+off_w), halfPoint.y);
					startMenuItem.scale=1.4f;
				}else{
					startMenuItem.position = ccp(cFixedScale(425+off_w), halfPoint.y);
				}
                CCMenu *menu = [CCMenu menuWithItems:startMenuItem, nil];
                menu.position = ccp(0, 0);
                [self addChild:menu];
            }
                break;
                
            default:
                break;
        }
		
	}
	return self;
}

-(id)initWithType:(Tag_Union_Activity_Type)type activity:(NSString *)activity status:(Tag_Union_Activity_Status)status count:(int)count
{
    if (self = [super init]) {
        self.contentSize = CGSizeMake(cFixedScale(483), cFixedScale(77));
        self.anchorPoint = ccp(0, 0);
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p10.png"];
        bg.scaleX = self.contentSize.width / bg.contentSize.width;
        bg.scaleY = self.contentSize.height / bg.contentSize.height;
        CGPoint halfPoint = ccp(self.contentSize.width / 2,
                                self.contentSize.height / 2);
        bg.position = halfPoint;
        [self addChild:bg];
        
        CCSprite *activityType = nil;
        CCLabelTTF *activityName = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:18];
        activityName.scale=cFixedScale(1);
        activityName.color = ccc3(46, 19, 8);
        activityName.anchorPoint = ccp(0, 0.5);
        activityName.position = ccp(cFixedScale(79), halfPoint.y);
        [self addChild:activityName];
        switch (type) {
            case Tag_Union_Activity_Money:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/top_left/yuanbao.png"];
                //activityName.string = @"招财猫";
                activityName.string = NSLocalizedString(@"union_activity_cat",nil);
            }
                break;
            case Tag_Union_Activity_Challenge:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/richang_icon/richang13.png"];
                //activityName.string = @"组队挑战";
                activityName.string = NSLocalizedString(@"union_activity_team_fight",nil);
            }
                break;
            case Tag_Union_Activity_MainChallenge:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/top_left/yuanbao.png"];
                //activityName.string = @"同盟首领战";
                activityName.string = NSLocalizedString(@"union_activity_boss",nil);
            }
                break;
            case Tag_Union_Activity_Donate:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/top_left/yuanbao.png"];
                //activityName.string = @"捐献斗舰";
                activityName.string = NSLocalizedString(@"union_activity_donate",nil);
            }
                break;
            case Tag_Union_Activity_Engrave:
            {
                activityType = [CCSprite spriteWithFile:@"images/ui/top_left/yuanbao.png"];
                //activityName.string = @"宝具铭刻";
                activityName.string = NSLocalizedString(@"union_activity_engrave",nil);
            }
                break;
                
            default:
                break;
        }
        
        if (activityType) {
            activityType.position = ccp(cFixedScale(42), cFixedScale(41));
            [self addChild:activityType];
        }
        
        CCLabelTTF *activityLabel = [CCLabelTTF labelWithString:activity fontName:getCommonFontName(FONT_1) fontSize:16];
        activityLabel.scale=cFixedScale(1);
        activityLabel.color = ccc3(237, 227, 207);
        activityLabel.anchorPoint = ccp(0, 0.5);
        activityLabel.position = ccp(cFixedScale(210), halfPoint.y);
        [self addChild:activityLabel];
        
        switch (status) {
            case Tag_Union_Activity_Unopened:
            case Tag_Union_Activity_Ended:
            {
                CCLabelTTF *statusLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
                statusLabel.scale=cFixedScale(1);
                statusLabel.color = ccc3(237, 227, 207);
                statusLabel.position = ccp(cFixedScale(425), halfPoint.y);
                //statusLabel.string = status == Tag_Union_Activity_Unopened ? @"活动未开启" : @"活动已结束";
                statusLabel.string = status == Tag_Union_Activity_Unopened ? NSLocalizedString(@"union_activity_no_open",nil) : NSLocalizedString(@"union_activity_finish",nil);
                
                [self addChild:statusLabel];
            }
                break;
            case Tag_Union_Activity_Progress:
            {
                // 根据类型按钮文字
				//fix chao
				//                NSString *label = type % 2 == 0 ? @"传 送" : @"打 开";
				//                NSArray *startBtns = getLabelSprites(@"images/ui/button/bt_background2.png",
				//                                                    @"images/ui/button/bt_background2.png",
				//                                                    label,
				//                                                    14,
				//                                                    ccc4(65,197,186,255),
				//                                                    ccc4(65,197,186,255) );
				NSString *label = type % 2 == 0 ? @"bts_carry" : @"bts_open";
                NSArray *startBtns = getBtnSpriteWithStatus([NSString stringWithFormat:@"images/ui/button/%@",label]);
				
				//end
                CCMenuItem *startMenuItem = [CCMenuItemSprite itemWithNormalSprite:[startBtns objectAtIndex:0]
																	selectedSprite:[startBtns objectAtIndex:1]
																			target:self
																		  selector:@selector(startTapped:)];
                startMenuItem.tag = type;
				if (iPhoneRuningOnGame()) {
					startMenuItem.scale=1.4f;
				}
//                startMenuItem.scale=cFixedScale(1);
                startMenuItem.position = ccp(cFixedScale(425), halfPoint.y);
                CCMenu *menu = [CCMenu menuWithItems:startMenuItem, nil];
                menu.position = ccp(0, 0);
                [self addChild:menu];
            }
                break;
                
            default:
                break;
        }
        
    }
    return self;
}

-(NSString *)getBossTimeWithStatus:(int)status_
{
	NSString *timeString = s_unionBoss_time;
	if (timeString && ![@"" isEqualToString:timeString]) {
		NSArray *timeArray = [timeString componentsSeparatedByString:@"-"];
		if (timeArray.count >= 3) {
			int d = [[timeArray objectAtIndex:0] intValue];
			int h = [[timeArray objectAtIndex:1] intValue];
			int m = [[timeArray objectAtIndex:2] intValue];
			NSString *day = nil;
			switch (d) {
				case 1:
					//day = @"一";
                    day = NSLocalizedString(@"union_activity_monday",nil);
					break;
				case 2:
					//day = @"二";
                    day = NSLocalizedString(@"union_activity_tuesday",nil);
					break;
				case 3:
					//day = @"三";
                    day = NSLocalizedString(@"union_activity_wednesday",nil);
					break;
				case 4:
					//day = @"四";
                    day = NSLocalizedString(@"union_activity_thursday",nil);
					break;
				case 5:
					//day = @"五";
                    day = NSLocalizedString(@"union_activity_friday",nil);
					break;
				case 6:
					//day = @"六";
                    day = NSLocalizedString(@"union_activity_saturday",nil);
					break;
				case 7:
					//day = @"日";
                    day = NSLocalizedString(@"union_activity_sunday",nil);
					break;
				default:
					day = @"";
					break;
			}
			//return [NSString stringWithFormat:@"本周%@%02d:%02d", day, h, m];
            if (Tag_Union_Activity_Unopened == status_) {
                return [NSString stringWithFormat:NSLocalizedString(@"union_activity_date",nil), day, h, m];
            }else if(Tag_Union_Activity_Ended == status_){
                return [NSString stringWithFormat:NSLocalizedString(@"union_activity_next_date",nil), day, h, m];
            }else if(Tag_Union_Activity_Progress == status_){
                return [NSString stringWithFormat:NSLocalizedString(@"union_activity_in_date",nil)];
            }
            //return [NSString stringWithFormat:NSLocalizedString(@"union_activity_date",nil), day, h, m];
		}
	}
	return @"";
}

-(void)startTapped:(id)sender
{
	//fix chao
	if (![s_unionActivity_panel isTouchValid]) {
		return;
	}
	//end
	
    CCMenuItem *menuItem = sender;
    switch (menuItem.tag) {
        case Tag_Union_Activity_Money:
        {
            CCLOG(@"点击了招财猫");
            [[Window shared] removeWindow:PANEL_UNION];
			
			[UnionManager doUnionAction:UNION_ACTION_TYPE_Cat];
			
        }
            break;
        case Tag_Union_Activity_Donate:
        {
            CCLOG(@"点击了捐献斗舰");
            [[Window shared] removeWindow:PANEL_UNION];
			
			[UnionManager doUnionAction:UNION_ACTION_TYPE_Donate];
			
        }
            break;
        case Tag_Union_Activity_Challenge:
        {
            CCLOG(@"点击了组队挑战");
            [[Window shared] removeWindow:PANEL_UNION];
			//组队炼妖
			[UnionPracticeCreatJoin statr];
			//[UnionManager doUnionAction:UNION_ACTION_TYPE_Challenge];
        }
            break;
        case Tag_Union_Activity_MainChallenge:
        {
            CCLOG(@"点击了同盟首领战");
            [[Window shared] removeWindow:PANEL_UNION];
			
			[UnionManager doUnionAction:UNION_ACTION_TYPE_MainChallenge];
        }
            break;
        case Tag_Union_Activity_Engrave:
        {
            CCLOG(@"点击了宝具铭刻");
            [[Window shared] removeWindow:PANEL_UNION];
			
			[UnionManager doUnionAction:UNION_ACTION_TYPE_Engrave];
        }
            break;
        case Tag_Union_Activity_Fly:
        {
            CCLOG(@"点击了烛龙飞天");
            [GameConnection request:@"awarEnterRoom" data:[NSDictionary dictionary] target:[DragonReadyData class] call:@selector(beginWithData:)];
        }
            break;
        case Tag_Union_Activity_Cometo:
        {
            CCLOG(@"点击了魔龙降世");
            [GameConnection request:@"awarEnterRoom" data:[NSDictionary dictionary] target:[DragonReadyData class] call:@selector(beginWithData:)];
        }
            break;
        default:
            break;
    }
}

@end

#define UNIONACTIVITY_W (502)
#define UNIONACTIVITY_H (469)
@implementation UnionActivity
//fix chao
-(void)onExit{
	s_unionActivity_panel = nil;
	s_unionBoss_time = nil;
	[super onExit];
}
//end
-(id)initWithUnionId:(int)uid
{
    int w_ = UNIONACTIVITY_W;
    int h_ = UNIONACTIVITY_H;
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
//            w_ += 100;
            h_ += 30;
        }else{
            //w_ += 100;
            h_ += 30;
        }
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:cFixedScale(w_) height:cFixedScale(h_)]) {
        
		//CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:@"活动随家族等级提升而增多" fontName:getCommonFontName(FONT_1) fontSize:16];
        CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_activity_info",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
        tipsLabel.scale=cFixedScale(1);
        tipsLabel.color = ccc3(239, 227, 206);
        tipsLabel.anchorPoint = ccp(0, 0.5);
        tipsLabel.position = ccp(cFixedScale(8), cFixedScale(h_-13));
        [self addChild:tipsLabel];
		
        self.touchEnabled=YES;
		
		s_unionBoss_time = @"";
		[GameConnection request:@"actiInfo" format:@"allyOnly::1" target:self call:@selector(didGetAllyEvent:)];
		
		//Kevin added
		if (iPhoneRuningOnGame()) {
			tipsLabel.position = ccpAdd(tipsLabel.position, ccp(0, -2));
		}
		
    }
    return self;
}

-(void)loadDragonString{
    s_unionFly_time = @"";
    s_unionCometo_time = @"";
    
    NSDictionary *startConfig = [[GameDB shared] readDB:@"awar_start_config"];
	NSArray *allKeys = startConfig.allKeys;
    NSMutableArray *flyMutArray = [NSMutableArray array];
    NSMutableArray *cometoMutArray = [NSMutableArray array];
	for (NSString *key in allKeys) {
		NSDictionary *dict = [startConfig objectForKey:key];
		int dragonType = [[dict objectForKey:@"type"] intValue];
		// 烛龙
        if (dragonType == DragonType_fly) {
            [flyMutArray addObject:[dict objectForKey:@"stime"]];
        }
		// 魔龙
        if (dragonType == DragonType_cometo) {
            [cometoMutArray addObject:[dict objectForKey:@"stime"]];
        }
	}
    [flyMutArray sortUsingSelector:@selector(compare:)];
    [cometoMutArray sortUsingSelector:@selector(compare:)];
    //
    NSMutableArray *flyTimeMutArray = [NSMutableArray array];
    NSMutableArray *cometoTimeMutArray = [NSMutableArray array];
    NSString *fly_tips = nil;
    NSString *cometo_tips = nil;
    NSArray *array = [[GameDB shared] getDailyByType:DailyMainType_union];
    for (NSDictionary *dict_ in array) {
        if([[dict_ objectForKey:@"subType"] intValue] == DailyType_fly){
            fly_tips = [dict_ objectForKey:@"tip"];
        }
        if([[dict_ objectForKey:@"subType"] intValue] == DailyType_cometo){
            cometo_tips = [dict_ objectForKey:@"tip"];
        }
    }
    
    for (NSString *string in flyMutArray) {
		int seconds = [string intValue];
        int hour = seconds / 3600;
        int minute = (seconds % 3600) / 60;
        NSString *timeString = [NSString stringWithFormat:@"%d:%@%d", hour, (minute<10?@"0":@""), minute];
		[flyTimeMutArray addObject:timeString];
	}
    if ([flyTimeMutArray count]>0) {
        if (fly_tips) {
            s_unionFly_time = [NSString stringWithFormat:fly_tips, [flyTimeMutArray componentsJoinedByString:@"/"]]; 
        }else{
            s_unionFly_time = [flyTimeMutArray componentsJoinedByString:@"/"]; 
        }
    }
    //
    for (NSString *string in cometoMutArray) {
		int seconds = [string intValue];
        int hour = seconds / 3600;
        int minute = (seconds % 3600) / 60;
        NSString *timeString = [NSString stringWithFormat:@"%d:%@%d", hour, (minute<10?@"0":@""), minute];
		[cometoTimeMutArray addObject:timeString];
	}
    if ([flyTimeMutArray count]>0) {
        if (cometo_tips) {
            s_unionCometo_time = [NSString stringWithFormat:cometo_tips, [cometoTimeMutArray componentsJoinedByString:@"/"]];
        }else{
            s_unionCometo_time = [cometoTimeMutArray componentsJoinedByString:@"/"];
        }
    }
}
-(void)didGetAllyEvent:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSDictionary * events = getResponseData(response);
		
        // 通过同盟Id获取动态
		
		NSMutableDictionary * trendsDict = nil;
		NSMutableArray *unionActivityArray = [NSMutableArray array];
		
		// 同盟首领战时间
		s_unionBoss_time = [events objectForKey:@"allyBossTime"];
		
		//招财猫
		int a_count = [[events objectForKey:@"cat"] intValue];
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Money] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:a_count] forKey:@"count"];
		//[trendsDict setObject:[NSString stringWithFormat:@"剩余次数 : %d", a_count] forKey:@"activity"];
		//[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Progress] forKey:@"status"];
		[unionActivityArray addObject:trendsDict];
		
		//招财猫
		a_count = [[events objectForKey:@"grave"] intValue];
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Engrave] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:a_count] forKey:@"count"];
		//[trendsDict setObject:[NSString stringWithFormat:@"剩余次数 : %d", a_count] forKey:@"activity"];
		//[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Progress] forKey:@"status"];
		[unionActivityArray addObject:trendsDict];

        //同盟首领
		a_count = [[events objectForKey:@"allyBoss"] intValue];
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_MainChallenge] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:a_count] forKey:@"count"];
		//[trendsDict setObject:[NSString stringWithFormat:@"剩余次数 : %d", a_count] forKey:@"activity"];
		//[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Progress] forKey:@"status"];
		[unionActivityArray addObject:trendsDict];
		
		
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Challenge] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:0] forKey:@"count"];
		[unionActivityArray addObject:trendsDict];
		
        //烛龙飞空
		a_count = [[events objectForKey:@"allyWarSky"] intValue];
        s_unionFly_time = [events objectForKey:@"awar_sky_data"];
        //s_unionFly_time = @"本周18:00";
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Fly] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:a_count] forKey:@"count"];
		//[trendsDict setObject:[NSString stringWithFormat:@"剩余次数 : %d", a_count] forKey:@"activity"];
		//[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Progress] forKey:@"status"];
		[unionActivityArray addObject:trendsDict];
        
        //魔龙降世
		a_count = [[events objectForKey:@"allyWarWorld"] intValue];
        s_unionCometo_time = [events objectForKey:@"awar_world_data"];
        //s_unionCometo_time = @"本周18:00";
		trendsDict = [NSMutableDictionary dictionary];
		[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Cometo] forKey:@"type"];
		[trendsDict setObject:[NSNumber numberWithInt:a_count] forKey:@"count"];
		//[trendsDict setObject:[NSString stringWithFormat:@"剩余次数 : %d", a_count] forKey:@"activity"];
		//[trendsDict setObject:[NSNumber numberWithInt:Tag_Union_Activity_Progress] forKey:@"status"];
		[unionActivityArray addObject:trendsDict];
        //
        //[self loadDragonString];
		//fix chao
		/*
		ScrollPanel *scrollPanel = [ScrollPanel create:self direction:ScrollPanelDirVertical size:CGSizeMake(502, 435) priority:ScrollPanelPriorityNormal];
		[self addChild:scrollPanel];
		 */
        //end
        float perHeight = cFixedScale(87);
        //int pageCount = ceil((float)[unionActivityArray count]/5);
        
        listLayer = [[[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0)] autorelease];
        //listLayer.contentSize = CGSizeMake(scrollPanel.contentSize.width, scrollPanel.contentSize.height * pageCount);
		int w = cFixedScale(UNIONACTIVITY_W);
		int h = cFixedScale(UNIONACTIVITY_H-34);
        if (iPhoneRuningOnGame()) {
			h += cFixedScale(30);
			w=554/2.0f;
        }
        int count = [unionActivityArray count];
        float contentHeight=count*perHeight<h?h:count*perHeight;
        //listLayer.contentSize = CGSizeMake(w, h * pageCount);
        listLayer.contentSize = CGSizeMake(w, contentHeight);
		for(int i = 0; i < unionActivityArray.count; i++){
            NSDictionary * dict = [unionActivityArray objectAtIndex:i];
            UnionActivityItem *unionActivityItem = [[[UnionActivityItem alloc]
													 initWithType:[[dict objectForKey:@"type"] intValue]
													 //activity:[dict objectForKey:@"activity"]
													 //status:[[dict objectForKey:@"status"] intValue]
													 count:[[dict objectForKey:@"count"] intValue]
													 ] autorelease];
            unionActivityItem.tag = [[dict objectForKey:@"type"] intValue];
            unionActivityItem.position = ccp(0, listLayer.contentSize.height - perHeight * (i+1));
            [listLayer addChild:unionActivityItem];			
        }		
		//fix chao
        CCPanel *scrollPanel = [CCPanel panelWithContent:listLayer viewSize:CGSizeMake(w, h)];
		s_unionActivity_panel = scrollPanel;
		scrollPanel.position = ccp(cFixedScale(5), cFixedScale(3));
		[scrollPanel showScrollBar:@"images/ui/common/scroll3.png"];
		[self addChild:scrollPanel];
		[scrollPanel updateContentToTop];
		//scrollPanel.contentLayer = listLayer;
		//end
		
	}else{
		CCLOG(@"error load ally event");
	}
}

@end