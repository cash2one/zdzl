//
//  InAppPurchasesHelper.h
//  TXSFGame
//
//  Created by TigerLeung on 13-4-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface InAppPurchasesHelper : NSObject <SKPaymentTransactionObserver> {
	
	//id verifyer;
	//SEL verifyCall;
	
}

+(InAppPurchasesHelper*)shared;

-(void)purchases:(NSString*)product order:(NSString*)order;
-(void)purchases:(NSString*)product order:(NSString*)order target:(id)target call:(SEL)call;

-(void)checkVerify:(BOOL)isPass;

@end

@interface InAppPurchasesVerify : NSObject{
	SKPaymentTransaction * paymentTransaction;
}
@end
