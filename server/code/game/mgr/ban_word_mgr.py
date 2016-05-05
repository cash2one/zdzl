#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib.data import Trie
from game import Game
from game.store.define import TN_RES_BAN_WORD
from game.base.msg_define import MSG_RES_RELOAD, MSG_START

class BanWordMgr(object):
    _rpc_name_ = 'rpc_ban_word_mgr'

    def __init__(self):
        self.words = None
        import app
        app.sub(MSG_START, self.start)

    def start(self):
        Game.res_mgr.sub(MSG_RES_RELOAD, self.load)
        self.load()

    def load(self):
        self._load_words()

    def _load_words(self):
        #处理敏感词
        words = Game.rpc_res_store.load_all(TN_RES_BAN_WORD)
        self.words = Trie()
        for word in words:
            self.words.insert(word['banword'].decode('utf-8'))

    def check_ban_word(self, string):
        """ 检查是否有敏感词
        result:
            True: 有敏感词
        """
        string = string.lower()
        node = self.words.searchs(string, full=0)
        return node is not None

    def replace_ban_word(self, string):
        """ 用特殊符号代替敏感词 """
        #string = string.lower()
        return self.words.replaces(string, '$')


def new_ban_word_mgr():
    return BanWordMgr()
