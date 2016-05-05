//
//  RankPanel.m
//  TXSFGame
//
//  Created by efun on 13-1-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RankPanel.h"

#define RANK_PANEL_TAG		200

// index 0=头像,1=等级排名,2=名字,3=等级,4=位阶或战斗力
static inline float getPositionX(int index)
{
	float x = 0;
	switch (index) {
		case 0:	x = cFixedScale(48);	break;
		case 1:	x = cFixedScale(148);break;
		case 2:	x = cFixedScale(247);break;
		case 3:	x = cFixedScale(335);break;
		case 4:	x = cFixedScale(428);break;
		default:
			break;
	}
	return x;
}

@interface TabItem : CCListItem
{
	CCSprite *itemBg;
	CCSprite *currentItemBg;
	
	CCLabelTTF *label;
	ccColor3B normalColor;
	ccColor3B selectedColor;
}
@property (nonatomic) BOOL isSelected;
@end

@implementation TabItem
@synthesize isSelected;
-(id)initWithType:(RankType)type
{
	if (self = [super init]) {
		self.tag = type;
		
		itemBg = [CCSprite spriteWithFile:@"images/ui/panel/t25.png"];
		self.contentSize = itemBg.contentSize;
		CGPoint halfPoint = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
		currentItemBg = [CCSprite spriteWithFile:@"images/ui/panel/t24.png"];
		currentItemBg.visible = NO;
		itemBg.position = halfPoint;
		currentItemBg.position = halfPoint;
		[self addChild:itemBg];
		[self addChild:currentItemBg];
		
		isSelected = NO;
		
		normalColor = ccc3(169, 156, 124);
		selectedColor = ccc3(235, 229, 206);

		NSString *name = nil;
		switch (type) {
			case RankType_level:
				//name = @"等级榜";
                name = NSLocalizedString(@"rank_level",nil);
				break;
			case RankType_fight:
				//name = @"战斗力";
                name = NSLocalizedString(@"rank_fight",nil);
				break;
			case RankType_arena:
				//name = @"竞技场";
                name = NSLocalizedString(@"rank_arena",nil);
				break;
			case RankType_union:
				//name = @"同盟榜";
                name = NSLocalizedString(@"rank_union",nil);
				break;
            case RankType_abyss:
				//name = @"深渊榜";
                name = NSLocalizedString(@"rank_abyss",nil);
				break;
            case RankType_boss:
				//name = @"BOSS榜";
                name = NSLocalizedString(@"rank_boss",nil);
				break;
			default:
				name = @"";
				break;
		}
		label = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:14];
		label.position = halfPoint;
		label.color = normalColor;
        label.scale =cFixedScale(1);
		[self addChild:label];
	}
	return self;
}

-(void)setSelected:(BOOL)_isSelected
{
    if (isSelected == _isSelected) return;
    
    isSelected = _isSelected;
	itemBg.visible = !isSelected;
	currentItemBg.visible = isSelected;
	label.color = isSelected ? selectedColor : normalColor;
}

@end

@interface RankItem : CCLayer

@end

@implementation RankItem

-(id)initWithPlayerId:(int)pid roleId:(int)rid rank:(int)rank name:(NSString*)name level:(int)level data:(NSString*)data
{
	if (self = [super init]) {
		CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/t63.png"];
		self.contentSize = bg.contentSize;
		bg.anchorPoint = CGPointZero;
		[self addChild:bg];
		
		float y = self.contentSize.height / 2;
		
		self.tag = pid;
		
		CCSprite *player = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
		if (player) {
			player.scale = bg.contentSize.height / player.contentSize.height;
			player.position = ccp(getPositionX(0), y);
			[self addChild:player];
		}
		
		CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", rank] fontName:getCommonFontName(FONT_1) fontSize:16];
		rankLabel.position = ccp(getPositionX(1), y);
        rankLabel.scale = cFixedScale(1);
		[self addChild:rankLabel];
		if (name == nil || [name isKindOfClass:[NSNull class]]) {
            name = @"";
        }
		CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:16];
		nameLabel.position = ccp(getPositionX(2), y);
        nameLabel.scale = cFixedScale(1);
		[self addChild:nameLabel];
		
		CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", level] fontName:getCommonFontName(FONT_1) fontSize:16];
		levelLabel.position = ccp(getPositionX(3), y);
        levelLabel.scale = cFixedScale(1);
		[self addChild:levelLabel];
		if (data == nil || [data isKindOfClass:[NSNull class]]) {
            data = @"";
        }
		CCLabelTTF *dataLabel = [CCLabelTTF labelWithString:data fontName:getCommonFontName(FONT_1) fontSize:16];
		dataLabel.position = ccp(getPositionX(4), y);
        dataLabel.scale = cFixedScale(1);
		[self addChild:dataLabel];
	}
	return self;
}

@end

@implementation RankPanel

@synthesize defaultType;

-(void)onEnter
{
	[super onEnter];
	isSend = NO;
	self.touchEnabled = YES;
	self.touchPriority = -1;
	
	rankItems = [NSMutableArray array];
	[rankItems retain];
	moreButton = [CCSimpleButton spriteWithFile:@"images/ui/panel/t63.png" select:@"images/ui/panel/t63.png" target:self call:@selector(loadWithType:)];
	moreButton.visible = NO;
	moreButton.anchorPoint = ccp(0, 0);
	[moreButton retain];

	//Kevin added
	int	iFontSize = 16;
	if (iPhoneRuningOnGame()) {
		iFontSize = 8;
	}
	//----------------//
	
	//CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:@"查看更多..." fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
    CCLabelTTF *moreLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_read_much",nil) fontName:getCommonFontName(FONT_1) fontSize:iFontSize];
	moreLabel.color = ccc3(238, 228, 207);
	moreLabel.position = ccp(moreButton.contentSize.width/2,
							 moreButton.contentSize.height/2);
	[moreButton addChild:moreLabel];
	
	MessageBox *box1 = [MessageBox create:CGPointZero color:ccc4(83, 57, 32, 255)];
	box1.contentSize = CGSizeMake(cFixedScale(823), cFixedScale(476) );
    box1.anchorPoint = ccp(0, 0);
	box1.position = ccp(cFixedScale(25), cFixedScale(19));
	[self addChild:box1];
	
	CCSprite *girl = [CCSprite spriteWithFile:@"images/ui/panel/p28.png"];
	girl.anchorPoint = ccp(1, 0);
	girl.position = ccp(cFixedScale(856), cFixedScale(12));
	[self addChild:girl];
	
	//updateLabel = [CCLabelTTF labelWithString:@"排行每10分钟更新1次" fontName:getCommonFontName(FONT_1) fontSize:14];
    updateLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_flash",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
	updateLabel.color = ccc3(238, 228, 206);
	updateLabel.anchorPoint = ccp(0, 0.5);
	updateLabel.position = ccp(cFixedScale(35), cFixedScale(540));
    updateLabel.scale = cFixedScale(1);
	//updateLabel.visible = NO;
	[self addChild:updateLabel];
	
	rankTitle = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
	rankTitle.color = ccc3(238, 228, 206);
	rankTitle.anchorPoint = ccp(0, 0.5);
	rankTitle.position = ccp(cFixedScale(167), cFixedScale(36));
    rankTitle.scale = cFixedScale(1);
	rankTitle.visible = NO;
	[self addChild:rankTitle];
	
	rankLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
	rankLabel.color = ccc3(233, 180, 68);
	rankLabel.anchorPoint = ccp(0, 0.5);
    rankLabel.scale = cFixedScale(1);
	rankLabel.visible = NO;
	[self addChild:rankLabel];
	
	mineTitle = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
	mineTitle.color = ccc3(238, 228, 206);
	mineTitle.anchorPoint = ccp(0, 0.5);
    mineTitle.scale = cFixedScale(1);
	mineTitle.position = ccp(cFixedScale(329),cFixedScale(36));
	mineTitle.visible = NO;
	[self addChild:mineTitle];
	
	mineLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
	mineLabel.color = ccc3(233, 180, 68);
	mineLabel.anchorPoint = ccp(0, 0.5);
	mineLabel.visible = NO;
    mineLabel.scale = cFixedScale(1);
	[self addChild:mineLabel];
	
	//Kevin added
	if (iPhoneRuningOnGame()) {
		rankLabel.fontSize = 18;
		rankTitle.fontSize = 18;
		mineTitle.fontSize = 18;
		mineLabel.fontSize = 18;

	}
	//-------------------------------//
	
	CCSprite *rankTitleBg = [CCSprite spriteWithFile:@"images/ui/panel/columnTop-1.png"];
	rankTitleBg.scaleX = cFixedScale(485.5 / rankTitleBg.contentSize.width);
	rankTitleBg.anchorPoint = CGPointZero;
	rankTitleBg.position = ccp(cFixedScale(40.3), cFixedScale(462.5));
	[self addChild:rankTitleBg];
	
    
	listRank = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
	listRank.color = ccc3(56, 23, 11);
	listRank.position = ccpAdd(ccp(getPositionX(1), rankTitleBg.contentSize.height/2),
							   rankTitleBg.position);
    listRank.scale = cFixedScale(1);
	[self addChild:listRank];
	
	//CCLabelTTF *listName = [CCLabelTTF labelWithString:@"名字" fontName:getCommonFontName(FONT_1) fontSize:16];
    CCLabelTTF *listName = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_name_text",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
	listName.color = ccc3(56, 23, 11);
    listName.scale = cFixedScale(1);
	listName.position = ccpAdd(ccp(getPositionX(2), rankTitleBg.contentSize.height/2),
							   rankTitleBg.position);

	[self addChild:listName];
	
	//CCLabelTTF *listLevel = [CCLabelTTF labelWithString:@"等级" fontName:getCommonFontName(FONT_1) fontSize:16];
    CCLabelTTF *listLevel = [CCLabelTTF labelWithString:NSLocalizedString(@"rank_level_text",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
    listLevel.scale =cFixedScale(1);
	listLevel.color = ccc3(56, 23, 11);
	listLevel.position = ccpAdd(ccp(getPositionX(3), rankTitleBg.contentSize.height/2),
								rankTitleBg.position);
	[self addChild:listLevel];
	
	listData = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
	listData.color = ccc3(56, 23, 11);
    listData.scale = cFixedScale(1);
	listData.position = ccpAdd(ccp(getPositionX(4), rankTitleBg.contentSize.height/2),
							   rankTitleBg.position);
	[self addChild:listData];
	
	tabList = [CCLayerList listWith:LAYOUT_X :ccp(0, 0) :6.5 :0];
	NSArray *tabTypes = [NSArray arrayWithObjects:
						 //[NSNumber numberWithInt:RankType_level],
						 [NSNumber numberWithInt:RankType_fight],
						 [NSNumber numberWithInt:RankType_arena],
                         [NSNumber numberWithInt:RankType_union],
						 [NSNumber numberWithInt:RankType_abyss],
						 [NSNumber numberWithInt:RankType_boss],
						 nil];
	for (NSNumber *number in tabTypes) {
		RankType type = [number intValue];
		TabItem *item = [[[TabItem alloc] initWithType:type] autorelease];
		
		//Kevin added
		if (iPhoneRuningOnGame()) {
			item.scaleX = 1.6f;
			item.scaleY = 1.3f;
		}
		//----------------//
		
		[tabList addChild:item];
	}
	[tabList setDelegate:self];
	tabList.position = ccp(cFixedScale(25), cFixedScale(495));
	[self addChild:tabList z:20];
	

	[self selectTag:defaultType];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchlocation = [touch locationInView:touch.view];
	touchlocation = [[CCDirector sharedDirector] convertToGL:touchlocation];
	
	CCPanel *panel = (CCPanel *)[self getChildByTag:RANK_PANEL_TAG];
	if (panel) {
		CCLayer *contentLayer = (CCLayer *)[panel getContent];
		if (contentLayer) {
			touchlocation = [contentLayer convertToNodeSpace:touchlocation];
			CCLayer *layer = nil;
			CCARRAY_FOREACH(contentLayer.children, layer) {
				if (CGRectContainsPoint(CGRectMake(layer.boundingBox.origin.x, layer.boundingBox.origin.y, layer.contentSize.width, layer.contentSize.height), touchlocation)) {
					break;
				}
			}
		}
	}
	return YES;
}

-(void)showLabel:(RankType)type rank:(int)rank data:(int)data
{
	//updateLabel.visible = NO;
	rankTitle.visible = YES;
	rankLabel.visible = YES;
	mineTitle.visible = YES;
	mineLabel.visible = YES;
	
	float distance = cFixedScale(5);
	switch (type) {
		case RankType_level:
			//rankTitle.string = @"我的排名";
            rankTitle.string = NSLocalizedString(@"rank_my_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			//mineTitle.string = @"我的等级";
            mineTitle.string = NSLocalizedString(@"rank_my_level",nil);
			mineLabel.string = [NSString stringWithFormat:@"%d", data];
			mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width+distance, 0));
			
			//listRank.string = @"等级排名";
            listRank.string = NSLocalizedString(@"rank_level_rank",nil);
			//listData.string = @"位阶";
            listData.string = NSLocalizedString(@"rank_office",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				
				rankTitle.position = ccp(83, 18);
				mineTitle.position = ccp(164, 18);
				
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
				mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			break;
		case RankType_fight:
			//rankTitle.string = @"我的排名";
            rankTitle.string = NSLocalizedString(@"rank_my_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			//mineTitle.string = @"我的战斗力";
            mineTitle.string = NSLocalizedString(@"rank_my_fight",nil);
			mineLabel.string = [NSString stringWithFormat:@"%d", data];
			mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width+distance, 0));
			
			//listRank.string = @"战斗力排名";
            listRank.string = NSLocalizedString(@"rank_fight_rank",nil);
			//listData.string = @"战斗力";
            listData.string = NSLocalizedString(@"rank_fight",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				rankTitle.position = ccp(83, 18);
				mineTitle.position = ccp(164, 18);
				
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
				mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			
			break;
		case RankType_arena:
			//updateLabel.visible = NO;
			mineTitle.visible = NO;
			mineLabel.visible = NO;
			
			//rankTitle.string = @"我的竞技场排名";
            rankTitle.string = NSLocalizedString(@"rank_my_arena_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			
			//listRank.string = @"竞技场排名";
            listRank.string = NSLocalizedString(@"rank_arena_rank",nil);
			//listData.string = @"总战力";
            listData.string = NSLocalizedString(@"rank_count_fight",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				rankTitle.position = ccp(cFixedScale(167)+20, cFixedScale(36));
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			break;
        case RankType_union:
            //rankTitle.string = @"我盟排名";
            rankTitle.string = NSLocalizedString(@"rank_my_union_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			//mineTitle.string = @"同盟等级";
            mineTitle.string = NSLocalizedString(@"rank_union_level",nil);
			mineLabel.string = [NSString stringWithFormat:@"%d", data];
			mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width+distance, 0));
            
			//listRank.string = @"同盟排名";
            listRank.string = NSLocalizedString(@"rank_union_rank",nil);
			//listData.string = @"盟主";
            listData.string = NSLocalizedString(@"rank_union_main",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				rankTitle.position = ccp(83, 18);
				mineTitle.position = ccp(164, 18);
				
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
				mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			break;
        case RankType_abyss:
            //rankTitle.string = @"我的排名";
            rankTitle.string = NSLocalizedString(@"rank_my_abyss_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			//mineTitle.string = @"我的层数";
            mineTitle.string = NSLocalizedString(@"rank_abyss_level",nil);
			mineLabel.string = [NSString stringWithFormat:@"%d", data];
			mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width+distance, 0));
            
			//listRank.string = @"深渊排名";
            listRank.string = NSLocalizedString(@"rank_abyss_rank",nil);
			//listData.string = @"深渊层数";
            listData.string = NSLocalizedString(@"rank_abyss_data",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				rankTitle.position = ccp(83, 18);
				mineTitle.position = ccp(164, 18);
				
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
				mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			break;
        case RankType_boss:
            //rankTitle.string = @"我的伤害排名";
            rankTitle.string = NSLocalizedString(@"rank_my_boss_rank",nil);
			rankLabel.string = [NSString stringWithFormat:@"%d", rank];
			rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width+distance, 0));
			//mineTitle.string = @"我的伤害";
            mineTitle.string = NSLocalizedString(@"rank_boss_level",nil);
            if (data <= 0) {
                data = 0;
            }
            if (data<10000) {
                mineLabel.string = [NSString stringWithFormat:@"%d", data];
            }else{
                data /= 1000;
                float f_data = data/10.0;
                mineLabel.string = [NSString stringWithFormat:@"%.1fW", f_data];
            }
			mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width+distance, 0));
            
			//listRank.string = @"BOSS排名";
            listRank.string = NSLocalizedString(@"rank_boss_rank",nil);
			//listData.string = @"BOSS伤害";
            listData.string = NSLocalizedString(@"rank_boss_data",nil);
			
			//Kevin added
			if (iPhoneRuningOnGame()) {
				rankTitle.position = ccp(63, 18);
				mineTitle.position = ccp(164, 18);
				
				rankLabel.position = ccpAdd(rankTitle.position, ccp(rankTitle.contentSize.width/2+5, 0));
				mineLabel.position = ccpAdd(mineTitle.position, ccp(mineTitle.contentSize.width/2+5, 0));
			}
			//------------------------//
			break;
		default:
			break;
	}
}
-(void)showNoMineDictWithType:(int)type{
    rankTitle.visible = YES;
	rankLabel.visible = NO;
	mineTitle.visible = NO;
	mineLabel.visible = NO;
    switch (type) {
        case RankType_level:
        case RankType_fight:
        case RankType_arena:
        case RankType_union:
        case RankType_abyss:
        case RankType_boss:
            rankTitle.string = NSLocalizedString(@"rank_no_in_rank",nil);
            break;
        default:
            rankTitle.string = @"";
            break;
    }
}
-(void)didRankEnter:(id)sender data:(NSDictionary *)data
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			moreButton.visible = NO;
			if (moreButton.parent) {
				[moreButton removeFromParentAndCleanup:NO];
			}
			
			float offsetY = 0;
			CCPanel *panel = (CCPanel *)[self getChildByTag:RANK_PANEL_TAG];
			if (panel) {
				CCNode *content = [panel getContent];
				if (content) {
					offsetY = content.contentSize.height+content.position.y-panel.contentSize.height;
				}
				[content removeFromParentAndCleanup:YES];
				content = nil;
				[panel removeFromParentAndCleanup:YES];
				panel = nil;
			}
			
			BOOL next = ([[dict objectForKey:@"next"] intValue] == 1) && (currentPageCount < 10);
			RankType type = RankType_level;
			if (data) {
				type = [[data objectForKey:@"t"] intValue];
			}
			if (next) {
				currentPageCount++;
			}
			
			NSDictionary *mineDict = [dict objectForKey:@"mine"];
			if (mineDict) {
                if ((![mineDict objectForKey:@"r"]) && (![mineDict objectForKey:@"value"])) {
                    [self showNoMineDictWithType:type];
                }else{
                    int rank = [[mineDict objectForKey:@"r"] intValue];
                    int value = [[mineDict objectForKey:@"value"] intValue];
                    [self showLabel:type rank:rank data:value];
                }
                
			}else{
                [self showNoMineDictWithType:type];
            }
			
			float perWidth = 0;
			float perHeight = 0;
			NSArray *array = [dict objectForKey:@"ret"];
			for (NSDictionary *d in array) {
                
                int rid = 0;
				int r = 0;
				NSString *name = @"";
				int level = 0;
				int pid = 0;
                
                if ([d objectForKey:@"rid"] && ![[d objectForKey:@"rid"]isKindOfClass:[NSNull class]]) {
                    rid = [[d objectForKey:@"rid"] intValue];
                }
                if ([d objectForKey:@"r"] && ![[d objectForKey:@"r"]isKindOfClass:[NSNull class]]) {
                    r = [[d objectForKey:@"r"] intValue];
                }
                if ([d objectForKey:@"name"] && ![[d objectForKey:@"name"]isKindOfClass:[NSNull class]]) {
                    name = [d objectForKey:@"name"];
                }
                if ([d objectForKey:@"level"] && ![[d objectForKey:@"level"]isKindOfClass:[NSNull class]]) {
                    level = [[d objectForKey:@"level"] intValue];
                }
                if ([d objectForKey:@"pid"] && ![[d objectForKey:@"pid"]isKindOfClass:[NSNull class]]) {
                    pid = [[d objectForKey:@"pid"] intValue];
                }
                
				//
                NSString *dataString = @"";
                switch (type) {
                    case RankType_level:
                        if ([d objectForKey:@"office"] && ![[d objectForKey:@"office"]isKindOfClass:[NSNull class]]) {
                            dataString = [d objectForKey:@"office"];
                        }
                        break;
                    case RankType_fight:
                        if ([d objectForKey:@"CBE"] && ![[d objectForKey:@"CBE"]isKindOfClass:[NSNull class]]) {
                            dataString = [NSString stringWithFormat:@"%d", [[d objectForKey:@"CBE"] intValue]];
                        }
                        break;
                    case RankType_arena:
                        if ([d objectForKey:@"CBE"] && ![[d objectForKey:@"CBE"]isKindOfClass:[NSNull class]]) {
                            dataString = [NSString stringWithFormat:@"%d", [[d objectForKey:@"CBE"] intValue]];
                        }
                        break;
                    case RankType_union:
                        if ([d objectForKey:@"aname"] && ![[d objectForKey:@"aname"]isKindOfClass:[NSNull class]]) {
                            //
                            dataString = [d objectForKey:@"aname"];
                        }
                        break;
                    case RankType_abyss:
                        if ([d objectForKey:@"deep"] && ![[d objectForKey:@"deep"]isKindOfClass:[NSNull class]]) {
                            dataString = [NSString stringWithFormat:@"%d", [[d objectForKey:@"deep"] intValue]];
                        }
                        break;
                    case RankType_boss:
                        if ([d objectForKey:@"boss"]  && ![[d objectForKey:@"boss"]isKindOfClass:[NSNull class]]) {
                            int count_data = [[d objectForKey:@"boss"] intValue];
                            if (count_data <= 0) {
                                count_data = 0;
                            }
                            if (count_data<10000) {
                                dataString = [NSString stringWithFormat:@"%d", count_data];
                            }else{
                                count_data /= 1000;
                                float f_count_data = count_data/10.0;
                                dataString = [NSString stringWithFormat:@"%.1fW", f_count_data];
                            }
                            //dataString = [NSString stringWithFormat:@"%d", [[d objectForKey:@"boss"] intValue]];
                        }
                        break;
                    default:
                        break;
                }
                
                //NSString *dataString = office ? office : [NSString stringWithFormat:@"%d", CBE];
				
				RankItem *item = [[[RankItem alloc] initWithPlayerId:pid roleId:rid rank:r name:name level:level data:dataString] autorelease];
				[rankItems addObject:item];
				
				if (perWidth == 0) {
					perWidth = item.contentSize.width;
				}
				if (perHeight == 0) {
					perHeight = item.contentSize.height;
				}
			}
			
			float offsetHeight = cFixedScale(3.5);
			float viewHeight =10*perHeight+9*offsetHeight;
			
			float height = next ? (perHeight + offsetHeight) * rankItems.count + moreButton.contentSize.height : (perHeight + offsetHeight) * rankItems.count - offsetHeight;
			height = MAX(height, viewHeight);
			CCLayerColor *contentLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:perWidth height:height];
			int i = 0;
			for (CCNode *node in rankItems) {
				node.position = ccp(0, height-(i+1)*perHeight-i*offsetHeight);
				[contentLayer addChild:node];
				i++;
			}
			if (next) {
				moreButton.visible = YES;
				[contentLayer addChild:moreButton];
			}
			CCPanel *newPanel = [CCPanel panelWithContent:contentLayer viewSize:CGSizeMake(perWidth, viewHeight)];
            [newPanel showScrollBar:@"images/ui/common/scroll3.png"];
			newPanel.position = ccp(cFixedScale(42), cFixedScale(50));
			[newPanel updateContentToTop:offsetY];
			[self addChild:newPanel z:10 tag:RANK_PANEL_TAG];
		}
	} else {
		CCLOG(@"读取排行榜数据错误");
        [ShowItem showErrorAct:getResponseMessage(sender)];
        rankTitle.visible = NO;
        rankLabel.visible = NO;
        mineTitle.visible = NO;
        mineLabel.visible = NO;
	}
    //
    isSend = NO;
}

-(void)loadWithType:(CCNode*)node
{
//    if (node) {
//        CCPanel* temp = (CCPanel*)node.parent.parent.parent;
//        if (!temp.isTouchValid) {
//            return;
//        }
//    }
    
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
    if (isSend) {
        return;
    }
	RankType type = moreButton.tag;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setValue:[NSNumber numberWithInt:type] forKey:@"t"];
	[dict setValue:[NSNumber numberWithInt:currentPageCount] forKey:@"p"];
	[GameConnection request:@"rankEnter" data:dict target:self call:@selector(didRankEnter:data:) arg:dict];
    //
    isSend = YES;
}

-(void)selectTag:(RankType)type
{
	TabItem *item = nil;
	CCARRAY_FOREACH(tabList.children, item) {
		[item setSelected:item.tag == type];
	}
	
	[self showLabel:type rank:0 data:0];
	
	// 删掉旧数据
	CCNode *node = [self getChildByTag:RANK_PANEL_TAG];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	[rankItems removeAllObjects];
	
	currentPageCount = 1;
	moreButton.visible = NO;
	moreButton.tag = type;
	[self loadWithType:nil];
}

-(void)selectedEvent:(CCLayerList *)_list :(CCListItem *)_listItem
{
    if (isSend) {
        return;
    }
	TabItem *tabItem = (TabItem*)_listItem;
	if (tabItem.isSelected) return;
	
	[self selectTag:tabItem.tag];
}

-(void)onExit
{
	if (rankItems) {
		[rankItems release];
		rankItems = nil;
	}
	
	if (moreButton) {
		[moreButton release];
		moreButton = nil;
	}
	
	[GameConnection freeRequest:self];
	
	[super onExit];
}

-(CGPoint)getCaptionPosition{
	CGPoint pt = [super getCaptionPosition];
	if (iPhoneRuningOnGame()) {
		return ccpAdd(pt, ccp(0, cFixedScale(28)));
	}
	return pt;
}

@end
