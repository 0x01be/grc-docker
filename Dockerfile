FROM alpine as builder

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
    guidata \
    sip

RUN svn checkout svn://svn.code.sf.net/p/qwt/code/branches/qwt-6.1 /qwt

WORKDIR /qwt

RUN qmake-qt5 qwt.pro
RUN make install

RUN git clone --depth 1 https://github.com/PierreRaybaut/PythonQwt /pythonqwt

WORKDIR /pythonqwt

RUN python3 setup.py build install

RUN svn checkout svn://svn.code.sf.net/p/qwtpolar/code/branches/qwtpolar-1.1 /qwtpolar

WORKDIR /qwtpolar

RUN cp /usr/local/qwt-6.1.5-svn/include/*.h /qwtpolar/src/

RUN apk --no-cache add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing qt-creator

RUN qmake-qt5 qwt.pro
RUN make install

RUN git clone --depth 1 https://github.com/EttusResearch/uhd /uhd

RUN mkdir -p /uhd/host/build/
WORKDIR /uhd/host/build/

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/uhd \
    ..
RUN make install

RUN git clone --depth 1 https://github.com/gnuradio/gnuradio /gnuradio

RUN mkdir -p /gnuradio/build
WORKDIR /gnuradio/build

ENV PATH      $PATH:/opt/udh/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib/:/usr/local/qwtpolar-1.1.1-svn/lib/
ENV LD_LIBRARY_PATH /usr/lib/:/opt/uhd/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib/:/usr/local/qwtpolar-1.1.1-svn/lib/
ENV LD_RUN_PATH     /usr/lib/:/opt/uhd/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib:/usr/local/qwtpolar-1.1.1-svn/lib/
ENV PYTHONPATH      /usr/lib/python3.8/site-packages/:/opt/uhd/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages/
ENV CFLAGGS "$CFLAGS -U_FORTIFY_SOURCE" 
ENV CXXFLAGS "$CXXFLAGS -U_FORTIFY_SOURCE"


#RUN cmake \
#    -DLIBCODEC2_LIBRARIES=/opt/codec2/lib64 \
#    -DLIBCODEC2_INCLUDE_DIRS=/opt/codec2/include \
#    -DMPIR_LIBRARY=/opt/mpir/lib/libmpir.so.23.0.3 \
#    -DMPIR_INCLUDE_DIR=/opt/mpir/include \
#    -DQWT_INCLUDE_DIRS= /usr/local/qwt-6.1.5-svn/include \
#    -DQWT_LIBRARIES=/usr/local/qwt-6.1.5-svn/lib \
#    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
#    -DCMAKE_BUILD_TYPE=Release \
#    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#    ..
#
#RUN make install
#
#ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/gnuradio/lib/
#ENV LD_RUN_PATH $LD_RUN_PATH:/opt/gnuradio/lib/
#ENV PATH $PATH:/opt/gnuradio/lib/:/opt/gnuradio/bin/
#
#RUN git clone --depth 1 git://git.osmocom.org/rtl-sdr /rtl-sdr
#
#RUN mkdir -p /rtl-sdr/build
#WORKDIR /rtl-sdr/build
#
#RUN cmake \
#    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
#    ..
#RUN make install
#
#RUN git clone --depth 1 git://git.osmocom.org/gr-osmosdr /gr-osmosdr
#
#RUN mkdir -p /gr-osmosdr/build
#WORKDIR /gr-osmosdr/build
#
#RUN cmake \
#    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
#    ..
#RUN make install
#
#FROM 0x01be/xpra
#
#COPY --from=builder /usr/lib/python3.8/site-packages/ /usr/lib/python3.8/site-packages/
#
#RUN apk add --no-cache --virtual gnuradio-runtime-dependencies \
#    gtk+3.0 \
#    qt5-qtbase \
#    qt5-qtsvg \
#    ttf-freefont \
#    gnome-icon-theme \
#    boost \
#    xterm \
#    fftw \
#    portaudio \
#    alsa-lib \
#    jack \
#    gsl \
#    sdl \
#    python3
#
# RUN apk add --no-cache --virtual gnuradio-edge-runtime-dependencies \
#    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
#    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
#    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
#    log4cpp \
#    gsm \
#    thrift
#
#COPY --from=builder /opt/volk/ /opt/volk/
#COPY --from=builder /opt/mpir/ /opt/mpir/
#COPY --from=builder /opt/codec2/ /opt/codec2/
#COPY --from=builder /usr/local/qwt-6.1.5-svn/ /usr/local/qwt-6.1.5-svn/
#COPY --from=builder /usr/local/qwtpolar-1.1.1-svn/ /usr/local/qwtpolar-1.1.1-svn/
#COPY --from=builder /opt/uhd/ /opt/uhd/
#COPY --from=builder /opt/gnuradio/ /opt/gnuradio/
#
#ENV PATH      $PATH:/opt/udh/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib/:/usr/local/qwtpolar-1.1.1-svn/lib/:/opt/gnuradio/lib/:/opt/gnuradio/bin/
#ENV LD_LIBRARY_PATH /usr/lib/:/opt/uhd/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib/:/usr/local/qwtpolar-1.1.1-svn/lib/:/opt/gnuradio/lib/
#ENV LD_RUN_PATH     /usr/lib/:/opt/uhd/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5-svn/lib:/usr/local/qwtpolar-1.1.1-svn/lib/:/opt/gnuradio/lib/
#ENV PYTHONPATH      /usr/lib/python3.8/site-packages/:/opt/uhd/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages/:/opt/gnuradio/lib/python3.8/site-packages/
#
#EXPOSE 10000
#
#VOLUME /workspace
#WORKDIR /workspace
#
#ENV COMMAND "gnuradio-companion"
#
#CMD /usr/bin/xpra start --bind-tcp=0.0.0.0:10000 --html=on --start-child=$COMMAND --exit-with-children --daemon=no --xvfb="/usr/bin/Xvfb +extension  Composite -screen 0 1280x720x24+32 -nolisten tcp -noreset" --pulseaudio=no --notifications=no --bell=no --mdns=no
#
