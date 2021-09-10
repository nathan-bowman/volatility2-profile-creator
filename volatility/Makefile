# FYI - CPU and TOOLDIR vars come from exports

obj-m += module.o
KDIR ?= /
KVER ?= $(shell uname -r)

-include version.mk

all: dwarf

dwarf: module.c
	$(MAKE) -C $(KDIR)/lib/modules/$(KVER)/build CONFIG_DEBUG_INFO=y M="$(TOOLDIR)/volatility" modules
	$(TOOLDIR)/dwarfdump/dwarfdump-$(CPU) -di $(TOOLDIR)/volatility/module.ko > $(TOOLDIR)/volatility/module.dwarf
	$(MAKE) -C $(KDIR)/lib/modules/$(KVER)/build M="$(TOOLDIR)/volatility" clean

clean:
	$(MAKE) -C $(KDIR)/lib/modules/$(KVER)/build M="$(TOOLDIR)/volatility" clean
	rm -f $(TOOLDIR)/volatility/module.dwarf
