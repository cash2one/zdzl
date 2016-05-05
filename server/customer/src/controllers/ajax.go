package controllers

import (
	"../models"
	"encoding/json"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	//    "crypto/md5"
	//    "encoding/hex"
	//    "io"
	"../helper"
	"strconv"
)

type Result struct {
	Ret    int
	Reason string
	Data   interface{}
}

//type Users struct{
//	models.Users
//}

type ajaxController struct {
}

//注册数据处理
func (this *ajaxController) RegAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	log.Println("RegAction")
	err := r.ParseForm()
	if err != nil {
		OutputJson(w, 0, "参数错误", nil)
		return
	}

	admin_name := r.FormValue("admin_name")
	admin_password := r.FormValue("admin_password")

	if admin_name == "" || admin_password == "" {
		OutputJson(w, 0, "用户名或密码不能为空", nil)
		return
	}
	log.Println(admin_name, admin_password)
	var mongoDrive models.MongoDrive
	mongoDrive.Database("customer", "users")
	id := mongoDrive.GetId()
	//    h := md5.New()
	//    io.WriteString(h, admin_password)
	//    tmpPassword := hex.EncodeToString(h.Sum(nil))
	var help helper.Helper
	tmpPassword := help.GetMd5(admin_password)
	users := models.Users{Id: id, Email: admin_name, Password: tmpPassword}
	isFind := mongoDrive.UserOne(admin_name, "")
	if isFind {
		OutputJson(w, 0, "当前用户名已经存在请重新注册", nil)
		return
	}
	isSave := mongoDrive.InsertUser(users)
	if isSave {
		OutputJson(w, 1, "操作成功", nil)
	} else {
		OutputJson(w, 0, "操作失败", nil)
	}
	return
}

//登录数据处理
func (this *ajaxController) LoginAction(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	err := r.ParseForm()
	if err != nil {
		OutputJson(w, 0, "参数错误", nil)
		return
	}

	admin_name := r.FormValue("admin_name")
	admin_password := r.FormValue("admin_password")

	if admin_name == "" || admin_password == "" {
		OutputJson(w, 0, "用户名或密码不能为空", nil)
		return
	}

	url := models.GetMongoUrl()
	session, err := mgo.Dial(url)
	if err != nil {
		log.Print(err)
	}
	defer session.Close()
	session.SetMode(mgo.Monotonic, true)
	c := session.DB("customer").C("users")
	var users models.Users
	var help helper.Helper
	tmpPassword := help.GetMd5(admin_password)
	c.Find(bson.M{"email": admin_name, "password": tmpPassword}).One(&users)
	if users.T != 1 {
		OutputJson(w, 0, "登录失败", nil)
		return
	}
	if users.Email != "" && users.Password != "" {
		// 存入cookie,使用cookie存储
		cookieName := http.Cookie{Name: "efun_admin_name", Value: admin_name, Path: "/"}
		http.SetCookie(w, &cookieName)
		cookieId := http.Cookie{Name: "efun_admin_id", Value: strconv.Itoa(users.Id), Path: "/"}
		http.SetCookie(w, &cookieId)
	} else {
		OutputJson(w, 0, "登录失败", nil)
		return
	}
	OutputJson(w, 1, "操作成功", nil)
	return
}

func OutputJson(w http.ResponseWriter, ret int, reason string, i interface{}) {
	out := &Result{ret, reason, i}
	b, err := json.Marshal(out)
	if err != nil {
		return
	}
	w.Write(b)
}
