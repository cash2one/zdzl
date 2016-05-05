#!/usr/bin/env python
# -*- coding:utf-8 -*-
import config

import os, sys
import locale
encoding = locale.getdefaultlocale()[1]
if encoding is None:
    encoding = 'UTF-8'
here = os.path.join(os.environ['ROOT_PATH'], 'test')


def main():
    if '-h' in sys.argv:
        print u"""
使用nose测试框架, 运行测试需要先安装nose:
    easy_install nose

使用方式：
    python main.py test    运行test目录下的所有测试
说明：
    测试函数中可以使用log模块记录错误信息
    只运行部分测试的方法(参考test_other/test_speed.py代码)：
    1.先在测试函数前，增加common.attr的装饰
    2.运行时参数如：
        python main.py test -a speed
        """.decode('utf-8').encode(encoding)
        sys.exit(0)

    #下面代码中，level不起作用，nose会去处理
    from corelib import log
    log.console_config(False)
    import game
    game.Game.app = 'test'

    if '-g' in sys.argv:
        sys.argv.remove('-g')
        from game import SimpleGame
        game = SimpleGame(config.res_dir)
        game.init(config.db_engine, config.setting_url_mongodb)

    try:
        try:
            print u'测试路径:%s' % here
            from nose import main as nose_main
            if sys.platform in ['cygwin']:
                os.environ['NOSE_INCLUDE_EXE'] = '1'
            nose_main(defaultTest=here)
        finally:
            pass
    except ImportError:
        print u'需要安装nose包，请执行:easy_install -U nose'

if __name__ == '__main__':
    main()
