package rpc

import (
	"fmt"
	"labix.org/v2/mgo"
	"log"
)

const (
	AUTO_INC      = "_auto_inc_" // 自增
	MongoHost     = "172.16.40.2"
	MongoPort     = "27017"
	MongoName     = "td"
	MongoPassword = "123456"
)

var (
	Mongo    *MongoDrive
	DB       *mgo.Database
	BanWordC *mgo.Collection
	AutoC    *mgo.Collection
	BTrie    = NewTrie()
)

// 包初始化
func init() {
	Mongo = &MongoDrive{}
	Mongo.Connection()

	DB := Mongo.MongoSession.DB("td_res")
	BanWordC = DB.C("ban_word")
	AutoC = DB.C(AUTO_INC)

	InitBanWord()
}

// 自增表
type AutoResult struct {
	Name string
	Id   int
}

// mongo url
func mongoUrl() string {
	return string(fmt.Sprintf("mongodb://%s:%s@%s:%s", MongoName, MongoPassword, MongoHost, MongoPort))
}

// 连接数据库
type MongoDrive struct {
	MongoSession *mgo.Session
}

func (this *MongoDrive) Connection() {
	url := mongoUrl()
	session, err := mgo.Dial(url)
	if err != nil {
		log.Println(err)
	}
	session.SetMode(mgo.Monotonic, true)
	this.MongoSession = session
	// defer session.Close()
}

type Ban struct {
	Id      int    `bson:"_id"`
	Banword string `bson:"banword"`
}

func InitBanWord() {
	ban := []Ban{}
	BanWordC.Find(nil).All(&ban)
	for _, item := range ban {
		BTrie.Insert(item.Banword)
	}

}
