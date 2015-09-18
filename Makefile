PREFIX := local
BINDIR := $(abspath $(PREFIX)/bin)
SRCDIR := src

JQ_DIR := jq
MASSCAN_DIR := masscan

DEPS := jq masscan
SRC := main.sh scan.sh probe.sh filter.pl

.PHONY: all boot clean distclean scan

all: $(BINDIR) $(addprefix $(BINDIR)/, $(DEPS) $(SRC))

boot:
	git submodule update --init $(JQ_DIR)
	git submodule update --init $(MASSCAN_DIR)

clean:
	-$(MAKE) -C $(JQ_DIR) clean
	-$(MAKE) -C $(MASSCAN_DIR) clean

distclean: clean
	-$(MAKE) -C $(JQ_DIR) distclean
	-rm -rf $(PREFIX)

scan: all
	env PATH="$(BINDIR):$$PATH" sudo bash '$(BINDIR)/main.sh'

$(BINDIR):
	mkdir -p $@

$(BINDIR)/%.sh: $(SRCDIR)/%.sh $(BINDIR)
	cp $< $@

$(BINDIR)/%.pl: $(SRCDIR)/%.pl $(BINDIR)
	cp $< $@

$(JQ_DIR)/configure:
	cd $(JQ_DIR); autoreconf -i;

$(JQ_DIR)/Makefile: $(JQ_DIR)/configure
	# disable-maintainer-mode to build without bison & flex
	cd $(JQ_DIR); ./configure --disable-maintainer-mode --prefix='$(abspath $(PREFIX))'


$(BINDIR)/jq: $(BINDIR) $(JQ_DIR)/Makefile
	$(MAKE) -C $(JQ_DIR)
	$(MAKE) -C $(JQ_DIR) install

$(BINDIR)/masscan: $(BINDIR)
	$(MAKE) -C $(MASSCAN_DIR)
	cp $(MASSCAN_DIR)/bin/masscan $@
