//
//  Notice.m
//  TXSFGame
//
//  Created by peak on 13-8-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Notice.h"
#import "Window.h"
#import "intro.h"
#import "CCPanel.h"

@implementation Notice

-(void)onEnter{
	[super onEnter];
    //
    [self loadNotice];
}
-(void)loadNotice{
    CCSprite *note_bg = nil;
    NSDictionary * serverInfo = [GameConnection share].serverInfo;
	NSString * note= [serverInfo objectForKey:@"notice"];
	if(note && [note length]>1){
		int fontSize=18;
		if(iPhoneRuningOnGame()){
			fontSize=28;
		}else{
			fontSize=18;
		}
		
		NSArray *noteAr=[note componentsSeparatedByString:@"|"];
		NSString *drawcontent=@"";
		for(NSString *c in noteAr){
			NSArray *dc=[c componentsSeparatedByString:@"#"];
			if(dc.count>1){
				drawcontent =[drawcontent stringByAppendingFormat:@"%@#38d3ff#%i#0#URL%@|",[dc objectAtIndex:0],fontSize,[dc objectAtIndex:1]];
			}else{
				drawcontent=[drawcontent stringByAppendingFormat:@"%@#ffffff#%i#0|",[dc objectAtIndex:0],fontSize];
			}
		}
		
		note_bg = [CCSprite spriteWithFile:@"images/start/note.png"];
        note_bg = getSpriteWithSpriteAndNewSize(note_bg, CGSizeMake(note_bg.contentSize.width*1.3, note_bg.contentSize.height*1.3));
		self.contentSize = note_bg.contentSize;
		CCSprite *cccbg=[CCSprite node];
		CCSprite *cccontent=nil;

        int base_w = note_bg.contentSize.width-cFixedScale(50);
        int base_h = note_bg.contentSize.height-cFixedScale(100);
        
		if(iPhoneRuningOnGame())
		{
			cccontent=drawString(drawcontent, CGSizeMake(base_w*2-50/2, 1*2), getCommonFontName(FONT_1), fontSize, fontSize+2, @"ffffff");
		}else{
			cccontent=drawString(drawcontent, CGSizeMake(base_w, 1), getCommonFontName(FONT_1), fontSize, fontSize+2, @"ffffff");
		}
        
        int w_ = cccontent.contentSize.width;
        int h_ = cccontent.contentSize.height;
        
        if(cccontent.contentSize.width<base_w){
			w_ = base_w;
		}
        
		if(cccontent.contentSize.height<base_h){
            h_ = base_h;
		}

        cccbg.contentSize=CGSizeMake(w_, h_);
        
		CGSize showsize=CGSizeMake(w_, base_h);
		CCPanel *panel=[CCPanel panelWithContent:cccbg viewSize:showsize];
		
		
		[cccontent setPosition:ccp(0, cccbg.contentSize.height-cccontent.contentSize.height)];
		[panel setPosition:ccp(cFixedScale(20), cFixedScale(20))];
		[panel showScrollBar:@"images/ui/common/scroll3.png"];
		[panel updateContentToTop];
		[note_bg setAnchorPoint:ccp(0, 0)];
		[cccontent setAnchorPoint:ccp(0, 0)];
		[cccbg setAnchorPoint:ccp(0, 0)];
		
		[cccbg addChild:cccontent];
		[note_bg addChild:panel];
		[self addChild:note_bg];
        //
        _closeBnt = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/btn_tipsclose.png"
                                            select:nil
                                            target:self
                                              call:@selector(closeWindow)
                                          priority:_closePy];
        _closeBnt.opacity = 0;
        if (iPhoneRuningOnGame()) {
            _closeBnt.scale = 0.95f;
        }
        _closeBnt.position = ccp(self.contentSize.width-_closeBnt.contentSize.width/2,self.contentSize.height-_closeBnt.contentSize.height);
        // ccpAdd([self getClosePosition],ccp(_closeBnt.contentSize.width/2,_closeBnt.contentSize.height/4));
        [self addChild:_closeBnt z:100];
	}else{
        [self closeWindow];
    }
}

-(CCSprite*)getBackground:(NSString*)path
{
	return nil;
}

-(void)onExit{
	[super onExit];
}

+(void)showNotice{
    [[Window shared] showWindow:PANEL_NOTICE];
}
@end
