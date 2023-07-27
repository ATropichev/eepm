#!/bin/sh -x
# It will run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT=masterpdfeditor5
PRODUCTCUR=master-pdf-editor
PRODUCTDIR=/opt/master-pdf-editor-5

UNIREQUIRES="libsane.so.1 libz.so.1"

. $(dirname $0)/common.sh

add_bin_link_command
add_bin_link_command $PRODUCTCUR $PRODUCT

fix_desktop_file

add_qt5_deps
