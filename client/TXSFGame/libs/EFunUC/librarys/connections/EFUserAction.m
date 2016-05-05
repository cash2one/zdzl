//
//  EFUserAction.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFUserAction.h"
#import "EFunUC.h"
#import "EFUserInfo.h"
#import "EFPostNotification.h"
#import "EFDeviceInfo.h"
#import "EFAlert.h"
#import "EFUIWindow.h"

#import "CJSONDeserializer.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

//#define EF_UserCenter_API @"http://dev.zl.efun.com:5005"
#define EF_UserCenter_API @"http://web1.zl.52yh.com:5005"
//#define EF_UserCenter_API @"http://web1.zl.52yh.com:5006"

@implementation EFUserAction

static bool s_isSend = NO;

+(void)autoLogin{
	
	int chooseId = [EFUserInfo chooseUserId];
	NSString * token = [EFUserInfo token];
	
	if(chooseId>0 && token==nil){
		//[[EFunUC shared] login];
		//return;
	}
	
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/check",EF_UserCenter_API]];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	//
    if (request) {
        s_isSend = YES;
    }
    //
	NSString * appId = [NSString stringWithFormat:@"%d",[EFunUC shared].appId];
	[request setPostValue:appId forKey:@"aid"];
	[request setPostValue:[EFDeviceInfo macaddress] forKey:@"mac"];
	[request setPostValue:[EFDeviceInfo model] forKey:@"model"];
	[request setPostValue:[EFDeviceInfo version] forKey:@"version"];
	
	if(token){
		[request setPostValue:token forKey:@"token"];
	}
	
	[request setCompletionBlock:^{
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:[request responseData] error:&error];
		if(!error){
			if([[json objectForKey:@"status"] intValue]==1){
				NSDictionary * result = [json objectForKey:@"result"];
				
				if(![[result objectForKey:@"other"] isKindOfClass:[NSNull class]]){
					NSArray * other = [result objectForKey:@"other"];
					for(id user in other){
						[EFUserInfo saveUser:user];
						[EFUserInfo chooseUser:[result objectForKey:@"user"]];
					}
				}
				
				[EFUserInfo saveUser:[result objectForKey:@"user"]];
				[EFUserInfo chooseUser:[result objectForKey:@"user"]];
				
				NSString * token = [result objectForKey:@"token"];
				if([token length]>0){
					[EFUserInfo saveToken:[result objectForKey:@"token"]];
					[EFUserInfo currentUser:[result objectForKey:@"user"]];
				}
				
				// 如果不是注册用户，弹出注册框
				NSDictionary *user = [result objectForKey:@"user"];
				if (user == nil || [user isKindOfClass:[NSNull class]]) {
					[EFUIWindow showUserRegister];
				} else {
					int type = [[user objectForKey:@"type"] intValue];
					
					//游客
					if(type==1){
						[EFUserInfo currentUser:[result objectForKey:@"user"]];
					}
					
					if (type != 3) {
						[EFUIWindow showUserRegister];
					}
				}
				[EFUserInfo synchronize];
				
				//NSDictionary * app = [result objectForKey:@"app"];
				//[[EFunUC shared] updateAppInfo:app];
				
			}else{
				[EFAlert alert:[json objectForKey:@"message"]];
			}
		}
		[EFPostNotification postLogin];
        //
        s_isSend = NO;
	}];
	
	[request setFailedBlock:^{
		[EFPostNotification postLogin];
        //
        s_isSend = NO;
	}];
	
	[request setRequestMethod:@"POST"];
	[request setTimeOutSeconds:300];
	[request startAsynchronous];
	
}

+(void)login:(NSDictionary*)userInfo{
	
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/login",EF_UserCenter_API]];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	//
    if (request) {
        s_isSend = YES;
    }
    //
	NSString * appId = [NSString stringWithFormat:@"%d",[EFunUC shared].appId];
	[request setPostValue:appId forKey:@"aid"];
	[request setPostValue:[EFDeviceInfo macaddress] forKey:@"mac"];
	[request setPostValue:[EFDeviceInfo model] forKey:@"model"];
	[request setPostValue:[EFDeviceInfo version] forKey:@"version"];
	
	[request setPostValue:[userInfo objectForKey:@"email"] forKey:@"email"];
	[request setPostValue:[userInfo objectForKey:@"password"] forKey:@"password"];
	
	[request setCompletionBlock:^{
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:[request responseData] error:&error];
		if(!error){
			if([[json objectForKey:@"status"] intValue]==1){
				
				NSDictionary * result = [json objectForKey:@"result"];
				[EFUserInfo saveToken:[result objectForKey:@"token"]];
				[EFUserInfo saveUser:[result objectForKey:@"user"]];
				[EFUserInfo chooseUser:[result objectForKey:@"user"]];
				[EFUserInfo currentUser:[result objectForKey:@"user"]];
				
				[EFUserInfo synchronize];
				
				[EFPostNotification postLogin];
				
				[EFUIWindow hideLoading];
				[EFUIWindow closeWindowsWithDelay:0.25f];
				
				//[EFUIWindow showUserCenter];
				
			}else{
				[EFAlert alert:[json objectForKey:@"message"]];
				[EFUIWindow hideLoading];
			}
		}else{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
		}
        //
        s_isSend = NO;
	}];
	[request setFailedBlock:^{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
        //
        s_isSend = NO;
	}];
	[request setRequestMethod:@"POST"];
	[request setTimeOutSeconds:300];
	[request startAsynchronous];
	
}

+(void)logout{
	EFUserInfo * currentUserInfo = [EFUserInfo currentUserInfo];
	if(currentUserInfo!=nil){
		if(![currentUserInfo isGuest]){
			
			NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/logout",EF_UserCenter_API]];
			ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
			//
            if (request) {
                s_isSend = YES;
            }
            //
			[request setPostValue:[currentUserInfo getUserId] forKey:@"uid"];
			[request setPostValue:[EFUserInfo token] forKey:@"token"];
			
			[request setCompletionBlock:^{
				
				NSError * error = nil;
				NSDictionary * json = [[CJSONDeserializer deserializer] 
									   deserializeAsDictionary:[request responseData] error:&error];
				if(!error){
					if([[json objectForKey:@"status"] intValue]==1){
						
						[EFUserInfo logoutCurrrentUser];
						[EFPostNotification postLogout];
						
						[EFUIWindow hideLoading];
						[EFUIWindow showLogin];
						
					}else{
						[EFAlert alert:[json objectForKey:@"message"]];
						[EFUIWindow hideLoading];
					}
				}else{
					[EFAlert alert:@"网络连接错误!"];
					[EFUIWindow hideLoading];
				}
                //
                s_isSend = NO;
			}];
			[request setFailedBlock:^{
				[EFAlert alert:@"网络连接错误!"];
				[EFUIWindow hideLoading];
                //
                s_isSend = NO;
			}];
			[request setRequestMethod:@"POST"];
			[request setTimeOutSeconds:300];
			[request startAsynchronous];
			
		}else{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
		}
	}else{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
	}
}

+(void)createGuest{
	
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/create",EF_UserCenter_API]];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	//
    if (request) {
        s_isSend = YES;
    }
    //
	NSString * appId = [NSString stringWithFormat:@"%d",[EFunUC shared].appId];
	[request setPostValue:appId forKey:@"aid"];
	[request setPostValue:[EFDeviceInfo macaddress] forKey:@"mac"];
	[request setPostValue:[EFDeviceInfo model] forKey:@"model"];
	[request setPostValue:[EFDeviceInfo version] forKey:@"version"];
	
	[request setCompletionBlock:^{
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:[request responseData] error:&error];
		if(!error){
			if([[json objectForKey:@"status"] intValue]==1){
				
				NSDictionary * result = [json objectForKey:@"result"];
				[EFUserInfo saveToken:[result objectForKey:@"token"]];
				[EFUserInfo saveUser:[result objectForKey:@"user"]];
				[EFUserInfo chooseUser:[result objectForKey:@"user"]];
				[EFUserInfo currentUser:[result objectForKey:@"user"]];
				[EFUserInfo synchronize];
				
				[EFUIWindow hideLoading];
				//[EFUIWindow closeWindows];
				[NSTimer scheduledTimerWithTimeInterval:0.38f 
												 target:[EFUIWindow class] 
											   selector:@selector(closeWindows) 
											   userInfo:nil 
												repeats:NO];
				
			}else{
				[EFAlert alert:[json objectForKey:@"message"]];
				[EFUIWindow hideLoading];
			}
		}else{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
		}
		
		[EFPostNotification postLogin];
		//
        s_isSend = NO;
	}];
	[request setFailedBlock:^{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
        //
        s_isSend = NO;
	}];
	[request setRequestMethod:@"POST"];
	[request setTimeOutSeconds:300];
	[request startAsynchronous];
}

+(void)registerUser:(NSDictionary*)userInfo{
	
	EFUserInfo * currentUserInfo = [EFUserInfo currentUserInfo];
	if(currentUserInfo!=nil || YES){
		
		NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/register",EF_UserCenter_API]];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		//
        if (request) {
            s_isSend = YES;
        }
        // 如果没游客，发送相关创建游客数据
		if (currentUserInfo == nil) {
			NSString * appId = [NSString stringWithFormat:@"%d",[EFunUC shared].appId];
			[request setPostValue:appId forKey:@"aid"];
			[request setPostValue:[EFDeviceInfo macaddress] forKey:@"mac"];
			[request setPostValue:[EFDeviceInfo model] forKey:@"model"];
			[request setPostValue:[EFDeviceInfo version] forKey:@"version"];
			
			[request setPostValue:[NSNumber numberWithInt:-1] forKey:@"uid"];
		} else {
			[request setPostValue:[currentUserInfo getUserId] forKey:@"uid"];
			[request setPostValue:[EFUserInfo token] forKey:@"token"];
		}
		[request setPostValue:[userInfo objectForKey:@"email"] forKey:@"email"];
		[request setPostValue:[userInfo objectForKey:@"password"] forKey:@"password"];
		
		[request setCompletionBlock:^{
			
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer] 
								   deserializeAsDictionary:[request responseData] error:&error];
			if(!error){
				if([[json objectForKey:@"status"] intValue]==1){
					
					NSDictionary * result = [json objectForKey:@"result"];
					[EFUserInfo saveToken:[result objectForKey:@"token"]];
					[EFUserInfo saveUser:[result objectForKey:@"user"]];
					[EFUserInfo chooseUser:[result objectForKey:@"user"]];
					[EFUserInfo currentUser:[result objectForKey:@"user"]];
					[EFUserInfo synchronize];
					
					[EFUIWindow hideLoading];
					[EFUIWindow showUserCenter];
					
					[EFPostNotification postLogin];
					
				}else{
					[EFAlert alert:[json objectForKey:@"message"]];
					[EFUIWindow hideLoading];
				}
			}else{
				[EFAlert alert:@"网络连接错误!"];
				[EFUIWindow hideLoading];
			}
            //
            s_isSend = NO;
		}];
		[request setFailedBlock:^{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
            //
            s_isSend = NO;
		}];
		[request setRequestMethod:@"POST"];
		[request setTimeOutSeconds:300];
		[request startAsynchronous];
	}else{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
	}
}

+(void)modifyUser:(NSDictionary*)userInfo{
	
	EFUserInfo * currentUserInfo = [EFUserInfo currentUserInfo];
	if(currentUserInfo!=nil){
		
		NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/modify",EF_UserCenter_API]];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		//
        if (request) {
            s_isSend = YES;
        }
        //
		[request setPostValue:[currentUserInfo getUserId] forKey:@"uid"];
		[request setPostValue:[EFUserInfo token] forKey:@"token"];
		[request setPostValue:[userInfo objectForKey:@"email"] forKey:@"email"];
		[request setPostValue:[userInfo objectForKey:@"password"] forKey:@"password"];
		[request setPostValue:[userInfo objectForKey:@"newpassword"] forKey:@"newpassword"];
		
		[request setCompletionBlock:^{
			
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer] 
								   deserializeAsDictionary:[request responseData] error:&error];
			if(!error){
				if([[json objectForKey:@"status"] intValue]==1){
					
					[EFAlert alert:[json objectForKey:@"message"]];
					[EFUIWindow hideLoading];
					//[EFUIWindow showUserCenter];
					
				}else{
					[EFAlert alert:[json objectForKey:@"message"]];
					[EFUIWindow hideLoading];
				}
			}else{
				[EFAlert alert:@"网络连接错误!"];
				[EFUIWindow hideLoading];
			}
            //
            s_isSend = NO;
		}];
		[request setFailedBlock:^{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
            //
            s_isSend = NO;
		}];
		[request setRequestMethod:@"POST"];
		[request setTimeOutSeconds:300];
		[request startAsynchronous];
	}else{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
	}
}

+(void)changeNickname:(NSString*)nickname{
	EFUserInfo * currentUserInfo = [EFUserInfo currentUserInfo];
	if(currentUserInfo!=nil){
		
		NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/rename",EF_UserCenter_API]];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		//
        if (request) {
            s_isSend = YES;
        }
        //
		[request setPostValue:[currentUserInfo getUserId] forKey:@"uid"];
		[request setPostValue:[EFUserInfo token] forKey:@"token"];
		[request setPostValue:nickname forKey:@"nickname"];
		
		[request setCompletionBlock:^{
			
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer] 
								   deserializeAsDictionary:[request responseData] error:&error];
			if(!error){
				if([[json objectForKey:@"status"] intValue]==1){
					
					NSDictionary * result = [json objectForKey:@"result"];
					[EFUserInfo saveUser:[result objectForKey:@"user"]];
					[EFUserInfo synchronize];
					
					[EFUIWindow hideLoading];
					//[EFUIWindow showUserCenter];
					
					[EFPostNotification postLogin];
					
				}else{
					[EFAlert alert:[json objectForKey:@"message"]];
					[EFUIWindow hideLoading];
				}
			}else{
				[EFAlert alert:@"网络连接错误!"];
				[EFUIWindow hideLoading];
			}
            //
            s_isSend = NO;
		}];
		[request setFailedBlock:^{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
            //
            s_isSend = NO;
		}];
		[request setRequestMethod:@"POST"];
		[request setTimeOutSeconds:300];
		[request startAsynchronous];
	}else{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
	}
}

+(void)forget:(NSString*)email{
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/forget",EF_UserCenter_API]];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	//
    if (request) {
        s_isSend = YES;
    }
    //
	[request setPostValue:email forKey:@"email"];
	
	[request setCompletionBlock:^{
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:[request responseData] error:&error];
		if(!error){
			if([[json objectForKey:@"status"] intValue]==1){
				
				NSString * msg = [NSString stringWithFormat:@"新的密码已发送到%@,请注意查收邮件!",email];
				[EFAlert alert:msg];
				
				[EFUIWindow hideLoading];
				[EFUIWindow returnWindow];
				
			}else{
				[EFAlert alert:[json objectForKey:@"message"]];
				[EFUIWindow hideLoading];
			}
		}else{
			[EFAlert alert:@"网络连接错误!"];
			[EFUIWindow hideLoading];
		}
        //
        s_isSend = NO;
	}];
	[request setFailedBlock:^{
		[EFAlert alert:@"网络连接错误!"];
		[EFUIWindow hideLoading];
        //
        s_isSend = NO;
	}];
	[request setRequestMethod:@"POST"];
	[request setTimeOutSeconds:300];
	[request startAsynchronous];
}
+(BOOL)isSend{
    return s_isSend;
}
@end
