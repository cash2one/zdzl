#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os, sys
from os.path import join, abspath
from corelib import common, log

import config

class Application(common.BaseApp):
    def __init__(self):
        common.BaseApp.init(self, config)

    def run(self):
        log.warn('run...')
        import manage
        #manage.run(config.SERVER_HOST_PORT)
        manage.start(config.SERVER_HOST_PORT)

def main():
#    admin_path = join(os.environ['ROOT_PATH'], 'serveradmin')
    log.warning("admin_path:::%s", config.admin_path)
    sys.path.insert(0, config.admin_path)
    app = Application()
    common.daemon(app)

