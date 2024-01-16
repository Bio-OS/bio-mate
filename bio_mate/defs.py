from datetime import datetime
from pathlib import Path
import json
import base64

current_file = Path(__file__)
plot_defs = current_file.parents[0] / "plot-defs"


def get_init_path():
    """选择数据文件时，初始路径"""
    return str(Path.home()) + "/"


all_defs = {"BIOMATE_CONFIG": {"init_path": get_init_path()}}
for dir_plot in plot_defs.iterdir():
    if dir_plot.name.startswith(".") or dir_plot.is_file():
        continue

    all_defs[dir_plot.name] = {
        "meta": json.loads((dir_plot / "meta.json").read_bytes()),
        "ui": json.loads((dir_plot / "ui.json").read_bytes()),
        "input": json.loads((dir_plot / "input.json").read_bytes()),
        "sample_img": "",
        "sample_data_file": "",
        "main_abs_path": "",
    }

    meta = all_defs[dir_plot.name]["meta"]

    sample_data_file = meta["sample_data_file"]
    all_defs[dir_plot.name]["sample_data_file"] = str(dir_plot / sample_data_file)

    main_file_name = meta["main"]
    all_defs[dir_plot.name]["main_abs_path"] = str(dir_plot / main_file_name)


def get_img(type):
    img_data_url = all_defs[type]["sample_img"]
    if img_data_url:
        return img_data_url

    img_name = all_defs[type]["meta"]["sample_img"]
    if not img_name:
        return

    img_path = plot_defs / type / img_name
    data_url = gen_data_url_img(img_path)

    all_defs[type]["sample_img"] = data_url

    return data_url


def gen_data_url_img(img_path: Path):
    base64_utf8_str = base64.b64encode(img_path.read_bytes()).decode("utf-8")
    ext = str(img_path).split(".")[-1]
    data_url = f"data:image/{ext};base64,{base64_utf8_str}"

    return data_url


def list_files(path: str):
    custom_path = Path(path)

    if not custom_path.exists():
        print(f"{path} not exists")
        return

    return [
        {"name": item.name, "is_dir": item.is_dir()} for item in custom_path.iterdir()
    ]


def prepare_plot_env(params: dict):
    now = datetime.utcnow()
    time_str = now.strftime("%Y%m%d_%H%M%S_%f")

    current_plot = current_file.parent / "log_plot" / time_str
    current_plot.mkdir(exist_ok=True, parents=True)

    input_json = current_plot / "input.json"
    input_json.write_text(json.dumps(params, indent=2))

    return current_plot
