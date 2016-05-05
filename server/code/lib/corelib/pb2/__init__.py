#!/usr/bin/env python
# -*- coding:utf-8 -*-
from google.protobuf.internal import type_checkers
#  _MIN = -2147483648
#  _MAX = 2147483647
INT32_MIN = type_checkers.Int32ValueChecker._MIN
INT32_MAX = type_checkers.Int32ValueChecker._MAX
UINT32_MAX = (1 << 32) - 1

