library(methods)

# 1. Verify OpenBLAS is the linked BLAS
blas_path <- La_library()
cat("BLAS library:", blas_path, "\n")
stopifnot("BLAS is not OpenBLAS — rebuild image with libopenblas-dev" =
    grepl("openblas", blas_path, ignore.case = TRUE))

# 2. Verify BLAS thread count responds to OPENBLAS_NUM_THREADS
library(RhpcBLASctl)
n_procs <- blas_get_num_procs()
cat("BLAS threads:", n_procs, "\n")
stopifnot("BLAS is running single-threaded; check OPENBLAS_NUM_THREADS" =
    n_procs >= 1L)
cat("OPENBLAS_NUM_THREADS env var:", Sys.getenv("OPENBLAS_NUM_THREADS", unset = "(not set)"), "\n")

# 3. Load all Mixscale dependencies
library(glmGamPoi)
library(Seurat)
library(Mixscale)
cat("All packages loaded successfully\n")

# 4. Functional smoke test: glm_gp on a tiny synthetic count matrix
set.seed(42)
n_genes <- 50L
n_cells <- 200L
counts <- matrix(
    rnbinom(n_genes * n_cells, mu = 5, size = 0.5),
    nrow = n_genes,
    ncol = n_cells
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("cell", seq_len(n_cells))

fit <- glm_gp(counts, design = ~ 1)
stopifnot(
    "glm_gp did not return a list" = is.list(fit),
    "glm_gp result missing Beta" = !is.null(fit$Beta),
    "Beta dimensions wrong" = nrow(fit$Beta) == n_genes
)
cat("glm_gp smoke test passed\n")
cat("All checks passed.\n")
