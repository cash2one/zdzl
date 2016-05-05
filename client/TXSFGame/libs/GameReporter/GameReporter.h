//
//  GameReporter.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	GameReporterStatus_new		= 1,
	GameReporterStatus_reply	= 2,
	GameReporterStatus_close	= 3,
	GameReporterStatus_readed	= 4,
}GameReporterStatus;

@class GCDiscreetNotificationView;
@interface GameReporter : NSObject{
	
	NSString * baseUri;
	
	NSDictionary * reportData;
	NSMutableArray * reports;
	
	CGSize winSize;
	GCDiscreetNotificationView * notificationView;
	
	int timerCount;
	NSTimer * checkTimer;
	
}
@property(nonatomic,assign) CGSize winSize;
@property(nonatomic,assign) NSDictionary * reportData;
@property(nonatomic,readonly) NSMutableArray * reports;
@property(nonatomic,assign) NSString * baseUri;

+(GameReporter*)shared;
+(void)stopAll;

-(void)start;
-(void)stop;

-(void)show;
-(void)hide;

-(void)sendReport:(NSString*)report type:(int)type;
-(void)replyReport:(NSString*)report index:(int)index;

-(void)viewReportAtIndex:(int)index;

-(NSString*)getReportTitleAt:(int)index;
-(int)getReportContentCountAt:(int)index;

-(NSDictionary*)getReportContent:(int)cIndex infoAt:(int)mIndex;
-(NSString*)getReportContent:(int)cIndex msgAt:(int)mIndex;


@end
