from ipywidgets import DOMWidget
from traitlets import Bool, Unicode, Dict, Int
import json
import warnings
import subprocess

from bio_mate.defs import gen_data_url_img, get_img, list_files, prepare_plot_env

module_name = "bio-mate"
module_version = "1.0.0"


class BaseWidget(DOMWidget):
    _model_name = Unicode("BaseWidgetModel").tag(sync=True)
    _model_module = Unicode(module_name).tag(sync=True)
    _model_module_version = Unicode(module_version).tag(sync=True)

    _view_name = Unicode("BaseWidgetView").tag(sync=True)
    _view_module = Unicode(module_name).tag(sync=True)
    _view_module_version = Unicode(module_version).tag(sync=True)
    _view_count = Int(0).tag(sync=True)

    type = Unicode("").tag(sync=True)
    count = Int(100).tag(sync=True)
    all_defs = Dict().tag(sync=True)

    def handle_messages(self, widget, content: dict, buffers):
        reqId = content.get("reqId", "")
        method_name = content.get("method", "")

        if not reqId or not method_name:
            print(f"Invalid CommRequest: reqId: {reqId}-{method_name}")
            return

        if not hasattr(self, method_name):
            content["response"] = {"status": "failed", "msg": "NotImplementedError"}
            self.send(content)
            return

        func = getattr(self, method_name)
        func(content)

    def __init__(self, **kwargs):
        super(BaseWidget, self).__init__(**kwargs)

        # Assign keyword parameters to this object
        recognized_keys = dir(self.__class__)
        for key, value in kwargs.items():
            if key not in recognized_keys and f"_{key}" not in recognized_keys:
                warnings.warn(RuntimeWarning(f"Keyword parameter {key} not recognized"))
            setattr(self, key, value)

        # Attach the callback event handler
        self.on_msg(self.handle_messages)

    def getSampleImage(self, content: dict):
        content["response"] = {"status": "ok", "result": get_img(self.type)}
        self.send(content)

    def listFiles(self, content: dict):
        params = content["params"]
        files = list_files(params["path"])

        if not files:
            content["response"] = {"status": "failed", "msg": "Failed to list files"}
        else:
            content["response"] = {"status": "ok", "result": files}

        self.send(content)

    def genPlot(self, content: dict):
        params = content["params"]
        current_plot = prepare_plot_env(params)

        meta = self.all_defs[self.type]["meta"]
        output_img = current_plot / meta["output_img"]

        main_abs_path = self.all_defs[self.type]["main_abs_path"]
        run_args = [item.replace("{main}", main_abs_path) for item in meta["run"]]
        ret = subprocess.run(run_args, capture_output=True, cwd=str(current_plot))

        ret_info = {
            "returncode": ret.returncode,
            "stdout": ret.stdout.decode(),
            "stderr": ret.stderr.decode(),
            "args": ret.args,
        }

        if ret.returncode != 0:
            content["response"] = {
                "status": "failed",
                "msg": "执行失败",
                "extra": ret_info,
            }
            self.send(content)
            return

        if not output_img.exists():
            content["response"] = {
                "status": "failed",
                "msg": "未找到输出图形文件",
                "extra": ret_info,
            }
            self.send(content)
            return

        content["response"] = {
            "status": "ok",
            "result": gen_data_url_img(output_img),
            "extra": ret_info,
        }
        self.send(content)


class BaseWidget1(DOMWidget):
    """from: nbtools
    nbtools/nbtools/basewidget.py"""

    _model_name = Unicode("BaseWidgetModel").tag(sync=True)
    _model_module = Unicode(module_name).tag(sync=True)
    _model_module_version = Unicode(module_version).tag(sync=True)

    _view_name = Unicode("BaseWidgetView").tag(sync=True)
    _view_module = Unicode(module_name).tag(sync=True)
    _view_module_version = Unicode(module_version).tag(sync=True)
    _view_count = Int(0).tag(sync=True)

    _id = Unicode(sync=True)
    origin = Unicode("Notebook").tag(sync=True)
    name = Unicode("").tag(sync=True)
    subtitle = Unicode("").tag(sync=True)
    description = Unicode("").tag(sync=True)
    collapsed = Bool(False).tag(sync=True)
    color = Unicode("var(--jp-layout-color4)").tag(sync=True)
    logo = Unicode("").tag(sync=True)
    info = Unicode("", sync=True)
    error = Unicode("", sync=True)
    extra_menu_items = Dict(sync=True)

    def handle_messages(self, _, content, buffers):
        """Handle messages sent from the client-side"""
        if content.get("event", "") == "method":  # Handle method call events
            method_name = content.get("method", "")
            params = content.get("params", None)
            if method_name and hasattr(self, method_name) and not params:
                getattr(self, method_name)()
            elif method_name and hasattr(self, method_name) and params:
                try:
                    kwargs = json.loads(params)
                    getattr(self, method_name)(**kwargs)
                except json.JSONDecodeError:
                    pass

    def __init__(self, **kwargs):
        super(BaseWidget, self).__init__(**kwargs)

        # Assign keyword parameters to this object
        recognized_keys = dir(self.__class__)
        for key, value in kwargs.items():
            if key not in recognized_keys and f"_{key}" not in recognized_keys:
                warnings.warn(RuntimeWarning(f"Keyword parameter {key} not recognized"))
            setattr(self, key, value)

        # Attach the callback event handler
        self.on_msg(self.handle_messages)
