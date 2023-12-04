# 如果需要的library没有的话，先下载
if (!"optparse" %in% installed.packages()[, "Package"]) {
  # 这个包用来解析命令行选项
  install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
}
library(optparse)
# 解析第一个选项
args <- commandArgs(trailingOnly = TRUE)
command <- args[1]

if (command == "plot") {
  # 如果需要的library没有的话，先下载
  packages <- c( "ggstatsplot", "tidyverse","jsonlite","readr","ggsci","ggridges")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }
  
  ######包调用#####
  library(ggstatsplot)
  library(ggridges)
  suppressMessages(library(tidyverse))
  library(ggsci)
  library(jsonlite)
  #命令行选项
  option_list <- list(
    make_option(c("--config"), type = "character", default = NULL, help = "Path to JSON config file", metavar = "character"),
    make_option(c("--output"), type = "character", default = "output.png", help = "Output file name with extension", metavar = "character")
  )
  
  opt_parser <- OptionParser(option_list = option_list)
  opts <- parse_args(opt_parser, args = args[-1])
  json_file_path <- opts$config
  data_file_path <- opts$input
  output_file_name <- opts$output
  create_heatmp_plot_from_json <- function(json_file_path, data_file_path, output_file_name) {
    #####文件夹切换#####
    if (!file.exists(json_file_path)) {
      stop(paste("JSON file not found:", json_file_path))
    }
    
    tryCatch(
      {
        config <- fromJSON(json_file_path)
      },
      error = function(e) {
        stop(paste("Error reading JSON file:", e))
      }
    )
    # 从JSON文件中读取列配置
    column_config <- config$columns
    
    # 从JSON中读取数据文件path
    data_file_path <- config$dataFile$dataFilePath
    
    # 检查CSV文件是否存在
    if (!file.exists(data_file_path)) {
      stop(paste("CSV file not found:", data_file_path))
    }
    
    tryCatch(
      {
        data <- read.csv(data_file_path)
      },
      error = function(e) {
        stop(paste("Error reading csv file:", e))
      }
    )
    ###没有对应列报错#####
    if (!column_config$group %in% colnames(data)) {
      stop("group col not found in data")
    }
    colnames(data)[colnames(data) == column_config$group] <- "group"
    if (!column_config$value %in% colnames(data)) {
      stop("value col not found in data")
    }
    colnames(data)[colnames(data) == column_config$value] <- "value"
    #####读入主题#####
    if (config$plot_settings$theme=="theme_ggstatsplot") theme= ggstatsplot::theme_ggstatsplot()
    if (config$plot_settings$theme=="theme_bw")theme= theme_bw()
    if (config$plot_settings$theme=="theme_classic")theme=theme_classic()
    
    #####读入颜色#####
    temp_color=config$plot_settings$colortype
    temp_color_you_choose=config$plot_settings$color_you_choose
    if (temp_color == "igv")    color1=scale_color_igv()
    if (temp_color == "igv")    fill1=scale_fill_igv(na.translate = FALSE)
    if (temp_color == "jama")   color1=scale_color_jama()
    if (temp_color == "jama")   fill1=scale_fill_jama(na.translate = FALSE)
    if (temp_color == "nejm")   color1=scale_color_nejm()
    if (temp_color == "nejm")    fill1=scale_fill_nejm(na.translate = FALSE)
    if (temp_color == "lancet")   color1=scale_color_lancet()
    if (temp_color == "lancet")  fill1=scale_fill_lancet(na.translate = FALSE)
    if (temp_color == "AAAS")    fill1=scale_fill_aaas(na.translate = FALSE)
    if (temp_color == "AAAS")   color1=scale_color_aaas()
    if (temp_color == "jco")    color1=scale_color_jco()
    if (temp_color == "jco")   fill1=scale_fill_jco(na.translate = FALSE)
    if (temp_color == "NPG")    color1=scale_color_npg()
    if (temp_color == "NPG")   fill1=scale_fill_npg(na.translate = FALSE)
    if (temp_color == "Your order")    color1=scale_color_manual(values = temp_color_you_choose)
    if (temp_color == "Your order")   fill1=scale_fill_manual(values = temp_color_you_choose)
    
    ######箱线图/小提琴图#######
    if (config$general$plottype=="box"|config$general$plottype=="violin"|config$general$plottype=="boxviolin"){
      
      plot=ggbetweenstats(
        data             = data,
        x                = group,
        y                = value,
        pairwise.comparisons=config$general$pairwisecompare,#成对比较
        pairwise.display=config$general$pairwisedisplay,#差异展示
        type=config$general$pairwisetype,#比较类别
        ggsignif.args    = list(textsize = config$plot_settings$signiftextsize, tip_length = config$plot_settings$signiftiplength),
        p.adjust.method  = config$general$pairwiseadjustmethod,#校正方式
        title=config$general$title,#标题
        xlab=config$general$x_name,#x轴lab
        ylab=config$general$y_name,#y轴lab
        plot.type = config$general$plottype,#图像类别选择
        results.subtitle=config$plot_settings$results_subtitle,#副标题
        plotgrid.args    = list(nrow = 1),
        annotation.args  = list(title = config$general$title)
      )+theme+color1+fill1
    }
    ######密度图########
    if (config$general$plottype=="density"){
      
      plot=ggplot(data, aes(x = value, fill = group)) +  # 创建一个ggplot对象，使用data作为数据源，x轴为value，填充颜色为group
        geom_density(alpha = 0.5)+
        theme+
        color1+
        fill1+
        xlab(config$general$x_name)+
        ylab(config$general$y_name)
    }
    ######山岭图########
    if (config$general$plottype=="ridges"){
      
      plot=ggplot(data) + 
        ggridges::geom_density_ridges(aes(x = value, y = group, fill = group))+# 添加ggridges包中的geom_density_ridges层，x轴为value，y轴为group，填充颜色为group
        theme+
        color1+
        fill1+
        xlab(config$general$x_name)+
        ylab(config$general$y_name)
    }
    ggsave(output_file_name,plot=plot,width = config$plot_settings$width,height = config$plot_settings$height)
  }
  create_heatmp_plot_from_json(json_file_path,data_file_path, output_file_name)
}
