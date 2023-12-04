#!/usr/bin/env Rscript

# 定义镜像源
mirror_repo <- "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"

# 如果需要的library没有的话，先下载
packages <- c("optparse", "ggplot2", "jsonlite")
new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) {
  install.packages(new_packages, repos = mirror_repo)
}
# 加载library
library(optparse)
library(ggplot2)
library(jsonlite)

# 命令行选项
option_list <- list(
  make_option(
    c("--config"),
    type = "character",
    default = NULL,
    help = "Path to JSON config file",
    metavar = "character"
  ),
  make_option(
    c("--output"),
    type = "character",
    default = "output.png",
    help = "Output file name with extension",
    metavar = "character"
  )
)

# 解析选项
args <- commandArgs(trailingOnly = TRUE)
opt_parser <- OptionParser(option_list = option_list)
opts <- parse_args(opt_parser, args = args)
print(opts)
json_file_path <- opts$config
output_file_name <- opts$output

# 检查路径是否存在
check_file_if_exist <- function(path) {
  if (!file.exists(path)) {
    stop(paste("File not found:", path))
  }
}


create_ver_bar_diagram <- function(json_file_path, output_file_name) {
  # 检查JSON文件是否存在
  check_file_if_exist(json_file_path)

  # 读取JSON文件, 如果读取失败，抛出异常
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
  check_file_if_exist(data_file_path)

  # 读取CSV文件, 如果读取失败，抛出异常
  tryCatch(
    {
      data <- read.csv(data_file_path)
    },
    error = function(e) {
      stop(paste("Error reading CSV file:", e))
    }
  )

  # 检查列是否存在,若存在则重命名,不存在则抛出异常
  for (key in names(column_config)) {
    value <- column_config[[key]]
    if (!(value %in% colnames(data))) {
      stop(paste("Column '", value, "' not found in the data file."))
    } else {
      colnames(data)[colnames(data) == value] <- key
    }
  }

  # 重新排列data
  order_sig <- config$plot_settings$order
  if (order_sig == 1) {
    # 保持输入顺序
    # do nothing
  } else if (order_sig == 2) {
    # name顺序
    data <- data[order(data$name), ]
  } else if (order_sig == 3) {
    # name逆序
    data <- data[order(data$name, decreasing = TRUE), ]
  } else if (order_sig == 4) {
    # value顺序
    data <- data[order(data$value), ]
  } else if (order_sig == 5) {
    # value逆序
    data <- data[order(data$value, decreasing = TRUE), ]
  } else {
    stop(paste("order_sig is not in the range of 1 to 5"))
  }
  # 因子化name
  data$name <- factor(data$name, levels = data$name)

  # 创建图对象
  ver_bar <- ggplot(
    data,
    aes(x = name, y = value)
  ) +
    geom_bar(
      stat = "identity",
      fill = config$plot_settings$fillcolor,
      width = config$plot_settings$barWidth
    ) +
    ggtitle(config$general$title) +
    theme_bw(base_size = config$general$titleSize) +
    theme(plot.title = element_text(hjust = config$general$titlePosition)) +
    labs(x = config$general$x_name, y = config$general$y_name)

  # 设置是否显示数值标签
  if (config$plot_settings$showValue) {
    ver_bar <- ver_bar + geom_text(mapping = aes(label = value))
  }

  # 保存图像并日志
  ggsave(output_file_name, plot = ver_bar)
  message <- paste("Generate plot", output_file_name, "success")
  print(message)
}

create_ver_bar_diagram(json_file_path, output_file_name)
