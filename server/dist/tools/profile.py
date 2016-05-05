import sys, os
from datetime import datetime as dt
from time import mktime
from pprint import pprint

#s1
url_traffic = 'http://cacti.efun.com/graph.php?action=zoom&local_graph_id=1081&rra_id=%d&view_type=&graph_start=%d&graph_end=%d'
url_load = 'http://cacti.efun.com/graph.php?action=zoom&local_graph_id=1079&rra_id=%d&view_type=&graph_start=%d&graph_end=%d'

SPACE_1MIN = 5
SPACE_5MIN = 1
SPACE_30MIN = 2

def get_urls(start, end, space=SPACE_5MIN):
    traffic = url_traffic % (space, start, end)
    load = url_load % (space, start, end)
    return traffic, load


def one_day():
    start = [2013, 4, 28]
    day = start[-1]
    st = int(mktime(dt(*start).timetuple()))
    c = 40
    for i in xrange(c):
        et = st + 86400
        urls = get_urls(st, et, SPACE_5MIN)
        print 'day:%s' % str(dt.fromtimestamp(st))
        for u in urls:
            print '  %s' % u
        st += 86400


one_day()



