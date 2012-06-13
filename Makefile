ifeq ($(shell uname -o),Cygwin)
win_path = $(shell cygpath -ma $(1))
uri = $(shell echo file:///$(call win_path,$(1))  | perl -pe 's/ /%20/g')
else
uri = $(1)
endif

lc = $(shell echo $(1) | tr '[:upper:]' '[:lower:]')

SAXON := saxon
DEBUG := 1
DEBUGDIR = debug

default: usage

%.idml.HUB %.idml.INDEXTERMS %.idml.TAGGED:	%.idml Makefile xslt/*.xsl xslt/modes/*.xsl
	mkdir -p "$<.tmp"
	unzip -u -o -d "$<.tmp" "$<"
	$(SAXON) \
      $(SAXONOPTS) \
      -xsl:xslt/idml2xml.xsl \
      -it:$(call lc,$(subst .,,$(suffix $@))) \
      src-dir-uri=$(call uri,"$<").tmp \
      split=$(SPLIT) \
      debug=$(DEBUG) \
      debugdir=$(call uri,$(DEBUGDIR)) \
      > "$@"

usage:
	@echo ""
	@echo "This is idml2xml, an IDML to XML converter"
	@echo "written by Philipp Glatza and Gerrit Imsieke"
	@echo "(C) 2010--2012 le-tex publishing services GmbH"
	@echo "All rights reserved"
	@echo ""
	@echo "Usage:"
	@echo "  Place a file xyz.idml anywhere, then run 'make path_to/xyz.idml.XYZ',"
	@echo "    where XYZ is one of TAGGED, HUB, or INDEXTERMS."
	@echo "  Optional parameter SPLIT for the .TAGGED target: comma-separated list of tags that"
	@echo "    should be split if they cross actual InDesign paragraph boundaries (e.g., SPLIT=span,p)."
	@echo "  Optional parameter DEBUG=1 (which is default) will cause debugging info to be dumped"
	@echo "    into DEBUGDIR (which is `realpath $(DEBUGDIR)` by default)."
	@echo "    Use DEBUG=0 to switch off debugging."
	@echo "  If you want to invoke this from your project directory (and also want to have"
	@echo "    the debug files there), use something like:"
	@echo "  > make -C $(CURDIR) \`realpath relpath_to/xyz.idml.HUB\` DEBUGDIR=\`pwd\`/debug"
	@echo "  Example for processing 37 chapters from bash:"
	@echo "  > for c in $$(seq -f '%02g' 37); do make -C Dev/idml2xml/  /path/to/IDML/$${c}_Chap.idml.HUB; done"
	@echo ""
	@echo "Prerequisites:"
	@echo "  Saxon 9.3 or newer, expected as a 'saxon' script in the path (override this with SAXON=...)"
	@echo ""