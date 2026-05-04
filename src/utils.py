# =============================================================
# src/utils.py — Shared helper functions
# =============================================================
# Used across all notebooks. Import with:
#   import sys; sys.path.insert(0, str(REPO_ROOT / "src"))
#   from utils import load_config, save_tif, ...
# =============================================================

import pathlib
import yaml
import numpy as np
import rasterio
from rasterio.warp import calculate_default_transform, reproject, Resampling


def load_config(town: str, repo_root: pathlib.Path) -> dict:
    """Load town-specific config from config/<town>.yaml."""
    cfg_path = repo_root / "config" / f"{town}.yaml"
    with open(cfg_path) as f:
        return yaml.safe_load(f)


def save_tif(array: np.ndarray, path: pathlib.Path, meta: dict) -> None:
    """Write a numpy array to GeoTIFF using the given rasterio metadata."""
    m = meta.copy()
    m.update(dtype=rasterio.float32, count=1, nodata=-9999)
    arr = array.astype(np.float32)
    arr[np.isnan(arr)] = -9999
    path.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.open(path, "w", **m) as dst:
        dst.write(arr, 1)


def reproject_raster(src_path: pathlib.Path,
                     dst_path: pathlib.Path,
                     dst_crs: str,
                     resampling: Resampling = Resampling.bilinear,
                     ref_meta: dict = None) -> dict:
    """
    Reproject a raster to dst_crs, optionally snapping to ref_meta grid.
    Returns the output metadata dict.
    """
    with rasterio.open(src_path) as src:
        if ref_meta:
            transform = ref_meta["transform"]
            width     = ref_meta["width"]
            height    = ref_meta["height"]
        else:
            transform, width, height = calculate_default_transform(
                src.crs, dst_crs, src.width, src.height, *src.bounds
            )

        meta = src.meta.copy()
        meta.update(crs=dst_crs, transform=transform,
                    width=width, height=height,
                    dtype=rasterio.float32, nodata=-9999)

        dst_path.parent.mkdir(parents=True, exist_ok=True)
        with rasterio.open(dst_path, "w", **meta) as dst:
            reproject(
                source=rasterio.band(src, 1),
                destination=rasterio.band(dst, 1),
                src_transform=src.transform,
                src_crs=src.crs,
                dst_transform=transform,
                dst_crs=dst_crs,
                resampling=resampling,
            )
    return meta


def tif_to_asc(tif_path: pathlib.Path,
               asc_path: pathlib.Path,
               nodata_val: int = -9999,
               dtype=int) -> None:
    """Convert a single-band GeoTIFF to ESRI ASCII raster (.asc)."""
    with rasterio.open(tif_path) as ds:
        data   = ds.read(1)
        tr     = ds.transform
        nrows  = ds.height
        ncols  = ds.width
        xll    = tr.c
        yll    = tr.f - nrows * tr.a
        cs     = tr.a

    nd = ds.nodata if ds.nodata is not None else nodata_val
    data = np.where(data == nd, nodata_val, data)

    header = (
        f"ncols         {ncols}\n"
        f"nrows         {nrows}\n"
        f"xllcorner     {xll:.6f}\n"
        f"yllcorner     {yll:.6f}\n"
        f"cellsize      {cs:.6f}\n"
        f"NODATA_value  {nodata_val}\n"
    )

    asc_path.parent.mkdir(parents=True, exist_ok=True)
    with open(asc_path, "w") as f:
        f.write(header)
        np.savetxt(f, data.astype(dtype), fmt="%d" if dtype == int else "%.4f")
