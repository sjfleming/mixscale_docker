ARG R_VERSION=4.6.1
FROM rocker/r-ver:${R_VERSION}

ARG VERSION=main

# System libraries required by Seurat and its dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libhdf5-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libglpk-dev \
    libgsl-dev \
    libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# OpenBLAS auto-detects cores during build and runtime (0 = auto-detect, valid for OpenBLAS)
ENV OPENBLAS_NUM_THREADS=0

# Use Posit Package Manager for pre-built Linux binaries — avoids compiling Seurat/RcppEigen from source
RUN Rscript -e "\
    options( \
        repos = c(PPM = 'https://packagemanager.posit.co/cran/__linux__/noble/latest', \
                  CRAN = 'https://cloud.r-project.org'), \
        warn = 2 \
    ); \
    install.packages(c('BiocManager', 'remotes', 'RhpcBLASctl'), Ncpus = parallel::detectCores()); \
    "

RUN Rscript -e "\
    options( \
        repos = c(PPM = 'https://packagemanager.posit.co/cran/__linux__/noble/latest', \
                  CRAN = 'https://cloud.r-project.org'), \
        warn = 2 \
    ); \
    install.packages(c('Seurat', 'PMA', 'protoclust', 'ggridges', 'gplots'), \
        Ncpus = parallel::detectCores()); \
    "

RUN Rscript -e "\
    options( \
        repos = c(PPM = 'https://packagemanager.posit.co/cran/__linux__/noble/latest', \
                  CRAN = 'https://cloud.r-project.org'), \
        warn = 2 \
    ); \
    BiocManager::install('glmGamPoi', ask = FALSE, update = FALSE); \
    "

RUN Rscript -e "\
    options(warn = 2); \
    remotes::install_github('satijalab/Mixscale', ref = Sys.getenv('VERSION', unset = 'main')); \
    " \
    VERSION=${VERSION}

# Set OpenMP thread count for runtime use only — value 0 is invalid during build (libgomp rejects it)
ENV OMP_NUM_THREADS=0
