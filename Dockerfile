FROM 0x01be/grc:build as build

FROM 0x01be/xpra

RUN apk add --no-cache --virtual gnuradio-runtime-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community  \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
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
    mesa-dri-gallium \
    log4cpp \
    gsm 

COPY --from=build /usr/lib/python3.8/site-packages/ /usr/lib/python3.8/site-packages/
COPY --from=build /opt/volk/ /opt/volk/
COPY --from=build /opt/mpir/ /opt/mpir/
COPY --from=build /opt/codec2/ /opt/codec2/
COPY --from=build /opt/qwt/ /opt/qwt/
COPY --from=build /opt/gnuradio/ /opt/gnuradio/
COPY --from=build /opt/rtl-sdr/ /opt/rtl-sdr/

ENV PATH $PATH:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/bin/:/opt/rtl-sdr/bin/
ENV LD_LIBRARY_PATH /usr/lib/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/lib/:/opt/rtl-sdr/lib64/
ENV LD_RUN_PATH /usr/lib/:/usr/bin/:/opt/codec2/lib64/:/opt/mpir/lib/:/opt/volk/lib/:/opt/qwt/lib/:/opt/gnuradio/lib/:/opt/rtl-sdr/lib64/
ENV PYTHONPATH /usr/lib/python3.8/site-packages/:/opt/volk/lib/python3.8/site-packages/:/opt/gnuradio/lib/python3.8/site-packages/

ENV COMMAND gnuradio-companion

