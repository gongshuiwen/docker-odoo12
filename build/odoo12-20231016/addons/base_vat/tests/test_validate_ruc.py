# Part of Odoo. See LICENSE file for full copyright and licensing details.

import logging
_logger = logging.getLogger(__name__)

from odoo.tests import common
from odoo.exceptions import ValidationError
try:
    from unittest.mock import patch
except ImportError:
    from mock import patch


class TestStructure(common.SingleTransactionCase):

    @classmethod
    def setUpClass(cls):
        def check_vies(vat_number):
            return {'valid': vat_number == 'BE0477472701'}

        super().setUpClass()
        cls.env.user.company_id.vat_check_vies = False
        cls._vies_check_func = check_vies

    def test_peru_ruc_format(self):
        """Only values that has the length of 11 will be checked as RUC, that's what we are proving. The second part
        will check for a valid ruc and there will be no problem at all.
        """
        partner = self.env['res.partner'].create({'name': "Dummy partner", 'country_id': self.env.ref('base.pe').id})

        with self.assertRaises(ValidationError):
            partner.vat = '11111111111'
        partner.vat = '20507822470'

    def test_parent_validation(self):
        """Test the validation with company and contact"""

        # set an invalid vat number
        self.env.user.company_id.vat_check_vies = False
        company = self.env["res.partner"].create({
            "name": "World Company",
            "country_id": self.env.ref("base.be").id,
            "vat": "ATU12345675",
            "company_type": "company",
        })
        contact = self.env["res.partner"].create({
            "name": "Sylvestre",
            "parent_id": company.id,
            "company_type": "person",
        })

        # reactivate it and correct the vat number
        with patch('odoo.addons.base_vat.models.res_partner.check_vies', type(self)._vies_check_func):
            self.env.user.company_id.vat_check_vies = True
            with self.assertRaises(ValidationError), self.env.cr.savepoint():
                company.vat = "BE0987654321"  # VIES refused, don't fallback on other check
            company.vat = "BE0477472701"

    def test_vat_syntactic_validation(self):
        """ Tests VAT validation (both successes and failures), with the different country
        detection cases possible.
        """
        # Disable VIES; syntactic verification is enough for this test case
        self.env.user.company_id.vat_check_vies = False

        test_partner =self.env['res.partner'].create({'name': "John Dex"})

        # VAT starting with country code: use the starting country code
        test_partner.write({'vat': 'BE0477472701', 'country_id': self.env.ref('base.fr').id})
        test_partner.write({'vat': 'BE0477472701', 'country_id': None})

        with self.assertRaises(ValidationError):
            test_partner.write({'vat': 'BE42', 'country_id': self.env.ref('base.fr').id})

        with self.assertRaises(ValidationError):
            test_partner.write({'vat': 'BE42', 'country_id': None})

        # No country code in VAT: use the partner's country
        test_partner.write({'vat': '0477472701', 'country_id': self.env.ref('base.be').id})

        with self.assertRaises(ValidationError):
            test_partner.write({'vat': '42', 'country_id': self.env.ref('base.be').id})

        # If no country can be guessed: VAT number should always be considered valid
        # (for technical reasons due to ORM and res.company making related fields towards res.partner for country_id and vat)
        test_partner.write({'vat': '0477472701', 'country_id': None})
