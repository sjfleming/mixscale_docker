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

# Use all cores for BLAS operations at runtime (0 = auto-detect)
ENV OPENBLAS_NUM_THREADS=0
ENV OMP_NUM_THREADS=0

# Use a fast CRAN mirror and install packages without recommended extras
RUN Rscript -e "\
    options(repos = c(CRAN = 'https://cloud.r-project.org'), warn = 2); \
    install.packages(c('BiocManager', 'remotes', 'RhpcBLASctl'), Ncpus = parallel::detectCores()); \
    "

RUN Rscript -e "\
    options(repos = c(CRAN = 'https://cloud.r-project.org'), warn = 2); \
    install.packages(c('Seurat', 'PMA', 'protoclust', 'ggridges', 'gplots'), \
        Ncpus = parallel::detectCores()); \
    "

RUN Rscript -e "\
    options(warn = 2); \
    BiocManager::install('glmGamPoi', ask = FALSE, update = FALSE); \
    "

RUN Rscript -e "\
    options(warn = 2); \
    remotes::install_github('satijalab/Mixscale', ref = Sys.getenv('VERSION', unset = 'main')); \
    " \
    VERSION=${VERSION}
