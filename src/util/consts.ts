import {
  IconAreaChart,
  IconBoxPlot,
  IconComprehensiveEvaluation,
  IconConversionAnalysis,
  IconCurve,
  IconDataVisualization,
  IconEllipse,
  IconFunnelPlot,
  IconIGV,
  IconLevelTest,
  IconPiechart,
  IconScatterPlot
} from '@arco-iconbox/react-biomate';

export const WIDGET_ID_APP_PANEL = 'bioMate:appPanel';

export const NAMESPACE = 'bioMate';

export const MODULE_NAME = 'bio-mate';
export const MODULE_VERSION = '1.0.0';

export const basicPlotApps = [
  {
    id: 'volcano',
    name: '火山散点图',
    icon: IconScatterPlot,
    color: '#4E925A'
  },
  { id: 'venn', name: '韦恩图', icon: IconPiechart, color: '#368ECE' },
  { id: '', name: '柱状图', icon: IconLevelTest, color: '#368ECE' },
  { id: '', name: '饼图', icon: IconPiechart, color: '#AC7300' },
  { id: '', name: '条形图', icon: IconConversionAnalysis, color: '#AC7300' },
  { id: '', name: '面积图', icon: IconAreaChart, color: '#D45900' },
  { id: '', name: '折线图', icon: IconCurve, color: '#4E925A' },
  { id: '', name: '箱型图', icon: IconBoxPlot, color: '#D45900' },
  { id: '', name: '直方图', icon: IconDataVisualization, color: '#368ECE' },
  { id: '', name: '漏斗图', icon: IconFunnelPlot, color: '#368ECE' },
  { id: '', name: '环形图', icon: IconEllipse, color: '#AC7300' },
  {
    id: '',
    name: '雷达图',
    icon: IconComprehensiveEvaluation,
    color: '#4E925A'
  }
];
export const advancedPlotApps = [
  { id: '', name: 'IGV', icon: IconIGV, color: '#7F7F7F' }
];
