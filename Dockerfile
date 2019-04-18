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


FROM ubuntu:disco
MAINTAINER Jesse Vincent <jesse@keyboard.io>
LABEL Description="Minimal KiCad image based on Ubuntu"


ADD upstream/kicad-automation-scripts/kicad-ppa.pgp .
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
        apt-get -y update && \
        apt-get -y install gnupg2 && \
        echo 'deb http://ppa.launchpad.net/js-reynaud/kicad-5.1/ubuntu disco main' >> /etc/apt/sources.list && \
        apt-key add kicad-ppa.pgp && \
        apt-get -y update && apt-get -y install --no-install-recommends kicad kicad-footprints kicad-symbols kicad-packages3d && \
        apt-get -y purge gnupg2 && \
        apt-get -y autoremove && \
        rm -rf /var/lib/apt/lists/* && \
        rm kicad-ppa.pgp

COPY upstream/kicad-automation-scripts/eeschema/requirements.txt .
RUN apt-get -y update && \
    apt-get install -y python python-pip xvfb recordmydesktop xdotool xclip && \
    pip install -r requirements.txt && \
    rm requirements.txt

RUN apt-get -y remove python3-pip && \
    rm -rf /var/lib/apt/lists/*


# Use a UTF-8 compatible LANG because KiCad 5 uses UTF-8 in the PCBNew title
# This causes a "failure in conversion from UTF8_STRING to ANSI_X3.4-1968" when
# attempting to look for the window name with xdotool.
ENV LANG C.UTF-8

COPY upstream/kicad-automation-scripts /usr/lib/python2.7/dist-packages/kicad-automation

# Copy default configuration and fp_lib_table to prevent first run dialog
COPY upstream/kicad-automation-scripts/config/* /root/.config/kicad/

# Copy the installed global symbol and footprint so projcts built with stock
# symbols and footprints don't break
RUN cp /usr/share/kicad/template/sym-lib-table /root/.config/kicad/
RUN cp /usr/share/kicad/template/fp-lib-table /root/.config/kicad/



# Install KiPlot

# Kicad's libraries are tied to python3, so we need to install kiplot with
# python 3
RUN apt-get -y update && \
    apt-get install -y python3-pip

COPY upstream/kiplot /opt/kiplot

RUN cd /opt/kiplot && pip3 install -e . 

COPY etc/kiplot /opt/etc/kiplot


# Install KiCost
#
# Disabled because KiCost depends on Octopart which no longer has a free API
#RUN pip3 install 'kicost==1.0.4'
#
#RUN apt-get -y remove python3-pip && \
#    rm -rf /var/lib/apt/lists/*
#

# Install the interactive BOM

COPY upstream/InteractiveHtmlBom /opt/InteractiveHtmlBom
COPY scripts/make-interactive-bom /opt/InteractiveHtmlBom/

# Install image diffing
RUN apt-get -y update && \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/*

COPY bin-on-docker/git-diff-boards.sh /opt/diff-boards/
#COPY bin/git-imgdiff /opt/diff-boards/
COPY bin-on-docker/plot_board.py /opt/diff-boards/
COPY bin-on-docker/pcb-diff.sh /opt/diff-boards/
COPY bin-on-docker/schematic-diff.sh /opt/diff-boards/
