//
//  PHStoreProductViewControllerDelegate.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 9/18/12.
//
//
#if PH_USE_STOREKIT!=0
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class SKStoreProductViewController;
@protocol SKStoreProductViewControllerDelegate;
@interface PHStoreProductViewControllerDelegate : NSObject<SKStoreProductViewControllerDelegate>{
    UIViewController *_visibleViewController;
}

+(PHStoreProductViewControllerDelegate *)getDelegate;
-(BOOL)showProductId:(NSString *)productId;

@end

#endif