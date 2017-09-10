# Builds a Docker image with Ubuntu 16.04, FEniCS, Python3 and Jupyter Notebook
# for "AMS 529: Finite Element Methods" at Stony Brook University
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

# Use PETSc prebuilt in fastsolve/desktop
FROM fastsolve/desktop:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install system packages
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        git-lfs \
        gdb \
        ccache \
        libnss3 \
        doxygen \
        flex \
        \
        libomp-dev \
        libpcre3-dev \
        libhdf5-mpich-dev \
        libgmp-dev \
        libcln-dev \
        libmpfr-dev \
        \
        meld && \
    apt-get clean && \
    pip3 install -U \
        numpy \
        scipy \
        sympy \
        pandas \
        matplotlib \
        autopep8 \
        flake8 \
        PyQt5 \
        spyder && \
    ln -s -f /usr/local/bin/spyder3 /usr/local/bin/spyder && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Environment variables
ENV SLEPC_VERSION=3.7.4 \
    SWIG_VERSION=3.0.12 \
    MPI4PY_VERSION=2.0.0 \
    PETSC4PY_VERSION=3.7.0 \
    SLEPC4PY_VERSION=3.7.0

# Install SLEPc from source
RUN wget -nc --quiet https://bitbucket.org/slepc/slepc/get/v${SLEPC_VERSION}.tar.gz -O slepc-${SLEPC_VERSION}.tar.gz && \
    mkdir -p slepc-src && tar -xf slepc-${SLEPC_VERSION}.tar.gz -C slepc-src --strip-components 1 && \
    cd slepc-src && \
    ./configure --prefix=/usr/local/slepc-${SLEPC_VERSION} && \
    make && \
    make install && \
    rm -rf /tmp/*

ENV SLEPC_DIR=/usr/local/slepc-${SLEPC_VERSION}

# Install mpi4py, petsc4py, slepc4py and Swig from source.
RUN pip3 install --no-cache-dir https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-${MPI4PY_VERSION}.tar.gz && \
    pip3 install --no-cache-dir https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-${PETSC4PY_VERSION}.tar.gz && \
    pip3 install --no-cache-dir https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-${SLEPC4PY_VERSION}.tar.gz && \
    wget -nc --quiet http://downloads.sourceforge.net/swig/swig-${SWIG_VERSION}.tar.gz -O swig-${SWIG_VERSION}.tar.gz && \
    tar -xf swig-${SWIG_VERSION}.tar.gz && \
    cd swig-${SWIG_VERSION} && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/*

########################################################
# Customization for user
########################################################

ADD image/home $DOCKER_HOME

USER $DOCKER_USER
ENV GIT_EDITOR=vi EDITOR=vi
RUN echo 'export OMP_NUM_THREADS=$(nproc)' >> $DOCKER_HOME/.profile && \
    sed -i '/octave/ d' $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "PATH=$DOCKER_HOME/bin:$PATH" >> $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME
USER root
