//
//  idsADAPI.h
//  ids
//  ids 广告api
//  Created by 何凌铿 on 13-4-1. qq:2357303
//  Copyright (c) 2013年 hlk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//植入式广告条 (web形式)
@interface idsADView : UIWebView<UIWebViewDelegate>
{
	UIButton *btnClose_;
	id webDelegate_;
}

@property(nonatomic, assign) id webDelegate;


- (id)initWithFrame:(CGRect)frame;
- (void)setADUnitID:(NSString *)adUnitID;
- (void)startLoadWeb;
- (void)cancel;

@end

@protocol idsADViewFinishDelegate

- (void)idsADViewDidFinish:(idsADView *)webView;
- (void)idsADViewDidFail:(idsADView *)webView;

@end


//橱窗广告
@protocol idsWinADViewDelegate;
@interface idsWinADView : UIView

@property (nonatomic,assign) id<idsWinADViewDelegate> webDelegate;
//手动设置大小
- (id)initWithFrame:(CGRect)frame;
//设置橱窗广告id
- (void)setWinADUnitID:(NSString *)winAdUnitID;
- (void)startLoadLocalWeb;//首次加载，以及无网络时候使用
- (void)startLoadWeb;
- (void)stopLoadWeb;
- (void)reload;
- (BOOL)isLoading;
@end

/////////////////////////////////////////////////

//广告业务 （橱窗广告以及广告条）
@interface idsAD : NSObject

//橱窗广告 全屏弹出，等控制；
+ (idsWinADView *)winAdInstance;
+ (void)setWinADUnitID:(NSString *)winAdUnitID andDelegate:(id)delegate;//设置广告橱窗id
+ (void)showWinAd;//显示广告橱窗
+ (void)dismissWinAd;//隐藏并且销毁广告橱窗
+ (BOOL)canDisplayWinAd;//判断是否可以显示广告橱窗

//植入式广告条（web形式）
+ (void)setADWebViewFrame:(CGRect)frame
                andUnitID:(NSString *)unitID
                   toView:(UIView *)parentView
                setOpaque:(BOOL)isShowBg;
@end

@protocol idsWinADViewDelegate <NSObject>
@optional
- (void)idsWindADViewDidClosed; //如果橱窗广告只使用一次，可以调用此委托，在委托内调用[idsAD dismissWinAd];即可彻底销毁橱窗广告释放内存
@end
