#!/usr/bin/python

#------------------------------------------------------------------------------
#           Name: notches.py
#         Author: Ra Inta, 20160513
#  Last Modified: 20160514, R.I.
#
# A file to parse text files associated with known instrumental lines and
# create notches in an XML file (veto_bands.xml).
#
#------------------------------------------------------------------------------

import sys

try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET
try:
    from xml.etree.cElementTree import Element, SubElement, Comment, tostring
except ImportError:
    from xml.etree.ElementTree import Element, SubElement, Comment, tostring

def indent(elem, level=0):
    """This is a function to make the XML output pretty, with the right level
    of indentation"""
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

############################################################


def veto_xml(veto_root, freq, band, comment):
    vetoIdx = SubElement( veto_root, "veto_band")
    indent(vetoIdx, 2)
    vetoIdx.set('comment', 'notch (' + comment + ')' )
    vetoIdx_band = SubElement( vetoIdx, "band")
    vetoIdx_band.text = str(band)
    indent(vetoIdx_band, 3)
    vetoIdx_band = SubElement( vetoIdx, "freq")
    vetoIdx_band.text = str(freq)
    indent(vetoIdx_band, 3)
    return vetoIdx



# Read the veto_bands XMl file and create an array of tuples containing vetoed bands
with open('veto_bands.xml', 'r') as vetoFile:
    veto_tree = ET.parse( vetoFile )
    veto_root = veto_tree.getroot()

## Read in
#with open('search_setup.xml','r') as searchSetup:
#    setup_tree = ET.parse( searchSetup )
#    setup_root = setup_tree.getroot()

for IFO in ['H1', 'L1']:
    with open(sys.path[0] + '/notches_' + IFO + '.txt','r') as notchFile:
        for eachLine in notchFile.readlines():
            if eachLine[0] != '%':
                eachCol=eachLine.split()
                veto_comment = ""
                for commentIdx in eachCol[8:]:
                    veto_comment += commentIdx + ' '
                veto_comment += 'in ' + IFO
                f0 = float(eachCol[0])
                lBand = float(eachCol[5])
                rBand = float(eachCol[6])
                offset = float(eachCol[2])
                harmInitial = int(eachCol[3])
                harmFinal = int(eachCol[4])
                # Check for lines
                if eachCol[1] == '0':
                    veto_freq = f0 - lBand
                    veto_band = rBand + lBand
                    veto_xml(veto_root, veto_freq, veto_band, veto_comment)
                # Check for combs of fixed width
                elif eachCol[1] == '1':
                    for harmIdx in range( harmFinal - harmInitial ):
                        harm = harmIdx + harmInitial
                        veto_freq = offset + harm*f0 - lBand
                        veto_band = rBand + lBand
                        veto_xml(veto_root, veto_freq, veto_band, veto_comment)
                # Check for combs of scaled width
                elif eachCol[1] == '2':
                    for harmIdx in range( harmFinal - harmInitial ):
                        harm = harmIdx + harmInitial
                        veto_freq = offset + harm*(f0 - lBand)
                        veto_band = harm*(rBand + lBand)
                        veto_xml(veto_root, veto_freq, veto_band, veto_comment)
                else:
                    print("Warning! Couldn't read data. Is one of the notch files corrupted?")
                    break



#for search_params in setup_root.iter('search'):
#    search_band = float( search_params.find('band').text )
#    start_freq = float( search_params.find('freq').text )
#    Tspan = float( search_params.find('span_time').text )


veto_bands_xml = ET.ElementTree( veto_root )
#veto_bands_xml.append( veto_segments )
veto_bands_xml.write("veto_bands_py.xml", xml_declaration=True, encoding='UTF-8' )
