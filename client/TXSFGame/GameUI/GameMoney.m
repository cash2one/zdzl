//
//  GameMoney.m
//  TXSFGame
//
//  Created by chao chen on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import "GameMoney.h"
#import "Config.h"
#define GAMEM_FONT (FONT_1)
#define GAMEM_FONT_SIZE (15)
@implementation GameMoney
@synthesize type;
@synthesize moneyValue;
-(id)init{
    if (self = [super init]) {
		sprite = [CCSprite spriteWithFile:getImagePath(GAMEMONEY_YIBI)];
		sprite.anchorPoint = ccp(0,0.5);
		sprite.position = ccp(0,[sprite contentSize].width/2);
		[self addChild:sprite];
		
		CGSize shadowOffset = CGSizeMake(2, 2);
		if(iPhoneRuningOnGame()){
			shadowOffset = CGSizeMake(1, 1);
		}
		txt = [CCLabelFX labelWithString:@"0"
								fontName:getCommonFontName(FONT_1)
								fontSize:15
							shadowOffset:shadowOffset
							  shadowBlur:0.2
							 shadowColor:ccc4(0, 0, 0, 128)
							   fillColor:ccc4(254,237,131, 255)];
		[txt setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[txt setHorizontalAlignment:kCCTextAlignmentLeft];
		txt.anchorPoint = ccp(0,0.5);
		
		if(iPhoneRuningOnGame()){
			txt.position = ccp(sprite.position.x+sprite.contentSize.width + 1,sprite.position.y);
		}else{
			txt.position = ccp(sprite.position.x+sprite.contentSize.width + 2,sprite.position.y);
		}
		
		[self addChild:txt];
    }
    return self;
}

-(void)onEnter{
	[super onEnter];
	
}
-(NSString*)getMoneyString:(NSInteger)value{
	return [NSString stringWithFormat:@"%d ",value];
}

-(NSString*)getMoneyString:(GameMoneyType)_type value:(NSInteger)value
{
	NSString *string = nil;
	switch (_type) {
		case GAMEMONEY_YIBI:
			//string = @"银币";
            string = NSLocalizedString(@"money_coin1",nil);
			break;
		case GAMEMONEY_YUANBAO_ONE:
			//string = @"元宝1";
            string = NSLocalizedString(@"money_coin2",nil);
			break;
		case GAMEMONEY_YUANBAO_TWO:
			//string = @"元宝2";
            string = NSLocalizedString(@"money_coin3",nil);
			break;
		case GAMEMONEY_EXP:
			//string = @"经验";
            string = NSLocalizedString(@"money_exp",nil);
			break;
		case GAMEMONEY_SIT_EXP:
			//string = @"打坐经验";
            string = NSLocalizedString(@"money_sit_exp",nil);
			break;
		case GAMEMONEY_TRAIN:
			//string = @"练历";
            string = NSLocalizedString(@"money_train",nil);
			break;
			
		default:
			break;
	}
	return [NSString stringWithFormat:@"%@ : %d", string, value];
}

+(GameMoney*)gameMoneyWithType:(GameMoneyType)_type value:(NSInteger)value
{
	GameMoney* node = [GameMoney node];
	[node setType:_type];
	[node setMoneyValue:value];
	return node;
}

+(GameMoney*)gameStringWithType:(GameMoneyType)_type value:(NSInteger)value
{
	GameMoney* node = [GameMoney node];
	[node setMoneyValue:value];
	return node;
}
-(id)getActionWithType:(NSInteger)_type{
	id ac = nil;
	SEL acSel = nil;
	NSMutableArray *acArr = [NSMutableArray array];
	if (_type == 0) {
		acSel = @selector(setTxtRed);
	}else if(_type == 1){
		acSel = @selector(setTxtGreen);
	}
	float time = 0.2;
	for (int i=0; i<3; i++) {
		ac = [CCDelayTime actionWithDuration:time];
		[acArr addObject:ac];
		ac = [CCCallFuncN actionWithTarget:self selector:acSel];
		[acArr addObject:ac];
		ac = [CCDelayTime actionWithDuration:time];
		[acArr addObject:ac];
		ac = [CCCallFuncN actionWithTarget:self selector:@selector(setTxtDef)];
		[acArr addObject:ac];
	}
	ac = [CCSequence actionWithArray:acArr];
	return ac;
}
-(void)setMoneyValue:(NSInteger)value{
	[txt setString:[self getMoneyString:value]];
	if (moneyValue > value) {
		[txt runAction:[self getActionWithType:1]];
	}else if(moneyValue < value){
		[txt runAction:[self getActionWithType:1]];
	}
	moneyValue = value;
	self.contentSize=[self rect];
}
-(void)setMoneyValue:(GameMoneyType)_type :(NSInteger)value
{
	if (sprite) {
		[sprite removeFromParentAndCleanup:YES];
	}
	if (txt) {
		txt.position = ccp(0, txt.position.y);
	}
	[txt setString:[self getMoneyString:_type value:value]];
	if (moneyValue > value) {
		[txt runAction:[self getActionWithType:1]];
	}else if(moneyValue < value){
		[txt runAction:[self getActionWithType:1]];
	}
	moneyValue = value;
	self.contentSize=[self rect];
}
-(void)setTxtDef{
	[txt setColor:ccc3(255,235,123)];
}
-(void)setTxtRed{
	[txt setColor:ccc3(255,0,0)];
}
-(void)setTxtGreen{
	[txt setColor:ccc3(0,255,0)];
}
-(CGSize)rect
{
	CGSize size;
	size.width = sprite.contentSize.width + txt.contentSize.width;
	
	if(iPhoneRuningOnGame()){
		if (size.width < 40) {
			size.width = 40;
		}
	}else{
		if (size.width < 80) {
			size.width = 80;
		}
	}
	
	if (sprite.contentSize.height>txt.contentSize.height) {
		size.height= sprite.contentSize.height;
	}
	else
	{
		size.height =  txt.contentSize.height;
	}
	return size;
}

-(void)setType:(GameMoneyType)_type{
	type = _type;	
	[sprite setTexture:[[CCTextureCache sharedTextureCache] addImage:getImagePath(type)] ];
	
}

@end
