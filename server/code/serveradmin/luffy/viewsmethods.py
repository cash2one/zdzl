#!/usr/bin/env python
#coding=utf-8
__author__ = 'kainwu'

from flask import request


def from_html(method='GET', t=None):
    ret = {}
    if method == 'GET':
        items = request.args
    if method == 'POST':
        items = request.form
    [ret.update({item:t[item](items[item])}) for item in items if item in t]
    return ret
