from odoo.tools import config

config.parse_config(['-c', '/etc/odoo/odoo.conf'])

try:
    __import__('odoo.addons.hg_base')
    from odoo import celery
except ImportError:
    pass
