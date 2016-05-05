package models

import (
	"errors"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"strconv"
)

type ReportsAll struct {
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
	Contents      []Content
}

func (this *MongoDrive) UserReportsFilter(query bson.M, page int) (result []ReportsAll, count int, err error) {
	defaultLimit := 100
	var contentResult []Content
	var reportResult []Reports
	url := GetMongoUrl()
	session, err := mgo.Dial(url)
	defer session.Close()
	if err != nil {
		log.Println(err)
	}
	c := session.DB(MONGO_DATABASE).C(C_REPORTS)
	skipNum := page*defaultLimit - defaultLimit
	err = c.Find(query).Sort("-_id").Limit(defaultLimit).Skip(skipNum).All(&reportResult)
	count, err = c.Find(query).Count()
	if err != nil {
		return result, 0, errors.New("查找失败")
	}
	var idList []int
	err = c.Find(query).Distinct("_id", &idList)
	contentQuery := bson.M{"rid": bson.M{"$in": idList}}
	contentSession := session.DB(MONGO_DATABASE).C(C_CONTENT)
	err = contentSession.Find(contentQuery).Sort("-_id").All(&contentResult)
	mapContent := map[string][]Content{}
	for _, con := range contentResult {
		mapContent[strconv.Itoa(con.Rid)] = append(mapContent[strconv.Itoa(con.Rid)], con)
	}
	for _, rep := range reportResult {
		result = append(result, ReportsAll{Id: rep.Id, ServerId: rep.ServerId,
			ServerName: rep.ServerName, SnsType: rep.SnsType, SnsUserId: rep.SnsUserId,
			Uid: rep.Uid, PlayerId: rep.PlayerId, PlayerName: rep.PlayerName,
			ClientVersion: rep.ClientVersion, DbVersion: rep.DbVersion,
			T: rep.T, Report: rep.Report, Status: rep.Status, Ct: rep.Ct,
			Contents: mapContent[strconv.Itoa(rep.Id)]})
	}
	return result, count, nil
}
