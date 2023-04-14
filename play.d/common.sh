#!/bin/sh

fatal()
{
    echo "FATAL: $*" >&2
    exit 1
}

# check if <arg> is a real command
is_command()
{
    epm tool which "$1" >/dev/null
}

eget()
{
    epm tool eget "$@"
}

[ -n "$BIGTMPDIR" ] || [ -d "/var/tmp" ] && BIGTMPDIR="/var/tmp" || BIGTMPDIR="/tmp"

cd_to_temp_dir()
{
    PKGDIR=$(mktemp -d --tmpdir=$BIGTMPDIR)
    trap "rm -fr $PKGDIR" EXIT
    cd $PKGDIR || fatal
}

is_supported_arch()
{
    local i

    # skip checking if there are no arches
    [ -n "$SUPPORTEDARCHES" ] || return 0
    [ -n "$1" ] || return 0

    for i in $SUPPORTEDARCHES ; do
        [ "$i" = "$1" ] && return 0
    done
    return 1
}


get_latest_version()
{
    local epmver="$(epm --short --version)"
    local URL="https://eepm.ru/releases/$epmver/app-versions"
    if ! eget -q -O- "$URL/$1" ; then
        URL="https://eepm.ru/app-versions"
        eget -q -O- "$URL/$1"
    fi
}

print_product_alt()
{
    [ -n "$1" ] || return
    shift
    echo "$*"
}

get_pkgvendor()
{
    epm print field Vendor for package $1
}

case "$1" in
    "--remove")
        epm remove $PKGNAME
        exit
        ;;
    "--info")
        if [ -n "$PRODUCTALT" ] ; then
            echo "Help about additional parameters."
            echo "Use epm play $(basename $0 .sh) [= $(echo "$PRODUCTALT" | sed -e 's@ @|@g')]"
        fi
        [ -n "$TIPS" ] && echo "$TIPS"
        [ -n "$URL" ] && echo "Url: $URL"
        exit
        ;;
    "--package-name")
        [ -n "$DESCRIPTION" ] || exit 0
        echo "$PKGNAME"
        exit
        ;;
    "--product-alternatives")
        print_product_alt $PRODUCTALT
        exit
        ;;
    "--installed")
        epm installed $PKGNAME
        exit
        ;;
    "--installed-version")
        epm print version for package $PKGNAME
        exit
        ;;
    "--description")
        is_supported_arch "$2" || exit 0
        echo "$DESCRIPTION"
        exit
        ;;
    "--update")
        if ! epm installed $PKGNAME ; then
            echo "Skipping update of $PKGNAME (package is not installed)"
            exit
        fi
        if epm mark showhold | grep -q "^$PKGNAME$" ; then
            echo "Skipping update of $PKGNAME (package is on hold, see '# epm mark showhold')"
            exit
        fi
        pkgver="$(epm print version for package $PKGNAME)"
        latestpkgver="$(get_latest_version $PKGNAME)"
        # ignore update if have no latest package version or the latest package version no more than installed one
        if [ -n "$pkgver" ] ; then
            if [ -z "$latestpkgver" ] ; then
                echo "Can't get info about latest version of $PKGNAME, so skip updating installed version $pkgver."
                exit
            fi
            # latestpkgver <= $pkgver
            if [ "$(epm print compare package version $latestpkgver $pkgver)" != "1" ] ; then
                echo "Latest available version of $PKGNAME: $latestpkgver. Installed version: $pkgver."
                exit
            fi
            echo "Updating $PKGNAME from $pkgver to available $latestpkgver version ..."
        fi
        ;;
    "--run")
        # just pass
        ;;
    *)
        fatal "Unknown command '$1'. Use this script only via epm play."
        ;;
esac


# support direct run the script
if [ -x "../bin/epm" ] ; then
    export PATH="$(realpath ../bin):$PATH"
fi

if [ -z "$SUDO" ] && [ "$UID" != "0" ] ; then
    SUDO="sudo"
fi

is_supported_arch "$(epm print info -a)" || fatal "Only '$SUPPORTEDARCHES' architectures is supported"
