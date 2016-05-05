//
//  DPayPlatformError.h
//  DPay
//
//  Created by loary qing on 2/10/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#define  DPAY_ERROR_CANCEL_PURCHASE                 -7                  //用户取消购买商品
#define  DPAY_ERROR_PACKAGE_INVALID					-6					//数据包不全、丢失或无效
#define  DPAY_ERROR_PACKAGE_DECRYPT_FAILED			-5					//数据包体解密失败 
#define  DPAY_ERROR_JSON_ANALYSIS_FAILED			-4					//json数据解析失败
#define  DPAY_ERROR_NO_SET_APP_ID_OR_KEY			-3					//没有设置appid或appkey
#define  DPAY_ERROR_NETWORK_FAIL					-2					//网络异常
#define  DPAY_ERROR_UNKNOWN							-1					//未知错误
#define  DPAY_NO_ERROR								0					// 成功没有错误

#define  DPAY_ERROR_REQUEST_DATA_LENGTH_IS_TOO_LONG   6                 //发送的请求数据太长
#define  DPAY_ERROR_INTERFCE_HAS_DEACTIVATED       10                   //接口已停用，需要升级SDK
#define  DPAY_ERROR_SERVER_MAINTENANCE             901                  //服务器维护中
#define  DPAY_ERROR_USER_DIDNOT_LOGIN              903                  //用户未登录或已过期，请重新登录
#define  DPAY_ERROR_SERVER_ERROR_OR_UNKNOW         905                  //服务器错误/位置错误
#define  DPAY_ERROR_PRAGMA_ERROR                   906                  //参数错误
#define  DPAY_ERROR_SERVER_INVALIDE                907                  //非法访问
#define  DPAY_ERROR_APPLICATION_INVALIDE           908                  //应用不可用

#define  DPAY_ERROR_GOODS_NOT_EXISTS               912                  //商品不存在
#define  DPAY_ERROR_NO_DETAIL_INFORMATION          4001                 //无详细资料
#define  DPAY_ERROR_RECHARGE_NUMBER_NOT_EXISTS     7001                 //交易号不存在
#define  DPAY_ERROR_GOODS_LITTLE_NUMBER            11002                //商品个数不够  
#define  DPAY_ERROR_MOENY_NOT_ENOUGH               12001                //余额不足（购买商品）
#define  DPAY_ERROR_MOENY_NOT_ENOUGH_CUSTOM_GOODS  29001                //余额不足（购买自定义商品）
#define  DPAY_ERROR_ORDER_FAILD                    12007                //下单失败
#define  DPAY_ERROR_GOODS_LIST_IS_LLLEGAL          12008                //商品中已经有购买过的“非消耗型”商品
#define  DPAY_ERROR_FEED_BACK_MESSAGE_ERROR        15001                //内容非法（反馈内容过长或过短）
#define  DPAY_ERROR_ORDERSS_NOT_EXISTS             22002                //订单不存在

#define  DPAY_ERROR_APP_NOT_ACCEPT                  1002                //App未接入(app_id 或者 app_key 无效)
#define  DPAY_ERROR_USER_ALREADY_LOGIN              2004                //用户登录状态请先注销
#define  DPAY_ERROR_ACCOUNT_FORBIDDEN               3003                //账户已经禁用
#define  DPAY_ERROR_USER_NOT_EXIST                  913                 //用户不存在
#define  DPAY_ERROR_PASSWORD_ERROR                  910                 //密码错误
#define  DPAY_ERROR_RECHARGE_MONEY_DISALBE          6001                //充值金额非法
#define  DPAY_ERROR_RECHARGE_QUIT_HALFWAY           6002                //充值中途退出
#define  DPAY_ERROR_PAYMENT_FAILED                  6003                //付款失败
#define  DPAY_ERROR_NOT_GET_PAYMENT_RESULT          6004                //还未获取支付结果
#define  DPAY_ERROR_RECHARGE_RECORD_EXIST           6005                //该充值记录已经存在
#define  DPAY_ERROR_ILLEGAL_UIN                     6006                //UIN非法
#define  DPAY_ERROR_ILLEGAL_CACCESSS                18001               //非法访问
#define  DPAY_ERROR_ILLEGAL_GACCESSS                8001                //非法访问
#define  DPAY_ERROR_ILLEGAL_GGACCESSS               9001                //非法访问
#define  DPAY_ERROR_ILLEGAL_QCACCESSS               11001               //非法访问
#define  DPAY_ERROR_GOODS_NOT_ENOUGH                1102                //商品个数不够
#define  DPAY_ERROR_USER_HAS_NOT_LOGIN              12003               //用户未登录
#define  DPAY_ERROR_PARAM_IS_ERROR                  12004               //参数错误
#define  DPAY_ERROR_GOODS_NOT_THE_APPLICATION       12005               //商品不属于该应用
#define  DPAY_ERROR_ORDER_FAILED_OR_DB_ERROR        12006               //下单失败或者数据库错误
#define  DPAY_ERROR_ILLEGAL_QGACCESSS               13001               //非法访问
#define  DPAY_ERROR_NO_PUSH_MESSAGE                 14001               //无消息
#define  DPAY_ERROR_ERROR_VISIT                     22001               //非法访问
#define  DPAY_ERROR_PPARAM_ERROR                    22003               //参数出错
#define  DPAY_ERROR_USER_NOT_LOGIN                  22004               //用户未登录
#define  DPAY_ERROR_SERVER_OR_UNKNOW_ERROR          22005               //服务器出错/未知错误
#define  DPAY_ERROR_APPLICATION_NOT_EXIST           23001               //应用不存在
#define  DPAY_ERROR_REQUEST_TOO_MUCH                190001              //单位时间内获取的次数超过限制
#define  DPAY_ERROR_CHANNEL_ERROR                   1003                //渠道非法
