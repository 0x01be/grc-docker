FROM alpine as builder

ENV QWT_SVN_BRANCH 6.2
ENV QWT_VERSION 6.2.0

RUN apk add --no-cache --virtual gnuradio-build-dependencies \
    git \
    subversion \
    build-base \
    pkgconfig \
    cmake \
    autoconf \
    automake \
    libtool \
    doxygen \
    graphviz \
    texinfo \
    qt5-qtbase-dev \
    qt5-qtsvg-dev \
    gtk+3.0-dev \
    python3-dev \
    cython \
    py3-mako \
    py3-gobject3 \
    py3-cairo \
    py3-numpy-dev \
    py3-scipy \
    py3-pillow \
    py3-pybind11-dev \
    py3-yaml \
    py3-qt5 \
    py3-pip \
    pango \
    m4 \
    yasm \
    gsl-dev \
    fftw-dev \
    boost-dev \
    ffmpeg-dev \
    portaudio-dev \
    alsa-lib-dev \
    jack-dev \
    gmp-dev \
    orc-dev \
    sdl-dev \
    libusb-dev

RUN apk add --no-cache --virtual gnuradio-edge-build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    log4cpp-dev \
    gsm-dev \
    thrift-dev \
    texlive-dev \
    texlive-luatex \
    texlive-xetex

RUN git clone --depth 1 https://github.com/gnuradio/volk /volk

RUN mkdir -p /volk/build
WORKDIR /volk/build

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/volk \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    ..
RUN make install

RUN git clone --depth 1 https://github.com/wbhart/mpir /mpir

WORKDIR /mpir

RUN ./autogen.sh
RUN ./configure --prefix=/opt/mpir
RUN make install

RUN git clone --depth 1  https://github.com/drowe67/codec2 /codec2

RUN mkdir -p /codec2/build
WORKDIR /codec2/build

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/codec2 \
    ..
RUN make install

RUN pip install \
    click \
    click-plugins \
    guidata

RUN svn checkout svn://svn.code.sf.net/p/qwt/code/branches/qwt-${QWT_SVN_BRANCH} /qwt

WORKDIR /qwt

RUN qmake-qt5 qwt.pro
RUN make install
RUN cp -R /usr/local/qwt-${QWT_VERSION}-svn/lib/* /usr/lib/
RUN cp -R /usr/local/qwt-${QWT_VERSION}-svn/include/* /usr/include/

RUN git clone --depth 1 https://github.com/GauiStori/PyQt-Qwt.git /pyqt-qwt

WORKDIR /pyqt-qwt

RUN sed -i.bak s/DocType\=\"dict-of-double-QString\"//g /pyqt-qwt/sip/qmap_convert.sip

# Needs to be sip4 (don't install with pip)
RUN apk add py3-sip-dev
RUN python3 configure.py --qmake /usr/bin/qmake-qt5 --verbose
RUN make install

RUN git clone --depth 1 https://github.com/gnuradio/gnuradio /gnuradio

RUN mkdir -p /gnuradio/build
WORKDIR /gnuradio/build

ENV PATH $PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/
ENV LD_LIBRARY_PATH /usr/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/
ENV LD_RUN_PATH /usr/lib/:/usr/bin/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/
ENV PYTHONPATH /usr/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages/
ENV CFLAGGS "$CFLAGS -U_FORTIFY_SOURCE" 
ENV CXXFLAGS "$CXXFLAGS -U_FORTIFY_SOURCE"

RUN cmake \
    -DLIBCODEC2_LIBRARIES=/opt/codec2/lib64 \
    -DLIBCODEC2_INCLUDE_DIRS=/opt/codec2/include \
    -DMPIR_LIBRARY=/opt/mpir/lib/libmpir.so\
    -DMPIR_INCLUDE_DIR=/opt/mpir/include \
    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    ..

RUN make install

ENV PATH $PATH:/opt/gnuradio/lib/:/opt/gnuradio/bin/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/gnuradio/lib/
ENV LD_RUN_PATH $LD_RUN_PATH:/opt/gnuradio/lib/

RUN git clone --depth 1 git://git.osmocom.org/rtl-sdr /rtl-sdr

RUN mkdir -p /rtl-sdr/build
WORKDIR /rtl-sdr/build

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/rtl-sdr \
    ..
RUN make install

RUN cp -R /usr/local/qwt-${QWT_VERSION}-svn /opt/qwt

FROM 0x01be/xpra

COPY --from=builder /usr/lib/python3.8/site-packages/ /usr/lib/python3.8/site-packages/

RUN apk add --no-cache --virtual gnuradio-runtime-dependencies \
    gtk+3.0 \
    qt5-qtbase \
    qt5-qtsvg \
    ttf-freefont \
    gnome-icon-theme \
    boost \
    xterm \
    fftw \
    portaudio \
    alsa-lib \
    jack \
    gsl \
    sdl \
    python3 \
    py3-numpy \
    py3-six \
    py3-mako \
    py3-yaml \
    py3-qt5 \
    py3-matplotlib \
    mesa-dri-gallium

 RUN apk add --no-cache --virtual gnuradio-edge-runtime-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    log4cpp \
    gsm 

COPY --from=builder /opt/volk/ /opt/volk/
COPY --from=builder /opt/mpir/ /opt/mpir/
COPY --from=builder /opt/codec2/ /opt/codec2/
COPY --from=builder /opt/qwt/ /opt/qwt/
COPY --from=builder /opt/gnuradio/ /opt/gnuradio/
COPY --from=builder /opt/rtl-sdr/ /opt/rtl-sdr/

ENV PATH $PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/bin/:/opt/rtl-sdr/bin/
ENV LD_LIBRARY_PATH /usr/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/lib/:/opt/rtl-sdr/lib64/
ENV LD_RUN_PATH /usr/lib/:/usr/bin/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/lib/:/opt/rtl-sdr/lib64/
ENV PYTHONPATH /usr/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages/:/opt/gnuradio/lib/python3.8/site-packages/

ENV COMMAND "gnuradio-companion"

