# coding=utf-8

import os

from ..__init__ import _
from . import interface
from ..generics import encoding
from .config import config
from .pkg_processors import sgmlxml
from .pkg_processors import pkg_processors


def call_make_packages(args, version):
    script, xml_path, acron, INTERATIVE, GENERATE_PMC = read_inputs(args)
    xml_list_or_pkg = None
    if any([xml_path, acron]):
        result = validate_inputs(script, xml_path)
        if result:
            stage, xml_list_or_pkg = get_inputs(result, acron)

    if xml_list_or_pkg is None:
        if INTERATIVE is True:
            display_form("xpm")
    else:
        execute(INTERATIVE, stage, xml_list_or_pkg, GENERATE_PMC)


def get_inputs(result, acron):
    sgm_xml, xml_list = result
    if sgm_xml:
        sgmxml2xml = sgmlxml.SGMLXML2SPSXML(sgm_xml, acron)
        pkg = sgmxml2xml.pack()
        stage = 'xml'
    else:
        stage = 'xpm'
    return stage, xml_list or pkg


def display_form(stage):
    interface.display_form(stage == 'xc', None, call_make_package_from_form)


def execute(INTERATIVE, stage, xml_list_or_pkg, GENERATE_PMC):
    print(_('Making package') + '...')
    configuration = config.Configuration()
    proc = pkg_processors.PkgProcessor(configuration, INTERATIVE, stage)
    pkg = xml_list_or_pkg
    if stage == "xpm":
        pkg = proc.receive_package(xml_list_or_pkg)
        print('...'*3)

    proc.make_package(pkg, GENERATE_PMC)
    print('...'*3)


def call_make_package_from_form(xml_path, GENERATE_PMC=False):
    xml_list = [os.join(xml_path, item)
                for item in os.listdir(xml_path) if item.endswith('.xml')]
    execute(True, "xpm", xml_list, GENERATE_PMC)
    return 'done', 'blue'


def read_inputs(args):
    INTERATIVE = True
    GENERATE_PMC = False
    args = encoding.fix_args(args)
    script = args[0]
    path = None
    acron = None

    items = []
    for item in args:
        if item == '-auto':
            INTERATIVE = False
        elif item == '-pmc':
            GENERATE_PMC = True
        else:
            items.append(item)

    if len(items) == 3:
        script, path, acron = items
    elif len(items) == 2:
        script, path = items
    if path is not None:
        path = path.replace('\\', '/')
    return (script, path, acron, INTERATIVE, GENERATE_PMC)


def validate_inputs(script, xml_path):
    sgm_xml, xml_list, errors = evaluate_xml_path(xml_path)
    if len(errors) > 0:
        messages = []
        messages.append('\n===== ATTENTION =====\n')
        messages.append('ERROR: ' + _('Incorrect parameters'))
        messages.append('\n' + _('Usage') + ':')
        messages.append('python ' + script + ' <xml_src> [-auto]')
        messages.append(_('where') + ':')
        messages.append('  <xml_src> = ' + _('XML filename or path which contains XML files'))
        messages.append('  [-auto]' + _('optional parameter to omit report'))
        messages.append('\n'.join(errors))
        encoding.display_message('\n'.join(messages))
    else:
        return sgm_xml, xml_list


def evaluate_xml_path(xml_path):
    errors = []
    sgm_xml = None
    xml_list = None

    if xml_path is None:
        errors.append(_('Missing XML location. '))
    else:
        if os.path.isfile(xml_path):
            if xml_path.endswith('.sgm.xml'):
                sgm_xml = xml_path
            elif xml_path.endswith('.xml'):
                xml_list = [xml_path]
            else:
                errors.append(_('Invalid file. XML file required. '))
        elif os.path.isdir(xml_path):
            xml_list = [xml_path + '/' + item for item in os.listdir(xml_path) if item.endswith('.xml')]

            if len(xml_list) == 0:
                errors.append(_('Invalid folder. Folder must have XML files. '))
        else:
            errors.append(_('Missing XML location. '))
    return sgm_xml, xml_list, errors
