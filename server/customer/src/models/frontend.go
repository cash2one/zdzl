package models

import (
	"errors"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
)

type Reports struct {
	Id            int    `bson:"_id"`
	ServerId      int    `bson:"serverId"`
	ServerName    string `bson:"serverName"`
	SnsType       int    `bson:"snsType"`
	SnsUserId     int    `bson:"snsUserId"`
	Uid           int    `bson:"uid"`
	PlayerId      int    `bson:"playerId"`
	PlayerName    string `bson:"playerName"`
	ClientVersion int    `bson:"clientVersion"`
	DbVersion     int    `bson:"dbVersion"`
	T             int    `bson:"type"`
	Report        string `bson:"report"`
	Status        int    `bson:"status"`
	Ct            int64  `bson:"ct"`
}

type Content struct {
	Id  int    `bson:"_id"`
	Rid int    `bson:"rid"`
	T   int    `bson:"t"`
	M   string `bson:"m"`
	Cid int    `bson:"cid"`
	Ct  int64  `bson:"ct"`
}

func (this *MongoDrive) InsertUser(users Users) bool {
	//	iType := reflect.TypeOf(i)
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		return false
	}
	collectionSession := session.DB(this.database).C(this.collection)
	collectionSession.Insert(&users)
	return true
}

func (this *MongoDrive) InsertReport(report Reports) bool {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		return false
	}
	collectionSession := session.DB(this.database).C(this.collection)
	err = collectionSession.Insert(&report)
	if err != nil {
		return false
	}
	return true
}

func (this *MongoDrive) InsertContent(content Content) bool {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		return false
	}
	collectionSession := session.DB(this.database).C(this.collection)
	// collectionSession.Insert(&content)
	collectionSession.Insert(&Content{Id: content.Id, Rid: content.Rid, T: content.T,
		M: bTrie.Replaces(content.M, "*"), Cid: content.Cid, Ct: content.Ct})
	return true
}

func (this *MongoDrive) UserOne(email string, password string) bool {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		panic(err)
	}
	user := Users{}
	c := session.DB(MONGO_DATABASE).C(C_USER)
	if password == "" {
		err = c.Find(bson.M{"email": email}).One(&user)
	} else {
		err = c.Find(bson.M{"email": email, "password": password}).One(&user)
	}
	//	err = c.Find(querys).One(&user)
	if user.Email != "" {
		return true
	}
	return false
}

//状态列
type StatusList struct {
	Id     int `bson:"_id"`
	Status int `bson:"status"`
}

func (this *MongoDrive) ReportsFind(snsType int, snsUserId int, uid int,
	playerId int) (result []StatusList, err error) {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		panic(err)
	}
	c := session.DB(MONGO_DATABASE).C(C_REPORTS)
	err = c.Find(bson.M{"snsType": snsType, "snsUserId": snsUserId, "uid": uid,
		"playerId": playerId}).All(&result)
	if err != nil {
		return nil, errors.New("查找失败")
	}
	return result, nil
}

func (this *MongoDrive) ReportsById(id int, status int) bool {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		panic(err)
	}
	c := session.DB(MONGO_DATABASE).C(C_REPORTS)
	err = c.Update(bson.M{"_id": id}, bson.M{"$set": bson.M{"status": status}})
	if err != nil {
		return false
	}
	return true
}

type ReportsAllList struct {
	Id       int `bson:"_id"`
	Status   int `bson:"status"`
	Contents []ReportsContent
}

type ReportsQuestion struct {
	Id     int    `bson:"_id"`
	Status int    `bson:"status"`
	Report string `bson:"report"`
}

type ReportsContent struct {
	T int    `bson:"t"`
	M string `bson:"m"`
}

func (this *MongoDrive) ReportsAll(snsType int, snsUserId int, uid int,
	playerId int) (result []ReportsAllList, err error) {
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		log.Println("")
	}
	c := session.DB(MONGO_DATABASE).C(C_REPORTS)
	var question []ReportsQuestion
	err = c.Find(bson.M{"snsType": snsType, "snsUserId": snsUserId, "uid": uid,
		"playerId": playerId}).All(&question)
	if err != nil {
		return nil, errors.New("查找失败")
	}

	for _, item := range question {
		c := session.DB(MONGO_DATABASE).C(C_CONTENT)
		var reportsContent, tmpContent []ReportsContent
		reportsContent = append(reportsContent, ReportsContent{T: 1, M: item.Report})
		err = c.Find(bson.M{"rid": item.Id}).All(&tmpContent)
		if err != nil {
			return nil, errors.New("查找失败")
		}
		for _, con := range tmpContent {
			reportsContent = append(reportsContent, ReportsContent{T: con.T, M: con.M})
		}
		result = append(result, ReportsAllList{Id: item.Id, Status: item.Status, Contents: reportsContent})
	}
	log.Println("last result:::", result)
	return result, nil
}
