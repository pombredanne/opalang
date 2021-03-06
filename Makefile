#!/usr/bin/make

# [ Warning ] don't use make to solve dependencies !!
#
# we rely on ocamlbuild which already handles them ; every rule should
# call it only once (no recursion)
#
# More info in build/Makefile.bld

include config.make

INSTALL ?= cp -u -L
MAKE ?= $_
export MAKE

ifndef NO_REBUILD_OPA_PACKAGES
OPAOPT += "--rebuild"
endif

ifneq ($(HAS_CAMLIDL)$(HAS_LIBNATPMP)$(HAS_MINIUPNPC),111)
export DISABLED_LIBS = libnattraversal
endif

.PHONY: default
default: all

include build/Makefile.bld

export

##
## STANDARD TARGETS
##

.PHONY: all
all: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(ALL_TOOLS)) opa-packages.stamp
	@$(call copy-tools,$(ALL_TOOLS))

.PHONY: build
build: all

.PHONY: runtime-libs
runtime-libs: $(MYOCAMLBUILD)
	$(OCAMLBUILD) runtime-libs.stamp

.PHONY: $(BUILD_DIR)/bin/opa
$(BUILD_DIR)/bin/opa: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-packages.stamp $(target-tool-opa-bin)
	@$(copy-tool-opa-bin)
	@utils/install.sh --quiet --dir $(PWD)/$(BUILD_DIR) --ocaml-prefix $(OCAMLLIB)/../..

.PHONY: opa
opa: $(BUILD_DIR)/bin/opa

.PHONY: opa-packages
opa-packages: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-packages.stamp

.PHONY: stdlib
stdlib: opa-packages

DISTRIB_TOOLS = opa-bin opadoc opa-plugin-builder-bin opa-plugin-browser-bin bslServerLib.ml opa-db-server opa-db-tool opa-cloud opatop

.PHONY: distrib
distrib: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(DISTRIB_TOOLS)) opa-packages.stamp
	@$(call copy-tools,$(DISTRIB_TOOLS))

##
## INSTALLATION
##

.PHONY: install*

STDLIB_DIR = $(INSTALL_DIR)/lib/opa/stdlib
define install-package
@printf "Installing into $(STDLIB_DIR)/$*.opx[K\r"
@mkdir -p "$(STDLIB_DIR)/$*.opx/_build"
@find "$(BUILD_DIR)/$*.opx" -maxdepth 1 ! -type d -exec $(INSTALL) {} "$(STDLIB_DIR)/$*.opx/" \;
@$(INSTALL) $(BUILD_DIR)/$*.opx/_build/*.a "$(STDLIB_DIR)/$*.opx/_build/"
@$(INSTALL) $(BUILD_DIR)/$*.opx/_build/*.cmi "$(STDLIB_DIR)/$*.opx/_build/"
@$(INSTALL) $(BUILD_DIR)/$*.opx/_build/*.cmxa "$(STDLIB_DIR)/$*.opx/_build/"
endef

define install-plugin
@printf "Installing into $(STDLIB_DIR)/$*.opp^[[K\r"
@mkdir -p "$(STDLIB_DIR)/$*.opp"
@$(INSTALL) $(BUILD_DIR)/$*.opp/*.bypass "$(STDLIB_DIR)/$*.opp/";
@$(INSTALL) $(BUILD_DIR)/$*.opp/*MLRuntime.* "$(STDLIB_DIR)/$*.opp/";
endef



OPA_PACKAGES := $(shell cd stdlib && ./all_packages.sh)
OPA_PLUGINS  := $(shell cd stdlib && ./all_plugins.sh)

# Rules installing everything that has been compiled
#
# This doesn't rely on install rules generated by Makefile.bld ;
# instead it assumes that what you want to install has been properly
# put in $(BUILD_DIR)/{bin,lib/opa,share/opa}.
#
# This is the case of tools (because of Makefile.bld),
# and of opa runtime libs (because build rules copy them
# to $(BUILD_DIR)/lib/opa/static).
# This doesn't install the other libs though, use target install-libs
# for that

install-packageopt-%:
	$(if $(wildcard $(BUILD_DIR)/$*.opx/_build/*),$(install-package))

install-package-%:
	$(install-package)

install-packages: $(addprefix install-packageopt-,$(OPA_PACKAGES))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"

install-all-packages: $(addprefix install-package-,$(OPA_PACKAGES))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"

install-pluginopt-%:
	$(if $(wildcard $(BUILD_DIR)/$*.opp/),$(install-plugin))

install-plugin-%:
	$(install-plugin)

install-plugins: $(addprefix install-pluginopt-,$(OPA_PLUGINS))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"

install-all-plugins: $(addprefix install-plugin-,$(OPA_PLUGINS))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"



install-bin:
	@printf "Installing into $(INSTALL_DIR)/bin[K\r"
	@mkdir -p $(INSTALL_DIR)/bin
	@$(if $(wildcard $(BUILD_DIR)/bin/*),$(INSTALL) -r $(BUILD_DIR)/bin/* $(INSTALL_DIR)/bin)
	@utils/install.sh --quiet --dir $(INSTALL_DIR) --ocamllib $(OCAMLLIB) --ocamlopt $(OCAMLOPT)
	@printf "Installation to $(INSTALL_DIR)/bin done.[K\n"

install-lib:
	@printf "Installing into $(INSTALL_DIR)/lib/opa[K\r"
	@mkdir -p $(INSTALL_DIR)/lib/opa
	@$(if $(wildcard $(BUILD_DIR)/lib/opa/*),$(INSTALL) -r $(BUILD_DIR)/lib/opa/* $(INSTALL_DIR)/lib/opa/)
	@printf "Installation to $(INSTALL_DIR)/lib/opa done.[K\n"

install-share:
	@printf "Installing into $(INSTALL_DIR)/share/opa[K\r"
	@mkdir -p $(INSTALL_DIR)/share/opa
	@$(if $(wildcard $(BUILD_DIR)/share/opa/*),$(INSTALL) -r $(BUILD_DIR)/share/opa/* $(INSTALL_DIR)/share/opa/)
	@printf "Installation to $(INSTALL_DIR)/share/opa done.[K\n"

install-doc:
	@printf "Installing into $(INSTALL_DIR)/share/doc/opa[K\r"
	@if [ -d $(BUILD_DIR)/opadoc/doc/ ]; then \
	  mkdir -p $(INSTALL_DIR)/share/doc/opa/api; \
	  $(INSTALL) -r $(BUILD_DIR)/opadoc/doc/* $(INSTALL_DIR)/share/doc/opa/api; \
	fi
	@printf "Installation to $(INSTALL_DIR)/share/doc/opa done.[K\n"

install: install-bin install-lib install-share install-plugins install-packages install-doc
	@printf "Installation into $(INSTALL_DIR) done.[K\n"

.PHONY: uninstall
uninstall:
	rm -rf $(INSTALL_DIR)/lib/opa
	@[ ! -d $(INSTALL_DIR)/lib ] || [ -n "`ls -A $(INSTALL_DIR)/lib`" ] || rmdir $(INSTALL_DIR)/lib
	rm -rf $(INSTALL_DIR)/share/opa
	rm -rf $(INSTALL_DIR)/share/doc/opa
	@[ ! -d $(INSTALL_DIR)/share ] || [ -n "`ls -A $(INSTALL_DIR)/share`" ] || rmdir $(INSTALL_DIR)/share
	$(foreach file,$(wildcard $(BUILD_DIR)/bin/*),rm -f $(INSTALL_DIR)/bin/$(notdir $(file));)
	@utils/install.sh --uninstall --dir $(INSTALL_DIR)
	@[ ! -d $(INSTALL_DIR)/bin ] || [ -n "`ls -A  $(INSTALL_DIR)/bin`" ] || rmdir $(INSTALL_DIR)/bin
	@printf "Uninstall done.[K\n"

# Install our ocamlbuild-generation engine
install-bld:
	@mkdir -p $(INSTALL_DIR)/bin
	@echo "#!/usr/bin/env bash" > $(INSTALL_DIR)/bin/bld
	@echo "set -e" >> $(INSTALL_DIR)/bin/bld
	@echo "set -u" >> $(INSTALL_DIR)/bin/bld
	@chmod 755 $(INSTALL_DIR)/bin/bld
	@echo "BLDDIR=$(PREFIX)/share/opa/bld $(PREFIX)/share/opa/bld/gen_myocamlbuild.sh" >> $(INSTALL_DIR)/bin/bld
	@echo "_build/myocamlbuild -no-plugin -j 6 \"\$$@\"" >> $(INSTALL_DIR)/bin/bld
	@mkdir -p $(INSTALL_DIR)/share/opa/bld
	@$(INSTALL) build/gen_myocamlbuild.sh build/myocamlbuild_*fix.ml config.sh config.mli config.ml\
	  $(INSTALL_DIR)/share/opa/bld

# Install an opa wrapper with different stdlib and options (for some backwards-compatibility)
install-qmlflat: # depends on opabsl_for_compiler, but we don't want to run ocamlbuild twice
	@mkdir -p $(INSTALL_DIR)/bin $(INSTALL_DIR)/share/opa/mlstatebsl
	@$(INSTALL) $(BUILD_DIR)/opabsl/mlstatebsl/opabslgen_*.opa $(INSTALL_DIR)/share/opa/mlstatebsl
	@echo "#!/usr/bin/env bash" > $(INSTALL_DIR)/bin/qmlflat
	@echo "set -e" >> $(INSTALL_DIR)/bin/qmlflat
	@echo "set -u" >> $(INSTALL_DIR)/bin/qmlflat
	@chmod 755 $(INSTALL_DIR)/bin/qmlflat
	@echo 'exec opa --no-stdlib --no-server --no-cps --no-closure --no-ei --no-constant-sharing --no-undot --separated off --value-restriction disabled --no-warn duplicateL0  --no-warn typer.warncoerce --no-warn unused --no-discard-of-unused-stdlib --no-warn pattern $$(if ! grep -qE "(^| )--no-stdlib( |$$)" <<<"$$*"; then echo $(shell sed "s%^[^# ]\+%$(PREFIX)/share/opa/mlstatebsl/opabslgen_&%; t OK; d; :OK" opabsl/mlstatebsl/bsl-sources); fi) "$$@"' \
	>> $(INSTALL_DIR)/bin/qmlflat

# installs some dev tools on top of the normal install; these should not change often
install-all: install install-bld install-qmlflat utils/maxmem
	@$(INSTALL) platform_helper.sh $(INSTALL_DIR)/bin/
	@$(INSTALL) utils/maxmem $(INSTALL_DIR)/bin/
	@rm utils/maxmem
	@$(INSTALL) utils/plotmem $(INSTALL_DIR)/bin/

##
## DOCUMENTATION
##
# (in this section, multiple calls to ocamlbuild are tolerated)

.PHONY: doc.jsbsl
doc.jsbsl: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $@/index.html

# this rules provides the doc.html target (from Makefile.bld)
# the sed are just there to help sorting by filename-within-directory
.PHONY: doc.odocl
doc.odocl:
	echo $(foreach lib,$(ALL_LIBS),$(lib-cmi-$(lib):%.cmi=%)) \
	| sed 's# \+#\n#g' \
	| sed 's#\(.*\)/\([^/]*\)#\1 \2#' \
	| sort -k 2 -u \
	| sed 's#\(.*\) \([^ ]*\)#\1/\2#' \
	>$@

.PHONY: packages-api
packages-api: $(MYOCAMLBUILD)
	OPAOPT="$(OPAOPT) --rebuild --api" $(OCAMLBUILD) opa-packages.stamp

.PHONY: opadoc/doc
opadoc/doc: opadoc packages-api
	@mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR) && ./bin/opadoc -o $@ stdlib && cd -

.PHONY: book
book:
	$(MAKE) -C doc/book

.PHONY: examples
examples: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,opa-bin opa-plugin-builder-bin) opa-packages.stamp
	$(call copy-tools,opa-bin opa-plugin-builder-bin)
	MLSTATELIBS=`pwd`/$(BUILD_DIR) \
	OPA="`pwd`/$(BUILD_DIR)/lib/opa/bin/opa-bin -I `pwd`/$(BUILD_DIR)" \
	OPA_PLUGIN_BUILDER=`pwd`/$(BUILD_DIR)/lib/opa/bin/opa-plugin-builder-bin \
	$(MAKE) -C doc/book examples

.PHONY: book-clean
book-clean:
	$(MAKE) -C doc/book clean

.PHONY: clean
clean: book-clean

.PHONY: doc
doc: doc.html opadoc/doc book
