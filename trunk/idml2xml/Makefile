IDML2XML_MAKEFILEDIR = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(shell uname -o),Cygwin)
win_path = $(shell cygpath -ma $(1))
uri = $(shell echo file:///$(call win_path,$(1))  | perl -pe 's/ /%20/g')
else
uri = $(shell echo file://$(abspath $(1))  | perl -pe 's/ /%20/g')
endif

SAXON := saxon
DEBUG := 1
DEBUGDIR = "$<.tmp/debug"

default: idml2xml_usage

%.hub.xml %.indexterms.xml %.tagged.xml:	%.idml $(IDML2XML_MAKEFILEDIR)/Makefile $(wildcard $(IDML2XML_MAKEFILEDIR)/xslt/*.xsl) $(wildcard $(IDML2XML_MAKEFILEDIR)/xslt/modes/*.xsl)
	umask 002; mkdir -p "$<.tmp" && unzip -u -o -q -d "$<.tmp" "$<"
	umask 002; $(SAXON) \
      $(SAXONOPTS) \
      -xsl:$(call uri,$(IDML2XML_MAKEFILEDIR)/xslt/idml2xml.xsl) \
      -it:$(subst .,,$(suffix $(basename $@))) \
      hub-other-elementnames-whitelist=$(HUB-OTHER-ELNAMES-WHITELIST) \
      src-dir-uri=$(call uri,"$<").tmp \
      split=$(SPLIT) \
      debug=$(DEBUG) \
      debugdir=$(call uri,$(DEBUGDIR)) \
      > "$@"
ifeq ($(DEBUG),0)
	-@rm -rf $(DEBUGDIR) && rm -rf "$<.tmp"
endif

idml2xml_usage:
	@echo ""
	@echo "This is idml2xml, an IDML to XML converter"
	@echo "written by Philipp Glatza and Gerrit Imsieke"
	@echo "(C) 2010--2012 le-tex publishing services GmbH"
	@echo "All rights reserved"
	@echo ""
	@echo "Usage:"
	@echo "  Place a file xyz.idml anywhere, then run 'make -f $(IDML2XML_MAKEFILEDIR)/Makefile path/to/xyz.targetfmt.xml',"
	@echo "    where targetfmt is one of tagged, hub, or indexterms. Use make's -C option (instead of the -f option)"
	@echo "    only if the file name contains an absolute directory."
	@echo "  Optional parameter SPLIT for the .TAGGED target: comma-separated list of tags that"
	@echo "    should be split if they cross actual InDesign paragraph boundaries (e.g., SPLIT=span,p)."
	@echo "  Optional parameter DEBUG=1 (which is default) will cause debugging info to be dumped"
	@echo "    into DEBUGDIR (which is `realpath $(DEBUGDIR)` by default)."
	@echo "    Use DEBUG=0 to switch off debugging."
	@echo "  Example for processing 37 chapters from bash:"
	@echo '  > for c in $$(seq -f '%02g' 37); do make -f $(IDML2XML_MAKEFILEDIR)Makefile path/to/IDML/$${c}_Chap.idml.HUB; done'
	@echo ""
	@echo "Prerequisites:"
	@echo "  Saxon 9.3 or newer, expected as a 'saxon' script in the path (override this with SAXON=...)"
	@echo ""
