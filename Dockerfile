FROM ubuntu:18.04 as builder
COPY ./Detector_linux_so.tar.gz /home/
COPY ./sources.list /etc/apt/sources.list
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install cmake g++ git -y \
    && apt-get install -y libopenblas-dev libopencv-dev \
             libboost-chrono-dev libboost-date-time-dev \
             libboost-system-dev libboost-filesystem-dev \
             libboost-random-dev libboost-random-dev \
             libboost-regex-dev libboost-test-dev \
             libboost-thread-dev libboost-serialization-dev \
    && mkdir /file_swap \
    # compile Detector
    && cd /home/ \ 
    && tar -zxvf Detector_linux_so.tar.gz \
    && cp linux_so/*so* /file_swap \
    && git clone https://github.com/kirisame-project/Detector.git \
    && mv linux_so Detector/ \
    && cd Detector && mkdir build && cd build && cmake .. && make -j"$(nproc)" && mv Detector /file_swap \
    # compile FaissServer
    && cd /home/ \ 
    && git clone https://github.com/kirisame-project/SearchServer.git \
    && cd SearchServer && mkdir build && cd build && cmake .. && make -j"$(nproc)" && mv bin/searcher /file_swap



FROM debian:10.1

LABEL Antinomy at GXU <https://github.com/Antinomy20001>

COPY --from=builder /file_swap/* /file_swap/

RUN cp /file_swap/*so* /usr/lib/ \
    && mkdir Detector FaissServer && mv file_swap/Detector /Detector && mv file_swap/searcher /FaissServer/FaissServer \
    && sed -i 's/deb.debian.org/ftp2.cn.debian.org/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y libopencv-core3.2 libopencv-imgcodecs3.2 libopencv-imgproc3.2 libopenblas-base \
    && apt-get clean -y && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && export LD_LIBRARY_PATH=/file_swap:$LD_LIBRARY_PATH