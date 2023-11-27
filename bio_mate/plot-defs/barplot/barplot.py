"""
barplot.py

绘制柱状图

Author: Zehua Zeng
Mail: starlitnightly@163.com
"""
import subprocess
import sys

def check_and_install_seaborn():
    try:
        import seaborn
        print(f"seaborn version {seaborn.__version__} is already installed.")
    except ImportError:
        print("seaborn is not installed. Attempting to install...")
        try:
            index_url = "https://pypi.tuna.tsinghua.edu.cn/simple"  # 指定pip的镜像源
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--index-url", index_url, "seaborn"])
            print(f"seaborn installed successfully using index-url: {index_url}")
        except Exception as e:
            print(f"Error installing seaborn: {e}")
            sys.exit(1)
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
check_and_install_seaborn()
check_and_install_scanpy()

import argparse
import json
import matplotlib.pyplot as plt
import pandas as pd
import scanpy as sc
import seaborn as sns

red_color=['#F0C3C3','#E07370','#CB3E35','#A22E2A','#5A1713','#D3396D','#DBC3DC','#85539B','#5C2B80','#5C4694']
green_color=['#91C79D','#8FC155','#56AB56','#2D5C33','#BBCD91','#6E944A','#A5C953','#3B4A25','#010000']
orange_color=['#EFBD49','#D48F3E','#AC8A3E','#7D7237','#745228','#E1C085','#CEBC49','#EBE3A1','#6C6331','#8C9A48','#D7DE61']
blue_color=['#347862','#6BBBA0','#81C0DD','#3E8CB1','#88C8D2','#52B3AD','#265B58','#B2B0D4','#5860A7','#312C6C']

def read(path,**kwargs):
    """
    读取文件函数

    Parameters
    ----------
    path : str
        文件路径
    **kwargs :
        其他参数参考`pandas.read_csv`、`pandas.read_excel`、`scanpy.read`等函数
    
    """
    import scanpy as sc
    import pandas as pd
    if path.split('.')[-1]=='h5ad':
        return sc.read(path,**kwargs)
    elif path.split('.')[-1]=='csv':
        return pd.read_csv(path,**kwargs)
    elif path.split('.')[-1]=='tsv' or path.split('.')[-1]=='txt':
        return pd.read_csv(path,sep='\t',**kwargs)
    elif path.split('.')[-1]=='xlsx':
        return pd.read_excel(path,**kwargs)
    elif path.split('.')[-1]=='gz':
        if path.split('.')[-2]=='csv':
            return pd.read_csv(path,**kwargs)
        elif path.split('.')[-2]=='tsv' or path.split('.')[-2]=='txt':
            return pd.read_csv(path,sep='\t',**kwargs)
    else:
        raise ValueError('The type is not supported.')

def plot_barplot(config_file, output_file):
    """
    绘制条形图

    Parameters
    ----------
    config_file : str
        配置文件路径
    output_file : str
        输出文件路径
    """
    # 读取配置文件
    with open(config_file, 'r') as json_file:
        config = json.load(json_file)

    # 解析配置文件中的数据
    data_file_path = config['dataFile']['dataFilePath']

    #数据参数设置
    x=config['columns']['x']
    y=config['columns']['y']


    #绘图参数设置
    fontsize=int(config['plot_settings']['fontsize'])
    xlabels=config['plot_settings']['xlabels']
    ylabels=config['plot_settings']['ylabels']
    width=float(config['plot_settings']['width'])
    color=config['plot_settings']['color']


    #通用设置
    title=config['general']['title']
    alpha=float(config['general']['alpha'])



    data=read(data_file_path)
    print(data.head())
    # Draw a nested boxplot to show bills by day and time
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(4,4))
    #print(data[x],data[y],width,color,log,alpha)
    ax.bar(x=data[x],
       height=data[y],
       width=width,
       color=color, 
       alpha=alpha
      )
    sns.despine(offset=10, trim=True)
    plt.xticks(fontsize=fontsize)
    plt.yticks(fontsize=fontsize)
    plt.xlabel(xlabels,fontsize=fontsize+1)
    plt.ylabel(ylabels,fontsize=fontsize+1)
    # 保存绘图结果
    plt.title(title,fontsize=fontsize+1)
    print('Saving figure to {}...'.format(output_file))
    plt.savefig(output_file,dpi=300,bbox_inches='tight')
    

if __name__ == "__main__":
    # 使用 argparse 解析命令行参数
    parser = argparse.ArgumentParser(description='Generate volcano plot based on configuration file.')
    parser.add_argument('action', choices=['plot'], help='Action to perform')
    parser.add_argument('--config', required=True, help='Path to the configuration file')
    parser.add_argument('--output', required=True, help='Path to the output file')

    args = parser.parse_args()

    # 根据命令行参数执行相应的操作
    if args.action == 'plot':
        plot_barplot(args.config, args.output)
    else:
        print('Invalid action. Use "plot" to generate a volcano plot.')

