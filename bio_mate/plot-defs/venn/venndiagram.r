# 如果需要的library没有的话，先下载
if (!"optparse" %in% installed.packages()[, "Package"]) {
  # 这个包用来解析命令行选项
  install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
}

library(optparse)
# 解析第一个选项
args <- commandArgs(trailingOnly = TRUE)
command <- args[1]

# 执行plot板块
if (command == "plot") {
  # 如果需要的library没有的话，先下载
  packages <- c("ggplot2", "VennDiagram", "gridExtra","jsonlite")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggplot2)
  library(VennDiagram)
  library(gridExtra)
  library(jsonlite)

  # 命令行选项
  option_list <- list(
    make_option(c("--config"), type = "character", default = NULL, help = "Path to JSON config file", metavar = "character"),
    make_option(c("--output"), type = "character", default = "output.png", help = "Output file name with extension", metavar = "character")
  )

  # 解析选项
  opt_parser <- OptionParser(option_list = option_list)
  opts <- parse_args(opt_parser, args = args[-1])
  json_file_path <- opts$config
  data_file_path <- opts$input
  output_file_name <- opts$output

  create_venn_diagram <- function(json_file_path,data_file_path, output_file_name){
    # 检查JSON文件是否存在
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
        stop(paste("Error reading CSV file:", e))
      }
    )

     # 检查所需的列是否存在
    if (!(column_config$Set1 %in% colnames(data))) {
      stop(paste("Column '", column_config$Set1, "' not found in the data file."))
    }
    if (!(column_config$Set2 %in% colnames(data))) {
      stop(paste("Column '", column_config$Set2, "' not found in the data file."))
    }
    if (!(column_config$Set3 %in% colnames(data))) {
      stop(paste("Column '", column_config$Set3, "' not found in the data file."))
    }
    if (!(column_config$Set4 %in% colnames(data))) {
      stop(paste("Column '", column_config$Set4, "' not found in the data file."))
    }
    if (!(column_config$Set5 %in% colnames(data))) {
      stop(paste("Column '", column_config$Set5, "' not found in the data file."))
    }

    # 重命名列
    colnames(data)[colnames(data) == column_config$Set1] <- "Set1"
    colnames(data)[colnames(data) == column_config$Set2] <- "Set2"
    colnames(data)[colnames(data) == column_config$Set3] <- "Set3"
    colnames(data)[colnames(data) == column_config$Set4] <- "Set4"
    colnames(data)[colnames(data) == column_config$Set5] <- "Set5"

    # 创建Venn图对象
    venn <- venn.diagram(
      x = list(data$Set1, data$Set2, data$Set3, data$Set4, data$Set5),
      category.names = c(column_config$Set1 , column_config$Set2 , column_config$Set3 , column_config$Set4 , column_config$Set5),
      filename = NULL,  # 指定维恩图文件的名称，如果为NULL，则不保存为文件。
      output = FALSE,  #用于指定输出文件的格式，例如"pdf"、"svg"、"png"等。
      imagetype = NULL, #用于指定图像类型，例如"png"、"cairo-png"、"cairo-svg"等。
      scaled = FALSE, #一个逻辑值，指示是否对维恩图进行缩放。
      col = config$general$bordercolor, #指定维恩图中各组的边界颜色。
      fill = c(config$plot_settings$fillcolors[1], config$plot_settings$fillcolors[2], config$plot_settings$fillcolors[3], config$plot_settings$fillcolors[4], config$plot_settings$fillcolors[5]), #指定维恩图中各组的填充颜色。
      alpha = config$general$alpha,  #指定维恩图中各组的透明度。
      label.col = config$general$labelcolor, #指定维恩图中组标签的颜色。
      cex = config$plot_settings$cex, # 指定维恩图中各元素（例如组标签和计数）的缩放比例。
      fontface = config$plot_settings$fontface, #指定维恩图中各元素的字体样式，如"plain"、"bold"、"italic"等。
      cat.pos = c(config$plot_settings$cat_pos[1], config$plot_settings$cat_pos[2],config$plot_settings$cat_pos[3],config$plot_settings$cat_pos[4], config$plot_settings$cat_pos[5]), #一个包含两个数值的向量，用于调整组标签的位置。
      cat.dist = config$plot_settings$cat_dist, #一个数值，用于调整组标签与中心的距离。
      cat.cex = config$plot_settings$cat_cex, #指定组标签的缩放比例。
      cat.fontface = config$plot_settings$cat_fontface, #指定组标签的字体样式。
      margin = config$plot_settings$margin, #一个数值，用于调整维恩图的边缘。
      main = config$general$title #指定维恩图的标题。
    )

    # 保存Venn图
    png(output_file_name, width = 800, height = 600, units = "px", res = 300)
    grid.draw(venn)
    dev.off()
  }

  create_venn_diagram(json_file_path, data_file_path, output_file_name)
}