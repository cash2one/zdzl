//
//  RewardPanel.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-12.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RewardPanel.h"
#import "CCSimpleButton.h"
#import "StretchingImg.h"
#import "Window.h"
#import "CCLabelFX.h"
#import "CCPanel.h"
#import "GameMail.h"
#import "MessageBox.h"
#import "Config.h"

//iphone for chenjunming

#define MailShow_count		10		// 每次加载邮件

#define RewardTag_icon		20000
#define RewardTag_bg		20001
#define RewardTag_title		20002
#define RewardTag_content	20003
#define RewardTag_date		20004
#define RewardTag_get		20005

static RewardPanel * rewardPanel = nil;

@interface RewardItem : CCLayer
{
	CCSimpleButton *_btn;
}

@property (nonatomic) int btnTag;
@property (nonatomic) int icon;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) CCSimpleButton *btn;

@end

@implementation RewardItem

@synthesize btnTag;
@synthesize icon;
@synthesize title;
@synthesize content;
@synthesize date;
@synthesize btn = _btn;

-(id)init
{
	if (self = [super init]) {
		if(iPhoneRuningOnGame())
        {
			self.contentSize = CGSizeMake(925/2, 35);
        }else{
            self.contentSize = CGSizeMake(802.5, 70);
        }
		CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
		bg.scaleX = self.contentSize.width/bg.contentSize.width;
		bg.scaleY = self.contentSize.height/bg.contentSize.height;
		bg.anchorPoint = CGPointZero;
		bg.tag = RewardTag_bg;
		[self addChild:bg];
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
}

-(void)updateLabel
{
	CCNode *node = nil;
	node = [self getChildByTag:RewardTag_icon];
	if (node) {
		node.position = ccp(node.position.x, self.contentSize.height/2);
	}
	node = [self getChildByTag:RewardTag_bg];
	if (node) {
		node.scaleX = self.contentSize.width/node.contentSize.width;
		node.scaleY = self.contentSize.height/node.contentSize.height;
	}
	
	node = [self getChildByTag:RewardTag_title];
	if (node) {
		node.position = ccp(node.position.x, self.contentSize.height-cFixedScale(22));
	}
	
	node = [self getChildByTag:RewardTag_date];
	if (node) {
		node.position = ccp(node.position.x, self.contentSize.height-cFixedScale(23));
	}
	
	// 按钮
	if (_btn) {
		_btn.position= ccp(_btn.position.x, self.contentSize.height/2);
	}
}

-(void)setBtnTag:(int)btnTag_
{
	btnTag = btnTag_;
	
	if (_btn) {
		[_btn removeFromParentAndCleanup:YES];
		_btn = nil;
	}
	self.btn = [CCSimpleButton spriteWithFile:@"images/ui/mail/btn-get-1.png"
									   select:@"images/ui/mail/btn-get-2.png"];
    if (iPhoneRuningOnGame()) {
		_btn.position = ccp(817/2, self.contentSize.height/2);
		_btn.scale = 1.6;
    }else{
        _btn.position = ccp(695, self.contentSize.height/2);
    }
	_btn.priority = -57;
	_btn.target = rewardPanel;
	_btn.call = @selector(doGet:);
	_btn.tag = btnTag;
	
	[self addChild:_btn];
}

-(void)setIcon:(int)icon_
{
	icon = icon_;
	
	[self removeChildByTag:RewardTag_icon cleanup:YES];
	CCSprite *sprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/mail/icon%d.png", icon]];
	if (!sprite) {
		sprite = [CCSprite spriteWithFile:@"images/ui/mail/icon0.png"];
	}
    if (iPhoneRuningOnGame()) {
//        sprite.scale=0.7f;
        if (isIphone5()) {
            sprite.position = ccp(38/2, self.contentSize.height/2);
        }else{
            sprite.position = ccp(38/2, self.contentSize.height/2);
        }
    }else{
        sprite.position = ccp(38, self.contentSize.height/2);
    }
	sprite.tag = RewardTag_icon;
	[self addChild:sprite];
}

-(void)setTitle:(NSString *)title_
{
	title = title_;
	
	[self removeChildByTag:RewardTag_title cleanup:YES];
	CCLabelTTF *label = [CCLabelTTF labelWithString:title fontName:getCommonFontName(FONT_1) fontSize:20];
	label.tag = RewardTag_title;
	label.color = ccc3(239, 227, 206);
	label.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        label.scale=0.5f;
        if (isIphone5()) {
            label.position = ccp(80/2, self.contentSize.height-22/2);
        }else{
            label.position = ccp(80/2, self.contentSize.height-22/2);
        }
    }else{
        label.position = ccp(80, self.contentSize.height-22);
    }
	[self addChild:label];
}

-(void)setContent:(NSString *)content_
{
	content = content_;
	
	[self removeChildByTag:RewardTag_content cleanup:YES];
	int fontSize = iPhoneRuningOnGame() ? 18 : 14;
	int lineHeight = iPhoneRuningOnGame() ? 22 : 18;
	int spriteWidth = iPhoneRuningOnGame() ? 660 : 550;
	CCSprite *sprite = drawString(content, CGSizeMake(spriteWidth, 0), getCommonFontName(FONT_1), fontSize, lineHeight, @"#A0A0A0");
	
	float height = cFixedScale(38)+sprite.contentSize.height+cFixedScale(10);
	if (height > cFixedScale(70)) {
		self.contentSize = CGSizeMake(self.contentSize.width, height);
		[self updateLabel];
	}
	
	sprite.anchorPoint = ccp(0, 1);
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            sprite.position = ccp(80/2, self.contentSize.height-38/2);            
        }else{
            sprite.position = ccp(80/2, self.contentSize.height-38/2);
        }
    }else{
        sprite.position = ccp(80, self.contentSize.height-38);
    }
	sprite.tag = RewardTag_content;
	[self addChild:sprite];
}

-(void)setDate:(NSString *)date_
{
	date = date_;
	
	[self removeChildByTag:RewardTag_date cleanup:YES];
	CCLabelTTF *label = [CCLabelTTF labelWithString:date fontName:getCommonFontName(FONT_1) fontSize:14];
	label.tag = RewardTag_date;
	label.color = ccc3(254, 237, 130);
	label.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        label.scale=0.5f;
        if (isIphone5()) {
            label.position = ccp(426/2, self.contentSize.height-cFixedScale(23));
//            label.position = ccp(545/2, self.contentSize.height-cFixedScale(23));
        }else{
            label.position = ccp(426/2, self.contentSize.height-cFixedScale(23));
        }
    }else{
        label.position = ccp(426, self.contentSize.height-cFixedScale(23));
    }
	[self addChild:label];
}

-(void)onExit
{
	
	[super onExit];
}

@end

@implementation RewardPanel

+(RewardPanel*)shared{
	return rewardPanel;
}

-(void)onEnter{
	[super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	rewardPanel = self;
	
	//CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	MessageBox *box = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            box.contentSize = CGSizeMake(940/2, 553/2);
            box.position = ccp(10/2+44, 31/2);
        }else{
            box.contentSize = CGSizeMake(940/2, 553/2);
            box.position = ccp(10/2+44, 31/2);
        }
    }else{
        box.contentSize = CGSizeMake(823, 491);
        box.position = ccp(25, 9);
    }
	[self addChild:box];
	
	CCSprite * ct = [CCSprite spriteWithFile:@"images/ui/panel/columnTop-1.png"];
    if (iPhoneRuningOnGame()) {
		ct.scaleX = cFixedScale(925) / ct.contentSize.width;
		ct.scaleY = 1.2f;														//Kevin added
        ct.position = ccp(9/2, 520/2 - 5);											//Kevin modified. before 
    }else{
        ct.scaleX = cFixedScale(804) / ct.contentSize.width;
        ct.position = ccp(9, 458);
    }
	ct.anchorPoint = ccp(0, 1);
	[box addChild:ct];

	//CCLabelTTF *label = [CCLabelTTF labelWithString:@"活动奖励最多只保留10天" fontName:getCommonFontName(FONT_1) fontSize:15];
    CCLabelTTF *label = [CCLabelTTF labelWithString:NSLocalizedString(@"reward_hold_time",nil) fontName:getCommonFontName(FONT_1) fontSize:15];
	label.anchorPoint = ccp(0, 0.5);
    if (iPhoneRuningOnGame()) {
        label.scale=0.6f;														//Kevin modified. before 0.5f
		label.position = ccp(9/2 + 5, 543/2 - 5);								//Kevin modified. before 
    }else{
        label.position = ccp(9, 475);
    }
	label.color = ccc3(238, 228, 207);
	[box addChild:label];
	
	//label = [CCLabelTTF labelWithString:@"礼包奖励名称" fontName:getCommonFontName(FONT_1) fontSize:15];
    label = [CCLabelTTF labelWithString:NSLocalizedString(@"reward_gift_name",nil) fontName:getCommonFontName(FONT_1) fontSize:15];
    if (iPhoneRuningOnGame()) {
        label.scale=0.7f;
		label.position = ccp(163/2, 509/2 - 5);									//Kevin modified. before 
    }else{
        label.position = ccp(163, 444);
    }
	label.color = ccc3(62, 23, 8);
	[box addChild:label];
	
	//label = [CCLabelTTF labelWithString:@"日期" fontName:getCommonFontName(FONT_1) fontSize:15];
    label = [CCLabelTTF labelWithString:NSLocalizedString(@"reward_date",nil) fontName:getCommonFontName(FONT_1) fontSize:15];
    if (iPhoneRuningOnGame()) {
        label.scale=0.7f;
		label.position = ccp(478/2, 509/2 - 5);									//Kevin modified. before ccp(478/2, 509/2)
    }else{
        label.position = ccp(478, 444);
    
    }
	label.color = ccc3(62, 23, 8);
	[box addChild:label];
	
	//label = [CCLabelTTF labelWithString:@"操作" fontName:getCommonFontName(FONT_1) fontSize:15];
    label = [CCLabelTTF labelWithString:NSLocalizedString(@"reward_operate",nil) fontName:getCommonFontName(FONT_1) fontSize:15];
    if (iPhoneRuningOnGame()) {
        label.scale=0.7f;
        label.position = ccp(825/2, 509/2 - 5);									//Kevin modified. before ccp(825/2, 509/2);
    }else{
        label.position = ccp(706, 444);
    
    }
	label.color = ccc3(62, 23, 8);
	[box addChild:label];
	
	CCSprite * f = [CCSprite spriteWithFile:@"images/ui/panel/p18.png"];
	f.anchorPoint = ccp(0.5,0.5);
    if (iPhoneRuningOnGame()) {
		f.scaleX = (920/2)/f.contentSize.width;
		f.position = ccp(485/2, 105/2);
    }else{
        f.scaleX = cFixedScale(804)/f.contentSize.width;
        f.position = ccp(cFixedScale(432), cFixedScale(105));
    }
	
	[self addChild:f];
	
   	//全部收取菜单
	CCSimpleButton * get = [CCSimpleButton spriteWithFile:@"images/ui/mail/btn-getall-1.png"
												   select:@"images/ui/mail/btn-getall-2.png"];
    if (iPhoneRuningOnGame()) {
        get.position = (ccp(self.contentSize.width/2,66/2));
    }
    else {
        get.position = ccp(self.contentSize.width/2,63);
	}
	get.priority = -57;
	get.target = self;
	get.call = @selector(doGetAll:);
	[self addChild:get];
	
	panelWidth = 802.5f;
	panelHeight = 320.0f;
	if (iPhoneRuningOnGame()) {
		panelWidth=925/2;
		panelHeight=400/2;
		get.scale = 1.3;
    }
	content = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:panelWidth height:panelHeight];

	panel = [CCPanel panelWithContent:content
							 viewSize:CGSizeMake(panelWidth, content.contentSize.height)];
	panel.endTarget = self;
	panel.endCall = @selector(endMove);
	panel.anchorPoint = ccp(0,0);
    if (iPhoneRuningOnGame()) {
        panel.position = ccp(18/2+44, 105/2);
    }else{
        panel.position = ccp(cFixedScale(33), cFixedScale(112));
    }
	[self addChild:panel z:10];
	
	[self showList];
	
	[panel updateContentToTop];
	
}

-(void)endMove
{
	[self addList];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void)onExit{
	rewardPanel = nil;
	[super onExit];
}

-(void)showList{
	//收取邮件
	NSArray * mails = [[GameMail shared] getMailsByType:Mail_type_reward];
	int count = [mails count];
	
	NSMutableArray *itemArray = [NSMutableArray array];
	float offsetY = 14.0f;
    if (iPhoneRuningOnGame()) {
		offsetY/=2;
    }
	float contentHeight = -offsetY;
	
	showCount = MIN(count, MailShow_count);
	
	NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	for(int i=0;i<showCount;i++){
		
		NSDictionary * mail = [mails objectAtIndex:i];
		
		RewardItem *item = [RewardItem node];
		item.anchorPoint = CGPointZero;
		
		// 图标
		item.icon = [[mail objectForKey:@"content"] intValue];
		
		// 标题
		item.title = [mail objectForKey:@"title"];
		
		// 内容
		item.content = [mail objectForKey:@"param"];
		
		// 时间
		NSDate * ct = [NSDate dateWithTimeIntervalSince1970:[[mail objectForKey:@"ct"] intValue]];
		NSDateComponents * comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
											   fromDate:ct];
		int _y = [comps year];
		int _m = [comps month];
		int _d = [comps day];
		item.date = [NSString stringWithFormat:@"%d-%d-%d",_y,_m,_d];
		
		// 按钮
		item.btnTag = [[mail objectForKey:@"id"] intValue];
		
		[itemArray addObject:item];
		
		contentHeight += offsetY+item.contentSize.height;
	}
	
	[content removeAllChildrenWithCleanup:YES];
    if (iPhoneRuningOnGame()) {
        content.contentSize = CGSizeMake(925/2, MAX(400/2, contentHeight));
    }else{
        content.contentSize = CGSizeMake(802.5, MAX(320, contentHeight));
    }
	int i = 0;
	float posY = content.contentSize.height;
	for (CCNode *node in itemArray) {
        if (iPhoneRuningOnGame()) {
            posY = posY - node.contentSize.height - (i == 0 ? 2 : offsetY);
			node.position = ccp(0, posY);
        }else{
            posY = posY - node.contentSize.height - (i == 0 ? 0 : offsetY);
            node.position = ccp(0, posY);
        }
		[content addChild:node];
		i++;
	}
	
	itemArray = nil;
	
	[calendar release];
	[panel showScrollBar:@"images/ui/common/scroll3.png"];
	[panel updateContentToTop];
	[panel revisionSwipe];
	
}

-(void)addList
{
	NSArray * mails = [[GameMail shared] getMailsByType:Mail_type_reward];
	int count = [mails count];
	if (showCount >= count) {
		return;
	}
	
	int addCount = MIN(count-showCount, MailShow_count);
	
	NSMutableArray *itemArray = [NSMutableArray array];
	float offsetY = 14.0f;
    if (iPhoneRuningOnGame()) {
		offsetY/=2;
    }
	
	float contentHeight = 0;
	NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	for (int i = showCount; i < showCount+addCount; i++) {
		NSDictionary * mail = [mails objectAtIndex:i];
		
		RewardItem *item = [RewardItem node];
		item.anchorPoint = CGPointZero;
		
		// 图标
		item.icon = [[mail objectForKey:@"content"] intValue];
		
		// 标题
		item.title = [mail objectForKey:@"title"];
		
		// 内容
		item.content = [mail objectForKey:@"param"];
		
		// 时间
		NSDate * ct = [NSDate dateWithTimeIntervalSince1970:[[mail objectForKey:@"ct"] intValue]];
		NSDateComponents * comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
											   fromDate:ct];
		int _y = [comps year];
		int _m = [comps month];
		int _d = [comps day];
		item.date = [NSString stringWithFormat:@"%d-%d-%d",_y,_m,_d];
		
		// 按钮
		item.btnTag = [[mail objectForKey:@"id"] intValue];
		
		[itemArray addObject:item];
		
		contentHeight += offsetY+item.contentSize.height;
	}
	showCount += addCount;
	
	float oldHeight = content.contentSize.height;
	content.contentSize = CGSizeMake(content.contentSize.width, content.contentSize.height+contentHeight);
	
	float posY = INT16_MAX;
	for (CCNode *node in content.children) {
		if ([node isKindOfClass:[RewardItem class]]) {
			node.position = ccpAdd(node.position, ccp(0, contentHeight));
			if (posY > node.position.y) {
				posY = node.position.y;
			}
		}
	}
	
	for (CCNode *node in itemArray) {
        posY = posY - node.contentSize.height - offsetY;
		node.position = ccp(0, posY);
		
		[content addChild:node];
	}
	
	itemArray = nil;
	[calendar release];
	
	[panel showScrollBar:@"images/ui/common/scroll3.png"];
	[panel updateContentToTop:oldHeight-panelHeight];
	[panel revisionSwipe];
}

-(void)doGet:(CCNode*)node{
    CCNode *temp = node;
    for (;; ) {
        if (temp == NULL) {
            break;
        }
        if ([temp isKindOfClass:[CCPanel class]]) {
            CCPanel *temp_ = (CCPanel *)temp;
            if(!temp_.isTouchValid){
                return;
            }
            break;
        }
        temp = temp.parent;
    }
    //
	[[GameMail shared] removeMailById:node.tag];
	[self showList];
}

-(void)doGetAll:(CCNode*)node{
	[[GameMail shared] removeAllMailByType:Mail_type_reward];
	[self closeWindow];
}

@end
