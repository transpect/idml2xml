# Makefile invocation (XSLT-only pipeline):
make -B sample/testdokument.idml.HUB
 

# XProc invocation:

calabash/calabash.sh xpl/idml2xml.xpl idmlfile=sample/testdokument.idml

# Write indented debug output of the XML-Hubformat-cleanup-paras-and-br step to out.xml, discard std output:
calabash/calabash.sh -o XML-Hubformat-cleanup-paras-and-br=out.xml xpl/idml2xml.xpl idmlfile=sample/testdokument.idml > /dev/null

# Apply sample schematron:
calabash/calabash.sh -o svrl=- xpl/schematron-test.xpl idmlfile=sample/testdokument.idml

