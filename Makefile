#########################################################
#
#    Makefile to install and test the proj utility
#
#########################################################

#########################################################
#
#                        Setup
#
#########################################################

SHELL := /bin/bash

#########################################################
#
#						Variables
#
#########################################################

# Base proj directory for testing
TEST_BASE := /proj-test

# The proj script
PROJ_SCRIPT := proj.sh

#########################################################
#
#						Goals
#
#########################################################

.PHONY: install test untest

# Copies the proj.sh file in PROJ_BASE and adds the line to source it to
# $HOME/.bashrc. The values of PROJ_BASE and PROJ_DB_FILE are determined by
# environment variables and the defaults defined in proj.sh.
install: $(PROJ_SCRIPT)
	source $< \
		&& cp $< "$$PROJ_BASE" \
		&& echo -e "\n# Proj\n[ -f $$PROJ_BASE/$< ] && source $$PROJ_BASE/$<" \
			>> "$$HOME/.bashrc"

# Removes the PROJ_BASE directory and the sourcing line in $HOME/.bashrc
uninstall:
	# Finding out what PROJ_BASE is by searching in $HOME/.bashrc
	$(eval BASE_DIR := $(shell grep -woP '\S*$(PROJ_SCRIPT)' $(HOME)/.bashrc \
		| head -n 1 | xargs dirname))

	rm -rf $(BASE_DIR)

	# Deleting the proj.sh sourcing line and the two before that (a blank line
	# and a comment) from $HOME/.bashrc
	grep -n -B 2 '$(BASE_DIR)' $(HOME)/.bashrc \
		| awk -F '[:-]' '{print $$1"d;"}' | xargs \
		| xargs -i sed -i '{}' $(HOME)/.bashrc

# Copies the proj.sh file in TEST_BASE and adds the line to source it to
# $HOME/.bashrc.
test: $(PROJ_SCRIPT)
	export PROJ_BASE="$$HOME/$(TEST_BASE)" \
		&& source $< \
		&& cp $< "$$PROJ_BASE" \
		&& echo "source $$PROJ_BASE/$<" >> "$$HOME/.bashrc"

# Removes the PROJ_BASE directory and the sourcing line in $HOME/.bashrc
untest:
	rm -rf $(HOME)/$(TEST_BASE)
	grep -n '$(TEST_BASE)' $(HOME)/.bashrc | cut -d':' -f 1 \
		| xargs -i sed -i '{}d' $(HOME)/.bashrc
