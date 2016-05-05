package helper

import (
	"log"
)

const (
	MONGO_HOST 			=	"127.0.0.1"
	MONGO_PORT 			=	 27017
	MONGO_NAME 			=	 "kain"
	MONGO_PASSWORD 		=	 "123456"
	
	MONGO_DATABASE		=	"customer"
	C_REPORTS 			=	"reports"
	C_USER				=	"users"
	C_CONTENT			=	"content"
	C_AUTO_INC			=	"_auto_inc_"
)

func GetMongoUrl()(url string){
	MONGO_URL := "mongodb://"
	if MONGO_NAME != ""{
		MONGO_URL += MONGO_NAME + ":" + MONGO_PASSWORD + "@" + MONGO_HOST
	}else{
		MONGO_URL += MONGO_HOST
	}
	log.Println("MONGO_URL::::", MONGO_URL)
	return MONGO_URL
}