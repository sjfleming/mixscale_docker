library(methods)
library(RhpcBLASctl)

# 1. Verify OpenBLAS is the linked BLAS
blas_path <- La_library()
cat("BLAS library:", blas_path, "\n")
stopifnot("BLAS is not OpenBLAS — rebuild image with libopenblas-dev" =
    grepl("openblas", blas_path, ignore.case = TRUE))

# 2. Verify OpenBLAS spawns worker threads (kernel-level observation)
# Trigger thread pool creation with a small BLAS call, then read /proc
m_small <- matrix(rnorm(100 * 100), nrow = 100)
invisible(crossprod(m_small))

proc_status <- readLines(sprintf("/proc/%d/status", Sys.getpid()))
threads_line <- grep("^Threads:", proc_status, value = TRUE)
n_threads <- as.integer(sub("Threads:\\s+", "", threads_line))
cat("OS thread count after BLAS call:", n_threads, "\n")
stopifnot("OpenBLAS did not spawn worker threads — threading is not active" =
    n_threads > 1L)

# 3. Verify threading produces a real speedup (timed comparison)
# Force single-threaded, time the solve, then restore full threads and time again.
# Test the ratio, not the absolute time, so it works on any hardware.
m <- matrix(rnorm(3000 * 3000), nrow = 3000)

blas_set_num_threads(1L)
t_single <- system.time(solve(m))["elapsed"]
cat(sprintf("Single-threaded solve: %.2fs\n", t_single))

n_cores <- parallel::detectCores()
blas_set_num_threads(n_cores)
t_multi <- system.time(solve(m))["elapsed"]
cat(sprintf("Multi-threaded solve (%d cores): %.2fs\n", n_cores, t_multi))

speedup <- t_single / t_multi
cat(sprintf("Speedup: %.2fx\n", speedup))
stopifnot("OpenBLAS speedup < 1.3x — multi-threading may not be working" =
    speedup > 1.3)

# 4. Load all Mixscale dependencies
library(glmGamPoi)
library(Seurat)
library(Mixscale)
cat("All packages loaded successfully\n")

# 5. Functional smoke test: glm_gp on a tiny synthetic count matrix
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
