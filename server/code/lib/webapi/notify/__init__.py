#!/usr/bin/env python
from os.path import join
from binascii import unhexlify

from corelib import log

class NotifyServer(object):
    """  """
    def start_apns(self, pem_data, pem_path, sandbox, **sslargs):
        """ start apns """
        import apns
        if self.apns_started:
            return

        import zlib, base64
        pem_data = zlib.decompress(base64.b64decode(pem_data))
        self.apns_pem = fn = join(pem_path, 'apns.pem')
        log.debug(self.apns_pem)
        with open(fn, 'wb') as f:
            f.write(pem_data)
        self.apns = apns.NotificationService(sandbox=sandbox,
                certfile=fn, **sslargs)
        self.apns.start()

    def stop_apns(self):
        if not self.apns_started:
            return
        self.apns.stop()
        del self.apns

    @property
    def apns_started(self):
        return getattr(self, 'apns', None) is not None

    def send_apns_msg(self, token, alert, sound='default', **kw):
        from apns import NotificationMessage
        if len(token) == 64:
            token = unhexlify(token)
        obj = NotificationMessage(token, alert=alert,
                sound=sound, **kw)
        self.apns.send(obj)


