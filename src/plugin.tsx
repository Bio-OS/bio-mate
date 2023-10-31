import { IJupyterWidgetRegistry } from '@jupyter-widgets/base';
import {
  ILayoutRestorer,
  JupyterFrontEnd,
  LabShell
} from '@jupyterlab/application';
import { ICommandPalette } from '@jupyterlab/apputils';
import { CodeCell } from '@jupyterlab/cells';
import { INotebookTracker, NotebookPanel } from '@jupyterlab/notebook';
import { BaseWidgetModel, BaseWidgetView } from './basewidget';
import { BioContext } from './context';
import { initAppPanel } from './pluginAppPanel';
import { MODULE_NAME, MODULE_VERSION } from './util/consts';

export function activatebioMatePlugin(
  app: JupyterFrontEnd<LabShell>,
  palette: ICommandPalette,
  notebookTracker: INotebookTracker,
  widgetRegistry: IJupyterWidgetRegistry,
  layoutRestorer: ILayoutRestorer
) {
  console.log(
    `JupyterLab extension bio-mate:plugin (v3) is activated! (JupyterLab: ${app.version})`
  );

  // 保存到 context
  BioContext.app = app;
  BioContext.notebookTracker = notebookTracker;
  BioContext.palette = palette;
  BioContext.widgetRegistry = widgetRegistry;
  BioContext.layoutRestorer = layoutRestorer;

  // 初始化 App Panel
  initAppPanel();

  // 注册自定义 notebook jupyter widget
  widgetRegistry.registerWidget({
    name: MODULE_NAME,
    version: MODULE_VERSION,
    exports: {
      BaseWidgetModel,
      BaseWidgetView
    }
  });

  // 隐式导入 bio_mate python package
  const notebookPanelkernelChanged: NotebookPanel[] = [];
  const PREFIX_ACTIVE_CELL_CHAANGED = 'notebookTracker: activeCellChanged';
  notebookTracker.activeCellChanged.connect(() => {
    const current_widget = notebookTracker.currentWidget;
    console.log(PREFIX_ACTIVE_CELL_CHAANGED, current_widget);

    if (!(current_widget instanceof NotebookPanel)) return;

    // 避免重复注册callback
    if (notebookPanelkernelChanged.includes(current_widget)) return;

    notebookPanelkernelChanged.push(current_widget);
    current_widget.context.sessionContext.kernelChanged.connect(
      sessionContext => {
        const kernel = sessionContext.session?.kernel;

        console.log('sessionContext: kernelChanged', kernel);

        if (!kernel) return;

        kernel.requestExecute({
          code: 'import bio_mate'
        });

        console.log('runBioMateCells', current_widget);
        runBioMateCells(current_widget);
      }
    );
  });

  // app.docRegistry.addWidgetExtension(
  //   'Notebook',
  //   new WidgetExtension({
  //     onClick() {
  //       BioContext.app.shell.activateById(WIDGET_ID_APP_PANEL);

  //       // if (BioContext.appPanelWidget.isVisible) {
  //       //   BioContext.appPanelWidget.setHidden(true);
  //       // } else {
  //       //   app.shell.activateById(WIDGET_ID_APP_PANEL);
  //       // }
  //     }
  //   })
  // );
}

function runBioMateCells(notebookPanel?: NotebookPanel) {
  if (!notebookPanel) return;

  const cell_widgets = notebookPanel.content.widgets;
  cell_widgets.forEach(widget => {
    if (!(widget instanceof CodeCell)) return;
    const flag = widget.model.metadata.get('BioMate');
    if (!flag) return;

    CodeCell.execute(widget, notebookPanel.sessionContext);
  });
}
