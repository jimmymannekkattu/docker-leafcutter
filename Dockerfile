# Set the base image
FROM ubuntu:20.04

# Set non-interactive mode for installation
ENV DEBIAN_FRONTEND=noninteractive

# Maintainer information
LABEL maintainer="Jimmy John Thomas <jimmymannekkattu@gmail.com>"
LABEL description="Image for use with LeafCutter https://github.com/davidaknowles/leafcutter"

RUN apt-get update && \
    apt-get install -y \
    apt-utils \
    build-essential \
    bash \
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
    libtbb-dev \
    libxt-dev \
    libsqlite3-dev \
    python3 \
    python3-pip \
    libharfbuzz-dev \
    libfribidi-dev \
    libfontconfig1-dev \
    lynx \
    evince \
    hisat2 \
    wget \
    libfreetype6-dev \
    libtiff5-dev \
    libjpeg-dev \
    zlib1g-dev && \
    apt-get clean

# Verify Python 3 installation
RUN python3 --version

########
# HTSlib
########
ENV HTSLIB_INSTALL_DIR=/opt/htslibA
ENV HTSLIB_VERSION="1.21"

WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 && \
    tar --bzip2 -xvf htslib-${HTSLIB_VERSION}.tar.bz2

WORKDIR /tmp/htslib-${HTSLIB_VERSION}
RUN ./configure --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/

WORKDIR /tmp
RUN rm -rf /tmp/*

##########
# Samtools
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
# Tabix
#######
RUN ln -s $HTSLIB_INSTALL_DIR/bin/tabix /usr/bin/tabix

##########
# Regtools
##########
WORKDIR /git
RUN git clone https://github.com/jimmymannekkattu/regtools.git && \
    cd regtools/ && \
    mkdir build && \
    cd build/ && \
    cmake .. && \
    make && \
    mkdir /opt/regtools/ && \
    mv regtools /opt/regtools/

#####
# R
#####
ENV R_INSTALL_DIR=/usr/local/
ENV R_VERSION="4.4.2"

RUN wget https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz && \
    tar -zxvf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ./configure --prefix=${R_INSTALL_DIR} --with-x=no --with-curl=/usr/bin/curl-config && \
    make && \
    make install

WORKDIR /git/
RUN git clone https://github.com/jimmymannekkattu/oneTBB.git

# Create binary directory for out-of-source build
RUN mkdir -p /git/oneTBB/build && cd /git/oneTBB/build && \
    cmake -DCMAKE_INSTALL_PREFIX=/tbb -DTBB_TEST=OFF /git/oneTBB

# Build the project
RUN cmake --build /git/oneTBB/build

# Install the library
RUN cmake --install /git/oneTBB/build

WORKDIR /git/
RUN git clone https://github.com/jimmymannekkattu/tbb.git

ENV CPLUS_INCLUDE_PATH=/git/oneTBB/include:$CPLUS_INCLUDE_PATH
ENV CPLUS_INCLUDE_PATH=/git/tbb/include:$CPLUS_INCLUDE_PATH

#########################
# R and Python packages
#########################
RUN R --vanilla -e 'install.packages(c("BiocManager", "remotes", "rstan", "ragg", "systemfonts", "rstantools"), repos = "http://cran.us.r-project.org")'

RUN R -e "install.packages('devtools', repos='https://cran.r-project.org')"
RUN R --vanilla -e 'devtools::install_version("BiocManager", version = "1.30.16", repos = "https://cloud.r-project.org")'
RUN R --vanilla -e 'BiocManager::install(c("Biobase", "DirichletMultinomial", "Hmisc"))'
RUN R --vanilla -e 'devtools::install_github("jimmymannekkattu/leafcutter/leafcutter")'
RUN R --vanilla -e 'remotes::install_github("jimmymannekkattu/leafviz")'

WORKDIR /git/

RUN git clone --recursive https://github.com/jimmymannekkattu/leafcutter.git && \
    git clone --recursive https://github.com/jimmymannekkattu/leafviz.git && \
    git clone --recursive https://github.com/jimmymannekkattu/devtools.git && \
    git clone --recursive https://github.com/jimmymannekkattu/hisat2.git && \
    git clone --recursive https://github.com/jimmymannekkattu/htslib.git && \
    git clone --recursive https://github.com/jimmymannekkattu/samtools.git && \
    git clone --recursive https://github.com/jimmymannekkattu/rstantools.git && \
    git clone --recursive https://github.com/jimmymannekkattu/htscodecs.git && \
    git clone --recursive https://github.com/jimmymannekkattu/RcppParallel.git && \
    git clone --recursive https://github.com/jimmymannekkattu/stan.git && \
    git clone --recursive https://github.com/jimmymannekkattu/math.git && \
    git clone --recursive https://github.com/jimmymannekkattu/cmdstan.git

# Update Stan within CmdStan
WORKDIR /git/cmdstan
RUN make stan-update

WORKDIR /git/hisat2
RUN make

# Set the entrypoint to a bash shell for further commands
ENTRYPOINT ["/bin/bash"]

CMD ["/bin/bash"]