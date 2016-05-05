//
//  MessageManager.h
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MessageHelper_delete			@"MessageHelper_delete"
#define MessageHelper_add				@"MessageHelper_add"
#define MessageHelper_add_private		@"MessageHelper_add_private"
#define CHAT_ARRAY_LEN (19)

@interface MessageData : NSObject{
	NSString *content;
	NSString *name;
	int channelId;
}

@property (nonatomic,retain)NSString *content;
@property (nonatomic,retain)NSString *name;
@property (nonatomic,assign)int channelId;


-(id)initMessage:(NSString*)_name :(NSString*)_content :(int)_channelId;

@end



@interface MessagePatcher : NSObject{
	id target;
	SEL call;
}

@property(nonatomic,assign)id target;
@property(nonatomic,assign)SEL call;

@end



@interface MessageManager : NSObject{
	NSMutableArray *messageList;
	NSMutableArray *dispatcherPool;
	
}


@property (nonatomic,retain)NSMutableArray* messageList;
@property (nonatomic,retain)NSMutableArray *dispatcherPool;

-(void)start;
-(void)receive:(NSNotification*)data;
+(MessageManager*)share;
+(void)stopAll;
-(void)addDispatcherPool:(id)target :(SEL)call;
-(void)removeDispatcherPool:(id)target;

@end


/*
@interface NSDictionary (MessageManager)
-(id)objectForChanel:(int)cid;
@end

@interface MessageHelper:NSObject{
	NSArray* messageInfo;
	int serialNumber;
}
@property(nonatomic,assign)int serialNumber;
@property(nonatomic,retain)NSArray* messageInfo;
-(int)getChannel;
@end

@interface MessageManager : NSObject{
	int capacity ;
	NSMutableDictionary* messageBuffs;
	NSTimer * paintTimer;
	NSMutableArray* paintArray;
}
@property(nonatomic,assign)int capacity ;
+(MessageManager*)shared;
+(void)stopAll;
-(NSArray*)getChatsWithChanel:(int)cid;
-(void)start;
@end
 */
