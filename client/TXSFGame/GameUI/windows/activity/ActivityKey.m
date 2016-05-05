//
//  ActivityKey.m
//  TXSFGame
//
//  Created by efun on 13-3-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ActivityKey.h"
#import "ActivityPanel.h"
#import "CCSimpleButton.h"
#import "AlertManager.h"

//iphone for chenjunming

float orig_y=0.0f;

BOOL isCreate=NO;

@implementation ActivityKey

@synthesize aid;
@synthesize keyInput;

-(void)loadData:(NSDictionary *)dict{
	//todo
}

-(void) dealloc
{
	isCreate=NO;
	
	if (key) {
		[key release];
		key = nil ;
	}
	
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	[self setTouchEnabled:YES];
	
//	CCDirector *director = [CCDirector sharedDirector];
//	[[director touchDispatcher] addTargetedDelegate:self priority:-1 swallowsTouches:YES];
	
	/*
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/activity/1.jpg"];
	bg.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
//            bg.scaleX=1.45f;
            bg.scale=1.13f;
        }else{
            bg.scale=1.13f;
        }
    }
	self.contentSize =CGSizeMake(bg.contentSize.width*bg.scaleX,bg.contentSize.height*bg.scaleY);
	[self addChild:bg];
	*/
	
	if (isCreate) {
		return;
	}
	isCreate=YES;
	
	CGSize inputSize = CGSizeMake(cFixedScale(435), cFixedScale(40));
	
	//点击这个输入框就会出现
	CCSimpleButton * inputButton = [CCSimpleButton spriteWithFile:@"images/btn-tmp.png"];
	
	inputButton.target = self;
	inputButton.call  =@selector(doShowInput);
	inputButton.priority = INT32_MIN+10;
	inputButton.opacity = 0;
	
    inputButton.scaleX = inputSize.width / inputButton.contentSize.width;
    inputButton.scaleY = inputSize.height / inputButton.contentSize.height;
	inputButton.anchorPoint = CGPointZero;
	inputButton.tag = 12222;
	
    inputButton.position = ccp(cFixedScale(64), cFixedScale(213));
	
	[self addChild:inputButton z:-1];
	
	keyLabel = [CCLabelFX labelWithString:@""
								 dimensions:CGSizeMake(0,0)
								  alignment:kCCTextAlignmentCenter
								   fontName:GAME_DEF_CHINESE_FONT
								   fontSize:18
							   shadowOffset:CGSizeMake(-1.5, -1.5)
								 shadowBlur:2.0f];
	keyLabel.anchorPoint = ccp(0, 0.0);
//	if (iPhoneRuningOnGame()) {
//		keyLabel.position = ccp(71, 215);
//	}else{
		keyLabel.position = ccp(71, 215);
//	}
	[self addChild:keyLabel];
	
	//key = @"";
	
	CCSimpleButton *getButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_soonget_1.png"
														select:@"images/ui/button/bt_soonget_2.png"
														target:self
														  call:@selector(doGet:)
													  priority:INT32_MIN+10];
	getButton.tag = 12223;
	if (iPhoneRuningOnGame()) {
		getButton.scale=1.3f;
		keyLabel.position = ccp(68/2.0f, 211/2.0f);

	}
    getButton.position =ccp(cFixedScale(284), cFixedScale(108));
	[self addChild:getButton];
	
	orig_y=[ActivityPanel shared].position.y;
//	CCDirector *director = [CCDirector sharedDirector];
//	[[director touchDispatcher] addTargetedDelegate:self priority:-171 swallowsTouches:YES];
}



-(void)setVisible:(BOOL)__visible
{
	[super setVisible:__visible];
	
	CCNode *show = [self getChildByTag:12222];
	if (show) {
		show.visible = __visible;
	}
	CCNode *get = [self getChildByTag:12223];
	if (get) {
		get.visible = __visible;
	}
}

-(void)doGet:(id)sender
{
	//NSDictionary *dict = [NSDictionary dictionaryWithObject:key forKey:@"code"];
	if (key != nil) {
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:key forKey:@"code"];
		[GameConnection request:@"rewardCode" data:dict target:self call:@selector(didRewardCode:)];
	}else{
		CCLOG(@"doGet->key==nil");
		//[ShowItem showErrorAct:@"请输入兑换码!"];
        [ShowItem showErrorAct:NSLocalizedString(@"activity_input_key",nil)];
	}
}

-(void)didRewardCode:(id)sender
{
	if (checkResponseStatus(sender)) {
		NSDictionary *dict = getResponseData(sender);
        if (dict) {
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			[[GameConfigure shared] updatePackage:dict];
		}
	}
	else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(void)doShowInput
{
	if (keyInput) {
		return;
	}
    CGRect inputRect=CGRectMake(414, 392, 437, 40);
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
			inputRect=CGRectMake(375/2.0f+44, 317/2.0f, 482/2.0f, 40/2.0f);
        }else{
            inputRect=CGRectMake(375/2.0f, 317/2.0f, 482/2.0f, 40/2.0f);
        }
    }
	keyInput = [[UITextField alloc] initWithFrame:inputRect];
	
	[keyInput setHidden:YES];
	[keyInput setBorderStyle:UITextBorderStyleRoundedRect];
	[keyInput setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:iPhoneRuningOnGame()?12:16]];
	
	keyInput.delegate = self;
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:keyInput];
	[keyInput becomeFirstResponder];
	[keyInput setHidden:NO];
}

-(void)removeInputField
{
	if (keyInput) {
		[keyInput resignFirstResponder];
		[keyInput removeFromSuperview];
		[keyInput release];
		keyInput = nil;
	}
}

-(void)editKeyEnd:(UITextField *)textField
{
	[self removeInputField];
	
	if (keyLabel) {
		NSString* msg=textField.text;
		if (msg.length>=24) {
			msg=[msg substringToIndex:24];
		}
		
		if (key != nil) {
			[key release];
			key = nil;
		}
		
		key = msg;
		[key retain];
		
		keyLabel.string = msg;
	}
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (keyInput!=nil) {
		[keyInput resignFirstResponder];
    }
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{

	if (iPhoneRuningOnGame()) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 CGRect frame = textField.frame;
							 frame.origin.y-=60;
							 textField.frame = frame;
							 [ActivityPanel shared].position=ccp([ActivityPanel shared].position.x,[ActivityPanel shared].position.y+10);
						 }
						 completion:^(BOOL finished) {
							 
						 }];
	}else{
		[UIView animateWithDuration:0.25
						 animations:^{
							 CGRect frame = textField.frame;
							 frame.origin.y-=(70);
							 textField.frame = frame;
							 [ActivityPanel shared].position=ccp([ActivityPanel shared].position.x,[ActivityPanel shared].position.y+20);
						 }
						 completion:^(BOOL finished) {
							 
						 }];
	}

	
	[[ActivityPanel shared] moveTop:YES];
	return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	keyLabel.string = textField.text;
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (string.length<=0) {
		return YES;
	}
	//以下是可以允许输入的字符
	NSCharacterSet* cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789qwertyuiopasdfghjklzxcvbnm QWERTYUIOPASDFGHJKLZXCVBNM,.+=_;:?![]{}#%^*|<>\n"] invertedSet];
	NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
	BOOL find = [string isEqualToString:filtered];
	if (!find) {//不在过滤列表中
		return NO;
	}
	//判断长度
	if ([[textField text] length]>=24) {
		return NO;
	}
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	if (iPhoneRuningOnGame()) {
		[UIView animateWithDuration:0.25
						 animations:^{
							 CGRect frame = textField.frame;
							 frame.origin.y+=60;
							 textField.frame = frame;
							 [ActivityPanel shared].position=ccp([ActivityPanel shared].position.x,[ActivityPanel shared].position.y-10);
						 }
						 completion:^(BOOL finished) {
							 
						 }];
	}else{
		[UIView animateWithDuration:0.25
                     animations:^{
                         CGRect frame = textField.frame;
						 frame.origin.y+=70;
						 textField.frame = frame;
						 [ActivityPanel shared].position=ccp([ActivityPanel shared].position.x,[ActivityPanel shared].position.y-20);
                     }
                     completion:^(BOOL finished) {
						 
                     }];
	}
	[[ActivityPanel shared] moveTop:NO];
	[self editKeyEnd:textField];
}
//add by chenjunming
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    //关闭键盘
    [keyInput resignFirstResponder];
    return YES;
}

+(void) hideKeyboard:(ActivityKey*) keywin
{
	if (keywin) {
		[keywin editKeyEnd:keywin.keyInput];
	}
}



-(void)onExit
{
	//CCDirector *director = [CCDirector sharedDirector];
	//[[director touchDispatcher] removeDelegate:self];
	
	[self removeInputField];
	[GameConnection freeRequest:self];
	[super onExit];
}

@end
