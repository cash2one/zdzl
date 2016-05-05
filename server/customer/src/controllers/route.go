package controllers

import (
	"html/template"
	"log"
	"net/http"
	"reflect"
	"strings"
)

func FrontendHandler(w http.ResponseWriter, r *http.Request) {
	pathInfo := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(pathInfo, "/")
	action := "Frontend" + strings.Title(parts[0]) + "Action"
	frontend := &FrontendController{}
	controller := reflect.ValueOf(frontend)
	method := controller.MethodByName(action)
	if !method.IsValid() {
		method = controller.MethodByName("FrontendIndexAction")
	}
	requestValue := reflect.ValueOf(r)
	responseValue := reflect.ValueOf(w)
	method.Call([]reflect.Value{responseValue, requestValue})
}

func UserHandler(w http.ResponseWriter, r *http.Request) {
	// 获取cookie
	cookie, err := r.Cookie("efun_admin_name")
	if err != nil || cookie.Value == "" {
		http.Redirect(w, r, "/login", http.StatusFound)
		return
	}
	pathInfo := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(pathInfo, "/")
	var action = ""
	if len(parts) > 1 {
		action = "User" + strings.Title(parts[1]) + "Action"
	}
	user := &UserController{}
	controller := reflect.ValueOf(user)
	method := controller.MethodByName(action)
	if !method.IsValid() {
		method = controller.MethodByName("UserIndexAction")
	}
	requestValue := reflect.ValueOf(r)
	responseValue := reflect.ValueOf(w)
	userValue := reflect.ValueOf(cookie.Value)
	method.Call([]reflect.Value{responseValue, requestValue, userValue})
}

func AjaxHandler(w http.ResponseWriter, r *http.Request) {
	pathInfo := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(pathInfo, "/")
	var action = ""
	if len(parts) > 1 {
		action = strings.Title(parts[1]) + "Action"
	}

	ajax := &ajaxController{}
	controller := reflect.ValueOf(ajax)
	method := controller.MethodByName(action)
	if !method.IsValid() {
		method = controller.MethodByName(strings.Title("index") + "Action")
	}
	requestValue := reflect.ValueOf(r)
	responseValue := reflect.ValueOf(w)
	method.Call([]reflect.Value{responseValue, requestValue})
}

func NotFoundHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" {
		http.Redirect(w, r, "/login", http.StatusFound)
	}

	t, err := template.ParseFiles("template/html/404.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, nil)
}
