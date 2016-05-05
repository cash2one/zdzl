#!/usr/bin/env python
# -*- coding:utf-8 -*-

class GameError(StandardError): pass

class GameMasterError(GameError): pass

class ItemDropError(GameError):
	pass

class SceneError(GameError): pass
class TransSceneError(GameError): pass

class SkillError(GameError): pass

class StoreDbError(GameError):
	pass

class PlayerError(GameError): pass

class BattleError(GameError):
	pass
class BattleTimeout(BattleError):
	pass
class MaxBattleError(BattleError):
	pass


#资源异常
class ResError(GameError):pass
class ResNotFoundError(ResError):pass

#物品异常类型
class ItemError(GameError): pass
class ItemTimePartEndError(GameError):pass

#背包异常类型
class BagError(GameError): pass
class BagAddError(BagError): pass
class BagNotEnoughSpaceError(BagAddError): pass
class BagItemCountLimitError(BagAddError): pass
class BagItemAddCountError(BagAddError): pass
class BagPopError(BagError): pass
class BagItemPopCountError(BagPopError): pass
class BagNotEnoughItemForPopError(BagPopError): pass
class BagItemIndexNotFoundError(BagPopError):pass
class BagExchangeItemError(BagError): pass
class BagItemNotFoundError(BagError): pass
class BagCountNotEnoughError(BagError): pass
class BagGetWrongCountError(BagError):pass

#强化异常类型
class ReinforceError(GameError): pass
class ReinforceItemError(ReinforceError): pass
class ReinforceReachHighestLevelError(ReinforceError): pass
class ReinforceGemError(ReinforceError): pass
class ReinforceStuffError(ReinforceError): pass
class ReinforceDataError(ReinforceError): pass
class ReinforceDestroyError(ReinforceError): pass
class ReinforceNotEnoughMoneyRrror(ReinforceError):pass

#公会异常
class GuildError(GameError): pass
class LackOfPrivilegeError(GuildError): pass
class AlreadyInGuildError(GuildError): pass
class NotInGuildError(GuildError): pass
class GuildExistError(GuildError): pass
class GuildNotExistError(GuildError): pass
class GuildMemberMaxError(GuildError): pass

#part功能部件
class PartError(GameError): pass
#会被忽略的错误
class PartValueError(PartError): pass

#商城异常
class MallError(GameError): pass
class MallItemNotFound(MallError): pass
class MallReelNotEnough(MallError): pass
class MallWealthNotEnough(MallError): pass

#拍卖行异常
class ExchangeError(GameError): pass
class ExchangeItemNotFound(ExchangeError): pass
class ExchangeMoneyNotEnough(ExchangeError): pass
class ExchangeBagItemNotEnough(ExchangeError): pass
class ExchangeAuctionCountLimit(ExchangeError): pass
class ExchangeBidOwnItem(ExchangeError): pass
class ExchangeHigherThanBuyoutPrice(ExchangeError): pass
class ExchangeBidPriceTooLow(ExchangeError): pass
class ExchangeAuctionPriceInvalid(ExchangeError): pass
class ExchangeBidPriceInvalid(ExchangeError): pass
class ExchangeItemExpired(ExchangeError): pass
class ExchangeItemIsBinding(ExchangeError): pass
class ExchangeItemCanNotTrade(ExchangeError): pass
class ExchangePriceTooHigh(ExchangeError): pass

# 助理异常
class AssistantError(GameError): pass
class AssistantPetNumberLimit(AssistantError): pass
class AssistantPetAlreadyWorking(AssistantError): pass
class AssistantPetNotWorking(AssistantError): pass
class AssistantWorkIsNotDone(AssistantError): pass
class AssistantMoneyNotEnough(AssistantError): pass
class AssistantReelNotEnough(AssistantError): pass
class AssistantWealthNotEnough(AssistantError): pass
class AssistantFormulaNotLearned(AssistantError): pass
class AssistantFormulaAlreadyLearned(AssistantError): pass
class AssistantRecipeNotLearned(AssistantError): pass
class AssistantRecipeAlreadyLearned(AssistantError): pass
class AssistantBagItemNotEnough(AssistantError): pass
class AssistantBagNotEnoughSpace(AssistantError): pass
class AssistantNotEnoughLevel(AssistantError): pass

# 钱包异常
class WalletError(GameError): pass
class WalletConnectionError(WalletError): pass
class WalletMaxWealthLimit(WalletError): pass
class WalletWealthInvalid(WalletError): pass
class WalletUuidInvalid(WalletError): pass
class WalletNotEnoughWealth(WalletError): pass

#分页异常
class PageNotAnInteger(GameError): pass
class EmptyPage(GameError): pass
