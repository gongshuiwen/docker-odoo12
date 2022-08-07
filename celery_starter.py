from celery import Celery

import odoo

odoo.tools.config.parse_config(['-c', '/etc/odoo/odoo.conf'])
celery = odoo.celery = Celery('odoo', broker=odoo.tools.config.get('celery_broker', 'pyamqp://guest@localhost//'))
