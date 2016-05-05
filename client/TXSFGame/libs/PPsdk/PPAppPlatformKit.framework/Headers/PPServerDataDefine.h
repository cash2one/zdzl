//
//  ServerDataDefine.h
//  PPAppPlatformKit
//
//  Created by 张熙文 on 1/11/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

typedef struct MsgGameServerResponse
{
    uint32_t len;
    uint32_t command;
    uint32_t status;                    //0为成功，其他为失败
}MSG_GAME_SERVER_RESPONSE;


typedef struct MsgPSVerifi2Response{
    uint32_t		len;
    uint32_t		command;           
    uint32_t        status;             //	[0为成功；其他为失败。注意：成功后才包含后续字段。]
    char        token_key[16];
}MSG_PS_VERIFI2_RESPONSE;

typedef struct MsgGameServer{
    uint32_t		len;
    uint32_t		commmand;         
    char            token_key[16];
}MSG_GAME_SERVER;

