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
  packages <- c("ggplot2", "gridExtra", "vroom", "magrittr", "jsonlite", "grid")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(RColorBrewer)
  library(gridExtra)
  library(jsonlite)
  library(magrittr)
  library(vroom)
  library(ggplot2)
  library(grid)

  # 命令行选项
  option_list <- list(
    make_option(c("--config"), type = "character", default = NULL, help = "Path to JSON config file", metavar = "character"),
    make_option(c("--output"), type = "character", default = "output.png", help = "Output file name with extension", metavar = "character")
  )

  # 解析选项
  opt_parser <- OptionParser(option_list = option_list)
  opts <- parse_args(opt_parser, args = args[-1])
  json_file_path <- opts$config
  output_file_name <- opts$output

  plot_Distribution_plot <- function(json_file_path, data_file_path, output_file_name) {
    # 检查JSON文件是否存在
    if (!file.exists(json_file_path)) {
      stop(paste("JSON file not found:", json_file_path))
    }

    # 读取json列表参数
    tryCatch(
      {
        config <- fromJSON(json_file_path)
      },
      error = function(e) {
        stop(paste("Error reading JSON file:", e))
      }
    )

    # 从JSON中读取数据文件path
    data_file_path <- config$dataFile$dataFilePath
    # 从JSON中读取用户输入的列名
    column_config <- config$columns

    # 检查CSV文件是否存在
    if (!file.exists(data_file_path)) {
      stop(paste("CSV file not found:", data_file_path))
    }

    # 读取表格数据文件, vroom默认会猜测表格的分割符，如果你的表格属于较为正常的类型
    tryCatch(
      {
        data <- vroom::vroom(data_file_path)
      },
      error = function(e) {
        stop(paste("Error reading CSV file:", e))
      }
    )

    # 判断用户输入的列名是否存在于输入的数据中
    if (!(column_config$Value %in% colnames(data))) {
      stop(paste("Column '", column_config$Value, "' not found in the data file."))
    }
    if (!(column_config$platform %in% colnames(data))) {
      stop(paste("Column '", column_config$platform, "' not found in the data file."))
    }


    ### -------------- 所有用户可选的参数
    # 通用参数
    Title <- config$general$Title
    PlotColor <- config$general$PlotColor
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight
    BaseLabelSize <- config$general$BaseLabelSize
    BaseLineSize <- config$general$BaseLineSize
    BaseRectSize <- config$general$BaseRectSize
    titlehjust <- config$general$titlehjust

    # 绘图参数
    CurveLineSize <- config$plot_settings$CurveLineSize
    nrow <- config$plot_settings$nrow
    scales <- config$plot_settings$scales

    # 数据排序和重命名
    DATA <- data[c(column_config$Value, column_config$platform)]
    colnames(DATA) <- c("value", "Type")
    XName <- colnames(DATA)[1]

    # 开始绘图
    plot <-
      ggplot(data = DATA) +
      geom_density(
        aes(x = value),
        size = CurveLineSize, # 线段粗细
        color = PlotColor, # 线段颜色
      ) +
      # 设置分面
      facet_wrap(
        . ~ Type, # 分面变量
        scales = scales, # 分面坐标轴缩放设置
        nrow = nrow # 分面成几行
      ) +
      # 主题设置
      theme_bw(
        base_size = BaseLabelSize, # 图片整体字体大小
        base_line_size = BaseLineSize, # 图片背景线粗细
        base_rect_size = BaseRectSize # 图片框线粗细
      ) +
      # 设置主标题的位置
      theme(plot.title = element_text(hjust = titlehjust)) +
      # 坐标轴标签和主图标题设置
      labs(x = XName, y = "Density", title = Title)


    # 以png格式保存结果
    png(
      output_file_name,
      width = plotwidth, # 设置图片宽度
      height = plotheight, # 设置图片高度
      units = "px",
      res = pictureRes # 设置图片分辨率
    )

    grid::grid.draw(plot)

    dev.off()
  }

  ### --------------  执行绘图函数
  plot_Distribution_plot(json_file_path, data_file_path, output_file_name)
}
