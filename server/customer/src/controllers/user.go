package controllers

import (
	"../helper"
	"../models"
	"html/template"
	"io/ioutil"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
)

type User struct {
	UserName string
}

type HtmlData struct {
	UserName      string
	Count         int
	Page          int
	ServerName    string
	QuestionT     string
	Status        string
	Question      string
	ReportsAllRet []models.ReportsAll
}

//管理员首页Controller
type UserController struct{}

func (this *UserController) UserIndexAction(w http.ResponseWriter, r *http.Request, user string) {
	log.Println("UserController/UserIndexAction")
	perPageLimit := 100
	b, err := ioutil.ReadFile("template/html/user/index.html")
	if err != nil {
		log.Println(err)
	}
	s := string(b)
	tmpFuncs := template.FuncMap{"DateTimeExpander": helper.DateTimeExpander, "showQType": helper.ShowQType,
		"showContentType": helper.ShowContentType}
	t, _ := template.New("").Funcs(tmpFuncs).Parse(s)
	//    t, _ := template.ParseFiles("template/html/user/index.html")
	//	t, _ := template.New("index").Funcs(template.FuncMap{"DateTimeExpander": DateTimeExpander}).ParseFiles("template/html/admin/index.html")
	var mongo models.MongoDrive
	//    mongo.Database("customer", "reports")
	serverName := r.FormValue("serverName")
	// serverId := r.FormValue("serverId")
	questionT := r.FormValue("questionT")
	status := r.FormValue("status")
	question := r.FormValue("question")
	playerId := r.FormValue("playerId")
	pageValue := r.FormValue("page")
	page := 1
	var help helper.Helper
	m := bson.M{}
	// if serverId != "0" && serverId != "" {
	// 	m["serverId"] = help.Strconv(serverId)
	// }
	if questionT != "0" && questionT != "" {
		m["type"] = help.Strconv(questionT)
	}
	if status != "0" && status != "" {
		m["status"] = help.Strconv(status)
	}
	if serverName != "" {
		m["serverName"] = serverName
	}
	if question != "" {
		m["report"] = bson.M{"$regex": ".*" + question + ".*"}
	}
	if playerId != "" {
		m["playerId"] = help.Strconv(playerId)
	}
	if pageValue != "" {
		page = help.Strconv(pageValue)
	}
	reportsResult, tmpCount, _ := mongo.UserReportsFilter(m, page)
	count := tmpCount / perPageLimit
	if tmpCount%perPageLimit != 0 {
		count += 1
	}
	t.Execute(w, &HtmlData{UserName: user, ReportsAllRet: reportsResult,
		Page: page, Count: count, QuestionT: questionT,
		Status: status, Question: question, ServerName: serverName})
}
