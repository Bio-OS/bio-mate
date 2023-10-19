import { IJupyterWidgetRegistry } from '@jupyter-widgets/base';
import {
  ILayoutRestorer,
  JupyterFrontEndPlugin,
  LabShell
} from '@jupyterlab/application';
import { ICommandPalette } from '@jupyterlab/apputils';
import { INotebookTracker } from '@jupyterlab/notebook';
import { activatebioMatePlugin } from './plugin';
import activatePluginApod from './pluginAstronomyPicture';

import '@arco-themes/react-bioos/index.less';

/**
 * Initialization data for the bio-mate extension.
 */
const plugin: JupyterFrontEndPlugin<void> = {
  id: 'bio-mate:apod',
  description: 'A JupyterLab extension. extension kind: frontend.',
  autoStart: true,
  requires: [ICommandPalette],
  optional: [ILayoutRestorer],
  activate: activatePluginApod
};

const bioMatePlugin: JupyterFrontEndPlugin<void, LabShell> = {
  id: 'bio-mate:plugin',
  description: 'bioMatePlugin',
  autoStart: true,
  requires: [
    ICommandPalette,
    INotebookTracker,
    IJupyterWidgetRegistry,
    ILayoutRestorer
  ],
  activate: activatebioMatePlugin
};

export default [bioMatePlugin, plugin];
