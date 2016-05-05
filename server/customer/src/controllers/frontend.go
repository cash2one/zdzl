package controllers

import (
	"html/template"
	"log"
	"net/http"
	//    "encoding/json"
	"../helper"
	"../models"
	"time"
)

//Frontend路由
type FrontendController struct{}

//首页
func (this *FrontendController) FrontendIndexAction(w http.ResponseWriter, r *http.Request) {
}

//登录
func (this *FrontendController) FrontendLoginAction(w http.ResponseWriter, r *http.Request) {
	log.Println("FrontendController/FrontendLoginAction")
	t, err := template.ParseFiles("template/html/frontend/login.html")
	log.Println(time.Now())
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, nil)
}

//注册
func (this *FrontendController) FrontendRegAction(w http.ResponseWriter, r *http.Request) {
	log.Println("FrontendController/FrontendRegAction")
	t, err := template.ParseFiles("template/html/frontend/reg.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, nil)
}

//前端查询状态
func (this *FrontendController) FrontendStatusAction(w http.ResponseWriter, r *http.Request) {
	log.Println("FrontendController/FrontendStatusAction")
	w.Header().Set("content-type", "application/json")
	err := r.ParseForm()
	if err != nil {
		OutputJson(w, 0, "参数错误", nil)
		return
	}

	snsType := r.FormValue("snsType")
	snsUserId := r.FormValue("snsUserId")
	uid := r.FormValue("uid")
	playerId := r.FormValue("playerId")
	println(snsType, snsUserId, uid, playerId)
	if snsType == "" || snsUserId == "" || uid == "" || playerId == "" {
		OutputJson(w, 0, "请传入正确参数", nil)
		return
	}
	var mongo models.MongoDrive
	mongo.Database("customer", "reports")
	var help helper.Helper
	reportsList, err := mongo.ReportsFind(help.Strconv(snsType), help.Strconv(snsUserId),
		help.Strconv(uid), help.Strconv(playerId))
	log.Println("reportsList:", reportsList)
	if err != nil {
		OutputJson(w, 0, "查找失败", nil)
		return
	}
	OutputJson(w, 1, "查找成功", reportsList)
	return
}

//前端获取reports
func (this *FrontendController) FrontendReportsAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	err := r.ParseForm()
	if err != nil {
		OutputJson(w, 0, "参数错误", nil)
		return
	}
	snsType := r.FormValue("snsType")
	snsUserId := r.FormValue("snsUserId")
	uid := r.FormValue("uid")
	playerId := r.FormValue("playerId")
	if snsType == "" || snsUserId == "" || uid == "" || playerId == "" {
		OutputJson(w, 0, "请传入正确参数", nil)
		return
	}
	var mongo models.MongoDrive
	mongo.Database("customer", "reports")
	var help helper.Helper
	reportsAllList, err := mongo.ReportsAll(help.Strconv(snsType), help.Strconv(snsUserId),
		help.Strconv(uid), help.Strconv(playerId))
	log.Println("reportsAllList:", reportsAllList)
	if err != nil {
		OutputJson(w, 0, "查找失败", nil)
		return
	}
	OutputJson(w, 1, "查找成功", reportsAllList)
	return
}

//更改状态为已阅
func (this *FrontendController) FrontendReadAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	var help helper.Helper
	err := r.ParseForm()
	if err != nil {
		log.Println("dont have data~~~~~~~~~~")
		OutputJson(w, 0, "参数错误", nil)
		return
	}
	id := r.FormValue("id")
	tmpstatus := r.FormValue("status")
	if id == "" {
		OutputJson(w, 0, "请传入正确参数222", nil)
		return
	}
	var status int
	if tmpstatus == "" {
		status = 4
	} else {
		status = help.Strconv(tmpstatus)
	}
	var mongo models.MongoDrive
	mongo.Database("customer", "reports")

	isOkay := mongo.ReportsById(help.Strconv(id), status)
	if isOkay == false {
		OutputJson(w, 0, "更改状态失败", nil)
		return
	}
	OutputJson(w, 1, "更改状态成功", nil)
	return
}

//从前端接收用户回复
func (this *FrontendController) FrontendResponseAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	err := r.ParseForm()
	if err != nil {
		log.Println("dont have data~~~~~~~~~~")
		OutputJson(w, 0, "参数错误", nil)
		return
	}
	rid := r.FormValue("id")
	m := r.FormValue("m")

	// m = models.bTrie.Replaces(m, "*")

	if rid == "" {
		OutputJson(w, 0, "请传入正确参数", nil)
		return
	}

	var mongo models.MongoDrive
	mongo.Database("customer", "content")
	contentId := mongo.GetId()
	var help helper.Helper
	responseMongo := models.Content{Id: contentId, Rid: help.Strconv(rid), T: 1,
		M: m, Ct: time.Now().Unix()}
	isOkay := mongo.InsertContent(responseMongo)
	if isOkay == false {
		OutputJson(w, 0, "保存失败", nil)
		return
	}
	log.Println("保存回复成功")
	OutputJson(w, 1, "保存成功", nil)
	return
}

//客服回复用户回复
func (this *FrontendController) FrontendCresponseAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	err := r.ParseForm()
	if err != nil {
		log.Println("dont have data~~~~~~~~~~")
		OutputJson(w, 0, "参数错误", nil)
		return
	}
	rid := r.FormValue("id")
	m := r.FormValue("m")
	t := r.FormValue("t")
	if rid == "" {
		OutputJson(w, 0, "请传入正确参数", nil)
		return
	}

	cookie, err := r.Cookie("efun_admin_id")

	if err != nil || cookie.Value == "" {
		log.Println("～～～～～～～～～～～～～～～～～～～～")
		http.Redirect(w, r, "/login", http.StatusFound)
		return
	}
	var mongo models.MongoDrive
	mongo.Database("customer", "content")
	contentId := mongo.GetId()
	var help helper.Helper
	responseMongo := models.Content{Id: contentId, Rid: help.Strconv(rid), T: help.Strconv(t),
		M: m, Cid: help.Strconv(cookie.Value), Ct: time.Now().Unix()}
	isOkay := mongo.InsertContent(responseMongo)
	if isOkay == false {
		OutputJson(w, 0, "保存失败", nil)
		return
	}
	log.Println("保存回复成功")
	OutputJson(w, 1, "保存成功", nil)
	return
}

//从前端接收信息并保存
func (this *FrontendController) FrontendQuestionAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	err := r.ParseForm()
	if err != nil {
		OutputJson(w, 0, "参数错误", nil)
		return
	}
	log.Println("this is questionController")
	serverId := r.FormValue("serverId")     //(服务器id)
	serverName := r.FormValue("serverName") //(服务器名)
	snsType := r.FormValue("snsType")       //(1:91平台)
	snsUserId := r.FormValue("snsUserId")   //(平台用户id)
	uid := r.FormValue("uid")               //(游戏用户id)
	playerId := r.FormValue("playerId")     //(玩家id)
	playerName := r.FormValue("playerName") //(玩家名)

	clientVersion := r.FormValue("clientVersion") //(游戏客户端版本)
	dbVersion := r.FormValue("dbVersion")         //(游戏数据库版本)

	t := r.FormValue("type")        //(问题类型)
	report := r.FormValue("report") //(问题内容)

	if serverId == "" || serverName == "" || snsType == "" || snsUserId == "" ||
		uid == "" || playerId == "" || playerName == "" || clientVersion == "" ||
		dbVersion == "" || t == "" || report == "" {
		OutputJson(w, 0, "请传入正确参数", nil)
		return
	}
	log.Println(serverId, serverName, snsType, snsUserId, uid, playerId,
		playerName, clientVersion, dbVersion, t, report)
	var mongo models.MongoDrive
	mongo.Database("customer", "reports")
	reportId := mongo.GetId()
	var help helper.Helper
	reportMongo := models.Reports{Id: reportId, ServerId: help.Strconv(serverId), ServerName: serverName,
		SnsType: help.Strconv(snsType), SnsUserId: help.Strconv(snsUserId), Uid: help.Strconv(uid),
		PlayerId: help.Strconv(playerId), PlayerName: playerName, ClientVersion: help.Strconv(clientVersion),
		DbVersion: help.Strconv(dbVersion), T: help.Strconv(t), Report: report, Status: 1,
		Ct: time.Now().Unix()}
	isOkay := mongo.InsertReport(reportMongo)
	if isOkay == false {
		log.Println("保存Reports失败")
		OutputJson(w, 0, "保存失败", nil)
		return
	}
	log.Println("保存Reports成功")
	OutputJson(w, 1, "保存成功", nil)
	return
}
