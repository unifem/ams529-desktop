# Builds a Docker image with Ubuntu 16.04, Python 3, FEniCS, and Jupyter Notebook
# for multiphysics coupling
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
        libnss3 \
        doxygen \
        flex \
        imagemagick \
        \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-math-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        libeigen3-dev \
        libomp-dev \
        libpcre3-dev \
        \
        libgmp-dev \
        libcln-dev \
        libmpfr-dev \
        \
        libhdf5-mpich-dev \
        libnetcdf-dev \
        metis \
        \
        tk-dev \
        libglu1-mesa-dev \
        libxmu-dev \
        \
        meld && \
    apt-get clean && \
    pip3 install -U \
        numpy \
        scipy \
        sympy \
        pandas \
        matplotlib \
        flufl.lock \
        ply \
        pytest \
        autopep8 \
        flake8 \
        PyQt5 \
        spyder && \
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
    cd /tmp && \
    rm -rf /tmp/*

# Install CGNS
RUN mkdir /usr/local/hdf5 && \
    ln -s -f /usr/include/hdf5/mpich /usr/local/hdf5/include && \
    ln -s -f /usr/lib/x86_64-linux-gnu/hdf5/mpich /usr/local/hdf5/lib  && \
    git clone --depth=1 -b master https://github.com/CGNS/CGNS.git && \
    cd CGNS/src && \
    export LIBS="-Wl,--no-as-needed -ldl -lz -lsz -lpthread" && \
    ./configure --enable-64bit --with-zlib --with-hdf5=/usr/local/hdf5 \
        --enable-cgnstools --enable-lfs && \
    sed -i 's/TKINCS =/TKINCS = -I\/usr\/include\/tcl/' cgnstools/make.defs && \
    make && \
    make install && \
    rm -rf /tmp/CGNS

ADD image/home $DOCKER_HOME

# Build FEniCS with Python3
ENV FENICS_BUILD_TYPE=Release \
    FENICS_PREFIX=/usr/local \
    FENICS_VERSION=2017.1.0 \
    FENICS_PYTHON=python3

RUN FENICS_SRC_DIR=/tmp/src $DOCKER_HOME/bin/fenics-pull && \
    FENICS_SRC_DIR=/tmp/src $DOCKER_HOME/bin/fenics-build && \
    ldconfig && \
    rm -f $DOCKER_HOME/bin/fenics-*

ENV PYTHONPATH=$FENICS_PREFIX/lib/python3/dist-packages:$PYTHONPATH

########################################################
# Customization for user
########################################################

USER $DOCKER_USER
ENV GIT_EDITOR=vi EDITOR=vi
RUN echo 'export OMP_NUM_THREADS=$(nproc)' >> $DOCKER_HOME/.profile && \
    sed -i '/octave/ d' $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "@spyder" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    cp -r $FENICS_PREFIX/share/dolfin/demo $DOCKER_HOME/fenics-demo && \
    echo "PATH=$DOCKER_HOME/bin:/usr/local/bin/cgnstools:$PATH" >> $DOCKER_HOME/.profile && \
    echo "alias python=python3" >> $DOCKER_HOME/.profile && \
    echo "alias ipython=ipython3" >> $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME
USER root
