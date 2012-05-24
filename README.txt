# Makefile invocation (XSLT-only pipeline):
make -B sample/testdokument.idml.HUB
 

# XProc invocation:

# Sample checks; patch findings as processing instructions into the converted hub:
calabash/calabash.sh -o result=- xpl/test.xpl idmlfile=sample/testdokument.idml conffile=../sch/sample-conf.xml
# Other possible output ports: 
#   svrl (all schematron reports), 
#   xsl (for patching hub), 
#   xpl (generated appl-schematrons pipeline)

# Plain idml to hub conversion:
calabash/calabash.sh xpl/idml2xml.xpl idmlfile=sample/testdokument.idml

# Write indented debug output of the XML-Hubformat-cleanup-paras-and-br step to out.xml, discard std output:
calabash/calabash.sh -o XML-Hubformat-cleanup-paras-and-br=out.xml xpl/idml2xml.xpl idmlfile=sample/testdokument.idml > /dev/null


