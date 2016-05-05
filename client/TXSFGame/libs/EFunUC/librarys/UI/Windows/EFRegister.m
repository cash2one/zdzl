//
//  EFRegister.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFRegister.h"
#import "EFUIWindow.h"
#import "EFAlert.h"
#import "EFUserAction.h"

@implementation EFRegister

-(void)show{
	
	[super showBackground:@"ef_resources/bg_login.jpg"];
	[super showCloseBtn];
	[super showTitle:@"用户注册"];
	
//	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-332)/2, 60, 332, 132)];
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-337)/2, 80, 337, 114)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_3.png"];
	[self addSubview:bg];
	[bg release];
	
	UIButton * btn_modify = [EFBaseWindow getSmallButton:@"确  定"];
	[btn_modify setFrame:CGRectMake((480-332)/2,230,
									btn_modify.frame.size.width,
									btn_modify.frame.size.height)
	 ];
	[btn_modify addTarget:self action:@selector(doRegister:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_modify];
	
	UIButton * btn_login = [EFBaseWindow getSmallButton:@"已有帐号"];
	[btn_login setFrame:CGRectMake((480-332)/2+332-btn_login.frame.size.width,230,
									btn_login.frame.size.width,
									btn_login.frame.size.height)
	 ];
	[btn_login addTarget:self action:@selector(doLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_login];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(80,95,320,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"邮箱:";
	[self addSubview:label_1];
	
	UILabel * label_2 = [EFBaseWindow getLabel];
	label_2.frame = CGRectMake(80,150,320,30);
	label_2.font = [UIFont systemFontOfSize:21];
	label_2.textAlignment = UITextAlignmentLeft;
	label_2.text = @"密码:";
	[self addSubview:label_2];
	
//	UILabel * label_3 = [EFBaseWindow getLabel];
//	label_3.frame = CGRectMake(80,155,90,30);
//	label_3.font = [UIFont systemFontOfSize:21];
//	label_3.textAlignment = UITextAlignmentLeft;
//	label_3.text = @"确认密码:";
//	[self addSubview:label_3];
	
	input_1 = [EFBaseWindow getTextFieldPlaceholder];
	input_1.frame = CGRectMake(140,98,230,30);
	input_1.text = @"";
	input_1.keyboardType = UIKeyboardTypeEmailAddress;
	input_1.placeholder = @"请输入正确的邮箱";
	[self addSubview:input_1];
	
	input_2 = [EFBaseWindow getTextField];
	input_2.frame = CGRectMake(140,153,230,30);
	input_2.text = @"";
	input_2.secureTextEntry = YES;
	input_2.clearsOnBeginEditing = NO;
	[self addSubview:input_2];
	
//	input_3 = [EFBaseWindow getTextField];
//	input_3.frame = CGRectMake(173,157,230,30);
//	input_3.text = @"";
//	input_3.secureTextEntry = YES;
//	input_3.clearsOnBeginEditing = NO;
//	[self addSubview:input_3];
	
	input_1.delegate = self;
	input_2.delegate = self;
//	input_3.delegate = self;
	
	input_1.tag = 1;
	input_2.tag = 2;
//	input_3.tag = 3;
	
}

-(void)doRegister:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	[input_2 resignFirstResponder];
//	[input_3 resignFirstResponder];
	
//	NSString * emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString * emailRegex = @"^\\w+((\\-\\w+)|(\\.\\w+))*@[A-Za-z0-9]+((\\.|\\-)[A-Za-z0-9]+)*.[A-Za-z0-9]+$";
    NSPredicate * emailVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	if(![emailVerify evaluateWithObject:input_1.text]){
		[EFAlert alert:@"请输入正确的邮箱地址!"];
		return;
	}
	if([input_2.text length]<6){
		[EFAlert alert:@"请输入6位或以上的密码!"];
		return;
	}
	NSString * passwordRegex = @"[A-Z0-9a-z]+[A-Za-z0-9]";
    NSPredicate * passwordVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
	if(![passwordVerify evaluateWithObject:input_2.text]){
		[EFAlert alert:@"请输入由数字与大小写字母组成的密码!"];
		return;
	}
//	if(![input_2.text isEqualToString:input_3.text]){
//		[EFAlert alert:@"请输入与[用户密码]一致的[确认密码]!"];
//		return;
//	}
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:input_1.text forKey:@"email"];
	[userInfo setObject:input_2.text forKey:@"password"];
	[EFUserAction registerUser:userInfo];
	
	[EFUIWindow showLoading];
    //
}

-(void)doLogin:(id)sender
{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow showLogin];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
	isBeginInput = YES;
	if([EFUIWindow isRunOniPhone]){
//		if(textField.tag==3){
//			[EFUIWindow moveContentToY:-96];
//		}else{
//			[EFUIWindow moveContentToY:-50];
//		}
		[EFUIWindow moveContentToY:-50];
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
//	if(textField.tag==2) [input_3 becomeFirstResponder];
//	if(textField.tag==3) [textField resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField{
	if(!isBeginInput){
		[EFUIWindow moveContentToOrigin];
	}
	isBeginInput = NO;
}

@end
