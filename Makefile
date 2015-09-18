PREFIX := local
BINDIR := $(abspath $(PREFIX)/bin)
SRCDIR := src

JQ_DIR := jq
MASSCAN_DIR := masscan

DEPS := $(BINDIR)/jq $(BINDIR)/masscan
SRC := main.sh scan.sh probe.sh filter.pl

.PHONY: all boot update clean distclean scan

all: $(DEPS) $(addprefix $(BINDIR)/, $(SRC))

boot:
	git submodule update --init $(JQ_DIR)
	git submodule update --init $(MASSCAN_DIR)

update:
	git pull origin HEAD
	git submodule update --checkout $(JQ_DIR)
	git submodule update --checkout $(MASSCAN_DIR)

clean:
	-$(MAKE) -C $(JQ_DIR) clean
	-$(MAKE) -C $(MASSCAN_DIR) clean

distclean: clean
	-$(MAKE) -C $(JQ_DIR) distclean
	-rm -rf $(PREFIX)

spotless: distclean
	-rm -rf $(JQ_DIR)
	-rm -rf $(MASSCAN_DIR)

scan: $(DEPS) $(addprefix $(BINDIR)/, $(SRC))
	env PATH="$(BINDIR):$$PATH" sudo bash '$(BINDIR)/main.sh'

$(BINDIR):
	mkdir -p $@

$(BINDIR)/%.sh: $(SRCDIR)/%.sh
	cp $< $@

$(BINDIR)/%.pl: $(SRCDIR)/%.pl
	cp $< $@

$(JQ_DIR)/configure:
	cd $(JQ_DIR); autoreconf -i;

$(JQ_DIR)/Makefile:
	cd $(JQ_DIR); ./configure --prefix='$(abspath $(PREFIX))'

$(BINDIR)/jq: $(BINDIR) $(JQ_DIR)/Makefile
	$(MAKE) -C $(JQ_DIR)
	$(MAKE) -C $(JQ_DIR) install

$(BINDIR)/masscan: $(BINDIR)
	$(MAKE) -C $(MASSCAN_DIR)
	cp $(MASSCAN_DIR)/bin/masscan $@
