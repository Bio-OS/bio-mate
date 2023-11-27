"""
annotation.py

绘制核密度图

Author: Zehua Zeng
Mail: starlitnightly@163.com

"""

import subprocess
import sys
import omicverse as ov

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

def check_and_install_omicverse():
    try:
        import omicverse
        print(f"omicverse version {omicverse.__version__} is already installed.")
    except ImportError:
        print("omicverse is not installed. Attempting to install...")
        try:
            index_url = "https://pypi.tuna.tsinghua.edu.cn/simple"  # 指定pip的镜像源
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--index-url", index_url, "omicverse"])
            print(f"omicverse installed successfully using index-url: {index_url}")
        except Exception as e:
            print(f"Error installing omicverse: {e}")
            sys.exit(1)

def check_and_install_torch_geo():
    try:
        import torch_geometric
        print(f"torch_geometric version {torch_geometric.__version__} is already installed.")
    except ImportError:
        print("torch_geometric is not installed. Attempting to install...")
        try:
            index_url = "https://pypi.tuna.tsinghua.edu.cn/simple"  # 指定pip的镜像源
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--index-url", index_url, "torch_geometric"])
            print(f"torch_geometric installed successfully using index-url: {index_url}")
        except Exception as e:
            print(f"Error installing torch_geometric: {e}")
            sys.exit(1)

# 在脚本的最上方调用这个函数
check_and_install_scanpy()
check_and_install_torch_geo()
check_and_install_omicverse()


import argparse
import json
import matplotlib.pyplot as plt
import pandas as pd
import scanpy as sc

red_color=['#F0C3C3','#E07370','#CB3E35','#A22E2A','#5A1713','#D3396D','#DBC3DC','#85539B','#5C2B80','#5C4694']
green_color=['#91C79D','#8FC155','#56AB56','#2D5C33','#BBCD91','#6E944A','#A5C953','#3B4A25','#010000']
orange_color=['#EFBD49','#D48F3E','#AC8A3E','#7D7237','#745228','#E1C085','#CEBC49','#EBE3A1','#6C6331','#8C9A48','#D7DE61']
blue_color=['#347862','#6BBBA0','#81C0DD','#3E8CB1','#88C8D2','#52B3AD','#265B58','#B2B0D4','#5860A7','#312C6C']


def preprocess_scrna(config_file, output_file):
    """
    scRNA-seq自动注释函数

    Parameters
    ----------
    config_file: str
        配置文件路径
    output_file: str
        输出文件路径
    
    """
    # 读取配置文件
    with open(config_file, 'r') as json_file:
        config = json.load(json_file)

    # 解析配置文件中的数据
    data_file_path = config['dataFile']['dataFilePath']
    # 在这里添加其他需要的解析步骤...
    fontsize=int(config['plot_settings']['fontsize'])
    basis=config['plot_settings']['basis']

    title=config['columns']['title']
    save_name=config['columns']['save_name']
    model_path=config['columns']['model_path']

    mito_perc=config['general']['mito_perc']
    nUMIs=config['general']['nUMIs']
    detected_genes=config['general']['detected_genes']
    n_HVGs=config['general']['n_HVGs']
    n_neighbors=config['general']['n_neighbors']
    n_pcs=config['general']['n_pcs']
    resolution=config['general']['resolution']
    foldchange=config['general']['foldchange']
    pvalue=config['general']['pvalue']
    celltype=config['general']['celltype']
    target=config['general']['target']
    tissue=config['general']['tissue']

    

    #读取数据
    adata=sc.read(data_file_path)
    #去重
    adata.var_names_make_unique()
    adata.obs_names_make_unique()
    #质控
    adata=ov.pp.qc(adata,
              tresh={'mito_perc': mito_perc, 'nUMIs': nUMIs, 'detected_genes': detected_genes})
    #标准化
    adata=ov.pp.preprocess(adata,mode='shiftlog|pearson',n_HVGs=n_HVGs,)
    #保留高可变基因
    adata.raw = adata
    adata = adata[:, adata.var.highly_variable_features]
    #scale和主成分分析
    ov.pp.scale(adata)
    ov.pp.pca(adata,layer='scaled',n_pcs=n_pcs)
    #聚类和降维
    sc.pp.neighbors(adata, n_neighbors=n_neighbors, n_pcs=n_pcs,
               use_rep='scaled|original|X_pca')
    ov.utils.cluster(adata,method='leiden',resolution=resolution)
    sc.tl.umap(adata)
    #自动注释
    scsa=ov.single.pySCSA(adata=adata,
                      foldchange=foldchange,
                      pvalue=pvalue,
                      celltype=celltype,
                      target=target,
                      tissue=tissue,
                      model_path=model_path                  
    )
    anno=scsa.cell_anno(clustertype='leiden',
               cluster='all',rank_rep=True)
    scsa.cell_auto_anno(adata,key='scsa_celltype_cellmarker')
    #gpu加速的降维可视化
    adata.obsm["X_mde"] = ov.utils.mde(adata.obsm["scaled|original|X_pca"])
    #绘图
    import matplotlib.pyplot as plt
    #可视化`scsa_celltype_cellmarker`
    fig, ax = plt.subplots(figsize=(4,4))
    ov.utils.embedding(adata,
                   basis=basis,
                   color=['scsa_celltype_cellmarker'], 
                   legend_loc='on data', 
                   frameon='small',
                   legend_fontoutline=2,
                   palette=ov.utils.palette(),
                   show=False,
                   ax=ax
                  )
    print('Plotting scsa_celltype_cellmarker...')

    # 保存绘图结果
    plt.title(title,fontsize=fontsize+1)
    print('Saving figure to {}...'.format(output_file))
    fig.savefig(output_file,dpi=300,bbox_inches='tight')
    # 保存注释结果
    print('Annotated annotation saved to {}...'.format(save_name))
    adata.write_h5ad(save_name,compression='gzip')
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
        preprocess_scrna(args.config, args.output)
    else:
        print('Invalid action. Use "plot" to generate a volcano plot.')
