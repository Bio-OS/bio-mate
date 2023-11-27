"""
embedding.py

单细胞降维可视化

Author: Zehua Zeng
Mail: starlitnightly@163.com
"""
import subprocess
import sys

def check_and_install_scanpy():
    try:
        import scanpy
        print(f"scanpy version {scanpy.__version__} is already installed.")
    except ImportError:
        print("scanpy is not installed. Attempting to install...")
        try:
            index_url = "https://pypi.tuna.tsinghua.edu.cn/simple"  # 指定pip的镜像源
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--index-url", index_url, "scanpy"])
            print(f"scanpy installed successfully using index-url: {index_url}")
        except Exception as e:
            print(f"Error installing scanpy: {e}")
            sys.exit(1)

# 在脚本的最上方调用这个函数
check_and_install_scanpy()

import argparse
import json
import matplotlib.pyplot as plt
import pandas as pd
import scanpy as sc

red_color=['#F0C3C3','#E07370','#CB3E35','#A22E2A','#5A1713','#D3396D','#DBC3DC','#85539B','#5C2B80','#5C4694']
green_color=['#91C79D','#8FC155','#56AB56','#2D5C33','#BBCD91','#6E944A','#A5C953','#3B4A25','#010000']
orange_color=['#EFBD49','#D48F3E','#AC8A3E','#7D7237','#745228','#E1C085','#CEBC49','#EBE3A1','#6C6331','#8C9A48','#D7DE61']
blue_color=['#347862','#6BBBA0','#81C0DD','#3E8CB1','#88C8D2','#52B3AD','#265B58','#B2B0D4','#5860A7','#312C6C']


def plot_embedding(config_file, output_file):
    # 读取配置文件
    with open(config_file, 'r') as json_file:
        config = json.load(json_file)

    # 解析配置文件中的数据
    data_file_path = config['dataFile']['dataFilePath']
    # 在这里添加其他需要的解析步骤...
    basis=config['plot_settings']['basis']
    color=config['plot_settings']['color']
    cmap=config['plot_settings']['cmap']
    fontsize=int(config['plot_settings']['fontsize'])
    palette=[int(i) for i in config['plot_settings']['palette']]

    title=config['general']['title']
    Normalized=config['columns']['Normalized']
    if Normalized=='True':
        Normalized=True
    else:
        Normalized=False

    # 在这里编写绘制火山图的代码
    # 示例：使用matplotlib
    # 注意：这里只是一个示例，具体的绘图逻辑需要根据实际情况进行调整
    # 假设有一个函数 plot_volcano_data(data) 用于绘制火山图
    # 你需要根据实际情况定义该函数，并传递解析的数据进行绘制

    # data = 从数据文件中读取数据的逻辑，例如使用pandas读取CSV文件
    adata=sc.read(data_file_path)
    adata.layers['counts']=adata.X.copy()
    adata.var_names_make_unique()
    adata.obs_names_make_unique()
    if Normalized:
        sc.pp.normalize_total(adata, target_sum=1e4)
        sc.pp.log1p(adata) 

    print(adata)
    print(palette)
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(4,4))
    sc.pl.embedding(
        adata,
        basis=basis,
        color=color,
        title=title,
        frameon=False,
        #ncols=1,
        wspace=0.65,
        palette=red_color[palette[0]:palette[1]]+green_color[palette[2]:palette[3]]+orange_color[palette[4]:palette[5]]+blue_color[palette[6]:palette[7]],
        ax=ax,
        cmap=cmap,
        show=False
    )
    # plot_volcano_data(data)
    #print(data.head())
    # 保存绘图结果
    plt.title(title,fontsize=fontsize+1)
    print('Saving figure to {}...'.format(output_file))
    fig.savefig(output_file,dpi=300,bbox_inches='tight')
    #fig.show()

if __name__ == "__main__":
    # 使用 argparse 解析命令行参数
    parser = argparse.ArgumentParser(description='Generate volcano plot based on configuration file.')
    parser.add_argument('action', choices=['plot'], help='Action to perform')
    parser.add_argument('--config', required=True, help='Path to the configuration file')
    parser.add_argument('--output', required=True, help='Path to the output file')

    args = parser.parse_args()

    # 根据命令行参数执行相应的操作
    if args.action == 'plot':
        plot_embedding(args.config, args.output)
    else:
        print('Invalid action. Use "plot" to generate a volcano plot.')
