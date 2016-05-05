package main

import (
	"./controllers"
	// _ "./models"
	"log"
	"net/http"
)

const (
	IP = "0.0.0.0:3000"
)

func main() {
	http.Handle("/css/", http.FileServer(http.Dir("static")))
	http.Handle("/js/", http.FileServer(http.Dir("static")))
	http.Handle("/bootstrap/", http.FileServer(http.Dir("static")))

	http.HandleFunc("/", controllers.NotFoundHandler)
	http.HandleFunc("/login/", controllers.FrontendHandler)
	// http.HandleFunc("/reg/", controllers.FrontendHandler)
	// 前端查询回复状态，返回状态为已回复列表
	http.HandleFunc("/status/", controllers.FrontendHandler)
	// 更发状态为已阅
	http.HandleFunc("/read/", controllers.FrontendHandler)
	// 前端获取数据
	http.HandleFunc("/reports/", controllers.FrontendHandler)
	// 玩家回复
	http.HandleFunc("/response/", controllers.FrontendHandler)
	// 客服回复
	http.HandleFunc("/cresponse/", controllers.FrontendHandler)
	// 玩家发送用户提问至服务器并进行保存
	http.HandleFunc("/question/", controllers.FrontendHandler)
	http.HandleFunc("/ajax/", controllers.AjaxHandler)

	http.HandleFunc("/user/", controllers.UserHandler)
	// http.HandleFunc("/user/search/", controllers.UserHandler)
	log.Println(IP)
	http.ListenAndServe(IP, nil)
}
