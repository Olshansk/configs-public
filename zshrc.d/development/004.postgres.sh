# This formula has created a default database cluster with:
#   initdb --locale=C -E UTF-8 /opt/homebrew/var/postgresql@18

# postgresql@18 is keg-only, which means it was not symlinked into /opt/homebrew,
# because this is an alternate version of another formula.

# If you need to have postgresql@18 first in your PATH, run:
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

# For compilers to find postgresql@18 you may need to set:
export LDFLAGS="-L/opt/homebrew/opt/postgresql@18/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@18/include"

# For pkg-config to find postgresql@18 you may need to set:
export PKG_CONFIG_PATH="/opt/homebrew/opt/postgresql@18/lib/pkgconfig"

# To start postgresql@18 now and restart at login:
# brew services start postgresql@18
# Or, if you don't want/need a background service you can just run:
# LC_ALL="C" /opt/homebrew/opt/postgresql@18/bin/postgres -D /opt/homebrew/var/postgresql@18

export PAGER="less -SRFX"