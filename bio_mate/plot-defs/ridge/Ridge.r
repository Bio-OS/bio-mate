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
  packages <- c("ggplot2", "gridExtra", "RColorBrewer", "ggridges", "vroom", "magrittr", "jsonlite", "grid")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(RColorBrewer)
  library(ggridges)
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

  plot_Ridge_plot <- function(json_file_path, data_file_path, output_file_name) {
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

    # 对用户输入的列按照顺序排序和重命名
    DATA <- data[c(column_config$Value, column_config$platform)]

    colnames(DATA) <- c("value", "Type")

    ### -------------- 所有用户可选的参数
    # 通用参数
    BaseLabelSize <- config$general$BaseLabelSize
    BaseLineSize <- config$general$BaseLineSize
    Title <- config$general$Title
    Color <- colorRampPalette(config$general$Color)(32) # 对用户输入的颜色进行扩增
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight
    titlehjust <- config$general$titlehjust

    # 绘图参数
    ridges_gradientSize <- config$plot_settings$ridges_gradientSize
    center_axis_labels <- config$plot_settings$center_axis_labels
    grid <- config$plot_settings$grid

    # 用户输入的坐标轴title名称
    XName <- c(column_config$Value, column_config$platform)

    plot <-
      ggplot(
        DATA, aes(
          x = value, y = Type, fill = ..density.. # 使用..避免与列名density重复
        )
      ) +
      # 峰峦密度分布填充
      geom_density_ridges_gradient(
        scale = ridges_gradientSize, # 设置峰峦高度
        rel_min_height = 0.00, size = 0.3, show.legend = F, color = F
      ) +
      scale_fill_gradientn(colours = Color) + # 数据分布密度颜色填充
      # 峰峦主题设置
      theme_ridges(
        font_size = BaseLabelSize, # 基础的字体大小
        grid = grid, # 是否添加网格
        center_axis_labels = center_axis_labels, # 坐标轴title是否居中
        line_size = BaseLineSize # 网格先粗细
      ) +
      # 其他主题设置
      theme(
        panel.border = element_blank(), # 图边缘线设置为空
        axis.title = element_text(face = "bold"), # 默认坐标轴标题加粗
        plot.title = element_text(hjust = titlehjust) # 设置主标题的位置
      ) +
      # 坐标轴标题名称和绘图标题设置
      labs(x = XName[1], y = XName[2], title = Title)

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
  plot_Ridge_plot(json_file_path, data_file_path, output_file_name)
}
