package helper

import (
	"crypto/md5"
	"encoding/hex"
	"io"
	"strconv"
	"time"
)

type Helper struct {
}

//加密为md5
func (this *Helper) GetMd5(val string) (result string) {
	h := md5.New()
	io.WriteString(h, val)
	result = hex.EncodeToString(h.Sum(nil))
	return
}

func (this *Helper) Strconv(str string) (result int) {
	result, _ = strconv.Atoi(str)
	return
}

func (this *Helper) In(val string, s []string) bool {
	for _, item := range s {
		if val == item {
			return true
		}
	}
	return false
}

/**管道**/
//时间转换
func DateTimeExpander(args ...interface{}) string {
	var s int64
	if len(args) == 1 {
		s, _ = args[0].(int64)
	}
	return time.Unix(s, 0).String()
}

//显示问题类型
func ShowQType(arg interface{}) string {
	val := arg.(int)
	var s string
	switch val {
	case 1:
		s = "未回复"
	case 2:
		s = "已回复"
	case 3:
		s = "关闭"
	case 4:
		s = "已阅"
	}
	return s
}

//回复类型
func ShowContentType(t int) bool {
	var s bool
	switch t {
	case 1:
		s = true
	case 2:
		s = false
	}
	return s
}
