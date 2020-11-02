FROM 0x01be/volk as volk
FROM 0x01be/mpir as mpir
FROM 0x01be/codec2 as codec2
FROM 0x01be/qwt as qwt

FROM alpine

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
    py3-mako \
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
    graphviz \
    mtex2mml-fixtures \
    libsndfile-dev 

RUN pip install \
    --prefix=/opt/gnuradio \
    --no-deps \
    click \
    click-plugins \
    guidata

COPY --from=volk /opt/volk/ /opt/volk/
COPY --from=mpir /opt/mpir/ /opt/mpir/
COPY --from=codec2 /opt/codec2/ /opt/codec2/
COPY --from=qwt /opt/qwt/ /opt/qwt/

ENV REVISION master
RUN git clone --depth 1 --branch ${REVISION} https://github.com/gnuradio/gnuradio /gnuradio

WORKDIR /gnuradio/build

ENV CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH};/opt/volk/;/opt/mpir/;/opt/codec2/;/opt/qwt/ \
    CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH};/opt/volk/;/opt/mpir/;/opt/codec2/;/opt/qwt/ \
    CPATH=${CPATH}:/opt/volk/lib/:/opt/mpir/lib/:/opt/codec2/lib/:/opt/codec2/lib64/:/opt/qwt/lib/ \
    C_INCLUDE_PATH=${C_INCLUDE_PATH}:/opt/volk/lib/:/opt/mpir/lib/:/opt/codec2/lib/:/opt/codec2/lib64/:/opt/qwt/lib/ \
    CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:/opt/volk/lib/:/opt/mpir/lib/:/opt/codec2/lib/:/opt/codec2/lib64/:/opt/qwt/lib/ \
    PYTHONPATH=/usr/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages:/opt/gnuradio/lib/python3.8/site-packages/:/opt/qwt/lib/python3.8/site-packages/ \
    CFLAGGS="$CFLAGS -U_FORTIFY_SOURCE" \
    CXXFLAGS="$CXXFLAGS -U_FORTIFY_SOURCE"

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/gnuradio \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    ..

RUN make install

