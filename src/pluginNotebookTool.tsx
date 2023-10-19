import { DisposableDelegate, IDisposable } from '@lumino/disposable';
// import {IJ} from '@jupyter-widgets/jupyterlab-manager';
import { IJupyterWidgetRegistry } from '@jupyter-widgets/base';

import { INotebookTracker } from '@jupyterlab/notebook';
import { Widget } from '@lumino/widgets';

import { JupyterFrontEnd } from '@jupyterlab/application';

import { DocumentRegistry } from '@jupyterlab/docregistry';

import { ToolbarButton } from '@jupyterlab/apputils';
import { NotebookPanel } from '@jupyterlab/notebook';
import { BaseWidgetModel, BaseWidgetView } from './basewidget';
import { BioContext } from './context';
import {
  MODULE_NAME,
  MODULE_VERSION,
  WIDGET_ID_APP_PANEL
} from './util/consts';
import { logoWidget } from './util/logo';

/**
 * The plugin registration information.
 */

/**
 * A notebook widget extension that adds a widget in the notebook header (widget below the toolbar).
 */
// export class WidgetExtension implements DocumentRegistry.WidgetExtension {
//   onClick: () => void;

//   constructor({ onClick }: { onClick(): void }) {
//     this.onClick = onClick;
//   }

//   /**
//    * Create a new extension object.
//    */
//   createNew(
//     panel: NotebookPanel,
//     context: DocumentRegistry.IContext<DocumentRegistry.IModel>
//   ): IDisposable {
//     const widget = new Widget({ node: Private.createNode() });
//     widget.addClass('jp-myextension-myheader');

//     const btn = new ToolbarButton({
//       icon: logoWidget,
//       actualOnClick: true,
//       onClick: this.onClick
//     });

//     // panel.toolbar.insertAfter('cellType', 'mmmm:bio', btn);

//     // panel.contentHeader.insertWidget(0, widget);
//     return new DisposableDelegate(() => {
//       widget.dispose();
//     });
//   }
// }

/**
 * Activate the extension.
 */
export function activateNotebookTool(
  app: JupyterFrontEnd,
  notebookTracker: INotebookTracker,
  widget_registry: IJupyterWidgetRegistry
): void {
  console.log(
    `JupyterLab extension bio-mate:notebookTool v3 is activated! (JupyterLab: ${app.version})`
  );
  BioContext.notebookTracker = notebookTracker;

  const PREFIX_ACTIVE_CELL_CHAANGED = 'notebookTracker: activeCellChanged';
  notebookTracker.activeCellChanged.connect(() => {
    const current_widget = notebookTracker.currentWidget;
    console.log(PREFIX_ACTIVE_CELL_CHAANGED, current_widget);

    if (!(current_widget instanceof NotebookPanel)) return;

    current_widget.context.sessionContext.kernelChanged.connect(
      sessionContext => {
        const kernel = sessionContext.session?.kernel;

        console.log('sessionContext: kernelChanged', kernel);

        if (!kernel) return;

        kernel.requestExecute({
          code: 'import bio_mate'
        });
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

  widget_registry.registerWidget({
    name: MODULE_NAME,
    version: MODULE_VERSION,
    exports: {
      BaseWidgetModel,
      BaseWidgetView
    }
  });
}

/**
 * Private helpers
 */
namespace Private {
  /**
   * Generate the widget node
   */
  export function createNode(): HTMLElement {
    const span = document.createElement('span');
    span.textContent = 'My custom header';
    return span;
  }
}
