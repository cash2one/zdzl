//
//  DailyPanel.m
//  TXSFGame
//
//  Created by efun on 13-1-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DailyPanel.h"
#import "MiningManager.h"
#import "InfoAlert.h"
#import "UnionManager.h"
#import "WorldBossManager.h"
#import "UnionBossManager.h"
#import "UnionPractice.h"
#import "CashCowManager.h"
#import "DragonReadyData.h"

#define DAILYITEM_COUNT			5
#define DAILY_BUTTON_ENABLE		1
#define DAILY_BUTTON_DISABLE	0

#define DAILYITEM_SCALE			1.1f

static NSDictionary* serverData = nil;

@interface DailyMenuItem : CCListItem
{
	CCSprite *itemBg;
	CCSprite *currentItemBg;
	CCSprite *currentIcon;
	
	CCLabelTTF *label;
}
@property (nonatomic) BOOL isSelected;
@end

@implementation DailyMenuItem
@synthesize isSelected;
-(id)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super init]) {
        itemBg = [CCSprite spriteWithFile:@"images/ui/panel/t54.png"];
        self.contentSize = itemBg.contentSize;
        CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        currentItemBg = [CCSprite spriteWithFile:@"images/ui/panel/t55.png"];
        currentIcon = [CCSprite spriteWithFile:@"images/ui/panel/t56.png"];
        currentItemBg.visible = NO;
        currentIcon.visible = NO;
        itemBg.position = halfPoint;
        currentItemBg.position = halfPoint;
        if (iPhoneRuningOnGame()) {
            currentIcon.position = ccp(self.contentSize.width + 9/2, self.contentSize.height / 2);
        }else{
            currentIcon.position = ccp(self.contentSize.width + 9, self.contentSize.height / 2);
		}
        [self addChild:itemBg];
        [self addChild:currentItemBg];
        [self addChild:currentIcon];
        
        isSelected = NO;
		
		if (dictionary) {
			self.tag = [[dictionary objectForKey:@"t"] intValue];
			
			// 任务菜单名
			label = [CCLabelTTF labelWithString:[dictionary objectForKey:@"name"] fontName:@"Helvetica-Bold" fontSize:24];
			label.color = ccc3(46, 16, 9);
            if (iPhoneRuningOnGame()) {
                label.scale = 0.5;
            }
			label.position = halfPoint;
			[self addChild:label z:5];
		}
    }
    return self;
}

-(void)setSelected:(BOOL)_isSelected
{
    if (isSelected == _isSelected) return;
    
    isSelected = _isSelected;
	itemBg.visible = !isSelected;
	currentItemBg.visible = isSelected;
	currentIcon.visible = isSelected;
	label.color = isSelected ? ccc3(252, 244, 111) : ccc3(46, 16, 9);
}

@end

@interface DailyItem : CCLayerColor
{
	CGPoint actionPoint;
	NSString *_tips;
	DailyType type;
	CCLabelTTF *tipsLabel;
}
@property (nonatomic, retain) CCSimpleButton *button;
@property (nonatomic, retain) NSString *tips;

@end

@implementation DailyItem
@synthesize tips = _tips;

@synthesize button;
-(id)initWithDictionary:(NSDictionary*)dictionary isEnable:(BOOL)_isEnable
{
	if (self = [super init]) {
		CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/t53.png"];
//        if (iPhoneRuningOnGame()) {
//            if (isIphone5()) {
//                bg.scaleX = 1.2;
//                bg.scaleY = 1.1;
//            }
//        }
		self.contentSize = bg.contentSize;
		bg.anchorPoint = CGPointZero;
		[self addChild:bg];
		
		if (dictionary) {
			type = [[dictionary objectForKey:@"subType"] intValue];
			self.tag = type;
			
			if (_isEnable) {
				// 时光盒
				if (type == DailyType_timeBox) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_timebox];
				}
				// 竞技场
				else if (type == DailyType_fight) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_arena];
				}
				// 深渊(指定级数解锁)
				else if (type == DailyType_abyss) {
					int abyssLevel = [[[[GameDB shared] getGlobalConfig] objectForKey:@"abyssLevel"] intValue];
					int playerLevel = [[GameConfigure shared] getPlayerLevel];
					if (playerLevel < abyssLevel) {
						_isEnable = NO;
					}
				}
				// 首领战
				else if (type == DailyType_mainFight) {
					_isEnable = YES ;//[[GameConfigure shared] checkPlayerFunction:Unlock_boss];
				}
				// 招财猫(同盟达到某等级可用，现在为一级)
				else if (type == DailyType_cat) {
					
				}
				// 宝具铭刻(同盟达到某等级可用，现在为一级)
				else if (type == DailyType_engrave) {
					
				}
				// 组队挑战(同盟达到某等级可用)
				else if (type == DailyType_teamFight) {
					
				}
				// 组队BOSS(同盟达到某等级可用)
				else if (type == DailyType_teamBoss) {
					
				}
				// 采矿
				else if (type == DailyType_mining) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_mine];
				}
				// 观星
				else if (type == DailyType_star) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_star];
				}
				// 点将
				else if (type == DailyType_recruit) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_recruit];
				}
				// 锻造
				else if (type == DailyType_strengthen) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_hammer];
				}
				// 商店(直接显示，不做是否解锁判断)
				else if (type == DailyType_shop) {
				}
				// 钓鱼
				else if (type == DailyType_fishing) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_fish];
				}
				// 食馆
				else if (type == DailyType_food) {
					_isEnable = [[GameConfigure shared] checkPlayerFunction:Unlock_food];
				}
				// 坐骑兑换(直接显示，不做是否解锁判断)
				else if (type == DailyType_car) {
				}
				//摇钱树(直接显示，不做是否解锁判断)
				else if (type == DailyType_ctree) {
                    //TODO soul
                    //解锁 摇钱树
                    _isEnable = [CashCowManager checkOpenSystem];
				}
				// 还有其他的没判断解锁
				
			}
			
			CCSprite *icon = getIconByDailyType(type);
			if (icon) {
                if (iPhoneRuningOnGame()) {
                    icon.position = ccp(43/2, 38/2);
                }else{
                    icon.position = ccp(43, 38);
				}
				[self addChild:icon];
			}
			
			NSString *name = [dictionary objectForKey:@"name"];
			CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:@"Helvetica-Bold" fontSize:24];
			nameLabel.color = ccc3(46, 16, 9);
			nameLabel.anchorPoint = ccp(0, 0.5);
            nameLabel.position = ccp(87, 52);
			[self addChild:nameLabel z:5];
			
			NSString *info = [dictionary objectForKey:@"info"];
			CCLabelTTF *infoLabel = [CCLabelTTF labelWithString:info fontName:@"Helvetica-Bold" fontSize:16];
			infoLabel.color = ccc3(238, 228, 207);
			infoLabel.anchorPoint = ccp(0, 0.5);
			infoLabel.position = ccp(87, 25);
			[self addChild:infoLabel z:5];
			
            if (iPhoneRuningOnGame()) {
                nameLabel.position = ccp(87/2,52/2);
                nameLabel.scale = 0.5;
                infoLabel.position = ccp(87/2, 25/2);
                infoLabel.scale = 0.5;

            }
			if (_isEnable) {
				
				self.tips = [dictionary objectForKey:@"tip"];
				//[tips retain];
				if (_tips) {
					tipsLabel = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:16];
					tipsLabel.color = ccc3(253, 245, 111);
					tipsLabel.anchorPoint = ccp(0, 0.5);
                    if (iPhoneRuningOnGame()) {
                        tipsLabel.position = ccp(nameLabel.position.x+nameLabel.contentSize.width/2+12/2, 50/2);
                        tipsLabel.scale = 0.5;
                    }else{
                        tipsLabel.position = ccp(nameLabel.position.x+nameLabel.contentSize.width+12, 50);
					}
					[self addChild:tipsLabel z:5];
					
					// 服务器数据
					if (isNeedLoadData(type)) {
						if (serverData) {
							[self setItemStatus];
						}
					} else {
						tipsLabel.string = _tips;
						button = [self getButtonByStatus:YES];
						if (button) [self addChild:button];
					}
				}
			}
			// 强制不能点击按钮。如同盟日常，没有加入同盟的时候
			else {
				button = [self getButtonByStatus:NO];
				if (button) [self addChild:button];
			}
			
		}
	}
	return self;
}
-(id)initWithDictionary:(NSDictionary*)dictionary
{
	return [self initWithDictionary:dictionary isEnable:YES];
}

-(CCSimpleButton*)getButtonByStatus:(BOOL)isEnable
{
	CCSimpleButton *simpleButton;
	if (isEnable) {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_open_1.png" select:@"images/ui/button/bts_open_2.png" target:self call:@selector(menuCallback:)];
		simpleButton.tag = DAILY_BUTTON_ENABLE;
	} else {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_open_3.png" select:@"images/ui/button/bts_open_3.png" target:self call:@selector(menuCallback:)];
		simpleButton.tag = DAILY_BUTTON_DISABLE;
	}
    if (iPhoneRuningOnGame()) {
		simpleButton.scale=1.6f;
        simpleButton.position = ccp(478/2, 39/2);
    }else{
        simpleButton.position = ccp(478, 39);
	}
	
	return simpleButton;
}

-(NSString *)convertTime:(int)seconds
{
	int hour = seconds / 3600;
	int minute = (seconds % 3600) / 60;
	return [NSString stringWithFormat:@"%d:%@%d", hour, (minute<10?@"0":@""), minute];
}

-(NSString *)formatTimeString:(int)seconds
{
	int delay = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bossAllyTimes"] intValue];
	NSString *startString = [[[GameDB shared] getGlobalConfig] objectForKey:@"bossStart"];
	if (seconds < 0 || startString == nil) {
		return nil;
	}
	
	// 默认第一个时间
	int startIndex = 0;
	
	int tipsStart = 0;
	int tipsEnd = 0;
	
	NSArray *startArray = [startString componentsSeparatedByString:@"|"];
	for (int i = 0; i < startArray.count; i++) {
		int start = [[[[startArray objectAtIndex:i] componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
		
		tipsStart = tipsEnd;
		tipsEnd = start + delay;
		
		if (seconds >= tipsStart && seconds <tipsEnd) {
			startIndex = i;
			break;
		}
		
	}
	
	int finalStart = [[[[startArray objectAtIndex:startIndex] componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
	int finalEnd = finalStart + delay;
	
	return [NSString stringWithFormat:@"%@-%@",
			[self convertTime:finalStart],
			[self convertTime:finalEnd]];
}

-(void)setItemStatus
{
	switch (type) {
		case DailyType_fight:
		{
			int num = [[serverData objectForKey:@"arena"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_mainFight:
		{
			int num = [[serverData objectForKey:@"wBossSecs"] intValue];
			NSString *timeString = [self formatTimeString:num];
			if (timeString != nil) {
				tipsLabel.string = [NSString stringWithFormat:_tips, timeString];
			}
			
			int status = [[serverData objectForKey:@"wBoss"] intValue];
			button = [self getButtonByStatus:(status==1)];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_cat:
		{
			int num = [[serverData objectForKey:@"cat"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_engrave:
		{
			int num = [[serverData objectForKey:@"grave"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_teamFight:
		{
			int num = [[serverData objectForKey:@"allyFight"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_teamBoss:
		{
			// 用客户端的
			NSString *teamBossTips = NSLocalizedString(@"daily_tips",nil);
			
			int status = [[serverData objectForKey:@"allyBoss"] intValue];
			NSArray *array = [teamBossTips componentsSeparatedByString:@"|"];
			if (array.count >= 3) {
				if (status == 0 || status == 2) {
					NSString *timeString = [serverData objectForKey:@"allyBossTime"];
					if (![timeString isEqualToString:@""]) {
						NSArray *timeArray = [timeString componentsSeparatedByString:@"-"];
						if (timeArray.count >= 3) {
							int d = [[timeArray objectAtIndex:0] intValue];
							int h = [[timeArray objectAtIndex:1] intValue];
							int m = [[timeArray objectAtIndex:2] intValue];
							NSString *day = nil;
							switch (d) {
								case 1:
									//day = @"一";
                                    day = NSLocalizedString(@"daily_monday",nil);
									break;
								case 2:
									//day = @"二";
                                    day = NSLocalizedString(@"daily_tuesday",nil);
									break;
								case 3:
									//day = @"三";
                                    day = NSLocalizedString(@"daily_wednesday",nil);
									break;
								case 4:
									//day = @"四";
                                    day = NSLocalizedString(@"daily_thursday",nil);
									break;
								case 5:
									//day = @"五";
                                    day = NSLocalizedString(@"daily_friday",nil);
									break;
								case 6:
									//day = @"六";
                                    day = NSLocalizedString(@"daily_saturday",nil);
									break;
								case 7:
									//day = @"日";
                                    day = NSLocalizedString(@"daily_sunday",nil);
									break;
								default:
									day = @"";
									break;
							}
							NSString *hourString = [NSString stringWithFormat:@"%@%d", h<10?@"0":@"",h];
							NSString *minuString = [NSString stringWithFormat:@"%@%d", m<10?@"0":@"",m];
							NSString *dayString = [NSString stringWithFormat:@"%@%@:%@", day, hourString, minuString];
							tipsLabel.string = [NSString stringWithFormat:[array objectAtIndex:status], dayString];
						}
					}
				} else if (status == 1) {
					tipsLabel.string = [array objectAtIndex:1];
				}
			}
			BOOL isOpen = (status == 1);
			button = [self getButtonByStatus:isOpen];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_fishing:
		{
			int num = [[serverData objectForKey:@"fish"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_ctree:
		{
			int num = [[serverData objectForKey:@"ctreenum"] intValue];
			tipsLabel.string = [NSString stringWithFormat:_tips, num];
			button = [self getButtonByStatus:YES];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_fly:
		{
			//tipsLabel.string = [NSString stringWithFormat:_tips, [self getDragonTime:type]];
            if ([serverData objectForKey:@"awar_sky_data"]) {
                tipsLabel.string = [NSString stringWithFormat:_tips, [serverData objectForKey:@"awar_sky_data"]];
            }
			int status = [[serverData objectForKey:@"allyWarSky"] intValue];
			button = [self getButtonByStatus:(status==1)];
			if (button) [self addChild:button];
		}
			break;
		case DailyType_cometo:
		{
			//tipsLabel.string = [NSString stringWithFormat:_tips, [self getDragonTime:type]];
			if ([serverData objectForKey:@"awar_world_data"]) {
                tipsLabel.string = [NSString stringWithFormat:_tips, [serverData objectForKey:@"awar_world_data"]];
            }
			int status = [[serverData objectForKey:@"allyWarWorld"] intValue];
			button = [self getButtonByStatus:(status==1)];
			if (button) [self addChild:button];
		}
			break;
		default:
			break;
	}
}

-(void)menuCallback:(id)sender
{
	CCNode *node = sender;
	int tag = node.tag;
	// 不可点击按钮(灰色)
	if (tag == 0) {
		return;
	}
	
	switch (self.tag) {
		case DailyType_timeBox:
		{
			[TimeBox enterTimeBox];
		}
			break;
		case DailyType_fight:
		{
			[Arena enterArena];
		}
			break;
		case DailyType_abyss:
		{
			[AbyssManager enterAbyss];
		}
			break;
		case DailyType_mainFight:
		{
			[WorldBossManager enterWorldBoss];
		}
			break;
		case DailyType_cat:
		{
			[UnionManager doUnionAction:UNION_ACTION_TYPE_Cat];
		}
			break;
		case DailyType_engrave:
		{
			[UnionManager doUnionAction:UNION_ACTION_TYPE_Engrave];
		}
			break;
		case DailyType_teamFight:
		{
			////////////////////////////////////////////////组队挑战
			CCLOG(@"点击了组队挑战");
			[UnionPracticeCreatJoin statr];
		}
			break;
		case DailyType_teamBoss:
		{
			[UnionBossManager enterUnionBoss];
		}
			break;
		case DailyType_mining:
		{
			[MiningManager enterMining];
		}
			break;
		case DailyType_star:
		{
			[[Window shared] showWindow:PANEL_FATE];
		}
			break;
		case DailyType_recruit:
		{
			[[Window shared] showWindow:PANEL_RECRUIT];
		}
			break;
		case DailyType_strengthen:
		{
			[[Window shared] showWindow:PANEL_HAMMER];
		}
			break;
		case DailyType_shop:
		{
			[[Window shared] showWindow:PANEL_BUSINESSMAN];
		}
			break;
		case DailyType_fishing:
		{
			[FishingManager enterFishing];
		}
			break;
		case DailyType_food:
		{
			[EatFoot show];
		}
			break;
		case DailyType_car:
		{
			[[Window shared] showWindow:PANEL_CAR];
		}
			break;
        case DailyType_ctree:
		{
			[[Window shared] showWindow:PANEL_CASHCOW];
		}
			break;
		case DailyType_fly:
		{
			[GameConnection request:@"awarEnterRoom" data:[NSDictionary dictionary] target:[DragonReadyData class] call:@selector(beginWithData:)];
		}
			break;
		case DailyType_cometo:
		{
			[GameConnection request:@"awarEnterRoom" data:[NSDictionary dictionary] target:[DragonReadyData class] call:@selector(beginWithData:)];
		}
			break;
		default:
			break;
	}
	[[Window shared] removeWindow:PANEL_DAILY];
}

-(NSString*)convertTimeWithArray:(NSArray*)_array
{
	if (_array == nil || _array.count <= 0) return @"";
	
	// 时间排序，从小到大
	NSArray *sorteArray = [_array sortedArrayUsingComparator:^(id obj1, id obj2){
		if([obj1 integerValue] > [obj2 integerValue]) {
			return(NSComparisonResult)NSOrderedDescending;
		}
		if([obj1 integerValue] < [obj2 integerValue]) {
			return(NSComparisonResult)NSOrderedAscending;
		}
		return(NSComparisonResult)NSOrderedSame;
	}];
	
	NSMutableArray *timeArray = [NSMutableArray array];
	
	for (NSString *string in sorteArray) {
		
		int seconds = [string intValue];
		NSString *timeString = [self convertTime:seconds];
		
		[timeArray addObject:timeString];
	}
	
	return [timeArray componentsJoinedByString:@"/"];
}

// 获取烛龙开启时间
-(NSString*)getDragonTime:(DailyType)_type
{
	NSMutableArray *array = [NSMutableArray array];
	
	NSDictionary *startConfig = [[GameDB shared] readDB:@"awar_start_config"];
	NSArray *allKeys = startConfig.allKeys;
	for (NSString *key in allKeys) {
		
		NSDictionary *dict = [startConfig objectForKey:key];
		int dragonType = [[dict objectForKey:@"type"] intValue];
		
		// 烛龙
		if (_type == DailyType_fly) {
			if (dragonType == DragonType_fly) {
				[array addObject:[dict objectForKey:@"stime"]];
			}
		}
		// 魔龙
		else if (_type == DailyType_cometo) {
			if (dragonType == DragonType_cometo) {
				[array addObject:[dict objectForKey:@"stime"]];
			}
		}
	}
	
	return [self convertTimeWithArray:array];
}

-(void)onExit
{
	
	if (_tips) {
		[_tips release];
		_tips = nil;
	}
	
	[super onExit];
}

@end

@implementation DailyPanel

-(void)onEnter
{
	[super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	MessageBox *box1 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
    if (iPhoneRuningOnGame()) {
        box1.contentSize = CGSizeMake(234/2 * 558/490 + 5, 490/2 * 558/490);
        box1.position = ccp(25/2 -10 + 44, 19/2 +4);
        box1.scale = 558/490;
    }else{
	box1.contentSize = CGSizeMake(234, 490);
	box1.position = ccp(25, 19);
	}
    
    [self addChild:box1];
	MessageBox *box2 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
    if (iPhoneRuningOnGame()) {
		box2.contentSize = CGSizeMake(582/2 * 558/490, 490/2 * 558/490);
		box2.position = ccp(268/2 + 10 + 44, 19/2 + 4);
    }else{
        box2.contentSize = CGSizeMake(582, 490);
        box2.position = ccp(268, 19);
	}
    [self addChild:box2];
	
	dailyPanels = [NSMutableArray array];
	[dailyPanels retain];
	dailyButtonDict = [NSMutableDictionary dictionary];
	[dailyButtonDict retain];
	
	// 主菜单
    if (iPhoneRuningOnGame()) {
        layerList = [CCLayerList listWith:LAYOUT_Y :ccp(0, 10/2) :0 :10/2];
    }else{
        layerList = [CCLayerList listWith:LAYOUT_Y :ccp(0, 10) :0 :10];
	}
	[layerList setIsDownward:YES];
//	NSArray *mainMenus = [NSArray arrayWithObjects:
//						  [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"id", @"挑战日常", @"name", @"1", @"t", nil],
//						  [NSDictionary dictionaryWithObjectsAndKeys:@"2", @"id", @"同盟日常", @"name", @"2", @"t", nil],
//						  [NSDictionary dictionaryWithObjectsAndKeys:@"3", @"id", @"设施日常", @"name", @"3", @"t", nil],
//						  [NSDictionary dictionaryWithObjectsAndKeys:@"4", @"id", @"休闲日常", @"name", @"4", @"t", nil],
//						  nil];
    NSArray *mainMenus = [NSArray arrayWithObjects:
						  [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"id", NSLocalizedString(@"daily_dare",nil), @"name", @"1", @"t", nil],
						  [NSDictionary dictionaryWithObjectsAndKeys:@"2", @"id", NSLocalizedString(@"daily_union",nil), @"name", @"2", @"t", nil],
						  [NSDictionary dictionaryWithObjectsAndKeys:@"3", @"id", NSLocalizedString(@"daily_fixture",nil), @"name", @"3", @"t", nil],
						  [NSDictionary dictionaryWithObjectsAndKeys:@"4", @"id", NSLocalizedString(@"daily_free",nil), @"name", @"4", @"t", nil],
						  nil];
	for (int i = 0; i < mainMenus.count; i++) {
		NSDictionary *dict = [mainMenus objectAtIndex:i];
		DailyMenuItem *item = [[[DailyMenuItem alloc] initWithDictionary:dict] autorelease];
		[layerList addChild:item];
		
		if (i == 0) {
			[item setSelected:YES];
		}
	}
	[layerList setDelegate:self];
    if (iPhoneRuningOnGame()) {
		layerList.position = ccp(20.5f + 44, self.contentSize.height-layerList.contentSize.height-73/2.0f);
		layerList.scale = 1.1f;
    }else{
        layerList.position = ccp(41, self.contentSize.height-layerList.contentSize.height-73);
	}
	[self addChild:layerList];
	
	NSString *requestString = [NSString stringWithFormat:@"allyOnly::0"];
	[GameConnection request:@"actiInfo" format:requestString target:self call:@selector(didActionInfo:)];
}

-(void)didActionInfo:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			CCLOG(@"did action info %@", dict);
			if (serverData == nil) {
				serverData = dict;
				[serverData retain];
				
				DailyMenuItem *item = nil;
				CCARRAY_FOREACH(layerList.children, item) {
					if (item.isSelected) {
						[self showWithType:item.tag];
						break;
					}
				}
			}
		}
	} else {
		CCLOG(@"获取日常数据不成功");
	}
}

-(void)showWithType:(DailyMainType)type
{
	BOOL exist = NO;
	for (CCLayer *layer in dailyPanels) {
		if (layer.tag == type) {
			exist = YES;
			break;
		}
	}
	// 不存在，添加
	if (!exist) {
		CCSprite *temp = [CCSprite spriteWithFile:@"images/ui/panel/t53.png"];
        float width = 0;
        float height =0;
        int offsetHeight = 0;
        if (iPhoneRuningOnGame()) {
            width = temp ? temp.contentSize.width : 546.0/2;
            height = temp ? temp.contentSize.height : 77.0/2;
            offsetHeight = 10/2;
        }else{
            width = temp ? temp.contentSize.width : 546.0;
            height = temp ? temp.contentSize.height : 77.0;
            offsetHeight = 10;
		}
        temp = nil;
		
		NSArray *array = [[GameDB shared] getDailyByType:type];
		if (array != nil && array.count > 0) {
			
			NSArray *dailyArray = [array sortedArrayUsingComparator:^(id obj1, id obj2){
				int type1 = [[obj1 objectForKey:@"subType"] intValue];
				int type2 = [[obj2 objectForKey:@"subType"] intValue];
				if(type1 > type2) {
					return(NSComparisonResult)NSOrderedDescending;
				}
				if(type1 < type2) {
					return(NSComparisonResult)NSOrderedAscending;
				}
				return(NSComparisonResult)NSOrderedSame;
			}];
			
			CGSize size = CGSizeMake(width, DAILYITEM_COUNT*height+(DAILYITEM_COUNT-1)*offsetHeight);
			
			int count = dailyArray.count;
			CCLayer *layer = [[[CCLayer alloc] init] autorelease];
			layer.anchorPoint = CGPointZero;
			layer.contentSize = (count>DAILYITEM_COUNT)?CGSizeMake(width, height*count+(count-1)*offsetHeight):size;
			
			NSMutableArray *buttons = [NSMutableArray array];
			int i = 1;
			for (NSDictionary *dailyDict in dailyArray) {
				BOOL _isEnable = YES;
				if (type == DailyMainType_union) {
					NSDictionary * ally = [[GameConfigure shared] getPlayerAlly];
					if (!ally) {
						_isEnable = NO;
					}
				}
				DailyItem *item = [[[DailyItem alloc] initWithDictionary:dailyDict isEnable:_isEnable] autorelease];
                if (iPhoneRuningOnGame()) {
					item.position = ccp(0, layer.contentSize.height-(height*i + offsetHeight*(i-1)));
                }else{
                    item.position = ccp(0, layer.contentSize.height-(height*i+offsetHeight*(i-1)));
				}
				[layer addChild:item];
				if (item.button) {
					[buttons addObject:item.button];
				}
				i++;
			}
			if (buttons.count > 0) {
				[dailyButtonDict setObject:buttons forKey:[NSString stringWithFormat:@"%d", type]];
			}
            CGPoint panelPosition = CGPointZero;
			if (iPhoneRuningOnGame()) {
                panelPosition = ccp(204, 50);
            }else{
                panelPosition = ccp(286, 65);
			}
			// CCPanel
			if (array.count > DAILYITEM_COUNT) {
				
				CGSize finalSize = size;
				CCLayer *finalLayer = [CCLayer node];
				
				if (iPhoneRuningOnGame()) {
					finalSize = CGSizeMake(size.width*DAILYITEM_SCALE, size.height*DAILYITEM_SCALE);
					
					finalLayer.contentSize = CGSizeMake(layer.contentSize.width*DAILYITEM_SCALE, layer.contentSize.height*DAILYITEM_SCALE);
					layer.scale = DAILYITEM_SCALE;
				} else {
					finalLayer.contentSize = CGSizeMake(layer.contentSize.width, layer.contentSize.height);
				}
				
				[finalLayer addChild:layer];
				
				CCPanel *panel = [CCPanel panelWithContent:finalLayer viewSize:finalSize];
				panel.tag = type;
				panel.anchorPoint = CGPointZero;
				panel.position = panelPosition;
				[self addChild:panel];
				[dailyPanels addObject:panel];
				
				[panel updateContentToTop];
			}
			// CCLayer
			else {
				layer.tag = type;
				layer.anchorPoint = CGPointZero;
				layer.position = panelPosition;
				[self addChild:layer];
				[dailyPanels addObject:layer];
				
				if (iPhoneRuningOnGame()) {
					layer.scale = DAILYITEM_SCALE;
				}
			}
		}
	}
	
	for (CCLayer *layer in dailyPanels) {
		layer.visible = (layer.tag == type);
	}
	NSString *typeKey = [NSString stringWithFormat:@"%d", type];
	for (NSString *key in [dailyButtonDict allKeys]) {
		NSArray *buttons = [dailyButtonDict objectForKey:key];
		for (CCSimpleButton *button in buttons) {
			button.isEnabled = [typeKey isEqualToString:key];
		}
	}
}

-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
	DailyMenuItem *listItem = (DailyMenuItem*)_listItem;
	if (listItem.isSelected) return;
	
	DailyMenuItem *item = nil;
	CCARRAY_FOREACH(layerList.children, item) {
		[item setSelected:item.tag == listItem.tag];
	}
	[self showWithType:listItem.tag];
}

-(void)onExit
{
	if (serverData) {
		[serverData release];
		serverData = nil;
	}
	if (dailyPanels) {
		[dailyPanels release];
		dailyPanels = nil;
	}
	if (dailyButtonDict) {
		[dailyButtonDict release];
		dailyButtonDict = nil;
	}
	
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end
