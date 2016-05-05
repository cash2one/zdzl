//
//  TaskPanel.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-20.
//  Copyright 2012 eGame. All rights reserved.
//

#import "TaskPanel.h"
#import "Window.h"
#import "TaskManager.h"
#import "Task.h"
#import "CCLabelFX.h"
#import "GameDB.h"
#import "CJSONDeserializer.h"
#import "GameMoney.h"
#import "GameEffects.h"
#import "ShowItem.h"
#import "InfoAlert.h"
#import "intro.h"
#import "GameUI.h"

static TaskList * taskList;
static TaskDetailList * taskDetailList;
static TaskDetail * taskDetail;
static TaskOfferPanel *taskOfferPanel;
static BOOL isTaskButtonTouch=NO;
static int  s_taskPanelType = Task_Type_none;

// 打开宝箱图片的Tag
#define BoxOpenTag		105

#define OfferTipsTag	100

@implementation TaskMenuItem
@synthesize label;
@synthesize isLock;
-(id)init
{
    if (self = [super init]) {
        //左边任务按钮
        itemBg = [CCSprite spriteWithFile:@"images/ui/panel/t19.png"];
        self.contentSize = itemBg.contentSize;
        CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        currentItemBg = [CCSprite spriteWithFile:@"images/ui/panel/t20.png"];
        currentIcon = [CCSprite spriteWithFile:@"images/ui/panel/t23.png"];
        currentItemBg.visible = NO;
        currentIcon.visible = NO;
        
        
        [self addChild:itemBg];
        [self addChild:currentItemBg];
        [self addChild:currentIcon];
        
        isMenuSelect = NO;
        
        // 任务菜单名
        float fontSize=24;
        if(iPhoneRuningOnGame()){
			fontSize=12;
        }
        
        label = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:fontSize];
        
        label.color = ccc3(46, 16, 9);
        [self addChild:label z:5];

        itemBg.position = halfPoint;
        currentItemBg.position = halfPoint;
        currentIcon.position = ccp(self.contentSize.width +cFixedScale(9), self.contentSize.height / 2);
        label.position =halfPoint;
    }
    return self;
}

-(void)setIsLock:(BOOL)_isLock
{
	itemBg.visible = NO;
	currentIcon.visible = NO;
	currentItemBg.visible = NO;
	
	label.color = ccc3(46, 46, 46);
	//不可用按钮
	CCSprite *lockBg = [CCSprite spriteWithFile:@"images/ui/panel/t35.png"];
	lockBg.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
	[self addChild:lockBg];
	
	isLock = _isLock;
}

-(void)setMenuSelected:(BOOL)select
{
    if (select == isMenuSelect || isLock) {
		return;
	}
    
    isMenuSelect = select;
    if (select) {
        itemBg.visible = NO;
        currentItemBg.visible = YES;
        currentIcon.visible = YES;
        label.color = ccc3(252, 244, 111);
    } else {
        itemBg.visible = YES;
        currentItemBg.visible = NO;
        currentIcon.visible = NO;
        label.color = ccc3(46, 16, 9);
    }
	
}

@end

@implementation TaskDetailMenuItem
//@synthesize task;
-(id)init
{
    if (self = [super init]) {
        itemBg = [CCSprite spriteWithFile:@"images/ui/panel/t21.png"];
        self.contentSize = itemBg.contentSize;
        CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
        currentItemBg = [CCSprite spriteWithFile:@"images/ui/panel/t22.png"];
        currentItemBg.visible = NO;
        itemBg.position = halfPoint;
        currentItemBg.position = halfPoint;
        [self addChild:itemBg];
        [self addChild:currentItemBg];
        
        isMenuSelect = NO;
        
		label = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:@"Helvetica-Bold"
								  fontSize:24
							  shadowOffset:CGSizeMake(0,0)
								shadowBlur:10.0f];
        if (iPhoneRuningOnGame()) {
            // label.scale=FONT_SIZE_SCALE;
        }
		label.color = ccc3(46, 16, 9);
		label.shadowColor =ccc4(255, 0, 0, 128);
		label.position = halfPoint;
		[self addChild:label z:1 tag:123];
		
    }
    return self;
}

-(void)setMenuSelected:(BOOL)select{
	
    if (select == isMenuSelect) {
        return;
    }
    
    isMenuSelect = select;
    if (select) {
        itemBg.visible = NO;
        currentItemBg.visible = YES;
    } else {
        itemBg.visible = YES;
        currentItemBg.visible = NO;
    }
}

-(void)dealloc{
	if (task != nil) {
		CCLOG(@"TaskDetailMenuItem->dealloc:%d",task.taskId);
		[task release];
		task = nil;
	}
	[super dealloc];
}

-(Task*)getTask{
	return task;
}

-(void)setTask:(Task*)_task{
	if (task != nil) {
		[task release];
		task = nil;
	}
	if (_task == nil) {
		return ;
	}
	task = _task;
	[task retain];
	
	NSDictionary * info = task.taskInfo;
	label.string = [info objectForKey:@"name"];
	
	// 加上锁图标
	if (![task isUnlock]) {
		currentItemBg.visible = NO;
		
		CCSprite *lockIcon = [CCSprite spriteWithFile:@"images/ui/common/lock.png"];
		lockIcon.position = ccp(self.contentSize.width - 20, self.contentSize.height - 20);
		[self addChild:lockIcon z:100];
	}
}

@end

//左边任务列表
@implementation TaskList

-(void)draw
{
    [super draw];
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    glLineWidth(1);
    ccDrawRect(ccp(0, 0), ccp(_contentSize.width, _contentSize.height));
}

-(id)init
{
    int w=191;
    int h=488;
    if (iPhoneRuningOnGame()) {
		w=228/2;
		h=549/2;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:w height:h]) {
		
        //NSArray *menuArray = [NSArray arrayWithObjects:@"主线任务", @"支线任务", @"悬赏任务", @"隐藏任务", nil];
        NSArray *menuArray = [NSArray arrayWithObjects:
                              NSLocalizedString(@"task_main",nil),
                              NSLocalizedString(@"task_ramus",nil),
                              NSLocalizedString(@"task_offer",nil),
                              NSLocalizedString(@"task_hide",nil),
                              nil];
        CGPoint pt=ccp(0, 10);
        if (iPhoneRuningOnGame()) {
			pt.y=7;
        }
        layerList = [CCLayerList listWith:LAYOUT_Y :pt :0 :10];
        [layerList setIsDownward:YES];
		
		// 是否解锁悬赏任务
		BOOL unlockOffer = [[GameConfigure shared] checkPlayerFunction:Unlock_offer];
        for (int i = 0; i < 4; i++) {
            TaskMenuItem *taskMenuItem = [TaskMenuItem node];
            if (iPhoneRuningOnGame()) {
				taskMenuItem.scale=1.19f;
            }
			Task_Type type = i+1;
			
			// 悬赏，主线，支线任务顺序交换
			if (unlockOffer) {
				if (type == 1) {
					type = 3;
				} else if (type == 2) {
					type = 1;
				} else if (type == 3) {
					type = 2;
				}
			} else {
				if (type == 2) {
					type = 3;
				} else if (type == 3) {
					type = 2;
				}
			}
            taskMenuItem.tag = type;
            taskMenuItem.label.string = [menuArray objectAtIndex:type-1];
            [layerList addChild:taskMenuItem];
			
			// 是否有对应的任务
			NSArray *taskList = [[TaskManager shared] getTaskListByType:type];
			if (taskList.count == 0) {
				if (taskMenuItem.tag == Task_Type_offer) {
					if (!unlockOffer) {
						taskMenuItem.isLock = YES;
					}
				} else {
					taskMenuItem.isLock = YES;
				}
			}
			//如果有任务
			//看看支线 和 隐藏线的任务功能是不是解锁了
			//如果没解锁，那也是需要被锁定的
			else
			{
				if (taskMenuItem.tag == Task_Type_vice) {
					if (![[GameConfigure shared] checkPlayerFunction:Unlock_vice]) {
						taskMenuItem.isLock = YES ;
					}
				}
				
			}
        }
        
        [self addChild:layerList];
        [layerList setDelegate:self];
        //这里修改列表项的位置
        if (iPhoneRuningOnGame()) {
			layerList.position = ccp(9, self.contentSize.height/2 - layerList.contentSize.height/2+35);
        }else{
            layerList.position = ccp(14, self.contentSize.height - layerList.contentSize.height);
        }
    }
    return self;
}

-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
    //
    if (isTaskButtonTouch) {
        return;
    }
    isTaskButtonTouch = YES;
	// 新手教程
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_MMission_Step_1];
	
	int tag = _listItem.tag;
	TaskMenuItem * item = (TaskMenuItem*)[layerList getChildByTag:tag];
	
	isTaskButtonTouch = NO;
	
	if (item.isLock) {
		return;
	}
	[self selectItemByTaskType:_listItem.tag];
}

-(void)selectItemByTaskType:(Task_Type)type{
    //
    s_taskPanelType = type;
    
	TaskMenuItem * item = (TaskMenuItem*)[layerList getChildByTag:type];
	if (item.isLock) {
		return;
	}
	
	for (int i = 1; i <= 4; i++) {
		TaskMenuItem * item = (TaskMenuItem*)[layerList getChildByTag:i];
		[item setMenuSelected:NO];
    }
	[item setMenuSelected:YES];
	
	
	if (type == Task_Type_offer) {
		taskDetail.visible = NO;
		taskDetailList.visible = NO;
		taskOfferPanel.visible = YES;
		if (taskOfferPanel.needLoad) {
			[taskOfferPanel loadDataByServer];
		}
	} else {
		taskDetailList.visible = YES;
		taskOfferPanel.visible = NO;
		[taskDetailList showTaskList:type];
	}
}

@end

@implementation TaskDetailList

-(void)draw{
    [super draw];
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    glLineWidth(1);
    if (iPhoneRuningOnGame()) {
        ccDrawRect(ccp(0, 0), ccp(_contentSize.width, _contentSize.height));
    }else{
        ccDrawRect(ccp(0, 0), ccp(_contentSize.width, _contentSize.height));
    }
}

-(id)init{
    float w=191;
    float h=488;
    if (iPhoneRuningOnGame()) {
		w=228/2;
		h=549/2;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:w height:h]) {
        
    }
    return self;
}

-(void)onEnter
{
	[super onEnter];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1 swallowsTouches:YES];
}

-(void)onExit
{
	[super onExit];
	
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}

-(void)showTaskList:(Task_Type)type{
	NSArray * tasks = [[TaskManager shared] getTaskListByType:type];
	[self showList:tasks withType:type];
}

// 非悬赏任务
-(void)showList:(NSArray*)list___ withType:(Task_Type)type
{
	NSArray* list = [NSArray arrayWithArray:list___];
	
	CCNode * node = [self getChildByTag:123];
	if(node) [node removeFromParentAndCleanup:YES];
	
	if([list count]>0){
		
		float height = 0;
        
		float offsetHeight = 10;

		BOOL isStart = YES ;
		NSMutableArray *items = [NSMutableArray array];
		for (int i = 0; i < [list count]; i++) {
			TaskDetailMenuItem * item = [TaskDetailMenuItem node];
			item.tag = i;
            if (iPhoneRuningOnGame()) {
                if (isIphone5()) {
                    item.scaleY=1.13f;
                }else{
                    item.scale=1.13f;
                }
            }
			Task* t = (Task *)[list objectAtIndex:i];
			
			if (t.status == Task_Status_complete) {
				continue;
			}
			
			[item setTask:t];
			
			if (height == 0) {
                height = item.contentSize.height;
			}
			
			if (isStart) {
				[item setMenuSelected:YES];
				[taskDetail setTask:t];
				isStart = NO ;
			}
			
			[items addObject:item];
		}
		
		float listHeight = list.count*(height+offsetHeight);
		listHeight = MAX(listHeight, self.contentSize.height-2);
		
		
		
		layerList = [[[CCLayer alloc] init] autorelease];
		layerList.contentSize = CGSizeMake(self.contentSize.width, listHeight);
		
		for (int i = 0; i < items.count; i++) {
			CCLayer *layer = [items objectAtIndex:i];
            if (iPhoneRuningOnGame()) {
				layer.position = ccp(16, layerList.contentSize.height-(i+1)*(height+offsetHeight));
            }else{
                layer.position = ccp(14, layerList.contentSize.height-(i+1)*(height+offsetHeight));
            }
			[layerList addChild:layer];
		}
		
		CCPanel *listPanel = [CCPanel panelWithContent:layerList viewSize:CGSizeMake(layerList.contentSize.width, self.contentSize.height-2)];
		[listPanel updateContentToTop];
		listPanel.tag = 123;
        listPanel.position = ccp(0, 1);
        
		[self addChild:listPanel];
        
	}else{
		[taskDetail setTask:nil];
	}
	
}

-(void)selected:(CCArray *)_array :(TaskDetailMenuItem *)_item
{
    if (isTaskButtonTouch) {
        return;
    }
    isTaskButtonTouch = YES;
    //
	TaskDetailMenuItem *item = nil;
	CCARRAY_FOREACH(_array, item) {
		[item setMenuSelected:NO];
	}
	[_item setMenuSelected:YES];
	
	[taskDetail setTask:[_item getTask]];
    //
    isTaskButtonTouch = NO;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
	if (self.visible && CGRectContainsPoint(CGRectMake(0, 0, self.contentSize.width, self.contentSize.height), touchLocation)) {
		return YES;
	}
	return NO;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
	
	if (layerList) {
		touchLocation = [layerList convertToNodeSpace:touchLocation];
		TaskDetailMenuItem *_item;
		CCARRAY_FOREACH(layerList.children, _item) {
			if (CGRectContainsPoint(_item.boundingBox, touchLocation)) {
				[self selected:layerList.children :_item];
				break;
			}
		}
	}
}

@end

@implementation TaskDetail

-(void)draw
{
    [super draw];
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    glLineWidth(1);
	
	ccDrawRect(ccp(0, 0), ccp(_contentSize.width, _contentSize.height));
	
    //#if TARGET_IPHONE
    //        ccDrawRect(ccp(0, 0), ccp(contentSize_.width, contentSize_.height));
    //#else
    //        ccDrawRect(ccp(0, 0), ccp(contentSize_.width, contentSize_.height));
    //#endif
}

-(id)init{
	
    float w=420;
    float h=488;
    
    if (iPhoneRuningOnGame()) {
		w=463/2;
		h=549/2;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:w height:h]) {
        float fontSize=22;
        float fontSize2=16;

		if (iPhoneRuningOnGame()) {
			fontSize=13;
			fontSize2=10;
        }
		
        titleLabel = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:fontSize];
        titleLabel.anchorPoint = ccp(0, 0.5);
        if (iPhoneRuningOnGame()) {
			titleLabel.position = ccp(27/2, 505/2);
        }else{
            titleLabel.position = ccp(27, 450);
        }
        titleLabel.color = ccc3(215, 106, 53);
        [self addChild:titleLabel];
		
		mainLockLabel = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:fontSize2];
        mainLockLabel.anchorPoint = ccp(0, 0.5);
        if (iPhoneRuningOnGame()) {
			mainLockLabel.position = ccp(27/2, 505/2);
        }else{
            mainLockLabel.position = ccp(27, 450);
            
        }
        mainLockLabel.color = ccc3(255, 0, 0);
		mainLockLabel.visible = NO;
        [self addChild:mainLockLabel];
        
        CGSize size=CGSizeMake(380, 65);
        if (iPhoneRuningOnGame()) {
			size=CGSizeMake(240, 245);
        }
        
        detailLabel = [CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:fontSize2 dimensions:size hAlignment:kCCTextAlignmentLeft];
        detailLabel.anchorPoint = ccp(0, 1);
        if (iPhoneRuningOnGame()) {
			detailLabel.position = ccp(27/2, 484/2);
        }else{
            detailLabel.position = ccp(27, 425);
        }
        detailLabel.color = ccc3(236, 228, 206);
        [self addChild:detailLabel];
		
        //rewardLabel = [CCLabelTTF labelWithString:@"任务奖励：" fontName:@"Helvetica-Bold" fontSize:fontSize];
        rewardLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"task_award",nil) fontName:@"Helvetica-Bold" fontSize:fontSize];
        rewardLabel.anchorPoint = ccp(0, 0.5);
        if (iPhoneRuningOnGame()) {
            rewardLabel.position = ccp(27/2, 214/2);
        }else{
            rewardLabel.position = ccp(27, 214);
        }
        rewardLabel.color = ccc3(215, 106, 53);
        [self addChild:rewardLabel];
        //fix chao
        //NSArray *findRoadBtns = getBtnSpriteForScale(@"images/ui/button/bt_background.png",1.1f);
		NSArray *findRoadBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_autodo");
		
        CCMenuItemImage *findRoadMenuItem = [CCMenuItemImage itemWithNormalSprite:[findRoadBtns objectAtIndex:0]
                                                                   selectedSprite:[findRoadBtns objectAtIndex:1]
                                                                   disabledSprite:nil
                                                                           target:self
                                                                         selector:@selector(findRoadTapped)];
        if (iPhoneRuningOnGame()) {
			findRoadMenuItem.scale=1.3f;
            findRoadMenuItem.position = ccp(215/2, 68/2);
        }else{
            findRoadMenuItem.position = ccp(215, 68);
        }
        findRoadMenu = [CCMenu menuWithItems:findRoadMenuItem, nil];
        findRoadMenu.position = CGPointZero;
        [self addChild:findRoadMenu];
        //end
    }
    return self;
}

-(void)dealloc{
	if (task) {
		CCLOG(@"TaskDetail->delete:%d",task.taskId);
		[task release];
		task = nil ;
	}
	[super dealloc];
}

-(void)setTask:(Task*)_task{
	if (task) {
		[task release];
		task = nil ;
	}
	if (_task == nil) {
		self.visible = NO;
		return ;
	}
	
	task = _task;
	[task retain];
	
	if(task==nil){
		self.visible = NO;
		return;
	}
	self.visible = YES;
	
	NSDictionary * info = task.taskInfo;
	
	// 写入任务详细内容
    titleLabel.string = [info objectForKey:@"name"];
	
	mainLockLabel.visible = NO;
	
	// 任务还没解锁
	if (![task isUnlock]) {
		// 主线
		if (task.type == Task_Type_main) {
			
			NSDictionary *taskDict = [[GameDB shared] getTaskInfo:Task_Type_main taskId:task.taskId];
			if (taskDict) {
				NSString *condition = [taskDict objectForKey:@"unlock"];
				if (condition && condition.length > 0){
					NSArray *array = [condition componentsSeparatedByString:@"|"];
					for (NSString *iterate in array) {
						if (iterate.length > 0) {
							NSRange rang = [iterate rangeOfString:@":"];
							NSString *conditionType = [iterate substringToIndex:rang.location];
							NSString *conditionContent = [iterate substringFromIndex:rang.location+1];
							if ([conditionType isEqualToString:@"level"]) {
								NSArray *array = [conditionContent componentsSeparatedByString:@":"];
								int needLevel = [[array objectAtIndex:0] intValue];
								if (needLevel > [[GameConfigure shared] getPlayerLevel]) {
									//mainLockLabel.string = [NSString stringWithFormat:@"(主将%d级可接)", needLevel];
									mainLockLabel.string = [NSString stringWithFormat:NSLocalizedString(@"task_level",nil), needLevel];
									if(iPhoneRuningOnGame()){
										mainLockLabel.position = ccp(titleLabel.position.x + titleLabel.contentSize.width + 10/2,
																	 mainLockLabel.position.y);
									}else{
										mainLockLabel.position = ccp(titleLabel.position.x + titleLabel.contentSize.width + 10,
																	 mainLockLabel.position.y);
									}
									
									mainLockLabel.visible = YES;
								}
								break;
							}
						}
					}
				}
			}
		}
		else {
            
		}
		
		findRoadMenu.visible = NO;
	} else {
		findRoadMenu.visible = YES;
	}
	
	detailLabel.string = [info objectForKey:@"info"];
	detailLabel.color = ccc3(236, 228, 206);
	
    //acceptNPCLabel.string = [NSString stringWithFormat:@"接取任务NPC：%@", @"小龙女"];
	//doneNPCLabel.string = [NSString stringWithFormat:@"完成任务NPC：%@", @"小龙女"];
	
	for(int i=0;i<6;i++){
		CCNode * node = [self getChildByTag:(1000+i)];
		if(node) [node removeFromParentAndCleanup:YES];
	}
    
	//WHT ??????
	int rid = [[info objectForKey:@"rid"] intValue];
	NSDictionary * rewardInfo = [[GameDB shared] getRewardInfo:rid];
	if(rewardInfo){
		NSError * error = nil;
		NSData * data = getDataFromString([rewardInfo objectForKey:@"reward"]);
		NSDictionary * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
		if(!error){
			NSMutableArray * adds = [NSMutableArray array];
			for(NSDictionary * reward in rewards){
				NSString * t = [reward objectForKey:@"t"];
				int i = [[reward objectForKey:@"i"] intValue];
				if([t isEqualToString:@"i"] && i<=6){
					[adds addObject:reward];
				}
			}
			
			CGPoint orginPoint = ccp(27, 180);
            if (iPhoneRuningOnGame()) {
                orginPoint=ccp(orginPoint.x/2, orginPoint.y/2);
            }
			float offsetY = -27;
            if (iPhoneRuningOnGame()) {
                offsetY/=2;
            }
			for(int j=0;j<[adds count];j++){
				NSDictionary * reward = [adds objectAtIndex:j];
				int i = [[reward objectForKey:@"i"] intValue];
				int c = [[reward objectForKey:@"c"] intValue];
				
				GameMoney * gm = [GameMoney node];
				[self addChild:gm z:100 tag:(1000+j)];
				
				gm.anchorPoint = ccp(0, 0.5);
				gm.position = ccp(orginPoint.x, orginPoint.y+j*offsetY);
				[gm setMoneyValue:i :c];
			}
		}
	}
}

-(void)findRoadTapped{
    if (isTaskButtonTouch) {
        return;
    }
    isTaskButtonTouch = YES;
    
	[[Window shared] removeWindow:PANEL_TASK];
	[[TaskManager shared] checkTask:task.userTaskId];
}

@end

@interface TaskOfferItem : CCLayerColor
{
	CCMenu *menu;
	NSObject<TaskOfferItemDelegate> *delegate_;
}
@property (nonatomic) int taskId;
@property (nonatomic) int index;
@property (nonatomic) Task_Status taskStatus;
@property(readwrite, assign)NSObject <TaskOfferItemDelegate> *delegate;
-(void)setMenuEnable:(BOOL)isEnable;	// 设置按钮是否可用（彩色，灰色）
-(void)setDone;		// 设置已完成该任务
@end



//任务列表项

@implementation TaskOfferItem
@synthesize taskId;
@synthesize index;
@synthesize taskStatus;
@synthesize delegate = delegate_;

-(void)onEnter
{
	[super onEnter];
	
	// 新手教程
	if (self.index == 3) {
		if (menu) {
			CCNode *node = [menu getChildByTag:OfferDetailGet];
			if (node) {
                
				[[Intro share] runIntroTager:node step:INTRO_MMission_Step_1];
			}
		}
	}
    //    showNode(self);
}

-(id)initWithQuality:(ItemQuality)quality taskId:(int)tid status:(TaskStatus)status exp:(int)exp
{
	if (self = [super init]) {
        //项的底图
		CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p21.png"];
		bg.anchorPoint = CGPointZero;
        if (iPhoneRuningOnGame()) {
			bg.scaleX=1.14f;
			bg.scaleY=1.13f;
        }
		self.contentSize = bg.contentSize;
		[self addChild:bg z:-1];
		
		self.taskId = tid;
		
		CCSprite *iconBg = nil;
		int iconId = 0 ;;
		switch (quality) {
			case IQ_WHITE:
				//iconId = [[GameConfigure shared] getItemIdByName:@"低级兵符"];
                iconId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"task_low_symbol",nil)];
				iconBg = [CCSprite spriteWithFile:@"images/ui/panel/p22.png"];
				break;
			case IQ_GREEN:
				//iconId = [[GameConfigure shared] getItemIdByName:@"低级兵符"];
                iconId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"task_low_symbol",nil)];
				iconBg = [CCSprite spriteWithFile:@"images/ui/panel/p23.png"];
				break;
			case IQ_BLUE:
				//iconId = [[GameConfigure shared] getItemIdByName:@"中级兵符"];
                iconId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"task_middle_symbol",nil)];
				iconBg = [CCSprite spriteWithFile:@"images/ui/panel/p24.png"];
				break;
			case IQ_PURPLE:
				//iconId = [[GameConfigure shared] getItemIdByName:@"高级兵符"];
                iconId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"task_height_symbol",nil)];
				iconBg = [CCSprite spriteWithFile:@"images/ui/panel/p25.png"];
				break;
				
			default:
				break;
		}
		if (iconBg) {
            if (iPhoneRuningOnGame()) {
				iconBg.position = ccp(38/2, 44/2);
            }else{
                iconBg.position = ccp(38, 38);
            }
			[self addChild:iconBg];
		}
        
		CCSprite *icon = getItemIcon(iconId);
		if (icon) {
            if (iPhoneRuningOnGame()) {
				iconBg.position = ccp(38/2, 44/2);
            }else{
                icon.position = ccp(38, 38);
            }
			[self addChild:icon];
		}
        //项字体大小
        float fontSize=18;
        float fontSize2=15;
		if (iPhoneRuningOnGame()) {
			fontSize=10;
			fontSize2=8.5f;
		}
        
		NSDictionary *taskDict = [[GameDB shared] getTaskInfo:Task_Type_offer taskId:tid];
		if (taskDict) {
			NSString *taskName = [taskDict objectForKey:@"name"];
			CCLabelTTF *taskNameLabel = [CCLabelTTF labelWithString:taskName fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			taskNameLabel.color = getColorByQuality(quality);
			taskNameLabel.anchorPoint = ccp(0, 0.5);
            if (iPhoneRuningOnGame()) {
				taskNameLabel.position = ccp(82/2, 66/2);
            }else{
                taskNameLabel.position = ccp(80, 60);
            }
			[self addChild:taskNameLabel];
			
			NSString *taskInfo = [taskDict objectForKey:@"info"];
            CGSize dimenSize=CGSizeMake(131, 43);
            if (iPhoneRuningOnGame()) {
				dimenSize=CGSizeMake(153/2.0f, 43/2.0f);
            }
			CCLabelTTF *taskInfoLabel = [CCLabelTTF labelWithString:taskInfo fontName:getCommonFontName(FONT_1) fontSize:fontSize2 dimensions:dimenSize hAlignment:kCCTextAlignmentLeft];
			taskInfoLabel.color = ccc3(54, 15, 6);
			taskInfoLabel.anchorPoint = ccp(0, 1);
            if (iPhoneRuningOnGame()) {
				taskInfoLabel.position = ccp(82/2, 54/2);
            }else{
                taskInfoLabel.position = ccp(80, 47);
            }
			[self addChild:taskInfoLabel];
			
			//CCLabelTTF *rewardLabel = [CCLabelTTF labelWithString:@"奖励" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
            CCLabelTTF *rewardLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"task_reward_text",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			rewardLabel.color = ccc3(238, 228, 208);
			rewardLabel.anchorPoint = ccp(0, 0.5);
            if (iPhoneRuningOnGame()) {
				rewardLabel.position = ccp(265/2, 66/2);
            }else{
                rewardLabel.position = ccp(232, 60);
            }
			[self addChild:rewardLabel];
			//CCLabelTTF *rewardTitle = [CCLabelTTF labelWithString:@"积分：\n经验：\n" fontName:getCommonFontName(FONT_1) fontSize:fontSize2 dimensions:dimenSize hAlignment:kCCTextAlignmentLeft];
            CCLabelTTF *rewardTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"task_mark_exp",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize2 dimensions:dimenSize hAlignment:kCCTextAlignmentLeft];
			rewardTitle.color = ccc3(54, 15, 6);
			rewardTitle.anchorPoint = ccp(0, 1);
            if (iPhoneRuningOnGame()) {
				rewardTitle.position = ccp(265/2, 53/2);
            }else{
                rewardTitle.position = ccp(232, 47);
            }
			[self addChild:rewardTitle];
			
			// Quality获取对应积分
			NSString *typeExpString = [[[GameDB shared] getGlobalConfig] objectForKey:@"bfTypeExp"];
			NSArray *typeExp = [typeExpString componentsSeparatedByString:@"|"];
			int grade = [[typeExp objectAtIndex:quality] intValue];
			if (exp == 0) {
				// 奖励id
				int rid = 0;
				NSDictionary *bfTaskDict = [[GameDB shared] getBFTaskInfo:tid q:quality];
				if (bfTaskDict) {
					rid = [[bfTaskDict objectForKey:@"rid"] intValue];
				}
				NSDictionary *rewardDict = [[GameDB shared] getRewardInfo:rid];
				if (rewardDict) {
					NSError *error = nil;
					NSData *data = getDataFromString([rewardDict objectForKey:@"reward"]);
					NSDictionary * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
					if (!error) {
						for(NSDictionary * reward in rewards){
							NSString * t = [reward objectForKey:@"t"];
							int i = [[reward objectForKey:@"i"] intValue];
							if([t isEqualToString:@"i"] && (i==5||i==4)){
								// 返回分钟数
								int count = [[reward objectForKey:@"c"] intValue];
								// 玩家每分钟打坐经验
								int playerLevel = [[GameConfigure shared] getPlayerLevel];
								NSDictionary *roleExpDict = [[GameDB shared] getRoleExpInfo:playerLevel];
								if (roleExpDict) {
									int expCount = [[roleExpDict objectForKey:@"siteExp"] intValue];
									exp = expCount * count;
								}
							}
						}
					}
				}
			}
			
			CCLabelTTF *rewardValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d\n%d", grade, exp] fontName:getCommonFontName(FONT_1) fontSize:fontSize2 dimensions:CGSizeMake(131, 43) hAlignment:kCCTextAlignmentLeft];
			rewardValueLabel.color = ccc3(254, 249, 109);
			rewardValueLabel.anchorPoint = ccp(0, 1);
            if (iPhoneRuningOnGame()) {
                    rewardValueLabel.position = ccp(310/2, 53/2);
            }else{
                rewardValueLabel.position = ccp(278, 47);
            }
			[self addChild:rewardValueLabel];
			
			NSDictionary *playerDict = [[GameConfigure shared] getPlayerInfo];
			int playerVip = [[playerDict objectForKey:@"vip"] intValue];
			taskStatus = status;
			// 已完成
			if (taskStatus == TaskStatus_Done_Accept) {
				CCSprite *doneSprite = [CCSprite spriteWithFile:@"images/ui/panel/p26.png"];
                if (iPhoneRuningOnGame()) {
					doneSprite.position = ccp(550/2, 44/2);
                }else{
                    doneSprite.position = ccp(475, 38);
                }
				[self addChild:doneSprite];
			} else {
				menu = [CCMenu menuWithItems:nil];
				menu.position = CGPointZero;
				[self addChild:menu];
				
				NSArray *gets = getBtnSpriteWithStatus(@"images/ui/button/bts_get");
				CCMenuItemSprite *getMenuItem = [CCMenuItemSprite itemWithNormalSprite:[gets objectAtIndex:0]
																		selectedSprite:[gets objectAtIndex:1]
																				target:self
																			  selector:@selector(menuCallback:)];
				getMenuItem.tag = OfferDetailGet;
				[menu addChild:getMenuItem];
				
				int needVip = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfFinishVip"] intValue];
				if (needVip > playerVip) {//不是vip
                    if(iPhoneRuningOnGame()){
						getMenuItem.scale=1.3f;
                            getMenuItem.position = ccp(550/2.0f, 44/2.0f);
                    }else{
                        getMenuItem.position = ccp(480, 38);
                    }
				}
				else {
                    if (iPhoneRuningOnGame()) {
						getMenuItem.scale=1.3f;
						getMenuItem.position = ccp(600/2, 44/2);
                    }else{
                        getMenuItem.position = ccp(526, 38);
					}
					//直接完成,vip4级以上才出来
					NSArray *dones = getBtnSpriteWithStatus(@"images/ui/button/bts_done");
					CCMenuItemSprite *doneMenuItem = [CCMenuItemSprite itemWithNormalSprite:[dones objectAtIndex:0]
																			 selectedSprite:[dones objectAtIndex:1]
																					 target:self
																				   selector:@selector(menuCallback:)];
					doneMenuItem.tag = OfferDetailDone;
                    if (iPhoneRuningOnGame()) {
						doneMenuItem.scale=1.3f;
						doneMenuItem.position = ccp(495/2.0f, 44/2.0f);
                    }else{
                        doneMenuItem.position = ccp(434, 38);
                    }
					[menu addChild:doneMenuItem];
				}
			}
		}
	}
	return self;
}

-(void)menuCallback:(id)sender
{
    if(isTaskButtonTouch || (s_taskPanelType != Task_Type_offer)){
        return;
    }
    isTaskButtonTouch = YES;
    
	CCMenuItem *menuItem = sender;
	// 领取
	if (menuItem.tag == OfferDetailGet) {
		if (delegate_ && [delegate_ respondsToSelector:@selector(menuItemTapped:taskId:index:)]) {
			[delegate_ menuItemTapped:sender taskId:taskId index:index];
		}
	}
	// 直接完成
	else if (menuItem.tag == OfferDetailDone) {
		if (delegate_ && [delegate_ respondsToSelector:@selector(menuItemTapped:taskId:index:)]) {
			[delegate_ menuItemTapped:sender taskId:taskId index:index];
		}
	}
    //
    //isTaskButtonTouch = NO;
}

// YES为菜单可点击
-(void)setMenuEnable:(BOOL)isEnable
{
	if (!menu || menu.touchEnabled == isEnable) {
		return;
	}
	
	menu.touchEnabled = isEnable;
	// 领取任务
	CCMenuItemSprite *getMenuItem = (CCMenuItemSprite *)[menu getChildByTag:OfferDetailGet];
	if (getMenuItem) {
		CGPoint point = getMenuItem.position;
		[menu removeChild:getMenuItem cleanup:YES];
		getMenuItem = nil;
		
		NSArray *btns = isEnable ? getBtnSpriteWithStatus(@"images/ui/button/bts_get") :
        getDisableBtnSpriteWithStatus(@"images/ui/button/bts_get");
		
		CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(menuCallback:)];
		menuItem.tag = OfferDetailGet;
		if (iPhoneRuningOnGame()) {
			menuItem.scale=1.3f;
		}
		menuItem.position = point;
		[menu addChild:menuItem];
	}
	// 直接完成
	CCMenuItemSprite *doneMenuItem = (CCMenuItemSprite *)[menu getChildByTag:OfferDetailDone];
	if (doneMenuItem) {
		CGPoint point = doneMenuItem.position;
		[menu removeChild:doneMenuItem cleanup:YES];
		doneMenuItem = nil;
		
		NSArray *btns = isEnable ? getBtnSpriteWithStatus(@"images/ui/button/bts_done") :
        getDisableBtnSpriteWithStatus(@"images/ui/button/bts_done");
		
		CCMenuItemSprite *menuItem = [CCMenuItemSprite itemWithNormalSprite:[btns objectAtIndex:0]
															 selectedSprite:[btns objectAtIndex:1]
																	 target:self
																   selector:@selector(menuCallback:)];
		menuItem.tag = OfferDetailDone;
		if (iPhoneRuningOnGame()) {
			menuItem.scale=1.3f;
		}
		menuItem.position = point;
		[menu addChild:menuItem];
	}
}

-(void)setDone
{
	if (taskStatus == TaskStatus_Done_Accept) {
		return;
	}
	
	if (menu) {
		[menu removeFromParentAndCleanup:YES];
		menu = nil;
	}
	
	CCSprite *doneSprite = [CCSprite spriteWithFile:@"images/ui/panel/p26.png"];
	doneSprite.position = ccp(475, 36);
	[self addChild:doneSprite];
	
	taskStatus = TaskStatus_Done_Accept;
}

@end


//右边领取任务面板
@implementation TaskOfferPanel
@synthesize needLoad;
-(void)draw{
    [super draw];
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    glLineWidth(1);
    ccDrawRect(ccp(0, 0), ccp(self.contentSize.width, self.contentSize.height));
}

-(id)init
{
	selectedIndex = -1;
    float w=621;
    float h=488;
    if (iPhoneRuningOnGame()) {
        h=549/2;
		w=700/2;
    }
	if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:w height:h]) {
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
	
	firstCountDown = YES;
	
	needLoad = YES;
	offerItems = [NSMutableArray array];
	[offerItems retain];
    
    float fontSize=15;
	if (iPhoneRuningOnGame()) {
		fontSize/=2.0f;
	}
	
	// 下次刷新
	//refreshTimeTitle = [CCLabelTTF labelWithString:@"距离下次刷新" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    refreshTimeTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"task_next_flash",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	refreshTimeTitle.color = ccc3(238, 228, 207);
	refreshTimeTitle.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
            refreshTimeTitle.position = ccp(21/2, 524/2);
    }else{
        refreshTimeTitle.position = ccp(21, 473);
    }
	refreshTimeTitle.visible = NO;
	[self addChild:refreshTimeTitle];
	
	refreshTimeLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	refreshTimeLabel.color = ccc3(254, 243, 114);
	refreshTimeLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
		refreshTimeLabel.position = ccp(125/2, 524/2);
    }else{
        refreshTimeLabel.position = ccp(125, 473);
    }
	refreshTimeLabel.visible = NO;
	[self addChild:refreshTimeLabel];
	
	// 今日可完成悬赏次数
	//CCLabelTTF *offerCountTitle = [CCLabelTTF labelWithString:@"今日可打开宝箱次数：" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *offerCountTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"task_open_count",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	offerCountTitle.color = ccc3(238, 228, 207);
	offerCountTitle.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
//        offerCountTitle.scale=FONT_SIZE_SCALE;
        offerCountTitle.position = ccp(126/2, 110/2);
    }else{
        offerCountTitle.position = ccp(126, 110);
    }
	[self addChild:offerCountTitle];
	
	offerCountLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	offerCountLabel.color = ccc3(254, 243, 114);
	offerCountLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
//        offerCountLabel.scale=FONT_SIZE_SCALE;
        offerCountLabel.position = ccp(281/2, 110/2);
    }else{
        offerCountLabel.position = ccp(281, 110);
    }
	[self addChild:offerCountLabel];
	
	// 当前积分
	//CCLabelTTF *offerScoreTitle = [CCLabelTTF labelWithString:@"当前积分：" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *offerScoreTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"task_now_mark",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	offerScoreTitle.color = ccc3(238, 228, 207);
	offerScoreTitle.anchorPoint = ccp(1, 0.5);
//    if (iPhoneRuningOnGame()) {
//        offerScoreTitle.scale=FONT_SIZE_SCALE;
//    }
    if (iPhoneRuningOnGame()) {
        offerScoreTitle.position = ccpAdd(offerCountTitle.position, ccp(offerCountTitle.contentSize.width/2, -25/2));
    }else{
        offerScoreTitle.position = ccpAdd(offerCountTitle.position, ccp(offerCountTitle.contentSize.width, -25));
    }[self addChild:offerScoreTitle];
	
	offerScoreLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	offerScoreLabel.color = ccc3(254, 243, 114);
	offerScoreLabel.anchorPoint = ccp(0, 0.5);
//    if (iPhoneRuningOnGame()) {
//        offerScoreLabel.scale=FONT_SIZE_SCALE;
//    }
    if (iPhoneRuningOnGame()) {
        offerScoreLabel.position = ccpAdd(offerCountLabel.position, ccp(0, -25/2.0f));
    }else{
        offerScoreLabel.position = ccpAdd(offerCountLabel.position, ccp(0, -25));
    }
	[self addChild:offerScoreLabel];
	
	// 剩余免费刷新
	//refreshCountTitle = [CCLabelTTF labelWithString:@"剩余免费刷新次数：" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    refreshCountTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"task_free_count",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	refreshCountTitle.color = ccc3(238, 228, 207);
	refreshCountTitle.anchorPoint = ccp(0, 0.5);
	if (iPhoneRuningOnGame()) {
		refreshCountTitle.position = ccp(510/2.0f, 110/2.0f);
    }else{
        refreshCountTitle.position = ccp(442, 110);
    }
	[self addChild:refreshCountTitle];
	
	refreshCountLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	refreshCountLabel.color = ccc3(254, 243, 114);
	refreshCountLabel.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
		refreshCountLabel.position = ccp(645/2.0f, 110/2.0f);
    }else{
    	refreshCountLabel.position = ccp(578, 110);
    }
	[self addChild:refreshCountLabel];
	
	// 宝箱经验
	CCSprite *boxBg = [CCSprite spriteWithFile:@"images/ui/panel/t43.png"];
    if (iPhoneRuningOnGame()) {
        boxBg.position = ccp(73/2.0f, 64/2.0f);
    }else{
        boxBg.position = ccp(73, 64);
    }
	[self addChild:boxBg];
	CCSprite *boxFore = [CCSprite spriteWithFile:@"images/ui/panel/t44.png"];
	boxFore.position = boxBg.position;
	[self addChild:boxFore z:10];
	
	// 宝箱
	CCSprite *boxSprite = [CCSprite spriteWithFile:@"images/ui/panel/t59.png"];
    if (iPhoneRuningOnGame()) {
        boxSprite.position = ccpAdd(boxBg.position, ccp(3/2.0f, 13/2.0f));
    }else{
        boxSprite.position = ccpAdd(boxBg.position, ccp(3, 13));
    }
	[self addChild:boxSprite];
	
	boxNeedExp = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfBoxNeedExp"] intValue];
	/*
	// 悬赏规则
	RuleButton *ruleButton = [RuleButton node];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            ruleButton.position = ccp(772/2, 530/2);
        }else{
            ruleButton.position = ccp(643/2, 530/2);
        }
    }else{
    	ruleButton.position = ccp(572, 476);
    }
	ruleButton.type = RuleType_offerTask;
	[self addChild:ruleButton];
	*/
	// 一键全紫
	CCSimpleButton *purpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_allpurple_1.png"
														   select:@"images/ui/button/bt_allpurple_2.png"
														   target:self
															 call:@selector(menuCallback:)];
	purpleButton.tag = OfferDetailAllPurple;
    if (iPhoneRuningOnGame()) {
		purpleButton.scale=1.3f;
		purpleButton.position = ccp(410/2.0f, 36/2.0f);
    }else{
        purpleButton.position = ccp(386, 36);
    }
	purpleButton.visible = NO;
	[self addChild:purpleButton];
	
	CCSimpleButton *disPurpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_allpurple_3.png"
															  select:@"images/ui/button/bt_allpurple_3.png"
															  target:self
																call:@selector(menuCallback:)];
	disPurpleButton.tag = OfferDetailAllPurpleDisable;
    if (iPhoneRuningOnGame()) {
		disPurpleButton.scale=1.3f;
		disPurpleButton.position = ccp(410/2.0f, 36/2.0f);
    }else{
        disPurpleButton.position = ccp(386, 36);
    }
	disPurpleButton.visible = NO;
	[self addChild:disPurpleButton];
	
	
	// 免费刷新
	CCSimpleButton *refreshButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_refresh_1.png"
															select:@"images/ui/button/bt_refresh_2.png"
															target:self
															  call:@selector(menuCallback:)];
	refreshButton.tag = OfferDetailRefresh;
    if (iPhoneRuningOnGame()) {
		refreshButton.scale=1.3f;
		refreshButton.position = ccp(590/2.0f, 36/2.0f);
    }else{
        refreshButton.position = ccp(532, 36);
    }
	refreshButton.visible = NO;
	[self addChild:refreshButton];
	
	CCSimpleButton *disRefreshButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_refresh_3.png"
															   select:@"images/ui/button/bt_refresh_3.png"
															   target:self
																 call:@selector(menuCallback:)];
	disRefreshButton.tag = OfferDetailRefreshDisable;
    if (iPhoneRuningOnGame()) {
		disRefreshButton.scale=1.3f;
		disRefreshButton.position = ccp(590/2.0f, 36/2.0f);
    }else{
        disRefreshButton.position = ccp(532, 36);
    }
	disRefreshButton.visible = NO;
	[self addChild:disRefreshButton];
	
	// 元宝刷新
	CCSimpleButton *goldButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gold_refresh_1.png"
														 select:@"images/ui/button/bt_gold_refresh_2.png"
														 target:self
														   call:@selector(menuCallback:)];
	goldButton.tag = OfferDetailGoldRefresh;
    if (iPhoneRuningOnGame()) {
		goldButton.scale=1.3f;
		goldButton.position = ccp(590/2.0f, 36/2.0f);
    }else{
    	goldButton.position = ccp(532, 36);
    }
	goldButton.visible = NO;
	[self addChild:goldButton];
	
	CCSimpleButton *disGoldButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gold_refresh_3.png"
															select:@"images/ui/button/bt_gold_refresh_3.png"
															target:self
															  call:@selector(menuCallback:)];
	disGoldButton.tag = OfferDetailGoldRefreshDisable;
    if (iPhoneRuningOnGame()) {
		disGoldButton.scale=1.3f;
		disGoldButton.position = goldButton.position;
    }else{
        disGoldButton.position =goldButton.position;
    }
	disGoldButton.visible = NO;
	[self addChild:disGoldButton];
	
}

-(void)setExp:(int)exp
{
	CCNode *node = [self getChildByTag:123];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	
	exp = MIN(boxNeedExp, exp);
	if (exp > 0) {
		int iconNum = 44 + exp;
		CCSprite *sprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/panel/t%d.png", iconNum]];
		sprite.tag = 123;
        if (iPhoneRuningOnGame()) {
            sprite.position = ccp(73/2.0f, 64/2.0f);
        }else{
            sprite.position = ccp(73, 64);
        }
		[self addChild:sprite z:5];
	}
	offerScoreLabel.string = [NSString stringWithFormat:@"%d/%d", exp, boxNeedExp];
}

-(void)menuCallback:(id)sender
{
	// 打开悬赏任务面板时有效
	if (!self.visible) {
		return;
	}
	if (isTaskButtonTouch || (s_taskPanelType != Task_Type_offer)) {
        return;
    }
    isTaskButtonTouch = YES;
    
	CCSimpleButton *simpleButton = sender;
	// 一键全紫
	if (simpleButton.tag == OfferDetailAllPurple) {
		int cost = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfReAllCoin2"] intValue];
		int coin2 = [[GameConfigure shared] getPlayerCoin2];
		int coin3 = [[GameConfigure shared] getPlayerCoin3];
		// 需消耗元宝，提示
		if (coin2 + coin3 >= cost) {
			BOOL isRecordPurple = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_REFRESH_PURPLE] boolValue];
			if (isRecordPurple) {
				[self refreshWithPurple];
			} else {
				//[[AlertManager shared] showMessageWithSettingFormFather:[NSString stringWithFormat:@"一键全紫需消耗 %d 元宝", cost] target:self confirm:@selector(refreshWithPurple) key:NO_REMIND_REFRESH_PURPLE father:self.parent];
                [[AlertManager shared] showMessageWithSettingFormFather:[NSString stringWithFormat:NSLocalizedString(@"task_all_purple",nil), cost] target:self confirm:@selector(refreshWithPurple) key:NO_REMIND_REFRESH_PURPLE father:self.parent];
			}
		}
		// 绑元宝+元宝不足，提示元宝不足
		else {
			//[ShowItem showItemAct:@"元宝不足"];
            [ShowItem showItemAct:NSLocalizedString(@"task_no_yuanbao",nil)];
		}
	}
	// 免费刷新
	else if (simpleButton.tag == OfferDetailRefresh) {
		[self refreshTaskWithType:RefreshTypeFree];
	}
	// 元宝刷新
	else if (simpleButton.tag == OfferDetailGoldRefresh) {
		int cost = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfReCoin2"] intValue];
		int coin2 = [[GameConfigure shared] getPlayerCoin2];
		int coin3 = [[GameConfigure shared] getPlayerCoin3];
		if (coin2 + coin3 >= cost) {
			BOOL isRecordGold = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_REFRESH_GOLD] boolValue];
			if (isRecordGold) {
				[self refreshWithGold];
			} else {
				//[[AlertManager shared] showMessageWithSettingFormFather:[NSString stringWithFormat:@"元宝刷新需消耗 %d 元宝", cost] target:self confirm:@selector(refreshWithGold) key:NO_REMIND_REFRESH_GOLD father:self.parent];
                [[AlertManager shared] showMessageWithSettingFormFather:[NSString stringWithFormat:NSLocalizedString(@"task_need_yuanbao",nil), cost] target:self confirm:@selector(refreshWithGold) key:NO_REMIND_REFRESH_GOLD father:self.parent];
			}
		}
		// 绑元宝+元宝不足，提示元宝不足
		else {
			//[ShowItem showItemAct:@"元宝不足"];
            [ShowItem showItemAct:NSLocalizedString(@"task_no_yuanbao",nil)];
		}
	}
	// 屏蔽
	else if (simpleButton.tag == OfferDetailAllPurpleDisable) {
        isTaskButtonTouch = NO;
		return;
	}
	else if (simpleButton.tag == OfferDetailRefreshDisable) {
        isTaskButtonTouch = NO;
		return;
	}
	else if (simpleButton.tag == OfferDetailGoldRefreshDisable) {
        isTaskButtonTouch = NO;
		return;
	}
    isTaskButtonTouch = NO;
}

-(void)menuItemTapped:(id)sender taskId:(int)tid index:(int)index
{
	// 新手教程
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_MMission_Step_1];
	
	CCMenuItem *menuItem = sender;
	if (menuItem.tag == OfferDetailDone) {
		
		// 在玩家任务列表中，立即完成
		Task *task = [[TaskManager shared] getUserTaskByTid:tid];
		if (task) {
			selectedIndex = -1;
		}
		// 不在列表，先确认是否要立即完成
		else {
			selectedIndex = index;
		}
		[self useCoinDone:selectedIndex];
		
	} else if (menuItem.tag == OfferDetailGet) {
		// 在玩家任务列表中，直接开始寻路
		Task *task = [[TaskManager shared] getUserTaskByTid:tid];
		if (task) {
            isTaskButtonTouch = NO;
			[[Window shared] removeWindow:PANEL_TASK];
			if ([TaskManager shared].runingTask != nil) {
				if ([TaskManager shared].runingTask.taskId == task.taskId) {
					[[GameUI shared] updateTaskStatus:0 taskStep:[[TaskManager shared].runingTask getStepIcon] type:[TaskManager shared].runingTask.type];
					[[TaskManager shared] executeTask];
				}else{
					//todo
					//停止主线任务，开始做悬赏
					[[TaskManager shared] startUserTask:task.userTaskId];
				}
			}else{
				[[TaskManager shared] startUserTask:task.userTaskId];
			}
		}
		// 不在列表，接任务
		else {
			NSString *tidString = [NSString stringWithFormat:@"index::%d", index];
			[GameConnection request:@"bfTaskGet" format:tidString target:self call:@selector(didAcceptTask:)];
		}
        //
        //isTaskButtonTouch = NO;
	}
}

// 接任务，自动寻路
-(void)didAcceptTask:(id)sender
{
    //
    isTaskButtonTouch = NO;
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			NSDictionary *newTask = [dict objectForKey:@"task"];
			int newTaskId = [[newTask objectForKey:@"id"] intValue];
			
			[[GameConfigure shared] addNewUserTasks:[NSArray arrayWithObject:newTask]];
			
			// 自动寻路
			[[Window shared] removeWindow:PANEL_TASK];
			
			// 更新背包
			[[GameConfigure shared] updatePackage:dict];
			
			[[TaskManager shared] reloadNewTaskList];
			[[TaskManager shared] startUserTask:newTaskId];
			
			// 屏蔽刷新按钮
			[self setRefreshDisable:refreshCount];
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

// 接任务，按下立即完成
-(void)didAcceptDoneTask:(id)sender :(NSDictionary *)_data
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			NSDictionary *newTask = [dict objectForKey:@"task"];
			[[GameConfigure shared] addNewUserTasks:[NSArray arrayWithObject:newTask]];
			
			[[TaskManager shared] reloadNewTaskList:NO];
			
			// 设置其他为灰色
			int index = [[_data objectForKey:@"index"] intValue];
			for (TaskOfferItem *taskOfferItem in offerItems) {
				BOOL enable = taskOfferItem.index == index;
				[taskOfferItem setMenuEnable:enable];
			}
			
			// 屏蔽刷新按钮
			[self setRefreshDisable:refreshCount];
			
			// 更新背包
			[[GameConfigure shared] updatePackage:dict];
			
			[[GameConfigure shared] markPlayerProperty];
			// 调用立即完成
			[GameConnection request:@"bfTaskFinish" data:[NSDictionary dictionary] target:self call:@selector(didDoneTask:)];
		}
	}else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

// isGet，-1=已接该任务，0-3=准备要接任务的索引
-(void)useCoinDone:(int)_index
{
	int costCoin = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfFinishCoin1"] intValue];
	
	SEL selector;
	if (_index == -1) {
		selector = @selector(useCoinDoneConfirm);
	} else {
		selector = @selector(useCoinDoneConfirm2);
	}
	
	//[[AlertManager shared] showMessage:[NSString stringWithFormat:@"你确认使用 %d 银币立即完成该任务吗？", costCoin] target:self confirm:selector canel:nil father:self.parent];
    [[AlertManager shared] showMessage:[NSString stringWithFormat:NSLocalizedString(@"task_sure_use_money",nil), costCoin] target:self confirm:selector canel:@selector(useCoinDoneCanel) father:self.parent];
}
-(void)useCoinDoneCanel{
    //
    isTaskButtonTouch = NO;
}
// 立即完成（任务已接，直接完成任务）
-(void)useCoinDoneConfirm
{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	if (dict) {
		int coin = [[dict objectForKey:@"coin1"] intValue];
		int costCoin = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfFinishCoin1"] intValue];
		if (coin < costCoin) {
			//[ShowItem showItemAct:@"银币不足"];
            [ShowItem showItemAct:NSLocalizedString(@"task_no_money",nil)];
		} else {
			[[GameConfigure shared] markPlayerProperty];
			[GameConnection request:@"bfTaskFinish" data:[NSDictionary dictionary] target:self call:@selector(didDoneTask:)];
		}
	}
    //
    isTaskButtonTouch = NO;
}

// 立即完成（要先接任务，后再直接完成任务）
-(void)useCoinDoneConfirm2
{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	if (dict) {
		int coin = [[dict objectForKey:@"coin1"] intValue];
		int costCoin = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfFinishCoin1"] intValue];
		if (coin < costCoin) {
			//[ShowItem showItemAct:@"银币不足"];
            [ShowItem showItemAct:NSLocalizedString(@"task_no_money",nil)];
		} else {
			NSDictionary *indexDict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", selectedIndex] forKey:@"index"];
			NSString *tidString = [NSString stringWithFormat:@"index::%d", selectedIndex];
			[GameConnection request:@"bfTaskGet" format:tidString target:self call:@selector(didAcceptDoneTask::) arg:indexDict];
		}
	}
    //
    isTaskButtonTouch = NO;
}

// 立即完成任务回调
-(void)didDoneTask:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			needLoad = YES;
			[[TaskManager shared] stopAllOfferTask];
			[[GameConfigure shared] updatePackage:dict];
			[[TaskManager shared] amendTheTaskIcon];
			
			// 开放刷新按钮
			[self setRefreshDisable:refreshCount];
		}
	}else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(void)refreshWithPurple
{
	[self refreshTaskWithType:RefreshTypePurple];
}

-(void)refreshWithGold
{
	[self refreshTaskWithType:RefreshTypeGold];
}

// 更新刷新按钮(免费、元宝)
-(void)setRefreshWithFreeCount:(int)freeCount
{
	CCNode *purple = [self getChildByTag:OfferDetailAllPurple];
	if (purple) {
		purple.visible = YES;
	}
	CCNode *disPurple = [self getChildByTag:OfferDetailAllPurpleDisable];
	if (disPurple) {
		disPurple.visible = NO;
	}
	CCNode *free = [self getChildByTag:OfferDetailRefresh];
	if (free) {
		free.visible = freeCount > 0;
	}
	CCNode *disFree = [self getChildByTag:OfferDetailRefreshDisable];
	if (disFree) {
		disFree.visible = NO;
	}
	CCNode *gold = [self getChildByTag:OfferDetailGoldRefresh];
	if (gold) {
		gold.visible = freeCount <= 0;
	}
	CCNode *disGold = [self getChildByTag:OfferDetailGoldRefreshDisable];
	if (disGold) {
		disGold.visible = NO;
	}
}

// 刷新按钮灰色
-(void)setRefreshDisable:(int)freeCount
{
	CCNode *purple = [self getChildByTag:OfferDetailAllPurple];
	if (purple) {
		purple.visible = NO;
	}
	CCNode *disPurple = [self getChildByTag:OfferDetailAllPurpleDisable];
	if (disPurple) {
		disPurple.visible = YES;
	}
	CCNode *free = [self getChildByTag:OfferDetailRefresh];
	if (free) {
		free.visible = NO;
	}
	CCNode *disFree = [self getChildByTag:OfferDetailRefreshDisable];
	if (disFree) {
		disFree.visible = freeCount > 0;
	}
	CCNode *gold = [self getChildByTag:OfferDetailGoldRefresh];
	if (gold) {
		gold.visible = NO;
	}
	CCNode *disGold = [self getChildByTag:OfferDetailGoldRefreshDisable];
	if (disGold) {
		disGold.visible = freeCount <= 0;
	}
}

// 打开宝箱次数为0时，隐藏刷新按钮
-(void)setRefreshDisable
{
	CCNode *purple = [self getChildByTag:OfferDetailAllPurple];
	if (purple) {
		purple.visible = NO;
	}
	CCNode *disPurple = [self getChildByTag:OfferDetailAllPurpleDisable];
	if (disPurple) {
		disPurple.visible = NO;
	}
	CCNode *free = [self getChildByTag:OfferDetailRefresh];
	if (free) {
		free.visible = NO;
	}
	CCNode *disFree = [self getChildByTag:OfferDetailRefreshDisable];
	if (disFree) {
		disFree.visible = NO;
	}
	CCNode *gold = [self getChildByTag:OfferDetailGoldRefresh];
	if (gold) {
		gold.visible = NO;
	}
	CCNode *disGold = [self getChildByTag:OfferDetailGoldRefreshDisable];
	if (disGold) {
		disGold.visible = NO;
	}
}

-(void)addFreeRefreshCountDown
{
	if (!refreshTimeTitle.visible) {
		refreshTimeTitle.visible = YES;
	}
	if (!refreshTimeLabel.visible) {
		refreshTimeLabel.visible = YES;
	}
	
	addSeconds--;
	refreshTimeLabel.string = getFormatTimeWithSeconds(addSeconds);
	if (addSeconds == 0) {
		firstCountDown = NO;
		
		refreshTimeTitle.visible = NO;
		refreshTimeLabel.visible = NO;
		[self unschedule:@selector(addFreeRefreshCountDown)];
		
		// 添加了一次免费刷新次数，重载面板
		[self loadDataByServer];
	}
}

-(void)loadDataByServer
{
	// 进入兵符任务数据
	[GameConnection request:@"bfTaskEnter" data:[NSDictionary dictionary] target:self call:@selector(didOfferTaskEnter:)];
}

-(void)didOfferTaskEnter:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			// 是否得到宝箱
			int getBox = [[dict objectForKey:@"isBox"] intValue];
			if (getBox > 0 && needLoad) {
				if (self.parent && [self.parent respondsToSelector:@selector(setRewardBox)]) {
					[self.parent performSelector:@selector(setRewardBox)];
				}
			}
			
			needLoad = NO;
			
			// 当前宝箱经验
			int exp = [[dict objectForKey:@"exp"] intValue];
			[self setExp:exp];
			
			// 剩余打开宝箱次数，上限次数
			offerCount = [[dict objectForKey:@"boxes"] intValue];
			offerCountMax = [[dict objectForKey:@"bMax"] intValue];
			offerCountLabel.string = [NSString stringWithFormat:@"%d/%d", offerCount, offerCountMax];
			
			// 免费刷新次数
			refreshCount = [[dict objectForKey:@"n1"] intValue];
			refreshCountLabel.string = [NSString stringWithFormat:@"%d", refreshCount];
			[self setRefreshWithFreeCount:refreshCount];
			
			// 任务列表
			NSArray *taskIds = [dict objectForKey:@"tids"];
			NSArray *qualitys = [dict objectForKey:@"qualitys"];
			NSArray *statusArray = [dict objectForKey:@"status"];
			NSArray *exps = [dict objectForKey:@"exps"];
			BOOL offerEnable = offerCount > 0;
			[self loadDataWithTaskIds:taskIds qualitys:qualitys statusArray:statusArray exps:exps enable:offerEnable];
            
			// 刷新剩余时间
			refreshTimeTitle.visible = NO;
			refreshTimeLabel.visible = NO;
			addSeconds = [[dict objectForKey:@"times"] intValue];
			if (addSeconds == 0) {
				[self unschedule:@selector(addFreeRefreshCountDown)];
			} else {
				if (firstCountDown) {
					addSeconds++;
				} else {
					addSeconds = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfReTime"] intValue];
					refreshTimeTitle.visible = YES;
					refreshTimeLabel.visible = YES;
				}
				refreshTimeLabel.string = getFormatTimeWithSeconds(addSeconds);
				[self schedule:@selector(addFreeRefreshCountDown) interval:1];
			}
			
			if (offerCount <= 0) {
				[self setRefreshDisable];
				refreshTimeTitle.visible = NO;
				refreshTimeLabel.visible = NO;
				refreshCountTitle.visible = NO;
				refreshCountLabel.visible = NO;
				[self unschedule:@selector(addFreeRefreshCountDown)];
			}
			
			// 当前无兵符任务
			CCNode *tipsNode = [self getChildByTag:OfferTipsTag];
			if (tipsNode) {
				[tipsNode removeFromParentAndCleanup:YES];
				tipsNode = nil;
			}
			if (taskIds.count <= 0) {
				[self setRefreshDisable];
				refreshTimeTitle.visible = NO;
				refreshTimeLabel.visible = NO;
				[self unschedule:@selector(addFreeRefreshCountDown)];
                float fontSize=20;
                //                if (iPhoneRuningOnGame()) {
                //                    fontSize=16;
                //                }
				//CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:@"当前等级无悬赏任务" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
				tipsLabel.color = ccc3(255, 0, 0);
                if (iPhoneRuningOnGame()) {
                    tipsLabel.scale=FONT_SIZE_SCALE;
                }
				tipsLabel.anchorPoint = ccp(0, 0.5);
				tipsLabel.position = ccp(cFixedScale(40), cFixedScale(435));
				[self addChild:tipsLabel z:10 tag:OfferTipsTag];
                //txt 1
                CCLabelTTF *tipsLabel_txt1 = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer_text1",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                tipsLabel_txt1.color = ccc3(255,255, 0);
                [tipsLabel addChild:tipsLabel_txt1];
                tipsLabel_txt1.anchorPoint = ccp(0, 0.5);
                tipsLabel_txt1.position = ccp(0, -tipsLabel.contentSize.height);
                //txt 2
                CCLabelTTF *tipsLabel_txt2 = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer_text2",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                tipsLabel_txt2.color = ccc3(255,255, 0);
                [tipsLabel addChild:tipsLabel_txt2];
                tipsLabel_txt2.anchorPoint = ccp(0, 0.5);
                tipsLabel_txt2.position = ccp(0, -tipsLabel.contentSize.height-tipsLabel_txt1.contentSize.height);
                
			} else if (statusArray.count > 0) {
				BOOL hadAccept = NO;
				for (int i = 0; i < statusArray.count; i++) {
					TaskStatus status = [[statusArray objectAtIndex:i] intValue];
					if (status == TaskStatus_Had_Accept) {
						hadAccept = YES;
						break;
					}
				}
				if (hadAccept) {
					[self setRefreshDisable:refreshCount];
				}
			}
		}
    } else {
        CCLOG(@"进入兵符任务界面没有获得数据");
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
}

-(void)refreshTaskWithType:(RefreshType)type
{
	NSString *typeString = [NSString stringWithFormat:@"type::%d", type];
	[GameConnection request:@"bfTaskRe" format:typeString target:self call:@selector(didRefreshOfferTask:)];
}

-(void)didRefreshOfferTask:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			// 删除悬赏任务
			[[TaskManager shared] stopAllOfferTask];
			
			// 任务列表
			NSArray *taskIds = [dict objectForKey:@"tids"];
			NSArray *qualitys = [dict objectForKey:@"qualitys"];
			NSArray *statusArray = [dict objectForKey:@"status"];
			NSArray *exps = [NSArray arrayWithObjects:@"0", @"0", @"0", @"0", nil];
			[self loadDataWithTaskIds:taskIds qualitys:qualitys statusArray:statusArray exps:exps];
			
			// 免费刷新次数
			refreshCount = [[dict objectForKey:@"n1"] intValue];
			refreshCountLabel.string = [NSString stringWithFormat:@"%d", refreshCount];
			[self setRefreshWithFreeCount:refreshCount];
			
			firstCountDown = YES;
			
			// 刷新剩余时间
			refreshTimeTitle.visible = NO;
			refreshTimeLabel.visible = NO;
			addSeconds = [[dict objectForKey:@"times"] intValue];
			if (addSeconds == 0) {
				[self unschedule:@selector(addFreeRefreshCountDown)];
			} else {
				if (firstCountDown) {
					addSeconds++;
				} else {
					addSeconds = [[[[GameDB shared] getGlobalConfig] objectForKey:@"bfReTime"] intValue];
					refreshTimeTitle.visible = YES;
					refreshTimeLabel.visible = YES;
				}
				refreshTimeLabel.string = getFormatTimeWithSeconds(addSeconds);
				[self schedule:@selector(addFreeRefreshCountDown) interval:1];
			}
			
			[[GameConfigure shared] updatePackage:dict];
			
			// 当前无兵符任务
			CCNode *tipsNode = [self getChildByTag:OfferTipsTag];
			if (tipsNode) {
				[tipsNode removeFromParentAndCleanup:YES];
				tipsNode = nil;
			}
			if (taskIds.count <= 0) {
				[self setRefreshDisable];
                int fontSize=20;
				//CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:@"当前等级无悬赏任务" fontName:getCommonFontName(FONT_1) fontSize:20];
                CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
				tipsLabel.color = ccc3(255, 0, 0);
				tipsLabel.anchorPoint = ccp(0, 0.5);
                if (iPhoneRuningOnGame()) {
                    tipsLabel.scale=FONT_SIZE_SCALE;
                }
				tipsLabel.position = ccp(cFixedScale(40), cFixedScale(435));
				[self addChild:tipsLabel z:10 tag:OfferTipsTag];
                //txt 1
                CCLabelTTF *tipsLabel_txt1 = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer_text1",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                tipsLabel_txt1.color = ccc3(255,255, 0);
                [tipsLabel addChild:tipsLabel_txt1];
                tipsLabel_txt1.anchorPoint = ccp(0, 0.5);
                tipsLabel_txt1.position = ccp(0, -tipsLabel.contentSize.height);
                //txt 2
                CCLabelTTF *tipsLabel_txt2 = [CCLabelTTF labelWithString:NSLocalizedString(@"task_no_offer_text2",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
                tipsLabel_txt2.color = ccc3(255,255, 0);
                [tipsLabel addChild:tipsLabel_txt2];
                tipsLabel_txt2.anchorPoint = ccp(0, 0.5);
                tipsLabel_txt2.position = ccp(0, -tipsLabel.contentSize.height-tipsLabel_txt1.contentSize.height);
			} else if (statusArray.count > 0) {
				BOOL hadAccept = NO;
				for (int i = 0; i < statusArray.count; i++) {
					TaskStatus status = [[statusArray objectAtIndex:i] intValue];
					if (status == TaskStatus_Had_Accept) {
						hadAccept = YES;
						break;
					}
				}
				if (hadAccept) {
					[self setRefreshDisable:refreshCount];
				}
			}
		}
	} else {
        [ShowItem showErrorAct:getResponseMessage(sender)];
    }
}

-(void)loadDataWithTaskIds:(NSArray *)taskIds qualitys:(NSArray *)qualitys statusArray:(NSArray *)statusArray exps:(NSArray *)exps
{
	[self loadDataWithTaskIds:taskIds qualitys:qualitys statusArray:statusArray exps:exps enable:YES];
}

-(void)loadDataWithTaskIds:(NSArray *)taskIds qualitys:(NSArray *)qualitys statusArray:(NSArray *)statusArray exps:(NSArray *)exps enable:(BOOL)enable
{
	// 删除之前数据
	if (offerItems.count != 0) {
		for (TaskOfferItem *taskOfferItem in offerItems) {
			[taskOfferItem removeFromParentAndCleanup:YES];
			taskOfferItem = nil;
		}
		[offerItems removeAllObjects];
	}
	BOOL hadAccept = NO;	// 是否有已接的
	CGPoint offsetPoint = ccp(21, 126);
    //悬赏任务列表项的间距
    float offsetY = 85;
    
	//右边列表项
    if (iPhoneRuningOnGame()) {
		offsetPoint=ccp(offsetPoint.x/2, offsetPoint.y/2);
		offsetY=50;
    }
    
    for (int i = 0; i < taskIds.count; i++) {
		int taskId = [[taskIds objectAtIndex:i] intValue];
		ItemQuality quality = [[qualitys objectAtIndex:i] intValue];
		TaskStatus status = [[statusArray objectAtIndex:i] intValue];
		if (status == TaskStatus_Had_Accept && !hadAccept) {
			hadAccept = YES;
		}
		int exp = 0 ;//[[exps objectAtIndex:i] intValue];
		if (exps != nil && exps.count == taskIds.count) {
			exp =[[exps objectAtIndex:i] intValue];
		}
		TaskOfferItem *taskOfferItem = [[[TaskOfferItem alloc] initWithQuality:quality taskId:taskId status:status exp:exp] autorelease];
		taskOfferItem.position = ccp(offsetPoint.x, offsetPoint.y+i*offsetY);
		taskOfferItem.delegate = self;
		taskOfferItem.index = i;
		[self addChild:taskOfferItem];
		[offerItems addObject:taskOfferItem];
	}
	
	// 如果有已接任务的，屏蔽其他按钮
	if (hadAccept) {
		for (TaskOfferItem *taskOfferItem in offerItems) {
			BOOL enable = taskOfferItem.taskStatus == TaskStatus_Had_Accept;
			[taskOfferItem setMenuEnable:enable];
		}
	}
	
	// 屏蔽
	if (!enable) {
		for (TaskOfferItem *taskOfferItem in offerItems) {
			[taskOfferItem setMenuEnable:NO];
		}
	}
}

-(void)onExit
{
	if (offerItems) {
		[offerItems release];
		offerItems = nil;
	}
	
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end


//TODO 任务面板
@implementation TaskPanel

-(void)onEnter
{
    [super onEnter];
	isTaskButtonTouch = NO;
    s_taskPanelType = Task_Type_none;
    
	self.touchEnabled = YES;
	self.touchPriority = -1;
    
	// 一级任务列表
	taskList = [TaskList node];
    if (iPhoneRuningOnGame()) {
		taskList.position = ccp(44+5,33/2);
    }else{
        taskList.position = ccp(self.contentSize.width/2-409, self.contentSize.height/2-268);
    }
    [self addChild:taskList z:10];
    
    // 二级任务列表 主线任务下面的任务列表
    taskDetailList = [TaskDetailList node];
    if (iPhoneRuningOnGame()) {
		taskDetailList.position = ccp(taskList.position.x+taskList.contentSize.width+5, 33/2);
    }else{
        taskDetailList.position = ccp(self.contentSize.width/2-208, self.contentSize.height/2-268);
    }
    [self addChild:taskDetailList z:5];
    
    // 任务详细 主线任务下面的任务详细
    taskDetail = [TaskDetail node];
    if (iPhoneRuningOnGame()) {
		taskDetail.position = ccp(taskDetailList.position.x+taskDetailList.contentSize.width+5, 33/2);
    }else{
        taskDetail.position = ccp(self.contentSize.width/2-7, self.contentSize.height/2-268);
    }
	taskDetail.visible = NO;
	[self addChild:taskDetail];
	
	// 悬赏任务
	taskOfferPanel = [TaskOfferPanel node];
    if (iPhoneRuningOnGame()) {
		taskOfferPanel.position = ccp(taskList.position.x+taskList.contentSize.width+5, 33/2);
    }else{
        taskOfferPanel.position = ccp(229, self.contentSize.height/2-268);
    }
	taskOfferPanel.visible = NO;
	[self addChild:taskOfferPanel];
	
	Task_Type type = Task_Type_main;
	Task * task = [TaskManager shared].runingTask;
	if(task) type = task.type;
    
	// 是否解锁悬赏任务
	BOOL unlockOffer = [[GameConfigure shared] checkPlayerFunction:Unlock_offer];
	if (unlockOffer) {
		type = Task_Type_offer;
	}

	// 宝箱闪烁
	NSString *fullPath1 = @"images/animations/boxopen/1/";
	NSString *fullPath2 = @"images/animations/boxopen/2/";
	NSArray *roleFrames1 = [AnimationViewer loadFileByFileFullPath:fullPath1 name:@"%d.png"];
	NSArray *roleFrames2 = [AnimationViewer loadFileByFileFullPath:fullPath2 name:@"%d.png"];
	
	shineOver = [AnimationViewer node];
    if (iPhoneRuningOnGame()) {
        shineOver.position = ccp(self.contentSize.width/2, self.contentSize.height/2);;
    }else{
        shineOver.position = ccp(self.contentSize.width/2, self.contentSize.height/2);;
    }
	shineOver.visible = NO;
	[shineOver playAnimation:roleFrames1];
	[self addChild:shineOver z:210];
	
	shineUnder = [AnimationViewer node];
	shineUnder.position = ccp(self.contentSize.width/2, self.contentSize.height/2);;
	shineUnder.visible = NO;
	[shineUnder playAnimation:roleFrames2];
	[self addChild:shineUnder z:190];
	
	[taskList selectItemByTaskType:type];

	[GameConnection addPost:ConnPost_updatePackage target:self call:@selector(updatePackage:)];
	[GameConnection addPost:ConnPost_updatePlayerUpLevel target:self call:@selector(playerUplevel:)];
}

-(void)updatePackage:(NSNotification*)notification
{
	[self showWithTaskType:Task_Type_offer];
}

-(void)showWithTaskType:(Task_Type)type
{
	[taskList selectItemByTaskType:type];
}

-(void)playerUplevel:(NSNotification*)notification
{
	taskOfferPanel.needLoad = YES;
	[self showWithTaskType:Task_Type_offer];
}

-(void)boxActionDone
{
	// 飞下宝箱震屏
	[[GameEffects share] showEffects:EffectsAction_loshingDirect target:nil call:nil];
}

-(void)boxAction
{
	if (boxMenuItem) {
		boxMenuItem.position = ccp(self.contentSize.width/2, self.contentSize.height/2+260);
		boxMenuItem.visible = YES;
		id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(self.contentSize.width/2, self.contentSize.height/2)];
		[boxMenuItem stopAllActions];
		[boxMenuItem runAction:[CCSequence actions:moveAction, [CCCallFunc actionWithTarget:self selector:@selector(boxActionDone)], nil]];
	}
}

-(void)didOpenBox:(id)sender
{
	if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
			shineOver.visible = YES;
			shineUnder.visible = YES;
			
			// 设置needload, 悬赏任务重新获得数据
			taskOfferPanel.needLoad = YES;
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			boxMenuItem.visible = NO;
			float delay = 1.0 * MAX(1, updateData.count);
			[self scheduleOnce:@selector(setRewardBoxHide) delay:delay];
			CCNode *node = [self getChildByTag:BoxOpenTag];
			if (node) {
				[node removeFromParentAndCleanup:YES];
				node = nil;
			}
			CCSprite *box = [CCSprite spriteWithFile:@"images/ui/panel/t57.png"];
			box.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
			[self addChild:box z:201 tag:BoxOpenTag];
			
			[[GameConfigure shared] updatePackage:dict];
		}
	}
	else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
    //
    isTaskButtonTouch = NO;
}

-(void)openBox:(id)sender
{
    if(isTaskButtonTouch || (s_taskPanelType != Task_Type_offer)){
        return;
    }
    isTaskButtonTouch = YES;
    //
	[[GameConfigure shared] markPlayerProperty];
	[GameConnection request:@"bfTaskBox" data:[NSDictionary dictionary] target:self call:@selector(didOpenBox:)];
}

-(void)setRewardBoxHide
{
	CCNode *node = [self getChildByTag:BoxOpenTag];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	[self setRewardBox:NO];
}
-(void)setRewardBox
{
	[self setRewardBox:YES];
}
-(void)setRewardBox:(BOOL)showBox
{
	CCDirector *director = [CCDirector sharedDirector];
	
	if (showBox) {
		[[director touchDispatcher] setPriority:kCCMenuHandlerPriority-1 forDelegate:self];
		
		hasBox = YES;
		if (maskLayer) {
			[maskLayer removeFromParentAndCleanup:YES];
			maskLayer = nil;
		}
		maskLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 190) width:823 height:491];
		maskLayer.position = ccp(self.contentSize.width/2-409, self.contentSize.height/2-268);
		[self addChild:maskLayer z:100];
		
		if (!boxMenuItem) {
			CCSprite *normalBox = [CCSprite spriteWithFile:@"images/ui/panel/t58.png"];
			CCSprite *selectedBox = [CCSprite spriteWithFile:@"images/ui/panel/t58.png"];
			boxMenuItem = [CCMenuItemSprite itemWithNormalSprite:normalBox selectedSprite:selectedBox target:self selector:@selector(openBox:)];
			CCMenu *boxMenu = [CCMenu menuWithItems:boxMenuItem, nil];
			boxMenu.position = ccp(0, 0);
			[self addChild:boxMenu z:200];
		}
		// 宝箱动画
		[self boxAction];
	} else {
		hasBox = NO;
		if (maskLayer) {
			[maskLayer removeFromParentAndCleanup:YES];
			maskLayer = nil;
		}
		if (boxMenuItem) {
			boxMenuItem.visible = NO;
		}
		shineOver.visible = NO;
		shineUnder.visible = NO;
		
		[[director touchDispatcher] setPriority:-1 forDelegate:self];
	}
}

-(void)onExit{
	[GameConnection removePostTarget:self];
	
	if (shineOver) {
		[shineOver removeFromParentAndCleanup:YES];
		shineOver = nil;
	}
	
	if (shineUnder) {
		[shineUnder removeFromParentAndCleanup:YES];
		shineUnder = nil;
	}
    //
	isTaskButtonTouch = NO;
    s_taskPanelType = Task_Type_none;
    
	[super onExit];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if (hasBox) {
		CGPoint touchLocation = [touch locationInView:touch.view];
		touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
		touchLocation = [self convertToNodeSpace:touchLocation];
		
		// 宝箱没打开可以点击
		if (CGRectContainsPoint(boxMenuItem.boundingBox, touchLocation) && boxMenuItem.visible) {
			return NO;
		}
		// 关闭可点击
		if (CGRectContainsPoint(_closeBnt.boundingBox, touchLocation)) {
			return NO;
		}
	}
    
    return YES;
}

-(void)closeWindow
{
    isTaskButtonTouch = YES;
    
	[super closeWindow];
	
	[[TaskManager shared] checkStartUserTask];
	
	// 新手教程
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_MMission_Step_1];
}

-(void)draw
{
	[super draw];
}

@end
