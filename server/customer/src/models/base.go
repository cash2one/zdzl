package models

import (
	//	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"

//    "reflect"
)

const (
	MONGO_HOST_LOCAL     = "127.0.0.1"
	MONGO_PORT_LOCAL     = "27017"
	MONGO_NAME_LOCAL     = "kain"
	MONGO_PASSWORD_LOCAL = "123456"

	MONGO_HOST_91     = "172.16.40.2"
	MONGO_PORT_91     = "27017"
	MONGO_NAME_91     = "td"
	MONGO_PASSWORD_91 = "123456"

	MONGO_HOST_SERVER     = "db_1"
	MONGO_PORT_SERVER     = "27017"
	MONGO_NAME_SERVER     = "pointing_king"
	MONGO_PASSWORD_SERVER = "5f987c8a88060906abc522eaeb100c74"

	MONGO_HOST_SERVER_TEST     = "192.168.159.84"
	MONGO_PORT_SERVER_TEST     = "27017"
	MONGO_NAME_SERVER_TEST     = "pointing_king"
	MONGO_PASSWORD_SERVER_TEST = "5f987c8a88060906abc522eaeb100c74"

	MONGO_DATABASE = "customer"
	C_REPORTS      = "reports"
	C_USER         = "users"
	C_CONTENT      = "content"
	C_AUTO_INC     = "_auto_inc_"
)

type Ban struct {
	Id      int    `bson:"_id"`
	Banword string `bson:"banword"`
}

var (
	ban   []Ban
	bTrie = NewTrie()
)

type Users struct {
	Id       int    `bson:"_id"`
	Email    string `bson:"email"`
	Password string `bson:"password"`
	T        int    `bson:"t"`
}

type AutoResult struct {
	Name string
	Id   int
}

func GetMongoUrl() (url string) {
	host := "91"
	switch host {
	case "local":
		url = "mongodb://" + MONGO_NAME_LOCAL + ":" + MONGO_PASSWORD_LOCAL +
			"@" + MONGO_HOST_LOCAL + ":" + MONGO_PORT_LOCAL
	case "91":
		url = "mongodb://" + MONGO_NAME_91 + ":" + MONGO_PASSWORD_91 +
			"@" + MONGO_HOST_91 + ":" + MONGO_PORT_91
	case "server":
		url = "mongodb://" + MONGO_NAME_SERVER + ":" + MONGO_PASSWORD_SERVER +
			"@" + MONGO_HOST_SERVER + ":" + MONGO_PORT_SERVER
	case "server_test":
		url = "mongodb://" + MONGO_NAME_SERVER_TEST + ":" + MONGO_PASSWORD_SERVER_TEST +
			"@" + MONGO_HOST_SERVER_TEST + ":" + MONGO_PORT_SERVER_TEST
	}
	return
}

type MongoDrive struct {
	database   string
	collection string
}

func (this *MongoDrive) Database(db string, c string) {
	this.database = db
	this.collection = c
}

func (this *MongoDrive) GetId() (id int) {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	if err != nil {
		log.Println("+++++++++++++++", err)
	}
	session.SetMode(mgo.Monotonic, true)
	defer session.Close()

	autoSession := session.DB(this.database).C(C_AUTO_INC)
	var autoResult AutoResult
	autoSession.Find(bson.M{"name": this.collection}).One(&autoResult)
	if autoResult.Name == "" {
		autoSession.Insert(&AutoResult{Name: this.collection, Id: 0})
	}
	change := mgo.Change{
		Update:    bson.M{"$inc": bson.M{"id": 1}},
		ReturnNew: true,
	}
	autoSession.Find(bson.M{"name": this.collection}).Apply(change, &autoResult)
	id = autoResult.Id
	return
}

func init() {
	InitBanWord()
}

func InitBanWord() {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	if err != nil {
		log.Println("++++++InitBanWord+++err++++", err)
	}
	session.SetMode(mgo.Monotonic, true)
	defer session.Close()
	banSession := session.DB("td_res").C("ban_word")

	banSession.Find(nil).All(&ban)
	for _, item := range ban {
		bTrie.Insert(item.Banword)
		// log.Println(item.Banword)
	}
	// log.Println("Replaces", bTrie.Replaces("如果这是尖閣列島中文", "*"))

	// log.Println("bTrie.root", bTrie.root)

}
