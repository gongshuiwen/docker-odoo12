#!/usr/bin/env python3
import logging
from os.path import join as joinpath, isdir

from celery import Celery

import odoo
from odoo.modules import get_modules, get_module_path

# set server timezone in UTC before time module imported
__import__('os').environ['TZ'] = 'UTC'
_logger = logging.getLogger('odoo.stater')


def initialize_celery():
    # Initialize Odoo config
    odoo.tools.config.parse_config(['-c', '/etc/odoo/odoo.conf'])
    _logger.info("Initialized Odoo Config.")

    # Create celery instance
    rabbit_host = odoo.tools.config.get("rabbit_host", "mq")
    rabbit_port = odoo.tools.config.get("rabbit_port", "5672")
    rabbit_user = odoo.tools.config.get("rabbit_user", "guest")
    rabbit_pass = odoo.tools.config.get("rabbit_password", "guest")
    broker = "pyamqp://{}:{}@{}:{}//".format(rabbit_user, rabbit_pass, rabbit_host, rabbit_port)
    app = odoo.celery = Celery('odoo', broker=broker)
    _logger.info("Celery instance created. (broker=pyamqp://{}@{}:{}//)".format(rabbit_user, rabbit_host, rabbit_port))

    # Import all addons' sub-module named 'tasks'
    _logger.info("Importing tasks from Odoo...")
    for module in get_modules():
        if isdir(joinpath(get_module_path(module), 'tasks')):
            __import__('odoo.addons.' + module + '.tasks')
    _logger.info("%s tasks imported from Odoo." % len([t for t in app.tasks.keys() if t.startswith('odoo')]))

    return app


celery = initialize_celery()


if __name__ == "__main__":
    odoo.cli.main()
