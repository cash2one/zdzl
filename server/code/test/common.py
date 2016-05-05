#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
使用nose的attr插件，实现测试部分模块的功能，下面的部分例子：
Simple syntax (-a, --attr) examples:
  * python main.py test -a status=stable
    => only test cases with attribute "status" having value "stable"

  * python main.py test -a priority=2,status=stable
    => both attributes must match

  * python main.py test -a tags=http
    => attribute list "tags" must contain value "http" (see test_foobar()
       below for definition)

  * python main.py test -a slow
    => attribute "slow" must be defined and its value cannot equal to False
       (False, [], "", etc...)

  * python main.py test -a !slow
    => attribute "slow" must NOT be defined or its value must be equal to False

Eval expression syntax (-A, --eval-attr) examples:
  * python main.py test -A "not slow"
  * python main.py test -A "(priority > 5) and not slow"

"""

def attr(**kwargs):
    """Add attributes to a test function/method/class"""
    def wrap(func):
        func.__dict__.update(kwargs)
        return func
    return wrap
