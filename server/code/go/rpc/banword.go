package rpc

import (
	// grpc "bitbucket.org/seewind/grpc/golang"
	// "labix.org/v2/mgo/bson"
	. "../data"
)

type BanWordExport struct {
}

func (bw *BanWordExport) Replaces(msg string) (ret string, err error) {
	// log.Println("Replaces", BTrie.Replaces("如果这是尖閣列島中文", "*"))
	ret = BTrie.Replaces(msg, "*")
	return ret, nil
}
