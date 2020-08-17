FROM alpine as builder

RUN apk add --no-cache --virtual gnuradio-build-dependencies \
    git \
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
    py3-mako \
    py3-gobject3 \
    py3-cairo \
    py3-numpy-dev \
    py3-pybind11-dev \
    py3-yaml \
    py3-qt5 \
    pango \
    m4 \
    yasm \
    gsl-dev \
    fftw-dev \
    boost-dev \
    ffmpeg-dev \
    portaudio-dev \
    gmp-dev \
    orc-dev

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
RUN make
RUN make install

RUN git clone --depth 1 https://github.com/wbhart/mpir /mpir

WORKDIR /mpir

RUN ./autogen.sh
RUN ./configure --prefix=/opt/mpir
RUN make
RUN make install

RUN git clone --depth 1  https://github.com/drowe67/codec2 /codec2

RUN mkdir -p /codec2/build
WORKDIR /codec2/build

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/codec2 \
    ..
RUN make
RUN make install

#RUN git clone --depth 1 https://github.com/opencor/qwt /qwt

#WORKDIR /qwt

#RUN qmake-qt5 qwt.pro
#RUN make
#RUN make install

#ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5/lib/
#ENV LD_RUN_PATH $LD_RUN_PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/usr/local/qwt-6.1.5/lib/

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/
ENV LD_RUN_PATH $LD_RUN_PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/

RUN git clone --depth 1 https://github.com/gnuradio/gnuradio /gnuradio

RUN mkdir -p /gnuradio/build
WORKDIR /gnuradio/build

ENV CFLAGGS "$CFLAGS -U_FORTIFY_SOURCE" 
ENV CXXFLAGS "$CXXFLAGS -U_FORTIFY_SOURCE"

RUN cmake \
    -DLIBCODEC2_LIBRARIES=/opt/codec2/lib \
    -DLIBCODEC2_INCLUDE_DIRS=/opt/codec2/include \
    -DMPIRXX_LIBRARY=/opt/mpir/lib \
    -DMPIR_LIBRARY=/opt/mpir/lib \
    -DMPIR_INCLUDE_DIR=/opt/mpir/include \
    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    ..
RUN make
RUN make install

FROM 0x01be/xpra

COPY --from=builder /opt/volk/ /opt/volk/
COPY --from=builder /opt/mpir/ /opt/mpir/
COPY --from=builder /opt/codec2/ /opt/codec2/
#COPY --from=builder /usr/local/qwt-6.1.5/ /usr/local/qwt-6.1.5/
COPY --from=builder /opt/gnuradio/ /opt/gnuradio/

#ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/qwt-6.1.5/lib/:/opt/codec2/lib/:/opt/mpir/lib/:/opt/volk/lib/:/opt/gnuradio/lib/
#ENV LD_RUN_PATH $LD_RUN_PATH:/usr/local/qwt-6.1.5/lib/:/opt/codec2/lib/:/opt/mpir/lib/:/opt/volk/lib/:/opt/gnuradio/lib/

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/codec2/lib/:/opt/mpir/lib/:/opt/volk/lib/:/opt/gnuradio/lib/
ENV LD_RUN_PATH $LD_RUN_PATH§:/opt/codec2/lib/:/opt/mpir/lib/:/opt/volk/lib/:/opt/gnuradio/lib/

RUN apk add --no-cache --virtual gnuradio-runtime-dependencies \
    gtk+3.0 \
    qt5-qtbase \
    qt5-qtsvg \
    ttf-freefont

ENV PATH $PATH:/opt/gnuradio/bin/

VOLUME /workspace
WORKDIR /workspace

CMD /usr/bin/xpra start --bind-tcp=0.0.0.0:10000 --html=on --start-child=gnuradio-companion --exit-with-children --daemon=no --xvfb="/usr/bin/Xvfb +extension  Composite -screen 0 1280x720x24+32 -nolisten tcp -noreset" --pulseaudio=no --notifications=no --bell=no --mdns=no

