FROM ubuntu:latest
LABEL Jimmy John Thomas <jimmymannekkattu@gmail.com>

LABEL \
    description="Image for use with LeafCutter https://github.com/davidaknowles/leafcutter"

RUN apt-get update && \
    apt-get install -y \
    apt-utils \
    build-essential \
    r-base-dev \
    vim \
    bzip2 \
    cmake \
    gcc \
    gfortran \
    git \
    curl \
    texlive \ 
    texinfo \
    texlive-latex-extra \
    libcurl4-openssl-dev \
    libbz2-dev \
    libgsl-dev \
    libjpeg-dev \
    liblzma-dev \
    libpcre2-dev \
    libpng-dev \
    libreadline-dev \
    libssl-dev \
    libv8-dev \
    libxml2-dev \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libtbb-dev \
    libxml2-dev \
    zlib1g-dev \
    gfortran \
    libreadline-dev \
    libxt-dev \
    libpcre2-dev \
    make \
    cmake \
    locate \
    ncurses-dev \
    libssl-dev \
    wget \
    build-essential \
    libbz2-dev \
    libsqlite3-dev \
    python3 \
    python3-pip \
    libharfbuzz-dev \
    libfribidi-dev \
    libfontconfig1-dev \
    lynx \
    evince \
    hisat2 \
    libxml2-dev \
    gfortran \
    libreadline-dev \
    libxt-dev \
    libpcre2-dev \  
    libssl-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    zlib1g-dev && \
    apt-get clean

# Verify Python 3 installation
RUN python3 --version

########
#HTSlib#
########
ENV HTSLIB_INSTALL_DIR=/opt/htslibA
ENV HTSLIB_VERSION="1.21"

WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 && \
    tar --bzip2 -xvf htslib-${HTSLIB_VERSION}.tar.bz2

WORKDIR /tmp/htslib-${HTSLIB_VERSION}
RUN ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/
WORKDIR /tmp
RUN rm -rf /tmp/*

##########
#Samtools#
##########
ENV SAMTOOLS_INSTALL_DIR=/opt/samtools
ENV SAMTOOLS_VERSION="1.21"
RUN wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 && \
    tar --bzip2 -xf samtools-${SAMTOOLS_VERSION}.tar.bz2

WORKDIR /tmp/samtools-${SAMTOOLS_VERSION}
RUN ./configure --with-htslib=$HTSLIB_INSTALL_DIR --prefix=$SAMTOOLS_INSTALL_DIR && \
    make && \
    make install

WORKDIR /
RUN rm -rf /tmp/*

#######
#tabix#
#######
RUN ln -s $HTSLIB_INSTALL_DIR/bin/tabix /usr/bin/tabix

##########
#Regtools#
##########
WORKDIR /git/regtools
RUN git clone https://github.com/jimmymannekkattu/regtools.git && \
    cd regtools/ && \
    mkdir build && \
    cd build/ && \
    cmake .. && \
    make && \
    mkdir /opt/regtools/ && \
    mv regtools /opt/regtools/

#####
# R #
#####
ENV R_INSTALL_DIR=/usr/local/
ENV R_VERSION="4.4.2"

RUN wget https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz && \
    tar -zxvf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ./configure --prefix=${R_INSTALL_DIR} --with-x=no  --with-curl=/usr/bin/curl-config && \
    make && \
    make install

WORKDIR /git/
RUN git clone https://github.com/jimmymannekkattu/oneTBB.git

# Create binary directory for out-of-source build
RUN mkdir -p /git/oneTBB/build && cd /git/oneTBB/build \
    && cmake -DCMAKE_INSTALL_PREFIX=/tbb -DTBB_TEST=OFF /git/oneTBB

# Build the project
RUN cmake --build /git/oneTBB/build

# Install the library
RUN cmake --install /git/oneTBB/build

WORKDIR /git/
RUN git clone https://github.com/jimmymannekkattu/tbb.git

ENV CPLUS_INCLUDE_PATH=/git/oneTBB/include:$CPLUS_INCLUDE_PATH
ENV CPLUS_INCLUDE_PATH=/git/tbb/include:$CPLUS_INCLUDE_PATH

#########################
# R and python packages #
#########################
RUN R --vanilla -e 'install.packages(c("BiocManager", "remotes", "rstan", "ragg", "systemfonts"), repos = "http://cran.us.r-project.org")'

RUN R -e "install.packages('devtools', repos='https://cran.r-project.org')"
#RUN R -e 'devtools::install_version("BiocManager", version = "1.30.16", repos = "http://cran.us.r-project.org")'
#RUN R --vanilla -e 'install.packages(c("BiocManager"), repos = "http://cran.us.r-project.org")'
RUN R --vanilla -e 'devtools::install_version("BiocManager", version = "1.30.16", repos = "https://cloud.r-project.org")'
RUN R --vanilla -e 'BiocManager::install(c("Biobase", "DirichletMultinomial", "Hmisc"))'
RUN R --vanilla -e 'devtools::install_github("jimmymannekkattu/leafcutter/leafcutter")'
RUN R --vanilla -e 'remotes::install_github("jimmymannekkattu/leafviz")'

WORKDIR /git/
RUN git clone https://github.com/jimmymannekkattu/leafcutter.git
RUN git clone https://github.com/jimmymannekkattu/leafviz.git
RUN git clone https://github.com/jimmymannekkattu/devtools.git
RUN git clone https://github.com/jimmymannekkattu/hisat2.git
RUN git clone https://github.com/jimmymannekkattu/htslib.git
RUN git clone --recursive https://github.com/jimmymannekkattu/samtools.git
RUN git clone --recursive https://github.com/jimmymannekkattu/rstantools.git
RUN git clone --recursive https://github.com/jimmymannekkattu/htscodecs.git
RUN git clone --recursive https://github.com/jimmymannekkattu/RcppParallel.git
RUN git clone --recursive https://github.com/jimmymannekkattu/stan.git
RUN git clone --recursive https://github.com/jimmymannekkattu/math.git
RUN git clone --recursive https://github.com/jimmymannekkattu/cmdstan.git



WORKDIR /

