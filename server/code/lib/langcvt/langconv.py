#!/usr/bin/env python
# -*- coding: utf-8 -*-

from copy import deepcopy
import re
import hashlib

##try:
##    import psyco
##    psyco.full()
##except:
##    pass

from zh_wiki import zh2Hant, zh2Hans, zh2TW, zh2SG, zh2HK

# states
(START, END, FAIL, WAIT_TAIL) = range(4)
# conditions
(TAIL, ERROR, MATCHED_SWITCH, UNMATCHED_SWITCH, CONNECTOR) = range(5)

MAPS = {}

class Node:
    def __init__(self, from_word, to_word=None, is_tail=True,
            have_child=False):
        self.from_word = from_word
        if to_word is None:
            self.to_word = from_word
            self.data = (is_tail, have_child, from_word)
            self.is_original = True
        else:
            self.to_word = to_word or from_word
            self.data = (is_tail, have_child, to_word)
            self.is_original = False
        self.is_tail = is_tail
        self.have_child = have_child

    def is_original_long_word(self):
        return self.is_original and len(self.from_word)>1

    def is_follow(self, chars):
        return chars != self.from_word[:-1]

    def __str__(self):
        return '<Node, %s, %s, %s, %s>' % (repr(self.from_word),
                repr(self.to_word), self.is_tail, self.have_child)

    __repr__ = __str__

class ConvertMap:
    def __init__(self, name, mapping=None):
        self.name = name
        self._map = {}
        if mapping:
            self.set_convert_map(mapping)

    def set_convert_map(self, mapping):
        convert_map = {}
        have_child = {}
        max_key_length = 0
        for key in sorted(mapping.keys()):
            if len(key)>1:
                for i in range(1, len(key)):
                    parent_key = key[:i]
                    have_child[parent_key] = True
            have_child[key] = False
            max_key_length = max(max_key_length, len(key))
        for key in sorted(have_child.keys()):
            convert_map[key] = (key in mapping, have_child[key],
                    mapping.get(key, ''))
        self._map = convert_map
        self.max_key_length = max_key_length

    def __getitem__(self, k):
        try:
            is_tail, have_child, to_word  = self._map[k]
            return Node(k, to_word, is_tail, have_child)
        except:
            return Node(k)

    def __contains__(self, k):
        return k in self._map

    def __len__(self):
        return len(self._map)

class StatesMachineException(Exception): pass

class StatesMachine:
    def __init__(self):
        self.state = START
        self.final = u''
        self.len = 0
        self.pool = u''

    def clone(self, pool):
        new = deepcopy(self)
        new.state = WAIT_TAIL
        new.pool = pool
        return new

    def feed(self, char, map):
        node = map[self.pool+char]

        if node.have_child:
            if node.is_tail:
                if node.is_original:
                    cond = UNMATCHED_SWITCH
                else:
                    cond = MATCHED_SWITCH
            else:
                cond = CONNECTOR
        else:
            if node.is_tail:
                cond = TAIL
            else:
                cond = ERROR

        new = None
        if cond == ERROR:
            self.state = FAIL
        elif cond == TAIL:
            if self.state == WAIT_TAIL and node.is_original_long_word():
                self.state = FAIL
            else:
                self.final += node.to_word
                self.len += 1
                self.pool = ''
                self.state = END
        elif self.state == START or self.state == WAIT_TAIL:
            if cond == MATCHED_SWITCH:
                new = self.clone(node.from_word)
                self.final += node.to_word
                self.len += 1
                self.state = END
                self.pool = ''
            elif cond == UNMATCHED_SWITCH or cond == CONNECTOR:
                if self.state == START:
                    new = self.clone(node.from_word)
                    self.final += node.to_word
                    self.len += 1
                    self.state = END
                else:
                    if node.is_follow(self.pool):
                        self.state = FAIL
                    else:
                        self.pool = node.from_word
        elif self.state == END:
            # END is a new START
            self.state = START
            new = self.feed(char, map)
        elif self.state == FAIL:
            raise StatesMachineException('Translate States Machine '
                    'have error with input data %s' % node)
        return new

    def __len__(self):
        return self.len + 1

    def __str__(self):
        return '<StatesMachine %s, pool: "%s", state: %s, final: %s>' % (
                id(self), self.pool, self.state, self.final)
    __repr__ = __str__

class Converter:
    def __init__(self, to_encoding):
        self.to_encoding = to_encoding
        self.map = MAPS[to_encoding]
        self.start()

    def feed(self, char):
        branches = []
        for fsm in self.machines:
            new = fsm.feed(char, self.map)
            if new:
                branches.append(new)
        if branches:
            self.machines.extend(branches)
        self.machines = [fsm for fsm in self.machines if fsm.state != FAIL]
        all_ok = True
        for fsm in self.machines:
            if fsm.state != END:
                all_ok = False
        if all_ok:
            self._clean()
        return self.get_result()

    def _clean(self):
        if len(self.machines):
            self.machines.sort(cmp=lambda x,y: cmp(len(x), len(y)))
            self.final += self.machines[0].final
        self.machines = [StatesMachine()]

    def start(self):
        self.machines = [StatesMachine()]
        self.final = u''

    def end(self):
        self.machines = [fsm for fsm in self.machines
                if fsm.state == FAIL or fsm.state == END]
        self._clean()

    def convert(self, string):
        self.start()
        for char in string:
            self.feed(char)
        self.end()
        return self.get_result()

    def get_result(self):
        return self.final

def registery(name, mapping):
    global MAPS
    MAPS[name] = ConvertMap(name, mapping)

registery('cn-hk', zh2Hant)
registery('hk-cn', zh2Hans)
registery('TW', zh2TW)
registery('SG', zh2SG)
registery('HK', zh2HK)
registery('Hans2Hant', zh2Hant)
registery('Hant2Hans', zh2Hans)
del zh2Hant, zh2Hans, zh2TW, zh2SG, zh2HK

def convert_to(content, region_code, instr_encoding='utf-8'):
    """
    :params 'content' 要转换的内容
    :params 'region_code' 是地区代号的两个字母的缩写, 例如： 香港为HK，新加波为SG
    :params 'instr_encoding' 要转换的字符串的编码，默认是utf-8
    :return type(str) the resulted string encoding in instr_encoding
    """
    if region_code not in MAPS:
        print('错误的region_code: %s\n  有效的转换码为%s' % (region_code, str(MAPS.keys())))
        return
    if not isinstance(content, unicode):
        content = content.decode(instr_encoding)
    c = Converter(region_code)
    return c.convert(content)


def cn2tw(content, encoding='utf-8'):
    """
    简中转为台湾
    """
    first_pass_res =  convert_to(content, "TW", encoding)
    return convert_to(first_pass_res, "Hans2Hant", encoding)


def cn2hk(content, encoding='utf-8'):
    """
    简中转为香港
    """
    first_pass_res = convert_to(content, "HK", encoding)
    return convert_to(first_pass_res, "Hans2Hant", encoding)

def hk2cn(content, encoding='utf-8'):
    """
    繁体转简休
    """
    return convert_to(content, "Hant2Hans", encoding)


def cn2sg(content, encoding='utf-8'):
    """
    简中转为新加坡语
    """
    return convert_to(content, 'SG', encoding)


def generate_ban_word(tn="ban_word", action='create'):
    """
    生成简繁体敏感词表
    字段: 't', 类型: int, 值: 1 简体; 2 繁体
    """

    from pymongo import MongoClient
    import pymongo
    host = 'dev.zl.efun.com'
    port = '27017'
    dbname = 'td_res'
    field_n = 't'
    trans_f = 'banword'
    connect_str = 'mongodb://%s:%s/' % (host, port)
    mc = MongoClient(host=connect_str)
    db = mc[dbname]
    coll = db[tn]
    if action == 'create':
        all_entries = coll.find(sort=[('_id', pymongo.ASCENDING)])
        n = all_entries.count()
        last_e = all_entries[n - 1]
        next_id = last_e['_id'] + 1
        for e in all_entries:
            if field_n not in e:
                e[field_n] = 1
                coll.save(e)
            trans_v = e[trans_f]
            hk_str = cn2hk(trans_v)
            if trans_v != hk_str:
                hk_entry = {'_id': next_id, trans_f: hk_str, field_n: 2}
                coll.save(hk_entry)
                next_id = next_id + 1
    elif action == 'reset':
        all_entries = coll.remove({field_n: 2})






def run():
    import sys
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option('-e', type='string', dest='region_code',
            help='region_code:%s' % (MAPS.keys(),))
    parser.add_option('-f', type='string', dest='file_in',
            help='input file (- for stdin)')
    parser.add_option('-t', type='string', dest='file_out',
            help='output file')
    (options, args) = parser.parse_args()
    if not options.region_code:
        parser.error('region_code must be set')
    if options.file_in:
        if options.file_in == '-':
            file_in = sys.stdin
        else:
            file_in = open(options.file_in)
    else:
        file_in = sys.stdin
    if options.file_out:
        if options.file_out == '-':
            file_out = sys.stdout
        else:
            file_out = open(options.file_out, 'w')
    else:
        file_out = sys.stdout

    c = Converter(options.region_code)
    for line in file_in:
        print >> file_out, c.convert(line.rstrip('\n').decode(
            'utf8')).encode('utf8')

if __name__ == '__main__':
    ##langconv.py -e cn-hk -f trade.html -t trade_hk.html
    run()
