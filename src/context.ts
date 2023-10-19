import { IJupyterWidgetRegistry } from '@jupyter-widgets/base';
import {
  ILayoutRestorer,
  JupyterFrontEnd,
  LabShell
} from '@jupyterlab/application';
import { ICommandPalette } from '@jupyterlab/apputils';
import { INotebookTracker } from '@jupyterlab/notebook';
import { AppPanelWidget } from './pluginAppPanel';

declare global {
  interface Window {
    BioContext: BioContext;
  }
}

export class BioContext {
  static app: JupyterFrontEnd<LabShell>;

  static palette: ICommandPalette;
  static notebookTracker: INotebookTracker;
  static widgetRegistry: IJupyterWidgetRegistry;
  static layoutRestorer: ILayoutRestorer;

  static appPanelWidget: AppPanelWidget;
}

window.BioContext = BioContext;
