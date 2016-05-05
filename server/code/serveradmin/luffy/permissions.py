# from flask.ext.principal import RoleNeed, Permission
from tprincipal import RoleNeed, Permission
other = Permission(RoleNeed('other'))
administrator = Permission(RoleNeed('admin'))
moderator = Permission(RoleNeed('moderator'))
auth = Permission(RoleNeed('authenticated'))
null = Permission(RoleNeed('null'))