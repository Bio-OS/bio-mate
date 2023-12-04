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
  packages <- c("ggplot2", "RColorBrewer", "gridExtra", "vroom", "magrittr", "ggpubr", "jsonlite")

  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]

  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggplot2)
  library(ggpubr)
  library(RColorBrewer)
  library(gridExtra)
  library(jsonlite)
  library(magrittr)
  library(vroom)

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

  plot_density_scatter_plot <- function(json_file_path, data_file_path, output_file_name) {
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

    # 从JSON文件中读取列配置
    column_config <- config$columns

    # 从JSON中读取数据文件path
    data_file_path <- config$dataFile$dataFilePath

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

    # 检查所需的列是否存在
    if (!(column_config$X %in% colnames(data))) {
      stop(paste("Column '", column_config$X, "' not found in the data file."))
    }
    if (!(column_config$Y %in% colnames(data))) {
      stop(paste("Column '", column_config$Y, "' not found in the data file."))
    }

    ### -------------- 所有用户可选的参数
    # 通用参数
    Title <- config$general$Title
    PlotColor <- config$general$PlotColor
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight
    PlotLineSize <- config$general$PlotLineSize
    PlotRectSize <- config$general$PlotRectSize
    LabelSize <- config$general$LabelSize
    titlehjust <- config$general$titlehjust

    # 绘图参数
    bins <- config$plot_settings$Bin_Count
    se <- config$plot_settings$Addse
    LineColor <- config$plot_settings$LineColor
    LineSize <- config$plot_settings$LineSize
    legendpos <- config$plot_settings$legendpos
    RLabelSize <- config$plot_settings$RLabelSize
    RLabelXpos <- config$plot_settings$RLabelXpos
    RLabelYpos <- config$plot_settings$RLabelYpos

    # 开始绘图
    plot <-
      ggplot(
        data = data, aes(
          x = .data[[column_config$X]], y = .data[[column_config$Y]] # 设置Data-masking
        )
      ) +
      # 设置密度区块数目
      stat_bin_2d(bins = bins) +
      # 设置密度渐变颜色
      scale_fill_gradientn(colours = PlotColor) +
      # 绘制拟合线
      geom_smooth(
        method = "lm", # 默认是直接，因为展示的是线性相关
        se = se, # 是否显示标准误范围
        color = LineColor, # 线颜色
        size = LineSize # 线粗细
      ) +
      # 设置主题
      theme_bw(
        base_size = LabelSize, # 字体大小
        base_rect_size = PlotRectSize, # 边框粗细
        base_line_size = PlotLineSize # 背景线粗细
      ) +
      theme(
        axis.title = element_text(face = "bold"), # 默认设置坐标轴标题加粗
        panel.grid.minor = element_blank(), # 默认设置背景小线为空
        # 修改刻度线内
        legend.position = legendpos, # 图例位置
        legend.background = element_blank(), # 图例背景设为空
        legend.title = element_blank(), # 图例标题设为空
        # 设置刻度label的边距
        axis.text.x = element_text(margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"), color = "black"),
        axis.text.y = element_text(margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"), color = "black"),
        plot.title = element_text(hjust = titlehjust) # 设置主标题的位置
      ) +
      # 添加相关系数值
      stat_cor(
        method = "spearman", # 默认方法
        size = RLabelSize, # 字体大小
        label.x.npc = RLabelXpos, # 横向位置
        label.y.npc = RLabelYpos, # 纵向位置
        fontface = "bold" # 字体加粗
      ) +
      # 设置主图标题
      labs(title = Title)

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
  plot_density_scatter_plot(json_file_path, data_file_path, output_file_name)
}
