# -*- coding:utf-8 -*-
"""
Copy right FQ.
"""

def __sorted_cmp__(a, b):
    try:
        return cmp(int(a), int(b))
    except ValueError:
        return cmp(a, b)

class dictstruct(object):
    """
    This is an jie-cao less like lua map date struct.
    Support a easy get-set obj and also support some attribute like dict.

    When use it, just make an object such as:          d = dictstruct()
    When use with dict date for init:                  d = dictstruct(d), d is a dict

    Functions:
        __sortediter_k__    :    return sorted iter keys of this object.
        __sortediter_v__    :    return sorted iter values of this object.
        __sortediter_kv__    :    return sorted iter keys,values of this object.
    """
    def __init__(self, d=None):
        object.__init__(self)
        if d is None:
            return
        if type(d) != dict:
            raise TypeError, 'need a dict or nothing.'
        self.__dict__.update(d)

    def __getattr__(self, key):
        try:
            return object.__getattr__(self, key)
        except AttributeError:
            return None

    def __sortinner__(self):
        __sorted_k = self.__dict__.keys()
        __sorted_k.sort(__sorted_cmp__)
        return __sorted_k

    def __sortediter_k__(self):
        __sorted_k = self.__sortinner__()
        return iter(__sorted_k)

    def __sortediter_v__(self):
        __sorted_k = self.__sortinner__()
        for k in __sorted_k:
            yield self.__dict__[k]

    def __sortediter_kv__(self):
        __sorted_k = self.__sortinner__()
        for k in __sorted_k:
            yield (k, self.__dict__[k])

    def charge(self, d):
        """
        Add new attributes with a dict.
        """
        if type(d) != dict:
            raise TypeError, 'need a dict.'
        self.__dict__.update(d)

    def charge_kv(self, key, value):
        """
        Add new attributes with key and value.
        """
        self.__dict__.update({key : value})

    def iter_v(self, sorted=False):
        if not sorted:
            return self.__dict__.itervalues()
        return self.__sortediter_v__()

    def iter_k(self, sorted=False):
        if not sorted:
            return self.__dict__.iterkeys()
        return self.__sortediter_k__()

    def iter_kv(self, sorted=False):
        if not sorted:
            return self.__dict__.iteritems()
        return self.__sortediter_kv__()