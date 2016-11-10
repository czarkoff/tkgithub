PREFIX ?=	/usr/local
BINDIR ?=	${PREFIX}/bin
MANDIR ?=	${PREFIX}/share/man
DATADIR ?=	${PREFIX}/share/tkgithub
DESKTOPDIR ?=	${PREFIX}/share/applications

WISH ?=/usr/bin/env wish

DATA_FILES :=	read.png \
		unread.png

SUBST_COMMANDS :=	-e 's|DATADIR|${DATADIR}|'

all: tkgithub tkgithub.1

tkgithub: tkgithub.tcl
	echo '#!${WISH}' > $@
	sed -e 1d ${SUBST_COMMANDS} tkgithub.tcl >> $@

tkgithub.1:tkgithub.1.in
	sed ${SUBST_COMMANDS} tkgithub.1.in > $@

install: tkgithub tkgithub.1
	install -D -m 0755 tkgithub ${BINDIR}/tkgithub
	for f in ${DATA_FILES}; do install -D DATADIR/$$f ${DATADIR}/$$f; done
	install -D tkgithub.desktop ${DESKTOPDIR}/tkgithub.desktop
	install -D tkgithub.1 ${MANDIR}/man1/tkgithub.1

uninstall:
	rm -Rf ${BINDIR}/tkgithub
	rm -Rf ${DATADIR}
	rm -Rf ${DESKTOPDIR}/tkgithub.desktop
	rm -Rf ${MANDIR}/man1/tkgithub.1

clean:
	rm -Rf tkgithub tkgithub.1

.PHONY: all clean install uninstall
