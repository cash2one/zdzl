#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import glob
from os.path import join, abspath, dirname, basename, exists
from corelib import spawn, sleep, common, message, Timeout

SUB_LOGIC = 1
SUB_UNION = 2

sys_encoding = os.environ['sys_encoding']
root_path = os.environ['ROOT_PATH']

def log(*args):
    for arg in args:
        if isinstance(arg, unicode):
            print arg.encode(sys_encoding)
        else:
            print arg,
    print '\n'

def _shell(local=None):
    try:
        import IPython
        try:
            import IPython.Shell
            IPython.Shell.start(user_ns=local).mainloop()
            return
        except ImportError as e:
            pass

        from IPython.frontend.terminal import ipapp
        app = ipapp.TerminalIPythonApp.instance()
        app.initialize(argv={})
        if local:
            app.shell.user_ns.update(local)
        app.start()
    except ImportError:
        import code
        code.interact(local=local)


def _get_apps(run_path=None):
    if run_path is None:
        home_path = os.environ['HOME']
        base_path = join(home_path, 'jhyfiles')
        run_path = join(base_path, 'run')
    if not exists(run_path):
        log(u'run目录不存在')
        return
    pidfiles = glob.glob(join(run_path, '*.pid'))
    pids = []
    for pidfile in pidfiles:
        with open(pidfile, 'r') as f:
            pid = f.read()
        pids.append(pid.strip())

    apps = {}
    for pid in pids:
        cmdline = '/proc/%s/cmdline' % pid
        try:
            with open(cmdline, 'rb') as f:
                data = f.read()
        except:
            continue
        cmds = data.split('\x00')
        config_file = ''
        for cmd in cmds:
            if cmd.find('_config.py') > 0:
                config_file = cmd
                break
        if not config_file:
            continue
        with open(config_file, 'rb') as f:
            pys = f.readlines()
        for py in pys:
            if py.find('app = ') == 0:
                _type = py[5:].strip()[1:-1]
                app = apps.setdefault(_type, {})
                app[config_file] = cmds
                break
    return apps






#内存分析
meliae_funcs = """
objs = om.objs
#ft=lambda tname, start=: [o for o in objs.itervalues() if o.type_str == tname]
def ft(tname, start=None, end=None):
    index = 0
    rs = []
    if start is None:
        start = 0
    if end is None:
        end = 9999
    for o in objs.itervalues():
        if o.type_str != tname:
            continue
        if start <= index <= end:
            rs.append(o)
        index += 1
        if index > end:
            break
    return rs
fp=lambda id: [objs.get(rid) for rid in objs.get(id).parents]
fr=lambda id: [objs.get(rid) for rid in objs.get(id).children]
def fp1(id):
    obj = fo1(id)
    return fp(obj)
def fps(obj, rs=None):
    if rs is None:
        rs = []
    if len(rs) > 2000:
        return rs
    if obj is not None and obj not in rs:
        rs.append(obj)
        for p in fr(obj):
            fps(p, rs=rs)
    return rs
def fps1(obj, rs=None):
    if rs is None:
        rs = []
    if len(rs) > 2000:
        return rs
    if obj is not None and obj not in rs:
        if obj.num_parents == 0:
            rs.append(obj)
        for p in fp(obj):
            fps(p, rs=rs)
    return rs
fo=lambda id: objs.get(id)
"""

def _cmd_meliae(app, *args):
    """ 使用meliae分析内存 """
    from meliae import loader
    om = loader.load(args[0])
    om.compute_parents()
    om.collapse_instance_dicts()
    log(om.summarize())
    local = locals()
    exec meliae_funcs in local
    _shell(local=local)

def _cmd_zb64(app, *args):
    """ 将输出的文件内容,先zlib,再以base64字符串输出 """
    from zlib import compress
    from base64 import b64encode
    log(u'********将输出的文件内容,先zlib,再以base64字符串输出********')
    for fn in args:
        if not exists(fn):
            log('file(%s) no found' % fn)
            continue
        log('file(%s):'% fn)
        f = open(fn, 'rb')
        try:
            d = f.read()
        finally:
            f.close()
        log(b64encode(compress(d)))

def _cmd_res(app, res_file, aes_key='xf3R0xdcmx8bxc0J'):
    """ 显示资源内容 """
    from zlib import decompress
    from corelib.aes import new_aes_decrypt
    decrypt = new_aes_decrypt(aes_key)
    with open(res_file, 'rb') as f:
        data = f.read()
    data = decrypt(data)
    try:
        log(decompress(data))
    except:
        log(data)

def _cmd_servers(app, res_file):
    _cmd_res(app, res_file, aes_key='4fcc09d3ceb79129')


def _cmd_all(app, cmd, *app_types):
    """ 根据~/jhyfiles/run目录下的pid文件列表,重启所有某类型的进程
    main.py cmd stop, channel
    app_types参数:channel, web, logon, chat
    """
    home_path = os.environ['HOME']
    base_path = join(home_path, 'jhyfiles')
    run_path = join(base_path, 'run')

    #获取所有运行中的进程信息
    apps = _get_apps()
    if cmd == 'status':
        for key in apps:
            log('app type:%s' % key)
            for config_file, cmds in apps.get(key, {}).iteritems():
                log('  app:%s' % config_file)
        return
        #print apps
    #修改当前路径
    os.chdir(join(base_path, 'virtualenv'))
    def _cmd(app_type):
        for config_file, cmds in apps.get(app_type, {}).iteritems():
            s = 'bin/python srv/main.pyc -c %s %s'
            #执行
            os.system(s % (config_file, cmd))
    for app_type in app_types:
        _cmd(app_type)


def _cmd_restartall(app, app_type=None):
    """ 根据~/jhyfiles/run目录下的pid文件列表,重启所有某类型的进程 """
    if app_type is None:
        log(u'restartall使用例子: main.py restartall channel  \n参数:channel, web, logon, chat')
        return
    home_path = os.environ['HOME']
    base_path = join(home_path, 'jhyfiles')
    run_path = join(base_path, 'run')
    apps = _get_apps()

    #修改当前路径
    os.chdir(join(base_path, 'virtualenv'))
    for config_file, cmds in apps.get(app_type, {}).iteritems():
        if 'start' not in cmds:
            continue
        log(u'*********重启:%s***********' % config_file)
        cmd = 'bin/python srv/main.pyc -c %s %s'
        #停止
        os.system(cmd % (config_file, 'stop'))
        #启动
        os.system(cmd % (config_file, 'start'))
        log(u'*********重启完成***********')

def _cmd_test_notify(app, *args):
    from corelib import sleep
    from webapi.notify import NotifyServer
    import config
    pem_data = """eJxtVsmyq0iS3fMVucfSBAgktKhFBPMo5mnHPM8CJH19c9/Lzs6qaswwwtwDj4O7n+P8+ed5QU6Q9D8YznIkXmKAw/0Y/0Q0SeKLL8NAIS/BIUFQSpI1xGn0kW9vZj1YM5SVMZKqPdWByfHQBEcZhW/mC2RY6h4CQeiAznM0Szs4M2Q901RYMMFUhGtkQznptU2zj0Mpf/lUltH/1xckV3lFIjGbIsEtLcEjIv+9p4L3kXi5SwQei/3Hln55TuMkAeAuB47jbgbwSM79HvH4JIJ1RWLf6iTO6rLeW5Mr7NIa2megKhO6PRm00iS8z7nuY1//bashzAJrPE+fMrE9ELFKdc3RDt0BH411ce2rHf4vm/nvtgZeNIs8RBAqTCT1dWR8VMGECDCPZ0g8XuoQvbMPdYvEaQ0J8v38AuonSRBomtbyRyq8O4mHn4Sw8PBqTQlBlrb7cJDTiKdEWbo/UPuuiQLtJgn6ntgUkQbplvfWLRH07R9JVs8kc/o30l3PChGtiRjNXA/mt1PgDlmyz7ICW/rPEsKzhGxZcgZgT785Muf6/ATltT/72B6HdFFum644m630DFBTKNv2AFW04C710j0qcxr9RTZvt9BnOluV74uMTRjyjCZJSB7S3PoNj8Ji7Om3OObV1/xUr0oBGVOMD2UiM2dbykW889/KazMIdYOV8KGYER6vKyz6qHIWN34sN1HtD86dS0v/Huy4sqHqgm4WPQLtQvi9M8kzW3MHzl0raZS6QUZyeYeHh95ufk0QyXvpaJ/Cg6+myAbzpHdYxTBVJu0W2JEEUt50ApF6vzNZv21iB24tElhNNYejB5+TDcyPmRFTlCoiGcp6bnTGhaGnPVy2CCyomxmjAKdnjj4xYPqX2/tz7xAhZKo0CSYq3h9+SNKsDp8J4zLg4ACInwzI3aMsxUqD2E87Z2xp+hA6c4R7XMgNAHkM8cvjcHT57H1xntD/xTLR0jjQAKBB+teL0mGGGowBL5UDf/TTq6rKGv0uyLZHop96tqc8rye1IXuc/WBhJTzXsPmpt3SUBS0w9izYUnINCZMHDgPp8z6OUEKUIzwbxBVPHTjKJNTKRP8h0xT6VHNS9oc8WCx037M7u3Swpujs1jA4CSjIlCTwG5Lb8AgDGTufVXrV8cT3zs18ExLekZ0bQsItEyIsM6HqJNEaI58sw1+UPgP5P3pgw+/PxkjgPxEDsSiQX+kHVklvlifJTnv3Wxc+cI/qH9646z/RIL/giCfUM+IPit8v/pcGHGnPN+e6+etALPLxLhmsL6I2p36V5QLLH71LGWCFWSxaWMqOu3rNrifFq98SRjUJge2/4XtNaNOHcxIQOTNeQC48LBYyI8eUxhjSfwcg/qlU/xHoL5TI3zB7Hj8Ttad9dyb0cc0I6xMS3BaewqmB9XcTHeapi5JYssD51Su2yyEsC5R/fAJ7No8Jy3Gu2lp4EHoLS42BQOIBC3RYtr/tBwaB6fIAPJlT0jiwsRkXhMvBXoacus66vnFKDJ93onsQfuxfYxOAQHk77u6w+F2xmbPJVQKV5dVsEZx0vQbzNNKqL3viJZG8suxn51FObJ6sYFyod0QlIGDp/d5XffWWJXd9J6G1NatIKyySpOAbEdkSFMt1/JSkjwY7n9A1lB4q2zueBPZ7dNeEbTahHpOE8zC2lfbaajPrwIlbhOR5nCTnCjeu9K74M7F+vtN3QU3u66KYV0X7Xj+zB/0RasyQsQ9GGyb3eKztbNOqugwIWVpKFs1QZL3vAF5ebyYTmeaPea+5/Kx17nPU0ZKc/16qMXhMq7lPqO+jJSwSz453JHVQ/ura+ty1LwItsS8Y5dVXM+r417+QX/OX09n/nsl//t+8tmzwh2FJ3un7Q+HCv2c2N4FzVgOF+anTTNC3aFLq7LMuM4lNT0qaQwm8Dq6TlZTbKdpBlS0geKav4rVjkWWqQsWT1mFbB3swqb4tox2rZyvWApJH6+TL5dVN1FlFILgRYjLaYPNQ4c/bxqzFGiBP3rcwjsNorfEzdAx8RbQGae3wWY/GXu/lODNW6wOTV35x5zu57TdK/JTge4ni6Nn2yPiUHNZ1cq4uaz/tyJ4WYXBfplhNol3YgncyeIV2jC0t3T+0wI/8MbffKZPb8tR4qCNpMYg81l5nMnfZ2cqEpzDVlcvdulP0ZHiNu+4Yi6pscRJ1L7T66R/1RrXMTlkYWoYC0lJ38m5CmFwWUd3cqFT49ysfuvmCR01zaBhHrbIpscAEEIxnsk1GnSi7WKf3haWBiFTiuuVM0SVmED5fL5WXeBR4gK4rbiTvnOg/fRwNv6QhOLhk6u2D5jshpC+0EHaOqCvIzcJzFu+TBuRKsIoXQvyKWadQF55un3rBGpFzkIRVNQOWC8mVRtORueQXg3wt2PMTvJDv7algBr4VU8SYcbop7LM4ogGjKd/D9kaobo6sBdT2fgwvia4n1VHtxvfv4Q6NWoUy4tyMgDQI1oZPDtwI37UuRm3fgpzta56kmrbIWyvX5lLAM5hce2CpcdHAZe/sFmDujnwuOeWGLR7leY7Cm5RjsfzIVjNv/ZYcJekbLOwm4tYbayhdtJxJC8yYNNCHNujVjKoIkO+qudhnhgUI9L6nH1dM1Yr3927F5BcLQ7XsWl+4wqfG+tpY1C/FpsjKu2ZpVQFNR2iCeNyvFf1u+LNa7UGygsWLu/5YlKrF9rusyRVze5PsAirp/BkJXpt75V9gQuml4PsImT0Zft2jq9myy96XyJydg56lVvysMQHJSSyCYSocoVfoYDOKNSOLPkPN6RdirW+Q+Uk2q71XQYdaXwdfLZWPbPHVEMnztVqa7D1Wxordw6Sovd4Yog8M4RmWRt4pa/BcOGSyPfw5h1e6r5I8Sg1SL4nAsnGS2I2YJovbtNyv2invDT746iRGaa2+X7TokxKjrHiL+ETZzxDn4/KRywqaH26Jw73PrGsmeQJZiQ+TLYk8+w25tClZLCJ88Z41TicbTSBFJMveQJvt0K18fQsEVoSH8c7bQfnexJHwdF2qM6LVncNSm2Cb0XNemIa3OO5lK14xUqTHOe9Iz1hfMM7J29cp2vy7neJeB4OuH6Pf7Sj1FnFojTv78aeNKRN7FLUejfyoAwiz3PjuZRufVZMzcjFIiQunya1OyKCwVcx9hPZe1pdYB98EWyu8pz6Jzc19U1is/iiQat4Yx5eE7vltQ5zdlXW6neL91iiCaxTy4RCiFcHYzfOHKneO63nTMGfKddWZSd/UAMGrlGz8yuzJZZgSfeqIYxhIyYpZ4uDG3FtnXKEeqOYu2M3C9JzmWTL8cmFtUjcPp66I2bwXWjqnfQjFeb8IOUcs3Q7kxDeY6zsxTXsc97FD5YDLPo/MPSjVhTIluIESrVffQ+j6EdePgmc/FdrE0dTJpdKIg7Xx76WI9GBgU0XR0/zkUnqtt513bfV1b/dDQgX8XkuIDicDE+r703A7MohEu7ML6/xvIPZilpOZuJHbO0avmsGXffdhMSPjiODfRtH/O27+B3avn9k="""
    token_see = '8845eae1bc0dfa069aec58a224623814f13ceb4794877a100e14a5bb1649681d'
    token_tiger = '94e9f4f87b0732e6a48c66f9d51d0d62157f993155f2976f1533282645e4b0de'
    svr = NotifyServer()
    svr.start_apns(pem_data, config.cfg_path, sandbox=0)
    svr.send_apns_msg(token_see, u'返屋企啦1111!')
#    svr.send_apns_msg(token_see, u'返屋企啦22222!')
    sleep(20)

def execute():
    CMDS = {}
    for name, value in globals().iteritems():
        if name.startswith('_cmd_'):
            CMDS[name[5:]] = value

    if len(sys.argv) == 1:
        rs = []
        for k,v in CMDS.iteritems():
            rs.append('  %s - %s' % (k, v.func_doc.decode('utf8') if v.func_doc else v.func_name))
        log('\n'.join(rs))
        return
    app = sys.argv[1]
    if app in CMDS:
        CMDS[app](*sys.argv[1:])
    else:
        log("tool(%s) no found" % app)



def main():
    execute()

if __name__ == '__main__':
    main()

