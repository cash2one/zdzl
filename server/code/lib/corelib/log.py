#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os, sys
import traceback
import types
import locale
locale_encode = locale.getdefaultlocale()[1]
if locale_encode is None:
    locale_encode = 'UTF-8'

import logging
from logging import (DEBUG, INFO, WARNING, ERROR, FATAL, NOTSET,
        debug, info, warn, warning, error, exception,
      getLogger, StreamHandler, handlers, config)

for n in logging.__all__:
    globals()[n] = getattr(logging, n)

simpleformat = '[%(asctime)s]p%(process)d{%(module)s:%(funcName)s:%(lineno)d}%(levelname)s-%(message)s'
shortformat = '[%(asctime)s]p%(process)d{%(module)s:%(lineno)d}%(levelname)s-%(message)s'
shortdatefmt = '%m-%d %H:%M:%S'
#StreamHandlerEx fix to support domain mode
##class StreamHandlerEx(StreamHandler):
##    """
##    A handler class which writes logging records, appropriately formatted,
##    to a stream. Note that this class does not close the stream, as
##    sys.stdout or sys.stderr may be used.
##    """
##    def __init__(self, strm=None):
##        StreamHandler.__init__(self, strm)
##        self.stoped = 0
##
##    def flush(self):
##        """
##        Flushes the stream.
##        """
##        self.stream.flush()

def _StreamHandler_emit(self, record):
    if getattr(self, 'stoped', False): return
    try:
        msg = self.format(record)
        fs = "%s\n"
        if not hasattr(types, "UnicodeType"): #if no unicode support...
            self.stream.write(fs % msg)
        else:
            if isinstance(msg, unicode):
                if self.stream in [sys.stderr, sys.stdout]:
                    self.stream.write(fs % msg.encode(locale_encode))
                else:
                    self.stream.write(fs % msg.encode('utf-8'))
            else:
                try:
                    self.stream.write(fs % msg)
                except UnicodeError:
                    self.stream.write(fs % repr(msg))
        self.flush()
    except (KeyboardInterrupt, SystemExit):
        raise
    except IOError:
        self.stoped = 1
        #self.close()
    except:
        log_except('args=(%s)', record.args)
        #self.handleError(record)

def _StreamHandler_wrap_init(init_func):
    def _wrap_init(self, *args, **kw):
        init_func(self, *args, **kw)
        self.stoped = 0
    return _wrap_init
logging.StreamHandler.__init__ = _StreamHandler_wrap_init(logging.StreamHandler.__init__)
logging.StreamHandler.emit = _StreamHandler_emit

try:
    import zmq____
    class ZMQPUBHandler(logging.Handler):
        def __init__(self, host, port):
            logging.Handler.__init__(self)
            ctx = zmq.Context(1,1)
            self.sock = ctx.socket(zmq.PUB)
            self.sock.bind('tcp://%s:%s' %(host, port))

        def emit(self, record):
            """
            Emit a record.

            If a formatter is specified, it is used to format the record.
            The record is then written to the stream with a trailing newline
            [N.B. this may be removed depending on feedback]. If exception
            information is present, it is formatted using
            traceback.print_exception and appended to the stream.
            """
            try:
                msg = self.format(record)
                fs = "%s\n"
                if not hasattr(types, "UnicodeType"): #if no unicode support...
                    self.sock.send(fs % msg, zmq.NOBLOCK)
                else:
                    try:
                        self.sock.send(fs % msg, zmq.NOBLOCK)
                    except UnicodeError:
                        self.sock.send(fs % msg.encode("UTF-8"), zmq.NOBLOCK)
            except (KeyboardInterrupt, SystemExit):
                raise
            except:
                self.handleError(record)
except ImportError:
    class ZMQPUBHandler(logging.Handler):
        def __init__(self, host, port):
            pass
        def emit(self, record):
            pass
handlers.ZMQPUBHandler = StreamHandler

class LogRecordEx(logging.LogRecord):
    def __init__(self, name, level, pathname, lineno,
                       msg, args, exc_info, func=None):
        if sys.platform <> 'win32':
            pathname = pathname.replace('\\', '/')
        logging.LogRecord.__init__(self, name, level, pathname, lineno,
                                               msg, args, exc_info, func)


class MyLogger(logging.Logger):
    def log(self, *args, **kw):
        self.debug("\n" + str(args) + str(kw) + "\n")

    def log_except(self, *args):
        log_except(*args, logger=self)

    def log_stack(self, msg='', level=WARNING):
        log_stack(msg=msg, level=level, logger=self)

    write = logging.Logger.debug
    write_info = logging.Logger.info
    write_error= logging.Logger.exception

    def close(self):
        for hd in self.handlers:
            hd.close()
        self.disabled = 1

    def makeRecord(self, name, level, fn, lno, msg, args, exc_info, func=None, extra=None):
        rv = LogRecordEx(name, level, fn, lno, msg, args, exc_info, func)
        if extra is not None:
            for key in extra:
                if (key in ["message", "asctime"]) or (key in rv.__dict__):
                    raise KeyError("Attempt to overwrite %r in LogRecord" % key)
                rv.__dict__[key] = extra[key]
        return rv
logging.setLoggerClass(MyLogger)

def log_except(*args, **kw):
    logger = kw.get('logger', None)
    better = kw.pop('_better', 0)
    if not logger:
        logger = logging.root

    if not len(args):
        msg = None
    elif len(args) == 1:
        msg = args[0]
        args = []
    else:
        msg = args[0]
        args = args[1:]
    lines = ['Traceback (most recent call last):\n']
    if better:
        import better_exchook
        better_exchook.better_exchook(*sys.exc_info(),
                output=lambda s:lines.append('%s\n' % s))
    else:
        ei = sys.exc_info()
        st = traceback.extract_stack(f=ei[2].tb_frame.f_back)
        et = traceback.extract_tb(ei[2])
        lines.extend(traceback.format_list(st))
        lines.append('  ****** Traceback ******  \n')
        lines.extend(traceback.format_list(et))
        lines.extend(traceback.format_exception_only(ei[0], ei[1]))
    exc = ''.join(lines)
    if msg:
        args = list(args)
        args.append(exc)
        logger.error(msg + ':\n%s', *args)
    else:
        logger.error(exc)


def log_stack(msg='', level=WARNING, logger=None):
    if not logger:
        logger = logging.root
    msg = 'log_stack:%s\n%s' % (msg, ''.join(traceback.format_stack()))
    if level == WARNING:
        logger.warning(msg)
    elif level == DEBUG:
        logger.debug(msg)
    elif level == INFO:
        logger.info(msg)
    elif level == ERROR:
        logger.error(msg)


def logmsg(obj):
    func = logmsg
    result = ''
    if isinstance(obj, str):
        return obj

    elif isinstance(obj, dict):
        for k,v in obj.items():
            k8 = func(k)
            v8 = func(v)
            result += '%s:%s, ' %(k8, v8)
        return '{%s}' % result
    elif isinstance(obj, list):
        for v in obj:
            result += '%s, ' % func(v)
        return '[%s]' % result
    elif isinstance(obj, tuple):
        for v in obj:
            result += '%s, ' % func(v)
        return '(%s)' % result
    else:
        return str(obj)

def write(msg):
    info(msg)

##def replace_syslog(logger=None):
##    class MyFile(object):
##        def __init__(self, logfunc):
##            self.logfunc = logfunc
##        def encoding(self):
##            pass
##        def flush(self):
##            pass
##        def write(self, data):
##            self.logfunc(data)
##
##    if not logger:
##        logger = logging.root
##    sys.stderr = MyFile(logger.error)
##    sys.stdout = MyFile(logger.info)

def console_config(debug=True, log_file=None, format=shortformat, datefmt=shortdatefmt):
        level = DEBUG if debug else INFO
        while logging.root.handlers:
            logging.root.handlers.pop()
        logging.basicConfig(level=level,
                format=format,
                datefmt=datefmt,
                stream=sys.stdout,
                #filename= logFullName('app.log'), filemode='w'
                )
        if log_file:
            fmt = Formatter(format, datefmt)
            hdlr = FileHandler(log_file, 'a')
            hdlr.setFormatter(fmt)
            logging.root.addHandler(hdlr)


def main():
    pass

if __name__ == '__main__':
    main()
