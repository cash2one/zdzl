package rpc

import (
	//  "fmt"
	"./rpc"
	grpc "bitbucket.org/seewind/grpc/golang"
	"log"
	"os"
	// "reflect"
)

var (
	rpcMgr *RpcMgr
)

type RpcMgr struct {
}

func NewRpcMgr() *RpcMgr {
	rpcMgr = &RpcMgr{}
	return rpcMgr
}

func (this *RpcMgr) Start(addr string) {
	svr := grpc.NewRpcServer()
	err := svr.Bind(addr)
	if err != nil {
		log.Println("bind error:%s", err.Error())
	}
	defer svr.Stop()

	app := &rpc.AppExport{}
	svr.Register("app", app)

	banword := &rpc.BanWordExport{}
	svr.Register("rpc_bandword_mgr", banword)

	svr.Start(true)
}
