# mixscale-docker

Docker image for [Mixscale](https://github.com/satijalab/Mixscale), an R package for quantifying perturbation heterogeneity in Perturb-seq data.

Slim, minimal image for running mixscale in pipelines.

## What's in the image

- R 4.6.1 (`rocker/r-ver` base)
- Mixscale and all dependencies: Seurat, glmGamPoi, PMA, protoclust, ggridges, gplots
- OpenBLAS — R is linked against it so BLAS-level matrix operations in glmGamPoi (via RcppArmadillo) use all available cores automatically

## Threading

The image sets `OPENBLAS_NUM_THREADS=0` and `OMP_NUM_THREADS=0`, which tells OpenBLAS to auto-detect and use all available cores at runtime. You can override this per-run:

```bash
docker run --rm -e OPENBLAS_NUM_THREADS=4 <image> Rscript your_script.R
```

Note: glmGamPoi has no R-level parallelism API. Multi-threading occurs inside BLAS routines called by its RcppArmadillo C++ code. To parallelize across many guide RNAs or conditions, wrap calls with `parallel::mclapply` or `BiocParallel::bplapply` in your own script.

## Prerequisites

Two GitHub Actions secrets must be configured in the repository settings for GCP Workload Identity Federation:

| Secret | Description |
|---|---|
| `WIF_PROVIDER` | Full WIF provider resource name |
| `WIF_SERVICE_ACCOUNT` | Service account email with Artifact Registry write access |
| `GCP_PROJECT` | GCP project ID hosting the Artifact Registry |

## Building and pushing

**On release:** Create a GitHub Release — the build workflow triggers automatically and tags the image with the release tag and `latest`.

**Manual trigger:** Go to Actions → "Build and Push Docker Image" → Run workflow, and enter the version tag (e.g. `v1.2.3`). The provided tag is passed as the `VERSION` build arg and used to pin the Mixscale GitHub ref installed inside the image.

## Pulling and running

```bash
# Pull
docker pull us-central1-docker.pkg.dev/<GCP_PROJECT>/mixscale/mixscale:latest

# Run an R script
docker run --rm \
  -v /path/to/your/data:/data \
  us-central1-docker.pkg.dev/<GCP_PROJECT>/mixscale/mixscale:latest \
  Rscript /data/your_script.R
```

## Tests

The test workflow (`test.yml`) runs when a PR is made against `main`, or can be triggered manually. It:

1. Builds a local docker image
2. Verifies R is linked against OpenBLAS (`La_library()`)
3. Checks BLAS thread count via `RhpcBLASctl`
4. Loads Mixscale and all dependencies
5. Runs a glm_gp smoke test on a synthetic count matrix
