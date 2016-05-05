//
//  InAppPurchasesHelper.m
//  TXSFGame
//
//  Created by TigerLeung on 13-4-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "InAppPurchasesHelper.h"
#import "NSString+MD5Addition.h"
#import "NSData+Base64.h"
#import "SVProgressHUD.h"
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"

#if GAME_SNS_TYPE==5
#define InAppPurchasesHelperVerifyUrl @"http://web1.zl.52yh.com:18000/api/app/checkPay";
#endif

#if GAME_SNS_TYPE==6
#define InAppPurchasesHelperVerifyUrl @"http://web1.zl.52yh.com:19000/api/apptw/checkPay";
#endif

#if GAME_SNS_TYPE==7
#define InAppPurchasesHelperVerifyUrl @"http://web1.zl.52yh.com:21000/api/appyd/checkPay";
#endif

@interface InAppPurchasesVerify (Internal)

+(void)cacheProduct:(NSString*)product order:(NSString*)order;
+(NSString*)loadOrderByProduct:(NSString*)product;
+(void)removeOrderByProduct:(NSString*)product;

+(void)verifyTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful;

@end

@implementation InAppPurchasesHelper

static InAppPurchasesHelper * iapHelper;

+(InAppPurchasesHelper*)shared{
	if(iapHelper==nil){
		iapHelper = [[InAppPurchasesHelper alloc] init];
	}
	return iapHelper;
}

-(id)init{
	if((self=[super init])!=nil){
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	}
	return self;
}

-(void)dealloc{
	[super dealloc];
}

-(void)purchases:(NSString*)product order:(NSString*)order{
	[self purchases:product order:order target:nil call:nil];
}

-(void)purchases:(NSString*)product order:(NSString*)order target:(id)target call:(SEL)call{
	
	BOOL isCanPayment = YES;
	if([product length]==0)					isCanPayment = NO;
	if([order length]==0)					isCanPayment = NO;
	if(![SKPaymentQueue canMakePayments])	isCanPayment = NO;
	
	if(isCanPayment){
		
		[InAppPurchasesVerify cacheProduct:product order:order];
		
		//verifyer = target;
		//verifyCall = call;
		
		SKPayment * payment = [SKPayment paymentWithProductIdentifier:product];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		
		[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
		
	}else{
		/*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"purchases_helper_cue",nil)
														 message:NSLocalizedString(@"purchases_helper_buy",nil)
														delegate:nil
											   cancelButtonTitle:NSLocalizedString(@"purchases_helper_sure",nil)
											   otherButtonTitles:nil];
		[alert show];
		[alert release];
		*/
	}
	
}

#pragma mark -

-(void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions{
	for(SKPaymentTransaction * transaction in transactions){
		switch(transaction.transactionState){
			case SKPaymentTransactionStatePurchased:
				[self finishTransaction:transaction wasSuccessful:YES];
				break;
			case SKPaymentTransactionStateFailed:
				[self finishTransaction:transaction wasSuccessful:NO];
				break;
			case SKPaymentTransactionStateRestored:
				[self finishTransaction:transaction wasSuccessful:YES];
				break;
			default:
				break;
        }
    }
}

#pragma mark Purchase helpers

-(void)finishTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful{
	
	[InAppPurchasesVerify verifyTransaction:transaction wasSuccessful:wasSuccessful];
	
}

-(void)checkVerify:(BOOL)isPass{
	
}

@end

@implementation InAppPurchasesVerify

static NSMutableArray * purchasesMemory;

+(void)cacheProduct:(NSString*)product order:(NSString*)order{
	NSMutableArray * result = [NSMutableArray array];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSArray * cache = [defaults arrayForKey:@"z_temp_cache"];
	if(cache!=nil){
		[result addObjectsFromArray:cache];
	}
	NSMutableDictionary * payData = [NSMutableDictionary dictionary];
	[payData setObject:product forKey:@"1"];
	[payData setObject:order forKey:@"2"];
	
	[result addObject:payData];
	
	[defaults setObject:result forKey:@"z_temp_cache"];
	[defaults synchronize];
}

+(NSString*)loadOrderByProduct:(NSString*)product{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSArray * cache = [defaults arrayForKey:@"z_temp_cache"];
	if(cache!=nil){
		for(NSDictionary * payData in cache){
			NSString * t_p = [payData objectForKey:@"1"];
			if([t_p isEqualToString:product]){
				return [payData objectForKey:@"2"];
			}
		}
	}
	return nil;
}

+(void)removeOrderByProduct:(NSString*)product{
	NSMutableArray * result = [NSMutableArray array];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSArray * cache = [defaults arrayForKey:@"z_temp_cache"];
	if(cache!=nil){
		for(NSDictionary * payData in cache){
			if(![[payData objectForKey:@"1"] isEqualToString:product]){
				[result addObject:payData];
			}
		}
	}
	[defaults setObject:result forKey:@"z_temp_cache"];
	[defaults synchronize];
}

+(void)saveToMemory:(id)target{
	if(purchasesMemory==nil){
		purchasesMemory = [[NSMutableArray alloc] init];
	}
	if(target){
		[purchasesMemory addObject:target];
	}
}

+(void)removeFromMemory:(id)target{
	if(purchasesMemory!=nil && target!=nil){
		[purchasesMemory removeObject:target];
	}
}


+(void)verifyTransaction:(SKPaymentTransaction*)transaction wasSuccessful:(BOOL)wasSuccessful{
	InAppPurchasesVerify * verify = [[[InAppPurchasesVerify alloc] initWithTransaction:transaction] autorelease];
	[verify checkWasSuccessful:wasSuccessful];
}

-(InAppPurchasesVerify*)initWithTransaction:(SKPaymentTransaction*)transaction{
	if((self=[super init])!=nil){
		paymentTransaction = transaction;
		[paymentTransaction retain];
		[InAppPurchasesVerify saveToMemory:self];
	}
	return self;
}

-(void)checkWasSuccessful:(BOOL)wasSuccessful{
	if(wasSuccessful){
		[self verifyTransaction];
	}else{
		if(paymentTransaction.error.code != SKErrorPaymentCancelled){
			UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"purchases_helper_buy_error",nil)
															 message:paymentTransaction.error.localizedDescription
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"purchases_helper_sure",nil)
												   otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
		[self overPaymentTransaction:NO];
	}
}

-(void)dealloc{
	if(paymentTransaction){
		[paymentTransaction release];
		paymentTransaction = nil;
	}
	[super dealloc];
}

-(void)verifyTransaction{
	
	NSString * order = [InAppPurchasesVerify loadOrderByProduct:paymentTransaction.payment.productIdentifier];
	if(order){
		
		NSString * transactionId = paymentTransaction.transactionIdentifier;
		NSData * receiptData = paymentTransaction.transactionReceipt;
		
		/*
		NSString* aStr = [[[NSString alloc] initWithData:receiptData encoding:NSUTF8StringEncoding] autorelease];
		NSString * bStr = [aStr stringByReplacingOccurrencesOfString:@";" withString:@","];
		bStr = [bStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		bStr = [bStr stringByReplacingOccurrencesOfString:@"	" withString:@""];
		bStr = [bStr stringByReplacingOccurrencesOfString:@",}" withString:@"}"];
		bStr = [bStr stringByReplacingOccurrencesOfString:@" = " withString:@":"];
		bStr = [bStr stringByReplacingOccurrencesOfString:@" " withString:@""];
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer]
							   deserializeAsDictionary:[bStr dataUsingEncoding:NSUTF8StringEncoding]
							   error:&error];
		if(json){
			
		}
		*/
		
		NSString * receipt = [receiptData base64EncodedString];
		
		NSString * urlString = InAppPurchasesHelperVerifyUrl;
		
		NSURL * url = [NSURL URLWithString:urlString];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		
		[request addPostValue:transactionId forKey:@"transactionId"];
		[request addPostValue:order forKey:@"order"];
		[request addPostValue:receipt forKey:@"receipt"];
		
		[request setCompletionBlock:^{
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer]
								   deserializeAsDictionary:[request responseData]
								   error:&error];
			if(!error){
				if([[json objectForKey:@"status"] intValue] == 1){
					[self overPaymentTransaction:YES];
					return;
				}
			}
			[self overPaymentTransaction:NO];
		}];
		[request setFailedBlock:^{
			[self overPaymentTransaction:NO];
		}];
		
		[request setRequestMethod:@"POST"];
		[request setTimeOutSeconds:30*60];
		[request startAsynchronous];
		
	}else{
		[self overPaymentTransaction:YES];
	}
	
	/*
	if(verifyer!=nil && verifyCall!=nil){
		
		NSString * receipt = [receiptData base64EncodedString];
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		
		[data setObject:transactionId forKey:@"transactionId"];
		[data setObject:orderId forKey:@"gorder"];
		[data setObject:receipt forKey:@"receipt"];
		
		[verifyer performSelector:verifyCall withObject:data];
		
	}else{
		
		[self overPaymentTransaction:YES];
		
	}
	*/
	
}

-(void)overPaymentTransaction:(BOOL)isPass{
	
	if(paymentTransaction){
		[InAppPurchasesVerify removeOrderByProduct:paymentTransaction.payment.productIdentifier];
		[[SKPaymentQueue defaultQueue] finishTransaction:paymentTransaction];
		[paymentTransaction release];
		paymentTransaction = nil;
	}
	
	[InAppPurchasesVerify removeFromMemory:self];
	
	if([purchasesMemory count]==0){
		[SVProgressHUD dismissWithAfterDelay:0.28f];
	}
	
	
}

@end
