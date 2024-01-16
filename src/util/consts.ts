import {
  IconARG,
  IconAnnotation,
  IconBoxPlot,
  IconCirclepie,
  IconComprehensiveEvaluation,
  IconCorrelation,
  IconCurve,
  IconDataVisualization,
  IconDensityPoint,
  IconDistribution,
  IconEmbedding,
  IconHeatmap,
  IconKdeplot,
  IconLevelTest,
  IconMulti,
  IconPiechart,
  IconPyCircos,
  IconPyCirosHist,
  IconPyCirosLine,
  IconPyCirosLink,
  IconPyCirosPoint,
  IconRidgePlot,
  IconScatterPlot,
  IconSpatialplot,
  IconTTestViolin,
  IconVenn
} from '@arco-iconbox/react-biomate';

export const WIDGET_ID_APP_PANEL = 'bioMate:appPanel';

export const NAMESPACE = 'bioMate';

export const MODULE_NAME = 'bio-mate';
export const MODULE_VERSION = '1.0.0';

export const basicPlotApps = [
  {
    id: 'Volcano',
    name: '火山图',
    icon: IconScatterPlot,
    color: '#4E925A'
  },
  { id: 'Venn', name: '韦恩图', icon: IconVenn, color: '#D45900' },
  { id: 'Barplot', name: '柱状图', icon: IconLevelTest, color: '#368ECE' },
  { id: 'Boxplot', name: '箱线图', icon: IconBoxPlot, color: '#D45900' },
  {
    id: 'Histplot',
    name: '直方图',
    icon: IconDataVisualization,
    color: '#368ECE'
  },
  { id: 'Kdeplot', name: '密度图', icon: IconKdeplot, color: '#7F7F7F' },
  { id: 'Lineplot', name: '线图', icon: IconCurve, color: '#4E925A' },
  { id: 'Pieplot', name: '饼图', icon: IconPiechart, color: '#AC7300' },
  {
    id: 'Radarplot',
    name: '雷达图',
    icon: IconComprehensiveEvaluation,
    color: '#4E925A'
  },
  {
    id: 'Ridgeplot',
    name: '峰峦图 (岭图)',
    icon: IconRidgePlot,
    color: '#7F7F7F'
  },
  { id: 'Circlepie', name: '环形饼图', icon: IconCirclepie, color: '#D45900' },
  {
    id: 'DensityPoint',
    name: '密度点图',
    icon: IconDensityPoint,
    color: '#368ECE'
  },
  {
    id: 'Distribution',
    name: '密度曲线分布图',
    icon: IconDistribution,
    color: '#AC7300'
  },
  {
    id: 'T-testViolin',
    name: '小提琴图',
    icon: IconTTestViolin,
    color: '#368ECE'
  },
  {
    id: 'Correlation',
    name: '相关性热图',
    icon: IconCorrelation,
    color: '#4E925A'
  },
  { id: 'Heatmap', name: '热图', icon: IconHeatmap, color: '#D45900' }
];

export const advancedPlotApps = [
  { id: 'ARG', name: 'ARG', icon: IconARG, color: '#7F7F7F' },
  { id: 'Multi', name: '多图生成', icon: IconMulti, color: '#368ECE' },
  {
    id: 'PyCircos',
    name: '环形基因组图',
    icon: IconPyCircos,
    color: '#4E925A'
  },
  {
    id: 'PyCircosHist',
    name: '基因组柱状圈图',
    icon: IconPyCirosHist,
    color: '#D45900'
  },
  {
    id: 'PyCircosPoint',
    name: '基因组点状圈图',
    icon: IconPyCirosPoint,
    color: '#AC7300'
  },
  {
    id: 'PyCircosLine',
    name: '基因组折线圈图',
    icon: IconPyCirosLine,
    color: '#368ECE'
  },
  {
    id: 'PyCircosLink',
    name: '基因组关联圈图',
    icon: IconPyCirosLink,
    color: '#368ECE'
  },
  {
    id: 'Annotation',
    name: '单细胞自动注释',
    icon: IconAnnotation,
    color: '#4E925A'
  },
  {
    id: 'Embedding',
    name: '低维可视化',
    icon: IconEmbedding,
    color: '#7F7F7F'
  },
  {
    id: 'Spatialplot',
    name: '空间转录组数据可视化',
    icon: IconSpatialplot,
    color: '#AC7300'
  }
];
