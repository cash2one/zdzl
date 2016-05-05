//
//  EFWindowLogin.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFWindowLogin.h"
#import "EFUserInfo.h"
#import "EFUIWindow.h"
#import "EFAlert.h"
#import "EFUserAction.h"
#import "EFunUC.h"
#import "GameConnection.h"

@implementation EFWindowLogin

-(void)show{
    
	[super showBackground:@"ef_resources/bg_general.jpg"];
	[super showCloseBtn];
	[super showTitle:@"登  录"];
	
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake(30, 60, 310, 114)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_3.png"];
	[self addSubview:bg];
	[bg release];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(35,75,60,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"邮箱:";
	[self addSubview:label_1];
	
	UILabel * label_2 = [EFBaseWindow getLabel];
	label_2.frame = CGRectMake(35,130,60,30);
	label_2.font = [UIFont systemFontOfSize:21];
	label_2.textAlignment = UITextAlignmentLeft;
	label_2.text = @"密码:";
	[self addSubview:label_2];
	
	input_1 = [EFBaseWindow getTextField];
	input_1.frame = CGRectMake(100,78,230,30);
	input_1.text = [[EFUserInfo chooseUserInfo] getUserEmail];
	input_1.keyboardType = UIKeyboardTypeEmailAddress;
	input_1.tag = 1;
	input_1.delegate = self;
	[self addSubview:input_1];
	
	input_2 = [EFBaseWindow getTextField];
	input_2.frame = CGRectMake(100,133,230,30);
	input_2.text = @"";
	input_2.secureTextEntry = YES;
	input_2.clearsOnBeginEditing = NO;
	input_2.tag = 2;
	input_2.delegate = self;
	[self addSubview:input_2];
	
	UIButton * btn_create = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn_create setFrame:CGRectMake(353,63,106,109)];
	[btn_create setImage:[UIImage imageNamed:@"ef_resources/btn_big_1.png"] forState:UIControlStateNormal];
	[btn_create setImage:[UIImage imageNamed:@"ef_resources/btn_big_2.png"] forState:UIControlStateHighlighted];
	UILabel * label = [EFBaseWindow getLabel];
	label.frame = CGRectMake(25,0,58,109);
	label.font = [UIFont systemFontOfSize:26];
	label.textAlignment = UITextAlignmentCenter;
	label.text = @"游客试玩";
	[btn_create addSubview:label];
	[self addSubview:btn_create];
	
	[btn_create addTarget:self action:@selector(doCreate:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton * btn_modify = [EFBaseWindow getButton:@"确  定"];
	[btn_modify setFrame:CGRectMake((480-234)/2,190,
									btn_modify.frame.size.width,
									btn_modify.frame.size.height)
	 ];
	
	[btn_modify addTarget:self action:@selector(doLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_modify];
	
//	UIButton * btn_register = [EFBaseWindow getSmallButton:@"注  册"];
//	[btn_register setFrame:CGRectMake(353+106-btn_register.frame.size.width,190,
//									btn_register.frame.size.width,
//									btn_register.frame.size.height)
//	 ];
//	
//	[btn_register addTarget:self action:@selector(doRegister:) forControlEvents:UIControlEventTouchUpInside];
//	[self addSubview:btn_register];
	
	UIButton * btn_1 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn_1.titleLabel.font = [UIFont systemFontOfSize:25];
	[btn_1 setFrame:CGRectMake(40,270,100,30)];
	[btn_1 setTitle:@"忘记密码" forState:UIControlStateNormal];
	[btn_1 setTitleColor:EF_FONT_COLOR forState:UIControlStateNormal];
	[btn_1 setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[btn_1 addTarget:self action:@selector(doBtn1:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_1];
	
	UIButton * btn_2 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn_2.titleLabel.font = [UIFont systemFontOfSize:25];
	[btn_2 setFrame:CGRectMake(340,270,100,30)];
	[btn_2 setTitle:@"一秒注册" forState:UIControlStateNormal];
	[btn_2 setTitleColor:EF_FONT_COLOR forState:UIControlStateNormal];
	[btn_2 setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[btn_2 addTarget:self action:@selector(doRegister:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_2];
	
}

-(void)doLogin:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	[input_2 resignFirstResponder];
	
	NSString * emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate * emailVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	if(![emailVerify evaluateWithObject:input_1.text]){
		[EFAlert alert:@"请输入正确的邮箱地址!"];
		return;
	}
	if([input_2.text length]<6){
		[EFAlert alert:@"请输入6位或以上的旧密码!"];
		return;
	}
	NSString * passwordRegex = @"[A-Z0-9a-z]+[A-Za-z0-9]";
    NSPredicate * passwordVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
	if(![passwordVerify evaluateWithObject:input_2.text]){
		[EFAlert alert:@"请输入由数字与大小写字母组成的旧密码!"];
		return;
	}

	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:input_1.text forKey:@"email"];
	[userInfo setObject:input_2.text forKey:@"password"];
	
	[EFUserAction login:userInfo];
	[EFUIWindow showLoading];
}

-(void)doRegister:(id)sender
{
	if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow showUserRegister];
}

-(void)doCreate:(id)sender{
    //
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	if([[EFunUC shared] isLogin]){
//        [EFAlert alert:@"已是游客模式!"];
		[EFUIWindow closeWindowsWithDelay:0.001f];
		
		// 已是游客，直接开始
		[GameConnection post:@"ConnPost_doStartDirect" object:nil];
		
		return;
	}

    //
	[EFUserAction createGuest];
	[EFUIWindow showLoading];
}

-(void)doBtn1:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow showForget];
}

-(void)doBtn2:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow showSimpleAbout];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
	isBeginInput = YES;
	if([EFUIWindow isRunOniPhone]){
		if(textField.tag==3){
			[EFUIWindow moveContentToY:-96];
		}else{
			[EFUIWindow moveContentToY:-50];
		}
	}else{
		[EFUIWindow moveContentToY:-150];
	}
	return YES;
}
-(void)textFieldDidBeginEditing:(UITextField*)textField{
	isBeginInput = NO;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	if(textField.tag==1) [input_2 becomeFirstResponder];
	if(textField.tag==2) [textField resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField{
	if(!isBeginInput){
		[EFUIWindow moveContentToOrigin];
	}
	isBeginInput = NO;
}

@end
