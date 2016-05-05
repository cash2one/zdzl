#!/usr/bin/env python
# -*- coding:utf-8 -*-
import datetime
import json
import urllib

from .common import PersistObject
from corelib import log, old_spawn
from corelib.tools import http_post
from corelib.common import spawn_later

#角色信息类型
RT_BAG = 1 #背包
RT_UPGRADE = 2 #角色升级
RT_TRADE = 3 #交易
RT_DELETE = 4 #角色删除
RT_GM = 5 #game master 命令
RT_SHELL = 6
RT_MAIL = 7 #邮件
RT_MALL = 8 #商城
RT_REPOSITORY = 9 #仓库
RT_EXCHANGE_ROLL = 10 #金币交易
RT_TEST_PAPER = 11 #答题
RT_INSURANCE = 12 #保险
RT_GAMBLE = 13  #星盘竞猜
RT_ENCHANT = 14 #装备附魔
RT_FORTUNECAT = 15 #招财猫
RT_ACTS_RECOVER = 16 #行动力恢复
RT_CANCEL_CD = 17 #取消cd时间
RT_WALLET_DEDUCT = 18 #扣点卷
RT_REVIVAL = 19 #点卷复活
RT_WALLET_RECHARGE = 20 #返还点券
RT_SWEEP_IMMEDIATELY = 21   #立即完成扫荡
RT_GEM_INLAY = 22 #宝石镶嵌
RT_STAR_REINFORCE = 23 #装备星级强化
RT_CHARGE_CHALLENGE = 24 #增加挑战次数
RT_REFRESH_WANTED = 25  #刷新通缉令


class BaseLog(PersistObject):
	def __init__(self):
		PersistObject.__init__(self)
		self.create_time = datetime.datetime.now()

class RoleLog(BaseLog):
	""" 记录角色重要资源信息 """
	chl_name = None
	def __init__(self, role=None, msg_type=None, msg=None):
		if RoleLog.chl_name is None:
			try:
				from . import game
				RoleLog.chl_name = game.Game.instance.channel_name
			except StandardError:
				RoleLog.chl_name = None

		self.log_id = None
		if role:
			#改记录user_name，这样能方便和平台关联
			self.role_name = role.user_name
			#self.role_name = role.uid
			self.name = role.name
		self.msg_type = msg_type
		self.msg = u'[%s]%s' % (RoleLog.chl_name, msg)
		BaseLog.__init__(self)

	@property
	def message(self):
		return u'重要信息:(%s)-角色(%s): %s' % (self.msg_type, self.name, self.msg)

class GameLog(object):
	""" 重要信息记录 """
	def stop(self):
		""" 停止 """
		self._game = None

	def set_game(self, game):
		self._game = game

	def log(self, uid, name, msg_type, msg, *args):
		""" 记录 """
		msg = RoleLog(msg_type=msg_type, msg=msg % args)
		msg.role_name = uid
		msg.name = name
		log.warn(msg.message)
		self._game.store.save(msg)

	def log_role(self, role, msg_type, msg, *args):
		""" 记录角色重要资源信息 """
		msg = RoleLog(role, msg_type=msg_type, msg=msg % args)
		log.warn(msg.message)
		old_spawn(self._game.store.save, msg)

	def log_gm(self, role, gm_cmd):
		""" 记录gm执行的命令 """
		self.log_role(role, RT_GM, gm_cmd)

	def log_shell(self, name, msg):
		""" 记录 rpc shell  """
		if not msg.strip():
			return
		self.log('shell', name, RT_SHELL, msg)

	def _check_interval(self, interval, cur_value, add_value):
		if add_value <= 0:
			return False
		if add_value >= interval:
			return True
		return add_value + cur_value % interval >= interval

	_reel_interval = 1000
	def role_log_reel(self, role, cur_reel, add_reel):
		""" 礼卷数量 """
		if not self._check_interval(self._reel_interval, cur_reel, add_reel):
			return
		self.log_role(role, RT_BAG, u'礼卷数量达到:%d', cur_reel+add_reel)

	_money_interval = 100000
	def role_log_money(self, role, cur_money, add_money):
		""" 游戏币（紫晶）数量可以分阶段记录，每100紫晶为一个档，
		在玩家包裹内的紫晶数到达100、200、300…时系统自动记录。
		若玩家进行消费则从消费后达到的整百数值起重新记录。
		"""
		if not self._check_interval(self._money_interval, cur_money, add_money):
			return
		self.log_role(role, RT_BAG, u'游戏币数量达到:%d', cur_money+add_money)

	_sp_interval = 1000
	def role_log_sp(self, role, cur_sp, add_sp):
		""" SP记录：玩家进行任务和完成副本获得的SP值可以分阶段记录，
		每1000SP为一个档，当玩家的SP值到达1000、2000、3000…时系统进行自动记录。
		若玩家使用SP值，则从使用后的整千数值重新记录。
		"""
		if not self._check_interval(self._sp_interval, cur_sp, add_sp):
			return
		self.log_role(role, RT_UPGRADE, u'SP数量达到:%d', cur_sp+add_sp)

	_level_interval = 5
	def role_log_level(self, role):
		""" 角色升级后调用
		等级：角色等级和属性的记录，可以记录每10级角色的技能学习情况，
		并对几个重要属性进行记录，如：基础属性中的HP、气力值，
		特殊属性中的能量罩值、硬值、break值和元素属性中的各类抗性进行记录。
		"""
		from . import player
		base = player.Player()
		if role.level % self._level_interval != 0:
			return
		base = role.base
		props = base.props
		ele_damage = base.ele_damage
		ele_defence = base.ele_damage
		msg = u"""升级-%d级;
基础属性:力=%d,智=%d,体=%d,神=%d,
hp=%d,气力=%d,罩=%d,硬直=%d,break=%d,
火=%d,腐=%d,爆=%d,乱=%d,
火抗=%d,腐抗=%d,爆抗=%d,乱抗=%d,
		""" % (role.level,
		base.strength.b, base.intellect.b, base.physique.b, base.spirit.b,
		base.hp.b, base.ep, props.cover.b, props.hard, props.break_value.b,
		ele_damage.fire, ele_damage.etch, ele_damage.blast, ele_damage.confusion,
		ele_defence.fire, ele_defence.etch, ele_defence.blast, ele_defence.confusion,
		)
		self.log_role(role, RT_UPGRADE, msg)

	def role_log_bag(self, role, msg):
		"""记录背包重要信息"""
		self.log_role(role, RT_BAG, msg)

##################
#################

LT_CONSUMPTION = 1 #消费日志
LT_EXCHANGE = 2 #拍卖行日志
LT_MALL = 3 #商城日志
LT_DELETE_ITEM = 4 #删除物品日志
LT_SEND_MAIL = 5 #发送邮件日志
LT_BATTLE = 6 #副本日志
LT_MATRIX = 7 #迷失矩阵日志
LT_EQUIP_REIFORCE = 8 #装备强化日志
LT_EQUIP_HOLE = 9 #装备打孔日志
LT_EQUIP_INLAY = 10 #装备镶嵌日志
LT_COMBINE_GEM = 11 #宝石合成日志
LT_EQUIP_DECOMPOSE = 12 #装备分解日志
LT_DESTROY_MONSTER = 13 #灭魔日志
LT_DNA_ENCHANT = 14 #基因改造日志
LT_EQUIP_ENCHANT = 15 #装备附魔日志
LT_COMBINE_AVATAR = 16 #时装合成日志
LT_LOGON = 17 #登录日志

def tw_log(msg_type):
	def log(func):
		def _log(self, *args, **kw):
			if not self.is_log:
				return
			try:
				log = func(self, *args, **kw)
			except:
				return
			if len(log) == 0:
				return
			data = [msg_type, log] #日志类型 #日志数据
			self.log_cache['logs'].append(data)
			if len(self.log_cache['logs']) >= 3:
				logs = json.dumps(self.log_cache)
				self.log_cache['logs'] = []
				spawn_later(1, self.send, logs)
		return _log
	return log

class TwLog(object):
	"""台湾需求日志记录"""
	def __init__(self, game):
		self.game = game
		self.is_log = False
		self.time_fmt = '%Y-%m-%d %H:%M:%S'

		self.log_cache = {}
		self.log_cache['big_area'] = self.game.big_area
		self.log_cache['area'] = self.game.area
		self.log_cache['channel_name'] = self.game.channel_name
		self.log_cache['logs'] = []

	def send(self, data):
		"""发送"""
		host, port, url = '192.168.0.45', 8085, '/log4game/log/push'
		for i in xrange(10):
			rs = http_post(host, port, url, urllib.urlencode({'game_log' : data}))
			if rs is None or 'error' in rs:
				continue
			break
		else:
			pass
##			print u'-------日志传输错误，写入本地文件----------', data
##			f = open('e:/a.txt', 'w')
##			f.write(data)
##			f.close()

	@tw_log(LT_CONSUMPTION)
	def consumption_log(self):
		"""
		消费日志
		分為四個頁籤 1.消費日誌(三種幣值都列出) 2.點券統計 3.遊戲幣統計 4.禮券統計 - 可查詢玩家ID,角色名稱,類型(如強化武器,星盤競猜花費,星盤競猜所得…等全部),可查詢一個時間區間,查詢按鈕
		列出 玩家ID,玩家名稱,消費點,消費名稱(強化武器等),消費(如遊戲幣-100),消費前遊戲幣數,消費後遊戲幣數,消費時間
		"""
		log = {}

		return log

	@tw_log(LT_EXCHANGE)
	def exchange_log(self, exchange_trade):
		"""
		拍卖行日志
		查詢:可選點券或遊戲幣或物品,數量範圍,金額範圍,物品ID,物品類型,買家ID,買家名稱,賣家ID,賣家名稱,查詢按鈕
		買家ID	買家名稱	買家_前_點券	買家_後_點券	買家_前_遊戲幣	買家_後_遊戲幣	賣家ID	賣家名稱	物品ID	物品類型	物品名稱	價格類型	價格	數量	拍賣時間
		"""
		uid = self.game.scene_mgr.name_to_uid(exchange_trade.buyer_name)
		player = self.game.scene_mgr.get_player(uid)
		if player is None:
			from .bag import Bag
			money = self.game.store.values(Bag, 'money', id=uid)
		else:
			money = player.bag.money

		bag_item = self.game.item_mgr.loads(exchange_trade.item_data)
		log = [
		  uid, #买家uid
			exchange_trade.buyer_name, #买家名称
			#买家_前_点券
			#买家_后_点券
			money, #买家_前_游戏币
			#买家_后_游戏币
			self.game.scene_mgr.name_to_uid(exchange_trade.seller_name), #卖家uid
			exchange_trade.seller_name, #卖家名称
			bag_item.item.id, #物品id
			#物品类型
			exchange_trade.item_name, #物品名称
			#价格类型
			exchange_trade.bid_price, #价格
			exchange_trade.item_count, #数量
			exchange_trade.trade_time.strftime(self.time_fmt), #时间
		]
		return log

	@tw_log(LT_MALL)
	def mall_log(self, mall_history, category):
		"""
		商城日志
		查詢:可輸入 數量範圍:大於???小於??? 金額範圍:大於??小於??,玩家ID,角色名,物品類型ID,查詢按鈕
		角色ID	商店子類型	角色名稱	物品類型ID	物品名稱	價格類型	消費價格	購買數量	購買時間
		"""
		log = [
			self.game.scene_mgr.name_to_uid(mall_history.rolename), #买家uid
			category, #商城物品分类
			mall_history.rolename, #角色名称
			mall_history.item_id, #物品id
			mall_history.item_name, #物品名称
			mall_history.currency, #消费类型  礼券 = 0   点卷 = 1
			mall_history.item_price, #价格
			mall_history.item_count, #数量
			mall_history.buy_datetime.strftime(self.time_fmt), #时间
		]
		return log

	@tw_log(LT_DELETE_ITEM)
	def delete_item_log(self):
		"""
		删除物品日志
		查詢:可輸入 角色ID,角色名稱,物品ID,物品類型ID,顏色,丟棄類型
		角色ID	角色名稱	物品ID	物品類型ID	物品名稱	物品數量	物品顏色	綁定類型	強化等級	刪除類型	操作時間
		"""
		log = {}
		return log

	@tw_log(LT_SEND_MAIL)
	def send_mail_log(self, sender, target, title, content, item_count_list, money):
		"""
    邮件发送日志
		查詢:可輸入 發件人名稱,收件人ID,物品類型ID,可勾選遊戲幣大於0,可勾選點券大於0,查詢按鈕
		列出 發件人名稱,收件人ID,收件人名稱,物品ID,物品數量,遊戲幣,點券,物品類型 ID,物品類型名稱,發送時間,領取附件時間
		"""
		md5 = sender, target, title, content
		log = {}
		return log

	@tw_log(LT_BATTLE)
	def battle_log(self):
		"""
		副本日志
		查詢:可輸入 玩家ID,角色名稱,選擇戰場別(競技場,攻城戰),日期,搜尋按鈕
		列出 參加人數,玩家ID,角色名稱,戰場,報名時間,後台發送進入時間, 玩家首次進入戰場時間,離開時間
		"""
		log = {}
		return log

	@tw_log(LT_MATRIX)
	def matrix_log(self):
		"""
		迷失矩阵日志
		查詢:可輸入 玩家ID,角色名稱,日期,搜尋按鈕
		列出迷失矩陣挑戰玩家:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕,挑戰層數,掉落物品
		"""
		log = {}
		return log

	@tw_log(LT_EQUIP_REIFORCE)
	def equip_reiforce_log(self):
		"""
		装备强化日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色ID,角色名稱,裝備名稱,裝備等級,裝備當前強化等級,總概率,隨機概率,失敗次數,強化石(1級升星石.等),幸運石使用量,是否使用保護石,消費遊戲幣,狀態(成功or失敗)
		"""
		log = {}
		return log

	@tw_log(LT_EQUIP_HOLE)
	def equip_hole_log(self):
		"""
		装备打孔日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色ID,角色名稱,裝備名稱,裝備等級,裝備當前孔數,消費遊戲幣,狀態
		"""
		log = {}
		return log

	@tw_log(LT_EQUIP_INLAY)
	def equip_inlay_log(self):
		"""
		装备镶嵌日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色ID,角色名稱,裝備名稱,裝備等級鑲嵌之寶石物品,消費遊戲幣
		"""
		log = {}
		return log

	@tw_log(LT_COMBINE_GEM)
	def combine_gem_log(self):
		"""
		宝石合成日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色ID,角色名稱,寶石名稱,寶石數量,新寶石名稱,概率,隨機概率,消費遊戲幣,狀態
		"""
		log = {}
		return log

	@tw_log(LT_EQUIP_DECOMPOSE)
	def equip_decompose_log(self):
		"""
		装备分解日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色 ID,角色名稱,裝備名稱,拆解後之物品
		"""
		log = {}
		return log

	@tw_log(LT_DESTROY_MONSTER)
	def destroy_monster_log(self):
		"""
		灭魔日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,操作時間,角色ID,角色名稱,物品ID,物品名稱,物品數量
		"""
		log = {}
		return log

	@tw_log(LT_DNA_ENCHANT)
	def dna_enhance_log(self):
		"""
		基因改造日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,角色ID,角色名稱,基因ID,基因等級,強化時間
		"""
		log = {}
		return log

	@tw_log(LT_EQUIP_ENCHANT)
	def equip_enchant_log(self):
		"""
		装备附魔日志
		分兩個頁籤,第一個 - 附魔日誌
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,角色ID,角色名稱,裝備ID,裝備名稱,第幾次附魔,附魔屬性,花費(遊戲幣or點券),附魔時間

		頁籤2 - 附魔統計
		查詢:(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 第一次附魔總次數,第二次附魔總次數,第三次附魔總次數,第四次附魔總次數
		列出 使用次數,使用人數,附魔次數,第一次附魔次數,第二次附魔次數,第三次附魔次數,第四次附魔次數
		"""
		log = {}
		return log

	@tw_log(LT_COMBINE_AVATAR)
	def combine_avatar_log(self):
		"""
		时装合成日志
		查詢:可輸入 角色ID,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 編號,角色ID,物品ID,合成前時裝,用來合成之時裝,合成後時裝,機率,狀態
		"""
		log = {}
		return log

	@tw_log(LT_LOGON)
	def logon_log(self):
		"""
		登录日志
		查詢:可輸入 角色ID,角色名稱,日期時段(從?月?日到?月?日,日曆選單),搜索按鈕
		列出 角色ID,角色名稱,上線時間,下線時間,登入IP
		"""
		log = {}
		return log











