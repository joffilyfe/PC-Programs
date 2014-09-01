import os
import shutil

from modules import xml_utils
from modules import java_xml_utils

PMC_PATH = './../../pmc'
XSL_SGML2XML = {}
XSL_SGML2XML['v3.0'] = PMC_PATH + '/v3.0/xsl/sgml2xml/sgml2xml.xsl'
XSL_SGML2XML['j1.0'] = PMC_PATH + '/j1.0/xsl/sgml2xml/sgml2xml.xsl'
XSL_SGML2XML_default = XSL_SGML2XML['j1.0']


def xsl_sgml2xml(version):
    return XSL_SGML2XML.get(version, XSL_SGML2XML_default)


class XMLContent(object):

    def __init__(self, content):
        self.content = content

    def fix_dtd_location(self, dtd_filename, doctype):
        if not dtd_filename in self.content:
            if not '<?xml ' in self.content:
                self.content = '<?xml version="1.0" encoding="utf-8"?>\n' + self.content

            if '<!DOCTYPE' in self.content:
                old_doctype = self.content[self.content.find('<!DOCTYPE'):]
                old_doctype = old_doctype[0:old_doctype.find('>')+1]
                self.content = self.content.replace(old_doctype, '')
            if not '<!DOCTYPE' in self.content:
                self.content = self.content.replace('\n<article ', doctype.replace('{DTD_FILENAME}', dtd_filename) + '\n<article ')

    def fix(self):
        self.content = self.content[0:self.content.rfind('>')+1]
        self.content = self.content[self.content.find('<'):]
        self.content = self.content.replace(' '*2, ' '*1)
        if xml_utils.is_xml_well_formed(self.content) is None:
            self._fix_style_tags()
        if xml_utils.is_xml_well_formed(self.content) is None:
            self._fix_open_close()

    def _fix_open_close(self):
        changes = []
        parts = self.content.split('>')
        for s in parts:
            if '<' in s:
                if not '</' in s and not '<!--' in s and not '<?' in s:

                    s = s[s.find('<')+1:]
                    if ' ' in s and not '=' in s:
                        test = s[s.find('<')+1:]
                        changes.append(test)
        for change in changes:
            print(change)
            self.content = self.content.replace('<' + test + '>', '[' + test + ']')

    def _fix_style_tags(self):
        rcontent = self.content
        tags = ['italic', 'bold', 'sub', 'sup']
        tag_list = []
        for tag in tags:
            rcontent = rcontent.replace('<' + tag.upper() + '>', '<' + tag + '>')
            rcontent = rcontent.replace('</' + tag.upper() + '>', '</' + tag + '>')
            tag_list.append('<' + tag + '>')
            tag_list.append('</' + tag + '>')
            rcontent = rcontent.replace('<' + tag + '>',  'BREAKBEGINCONSERTA<' + tag + '>BREAKBEGINCONSERTA').replace('</' + tag + '>', 'BREAKBEGINCONSERTA</' + tag + '>BREAKBEGINCONSERTA')
        if self.content != rcontent:
            parts = rcontent.split('BREAKBEGINCONSERTA')
            self.content = self._fix_problem(tag_list, parts)
        for tag in tags:
            self.content = self.content.replace('</' + tag + '><' + tag + '>', '')

    def _fix_problem(self, tag_list, parts):
        expected_close_tags = []
        ign_list = []
        debug = False
        k = 0
        for part in parts:
            if part in tag_list:
                tag = part
                if debug:
                    print('\ncurrent:' + tag)
                if tag.startswith('</'):
                    if debug:
                        print('expected')
                        print(expected_close_tags)
                        print('ign_list')
                        print(ign_list)
                    if tag in ign_list:
                        if debug:
                            print('remove from ignore')
                        ign_list.remove(tag)
                        parts[k] = ''
                    else:
                        matched = False
                        if len(expected_close_tags) > 0:
                            matched = (expected_close_tags[-1] == tag)
                            if not matched:
                                if debug:
                                    print('not matched')
                                while not matched and len(expected_close_tags) > 0:
                                    ign_list.append(expected_close_tags[-1])
                                    parts[k-1] += expected_close_tags[-1]
                                    del expected_close_tags[-1]
                                    matched = (expected_close_tags[-1] == tag)
                                if debug:
                                    print('...expected')
                                    print(expected_close_tags)
                                    print('...ign_list')
                                    print(ign_list)

                            if matched:
                                del expected_close_tags[-1]
                else:
                    expected_close_tags.append(tag.replace('<', '</'))
            k += 1
        return ''.join(parts)


def rename_embedded_img_href(content, xml_name, new_href_list):
    content = content.replace('<graphic href="?', '--FIXHREF--<graphic href="?')
    items = content.split('--FIXHREF--')
    new = ''
    i = 0
    for item in items:
        if item.startswith('<graphic href="?'):
            s = item[item.find('?'):]
            new += '<graphic href="' + xml_name + new_href_list[i] + s[s.find('"'):]
            i += 1
        else:
            new += item
    return new


def html_img_src(html_content):
    #[graphic href=&quot;?a20_115&quot;]</span><img border=0 width=508 height=314
    #src="a20_115.temp_arquivos/image001.jpg"><span style='color:#33CCCC'>[/graphic]
    html_content = html_content.replace('[graphic href="?', '[graphic href="?' + '"--FIXHREF--FIXHREF')
    items = [item for item in html_content.split('--FIXHREF--') if item.startswith('FIXHREF')]
    img_src = []
    for item in items:
        if ' src="' in item:
            item = item[item.find(' src="') + len(' src="')]
            item = item[0:item.find('"')]
            item = item[item.find('/') + 1:]
            if len(item) > 0:
                img_src.append(item)
    return img_src


def extract_embedded_images(xml_name, content, html_filename, dest_path):
    if content.find('href="?' + xml_name):
        html_content = open(html_filename, 'r').read()
        embedded_img_files = html_img_src(html_content)
        embedded_img_path = os.path.dirname(html_filename)
        content = rename_embedded_img_href(content, xml_name, embedded_img_files)
        for item in embedded_img_files:
            if os.path.isfile(embedded_img_path + '/' + item):
                shutil.copyfile(embedded_img_path + '/' + item, dest_path + '/' + xml_name + item)
    return content


def normalize_sgmlxml(xml_name, content, src_path, version, html_filename):
    content = extract_embedded_images(xml_name, content, html_filename, src_path)
    if not xml_utils.is_xml_well_formed(content):
        content = fix_xml(content)
    if xml_utils.is_xml_well_formed(content) is not None:
        content = java_xml_utils.xml_content_transform(content, xsl_sgml2xml(version))
    return content


def fix_xml(content):
    xml_fix = XMLContent(content)
    xml_fix.fix()
    if not xml_fix.content == content:
        content = xml_fix.content
    return content