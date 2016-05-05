//
//  EFModifyInfo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFModifyInfo.h"
#import "EFUIWindow.h"
#import "EFUserInfo.h"
#import "EFAlert.h"
#import "EFUserAction.h"

@implementation EFModifyInfo

-(void)show{
	[super showBackground:@"ef_resources/bg_general.jpg"];
	[super showCloseBtn];
	[super showTitle:@"修改资料"];
	[super showTabs:1];
	
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-332)/2, 60, 332, 132)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_2.png"];
	[self addSubview:bg];
	[bg release];
	
	UIButton * btn_modify = [EFBaseWindow getButton:@"确  定"];
	[btn_modify setFrame:CGRectMake((480-234)/2,195,
									btn_modify.frame.size.width,
									btn_modify.frame.size.height)
	 ];
	[btn_modify addTarget:self action:@selector(doModify:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_modify];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(85,70,80,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"邮箱 :";
	[self addSubview:label_1];
	
	UILabel * label_2 = [EFBaseWindow getLabel];
	label_2.frame = CGRectMake(85,113,80,30);
	label_2.font = [UIFont systemFontOfSize:21];
	label_2.textAlignment = UITextAlignmentLeft;
	label_2.text = @"旧密码:";
	[self addSubview:label_2];
	
	UILabel * label_3 = [EFBaseWindow getLabel];
	label_3.frame = CGRectMake(85,155,80,30);
	label_3.font = [UIFont systemFontOfSize:21];
	label_3.textAlignment = UITextAlignmentLeft;
	label_3.text = @"新密码:";
	[self addSubview:label_3];
	
	input_1 = [EFBaseWindow getTextField];
	input_1.frame = CGRectMake(170,72,230,30);
	input_1.text = [[EFUserInfo currentUserInfo] getUserEmail];
	input_1.keyboardType = UIKeyboardTypeEmailAddress;
	[self addSubview:input_1];
	
	input_2 = [EFBaseWindow getTextField];
	input_2.frame = CGRectMake(170,115,230,30);
	input_2.text = @"";
	input_2.secureTextEntry = YES;
	input_2.clearsOnBeginEditing = NO;
	[self addSubview:input_2];
	
	input_3 = [EFBaseWindow getTextField];
	input_3.frame = CGRectMake(170,157,230,30);
	input_3.text = @"";
	input_3.secureTextEntry = YES;
	input_3.clearsOnBeginEditing = NO;
	[self addSubview:input_3];
	
	input_1.delegate = self;
	input_2.delegate = self;
	input_3.delegate = self;
	
	input_1.tag = 1;
	input_2.tag = 2;
	input_3.tag = 3;
	
}

-(void)doModify:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	[input_2 resignFirstResponder];
	[input_3 resignFirstResponder];
	
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
	if([input_3.text length]<6){
		[EFAlert alert:@"请输入6位或以上的新密码!"];
		return;
	}
	NSString * passwordRegex = @"[A-Z0-9a-z]+[A-Za-z0-9]";
    NSPredicate * passwordVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
	if(![passwordVerify evaluateWithObject:input_2.text]){
		[EFAlert alert:@"请输入由数字与大小写字母组成的旧密码!"];
		return;
	}
	if(![passwordVerify evaluateWithObject:input_3.text]){
		[EFAlert alert:@"请输入由数字与大小写字母组成的新密码!"];
		return;
	}
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:input_1.text forKey:@"email"];
	[userInfo setObject:input_2.text forKey:@"password"];
	[userInfo setObject:input_3.text forKey:@"newpassword"];
	
	[EFUserAction modifyUser:userInfo];
	
	[EFUIWindow showLoading];
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
	if(textField.tag==2) [input_3 becomeFirstResponder];
	if(textField.tag==3) [textField resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField{
	if(!isBeginInput){
		[EFUIWindow moveContentToOrigin];
	}
	isBeginInput = NO;
}

@end
