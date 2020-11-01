FROM 0x01be/volk as volk
FROM 0x01be/mpir as mpir
FROM 0x01be/codec2 as codec2

FROM 0x01be/qwt:build

RUN apk add --no-cache --virtual gnuradio-build-dependencies \
    git \
    build-base \
    pkgconfig \
    cmake

RUN apk add --no-cache --virtual gnuradio-edge-build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    qt5-qtbase-dev \
    qt5-qtsvg-dev \
    gtk+3.0-dev \
    python3-dev \
    cython \
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
    libusb-dev \
    log4cpp-dev \
    gsm-dev \
    thrift-dev \
    texinfo \
    texlive-dev \
    texlive-luatex \
    texlive-xetex \
    doxygen \
    graphviz

COPY --from=volk /opt/volk/ /opt/volk/
COPY --from=mpir /opt/mpir/ /opt/mpir/
COPY --from=codec2 /opt/codec2/ /opt/codec2/

RUN pip install \
    click \
    click-plugins \
    guidata

ENV REVISION master
RUN git clone --depth 1 --depth ${REVISION} https://github.com/gnuradio/gnuradio /gnuradio

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

