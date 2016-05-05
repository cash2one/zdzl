package rpc

import (
	grpc "bitbucket.org/seewind/grpc/golang"
)

type AppExport struct {
}

func (app *AppExport) Init(parent *grpc.Proxyer, config interface{}) (rs interface{}, err error) {
	log.Printf("parent(%s), config(%s)", parent, config)
	return
}
