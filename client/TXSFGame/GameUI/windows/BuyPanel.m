//
//  BuyPanel.m
//  TXSFGame
//
//  Created by efun on 13-1-10.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "BuyPanel.h"


float lastY=0.0f;

@implementation BuyPanel

@synthesize itemCount;
@synthesize itemId;
@synthesize delegate = _delegate;
@synthesize gameMoney;

+(void)create:(id)targer itemId:(int)iid count:(int)count
{
	BuyPanel *buyPanel = [[[BuyPanel alloc] initWithDelegate:targer itemId:iid count:count] autorelease];
	[[Window shared] addChild:buyPanel];
}

-(id)initWithDelegate:(id)_d itemId:(int)iid count:(int)count
{
	if (self = [super init]) {
		
		// 大小
		if (iPhoneRuningOnGame()) {
			self.contentSize = CGSizeMake(383/2.0f, 283/2.0f);
		}else{
			self.contentSize = CGSizeMake(383, 283);
		}
		self.delegate = _d;
		itemId = iid;
		itemCount = count;
		
		// 背景
		CCSprite *bg =nil;
		if (iPhoneRuningOnGame()) {
			bg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width height:self.contentSize.height capx:8/2.0f capy:8/2.0f];
		}else{
			bg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:self.contentSize.width height:self.contentSize.height capx:8 capy:8];
		}
		bg.anchorPoint = CGPointZero;
		bg.position = CGPointZero;
		[self addChild:bg z:-1];
		
		// 标题
		//CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:@"缺少以下材料，是否购买？" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(GAME_PROMPT_FONT_SIZE)];
        CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"buy_need",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(GAME_PROMPT_FONT_SIZE)];
		titleLabel.color = ccc3(238, 227, 206);
		titleLabel.anchorPoint = ccp(0, 0.5);
		titleLabel.position = ccp(cFixedScale(66), cFixedScale(245));
		
		[self addChild:titleLabel];
		
		NSDictionary *itemDict = [[GameDB shared] getItemInfo:iid];
		if (itemDict) {
			
			ItemQuality itemQuality = [[itemDict objectForKey:@"quality"] intValue];
			CCSprite *qualityIcon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png", itemQuality]];
			if (qualityIcon) {
				qualityIcon.position = ccp(cFixedScale(97), cFixedScale(164));
				[self addChild:qualityIcon];
			}
			
			CCSprite *itemIcon = getItemIcon(iid);
			if (itemIcon) {
				itemIcon.position = ccp(cFixedScale(97), cFixedScale(164));
				[self addChild:itemIcon];
			}
			
			NSString *name = [itemDict objectForKey:@"name"];
			CCLabelTTF *titleLabel = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
			titleLabel.color = ccc3(76, 140, 199);
			titleLabel.anchorPoint = ccp(0, 0.5);
			titleLabel.position = ccp(cFixedScale(145), cFixedScale(182));
			[self addChild:titleLabel];
			
			//CCLabelTTF *countTitleLabel = [CCLabelTTF labelWithString:@"数量:" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
            CCLabelTTF *countTitleLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"buy_count",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
			countTitleLabel.color = ccc3(238, 227, 206);
			countTitleLabel.anchorPoint = ccp(0, 0.5);
			countTitleLabel.position = ccp(cFixedScale(145), cFixedScale(142));
			[self addChild:countTitleLabel];
			
			//CCLabelTTF *costLabel = [CCLabelTTF labelWithString:@"总花费:" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
            CCLabelTTF *costLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"buy_spend_count",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
			costLabel.color = ccc3(254, 236, 130);
			costLabel.anchorPoint = ccp(0, 0.5);
			costLabel.position = ccp(cFixedScale(112), cFixedScale(95));
			[self addChild:costLabel];
			
			cost = 1;
			NSDictionary *itemDict = [[GameDB shared] getDireShopInfo:itemId];
			if (itemDict) {
				int coin2 = [[itemDict objectForKey:@"coin2"] intValue];
				int coin3 = [[itemDict objectForKey:@"coin3"] intValue];
				cost = coin2 + coin3;
			}
			gameMoney = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:MAX(cost*itemCount, 0)];
			gameMoney.anchorPoint = ccp(0, 0.5);
			gameMoney.position = ccp(cFixedScale(178), cFixedScale(92));
			[self addChild:gameMoney];
		}
		
		CCSprite *inputBg = [CCSprite spriteWithFile:@"images/ui/panel/p20.png"];
		inputBg.anchorPoint = ccp(0, 0.5);
		inputBg.position = ccp(cFixedScale(200), cFixedScale(142));
		[self addChild:inputBg];
		
		countLabel = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d", itemCount]
									 dimensions:CGSizeMake(0,0)
									  alignment:kCCTextAlignmentCenter
									   fontName:GAME_DEF_CHINESE_FONT
									   fontSize:18
								   shadowOffset:CGSizeMake(-1.5, -1.5)
									 shadowBlur:2.0f];
		countLabel.anchorPoint = ccp(0, 0.5);
		countLabel.position = ccp(cFixedScale(5), inputBg.contentSize.height/2-2);
		[inputBg addChild:countLabel];
		
		CCSimpleButton *inputButton = [CCSimpleButton spriteWithFile:@"images/btn-tmp.png"
															  select:@"images/btn-tmp.png"
															  target:self
																call:@selector(doShowInput)];
		inputButton.scaleX = inputBg.contentSize.width / inputButton.contentSize.width;
		inputButton.scaleY = inputBg.contentSize.height / inputButton.contentSize.height;
		inputButton.anchorPoint = ccp(0, 0.5);
		inputButton.position = inputBg.position;
		inputButton.priority = -203;
		[self addChild:inputButton z:-1];
		
		// 菜单
		CCSimpleButton *buyButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_buy2_1.png" select:@"images/ui/button/bt_buy2_2.png" target:self call:@selector(menuItemTapped:)];
		buyButton.tag = Buy_Btn_Confirm;
		buyButton.position = ccp(cFixedScale(100), cFixedScale(37));
		buyButton.priority = -203;
		[self addChild:buyButton z:100];
		
		CCSimpleButton *cancelButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_cancel_1.png" select:@"images/ui/button/bt_cancel_2.png" target:self call:@selector(menuItemTapped:)];
		cancelButton.tag = Buy_Btn_Cancel;
		cancelButton.position = ccp(cFixedScale(278), cFixedScale(37));
		cancelButton.priority = -203;
		[self addChild:cancelButton z:100];
		
		if (iPhoneRuningOnGame()) {
			buyButton.scale=1.2f;
			cancelButton.scale=1.2f;
		}
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-202 swallowsTouches:YES];
	
//	if (iPhoneRuningOnGame()) {
//		lastY=245.5f/2.0f;
//	}else{
//		lastY=275.0f;
//	}
//	lastY=self.position.y;
	if (self.zOrder == 0) {
		[self setZOrder:10000];
	}
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	CGPoint finalPoint = CGPointMake(winSize.width/2 - self.contentSize.width/2,
									 winSize.height/2 - self.contentSize.height/2);
	CGPoint currentPoint = [self.parent convertToWorldSpace:self.position];
	
	self.position = ccpAdd(self.position, ccpSub(finalPoint, currentPoint));
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (countInput) {
		[self editCountEnd:countInput];
	}
	return YES;
}

-(void)showInputField{
	[countInput setHidden:NO];
}
-(void)removeInputField{
	if(countInput){
		[countInput resignFirstResponder];
		[countInput removeFromSuperview];
		countInput = nil;
	}
}

-(void)doShowInput
{
	if (countInput) {
		return;
	}
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			countInput = [[UITextField alloc] initWithFrame:CGRectMake(581/2.0f, 241/2.0f, 100/2.0f, 28/2.0f)];
		}else{
			countInput = [[UITextField alloc] initWithFrame:CGRectMake(493/2.0f, 241/2.0f, 100/2.0f, 28/2.0f)];
		}
	}else{
		countInput = [[UITextField alloc] initWithFrame:CGRectMake(527, 335, 97, 30)];
	}
	[countInput setHidden:YES];
	[countInput setKeyboardType:UIKeyboardTypeNumberPad];
	[countInput setBorderStyle:UITextBorderStyleRoundedRect];
	[countInput setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:cFixedScale(16)]];
	[countInput setText:[NSString stringWithFormat:@"%d", itemCount]];

	
	countInput.delegate = self;
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:countInput];
	[countInput becomeFirstResponder];
	[countInput setHidden:NO];
	lastY=self.position.y;
	
	[self stopAllActions];
	if(iPhoneRuningOnGame()){
		//chenjunming
		[self runAction:[CCSequence actions:
								 [CCMoveTo actionWithDuration:0.2 position:ccp(self.position.x,242.5/2.0f)],
								 [CCCallFunc actionWithTarget:self selector:@selector(showInputField)],
								 nil]
		 ];
	}else{
		[self runAction:[CCSequence actions:
						 [CCMoveTo actionWithDuration:0.2 position:ccp(self.position.x,275.0f)],
						 [CCCallFunc actionWithTarget:self selector:@selector(showInputField)],
						 nil]
		 ];
	}
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (range.location >= 3)
        return NO; // return NO to not change text
	NSUInteger len=[[textField text] length];
//	CCLOG(@"%@",string);
	
	if ([string length]==0) {
		return YES;
	}
	NSCharacterSet *cs;
	//判断是否数字
	cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789\n"] invertedSet];
	NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
	BOOL basicTest = [string isEqualToString:filtered];
	if (!basicTest) {//不是数字
		return NO;		
	}
	//判断长度
	if (len>=3) {
		return NO;
	}
    return YES;
}


-(void)onExit
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[self removeInputField];
	[GameConnection freeRequest:self];
	[super onExit];
}

-(void)setItemCount:(int)_itemCount
{
	itemCount = _itemCount;
	[gameMoney setMoneyValue:itemCount*cost];
}

-(void)didShopBuy:(id)sender
{
	 if (checkResponseStatus(sender)) {
		 NSDictionary *dict = getResponseData(sender);
		 if (dict) {
			 // 更新背包
			 [[GameConfigure shared] updatePackage:dict];
			 
			 if (self.delegate && [_delegate respondsToSelector:@selector(buySuccess:)]) {
				 [_delegate buySuccess:self];
			 }
		 }
	 } else {
		 [ShowItem showErrorAct:getResponseMessage(sender)];
		 if (self.delegate && [_delegate respondsToSelector:@selector(buyCancel:)]) {
			 [_delegate buyCancel:self];
		 }
	 }
}

-(void)editCountEnd:(UITextField*)textField
{
	//chenjunming
	[self stopAllActions];
	[self runAction:[CCSequence actions:
						 [CCMoveTo actionWithDuration:0.2 position:ccp(self.position.x,lastY)],
						 [CCCallFunc actionWithTarget:self selector:@selector(showInputField)],
						 nil]
		 ];

	[self removeInputField];
	if(countLabel){
//		int count=itemCount;
		itemCount = [textField.text intValue];
		//当数量为0，不改变原有的数字
//		if (itemCount==0) {
//			itemCount=count;
//		}
		[self setItemCount:itemCount];
		//不输入任何数字时，不执行
		if ([textField.text length]==0) {
			return;
		}
//		//当数量为0，不改变原有的数字
//		if (itemCount!=0) {
			[countLabel setString:textField.text];
//		}
	}
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[self editCountEnd:textField];
	return YES;
}
-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self editCountEnd:textField];
}
-(BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
	return YES;
}

-(void)buyEvent
{
	int _id = 1;
	NSDictionary *itemDict = [[GameDB shared] getDireShopInfo:itemId];
	if (itemDict) {
		_id = [[itemDict objectForKey:@"id"] intValue];
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setValue:[NSNumber numberWithInt:_id] forKey:@"id"];
	[dict setValue:[NSNumber numberWithInt:itemCount] forKey:@"c"];
	[GameConnection request:@"dshopBuy" data:dict target:self call:@selector(didShopBuy:)];
}

-(void)menuItemTapped:(id)sender
{
	CCMenuItemSprite *menuItem = sender;
	// 点击了购买
	if (menuItem.tag == Buy_Btn_Confirm) {
		if (itemCount == 0) {
			//[ShowItem showItemAct:@"输入数目不合法"];
            [ShowItem showItemAct:NSLocalizedString(@"buy_input_count_wrong",nil)];
			[self cancel];
		} else {
			
			int coin2 = [[GameConfigure shared] getPlayerCoin2];
			int coin3 = [[GameConfigure shared] getPlayerCoin3];
			int costCoin = itemCount*cost;
			
			// 需消耗元宝
			if (coin3 + coin2 >= costCoin) {
				BOOL isRecordBait = [[[GameConfigure shared] getPlayerRecord:NO_REMIDE_BAIT] boolValue];
				if (isRecordBait) {
					[self buyEvent];
				} else {
					NSString *itemName = nil;
					ItemQuality itemQuality = 0;
					NSDictionary *itemDict = [[GameDB shared] getItemInfo:itemId];
					if (itemDict) {
						itemName = [itemDict objectForKey:@"name"];
						itemQuality = [[itemDict objectForKey:@"quality"] intValue];
					} else {
						//itemName = @"鱼饵";
                        itemName = NSLocalizedString(@"buy_fish_foot",nil);
					}
					//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝购买|%@%@|",costCoin, itemName, getHexColorByQuality(itemQuality)];
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"buy_yuanbao_buy",nil),costCoin, itemName, getHexColorByQuality(itemQuality)];
					MessageAlert *alert = (MessageAlert *)[[AlertManager shared] showMessageWithSettingFormFather:message target:self confirm:@selector(buyEvent) key:NO_REMIDE_BAIT father:[Window shared]];
					alert.canel = @selector(cancel);
					
					self.visible = NO;
				}
			}
			// 元宝不够
			else {
				//[ShowItem showItemAct:@"元宝不足"];
                [ShowItem showItemAct:NSLocalizedString(@"buy_no_yuanbao",nil)];
				[self cancel];
			}
		}
	}
	// 点击了取消
	else if (menuItem.tag == Buy_Btn_Cancel) {
		[self cancel];
	}
}


-(void)cancel
{
	if (self.delegate && [_delegate respondsToSelector:@selector(buyCancel:)]) {
		[_delegate buyCancel:self];
	}
	[self removeFromParentAndCleanup:YES];
	self = nil;
}

-(void)remove
{
	[self removeFromParentAndCleanup:YES];
	self = nil;
}

@end
