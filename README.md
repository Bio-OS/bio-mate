# bio-mate

A JupyterLab extension.

## 开发调试 与 打包

### 建立初始环境

```bash
# 使用 conda 建立初始环境
conda create -n jl3-ext -y --override-channels --strict-channel-priority \
	-c conda-forge jupyterlab=3 ipywidgets=7 nodejs=18
```

### 开发调试

```bash
# 一个 terminal 运行
jupyter lab

# 另一个 terminal 运行
jlpm watch
```

### 打包生成 whl 文件

```bash
# 首先安装 build
pip install build

# 将会在 dist 文件夹生成 .whl package
python -m build
```

## Install

To install the extension, execute:

```bash
pip install bio_mate
```

## Uninstall

To remove the extension, execute:

```bash
pip uninstall bio_mate
```

## Contributing

### Development install

Note: You will need NodeJS to build the extension package.

The `jlpm` command is JupyterLab's pinned version of
[yarn](https://yarnpkg.com/) that is installed with JupyterLab. You may use
`yarn` or `npm` in lieu of `jlpm` below.

```bash
# Clone the repo to your local environment
# Change directory to the bio_mate directory
# Install package in development mode
pip install -e "."
# Link your development version of the extension with JupyterLab
jupyter labextension develop . --overwrite
# Rebuild extension Typescript source after making changes
jlpm build
```

You can watch the source directory and run JupyterLab at the same time in different terminals to watch for changes in the extension's source and automatically rebuild the extension.

```bash
# Watch the source directory in one terminal, automatically rebuilding when needed
jlpm watch
# Run JupyterLab in another terminal
jupyter lab
```

With the watch command running, every saved change will immediately be built locally and available in your running JupyterLab. Refresh JupyterLab to load the change in your browser (you may need to wait several seconds for the extension to be rebuilt).

By default, the `jlpm build` command generates the source maps for this extension to make it easier to debug using the browser dev tools. To also generate source maps for the JupyterLab core extensions, you can run the following command:

```bash
jupyter lab build --minimize=False
```

### Development uninstall

```bash
pip uninstall bio_mate
```

In development mode, you will also need to remove the symlink created by `jupyter labextension develop`
command. To find its location, you can run `jupyter labextension list` to figure out where the `labextensions`
folder is located. Then you can remove the symlink named `bio-mate` within that folder.

### Packaging the extension

See [RELEASE](RELEASE.md)
