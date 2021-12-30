# Portions Copyright 2019 Productize SPRL
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
#
# This docker configuration was originally based on https://github.com/productize/docker-kicad as of 301bf181b72c811e9644b83a895ec4a16f2fa1a0


FROM ubuntu:focal
MAINTAINER Jesse Vincent <jesse@keyboard.io>
LABEL Description="Minimal KiCad image based on Ubuntu"
LABEL org.opencontainers.image.source https://github.com/obra/kicad-tools

ADD etc/kicad-ppa.pgp .
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
        apt-get -y update && \
        apt-get -y install gnupg2 software-properties-common && \
        add-apt-repository ppa:kicad/kicad-6.0-releases && \
        apt-key add kicad-ppa.pgp && \
        apt-get -y update && \
	apt-get -y install --no-install-recommends kicad kicad-footprints kicad-symbols kicad-packages3d && \
        rm kicad-ppa.pgp


# Use a UTF-8 compatible LANG because KiCad 5 uses UTF-8 in the PCBNew title
# This causes a "failure in conversion from UTF8_STRING to ANSI_X3.4-1968" when
# attempting to look for the window name with xdotool.
ENV LANG C.UTF-8

COPY upstream/KiAuto /opt/kiauto

RUN apt-get install -y python3 xvfb recordmydesktop xdotool xclip zip curl x11vnc gcc build-essential \
	python3-dev python3-pip python3-distutils python3-yaml python3-xlsxwriter

RUN cd /opt/kiauto/ && pip3 install -e .



RUN useradd -ms /bin/bash user

# Install KiPlot
COPY upstream/KiBot /opt/kibot

RUN cd /opt/kibot && pip install --no-compile .

# Install JLCKicadTools

COPY upstream/JLCKicadTools /opt/jlckicadtools
RUN cd /opt/jlckicadtools && pip3 install -e .

# Install the interactive BOM

COPY upstream/InteractiveHtmlBom /opt/InteractiveHtmlBom
COPY scripts/make-interactive-bom /opt/InteractiveHtmlBom/

# Install image diffing
RUN apt-get -y update && \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/disable ghostscript format types/d' /etc/ImageMagick-6/policy.xml && \
    sed -i '/\"PS\"/d' /etc/ImageMagick-6/policy.xml && \
    sed -i '/\"EPS\"/d' /etc/ImageMagick-6/policy.xml && \
    sed -i '/\"PDF\"/d' /etc/ImageMagick-6/policy.xml && \
    sed -i '/\"XPS\"/d' /etc/ImageMagick-6/policy.xml


RUN apt-get -y purge gnupg2 python3-pip build-essential && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*




COPY bin-on-docker/git-diff-boards.sh /opt/diff-boards/
#COPY bin/git-imgdiff /opt/diff-boards/
COPY bin-on-docker/plot_board.py /opt/diff-boards/
COPY bin-on-docker/pcb-diff.sh /opt/diff-boards/
COPY bin-on-docker/schematic-diff.sh /opt/diff-boards/

COPY bin-on-docker/fill_zones.py /usr/local/bin/


USER user
WORKDIR /home/user

