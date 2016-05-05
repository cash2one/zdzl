#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
加载数值模型
物品信息
任务信息
等等所有外部的数据
"""
import os, sys
import functools
import re
import random
from os.path import join
import csv
from xml.etree import cElementTree

#from protobuf import game_pb2

from corelib import log
from . import common as common_md
from constant import ONE_DAY_DELTA

DATA_PATH = 'data/'

###职业名称: 0-通用 1-剑士 2-科学家 3-异能者 4-特种兵 5-其它
##JOB_ALL = game_pb2.JOB_ALL
##JOB_SWORDSMAN = game_pb2.JOB_SWORDSMAN
##JOB_SCIENTIST = game_pb2.JOB_SCIENTIST
##JOB_PROTOSS = game_pb2.JOB_PROTOSS
##JOB_SOLDIER = game_pb2.JOB_SOLDIER
##JOB_OTHER = game_pb2.JOB_OTHER #在技能类型中用到，怪物、飞行道具技能类型
##ROLE_JOBS = [JOB_ALL, JOB_SWORDSMAN, JOB_SCIENTIST, JOB_PROTOSS, JOB_SOLDIER]
##JOBS = [JOB_OTHER, ] + ROLE_JOBS

#csv文件编码
CSV_ENCODE = 'gb18030'
#静态常量配置
STATIC_CFG_FILE = 'config/static_cfg.csv'
#角色等级配置文件
LEVEL_SWORDSMAN_FILE = 'config/level/swordsman.csv'
LEVEL_PROTOSS_FILE = 'config/level/protoss.csv'
LEVEL_SCIENTIST_FILE = 'config/level/scientist.csv'
LEVEL_SOLDIER_FILE = 'config/level/soldier.csv'
#SP等级限制表
LEVEL_SP_LIMIT_FILE = 'config/level/level_sp_limit_file.csv'
#物品配置文件
ITEM_FILE = 'config/item/item.csv'
AVATAR_FILE = 'config/item/avatar.csv'
AVATAR_COMBINE_FILE = 'config/item/avatar_combine.csv'
EQUIP_FILE = 'config/item/equip.csv'
EQUIP_REINFORCE_FILE = 'config/item/equip_reinforce.csv'
EQUIP_RANDOM_FILE = 'config/item/equip_random.csv'
EQUIP_DECOMPOSE_FILE = 'config/item/equip_decompose.csv'
EQUIP_DECOMPOSE_LUCK_FILE = 'config/item/equip_decompose_luck.csv'
EQUIP_DECOMPOSE_SPECIAL_FILE = 'config/item/equip_decompose_special.csv'
EQUIP_IMPROVE_FILE = 'config/item/equip_improve.csv'
EQUIP_ENCHANT_FILE = 'config/item/equip_enchant.csv'
ITEM_MAKE_FILE = 'config/item/make.csv'
SUIT_FILE = 'config/item/suit.csv'
ITEM_SET_FILE = 'config/item/item_set.csv'
LIMIT_DROP_FILE = 'config/item/limit_drop.csv'
MAP_DROP_FILE = 'config/item/map_drop.csv'
MONSTER_DROP_FILE = 'config/item/monster_drop.csv'
GLOBAL_DROP_FILE = 'config/item/global_drop.csv'
PUBLIC_MAP_DROP_FILE = 'config/item/public_map_drop.csv'
FortuneCat_FILE1 = 'config/item/fortunecat1.csv'
FortuneCat_FILE2 = 'config/item/fortunecat2.csv'
#宝石镶嵌各种条件限制配置
INLAY_LIMIT_FILE = 'config/item/inlay/limit.csv'
#装备星级强化配置
STAR_REINFORCE_LIMIT_FILE = 'config/item/star_reinforce/limit.csv'
STAR_REINFORCE_ATTR_ODDS_FILE = 'config/item/star_reinforce/attr_odds.csv'

#问答题库配置文件
TEST_PAPER_QUESTION_FILE = 'config/questions/questions.csv'
TEST_PAPER_REWARD_FILE = 'config/questions/reward.csv'
TEST_PAPER_EXP_REWARD_FILE = 'config/questions/exp_reward.csv'

#技能配置表
SKILL_FILE = 'config/skill.csv'
#状态配置表
BUFF_FILE = 'config/buff.csv'
#任务配置表（废弃）
QUEST_FILE = 'config/quest/questConfig.xml'
#随机任务配置表
RANDOM_QUEST = 'config/quest/random_quest.csv'
#任务配置表CSV
QUEST_FILE_CSV = 'config/quest/quest.csv'
#任务目标配置表CSV
TASK_FILE_CSV = 'config/quest/task.csv'
#怪物配置表
MONSTER_FILE = 'config/monster.csv'
MONSTER_PREFIX_FILE = 'config/monster_prefix.csv'
MONSTER_PARAMS_FILE = 'config/monster_params.csv'
#副本物品配置表
BATTLE_ITEM_FILE = 'config/battle_item.csv'
#武器配置表（飞行道具）
ARM_FILE = 'config/arm.csv'
#关卡经验表
MAP_FILE = 'config/map.csv'
#主城地图配置表
CITY_MAP_FILE = 'config/map_city.csv'
#旅游热榜配置表
scenicspot_file = 'config/scenicspot.csv'
#旅游NPC随机内容配置表
scenicnpc_file = 'config/scenicnpc.csv'
#旅游经验配置表
scenicexp_file = 'config/scenicexp.csv'
#竞技场相关配置
ARENA_LEVEL = 'config/arena/level_point.csv'
ARENA_VIP = 'config/arena/vip_point.csv'
#商城物品
MALL_ITEM_FILE = 'config/item/mall.csv'
#助理宠物
ASSISTANT_PET_FILE = 'config/assistant/pet.csv'
#助理宠物等级
ASSISTANT_LEVEL_FILE = 'config/assistant/level.csv'
#助理景区
ASSISTANT_AREA_FILE = 'config/assistant/area.csv'
#助理景点
ASSISTANT_ATTRACTION_FILE = 'config/assistant/attraction.csv'
#助理事件
ASSISTANT_KNOWLEDGE_FILE = 'config/assistant/knowledge.csv'
#助理锻造表
ASSISTANT_FORMULA_FILE = 'config/assistant/formula.csv'
#助理食谱表
ASSISTANT_RECIPE_FILE = 'config/assistant/recipe.csv'
#竞技场战场特殊信息表
ARENA_BATTLE_INFO = 'config/arena/arena_scene.csv'
#VIP权限配置表
VIP_RIGHT_FILE = 'config/vipright.csv'
#VIP奖励配置表
VIP_REWARD_FILE = 'config/vip/vip_reward.csv'
#VIP对应装备提前等级穿戴，提前升级
VIP_EQUIP_IMPROVE = 'config/vip/vip2equip_level2improve_level.csv'
#VIP商店配置
VIP_SHOP_FILE = 'config/vip/vip_shop.csv'
#VIP行动力恢复次数
VIP_ACT_RECOVER_FILE = 'config/vip/vip_act_recover.csv'
#活动控制配置表
COPY_ACTI_CTRL = 'config/copy_acti_ctrl.csv'
COPY_BROAD_CAST = 'config/copy_broadcast.csv'
#游戏物品类型配置表
GAME_ITEM_TYPE = 'config/game_item_type.csv'
#保险配置
INSURANCE = 'config/insurance.csv'
#星盘竞猜相关
GLOBAL_PROP = 'config/astrolabe_gamble/global_prop.csv'
MONEY_PROP = 'config/astrolabe_gamble/money_prop.csv'
SP_PROP = 'config/astrolabe_gamble/sp_prop.csv'
ITEM_PROP = 'config/astrolabe_gamble/item_prop.csv'
SUIT_PROP = 'config/astrolabe_gamble/suit_prop.csv'
#副本地图顺序配置
BATTLE_ORDER = 'config/battle_order.csv'
#挂机练功经验配置
STYLITE_FILE = 'config/stylite.csv'
#商店配置
SHOP_FILE = 'config/item/shop.csv'
#VIP模块下，角色行为CD配置
VIP_ACTION_CD = 'config/vip/vipactioncd.csv'
#礼包配置表
GIFT_FILE = 'config/gifts.csv'
#角色升到5的倍数的级数时根据vip等级奖励复活币
VIP_RELIVE_COIN = 'config/vip/vip_relive_coin.csv'
#基因强化
DNA_ENHANCE = 'config/dna_enhance.csv'
#杀戮空间奖励配置
MELEE_REWARD_FILE = 'config/copy_activity/melee_reward.csv'
#科研中心
RESEARCH_REWARD = 'config/research_center/research_reward.csv'
RESEARCH_PROBABILITY_WEALTH = 'config/research_center/research_probability_wealth.csv'
BUILDING_FEE = 'config/research_center/building_fee.csv'
#在线奖励
SIGN_IN_REWARD = 'config/sign_in_reward.csv'
#挑战相关
CHALLENGE_CONTINUE_WIN = 'config/challenge/continue_win.csv'
CHALLENGE_TERMINATE_WIN = 'config/challenge/terminate_win.csv'
CHALLENGE_RANK_REWARD = 'config/challenge/rank_reward.csv'

def random_ran(start, end):
	""" 平均分布的随机数,允许输入浮点，输出浮点 """
	return random.uniform(start, end)

#数据表达式用到的特殊函数
GLOBAL_FUNCS = {
	'ran': random_ran,
	'Position': common_md.Position,
	'Speed': common_md.Speed,
	'randint': random.randint,
}


def expr_number(expression, params):
	"""
	计算expression字符串公式,返回数值;
	expression:公式,如：
		(100 + ran(10, 20))/100.0
		(100 + ran(<p-v1>,<p-v2>))/100.0
	其中<p-v1>代表变量，变量的具体数值由params确定
	params:公式的变量集(格式为字典)；如：
		params={'p-v1':10, 'p-v2':20}
	"""
	if not expression:
		return None
	if type(expression) in (str, unicode) and params:
		expression = re.sub('<', '%(', expression)
		expression = re.sub('>', ')s', expression)
		expression = expression % params
	try:
		return float(expression)
	except ValueError:
		pass
	except TypeError:
		#如：float(None) raise:
		#TypeError: float() argument must be a string or a number
		return 0
	return eval(expression, GLOBAL_FUNCS)

def eval_func(expression):
	def eval_expr():
		""" eval expression """
		return eval(expression, GLOBAL_FUNCS)
	try:
		return float(expression)
	except ValueError:
		eval_expr.expression = expression
		return eval_expr

DATA_TYPES = {
	'int': (int, 0),
	'float': (float, 0.0),
	'eval': (eval_func, 0.0),
	'': (str, ''),
    'string': (str, ''),
    'array': (str, ''),
	None: (str, ''),
}

def complex_float(value):
	""" 复杂数值，第一位字符可以包含运算符,如果是运算符，将返回函数 """
	if not value:
		return 0.0
	op = value[0]
	if op == '=':
		code = 'lambda x: ' + value[1:]
		return eval(code)
	elif op in ('+', '-', '*', '/'):
		#四则运算：+ - * /
		code = 'lambda x: x ' + value
		return eval(code)

	try:
		return float(value)
	except ValueError:
		return 0

def del_mongodb(fs):
	""" 删除data在mongodb中的所有资源 """
	fs.delete_path(DATA_PATH)

def save_to_mongodb(fs, app_path, delete_old=True):
	""" 将本地data目录下的所有服务器端用到的文件上传到mongodb中 """
	app_path = os.path.abspath(app_path)
	os_sep = os.path.sep
	my_sep = '/'
	path_len = len(app_path) + len(os_sep)
	if delete_old:
		del_mongodb(fs)

	for walk in os.walk(app_path):
		path, dirs, files = walk
		if not files:
			continue
		relpath = path[path_len:].replace(os_sep, my_sep)
		for file_name in files:
			if file_name[0] not in ['.', '_']:
				with open(os.path.join(path, file_name), 'rb') as f:
					print 'save file:%s' % relpath
					fs.put(f.read(), filename=relpath, path=DATA_PATH)


def get_no_none(data, typefunc, none_value):
	"""  将data格式化成typefunc指定的类型并返回，如果data是None,返回none_value
	"""
	if data is None or data.strip() == '':
		return none_value
	return typefunc(data)

def splite_data(data, data_type, sep = ',', default = None):
	"""  将固定格式的数据分隔，并类型转换，如：
		splite_data('1,2,3', int) 返回: [1,2,3]
	"""
	if not data:
		return default
	return [data_type(v) for v in data.split(sep)]

def avg_int(amount, share):
	"""
	将一个整数平均分成share份整数
	"""
	quotient, remainder = divmod(amount, share)

	rs = [quotient for x in xrange(share)]

	for index in xrange(remainder):
		rs[index] += 1

	return rs

def get_bound(bounds, value):
	"""
	bounds = [(min1, max1), (min2, max2), ...]
	获取value在哪个区间
	"""
	for bound in bounds:
		if bound[1] == 0:
			if bound[0] <= value:
				return bound
		elif bound[0] <= value <= bound[1]:
			return bound

def get_bounds(bounds, value):
	"""
	bounds = [(min1, max1), (min2, max2), ...]
	区间可能有重叠，需要获取value在哪几个区间
	"""
	sets = []
	for bound in bounds:
		if bound[0] <= value <= bound[1]:
			sets.append(bound)

	return sets

def is_day_step_over(old_time, new_time):
	"""
	是否跨越了一天
	"""
	if new_time.date() - old_time.date() >= ONE_DAY_DELTA:
		return True
	return False

def is_week_step_over(old_time, new_time):
	"""
	是否跨越到下星期
	"""
	old_weekday = old_time.weekday()
	new_weekday = new_time.weekday()
	if new_weekday < old_weekday:
		return True
	if (new_time - old_time).days >= 7:
		return True
	return False

def is_month_step_over(old_time, new_time):
	"""
	是否跨越到下个月
	"""
	if new_time.year > old_time.year:
		return True
	if new_time.month > old_time.month:
		return True
	return False

class Reader(object):

	def load(self, new_func=None, init_func = None, cls=None, assign_func=None, *args, **kwargs):
		pass

	def load_data(self, load_func, *args, **kwargs):
		pass

	def load_dict(self, load_fun,  *args, **kwargs):
		pass

class ModelReader(Reader):

	def  __init__(self, model_name):
		pass

	def load(self, new_func=None, init_func = None, cls=None, assign_func=None):
		pass

	def load_data(self, load_func = None):
		pass

	def load_dict(self, load_func = None):
		pass

class CsvReader(Reader):
	def __init__(self, full_name, row_name, row_type, encode=None):
		self.file = open(full_name, 'rb')
		self.row_name = row_name
		self.row_type = row_type
		self.names = None
		self.name_indexs = {}
		self.encode = encode
		if self.encode is None:
			self.reader = enumerate(csv.reader(self.file), start = 1)
		else:
			self.reader = enumerate(csv.reader(self._iter_file()), start = 1)

	def __del__(self):
		if not self.file.closed:
			self.file.close()

	def __iter__(self):
		return self

	def _iter_file(self):
		for data in self.file:
			yield data.decode(self.encode)

	def next(self):
		index, data = self.reader.next()
		if self.row_name == index:
			self.names = [v.strip() for v in data]
		elif self.row_type == index:
			self.types = [DATA_TYPES[v.strip()] for v in data]
		return index, data

	def _iter_data(self, data):
		for i, value in enumerate(data):
			if i >= len(self.names):
				return
			name = self.names[i]
			if not name:
				continue
			value = get_no_none(value, *self.types[i])
			if type(value) == str:
				value = value.decode('utf-8')
			yield name, value

	def assign_to(self, obj, data, assign_func):
		for name, value in self._iter_data(data):
			if assign_func is None:
				setattr(obj, name, value)
			else:
				assign_func(obj, name, value)

	def load(self, row_data, new_func=None, init_func = None, cls=None, assign_func=None):
		for index, data in self:
			if index < row_data:
				continue
			if callable(new_func):
				obj = new_func(self, data)
			else:
				obj = cls()

			if obj is None:
				continue

			self.assign_to(obj, data, assign_func)
			if callable(init_func):
				init_func(obj)

	def load_data(self, row_data, load_func):
		for index, data in self:
			if index >= row_data:
				load_func(data)

	def load_dict(self, row_data, load_func):
		""" 将数据转成字典，供外部处理 """
		for index, data in self:
			if index >= row_data:
				load_func(dict(self._iter_data(data)))


class ResMgr(object):
	""" 资源类 """
	def __init__(self):
		self.resources = {}
		self.cfg = None
		self.static_csv_cfg = {}

	def get_csv_reader(self, rel_path, row_name, row_type, encode=None):
		pass

	def init_cfg(self, cfg):
		self.cfg = cfg

	def init_static_csv_cfg(self):
		row_data, row_name, row_type = 4, 3, 2
		reader = self.get_csv_reader(STATIC_CFG_FILE, row_name, row_type)
		reader.load_dict(row_data, self._load_static_csv_cfg)

	def _load_static_csv_cfg(self, data):
		name = data['name']
		value = data['value']
		self.static_csv_cfg[name] = value

class FileResMgr(ResMgr):
	""" 文件资源 """
	def __init__(self, res_path):
		ResMgr.__init__(self)
		self.res_path = res_path

	def load(self):
		#加载game配置
		cfg_path = self.get_res_full_path('config')
		sys.path.insert(0, cfg_path)
		import game_config
		if self.cfg is not None:
			reload(game_config)
		self.init_cfg(game_config)
		self.init_static_csv_cfg()
		#sys.path.remove(cfg_path)

	def get_res_full_path(self, rel_path):
		return join(self.res_path, rel_path)

	def get_csv_reader(self, rel_path, row_name, row_type, encode=CSV_ENCODE):
		full_path = self.get_res_full_path(rel_path)
		reader = CsvReader(full_path, row_name, row_type, encode)
		return reader

	def get_xml_doc(self, rel_path):
		full_path = self.get_res_full_path(rel_path)
		xml_doc = cElementTree.parse(full_path)
		return xml_doc

	def get_model_reader(self, model_name):
		model_reader = ModelReader(model_name)
		return model_reader

	def dump_to_cache(self):
		pass

	def load_from_cache(self):
		pass
