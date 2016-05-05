//
//  EFunUC.h
//  EFunUC
//
//  Created by TigerLeung on 13-4-24.
//  Copyright (c) 2013年 Turbo-X . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFPostNotification.h"

#define EFUN_USER_CENTER_VERSION 0x0000001

@interface EFunUC : NSObject{
	int appId;
	NSString * appKey;
}
@property(nonatomic,readonly) int appId;

+(EFunUC*)shared;

-(BOOL)isLogin;
-(BOOL)isGuest;

-(int)userId;
-(NSString*)userName;

#pragma mark actions

-(void)setAppId:(int)aid AppKey:(NSString*)key;

-(void)autoLogin;
-(void)login;
-(void)logout;

-(void)enterUserCenter;

@end

