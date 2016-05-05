//
//  SuccessView.m
//  TXSFGame
//
//  Created by Soul on 13-4-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "SuccessView.h"
#import "Config.h"
#import "CCPanel.h"
#import "SuccessHelper.h"
#import "GameConnection.h"
#import "CCNode+AddHelper.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "GameConnection.h"
#import "SuccessLog.h"

@implementation CCLayer(SuccessLayout)

-(void)successLinearLayout:(float)_offset{
	CCNode* _temp = nil ;
	float paintY = -1*_offset;
	
	float _width = 0 ;
	CCARRAY_FOREACH(_children, _temp){
		if (_temp.contentSize.width > _width) {
			_width = _temp.contentSize.width;
		}
		_temp.position = ccp(_temp.contentSize.width/2, paintY - _temp.contentSize.height/2);
		paintY = paintY - _temp.contentSize.height;
		paintY = paintY - _offset;
	}
	
	self.contentSize = CGSizeMake(_width, fabsf(paintY));
	
	CCARRAY_FOREACH(_children, _temp){
		CGPoint pt = _temp.position;
		pt = ccpAdd(pt, ccp(0, fabsf(paintY)));
		_temp.position = pt;
	}
	
}

-(BOOL)checkComponent{
	return _children.count > 0;
}

@end

@implementation SuccessComponent

+(SuccessComponent*)create:(NSString *)data type:(SuccessComponentType)_t{
	//SuccessComponent* cmp = [[[SuccessComponent alloc] create:data type:_t] autorelease];
	SuccessComponent* cmp = [SuccessComponent node];
	[cmp create:data type:_t];
	return cmp;
}

-(void)create:(NSString *)data type:(SuccessComponentType)_t{
	//if ((self = [super init]) != nil){
	if (_data != nil) {
		[_data release];
		_data = nil;
	}
	
	if (data != nil) {
		_data = data;
		[_data retain];
	}
	
	_type = _t;
	
	if (_t == SuccessComponentType_success) {
		CCSprite* sprite = [CCSprite spriteWithFile:@"images/ui/success/component.png"];
		[self setContentSize:sprite.contentSize];
		[self Category_AddChildToCenter:sprite z:-1];
		if (iPhoneRuningOnGame()) {
			sprite.scaleX=1.17f;
			sprite.scaleY=1.1f;
			self.contentSize = CGSizeMake(sprite.contentSize.width*sprite.scaleX,sprite.contentSize.height*sprite.scaleY);
			sprite.position=ccp(self.contentSize.width/2.0f,self.contentSize.height/2.0f);
		}
	}
	
	if (_t == SuccessComponentType_log) {
		float _width = 0 ;
		float _height = 0 ;
		
		for (int i = 1; i < 5; i++) {
			NSString* path = [NSString stringWithFormat:@"images/ui/success/log_%d.png",i];
			CCSprite* logSpr = [CCSprite spriteWithFile:path];
			[self addChild:logSpr z:0 tag:2000+i];
			_width += logSpr.contentSize.width;
			if (logSpr.contentSize.height > _height) {
				_height = logSpr.contentSize.height;
			}
		}
		
		self.contentSize = CGSizeMake(_width, _height);
		
		float paintX = 0 ;

		for (int i = 2001; i < 2005; i++) {
			CCNode* _temp = [self getChildByTag:i];
			_temp.anchorPoint = ccp(0, 0.5);
			_temp.position = ccp(paintX, self.contentSize.height/2);
			paintX += _temp.contentSize.width;
		}
	}
	
}

-(void)dealloc{
	CCLOG(@"SuccessComponent->dealloc");
	if (_data != nil) {
		[_data release];
		_data = nil;
	}
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	
	if (_type == SuccessComponentType_log) {
		//绘制 日志
		if (_data != nil) {
			NSArray* array = [_data componentsSeparatedByString:@"|"];
			
			float fontSize=22;
			if (iPhoneRuningOnGame()) {
				fontSize=24;
			}
			
			if (array != nil && array.count == 5) {
				successId = [[array objectAtIndex:0] intValue];
				
				NSString* name = [array objectAtIndex:1];//成就的名字
				NSString* describe = [array objectAtIndex:2];//成就的完成描述
				NSString* rewardString = [array objectAtIndex:3];//成就奖励
				NSString* times = [array objectAtIndex:4];//完成时间
				
				CCLabelTTF *txt_name = [CCLabelTTF labelWithString:name
														  fontName:getCommonFontName(FONT_1)
														  fontSize:cFixedScale(fontSize)];
				txt_name.color = ccc3(0, 0, 0);
				txt_name.anchorPoint=ccp(0.5, 0.5);
				CCNode* _temp = [self getChildByTag:2001];
				[_temp Category_AddChildToCenter:txt_name];
				
				fontSize=18;
				if (iPhoneRuningOnGame()) {
					fontSize=20;
				}
				CCLabelTTF *txt_describe = [CCLabelTTF labelWithString:describe
															  fontName:getCommonFontName(FONT_1)
															  fontSize:cFixedScale(fontSize)];
				txt_describe.color = ccc3(200, 200, 200);
				txt_describe.anchorPoint=ccp(0.5, 0.5);
				
				_temp = [self getChildByTag:2002];
				[_temp Category_AddChildToCenter:txt_describe];
				
				
				CCLabelTTF *txt_reward = [CCLabelTTF labelWithString:rewardString
															fontName:getCommonFontName(FONT_1)
															fontSize:cFixedScale(fontSize)];
				txt_reward.color = ccc3(200, 200, 200);
				txt_reward.anchorPoint=ccp(0.5, 0.5);
				
				_temp = [self getChildByTag:2003];
				[_temp Category_AddChildToCenter:txt_reward];
				
				
				CCLabelTTF *txt_times = [CCLabelTTF labelWithString:times
														   fontName:getCommonFontName(FONT_1)
														   fontSize:cFixedScale(fontSize)];
				txt_times.color = ccc3(200, 200, 200);
				txt_times.anchorPoint=ccp(0.5, 0.5);
				
				_temp = [self getChildByTag:2004];
				[_temp Category_AddChildToCenter:txt_times];
			}
		}
	}
	
	if (_type == SuccessComponentType_success) {
		//绘制 成就
		if (_data != nil) {
			NSArray* array = [_data componentsSeparatedByString:@"|"];
			float fontSize=22;
			if (iPhoneRuningOnGame()) {
				fontSize=24;
			}
			if (array != nil) {
				if (array.count == 6){
					successId = [[array objectAtIndex:0] intValue];
					successType = [[array objectAtIndex:1] intValue];
					//永久成就
					int status = [[array objectAtIndex:5] intValue];
					if (status == SuccessStatus_done) {
						//已经完成
						if (successType == SuccessType_day) {
							//已领取
							CCSprite* getSpr = [CCSprite spriteWithFile:@"images/ui/success/get.png"];
							getSpr.anchorPoint = ccp(1.0, 0.5);
							getSpr.position = ccp(self.contentSize.width - cFixedScale(15),
												  self.contentSize.height/2);
							[self addChild:getSpr];
							if (iPhoneRuningOnGame()) {
								getSpr.scale=1.6f;
							}
						}
						if (successType == SuccessType_ever) {
							NSDictionary* successInfo = [[GameDB shared] getEverSuccessInfo:successId];
							NSString* tname = [successInfo objectForKey:@"tname"];
							//NSString* result = [NSString stringWithFormat:@"恭喜您！已经达成了 %@ 的所有成就了！",tname];
                            NSString* result = [NSString stringWithFormat:NSLocalizedString(@"success_view_arrive",nil),tname];
							float paintX = cFixedScale(15);
							CCLabelTTF *txt_over = [CCLabelTTF labelWithString:result
																	  fontName:getCommonFontName(FONT_1)
																	  fontSize:cFixedScale(fontSize)];
							txt_over.color = ccc3(0, 0, 0);
							txt_over.anchorPoint=ccp(0, 0.5);
							txt_over.position = ccp(paintX, self.contentSize.height/2);
							[self addChild:txt_over];
							return ;
						}
					}else if (status == SuccessStatus_undone){
						
						/*
						if (iPhoneRuningOnGame()) {
							fontSize=17;
						}else{
							fontSize=15;
						}
						*/
						
						//不能领取
						CCSprite* getSpr = [CCSprite spriteWithFile:@"images/ui/button/bts_get_3.png"];
						getSpr.anchorPoint = ccp(1.0, 0.5);
						getSpr.position = ccp(self.contentSize.width - cFixedScale(15),
											  self.contentSize.height/2);
						[self addChild:getSpr];
						if (iPhoneRuningOnGame()) {
							getSpr.scale=1.6f;
						}
					}else if (status == SuccessStatus_unget){
						//可以领取
						CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_get_1.png"
																	  select:@"images/ui/button/bts_get_2.png"
																	  target:self
																		call:@selector(getSuccessRewards:)];
						bnt.priority = -57;
						bnt.anchorPoint = ccp(1.0, 0.5);
						bnt.position = ccp(self.contentSize.width - cFixedScale(15),
										   self.contentSize.height/2);
						[self addChild:bnt];
						if (iPhoneRuningOnGame()) {
							bnt.scale=1.6f;
						}
					}
					
					NSString* name = [array objectAtIndex:2];//成就的名字
					NSString* describe = [array objectAtIndex:3];//成就的完成描述
					NSString* outcome = [array objectAtIndex:4];//成就是实际情况
					
					fontSize=22;
					if (iPhoneRuningOnGame()) {
						fontSize=24;
					}
					float paintX = cFixedScale(15);
					CCLabelTTF *txt_name = [CCLabelTTF labelWithString:name
															  fontName:getCommonFontName(FONT_1)
															  fontSize:cFixedScale(fontSize)];
					txt_name.color = ccc3(0, 0, 0);
					txt_name.anchorPoint=ccp(0, 0.5);
					txt_name.position = ccp(paintX, self.contentSize.height/2);
					
					paintX += (txt_name.contentSize.width + cFixedScale(15));
					
					fontSize=18;
					if (iPhoneRuningOnGame()) {
						fontSize=20;
					}
					paintX += cFixedScale(15) ;
					CCLabelTTF *txt_describe = [CCLabelTTF labelWithString:describe
																  fontName:getCommonFontName(FONT_1)
																  fontSize:cFixedScale(fontSize)];
					txt_describe.color = ccc3(255, 255, 255);
					txt_describe.anchorPoint=ccp(0, 0.5);
					txt_describe.position = ccp(paintX, self.contentSize.height/2);
					paintX += (txt_describe.contentSize.width + cFixedScale(15));
					
					NSArray* counts = [outcome componentsSeparatedByString:@"/"];
					if (counts != nil && counts.count == 2) {
						int c1 = [[counts objectAtIndex:0] intValue];
						int c2 = [[counts objectAtIndex:1] intValue];
						
						fontSize=14;
						float lineH=16;
						float rectH=20;
						if (iPhoneRuningOnGame()) {
							fontSize=16;
							lineH=20;
							rectH=24;
						}
						if (c1 >= c2 && c2 > 0) {
							NSString* count_str = [NSString stringWithFormat:@"( %d/%d )",c1,c2];
							CCLabelTTF *txt_count = [CCLabelTTF labelWithString:count_str
																	   fontName:getCommonFontName(FONT_1)
																	   fontSize:cFixedScale(fontSize)];
							txt_count.color = ccc3(255, 255, 0);
							txt_count.anchorPoint=ccp(0, 0.5);
							txt_count.position = ccp(paintX, self.contentSize.height/2);
							paintX += (txt_count.contentSize.width + cFixedScale(15));
							
							[self addChild:txt_count];
						}
						if (c1 < c2 && c2 > 0) {
							NSString* count_str = nil;
							if (iPhoneRuningOnGame()) {
								count_str=[NSString stringWithFormat:@"( |%d#ff0000#16#0|/%d )",c1,c2];
							}else{
								count_str=[NSString stringWithFormat:@"( |%d#ff0000#14#0|/%d )",c1,c2];
							}
							CCSprite* spr = drawString(count_str,
													   CGSizeMake(200, rectH),
													   getCommonFontName(FONT_1),
													   fontSize,
													   lineH,
													   @"ffff00");
							spr.anchorPoint = ccp(0, 0.5);
							if (iPhoneRuningOnGame()) {
								spr.position = ccp(paintX, self.contentSize.height/2);
							}else{
								spr.position = ccp(paintX, self.contentSize.height/2);
							}
							[self addChild:spr];
						}
					}
					
					[self addChild:txt_name];
					[self addChild:txt_describe];
					
				}
			}
		}
	}
}

-(void)onExit{
    [GameConnection freeRequest:[SuccessHelper shared]];
	[super onExit];
}

-(void)getSuccessRewards:(id)sender{
	CCLOG(@"getSuccessRewards:");
	if (![self checkTouchValid]) {
		return ;
	}
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:successId] forKey:@"id"];
	[dict setObject:[NSNumber numberWithInt:successType] forKey:@"t"];
	
	[GameConnection request:@"achiReward"
					   data:dict
					 target:[SuccessHelper shared]
					   call:@selector(endGetSuccrss:)];
}

-(BOOL)checkTouchValid{
	for( CCNode *c = self.parent; c != nil; c = c.parent ){
		if( [c isKindOfClass:[CCPanel class]]){
			CCPanel* temp = (CCPanel*)c;
			return temp.isTouchValid;
		}
	}
	return YES;
}

@end

@implementation SuccessView

@synthesize type = _type;


+(SuccessView*)viewWithDimension:(float)_width height:(float)_height{
	SuccessView* _view = [[[SuccessView alloc] initWithDimension:_width height:_height] autorelease];
	return _view;
}

-(id)initWithDimension:(float)_width height:(float)_height{
	if ((self=[super init]) == nil) {
		return nil;
	}
	[SuccessHelper start];
	self.contentSize = CGSizeMake(_width, _height);
	return self;
}

-(void)dealloc{
	CCLOG(@"SuccessView->dealloc!");
	[SuccessHelper stopAll];
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	
	CCLOG(@"SuccessView->show->%d",self.type);
	CCLOG(@"%@",[[SuccessHelper shared]getSuccessesInfo:self.type]);
	
	[GameConnection addPost:@"SuccessHelper_refresh" target:self call:@selector(showSuccessList)];
	
	if ([SuccessHelper shared].isReady) {
		[self showSuccessList];
	}
	
}


-(void)showSuccessList{
	[self removeAllChildrenWithCleanup:YES];
	
	CCLayer *content=[CCLayer node];
	NSArray *suList=[[SuccessHelper shared] getSuccessesInfo:self.type];
	
	if (suList.count > 0) {
		for(NSString *str in suList){
			CCLOG(@"%@",str);
			SuccessComponent *cmp = [SuccessComponent create:str type:SuccessComponentType_success];
			[content addChild:cmp];
		}
		
		[content successLinearLayout:10];
		float paintY = 0;
		BOOL bshow=NO;
		if (self.type == SuccessType_ever) {
			if (iPhoneRuningOnGame()) {
				paintY = 75/2.0f;
			}else{
				paintY = 55;
			}
			CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_check_success_1.png"
														  select:@"images/ui/button/bts_check_success_2.png"
														  target:self
															call:@selector(showSuccessLog:)];
			[self addChild:bnt];
			if (iPhoneRuningOnGame()) {
				bnt.scale=1.3f;
				bnt.position= ccp(self.contentSize.width/2, 35/2);
				bshow=YES;
			}else{
				bnt.position= ccp(self.contentSize.width/2, paintY/2);
			
			}
		}

		CCPanel* panel = nil;
		if (iPhoneRuningOnGame()) {
			if (bshow) {
				panel = [CCPanel panelWithContent:content
										 viewSize:CGSizeMake(content.contentSize.width, self.contentSize.height - paintY)];				
			}else{
				panel = [CCPanel panelWithContent:content
									 viewSize:CGSizeMake(content.contentSize.width, self.contentSize.height - 15)];
			}
		}else{
			panel = [CCPanel panelWithContent:content
										  viewSize:CGSizeMake(content.contentSize.width, self.contentSize.height - paintY)];
		}
		[self addChild:panel z:1];
		float _x = (self.contentSize.width - panel.contentSize.width)/2;
		if (iPhoneRuningOnGame()) {
			if (bshow) {
				[panel setPosition:ccp(_x, 65/2.0f)];
			}else{
				[panel setPosition:ccp(_x,10)];
			}
		}else{
			[panel setPosition:ccp(_x, paintY)];
		}
		[panel showScrollBar:@"images/ui/common/scroll3.png"];
		[panel updateContentToTopAndSetAligning:AligningType_top];
		[panel updateContentToTop];
	}
}

-(void)onExit{
	[GameConnection removePostTarget:self];
	[self removeAllChildrenWithCleanup:YES];
	[super onExit];
}

-(void)showSuccessLog:(id)_sender{
	NSArray* logs = [[SuccessHelper shared] getSuccessesLog];
	[SuccessLog addSuccessLog:logs];
	[[Window shared] showWindow:PANEL_SUCCESS_LOG];
}

@end









