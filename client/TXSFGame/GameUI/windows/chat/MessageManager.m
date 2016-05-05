//
//  MessageManager.m
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MessageManager.h"
#import "GameConnection.h"
#import "Game.h"
#import "ChatPanelBase.h"

@implementation MessageData


@synthesize channelId;
@synthesize name;
@synthesize content;


-(id)initMessage:(NSString*)_name :(NSString*)_content :(int)_channelId{
	
	if((self = [super init])!=nil){
		self.name=_name;
		self.channelId=_channelId;
		self.content=_content;
	}
	return self;
}
@end


@implementation MessagePatcher

@synthesize call;
@synthesize target;

@end





static MessageManager* s_MessageManager = nil ;

@implementation MessageManager

@synthesize messageList;
@synthesize dispatcherPool;


+(MessageManager*)share{
	if(!s_MessageManager){
		s_MessageManager = [[MessageManager alloc]init];
	}
	return s_MessageManager;
}

-(id)init
{
	if (self = [super init]) {
		[GameConnection addPost:ConnPost_ChatPush target:self call:@selector(receive:)];
	}
	return self;
}

-(void)dealloc{
	[GameConnection removePostTarget:self];
	[messageList release];
	[dispatcherPool release];
	[super dealloc];
}

+(void)stopAll{
	if(s_MessageManager){
		[s_MessageManager release];
		s_MessageManager = nil;
	}
}

-(void)start{
	if(messageList){
		[messageList release];
		messageList = nil;
	}
	if(dispatcherPool){
		[dispatcherPool release];
		dispatcherPool = nil;
	}
	
	messageList = [[NSMutableArray alloc]init];
	dispatcherPool = [[NSMutableArray alloc]init];
	
}

-(void)addDispatcherPool:(id)target :(SEL)call{
	MessagePatcher *mp=[[MessagePatcher alloc]init];
	[mp setTarget:target];
	[mp setCall:call];
	[dispatcherPool addObject:mp];
	[mp release];
}

-(void)removeDispatcherPool:(id)target{
	for(MessagePatcher *mp in dispatcherPool){
		if(mp.target == target){
			[dispatcherPool removeObject:mp];
			return;
		}
	}
}


-(void)receive:(NSNotification *)data{
	
	NSArray *array=data.object;
	
	for(NSArray *ar in  array){
		NSString *name=[NSString stringWithFormat:@"%@",[ar objectAtIndex:2]];
		NSString *msg=[NSString stringWithFormat:@"%@",[ar objectAtIndex:1]];
		int channel=[[ar objectAtIndex:0] integerValue ];
		MessageData *_temp=[[MessageData alloc]initMessage:name :msg :channel];
		[messageList addObject:_temp];
		if(channel == CHANNEL_TUBA){
			[[AlertTuba share]addPost:msg];
		}
		for(MessagePatcher *mp in dispatcherPool){
			[mp.target performSelector:mp.call withObject:_temp];
		}
		[_temp release];
	}

	
    int len = CHAT_ARRAY_LEN;
    if (iPhoneRuningOnGame()) {
        len += 10;
    }
    if(messageList.count>len){
		NSRange rang;
		rang.length = messageList.count-len;
		rang.location=0;
		[messageList removeObjectsInRange:rang];
	}
	
}

@end

/*

static int s_Number_of_private_chat = 0 ;

static int messageHelper_tag = 0;
static int getMessageHelper_tag(){
	messageHelper_tag += 1;
	if(messageHelper_tag>INT16_MAX){
		messageHelper_tag = 1;
	}
	return messageHelper_tag;
}


int sortMessageHelper(MessageHelper *p1, MessageHelper*p2, void*context){
	if(p1.serialNumber>p2.serialNumber) return NSOrderedAscending;
	if(p1.serialNumber<p2.serialNumber) return NSOrderedDescending;
	return NSOrderedSame;
}

@implementation NSDictionary (MessageManager)
-(id)objectForChanel:(int)cid{
	NSString * key = [NSString stringWithFormat:@"%d",cid];
	return [self objectForKey:key];
}
@end

@implementation MessageHelper
@synthesize serialNumber;
@synthesize messageInfo;

-(id)init{
	if ((self = [super init]) != nil) {
		self.serialNumber = getMessageHelper_tag();
	}
	return self;
}

-(void)dealloc{
	if (messageInfo) {
		[messageInfo release];
		messageInfo = nil ;
	}
	//告诉那边删除了个什么东西
	[GameConnection post:MessageHelper_delete object:[NSNumber numberWithInt:serialNumber]];
	[super dealloc];
}

-(int)getChannel{
	CCLOG(@"MessageHelper getChannel");
	if (messageInfo && messageInfo.count > 0) {
		return [[messageInfo objectAtIndex:0] intValue];
	}
	return 0;
}

@end

@implementation MessageManager

@synthesize capacity;

+(MessageManager*)shared{
	if (s_MessageManager == nil) {
		s_MessageManager = [[MessageManager alloc] init];
	}
	return s_MessageManager ;
}

+(void)stopAll{
	if (s_MessageManager) {
		[s_MessageManager release];
		s_MessageManager = nil ;
	}
}


 @discussion 检查是不是需要统计私聊
 @result true 需要 false 不需要

+(BOOL)checkNeedToCount{
	return YES ;
}

-(void)start{
	[GameConnection addPost:ConnPost_ChatPush target:self call:@selector(receive:)];
}

-(id)init{
	if ((self = [super init]) != nil) {
		messageBuffs = [NSMutableDictionary dictionary];
		[messageBuffs retain];
		paintArray = [NSMutableArray array];
		[paintArray retain];
		
		capacity = 10 ;
		paintTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f
													  target:self
													selector:@selector(showMessage)
													userInfo:nil
													 repeats:YES];
	}
	return self ;
}

-(void)dealloc{
	if (messageBuffs) {
		[messageBuffs release];
		messageBuffs = nil ;
	}
	if (paintArray) {
		[paintArray release];
		paintArray = nil ;
	}
	if(paintTimer){
		[paintTimer invalidate];
		paintTimer = nil;
	}
	[GameConnection removePostTarget:self];
	[super dealloc];
}

-(void)showMessage{
	if (paintArray != nil && paintArray.count > 0) {
		MessageHelper* helper = [[[MessageHelper alloc] init] autorelease];
		helper.messageInfo = [paintArray objectAtIndex:0];
		[self addMessageBuff:[helper getChannel] message:helper];
		[paintArray removeObjectAtIndex:0];
		CCLOG(@"showMessage->paintArray->count=%d",paintArray.count);
		if (paintArray.count >= capacity*4) {
			//大于4倍的缓存，直接丢
			NSRange rang;
			rang.length=capacity;
			rang.location=0;
			[paintArray removeObjectsInRange:rang];
		}
	}
}

-(void)receive:(NSNotification*)data{
	if (data == nil || data.object  == nil) {
		return ;
	}
	NSArray* array = data.object;
	[paintArray addObjectsFromArray:array];
	
}

-(NSArray*)getChatsWithChanel:(int)cid{
	NSMutableArray* array = [NSMutableArray arrayWithArray:[messageBuffs objectForChanel:cid]];
	[array sortUsingFunction:sortMessageHelper context:nil];
	return array;
}

-(void)addMessageBuff:(int)chanel message:(MessageHelper*)_message{
	if (_message == nil) {
		return ;
	}
	
	NSMutableArray* array = [NSMutableArray arrayWithArray:[messageBuffs objectForChanel:chanel]];
	if (array.count >= capacity) {
		[array removeObjectAtIndex:0];
	}
	
	[array addObject:_message];
	[messageBuffs setObject:array forKey:[NSString stringWithFormat:@"%d",[_message getChannel]]];
	
	[GameConnection post:MessageHelper_add
				  object:_message];
	
	if ([_message getChannel] == CHANNEL_PRIVATE) {
		if (![MessageManager checkNeedToCount]) {
			s_Number_of_private_chat = 0 ;
			return ;
		}
		s_Number_of_private_chat++;
		[GameConnection post:MessageHelper_add_private
					  object:[NSNumber numberWithInt:s_Number_of_private_chat]];
	}
	
}

@end
*/
