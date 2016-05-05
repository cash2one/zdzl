//
//  DPayApplicationMessage.h
//  DPay
//
//  Created by lory qing on 11/28/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

@interface DPayApplicationMessage : NSObject {
    int _identity;
    NSString *_title;
    NSString *_content;
}

@property (nonatomic, assign) int identity;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
