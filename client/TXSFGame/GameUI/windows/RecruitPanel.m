//
//  RecruitPanel.m
//  TXSFGame
//
//  Created by efun on 12-11-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "RecruitPanel.h"
#import "Window.h"
#import "GameDB.h"
#import "InfoAlert.h"
#import "RoleViewerContent.h"
#import "GameFileUtils.h"
#import "GameResourceLoader.h"
#import "RoleThumbViewerContent.h"

#define Intro_Step_Recruit			INTRO_Recruit_Step_1
#define Intro_Step_Recruit_Close	INTRO_CLOSE_Recruit

// 关平
#define Recruit_Rid					21


#define Recruit_Status_Size		CGSizeMake(iPhoneRuningOnGame()?116*1.18/2:116,iPhoneRuningOnGame()?40*1.18/2:40)

#define POS_RECRUIT_ROLE_INFO	ccp(iPhoneRuningOnGame()?3:10,iPhoneRuningOnGame()?120:180)		

static BOOL recruitFirst = YES;
static CCNode *recruitClose = nil;

static inline NSString *getChineseByNumber(int num){
	switch (num) {
		case 1:		return @"初";
		case 2:		return @"贰";
		case 3:		return @"叁";
		case 4:		return @"肆";
		case 5:		return @"伍";
		case 6:		return @"陆";
		case 7:		return @"柒";
		case 8:		return @"捌";
		case 9:		return @"玖";
		case 10:	return @"拾";
		case 11:	return @"拾壹";
		case 12:	return @"拾贰";
		case 13:	return @"拾叁";
		case 14:	return @"拾肆";
		case 15:	return @"拾伍";
			
		default:
			break;
	}
	return @"";
}

@implementation RecruitRoleInfo

@synthesize isSelected;
@synthesize currentRoleId;
@synthesize currentRoleStatus;
@synthesize unlock;
@synthesize unlockLook;
@synthesize statusLabel;
@synthesize conditionStatusArray;

-(void)onEnter
{
	[super onEnter];
	
	// 新手
	if (recruitFirst && [Intro getCurrenStep] == Intro_Step_Recruit && currentRoleId == Recruit_Rid) {
		CCSprite *clickOrange = [CCSprite node];
		clickOrange.contentSize = CGSizeMake(Recruit_Status_Size.width, Recruit_Status_Size.height);
		clickOrange.position = ccp(self.contentSize.width/2, Recruit_Status_Size.height/2);
		[self addChild:clickOrange];
		
		[[Intro share] runIntroTager:clickOrange step:Intro_Step_Recruit];
		recruitFirst = NO;
	}
}

-(BOOL)isExistRole:(int)rid
{
	NSArray *roleList = [[GameConfigure shared] getPlayerRoleList];
	for (NSDictionary *role in roleList) {
		
		int _rid = [[role objectForKey:@"rid"] intValue];
		if (_rid == rid) {
			return YES;
		}
		
	}
	
	return NO;
}

-(id)initWithRoleId:(int)rid
{
    if (self = [super init]) {
        self.currentRoleId = rid;
        isSelected = NO;
		
		recruitTypeDict = [NSMutableDictionary dictionary];
		[recruitTypeDict retain];
		NSString *recruitTypeString = [[[GameDB shared] getGlobalConfig] objectForKey:@"recruitType"];
		NSArray *recruitTypeArray = [recruitTypeString componentsSeparatedByString:@"|"];
		for (NSString *string in recruitTypeArray) {
			NSArray *array = [string componentsSeparatedByString:@":"];
			NSString *key = [array objectAtIndex:0];
			NSString *value = [array objectAtIndex:1];
			[recruitTypeDict setObject:value forKey:key];
		}
        
        NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
		NSDictionary *role = [[GameDB shared] getRoleInfo:rid];
		
        // 品质获取背景
        int quality = [[role objectForKey:@"quality"] intValue];
        NSArray *bgArray = getRecruitBackground(quality);
        bg = [bgArray objectAtIndex:0];
        currentBg = [bgArray objectAtIndex:1];
        currentBg.visible = NO;
        self.contentSize = bg.contentSize;
        CGPoint halfPoint = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        bg.position = halfPoint;
        currentBg.position = halfPoint;
        [self addChild:bg];
        [self addChild:currentBg];
        
        // 状态说明
        statusLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:13];
        statusLabel.color = ccc3(47, 19, 8);
        
        if (iPhoneRuningOnGame()) {
            statusLabel.position = ccp(self.contentSize.width / 2, 12.5/2);
            statusLabel.scale =0.5;
        }else{
            statusLabel.position = ccp(self.contentSize.width / 2, 12.5);
        }
        
        statusLabel.visible = NO;
        [self addChild:statusLabel z:150];
        
        int level = [[player objectForKey:@"level"] intValue];
        
        int index = [[role objectForKey:@"index"] intValue];
        int disLV = [[role objectForKey:@"disLV"] intValue];
        
        // 名字
		BOOL isShowName = NO;
		if (rid > 20000) {
			isShowName = [self isExistRole:rid];
		} else if (level >= disLV) {
			isShowName = YES;
		}
        NSString *name = isShowName ? [role objectForKey:@"name"] : @"???";
        CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:13];
        nameLabel.color = ccc3(47, 19, 8);
        if (iPhoneRuningOnGame()){
            nameLabel.position = ccp(self.contentSize.width / 2, 157/2.0);
            nameLabel.scale = 0.6;
        }else{
            nameLabel.position = ccp(self.contentSize.width / 2, 156);
        }
        [self addChild:nameLabel];
        
        // 职业
        NSString *office = [role objectForKey:@"office"];
        CCSprite *officeIcon = getOfficeIcon(office);
        officeIcon.anchorPoint = ccp(0.5, 1);
        if (iPhoneRuningOnGame()){
			officeIcon.position = ccp(15/2, 144/2);
        }else{
            officeIcon.position = ccp(15, 144);
        }
        [self addChild:officeIcon z:1000];
        
        // 头像
		BOOL isShowIcon = NO;
		if (rid > 20000) {
			isShowIcon = [self isExistRole:rid];
		} else if (level >= disLV) {
			isShowIcon = YES;
		}
		CCSprite *roleIcon = [RoleThumbViewerContent create:rid hide:!isShowIcon];
		roleIcon.anchorPoint = ccp(0, 0);
        roleIcon.position = ccp(2, 1);
        [self addChild:roleIcon z:50];
        
        // 是否解锁
        self.unlock = NO;
        self.unlockLook = (level >= disLV);
        
		int invLV = [[role objectForKey:@"invLV"] intValue];
		
		// 抽奖或签到获得的角色
		if (rid > 20000) {
			self.unlock = [self isExistRole:rid];
			self.unlockLook = [self isExistRole:rid];
		}
        // 非隐藏角色
        else if (index % 7 != 0) {
            if (level >= invLV) {
				// 普通角色默认通过可招募等级，完成任务（可选）解锁
				NSString *invString = [role objectForKey:@"invs"];
				if (invString && [invString rangeOfString:@"tid"].location != NSNotFound) {
					NSArray *keyValueArray = [invString componentsSeparatedByString:@":"];
					int tid = [[keyValueArray objectAtIndex:1] intValue];
					if (tid != 0) {
						NSArray* array = [[TaskManager shared].completeList allKeys];
						unlock = [array containsObject:[NSString stringWithFormat:@"%d", tid]];
					} else {
						unlock = YES;
					}
				} else {
					unlock = YES;
				}
            }
        }
        // 隐藏角色
        else if (index != 0) {
            // 是否完成所有或重要条件
            int vip = [[player objectForKey:@"vip"] intValue];
            conditionStatusArray = [NSMutableArray array];
			[conditionStatusArray retain];
            
            // 可招募条件
            if (level >= disLV) {
                BOOL roleUnlock = YES;
                
                NSArray *invsArray = [[role objectForKey:@"invs"] componentsSeparatedByString:@"|"];
                for (NSString *inv in invsArray) {
                    int done = 0;
                    NSArray *keyValueArray = [inv componentsSeparatedByString:@":"];
                    NSString *key = [keyValueArray objectAtIndex:0];
                    int value = [[keyValueArray objectAtIndex:1] intValue];
                    if ([key isEqualToString:@"vip"]) {
                        if (vip > 0) {
                            if (level >= value) {
                                unlock = YES;
                                done = 1;
                            }
                            //[conditionStatusArray addObject:[NSString stringWithFormat:@"满%d级即可招募:%d", value, done]];
                            [conditionStatusArray addObject:[NSString stringWithFormat:NSLocalizedString(@"recruit_can_recruit",nil), value, done]];
                        }
                    } else if ([key isEqualToString:@"max"]) {
                        if (vip <= 0) {
                            if (level >= value) {
                                unlock = YES;
                                done = 1;
                            }
                            //[conditionStatusArray addObject:[NSString stringWithFormat:@"满%d级即可招募:%d", value, done]];
                            [conditionStatusArray addObject:[NSString stringWithFormat:NSLocalizedString(@"recruit_can_recruit",nil), value, done]];
                        }
                    } else if ([key isEqualToString:@"lv"]) {
						if (level >= value) {
							done = 1;
						} else {
							roleUnlock = NO;
						}
						//[conditionStatusArray addObject:[NSString stringWithFormat:@"满%d级:%d", value, done]];
                        [conditionStatusArray addObject:[NSString stringWithFormat:NSLocalizedString(@"recruit_over_level",nil), value, done]];
					} else if ([key isEqualToString:@"rid"]) {
                        NSDictionary *playerRole = [[GameConfigure shared] getPlayerRoleFromListById:value];
                        NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:value];
                        NSString *roleName = roleInfo ? [roleInfo objectForKey:@"name"] : @"";
                        if (playerRole) {
                            done = 1;
                        } else {
                            roleUnlock = NO;
                        }
                        //[conditionStatusArray addObject:[NSString stringWithFormat:@"招募了%@:%d", roleName, done]];
                        [conditionStatusArray addObject:[NSString stringWithFormat:NSLocalizedString(@"recruit_is_recruit",nil), roleName, done]];
                    } else if ([key isEqualToString:@"tid"]) {
                        NSDictionary *taskInfo = [[GameConfigure shared] getTaskInfoById:value];
                        NSString *taskName = taskInfo ? [taskInfo objectForKey:@"name"] : @"";
                        
						NSDictionary *completeArray = [TaskManager shared].completeList;
						NSArray *completeKeys = [completeArray allKeys];
						if ([completeKeys containsObject:[NSString stringWithFormat:@"%d", value]]) {
							done = 1;
						} else {
							roleUnlock = NO;
						}
						
						// 如果有任务名就直接用任务名
						BOOL isHadAdd = NO;
						if (keyValueArray.count >= 3) {
							NSString *finalTaskName = [keyValueArray objectAtIndex:2];
							if (finalTaskName) {
								[conditionStatusArray addObject:[NSString stringWithFormat:@"%@:%d", finalTaskName, done]];
								isHadAdd = YES;
							}
						}
						if (!isHadAdd) {
							//[conditionStatusArray addObject:[NSString stringWithFormat:@"完成%@任务:%d", taskName, done]];
                            [conditionStatusArray addObject:[NSString stringWithFormat:NSLocalizedString(@"recruit_done_task",nil), taskName, done]];
						}
                    }
                }
                
                unlock = roleUnlock;
            }
        }
        
        NSDictionary *playerRole = [[GameConfigure shared] getPlayerRoleFromListById:rid];
        // 角色在玩家角色列表中
        if (playerRole) {
            int status = [[playerRole objectForKey:@"status"] intValue];
            ROLE_STATUS roleStatus = status == 0 ? ROLE_STATUS_AGAIN : ROLE_STATUS_OWN;
            [self updateByStatus:roleStatus];
        }
        // 角色不在玩家列表中
        else {
            ROLE_STATUS roleStatus = unlock ? ROLE_STATUS_RECRUIT : ROLE_STATUS_CANT_OWN;
            [self updateByStatus:roleStatus];
        }
    }
    return self;
}

-(void)updateByStatus:(ROLE_STATUS)roleStatus
{
    CCNode *child = [self getChildByTag:Tag_Status_Bg];
    if (child) {
        [child removeFromParentAndCleanup:YES];
    }
    CCSprite *statusBg = getStatusBgIcon(roleStatus);
    statusBg.tag = Tag_Status_Bg;
    
    if (iPhoneRuningOnGame()) {
		statusBg.scaleY=1.13f;
        statusBg.position = ccp(self.contentSize.width / 2, 14.5/2);
    }else{
        statusBg.position = ccp(self.contentSize.width / 2, 12.5);
    }
    [self addChild:statusBg z:100];
    self.currentRoleStatus = roleStatus;
    
    switch (roleStatus) {
        case ROLE_STATUS_AGAIN:
        {
            statusLabel.visible = NO;
        }
            break;
        case ROLE_STATUS_OWN:
        {
            statusLabel.visible = YES;
			statusLabel.string = @"";
			NSDictionary *roleDict = [[GameDB shared] getRoleInfo:self.currentRoleId];
			if (roleDict != nil) {
				int type = [[roleDict objectForKey:@"type"] intValue];
				NSString *key = [NSString stringWithFormat:@"%d", type];
				statusLabel.string = [recruitTypeDict objectForKey:key];
			}
        }
            break;
        case ROLE_STATUS_RECRUIT:
        {
			statusLabel.visible = NO;
        }
            break;
        case ROLE_STATUS_CANT_OWN:
        {
			statusBg.visible = NO;
            statusLabel.visible = NO;
        }
            break;
            
        default:
            break;
    }
}


-(void)select:(BOOL)select
{
    isSelected = select;
    
    bg.visible = !select;
    currentBg.visible = select;
}

-(void)dealloc{
	if(conditionStatusArray){
		[conditionStatusArray release];
		conditionStatusArray = nil;
	}
	if (recruitTypeDict != nil) {
		[recruitTypeDict release];
		recruitTypeDict = nil;
	}
	[super dealloc];
}

-(void)onExit{
	if(conditionStatusArray){
		[conditionStatusArray release];
		conditionStatusArray = nil;
	}
	[super onExit];
}

@end

@implementation RecruitHideRoleInfo

@synthesize isSelected;
@synthesize currentRoleId;
@synthesize recruitRoleInfo;

-(id)init
{
    if (self = [super init]) {
        isSelected = NO;
        
        bg = [CCSprite spriteWithFile:@"images/ui/panel/recruit_hideboss_bg.png"];
        if (iPhoneRuningOnGame()) {
            bg.scaleY = 1.2;
            bg.scaleX = 1.05;
        }
        bg.anchorPoint = ccp(0, 0);
        [self addChild:bg];
        
        currentBg = [CCSprite spriteWithFile:@"images/ui/panel/recruit_hideboss_bg2.png"];
        if (iPhoneRuningOnGame()) {
            currentBg.scaleY = 1.2;
            currentBg.scaleX = 1.05;
        }
        currentBg.anchorPoint = ccp(0, 0);
        currentBg.visible = NO;
        [self addChild:currentBg];
        
        self.contentSize = bg.contentSize;
        if (iPhoneRuningOnGame()) {
            iconX = 14/2;
            labelX = 22/2;
            startY = 220/2;
            offsetY = 3/2;
        }else{
			iconX = 18;
			labelX = 30;
			startY = 170;
			offsetY = 3;
        }
    }
    return self;
}

-(void)setRecruitRoleInfo:(RecruitRoleInfo *)recruitRoleInfo_
{
    currentRoleId = recruitRoleInfo_.currentRoleId;
    
    recruitRoleInfo = recruitRoleInfo_;
    if (iPhoneRuningOnGame()) {
        recruitRoleInfo.position =ccp(7,127);
    }else{
        recruitRoleInfo.position = POS_RECRUIT_ROLE_INFO;
    }
	[self addChild:recruitRoleInfo];
    
    // conditionArray为条件数组
    // {"满30级:1", "收齐左边六名武将:0", ...} 1为已完成，0为没完成
    NSMutableArray *statusArray = [NSMutableArray array];
    for (NSString *condition in recruitRoleInfo.conditionStatusArray) {
        NSArray *array = [condition componentsSeparatedByString:@":"];
        CCLabelTTF *lastLabel = [statusArray lastObject];
        float y = lastLabel ? lastLabel.position.y - lastLabel.contentSize.height - offsetY : startY;
        CCLabelTTF *conditionLabel = [CCLabelTTF labelWithString:[array objectAtIndex:0] fontName:getCommonFontName(FONT_1) fontSize:11];
        conditionLabel.color = ccc3(236, 226, 202);
        conditionLabel.anchorPoint = ccp(0, 1);
        conditionLabel.position = ccp(labelX, y);
        [self addChild:conditionLabel];
        [statusArray addObject:conditionLabel];
        
        if (iPhoneRuningOnGame()) {
            conditionLabel.scale = 0.7;
        }
        
        // 完成
        if ([[array objectAtIndex:1] intValue] == 1) {
            CCSprite *doneIcon = [CCSprite spriteWithFile:@"images/ui/common/done.png"];
            if (iPhoneRuningOnGame()) {
                doneIcon.position = ccp(iconX, y - 5);
            }else{
                doneIcon.position = ccp(iconX, y - 8);
			}
				
            [self addChild:doneIcon];
        }
    }
}

-(void)select:(BOOL)select
{
    isSelected = select;
    
    bg.visible = !select;
    currentBg.visible = select;
}

@end

@implementation RecruitRoleList

@synthesize lastRoleId;
@synthesize delegate;

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
		if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:600/2 height:556/2])
			initIsTrue = true;
    }else{
        if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:528 height:420]) {
            initIsTrue = true;
        }
    }
    
    if (initIsTrue) {
		offsetY = 27;
		offsetX2 = 0;
		offsetY2 = 370;
		startPoint = CGPointMake(7, 27);
		offsetPoint = CGPointMake(125, 198);
		
        if (iPhoneRuningOnGame()) {
            startPoint = CGPointMake(12, 38);
            offsetPoint = CGPointMake(72, 120);
			offsetY = 25;
			offsetX2 = -5.5f;
			offsetY2 = 220;
        }
		
		pageSize = CGSizeMake(self.contentSize.width, self.contentSize.height-offsetY);
        
        listLayer = [[[CCLayer alloc] init] autorelease];
        
        CCLOG(@"%d",CCP_SCALE);
        lastRoleId = -1;
        NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
        int level = [[player objectForKey:@"level"] intValue];
        
        NSDictionary *roleDict = [[GameDB shared] readDB:@"role"];
        NSArray *sorteArray = [[roleDict allKeys] sortedArrayUsingComparator:^(id obj1, id obj2){
            if([obj1 integerValue] < [obj2 integerValue]) {
                return(NSComparisonResult)NSOrderedDescending;
            }
            if([obj1 integerValue] > [obj2 integerValue]) {
                return(NSComparisonResult)NSOrderedAscending;
            }
            return(NSComparisonResult)NSOrderedSame;
        }];
        
        lastIndex = -1;
		int chapter = -100;
		
        for (NSString *key in sorteArray) {
            NSDictionary *roleInfo = [roleDict objectForKey:key];
            int index = [[roleInfo objectForKey:@"index"] intValue];
            if (index != 0) {
				// 判断每组的第一个，不可见，退出
				int _index = index - (index%7==0?1:0);
				int firstIndex = (_index/7)*7+1;
				NSDictionary *firstDict = [[GameDB shared] getRoleByIndex:firstIndex];
				if (firstDict) {
					int firstDisLV = [[firstDict objectForKey:@"disLV"] intValue];
					if (level < firstDisLV) {
						continue;
					}
				} else {
					continue;
				}
				
				// 读取第一个
				if (lastIndex == -1 ) {
					lastIndex = index;
				}
				
				int _chapter = [[firstDict objectForKey:@"chapter"] intValue];
				if (chapter != _chapter) {
					chapter = _chapter;
					
					// 获取该面板所有角色(7个)所在章节数
					NSMutableArray *chapterArray = [NSMutableArray array];
					for (int c = firstIndex; c < firstIndex+7; c++) {
						NSDictionary *_info = [[GameDB shared] getRoleByIndex:c];
						if (_info) {
							int __chapter = [[_info objectForKey:@"chapter"] intValue];
							if (__chapter > 0) {
								NSString *__string = [NSString stringWithFormat:@"%d", __chapter];
								if (![chapterArray containsObject:__string]) {
									[chapterArray addObject:__string];
								}
							}
						}
					}
					
					// 绘制章节标题
					CCNode *titleBg = [self getTitleBackground:chapterArray];
					if (iPhoneRuningOnGame()) {
						titleBg.scale = 1.18;
					}
					titleBg.position = [self getTitlePosition:firstIndex];
					titleBg.anchorPoint = ccp(0, 0);
					[listLayer addChild:titleBg];
				}
                
                int roleId = [[roleInfo objectForKey:@"id"] intValue];
                RecruitRoleInfo *recruitRoleInfo = [[[RecruitRoleInfo alloc] initWithRoleId:roleId] autorelease];
                if (iPhoneRuningOnGame()) {
                    recruitRoleInfo.scale = 1.18;
                }
                if (index % 7 == 0) {
                    RecruitHideRoleInfo *recruitHideRoleInfo = [[[RecruitHideRoleInfo alloc] init] autorelease];
                    if (iPhoneRuningOnGame()) {
                        recruitHideRoleInfo.anchorPoint = ccp(0,1);
                        recruitRoleInfo.scale = 1.18;
                    }
                    [recruitHideRoleInfo setRecruitRoleInfo:recruitRoleInfo];
                    [self setLayerPosition:recruitHideRoleInfo index:index];
                    recruitHideRoleInfo.tag = RECRUIT_HIDE_ROLE_TAG;
                    // 增加隐藏角色框
                    [listLayer addChild:recruitHideRoleInfo];
                } else {
                    if (recruitRoleInfo.unlockLook) {
						lastRoleId = MAX(lastRoleId, recruitRoleInfo.currentRoleId);
                    }
                    [self setLayerPosition:recruitRoleInfo index:index];
                    recruitRoleInfo.tag = RECRUIT_ROLE_TAG;
                    // 增加普通角色框
                    [listLayer addChild:recruitRoleInfo];
                }
            }
        }
         
        if (lastRoleId != -1) {
            [self setCurrentRoleInfoWithId:lastRoleId];
        }
		
		NSArray *otherRoleList = [self getOtherRoleList];
		for (int i = 0; i < otherRoleList.count; i++) {
			
			if (i % 8 == 0) {
				// 绘制章节标题
				NSArray *_array = [NSArray arrayWithObject:[[otherRoleList objectAtIndex:i] objectForKey:@"chapter"]];
				CCNode *titleBg = [self getTitleBackground:_array];
				if (iPhoneRuningOnGame()) {
					titleBg.scale = 1.18;
				}
				titleBg.anchorPoint = ccp(0, 0);
				titleBg.position = [self getOtherTitlePosition:i];
				[listLayer addChild:titleBg];
			}
			
			int rid = [[[otherRoleList objectAtIndex:i] objectForKey:@"id"] intValue];
			RecruitRoleInfo *recruitRoleInfo = [[[RecruitRoleInfo alloc] initWithRoleId:rid] autorelease];
			recruitRoleInfo.position = [self getOtherRolePosition:i];
			recruitRoleInfo.tag = RECRUIT_ROLE_TAG;
			[listLayer addChild:recruitRoleInfo];
			if (iPhoneRuningOnGame()) {
				recruitRoleInfo.scale = 1.18;
			}
		}
		
		int normalPage = ceil((float)lastIndex / 7);
		
		int otherRoleCount = [self getOtherRoleCount];
		int otherPage = ceil((float)otherRoleCount / 8);
		
		int page = normalPage + otherPage;
        listLayer.contentSize = CGSizeMake(self.contentSize.width, offsetY + pageSize.height * page);
		
		CCPanel *listPanel = [CCPanel panelWithContent:listLayer viewSize:self.contentSize];
		[listPanel showScrollBar:@"images/ui/common/scroll3.png"];
		if (otherPage == 0) {
			[listPanel updateContentToBottom];
		} else {
			[listPanel updateContentToTop:(normalPage - 1) * pageSize.height];
		}
		[self addChild:listPanel];
		
		// 新手时候不能拖拽
		if ([Intro getCurrenStep] == Intro_Step_Recruit) {
			listPanel.isLock = YES;
		}
		
        self.touchEnabled = YES;
		
    }
    return self;
}

-(CCNode*)getTitleBackground:(NSArray*)_array
{
	CCNode *node = [CCNode node];
	float width = 515;
	if (iPhoneRuningOnGame()) {
		width = 497/2;
	}
	node.contentSize = CGSizeMake(width, cFixedScale(20));
	
	CCSprite *_t1 = [CCSprite spriteWithFile:@"images/ui/panel/t60.png"];
	_t1.anchorPoint = ccp(0, 0);
	[node addChild:_t1];
	
	CCSprite *_t2 = [CCSprite spriteWithFile:@"images/ui/panel/t62.png"];
	_t2.anchorPoint = ccp(1, 0);
	_t2.position = ccp(node.contentSize.width, 0);
	[node addChild:_t2];
	
	CCSprite *_t3 = [CCSprite spriteWithFile:@"images/ui/panel/t61.png"];
	_t3.anchorPoint = ccp(0, 0);
	_t3.position = ccp(_t1.contentSize.width-cFixedScale(0.5), 0);
	_t3.scaleX = (node.contentSize.width-_t1.contentSize.width-_t2.contentSize.width+cFixedScale(1)) / _t3.contentSize.width;
	[node addChild:_t3];

	NSString *name = @"";
	if (_array.count == 1) {
		int _chapter = [[_array objectAtIndex:0] intValue];
		if (_chapter == -1) {
			name = NSLocalizedString(@"recruit_activity",nil);
		} else {
			name = [NSString stringWithFormat:@"%@%@",
					getChineseByNumber(_chapter),
					NSLocalizedString(@"recruit_chapter",nil)];
		}
	} else {
		int _first = [[_array objectAtIndex:0] intValue];
		int _last = [[_array lastObject] intValue];
		name = [NSString stringWithFormat:@"%@%@%@%@%@",
				getChineseByNumber(_first),
				NSLocalizedString(@"recruit_chapter",nil),
				NSLocalizedString(@"recruit_to",nil),
				getChineseByNumber(_last),
				NSLocalizedString(@"recruit_chapter",nil)];
	}
	
	CCLabelTTF *_name = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(14)];
	_name.position = ccp(node.contentSize.width/2, node.contentSize.height/2);
	_name.color = ccc3(47, 19, 8);
	[node addChild:_name];
	
	return node;
}

-(NSArray*)getOtherRoleList
{
	NSMutableArray *list = [NSMutableArray array];
	
	NSDictionary *roleList = [[GameDB shared] getRoleList];
	NSArray *allKeys = [roleList allKeys];
	for (NSString *key in allKeys) {
		NSDictionary *role = [roleList objectForKey:key];
		int _id = [[role objectForKey:@"id"] intValue];
		if (_id > 20000) {
			[list addObject:role];
		}
	}
	
	// 排序
	NSArray *sorteArray = [list sortedArrayUsingComparator:^(id obj1, id obj2){
		int id1 = [[obj1 objectForKey:@"id"] intValue];
		int id2 = [[obj2 objectForKey:@"id"] intValue];
		
		if(id1 > id2) {
			return(NSComparisonResult)NSOrderedDescending;
		}
		if(id1 < id2) {
			return(NSComparisonResult)NSOrderedAscending;
		}
		return(NSComparisonResult)NSOrderedSame;
	}];
	
	return sorteArray;
}

-(int)getOtherRoleCount
{
	NSArray *list = [self getOtherRoleList];
	return list.count;
}

-(int)getOtherRolePageCount
{
	int otherRoleCount = [self getOtherRoleCount];
	return ceil((float)otherRoleCount / 8);
}

-(CGPoint)getOtherRolePosition:(int)otherIndex
{
	int number  = otherIndex % 8;
	int numberX = number % 4;
	int numberY = (number / 4)==0 ? 1 : 0;
	
	CGPoint point = ccp(numberX * offsetPoint.x, numberY * offsetPoint.y);
	
	int partMax = [self getOtherRolePageCount];
	int part = partMax - otherIndex / 8 - 1;
	point = ccpAdd(point, ccp(startPoint.x, startPoint.y + pageSize.height * part));
	
	return point;
}

-(CGPoint)getOtherTitlePosition:(int)otherIndex
{
	int partMax = [self getOtherRolePageCount];
	int part = partMax - otherIndex / 8 - 1;
	CGPoint orginPoint = CGPointMake(startPoint.x,
									 startPoint.y + pageSize.height * part);
	return ccpAdd(orginPoint, ccp(offsetX2, offsetY2));
}

-(CGPoint)getTitlePosition:(int)index
{
	int page = ceil((float)lastIndex / 7);
    int part = (index - 1) / 7;
	part = page - 1 - part;	// 先大后小
	part += [self getOtherRolePageCount];
	CGPoint orginPoint = CGPointMake(startPoint.x,
									 startPoint.y + pageSize.height * part);
	return ccpAdd(orginPoint, ccp(offsetX2, offsetY2));
}

-(void)setLayerPosition:(CCLayer *)layer index:(int)index
{
	int page = ceil((float)lastIndex / 7);
    int part = (index - 1) / 7;
	part = page - 1 - part;	// 先大后小
	part += [self getOtherRolePageCount];
    int number = index % 7;
    
    // 默认part为1开始
    // number为1-7
    CGPoint orginPoint = CGPointMake(startPoint.x,
									 startPoint.y + pageSize.height * part);
    CGPoint realOffsetPoint;
    if (number == 0) {
        if (iPhoneRuningOnGame()) {
             realOffsetPoint = ccp(3 * offsetPoint.x-2, -7);
        }else{
             realOffsetPoint = ccp(3 * offsetPoint.x, 0);
		}
    } else {
		int xIndex = (number - 1) % 3;
		int yIndex = ((number - 1) / 3) == 0 ? 1 : 0;	// 上小下大
        realOffsetPoint = ccp(xIndex * offsetPoint.x,
                              yIndex * offsetPoint.y);
    }
    CGPoint realPoint = ccpAdd(orginPoint, realOffsetPoint);
    layer.position = realPoint;
}

-(void)setCurrentRoleInfoWithId:(int)rid
{
    for (CCLayer *recruitLayer in listLayer.children) {
        if (recruitLayer.tag == RECRUIT_HIDE_ROLE_TAG) {
            RecruitHideRoleInfo *hideRoleInfo = (RecruitHideRoleInfo *)recruitLayer;
            if (hideRoleInfo.currentRoleId == rid) {
                [hideRoleInfo select:YES];
            } else if (hideRoleInfo.isSelected) {
                [hideRoleInfo select:NO];
            }
            
        } else if (recruitLayer.tag == RECRUIT_ROLE_TAG) {
            RecruitRoleInfo *roleInfo = (RecruitRoleInfo *)recruitLayer;
            if (roleInfo.currentRoleId == rid) {
                [roleInfo select:YES];
            } else if (roleInfo.isSelected) {
                [roleInfo select:NO];
            }
        }
    }
}

-(void)updateById:(int)rid
{
    for (CCLayer *recruitLayer in listLayer.children) {
        RecruitRoleInfo *roleInfo = nil;
        if (recruitLayer.tag == RECRUIT_HIDE_ROLE_TAG) {
            RecruitHideRoleInfo *hideRoleInfo = (RecruitHideRoleInfo *)recruitLayer;
            if (hideRoleInfo.currentRoleId == rid) {
                roleInfo = hideRoleInfo.recruitRoleInfo;
            }
            
        } else if (recruitLayer.tag == RECRUIT_ROLE_TAG) {
            RecruitRoleInfo *roleInfoTemp = (RecruitRoleInfo *)recruitLayer;
            if (roleInfoTemp.currentRoleId == rid) {
                roleInfo = roleInfoTemp;
            }
        }
        if (roleInfo) {
            // 更新该角色
            [roleInfo updateByStatus:(ROLE_STATUS_OWN)];
            
            break;
        }
    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self ccSPTouchEnded:touch withEvent:event];
}

-(void)ccSPTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	CGPoint location = [self convertToNodeSpace:touchLocation];
	if (!CGRectContainsPoint(CGRectMake(0, 0, self.contentSize.width, self.contentSize.height), location)) {
		return;
	}	
    touchLocation = [listLayer convertToNodeSpace:touchLocation];	
    RecruitRoleInfo *roleInfo = nil;
	
    for (CCLayer *recruitLayer in listLayer.children) {
        // 点击某个信息框
        if (CGRectContainsPoint(recruitLayer.boundingBox, touchLocation)) {
            int status = 0;     // 默认点击查看信息
            roleInfo= nil;
			BOOL isHideRole = NO;
            if (recruitLayer.tag == RECRUIT_HIDE_ROLE_TAG) {
                RecruitHideRoleInfo *hideRoleInfo = (RecruitHideRoleInfo *)recruitLayer;
                roleInfo = hideRoleInfo.recruitRoleInfo;
                isHideRole = YES;
            } else if (recruitLayer.tag == RECRUIT_ROLE_TAG) {
                roleInfo = (RecruitRoleInfo *)recruitLayer;
				isHideRole = NO;
            }
            if (roleInfo) {
				if (roleInfo && roleInfo.unlock) {
                    if (roleInfo.currentRoleStatus == ROLE_STATUS_RECRUIT ||
                        roleInfo.currentRoleStatus == ROLE_STATUS_AGAIN) {
						CGRect buttonRect = CGRectMake(recruitLayer.boundingBox.origin.x,
                                                       recruitLayer.boundingBox.origin.y,
                                                       Recruit_Status_Size.width,
                                                       Recruit_Status_Size.height);
						if (isHideRole) {
							buttonRect = CGRectOffset(buttonRect, POS_RECRUIT_ROLE_INFO.x, POS_RECRUIT_ROLE_INFO.y);
						}
                        if (CGRectContainsPoint(buttonRect, touchLocation)) {
                            status = roleInfo.currentRoleStatus;
                        }
                    }
                }
				
                if (roleInfo.unlockLook) {
                    // 查看信息
                    if (status == 0) {
                        if ([delegate respondsToSelector:@selector(clickRecruitInfoWithRoleId:)]) {
                            [self setCurrentRoleInfoWithId:roleInfo.currentRoleId];
                            [delegate clickRecruitInfoWithRoleId:roleInfo.currentRoleId];
                        }
                    }
                }
                if (roleInfo.unlock) {
                    // 招募
                    if (status == ROLE_STATUS_RECRUIT) {
                        if ([delegate respondsToSelector:@selector(clickRecruitRoleWithRoleId:)]) {
                            [self setCurrentRoleInfoWithId:roleInfo.currentRoleId];
                            [delegate clickRecruitRoleWithRoleId:roleInfo.currentRoleId];
                        }
                    }
                    // 归队
                    else if (status == ROLE_STATUS_AGAIN) {
                        if ([delegate respondsToSelector:@selector(clickRecruitAgainWithRoleId:)]) {
                            [self setCurrentRoleInfoWithId:roleInfo.currentRoleId];
                            [delegate clickRecruitAgainWithRoleId:roleInfo.currentRoleId];
                        }
                    }
                }
            }
            break;
        }
    }
}

@end

@implementation RecruitRoleDetail

@synthesize currentRoleId;
@synthesize nameLabel;
@synthesize jobLabel;
@synthesize delegate;

-(id)init
{
	float w = 0;
	float h = 0;
	if (iPhoneRuningOnGame()) {
		w = 356/2.0f;
		h = 550/2.0f;
	}else{
		w = 282;
		h = 418;
	}
    
    if ((self = [super initWithColor:ccc4(0, 0, 0, 190) width:w height:h])) {
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_bg.png"];
        bg.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            bg.scaleX = 355/bg.contentSize.width/2.0f;
			bg.scaleY=550/bg.contentSize.height/2.0f;
            bg.position = ccp(0, 1);
        }else{
            bg.position = ccp(1, 1);
		}
        [self addChild:bg];
        
        // 八卦背景
        CCSprite *phalanxBg = [CCSprite spriteWithFile:@"images/animations/phalanx/1/0.png"];
        phalanxBg.anchorPoint = ccp(0.5, 0.43);
        if (iPhoneRuningOnGame()) {
            phalanxBg.position = ccp(self.contentSize.width/2, 240/2);
			phalanxBg.scale = 1.1;
        }else{
            phalanxBg.position = ccp(145, 178);
		}
        [self addChild:phalanxBg];
        
        // 帅印背景
        sealBg = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_seal_bg.png"];
        sealBg.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            sealBg.scale = 335/sealBg.contentSize.width/2;
            sealBg.position = ccp(9/2, 47);
        }else{
            sealBg.position = ccp(9, 75);
		}
        [self addChild:sealBg];
        
        // 帅印名
        sealNameLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
        sealNameLabel.color = ccc3(236, 226, 202);
        sealNameLabel.anchorPoint = ccp(0, 0.5);
        if (iPhoneRuningOnGame()) {
            sealNameLabel.position = ccp(52,67);
            sealNameLabel.scale = 0.7;
        }else{
            sealNameLabel.position = ccp(85, 107);
		}
        [self addChild:sealNameLabel];
        
        // 帅印材料数量
        sealNumLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:10];
        sealNumLabel.color = ccc3(241, 236, 215);
        sealNumLabel.anchorPoint = ccp(1, 0.5);
        if (iPhoneRuningOnGame()) {
            sealNumLabel.position = ccp(170,66);
            sealNumLabel.scale = 0.9;
        }else{
            sealNumLabel.position = ccp(273, 104);
		}
        [self addChild:sealNumLabel];
        
        // 进度条
        scrollLeft = [CCSprite spriteWithFile:@"images/ui/common/progress1.png"];
        scrollLeft.anchorPoint = ccp(0, 0);
        scrollLeft.position = ccp(cFixedScale(6), cFixedScale(6));
        scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/progress2.png"];
        scrollMiddle.anchorPoint = ccp(0, 0);
        scrollMiddle.position = ccp(cFixedScale(8), cFixedScale(6));
        scrollRight = [CCSprite spriteWithFile:@"images/ui/common/progress3.png"];
        scrollRight.anchorPoint = ccp(0, 0);

        scrollLeft.visible = NO;
        scrollMiddle.visible = NO;
        scrollRight.visible = NO;
        [sealBg addChild:scrollLeft];
        [sealBg addChild:scrollMiddle];
        [sealBg addChild:scrollRight];
		
		// 坐标
		namePoint = ccp(self.contentSize.width/2, 405);
		rankPoint = CGPointMake(62, 378);
		weaponPoint = CGPointMake(182, 378);
		jobPoint = ccp(62, 358);
		skillPoint = ccp(182, 358);
		if (iPhoneRuningOnGame()) {
			namePoint = ccp(self.contentSize.width/2, 530/2);
			rankPoint = CGPointMake(75/2, 490/2);
			weaponPoint = CGPointMake(260/2, 490/2);
			jobPoint = ccp(75/2,466/2);
			skillPoint = ccp(260/2, 466/2);
		}
		
		float _fontSize = 14;
		if (iPhoneRuningOnGame()) {
			_fontSize = 9;
		}
		
		CCLabelTTF *_label = nil;
		_label = [CCLabelTTF labelWithString:NSLocalizedString(@"recruit_rank",nil) fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
		_label.anchorPoint = ccp(1, 0.5);
		_label.position = rankPoint;
		_label.color = ccc3(238, 228, 208);
		[self addChild:_label z:100];
		
		_label = [CCLabelTTF labelWithString:NSLocalizedString(@"recruit_weapon",nil) fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
		_label.anchorPoint = ccp(1, 0.5);
		_label.position = weaponPoint;
		_label.color = ccc3(238, 228, 208);
		[self addChild:_label z:100];
		
		_label = [CCLabelTTF labelWithString:NSLocalizedString(@"recruit_office",nil) fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
		_label.anchorPoint = ccp(1, 0.5);
		_label.position = jobPoint;
		_label.color = ccc3(238, 228, 208);
		[self addChild:_label z:100];
		
		_label = [CCLabelTTF labelWithString:NSLocalizedString(@"recruit_stk",nil) fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
		_label.anchorPoint = ccp(1, 0.5);
		_label.position = skillPoint;
		_label.color = ccc3(238, 228, 208);
		[self addChild:_label z:100];
        
        nameLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:20];
		nameLabel.position = namePoint;
		if (iPhoneRuningOnGame()) {
			nameLabel.scale = 0.6;
		}
		nameLabel.color = ccc3(254, 236, 130);
        [self addChild:nameLabel z:100];
		
		rankLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
        rankLabel.anchorPoint = ccp(0, 0.5);
		rankLabel.position = rankPoint;
        rankLabel.color = ccc3(247, 158, 49);
        [self addChild:rankLabel z:100];
		
		weaponLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
        weaponLabel.anchorPoint = ccp(0, 0.5);
		weaponLabel.position = weaponPoint;
        weaponLabel.color = ccc3(247, 158, 49);
        [self addChild:weaponLabel z:100];
        
        jobLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:_fontSize];
        jobLabel.anchorPoint = ccp(0, 0.5);
		jobLabel.position = jobPoint;
        jobLabel.color = ccc3(247, 158, 49);
        [self addChild:jobLabel z:100];
        
        playSkill = NO;
        
        [self initMenu];
    }
    return self;
}

-(void)onEnter{
	[super onEnter];
	
	backing = NO;
	recruiting = NO;
}

-(void)onExit
{
	[GameConnection freeRequest:self];
	
	[super onExit];
}

// scrollValue为0~1
-(void)setScroll:(float)scrollValue
{
    if (scrollValue == 0) {
        scrollLeft.visible = NO;
        scrollMiddle.visible = NO;
        scrollRight.visible = NO;
        return;
    }
    scrollLeft.visible = YES;
    scrollMiddle.visible = YES;
    scrollRight.visible = YES;
    float minWidth = 4*CCP_SCALE;
    float maxWidth = 251*CCP_SCALE;
    float realWidth = MAX(MIN(maxWidth * scrollValue, maxWidth), minWidth);
    scrollMiddle.scaleX = realWidth / scrollMiddle.contentSize.width;
    scrollRight.position = ccp(scrollMiddle.position.x + realWidth,
                               scrollMiddle.position.y);
}

-(void)initMenu
{
    // 获取帅印
	CCSimpleButton *getBtn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_get_signet_1.png"
													select:@"images/ui/button/bt_get_signet_2.png"
													target:self
													call:@selector(getSealTapped)];
    if (iPhoneRuningOnGame()) {
        getBtn.position = ccp(self.contentSize.width/2 - 45, 23);
		getBtn.scale = 1.3f;
    }else{
		getBtn.position = ccp(75*CCP_SCALE, 37*CCP_SCALE);
	}
	getBtn.priority = -57;
	getBtn.tag = ROLE_STATUS_GET;
	[self addChild:getBtn];
    
    // 归队
	CCSimpleButton *againBtn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_rejoin_1.png"
													   select:@"images/ui/button/bt_rejoin_2.png"
													   target:self
														 call:@selector(getRoleAgainTapped)];
	againBtn.tag = ROLE_STATUS_AGAIN;
    if (iPhoneRuningOnGame()) {
        againBtn.position =  ccp(self.contentSize.width/2 + 45, 23);
		againBtn.scale = 1.3f;
    }else{
	againBtn.position = ccp(213*CCP_SCALE, 37*CCP_SCALE);
	}
	againBtn.visible = NO;
	againBtn.priority = -57;
	[self addChild:againBtn];
    
    // 招募
	CCSimpleButton *recruitBtn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_recruit_1.png"
														 select:@"images/ui/button/bt_recruit_2.png"
														 target:self
														   call:@selector(getRoleTapped)];
	recruitBtn.tag= ROLE_STATUS_RECRUIT;
    if (iPhoneRuningOnGame()) {
		recruitBtn.position = ccp(self.contentSize.width/2 + 45, 23);
		recruitBtn.scale = 1.3f;
    }else{
		recruitBtn.position = ccp(213*CCP_SCALE, 37*CCP_SCALE);
	}
	recruitBtn.visible = NO;
	recruitBtn.priority = -57;
	[self addChild:recruitBtn];
    
    // 不可招募
	CCSimpleButton *noRecruitBtn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_recruit_3.png"
														   select:@"images/ui/button/bt_recruit_3.png"
														   target:self
															 call:@selector(getNoRoleTapped)];
	noRecruitBtn.tag = ROLE_STATUS_CANT_OWN;
    if (iPhoneRuningOnGame()) {
		noRecruitBtn.position = ccp(self.contentSize.width/2 + 45,23);
		noRecruitBtn.scale = 1.3f;
    }else{
        noRecruitBtn.position = ccp(213*CCP_SCALE, 37*CCP_SCALE);
	}
	noRecruitBtn.visible = NO;
	noRecruitBtn.priority = -57;
	[self addChild:noRecruitBtn];
    
    // 已招募
    ownLabel = getButtonLabel(BUTTON_LABEL_1);
    //ownLabel.string = @"已招募";
    ownLabel.string = NSLocalizedString(@"recruit_done_recruit",nil);
    if (iPhoneRuningOnGame()) {
		ownLabel.position = ccp(self.contentSize.width/2 + 45, 23);
		ownLabel.scale = 0.7f;
    }else{
		ownLabel.position = ccp(213*CCP_SCALE, 37*CCP_SCALE);
	}
    [self addChild:ownLabel z:100];
    ownLabel.visible = NO;
}

-(void)setMenuWithRoleStatus:(ROLE_STATUS)roleStatus
{
    ownLabel.visible = (roleStatus == ROLE_STATUS_OWN);
	
	CCNode *getNode = [self getChildByTag:ROLE_STATUS_GET];
	getNode.visible = (roleStatus != ROLE_STATUS_NONE);
	
	CCNode *recruitNode = [self getChildByTag:ROLE_STATUS_RECRUIT];
	recruitNode.visible = (roleStatus == ROLE_STATUS_RECRUIT);
	
	CCNode *againNode = [self getChildByTag:ROLE_STATUS_AGAIN];
	againNode.visible = (roleStatus == ROLE_STATUS_AGAIN);
	
	CCNode *noRecruitNode = [self getChildByTag:ROLE_STATUS_CANT_OWN];
	noRecruitNode.visible = (roleStatus == ROLE_STATUS_CANT_OWN);
}

-(void)playRoleNormal{
	
	playSkill = NO;
	
    CCNode * roleChild = [self getChildByTag:Tag_Role];
    if (roleChild) {
        [roleChild removeFromParentAndCleanup:YES];
    }
	
	RoleViewerContent * rvc = [RoleViewerContent node];
	rvc.dir = 1;
	rvc.tag = Tag_Role;
	[rvc loadTargetRole:self.currentRoleId];
	if (iPhoneRuningOnGame()) {
		rvc.position = ccp(145/2 + 15, 250/2);
		rvc.scale = 1.1;
	}else{
		rvc.position = ccp(145, 190);
	}
	
	[self addChild:rvc];
}

-(void)endShowSkill{
	playSkill = NO;
}

// 播放角色绝技
-(void)playRoleSkill{
	
    RoleViewerContent * rvc = (RoleViewerContent*)[self getChildByTag:Tag_Role];
	if(rvc){
		playSkill = YES;
		CCCallFunc * call = [CCCallFunc actionWithTarget:self selector:@selector(endShowSkill)];
		[rvc showSkillByEndCall:call];
    }
	
}

// 是否可以直接招募
-(BOOL)isCanRecruit:(int)rid
{
	if (rid > 20000) return NO;
	return YES;
}

-(void)initDetail:(int)rid
{
	[self removeChildByTag:Tag_Role_detail];
	[self removeChildByTag:Tag_Seal];
	[self setMenuWithRoleStatus:ROLE_STATUS_NONE];
	[self setScroll:0.0f];
	sealBg.visible = NO;
	sealNameLabel.visible = NO;
	sealNumLabel.visible = NO;
	
	if ([self isCanRecruit:rid]) {
		sealBg.visible = YES;
		sealNameLabel.visible = YES;
		sealNumLabel.visible = YES;
	}
}

-(void)updateByRoleId:(int)rid
{
    NSDictionary *roleDict = [[GameDB shared] getRoleInfo:rid];
    int useId = [[roleDict objectForKey:@"useId"] intValue];
    
    playSkill = NO;
    
    // 点击了不同角色
    if (self.currentRoleId != rid) {
		self.currentRoleId = rid;
		
		[self initDetail:rid];
		
        [self playRoleNormal];
		
		nameLabel.string = [roleDict objectForKey:@"name"];
		rankLabel.string = [NSString stringWithFormat:@"%@", [roleDict objectForKey:@"office"]];
		int armId  = [[roleDict objectForKey:@"armId"] intValue];
 		NSDictionary *armDict = [[GameDB shared] getArmInfo:armId];
		if (armDict) {
			NSString *armName = [armDict objectForKey:@"name"];
			weaponLabel.string = armName;
		}
        jobLabel.string = [NSString stringWithFormat:@"%@", [roleDict objectForKey:@"job"]];
		
		[self removeChildByTag:2013];
        int sk2 = [[roleDict objectForKey:@"sk2"] intValue];
        NSDictionary *skillInfo = [[GameDB shared] getSkillInfo:sk2];
        if (skillInfo) {
            NSString *skillName = [skillInfo objectForKey:@"name"];
			
			int f_size = 14;
			if (iPhoneRuningOnGame()) {
				f_size = 9;
			}
			NSArray *labelArray = getUnderlineSpriteArray(skillName,getCommonFontName(FONT_1), f_size, ccc4(78, 142, 202,255));
			
			CCMenuItemFont *bt_nameItem = [CCMenuItemSprite itemWithNormalSprite:[labelArray objectAtIndex:0] selectedSprite:[labelArray objectAtIndex:1] target:self selector:@selector(skillNameBackCall:)];
			bt_nameItem.anchorPoint = ccp(0, 0.5);
			bt_nameItem.position = skillPoint;
			CCMenu *menu = [CCMenu menuWithItems:bt_nameItem, nil];
			menu.position = CGPointZero;
			[self addChild:menu z:100 tag:2013];
			
//            skillLabel.string = [NSString stringWithFormat:@"%@", skillName];
			
			
        } else {
            CCLOG(@"绝招不存在");
        }
		
		if ([self isCanRecruit:rid]) {
			// 帅印
			CCSprite *sealIcon = getSealIcon(useId);
			if (sealIcon) {
				if (iPhoneRuningOnGame()) {
					sealIcon.position = ccp(25, 75);
				}else{
					sealIcon.position = ccp(43, 120);
				}
				sealIcon.tag = Tag_Seal;
				[self addChild:sealIcon];
			} else {
				CCLOG(@"帅印不存在");
			}
			
			NSDictionary *itemDict = [[GameDB shared] getItemInfo:useId];
			sealNameLabel.string = [itemDict objectForKey:@"name"];
		}
		
		else {
			CCSprite *roleInfoBg = [CCSprite spriteWithFile:@"images/ui/panel/p38.png"];
			roleInfoBg.anchorPoint = ccp(0, 0);
			roleInfoBg.position = ccp(4, 5);
			roleInfoBg.tag = Tag_Role_detail;
			[self addChild:roleInfoBg];
			if (iPhoneRuningOnGame()) {
				roleInfoBg.scale = 1.215;
			}
			
			CCLabelTTF *infoLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"recruit_info",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(14)];
			infoLabel.anchorPoint = ccp(0, 0.5);
			infoLabel.position = ccp(cFixedScale(12), cFixedScale(109));
			infoLabel.color = ccc3(247, 158, 49);
			[roleInfoBg addChild:infoLabel];
			
			CCLabelTTF *infoDetail = [CCLabelTTF labelWithString:[roleDict objectForKey:@"info"] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(14) dimensions:CGSizeMake(cFixedScale(258), cFixedScale(90)) hAlignment:kCCTextAlignmentLeft];
			infoDetail.anchorPoint = ccp(0, 1);
			infoDetail.position = ccp(cFixedScale(12), cFixedScale(95));
			infoDetail.color = ccc3(240, 231, 197);
			[roleInfoBg addChild:infoDetail];
		}
    }
	
	if (![self isCanRecruit:rid]) return;
    
    // 招募消耗品
    useNum = [[roleDict objectForKey:@"useNum"] intValue];
    
    NSDictionary *playerRoleDict = [[GameConfigure shared] getPlayerRoleFromListById:rid];
    currentUseNum = 0;
    ROLE_STATUS roleStatus;
    // 角色在玩家角色列表中
    if (playerRoleDict) {
        currentUseNum = useNum;
        
        RoleStatus status = [[playerRoleDict objectForKey:@"status"] intValue];
        roleStatus = status == RoleStatus_in ? ROLE_STATUS_OWN : ROLE_STATUS_AGAIN;
    }
    // 角色不在玩家角色列表中
    else {
        currentUseNum = [[GameConfigure shared] getPlayerItemCountByIid:useId];
        
        // 角色信息
        RecruitRoleInfo *recruitRoleInfo = [[[RecruitRoleInfo alloc] initWithRoleId:rid] autorelease];
        
        // 可招募
        if (recruitRoleInfo.unlock) {
            roleStatus = ROLE_STATUS_RECRUIT;
        }
        // 不可招募
        else {
            roleStatus = ROLE_STATUS_CANT_OWN;
        }
    }
    sealNumLabel.string = [NSString stringWithFormat:@"%d / %d", currentUseNum, useNum];
    [self setMenuWithRoleStatus:roleStatus];
    
    // 进度条
    float percent = useNum == 0 ? 1.0 : (float)currentUseNum / useNum;
    [self setScroll:percent];
}

-(void)skillNameBackCall:(id)sender
{
	CCMenuItem *menuItem = sender;
	
	NSDictionary *roleDict = [[GameDB shared] getRoleInfo:self.currentRoleId];
	int sk = [[roleDict objectForKey:@"sk2"] intValue];
	int armId = [[roleDict objectForKey:@"armId"] intValue];
	NSDictionary *armDict = [[GameDB shared] getArmInfo:armId];
	int sk1 = [[armDict objectForKey:@"sk1"] intValue];
	int sk2 = [[armDict objectForKey:@"sk2"] intValue];
	
	NSDictionary *skillDict = [[GameDB shared] getSkillInfo:sk];
	NSDictionary *skillDict1 = [[GameDB shared] getSkillInfo:sk1];
	NSDictionary *skillDict2 = [[GameDB shared] getSkillInfo:sk2];
	
	NSString *skillInfo = [skillDict objectForKey:@"info"];
	NSString *skillInfo1 = [skillDict1 objectForKey:@"info"];
	NSString *skillInfo2 = [skillDict2 objectForKey:@"info"];
	
	NSString *skillName = [skillDict objectForKey:@"name"];
	NSString *skillName1 = [skillDict1 objectForKey:@"name"];
	NSString *skillName2 = [skillDict2 objectForKey:@"name"];

	NSString *skillAll = [NSString stringWithFormat:NSLocalizedString(@"recruit_skill",nil), skillName, skillInfo, skillName1, skillInfo1, skillName2, skillInfo2];

	float fontSize = 20;
	CCSprite *draw = drawString(skillAll, CGSizeMake(200,0), getCommonFontName(FONT_1), fontSize, fontSize+4, @"#EBE2D0");
	[InfoAlert show:self drawSprite:draw parent:self position:ccpAdd(menuItem.position, ccp(cFixedScale(-10), 0)) anchorPoint:ccp(1, 0.8f) offset:CGSizeMake(10, 10)];
}

// 获取帅印
-(void)getSealTapped
{
    if ([delegate respondsToSelector:@selector(getSealEvent)]) {
        [delegate getSealEvent];
    }
}

// 招募
-(void)getRoleTapped
{
	if (recruiting) return;
	
	int rolesMax = [[[[GameDB shared] getGlobalConfig] objectForKey:@"rolesMax"] intValue];
	NSArray *teamMember = [[GameConfigure shared] getTeamMember];
	if (teamMember.count >= rolesMax) {
		//[ShowItem showItemAct:@"配将人数已满"];
        [ShowItem showItemAct:NSLocalizedString(@"recruit_role_full",nil)];
		return;
	}
	
    if (currentUseNum >= useNum) {
		
		NSDictionary *roleDict = [[GameDB shared] getRoleInfo:self.currentRoleId];
		NSString *name = [roleDict objectForKey:@"name"];
		ItemQuality quality = [[roleDict objectForKey:@"quality"] intValue];
		
		int useId = [[roleDict objectForKey:@"useId"] intValue];
		NSDictionary *itemDict = [[GameDB shared] getItemInfo:useId];
		NSString *sealName = [itemDict objectForKey:@"name"];
		ItemQuality *sealQuality = [[itemDict objectForKey:@"quality"] intValue];
		
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"recruit_get_tips",nil), name, getHexColorByQuality(quality), useNum, sealName, getHexColorByQuality(sealQuality)];
		[[AlertManager shared] showMessage:message target:self confirm:@selector(getRoleConfirm) canel:nil];
		
//        NSString *str = [NSString stringWithFormat:@"rid::%d", currentRoleId];
//        [GameConnection request:@"invite" format:str target:self call:@selector(didGetRole:)];
//		
//		recruiting = YES;
    }
    else {
		//[ShowItem showItemAct:@"帅印不足"];
        [ShowItem showItemAct:NSLocalizedString(@"recruit_no_stamp",nil)];
    }
}

// 不可招募
-(void)getNoRoleTapped
{
	//[ShowItem showItemAct:@"不可招募"];
    [ShowItem showItemAct:NSLocalizedString(@"recruit_no_recruit",nil)];
}

-(void)getRoleConfirm
{
	NSString *str = [NSString stringWithFormat:@"rid::%d", currentRoleId];
	[GameConnection request:@"invite" format:str target:self call:@selector(didGetRole:)];
	
	recruiting = YES;
}

-(void)didGetRole:(id)sender
{
	recruiting = NO;
	
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            
            //int _id = [[dict objectForKey:@"id"] intValue];
            int rid = [[dict objectForKey:@"rid"] intValue];
            
            [[GameConfigure shared] updatePackage:dict];
            
			NSArray * roles = [dict objectForKey:@"role"];
			if([roles count]>0){
				NSDictionary * role = [roles objectAtIndex:0];
				[[GameConfigure shared] addPlayerRole:role];
				[self updateByRoleId:rid];
			}
			
            if (delegate && [delegate respondsToSelector:@selector(updateListWithRoleId:)]) {
                [delegate updateListWithRoleId:rid];
            }
			CGPoint pos = ccp(440*CCP_SCALE, self.contentSize.height/2+200*CCP_SCALE);
            [ClickAnimation showInLayer:(CCLayer*)self.parent z:99 tag:909 call:nil point:pos path:@"images/animations/uiupsucces/" loop:NO];
			[ClickAnimation showSpriteInLayer:(CCLayer*)self.parent z:99 call:nil point:pos moveTo:pos path:@"images/ui/panel/recruit_ok.png" loop:NO];
			
			// 新手
			if (rid == Recruit_Rid) {
				[[Intro share] removeCurrenTipsAndNextStep:Intro_Step_Recruit];
				if (recruitClose) {
					[[Intro share] runIntroTager:recruitClose step:Intro_Step_Recruit_Close];
				}
				
			}
			
        } else {
            CCLOG(@"招募后返回空数据");
        }
    } else {
        CCLOG(@"招募失败");
    }
}

// 归队
-(void)getRoleAgainTapped
{
	if (backing) return;
	
	int rolesMax = [[[[GameDB shared] getGlobalConfig] objectForKey:@"rolesMax"] intValue];
	NSArray *teamMember = [[GameConfigure shared] getTeamMember];
	if (teamMember.count >= rolesMax) {
		//[ShowItem showItemAct:@"配将人数已满"];
        [ShowItem showItemAct:NSLocalizedString(@"recruit_role_full",nil)];
		return;
	}
	
	
    NSMutableDictionary *playerRole = [NSMutableDictionary dictionaryWithDictionary:[[GameConfigure shared] getPlayerRoleFromListById:currentRoleId]];
    if (playerRole) {
        int rid = [[playerRole objectForKey:@"id"] intValue];
        NSString *str = [NSString stringWithFormat:@"rid::%d", rid];
        [GameConnection request:@"roleReturn" format:str target:self call:@selector(didGetRoleAgain:)];
		
		backing = YES;
    }
}

-(void)didGetRoleAgain:(id)sender
{
	backing = NO;
	
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            int _id = [[dict objectForKey:@"rid"] intValue];
            [[GameConfigure shared] updatePlayerRoleWithId:_id status:1];
            
            int rid = -1;
            for (NSDictionary *dict in [[GameConfigure shared] getPlayerRoleList]) {
                if ([[dict objectForKey:@"id"] intValue] == _id) {
                    rid = [[dict objectForKey:@"rid"] intValue];
                    break;
                }
            }
            
            if (rid != -1) {
                [self updateByRoleId:rid];
                if (delegate && [delegate respondsToSelector:@selector(updateListWithRoleId:)]) {
                    [delegate updateListWithRoleId:rid];
                }
            }
            
        } else {
            CCLOG(@"归队后返回空数据");
        }
		//[ShowItem showItemAct:@"归队成功"];
        [ShowItem showItemAct:NSLocalizedString(@"recruit_rejoin",nil)];
    } else {
        CCLOG(@"角色归队失败");
    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGRect touchRect ;
    if (iPhoneRuningOnGame()) {
		touchRect = CGRectMake(60/2.0f, 200/2.0f, 250/2.0f, 210/2.0f);
    }else{
		touchRect = CGRectMake(80, 160, 120, 170);
    }
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    if (CGRectContainsPoint(touchRect, touchLocation)) {
        if (!playSkill) {
            [self playRoleSkill];
        }
    }
}

@end

@implementation RecruitPanel

-(void)onEnter
{
    [super onEnter];
	
	self.touchEnabled = YES;
	if (iPhoneRuningOnGame()) {
		self.touchPriority = -2;
	} else {
		self.touchPriority = -1;
	}
    
    recruitRoleList = [[RecruitRoleList alloc] init];
    if (iPhoneRuningOnGame()) {
         recruitRoleList.position = ccp(44, 15);
    }else{
        recruitRoleList.position = ccp(self.contentSize.width/2-410, self.contentSize.height/2-232);
    }
    [self addChild:recruitRoleList z:10];
    recruitRoleList.delegate = self;
    
    recruitRoleDetail = [[RecruitRoleDetail alloc] init];
    if (iPhoneRuningOnGame()) {
		recruitRoleDetail.position = ccp(self.contentSize.width/2+127/2, 15);
    }else{
        recruitRoleDetail.position = ccp(self.contentSize.width/2+127, self.contentSize.height/2-232);
    }

    [self addChild:recruitRoleDetail];
    recruitRoleDetail.delegate = self;
    
    if (recruitRoleList.lastRoleId != -1) {
        [recruitRoleDetail updateByRoleId:recruitRoleList.lastRoleId];
    }
	
	// 新手
	if ([Intro getCurrenStep] == Intro_Step_Recruit) {
		recruitClose = _closeBnt;
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [recruitRoleList ccTouchEnded:touch withEvent:event];
    [recruitRoleDetail ccTouchEnded:touch withEvent:event];
}

#pragma mark -
#pragma mark RecruitPanelDelegate
-(void)clickRecruitInfoWithRoleId:(int)rid
{
    [recruitRoleDetail updateByRoleId:rid];
}

-(void)clickRecruitRoleWithRoleId:(int)rid
{
    [recruitRoleDetail updateByRoleId:rid];
    [recruitRoleDetail getRoleTapped];
}

-(void)clickRecruitAgainWithRoleId:(int)rid
{
    [recruitRoleDetail updateByRoleId:rid];
    [recruitRoleDetail getRoleAgainTapped];
}

-(void)getSealEvent
{
    [[Window shared] showWindow:PANEL_SACRIFICE];
    
    [[Window shared] removeWindow:PANEL_RECRUIT];
}

-(void)updateListWithRoleId:(int)rid
{
    [recruitRoleList updateById:rid];
}

-(void)onExit
{
	recruitFirst = YES;
	if (recruitClose) recruitClose = nil;
    
    recruitRoleDetail.delegate = nil;
    [recruitRoleDetail release];
    recruitRoleDetail = nil;
    
    recruitRoleList.delegate = nil;
    [recruitRoleList release];
    recruitRoleList = nil;

	[super onExit];
}

-(void)closeWindow{
	[super closeWindow];
	[[Intro share] removeCurrenTipsAndNextStep:Intro_Step_Recruit_Close];
}

@end
