#!/usr/bin/env python
import os, sys
import datetime
from os.path import join, abspath, dirname, exists

def main():
    root_path = abspath(dirname(__file__))
    log_file = join(root_path, 'restart.log')
    argv = sys.argv[1:]
    main_path = join(root_path, 'main.py')
    if not exists(main_path):
        main_path = join(root_path, 'main.pyc')
    argv = argv[:1] + [main_path] + argv[1:]

    with open(log_file, 'a') as f:
        f.write('restart on:%s\n' % datetime.datetime.now())
        f.write('  %s\n' % str(argv))
    os.system(' '.join(argv))


if __name__ =='__main__':
    main()
