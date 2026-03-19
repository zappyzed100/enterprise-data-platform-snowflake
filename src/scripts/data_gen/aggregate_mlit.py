"""国土交通省 位置参照情報 (mlit) CSVを統合する前処理スクリプト。

data/01_raw/mlint/ 配下の a 形式フォルダ内に存在するCSV(SJIS)を読み込み、
以下の成果物を data/02_intermediate/mlit/ に出力する。

    mlit_a.csv       : a 形式CSVの統合結果
    mlit_columns.csv : 元CSVごとのヘッダー列一覧

抽出列:
    市区町村名, 大字・丁目名, 小字・通称名, 緯度, 経度
"""

import csv
from pathlib import Path

RAW_DIR = Path(__file__).parents[3] / "data" / "01_raw" / "mlint"
OUT_DIR = Path(__file__).parents[3] / "data" / "02_intermediate" / "mlit"

OUT_HEADER = ["市区町村名", "大字・丁目名", "小字・通称名", "緯度", "経度"]
COLUMN_INVENTORY_HEADER = ["folder_name", "csv_name", "column_index", "column_name"]
REQUIRED_SOURCE_COLUMNS = OUT_HEADER.copy()


def iter_source_csvs() -> list[tuple[Path, Path]]:
    """a 形式の元CSV一覧を返す。"""
    source_csvs: list[tuple[Path, Path]] = []
    for folder in sorted(RAW_DIR.iterdir()):
        if not folder.is_dir():
            continue
        if not folder.name.endswith("a"):
            continue
        csv_files = sorted(folder.glob("*.csv"))
        if not csv_files:
            continue
        source_csvs.append((folder, csv_files[0]))
    return source_csvs


def resolve_extract_columns(header: list[str], csv_path: Path) -> list[int] | None:
    """a 形式CSVの必要列番号をヘッダー名から解決する。"""
    header_index = {column.strip(): index for index, column in enumerate(header)}
    resolved_indices: list[int] = []

    for column_name in REQUIRED_SOURCE_COLUMNS:
        if column_name not in header_index:
            print(
                "  必要列が見つかりません: "
                f"{csv_path.relative_to(RAW_DIR)} / {column_name}"
            )

            return None

        resolved_indices.append(header_index[column_name])

    return resolved_indices


def iter_rows() -> list[list[str]]:
    """mlint配下のa形式CSVを走査し、必要列だけを返す。"""
    rows: list[list[str]] = []
    for _, csv_path in iter_source_csvs():
        with open(csv_path, encoding="cp932", newline="") as f:
            reader = csv.reader(f)
            header = next(reader, [])
            extract_cols = resolve_extract_columns(header, csv_path)
            if extract_cols is None:
                continue

            for row in reader:
                if len(row) <= max(extract_cols):
                    continue
                rows.append([row[col_index].strip() for col_index in extract_cols])
    return rows


def build_column_inventory() -> None:
    """元CSVごとのヘッダー列一覧をCSVとして出力する。"""
    rows: list[list[str]] = []

    for folder, csv_path in iter_source_csvs():
        with open(csv_path, encoding="cp932", newline="") as f:
            reader = csv.reader(f)
            header = next(reader, [])

        for index, column_name in enumerate(header, start=1):
            rows.append(
                [
                    folder.name,
                    csv_path.name,
                    str(index),
                    column_name.strip(),
                ]
            )

    path = OUT_DIR / "mlit_columns.csv"
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(COLUMN_INVENTORY_HEADER)
        writer.writerows(rows)

    print(
        f"  書き込み完了: {path.relative_to(Path(__file__).parents[3])}  ({len(rows):,} 行)"
    )


def write_csv(path: Path, rows: list[list[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(OUT_HEADER)
        writer.writerows(rows)
    print(
        f"  書き込み完了: {path.relative_to(Path(__file__).parents[3])}  ({len(rows):,} 行)"
    )


def build_mlit_intermediates() -> None:
    """a形式の統合CSVと列一覧CSVを生成する。"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("mlit統合CSVを生成中...")

    rows = iter_rows()
    write_csv(OUT_DIR / "mlit_a.csv", rows)

    build_column_inventory()

    print("完了")


if __name__ == "__main__":
    build_mlit_intermediates()
