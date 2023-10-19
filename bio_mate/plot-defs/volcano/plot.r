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
  packages <- c("ggplot2", "jsonlite", "ggrepel")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggplot2)
  library(jsonlite)
  library(ggrepel)

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

  create_volcano_plot_from_json <- function(json_file_path, data_file_path, output_file_name) {
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
    if (!(column_config$Symbol %in% colnames(data))) {
      stop(paste("Column '", column_config$Symbol, "' not found in the data file."))
    }
    if (!(column_config$logFC %in% colnames(data))) {
      stop(paste("Column '", column_config$logFC, "' not found in the data file."))
    }
    if (!(column_config$p_value %in% colnames(data))) {
      stop(paste("Column '", column_config$p_value, "' not found in the data file."))
    }

    # 重命名列
    colnames(data)[colnames(data) == column_config$Symbol] <- "Symbol"
    colnames(data)[colnames(data) == column_config$logFC] <- "logFC"
    colnames(data)[colnames(data) == column_config$p_value] <- "p_value"

    # 将logFC转换为数字类型
    data$logFC <- as.numeric(data$logFC)

    # 将p_value转换为数字类型
    data$p_value <- as.numeric(data$p_value)

    # 初始化Expressed列为"NO"
    data$Expressed <- "NO"

    # 如果logFC大于给定阈值且p_value小于给定阈值，则设置Expressed为"UP"
    data$Expressed[data$logFC > config$plot_settings$vline_intercepts[2] & data$p_value < config$plot_settings$hline_intercept] <- "UP"

    # 如果logFC小于给定阈值且p_value小于给定阈值，则设置Expressed为"DOWN"
    data$Expressed[data$logFC < config$plot_settings$vline_intercepts[1] & data$p_value < config$plot_settings$hline_intercept] <- "DOWN"

    # 如果Symbol在前n个p_value中，则设置delabel为Symbol，否则设置为NA
    data$delabel <- ifelse(data$Symbol %in% head(data[order(data$p_value), "Symbol"], config$plot_settings$threshold), data$Symbol, NA)

    # 创建一个主题，并根据配置来修改背景
    custom_theme <- theme_gray()

    if (config$plot_settings$remove_background_subLine) {
      custom_theme <- custom_theme + theme(panel.grid.minor = element_blank())
    }

    if (config$plot_settings$remove_background_mainLine) {
      custom_theme <- custom_theme + theme(panel.grid.major = element_blank())
    }

    if (config$plot_settings$remove_background) {
      custom_theme <- custom_theme + theme(panel.background = element_blank())
    }

    # 使用ggplot创建图层
    p <- ggplot(data, aes(x = logFC, y = -log10(p_value), color = Expressed, label = delabel)) +
      # 添加垂直线
      geom_vline(xintercept = config$plot_settings$vline_intercepts, col = config$plot_settings$line_color, linetype = config$plot_settings$line_type) +
      # 添加水平线
      geom_hline(yintercept = -log10(config$plot_settings$hline_intercept), col = config$plot_settings$line_color, linetype = config$plot_settings$line_type) +
      # 添加点
      geom_point(size = config$plot_settings$point_size) +
      # 手动设置颜色
      scale_color_manual(values = config$plot_settings$colors, labels = config$plot_settings$labels) +
      # 设置坐标轴范围
      coord_cartesian(ylim = config$plot_settings$ylim, xlim = config$plot_settings$xlim) +
      # 设置标签名称
      labs(
        color = config$general$lab_name,
        x = config$general$x_name, y = config$general$y_name
      ) +
      # 设置x轴断点
      scale_x_continuous(breaks = config$plot_settings$x_breaks) +
      # 设置图表标题
      ggtitle(config$general$title) +
      # 设置标题样式，包括大小和对齐方式
      theme(plot.title = element_text(size = config$general$titleSize, hjust = config$plot_settings$h_just)) +
      custom_theme



    # 如果config$plot_settings$with_label为true，则添加基因标签
    if (config$plot_settings$with_label == TRUE) {
      if (config$plot_settings$with_label_frame == TRUE) {
        p <- p + geom_label_repel(max.overlaps = Inf) # 添加带边框的标签
      } else {
        p <- p + geom_text_repel(max.overlaps = Inf) # 添加不带边框的标签
      }
    }
    # 保存图片，--output里的后缀决定图片输出格式
    ggsave(output_file_name, plot = p)
    message <- paste("Generate plot", output_file_name, "success")
    print(message)
  }
  plot <- create_volcano_plot_from_json(json_file_path, data_file_path, output_file_name)
}
# 未来可以加别的板块
