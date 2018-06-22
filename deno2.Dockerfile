FROM phusion/baseimage

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libgtk-3-dev \
    pkg-config \
    ccache \
    curl \
    gnupg \
    build-essential \
    git \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* 

ENV PATH="/usr/lib/ccache/:$PATH"
RUN mkdir -p /root/.ccache/ && touch /root/.ccache/ccache.conf
ENV CCACHE_SLOPPINESS=time_macros
ENV CCACHE_CPP2=yes

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g yarn

RUN curl https://sh.rustup.rs > rustup.sh && sh ./rustup.sh -y

RUN cd /opt/ && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH=$PATH:/opt/depot_tools

WORKDIR /opt/
RUN git clone https://github.com/ry/deno.git
WORKDIR /opt/deno/src
RUN cd js; yarn install
RUN gclient sync --no-history
RUN gn gen out/Default --args='is_debug=false use_allocator="none" cc_wrapper="ccache" use_custom_libcxx=false use_sysroot=false'
RUN ninja -C out/Default/ mock_runtime_test deno
RUN ninja -C out/Default/ deno_rs

CMD /opt/deno/src/out/Default/deno
