SHELL :=bash
.SHELLFLAGS := -o errexit -o nounset -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:                                                          

.PHONY: tools build test run pack clean help

SHELLCHECK := shellcheck
SHFMT := shfmt
SRC_DIR := src 
TEST_DIR := tests
OUT_DIR := out 
DIST_DIR := dist 

tools: ##este target verifica dependencias
	@command -v $(SHELLCHECK) >/dev/null || { echo "shellcheck no instalado ";exit 1;}
	@commnad -v $(SHFMT) >/dev/null || { echo "shfmt no instalado"; exit 1 ; }
	@command -v grep >/dev/null || {echo "falta grep ", exit 1; }
	@command -v awk >/dev/null || { echo "awk ausente ", exit 1; }
	@tar --version 2 >/dev/null | grep -q 'GNU tar' || { echo "Se debe instalar GNU tar"}
	@command -v sha256sum >/dev/null || {echo "Falta sha256sum";exit 1;}