package main

import (
	"./rpc"
	"log"
	"os"
)

func main() {
	log.Printf("start")
	UNIXAddr := os.Args[3]
	os.Remove(UNIXAddr)
	rpcMgr := rpc.NewRpcMgr()
	rpcMgr.Start(UNIXAddr)
}
