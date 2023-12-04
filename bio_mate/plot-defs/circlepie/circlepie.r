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
  packages <- c("ggplot2", "gridExtra", "ggrepel", "vroom", "magrittr", "jsonlite", "grid")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggrepel)
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

  plot_circlepie_plot <- function(json_file_path, data_file_path, output_file_name) {
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

    # 从JSON文件中读取列配置
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

    # 检查所需的列是否存在
    if (!(column_config$value %in% colnames(data))) {
      stop(paste("Column '", column_config$value, "' not found in the data file."))
    }
    if (!(column_config$type %in% colnames(data))) {
      stop(paste("Column '", column_config$type, "' not found in the data file."))
    }

    # 检查value列加起来是否等于1
    if (
      sum(
        as.numeric(
          data[[column_config$value]]
        ),
        na.rm = T
      ) != 1
    ) {
      stop(paste0("The Sum of Column ", column_config$value, " not equal 1!"))
    }


    # 数据列排序和重命名
    DATA <- data[c(column_config$value, column_config$type)]
    colnames(DATA) <- c("value", "type")

    ### -------------- 所有用户可选的参数
    # 通用参数
    Title <- config$general$Title
    legendSize <- config$general$legendSize
    Gradient_color <- config$general$PlotColor
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight
    BaseLabelSize <- config$general$BaseLabelSize
    titlehjust <- config$general$titlehjust

    # 绘图参数
    labelcolor <- config$plot_settings$labelcolor
    barwidths <- config$plot_settings$barwidths
    LabelSize <- config$plot_settings$LabelSize
    Expand <- config$plot_settings$Expand
    LegendPos <- config$plot_settings$LegendPos
    Legendcols <- config$plot_settings$Legendcols

    # 根据变量数目，进行渐变色拓展
    Color <- colorRampPalette(Gradient_color)(length(unique(DATA$type)))

    # 设置标签字体位置和顺序
    TEXT_VALUE <- rev(DATA$value)
    Y_text_site <- cumsum(c(0, TEXT_VALUE[1:(length(TEXT_VALUE) - 1)])) + TEXT_VALUE / 2

    # 开始绘图
    plot <-
      ggplot(
        DATA, aes(
          x = "", y = value, fill = type
        )
      ) +
      # 绘制柱状图
      geom_bar(
        width = barwidths, # 设置环形的宽度
        stat = "identity" # 默认不进行统计操作
      ) +
      # 添加百分比字体标签
      geom_label_repel(
        aes(
          y = Y_text_site, # 标签信息
          label = rev(paste0(value * 100, "%")) # 设置为百分比
        ),
        fill = NA, # 不设置填充色
        size = LabelSize, # 字体大小
        nudge_x = 0.8, # 远离中心
        color = labelcolor # 标签颜色
      ) +
      # 柱状图环形化
      coord_polar("y", start = 0, direction = 1) +
      # 设置填充色
      scale_fill_manual(values = Color, name = NULL) +
      # 设置x方向缩放
      scale_x_discrete(expand = Expand) +
      # 主题设置
      theme_minimal(base_size = BaseLabelSize) +
      theme(
        axis.title = element_blank(), # 坐标轴字体为空
        panel.border = element_blank(), # 图框边缘设置为空
        panel.grid = element_blank(), # 不设置格子线
        axis.ticks = element_blank(), # 不设置坐标轴刻度
        legend.title = element_blank(), # 不设置图例标题
        legend.position = LegendPos, # 图例位置
        legend.justification = LegendPos, # 图例位置矫正
        axis.text.x = element_blank(), # x轴坐标字体为空
        plot.title = element_text(hjust = titlehjust, face = "bold") # 设置主标题的位置
      ) +
      # 主图题目设置
      labs(title = Title) +
      # 设置图例信息
      guides(
        fill = guide_legend(
          ncol = Legendcols, # 图例列数
          override.aes = list(size = legendSize) # 图例大小
        )
      )

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
  plot_circlepie_plot(json_file_path, data_file_path, output_file_name)
}
