VERSION := 0.19.1

# install directory layout
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# collect C++ sources, and link if necessary
CPPSRC := $(wildcard src/*.cc)

# collect sources
SRC := $(wildcard src/*.c)
SRC += $(CPPSRC)
OBJ := $(addsuffix .o,$(basename $(SRC)))

# ABI versioning
SONAME_MAJOR := 0
SONAME_MINOR := 0

CFLAGS ?= -O3 -Wall -Wextra
CXXFLAGS ?= -O3 -Wall -Wextra
override CFLAGS += -std=gnu99 -fPIC
override CXXFLAGS += -fPIC

# OS-specific bits
ifeq ($(shell uname),Darwin)
	SOEXT = dylib
	SOEXTVER_MAJOR = $(SONAME_MAJOR).dylib
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).dylib
	LINKSHARED += -dynamiclib -Wl,-install_name,$(LIBDIR)/libtree-sitter-javascript.$(SONAME_MAJOR).dylib
else
	SOEXT = so
	SOEXTVER_MAJOR = so.$(SONAME_MAJOR)
	SOEXTVER = so.$(SONAME_MAJOR).$(SONAME_MINOR)
	LINKSHARED += -shared -Wl,-soname,libtree-sitter-javascript.so.$(SONAME_MAJOR)
endif
ifneq (,$(filter $(shell uname),FreeBSD NetBSD DragonFly))
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif

all: libtree-sitter-javascript.a libtree-sitter-javascript.$(SOEXTVER)

libtree-sitter-javascript.a: $(OBJ)
	$(AR) rcs $@ $^

libtree-sitter-javascript.$(SOEXTVER): $(OBJ)
	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
	ln -sf $@ libtree-sitter-javascript.$(SOEXT)
	ln -sf $@ libtree-sitter-javascript.$(SOEXTVER_MAJOR)

install: all
	install -d '$(DESTDIR)$(LIBDIR)'
	install -m755 libtree-sitter-javascript.a '$(DESTDIR)$(LIBDIR)'/libtree-sitter-javascript.a
	install -m755 libtree-sitter-javascript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-javascript.$(SOEXTVER)
	ln -sf libtree-sitter-javascript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-javascript.$(SOEXTVER_MAJOR)
	ln -sf libtree-sitter-javascript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-javascript.$(SOEXT)
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter
	install -m644 bindings/c/javascript.h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/
	install -d '$(DESTDIR)$(PCLIBDIR)'
	sed -e 's|@LIBDIR@|$(LIBDIR)|;s|@INCLUDEDIR@|$(INCLUDEDIR)|;s|@VERSION@|$(VERSION)|' \
	    -e 's|=$(PREFIX)|=$${prefix}|' \
	    -e 's|@PREFIX@|$(PREFIX)|' \
	    -e 's|@ADDITIONALLIBS@|$(ADDITIONALLIBS)|' \
	    bindings/c/tree-sitter-javascript.pc.in > '$(DESTDIR)$(PCLIBDIR)'/tree-sitter-javascript.pc

clean:
	rm -f $(OBJ) libtree-sitter-javascript.a libtree-sitter-javascript.$(SOEXT) libtree-sitter-javascript.$(SOEXTVER_MAJOR) libtree-sitter-javascript.$(SOEXTVER)

.PHONY: all install clean